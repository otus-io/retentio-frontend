import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';
import 'storage_exception.dart';

/// Simple in-memory cache per storage instance to avoid losing the latest
/// state while the async storage write is still in flight. Namespaced by the
/// current storage token to avoid cross-contamination when swapping storage
/// instances in tests or apps.
final Map<int, Map<String, Map<String, dynamic>>> _inMemoryCache = {};

int _storageToken = 0;

@internal
Map<String, dynamic>? readFromCache(String key) =>
    _inMemoryCache[_storageToken]?[key];

@internal
void writeToCache(String key, Map<String, dynamic> value) {
  final scopedCache = _inMemoryCache.putIfAbsent(_storageToken, () => {});
  scopedCache[key] = value;
}

@internal
void removeFromCache(String key) {
  final scopedCache = _inMemoryCache[_storageToken];
  if (scopedCache == null) return;

  scopedCache.remove(key);
  if (scopedCache.isEmpty) {
    _inMemoryCache.remove(_storageToken);
  }
}

@internal
void clearCache() {
  _inMemoryCache.remove(_storageToken);
}

@internal
void clearAllCache() => _inMemoryCache.clear();

/// Storage interface for persisting and retrieving state
abstract class HydratedStorage {
  /// Returns singleton instance of [HydratedStorage]
  static HydratedStorage? get instance => _instance;
  static HydratedStorage? _instance;

  /// Sets the singleton instance of [HydratedStorage]
  static set instance(HydratedStorage? storage) {
    _instance = storage;
    _storageToken++;
    clearAllCache();
  }

  /// Writes [value] to storage for the given [key]
  Future<void> write(String key, dynamic value);

  /// Reads value from storage for the given [key]
  dynamic read(String key);

  /// Deletes value from storage for the given [key]
  Future<void> delete(String key);

  /// Clears all values from storage
  Future<void> clear();

  /// Closes the storage instance
  Future<void> close();
}

/// Hive implementation of [HydratedStorage]
class HiveHydratedStorage implements HydratedStorage {
  @visibleForTesting
  HiveHydratedStorage(this.box);

  /// Initializes storage with Hive
  ///
  /// Set [encrypted] to `true` to enable AES-256 encryption.
  /// When enabled, you must provide an [encryptionKey] (32 bytes).
  ///
  /// ```dart
  /// // Generate a key once and store it securely
  /// final key = Hive.generateSecureKey();
  ///
  /// final storage = await HiveHydratedStorage.build(
  ///   storageDirectory: appDir.path,
  ///   encrypted: true,
  ///   encryptionKey: key,
  /// );
  /// ```
  ///
  /// **Important**: Store the encryption key securely (e.g., using
  /// `flutter_secure_storage`). If the key is lost, the data cannot be
  /// recovered.
  static Future<HiveHydratedStorage> build({
    required String storageDirectory,
    String boxName = 'hydrated_box',
    bool encrypted = false,
    List<int>? encryptionKey,
  }) async {
    if (encrypted && encryptionKey == null) {
      throw ArgumentError(
        'encryptionKey is required when encrypted is true. '
        'Use Hive.generateSecureKey() to generate a 32-byte key.',
      );
    }

    if (!Hive.isBoxOpen(boxName)) {
      Hive.init(storageDirectory);
    }

    final cipher = encrypted ? HiveAesCipher(encryptionKey!) : null;
    final box = await Hive.openBox<dynamic>(
      boxName,
      encryptionCipher: cipher,
    );
    return HiveHydratedStorage(box);
  }

  final Box<dynamic> box;
  final _lock = Lock();

  @override
  dynamic read(String key) {
    try {
      return box.get(key);
    } catch (error, stackTrace) {
      throw StorageException('Failed to read key: $key', error, stackTrace);
    }
  }

  @override
  Future<void> write(String key, dynamic value) async {
    return _lock.synchronized(() async {
      try {
        await box.put(key, value);
      } catch (error, stackTrace) {
        throw StorageException('Failed to write key: $key', error, stackTrace);
      }
    });
  }

  @override
  Future<void> delete(String key) async {
    return _lock.synchronized(() async {
      try {
        await box.delete(key);
      } catch (error, stackTrace) {
        throw StorageException('Failed to delete key: $key', error, stackTrace);
      }
    });
  }

  @override
  Future<void> clear() async {
    clearCache();
    return _lock.synchronized(() async {
      try {
        await box.clear();
      } catch (error, stackTrace) {
        throw StorageException('Failed to clear storage', error, stackTrace);
      }
    });
  }

  @override
  Future<void> close() async {
    await box.close();
  }
}
