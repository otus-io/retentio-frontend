import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    Future<String> Function()? tempDir,
  }) async {
    final parts = <(String, String?)>[];
    await backgroundMediaBatchDownloader(
      run: run,
      cancel: cancel,
      tempDir: tempDir ?? () async => tmp.path,
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
    expect(savedPath(task), startsWith(p.join(tmp.path, 'media_batches')));
    expect(File(savedPath(task)).existsSync(), isFalse);
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
      backgroundMediaBatchDownloader()(
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
      backgroundMediaBatchDownloader()(
        ['m1'],
        (_, _) async {},
        cancelled.future,
      ),
      throwsStateError,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}
