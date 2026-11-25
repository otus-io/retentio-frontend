import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:retentio/core/network/dio_client.dart';
import 'package:retentio/features/offline_learning/data/background_media_batch.dart';
import 'package:retentio/features/offline_learning/data/remote_offline_package_data_source.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tmp;
  late List<DownloadTask> tasks;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('media_batch');
    tasks = [];
    SharedPreferences.setMockInitialValues({});
    await ApiService.setToken('tok');
    networkDioClient.configure(
      baseUrl: 'http://localhost',
      options: BaseOptions(),
    );
  });

  tearDown(() async {
    await ApiService.clearToken();
    await tmp.delete(recursive: true);
  });

  /// Where the OS saves a [BaseDirectory.root] task.
  String savedPath(DownloadTask task) =>
      p.join('/', task.directory, task.filename);

  /// Saves [body] as the task's response, then answers [status].
  RunDownloadTaskFn serve(
    String body, {
    TaskStatus status = TaskStatus.complete,
    TaskException? exception,
    Map<String, String>? headers = const {
      'content-type': 'multipart/mixed; boundary=b',
    },
  }) => (task) async {
    tasks.add(task);
    await File(savedPath(task)).create(recursive: true);
    await File(savedPath(task)).writeAsString(body);
    return TaskStatusUpdate(task, status, exception, null, headers);
  };

  Future<List<(String, String?)>> fetch(
    RunDownloadTaskFn run, {
    Future<void>? cancelled,
    CancelDownloadTaskFn? cancel,
    Future<void>? ready,
    Future<String> Function()? tempDir,
    Future<void> Function(Duration)? wait,
  }) async {
    final parts = <(String, String?)>[];
    await backgroundMediaBatchDownloader(
      ready: ready ?? Future.value(),
      run: run,
      cancel: cancel,
      tempDir: tempDir ?? () async => tmp.path,
      wait: wait,
    )(['m1?v=7', 'm2'], (key, bytes) async {
      parts.add((
        key,
        bytes == null
            ? null
            : utf8.decode(await bytes.expand((c) => c).toList()),
      ));
    }, cancelled ?? Completer<void>().future);
    return parts;
  }

  const body =
      '--b\r\nX-Media-Id: m1\r\nX-Media-Version: 7\r\nX-Media-Status: 200\r\n'
      'Content-Length: 3\r\n\r\nabc\r\n'
      '--b\r\nX-Media-Id: m2\r\nX-Media-Status: 404\r\n\r\n\r\n'
      '--b--\r\n';

  test('posts the keys and reads the saved response', () async {
    final parts = await fetch(serve(body));

    expect(parts, [('m1?v=7', 'abc'), ('m2', null)]);
    final task = tasks.single;
    expect(task.url, 'http://localhost/api/media/batch');
    expect(task.headers['Authorization'], 'Bearer tok');
    expect(task.headers['Content-Type'], 'application/json');
    expect(jsonDecode(task.post as String), {
      'items': [
        {'id': 'm1', 'v': 7},
        {'id': 'm2'},
      ],
    });
    expect(task.baseDirectory, BaseDirectory.root);
    expect(task.group, mediaBatchGroup);
    expect(savedPath(task), startsWith(p.join(tmp.path, 'media_batches')));
    expect(File(savedPath(task)).existsSync(), isFalse);
  });

  test('a batch waits until the leftovers are cleared', () async {
    final ready = Completer<void>();
    final result = fetch(serve(body), ready: ready.future);
    await Future<void>.delayed(Duration.zero);
    expect(tasks, isEmpty);

    ready.complete();

    expect(await result, [('m1?v=7', 'abc'), ('m2', null)]);
  });

  test('clears the tasks and files an earlier run left', () async {
    final leftover = File(p.join(tmp.path, 'media_batches', 'old'));
    await leftover.create(recursive: true);
    final resets = <String>[];

    await clearLeftoverMediaBatches(
      reset: (group) async {
        resets.add(group);
        return 1;
      },
      tempDir: () async => tmp.path,
    );

    expect(resets, [mediaBatchGroup]);
    expect(leftover.existsSync(), isFalse);
  });

  test('clearing without leftover files only resets the group', () async {
    var resets = 0;

    await clearLeftoverMediaBatches(
      reset: (_) async => ++resets,
      tempDir: () async => tmp.path,
    );

    expect(resets, 1);
  });

  test('a failing clear is not thrown', () async {
    await clearLeftoverMediaBatches(
      reset: (_) async => throw StateError('reset failed'),
      tempDir: () async => tmp.path,
    );
  });

  for (final (name, status, exception) in [
    ('a 404 answer (iOS, desktop)', TaskStatus.notFound, null),
    (
      'a 404 answer (Android)',
      TaskStatus.notFound,
      TaskHttpException('no', 404),
    ),
    ('a 405 answer', TaskStatus.failed, TaskHttpException('no', 405)),
  ]) {
    test('$name means no batch endpoint', () async {
      await expectLater(
        fetch(serve('', status: status, exception: exception)),
        throwsA(isA<MediaBatchUnsupported>()),
      );
      expect(File(savedPath(tasks.single)).existsSync(), isFalse);
    });
  }

  for (final (name, exception) in [
    ('another http error', TaskHttpException('boom', 500)),
    ('a connection error', TaskConnectionException('lost')),
    ('no error', null),
  ]) {
    test('a failed task with $name throws', () async {
      await expectLater(
        fetch(serve('', status: TaskStatus.failed, exception: exception)),
        throwsStateError,
      );
    });
  }

  test('a response without a content type throws', () async {
    await expectLater(fetch(serve(body, headers: null)), throwsStateError);
    expect(File(savedPath(tasks.single)).existsSync(), isFalse);
  });

  test('cancelling stops the running task', () async {
    final cancelled = Completer<void>();
    final cancelledIds = <String>[];
    final stopped = Completer<void>();
    final result = fetch(
      (task) async {
        tasks.add(task);
        cancelled.complete();
        await stopped.future;
        return TaskStatusUpdate(task, TaskStatus.canceled);
      },
      cancelled: cancelled.future,
      cancel: (id) async {
        cancelledIds.add(id);
        stopped.complete();
        return true;
      },
    );

    await expectLater(result, throwsStateError);
    expect(cancelledIds, [tasks.single.taskId]);
  });

  test('a cancel the OS does not know yet is retried', () async {
    final cancelled = Completer<void>();
    final stopped = Completer<void>();
    var cancels = 0;
    final result = fetch(
      (task) async {
        cancelled.complete();
        await stopped.future;
        return TaskStatusUpdate(task, TaskStatus.canceled);
      },
      cancelled: cancelled.future,
      cancel: (_) async {
        // The first cancel arrives before the OS has the task.
        if (++cancels == 1) return false;
        stopped.complete();
        return true;
      },
    );

    await expectLater(result, throwsStateError);
    expect(cancels, 2);
  });

  test('a cancel that misses is repeated until the task ends', () async {
    final cancelled = Completer<void>();
    final stopped = Completer<void>();
    final waits = <Duration>[];
    var cancels = 0;
    final result = fetch(
      (task) async {
        cancelled.complete();
        await stopped.future;
        return TaskStatusUpdate(task, TaskStatus.canceled);
      },
      cancelled: cancelled.future,
      cancel: (_) async {
        // iOS answers true even when the task has not reached it yet.
        if (++cancels == 3) stopped.complete();
        return true;
      },
      wait: (delay) async {
        waits.add(delay);
        await Future<void>.delayed(Duration.zero);
      },
    );

    await expectLater(result, throwsStateError);
    await pumpEventQueue();
    expect(cancels, 3);
    expect(waits.take(2), [
      mediaBatchCancelRetryDelay,
      mediaBatchCancelRetryDelay * 2,
    ]);
  });

  test('cancels back off to the cap and stop after the last try', () async {
    final cancelled = Completer<void>();
    final stopped = Completer<void>();
    final waits = <Duration>[];
    var cancels = 0;
    final result = fetch(
      (task) async {
        cancelled.complete();
        await stopped.future;
        return TaskStatusUpdate(task, TaskStatus.complete);
      },
      cancelled: cancelled.future,
      cancel: (_) async {
        cancels++;
        return false;
      },
      wait: (delay) async => waits.add(delay),
    );

    await pumpEventQueue();
    expect(cancels, mediaBatchCancelTries);
    expect(waits, [
      for (var ms = 100; ms < 2000; ms *= 2) Duration(milliseconds: ms),
      for (var i = 0; i < mediaBatchCancelTries - 6; i++)
        mediaBatchCancelMaxDelay,
    ]);
    stopped.complete();
    await expectLater(result, throwsStateError);
    expect(cancels, mediaBatchCancelTries);
  });

  test('a finished task is not cancelled again', () async {
    final cancelled = Completer<void>();
    final stopped = Completer<void>();
    var cancels = 0;
    final result = fetch(
      (task) async {
        cancelled.complete();
        await stopped.future;
        return TaskStatusUpdate(task, TaskStatus.canceled);
      },
      cancelled: cancelled.future,
      cancel: (_) async {
        cancels++;
        // The task ends on its own before the retry.
        if (!stopped.isCompleted) stopped.complete();
        return false;
      },
    );

    await expectLater(result, throwsStateError);
    await Future<void>.delayed(mediaBatchCancelRetryDelay * 2);
    expect(cancels, 1);
  });

  test('a failing cancel is not thrown', () async {
    final cancelled = Completer<void>();
    final stopped = Completer<void>();

    await expectLater(
      fetch(
        (task) async {
          cancelled.complete();
          await stopped.future;
          return TaskStatusUpdate(task, TaskStatus.canceled);
        },
        cancelled: cancelled.future,
        cancel: (_) async {
          stopped.complete();
          throw StateError('cancel failed');
        },
      ),
      throwsStateError,
    );
  });

  test('a failing cancel is retried', () async {
    final cancelled = Completer<void>();
    final stopped = Completer<void>();
    var cancels = 0;
    final result = fetch(
      (task) async {
        cancelled.complete();
        await stopped.future;
        return TaskStatusUpdate(task, TaskStatus.canceled);
      },
      cancelled: cancelled.future,
      cancel: (_) async {
        if (++cancels == 1) throw StateError('cancel failed');
        stopped.complete();
        return true;
      },
    );

    await expectLater(result, throwsStateError);
    expect(cancels, 2);
  });

  test('a batch cancelled before its task starts never runs it', () async {
    final cancelled = Completer<void>();
    var cancels = 0;

    await expectLater(
      fetch(
        (task) async => fail('must not run'),
        cancelled: cancelled.future,
        cancel: (_) async => ++cancels > 0,
        tempDir: () async {
          cancelled.complete();
          await Future<void>.delayed(Duration.zero);
          return tmp.path;
        },
      ),
      throwsStateError,
    );
    expect(cancels, 0);
  });

  test('reads at most $mediaBatchReadConcurrency responses at once', () async {
    final full = Completer<void>();
    final lateDownloaded = Completer<void>();
    final served = serve(body);
    final fetchBatch = backgroundMediaBatchDownloader(
      ready: Future.value(),
      // The batch of m3 is in only once every turn to read is taken.
      run: (task) async {
        if (!(task.post as String).contains('m3')) return served(task);
        await full.future;
        final update = await served(task);
        lateDownloaded.complete();
        return update;
      },
      tempDir: () async => tmp.path,
    );
    final gate = Completer<void>();
    var reading = 0;
    var most = 0;
    final batches = [
      for (var i = 0; i < mediaBatchReadConcurrency + 1; i++)
        fetchBatch(['m1?v=7', 'm2'], (key, bytes) async {
          if (key != 'm1?v=7') return;
          most = max(most, ++reading);
          if (reading == mediaBatchReadConcurrency) full.complete();
          await gate.future;
          await bytes!.drain<void>();
          reading--;
        }, Completer<void>().future),
    ];
    final lateCancel = Completer<void>();
    var lateRead = false;
    final refused = expectLater(
      fetchBatch(['m3'], (_, _) async => lateRead = true, lateCancel.future),
      throwsStateError,
    );
    await lateDownloaded.future;
    // The readers hold every turn, so m3 can only join the wait queue.
    await pumpEventQueue();

    // A batch cancelled while waiting for its turn is not read.
    lateCancel.complete();
    gate.complete();
    await Future.wait(batches);
    await refused;

    expect(most, mediaBatchReadConcurrency);
    expect(lateRead, isFalse);
    expect(tasks, hasLength(mediaBatchReadConcurrency + 2));
    for (final task in tasks) {
      expect(File(savedPath(task)).existsSync(), isFalse);
    }
  });

  test('by default the OS downloader runs it in the temp directory', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(pathProvider, (_) async => tmp.path);
    const native = MethodChannel('com.bbflight.background_downloader');
    // Refuses every task, so the download fails at once.
    messenger.setMockMethodCallHandler(native, (_) async => false);
    addTearDown(() {
      messenger.setMockMethodCallHandler(pathProvider, null);
      messenger.setMockMethodCallHandler(native, null);
    });

    await expectLater(
      backgroundMediaBatchDownloader(ready: Future.value())(
        ['m1'],
        (_, _) async {},
        Completer<void>().future,
      ),
      throwsStateError,
    );
  });

  test('by default the OS downloader cancels the task', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(pathProvider, (_) async => tmp.path);
    const native = MethodChannel('com.bbflight.background_downloader');
    final cancelled = Completer<void>();
    // Cancelled while the task is being enqueued, which then is refused.
    messenger.setMockMethodCallHandler(native, (call) async {
      if (call.method == 'enqueue') {
        cancelled.complete();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return false;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(pathProvider, null);
      messenger.setMockMethodCallHandler(native, null);
    });

    await expectLater(
      backgroundMediaBatchDownloader(ready: Future.value())(
        ['m1'],
        (_, _) async {},
        cancelled.future,
      ),
      throwsStateError,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}
