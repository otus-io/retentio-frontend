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

typedef RunDownloadTaskFn =
    Future<TaskStatusUpdate> Function(DownloadTask task);

typedef CancelDownloadTaskFn = Future<bool> Function(String taskId);

/// A [CancellableMediaBatchFn] whose requests the OS carries on while the app
/// is in the background. Each response is saved to a file under [tempDir] and
/// read once complete.
CancellableMediaBatchFn backgroundMediaBatchDownloader({
  RunDownloadTaskFn? run,
  CancelDownloadTaskFn? cancel,
  Future<String> Function()? tempDir,
}) {
  final runTask = run ?? (task) => FileDownloader().download(task);
  final cancelTask = cancel ?? (id) => FileDownloader().cancelTaskWithId(id);
  final dirOf = tempDir ?? () async => (await getTemporaryDirectory()).path;
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
