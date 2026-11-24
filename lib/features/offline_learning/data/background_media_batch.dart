import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/core/network/dio_client.dart';
import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/utils/log.dart';

typedef RunDownloadTaskFn =
    Future<TaskStatusUpdate> Function(DownloadTask task);

typedef CancelDownloadTaskFn = Future<bool> Function(String taskId);

/// Cancels every task of a group; returns how many there were.
typedef ResetDownloadGroupFn = Future<int> Function(String group);

/// The group of the media batch tasks, which no other download uses.
const mediaBatchGroup = 'media_batch';

/// Cancels the batch tasks and deletes the batch files an earlier run of the
/// app left behind: a task the OS kept after the app was killed would
/// otherwise still run, with the token of then, even after a logout. Run it
/// once per app process, before any batch: the reset also drops the tasks of
/// this process without settling them.
Future<void> clearLeftoverMediaBatches({
  ResetDownloadGroupFn? reset,
  Future<String> Function()? tempDir,
}) async {
  final resetGroup = reset ?? (group) => FileDownloader().reset(group: group);
  try {
    await resetGroup(mediaBatchGroup);
    final leftovers = Directory(
      p.join(await (tempDir ?? _tempDir)(), _batchDir),
    );
    if (await leftovers.exists()) await leftovers.delete(recursive: true);
  } catch (e) {
    // Batches still run; their own files are deleted once read.
    logger.w('Leftover media batches not cleared: $e');
  }
}

const _batchDir = 'media_batches';

Future<String> _tempDir() async => (await getTemporaryDirectory()).path;

/// How many saved batch responses are read at once; the reading runs on the
/// UI isolate.
const mediaBatchReadConcurrency = 4;

/// First wait between cancels of a batch task; it doubles up to
/// [mediaBatchCancelMaxDelay]. A cancel can miss a task still on its way to
/// the OS, which enqueues and cancels concurrently (Android then answers
/// false, iOS still true), so cancels repeat until the task is over.
const mediaBatchCancelRetryDelay = Duration(milliseconds: 100);
const mediaBatchCancelMaxDelay = Duration(seconds: 2);

/// A [CancellableMediaBatchFn] whose requests the OS carries on while the app
/// is in the background. Each response is saved to a file under [tempDir] and
/// read once complete, [mediaBatchReadConcurrency] at a time. Batches start
/// once [ready] (the [clearLeftoverMediaBatches] of this process) is done.
CancellableMediaBatchFn backgroundMediaBatchDownloader({
  required Future<void> ready,
  RunDownloadTaskFn? run,
  CancelDownloadTaskFn? cancel,
  Future<String> Function()? tempDir,
}) {
  final runTask = run ?? (task) => FileDownloader().download(task);
  final cancelTask = cancel ?? (id) => FileDownloader().cancelTaskWithId(id);
  final dirOf = tempDir ?? _tempDir;
  var reading = 0;
  final waiting = Queue<Completer<void>>();
  return (mediaKeys, onPart, cancelled) async {
    String? taskId;
    var isCancelled = false;
    var finished = false;
    unawaited(
      cancelled.then((_) async {
        isCancelled = true;
        final id = taskId;
        if (id == null) return;
        var delay = mediaBatchCancelRetryDelay;
        while (!finished) {
          try {
            await cancelTask(id);
          } catch (e) {
            logger.w('Media batch cancel failed: $e');
          }
          await Future<void>.delayed(delay);
          delay = Duration(
            milliseconds: min(
              delay.inMilliseconds * 2,
              mediaBatchCancelMaxDelay.inMilliseconds,
            ),
          );
        }
      }),
    );
    await ready;
    final dir = p.join(await dirOf(), _batchDir);
    final task = DownloadTask(
      url: '${networkDioClient.dio.options.baseUrl}${Api.mediaBatch}',
      headers: {
        for (final MapEntry(:key, :value) in ApiService.buildHeaders(
          null,
        ).entries)
          key: '$value',
      },
      post: jsonEncode(mediaBatchRequest(mediaKeys)),
      baseDirectory: BaseDirectory.root,
      directory: dir,
      group: mediaBatchGroup,
    );
    if (isCancelled) throw StateError('media batch cancelled');
    taskId = task.taskId;
    // The task keeps the directory relative to the root.
    final file = File(p.join(dir, task.filename));
    try {
      final TaskStatusUpdate update;
      try {
        update = await runTask(task);
      } finally {
        finished = true;
      }
      if (update.status != TaskStatus.complete) {
        final code = switch (update.exception) {
          TaskHttpException(:final httpResponseCode) => httpResponseCode,
          _ => null,
        };
        // A 404 ends as notFound, without an exception on iOS and desktop.
        if (update.status == TaskStatus.notFound || code == 405) {
          throw const MediaBatchUnsupported();
        }
        throw StateError('media batch ${update.status}: ${update.exception}');
      }
      if (reading < mediaBatchReadConcurrency) {
        reading++;
      } else {
        final turn = Completer<void>();
        waiting.add(turn);
        await turn.future;
      }
      try {
        if (isCancelled) throw StateError('media batch cancelled');
        await readMediaBatch(
          file.openRead(),
          update.responseHeaders?['content-type'] ?? '',
          onPart,
        );
      } finally {
        // Hands the turn to the next batch, if any waits.
        if (waiting.isNotEmpty) {
          waiting.removeFirst().complete();
        } else {
          reading--;
        }
      }
    } finally {
      if (await file.exists()) await file.delete();
    }
  };
}
