import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/offline_learning/data/app_foreground.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/data/datasources/offline_store_cipher.dart';
import 'package:retentio/features/offline_learning/data/datasources/study_sync_remote_data_source.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/data/repositories/offline_first_deck_study_repository.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/utils/log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline study objects for one account.
class OfflineLearningSession {
  OfflineLearningSession({
    required this.accountId,
    required this.store,
    required this.downloader,
    required this.sync,
    required this.mediaRootDir,
    this.foreground,
  });

  final String accountId;
  final OfflineLearningStore store;
  final OfflinePackageDownloader downloader;
  final OfflineSyncService sync;
  final String mediaRootDir;

  /// App lifecycle the downloader listens to; owned by this session.
  final AppForeground? foreground;

  /// Stops the session's app and network listeners once it is closed.
  void dispose() {
    downloader.dispose();
    foreground?.dispose();
  }

  /// Deletes a deck's offline data and the media files no other downloaded
  /// deck uses, after stopping the deck's download and any upload.
  Future<void> removeDeck(String deckId) => downloader.whileHalted(
    deckId,
    () => sync.whilePaused(() => _removeDeck(deckId)),
  );

  Future<void> _removeDeck(String deckId) async {
    await store.removeDeck(deckId);
    await pruneUnusedMedia(store);
  }

  /// Stops running downloads and drops the ones paused for the app, keeping
  /// the data. Used when logging out with the data kept, so no download of
  /// this account resumes under the next account's login.
  Future<void> stopDownloads() => downloader.whileHalted(null, () async {});

  /// Deletes the account's offline data, unsynced reviews and media files,
  /// after stopping running downloads and uploads.
  Future<void> clear() => downloader.whileHalted(
    null,
    () => sync.whilePaused(() async {
      await store.clear();
      final dir = Directory(mediaRootDir);
      if (await dir.exists()) await dir.delete(recursive: true);
    }),
  );
}

/// Study repository that serves downloaded decks from [session], uploads
/// each local review through the session's sync queue, and re-downloads a
/// deck whose facts changed.
DeckStudyRepository offlineFirstStudyRepository(
  Future<OfflineLearningSession?> session, {
  required DeckStudyRepository remote,
  Future<bool> Function()? isOnline,
}) => OfflineFirstDeckStudyRepository(
  store: session.then((s) => s?.store),
  remote: remote,
  remoteMediaUrl: (id) => '${Env.host}/api/media/$id',
  onLocalChange: () => _runSessionTask(
    session,
    (s) => s.sync.flush(),
    'offline sync after review',
  ),
  refreshLocalCopy: (deckId) => _runSessionTask(
    session,
    (s) => s.downloader.download(deckId, fresh: true),
    'offline refresh after edit',
  ),
  isOnline: isOnline,
);

Future<void> _runSessionTask(
  Future<OfflineLearningSession?> session,
  Future<Object?> Function(OfflineLearningSession session) task,
  String label,
) => session
    .then<void>((s) => s == null ? null : task(s))
    .then<void>((_) {}, onError: (Object e) => logger.w('$label: $e'));

/// Resolves the [OfflineLearningSession] of the logged-in account, or null
/// when the account cannot be identified (never logged in since the username
/// was persisted, and offline).
class OfflineLearningSessions {
  OfflineLearningSessions({
    Future<String?> Function()? readUsername,
    Future<void> Function(String username)? saveUsername,
    Future<String?> Function()? fetchUsername,
    Future<OfflineLearningStore> Function(String accountId)? openStore,
    Future<String> Function()? documentsDir,
    Future<bool> Function()? isOnline,
    Stream<void> Function()? connectivityChanged,
  }) : _isOnline = isOnline ?? hasNetworkConnection,
       _connectivityChanged = connectivityChanged ?? onConnectivityChange,
       _readUsername = readUsername ?? const LocalAuthDataSource().readUsername,
       _saveUsername = saveUsername ?? const LocalAuthDataSource().saveUsername,
       _fetchUsername = fetchUsername ?? _fetchProfileUsername,
       _openStore = openStore ?? _openHiveStore,
       _documentsDir = documentsDir ?? _appDocumentsDir;

  static final OfflineLearningSessions instance = OfflineLearningSessions();

  final Future<String?> Function() _readUsername;
  final Future<void> Function(String username) _saveUsername;
  final Future<String?> Function() _fetchUsername;
  final Future<OfflineLearningStore> Function(String accountId) _openStore;
  final Future<String> Function() _documentsDir;
  final Future<bool> Function() _isOnline;
  final Stream<void> Function() _connectivityChanged;
  final Map<String, Future<OfflineLearningSession>> _sessions = {};
  final Map<String, Future<void>> _closing = {};

  /// [fetchMissingUsername] false skips the profile request when no username
  /// is stored (the session is then null), for callers that must not wait on
  /// the network.
  Future<OfflineLearningSession?> current({
    bool fetchMissingUsername = true,
  }) async {
    var name = await _readUsername();
    if (name == null || name.isEmpty) {
      if (!fetchMissingUsername) return null;
      name = await _fetchUsername();
      if (name == null || name.isEmpty) return null;
      await _saveUsername(name);
    }
    final opening = _sessions[name] ??= _open(name);
    final OfflineLearningSession session;
    try {
      session = await opening;
    } catch (_) {
      // Retry on the next call (e.g. the keychain was locked).
      if (identical(_sessions[name], opening)) _sessions.remove(name);
      rethrow;
    }
    // Another account logged in meanwhile and is closing this session.
    if (!identical(_sessions[name], opening)) return null;
    _closeOthers(name);
    await _finishPendingWipe(session);
    return session;
  }

  /// Deletes the logged-in account's offline data. The wipe is recorded
  /// first so a failure is retried before that account id is opened again
  /// (a deleted username can be registered by someone else).
  Future<void> wipeCurrentAccount() async {
    final name = await _readUsername();
    if (name == null || name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(pendingWipeKey) ?? const <String>[];
    if (!pending.contains(name)) {
      await prefs.setStringList(pendingWipeKey, [...pending, name]);
    }
    await current(fetchMissingUsername: false);
  }

  static const String pendingWipeKey = 'offline_pending_wipe';

  Future<void> _finishPendingWipe(OfflineLearningSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(pendingWipeKey) ?? const <String>[];
    if (!pending.contains(session.accountId)) return;
    await session.clear();
    await prefs.setStringList(
      pendingWipeKey,
      pending.where((id) => id != session.accountId).toList(),
    );
  }

  /// Another account is logged in now: stops the sessions of earlier ones in
  /// the background and disposes them, so none of their downloads or
  /// listeners stays. Their next login opens a new session.
  void _closeOthers(String accountId) {
    for (final id in [..._sessions.keys]) {
      if (id == accountId) continue;
      final closing = _close(id, _sessions.remove(id)!);
      _closing[id] = closing;
      unawaited(
        closing.whenComplete(() {
          if (identical(_closing[id], closing)) _closing.remove(id);
        }),
      );
    }
  }

  static Future<void> _close(
    String accountId,
    Future<OfflineLearningSession> opening,
  ) async {
    try {
      final session = await opening;
      await session.stopDownloads();
      session.dispose();
    } catch (e) {
      logger.w('Offline session of $accountId not closed: $e');
    }
  }

  Future<OfflineLearningSession> _open(String accountId) async {
    // A fresh login of a closing account waits until its old downloads stop.
    await _closing[accountId];
    final store = await _openStore(accountId);
    final mediaRoot = p.join(await _documentsDir(), 'offline_media', accountId);
    final foreground = AppForeground();
    return OfflineLearningSession(
      accountId: accountId,
      store: store,
      foreground: foreground,
      downloader: OfflinePackageDownloader(
        store: store,
        mediaRootDir: mediaRoot,
        isOnline: _isOnline,
        foreground: foreground,
        connectivityChanged: _connectivityChanged,
      ),
      sync: OfflineSyncService(
        store: store,
        remote: StudySyncRemoteDataSource(),
        isOnline: _isOnline,
        nowSec: () => DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      mediaRootDir: mediaRoot,
    );
  }

  static Future<OfflineLearningStore> _openHiveStore(String accountId) async =>
      HiveOfflineLearningStore.open(
        accountId: accountId,
        cipher: await offlineStoreCipher(),
      );

  static Future<String> _appDocumentsDir() async =>
      (await getApplicationDocumentsDirectory()).path;

  static Future<String?> _fetchProfileUsername() async {
    try {
      final data = (await ApiService.get(Api.profile))?.data;
      return data is Map ? data['username']?.toString() : null;
    } catch (_) {
      return null;
    }
  }
}
