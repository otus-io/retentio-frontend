import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

/// A [CancellableMediaBatchFn] whose requests the OS carries on while the app
/// is in the background. Each response is saved to a file under [tempDir] and
/// read once complete.
///
/// Before its first batch it cancels the tasks and deletes the files an
/// earlier run left behind: a task the OS kept after the app was killed would
/// otherwise still run, with the token of then, even after a logout.
CancellableMediaBatchFn backgroundMediaBatchDownloader({
  RunDownloadTaskFn? run,
  CancelDownloadTaskFn? cancel,
  ResetDownloadGroupFn? reset,
  Future<String> Function()? tempDir,
}) {
  final runTask = run ?? (task) => FileDownloader().download(task);
  final cancelTask = cancel ?? (id) => FileDownloader().cancelTaskWithId(id);
  final resetGroup = reset ?? (group) => FileDownloader().reset(group: group);
  final dirOf = tempDir ?? () async => (await getTemporaryDirectory()).path;
  Future<void>? leftoversCleared;
  Future<void> clearLeftovers(String dir) async {
    try {
      await resetGroup(mediaBatchGroup);
      final leftovers = Directory(dir);
      if (await leftovers.exists()) await leftovers.delete(recursive: true);
    } catch (e) {
      // Batches still run; their own files are deleted once read.
      logger.w('Leftover media batches not cleared: $e');
    }
  }

  return (mediaKeys, onPart, cancelled) async {
    String? taskId;
    var isCancelled = false;
    unawaited(
      cancelled.then((_) {
        isCancelled = true;
        if (taskId case final id?) {
          // A failed cancel leaves the task to finish; nothing waits on it.
          unawaited(cancelTask(id).then<void>((_) {}, onError: (_) {}));
        }
      }),
    );
    final dir = p.join(await dirOf(), 'media_batches');
    await (leftoversCleared ??= clearLeftovers(dir));
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
      final update = await runTask(task);
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
      await readMediaBatch(
        file.openRead(),
        update.responseHeaders?['content-type'] ?? '',
        onPart,
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  };
}
