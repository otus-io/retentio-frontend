import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/index.dart';

/// Offline study objects for one account.
class OfflineLearningSession {
  OfflineLearningSession({
    required this.accountId,
    required this.store,
    required this.downloader,
  });

  final String accountId;
  final OfflineLearningStore store;
  final OfflinePackageDownloader downloader;
}

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
  }) : _readUsername = readUsername ?? const LocalAuthDataSource().readUsername,
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
  final Map<String, Future<OfflineLearningSession>> _sessions = {};

  Future<OfflineLearningSession?> current() async {
    var name = await _readUsername();
    if (name == null || name.isEmpty) {
      name = await _fetchUsername();
      if (name == null || name.isEmpty) return null;
      await _saveUsername(name);
    }
    return _sessions[name] ??= _open(name);
  }

  Future<OfflineLearningSession> _open(String accountId) async {
    final store = await _openStore(accountId);
    final mediaRoot = p.join(await _documentsDir(), 'offline_media', accountId);
    return OfflineLearningSession(
      accountId: accountId,
      store: store,
      downloader: OfflinePackageDownloader(
        store: store,
        mediaRootDir: mediaRoot,
      ),
    );
  }

  static Future<OfflineLearningStore> _openHiveStore(String accountId) =>
      HiveOfflineLearningStore.open(accountId: accountId);

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
