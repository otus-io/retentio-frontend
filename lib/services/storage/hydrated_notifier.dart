import 'dart:async';
import 'dart:developer' as developer;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

import 'hydrated_storage.dart';
import 'storage_exception.dart';

/// {@template hydrated_mixin}
/// Mixin that enables automatic state persistence and restoration for Riverpod notifiers.
///
/// This mixin provides automatic saving and loading of state using a configurable storage backend.
/// By default, it uses Hive as the storage mechanism, but can be extended to use other storage solutions.
///
/// Example usage:
/// ```dart
/// class CounterNotifier extends HydratedNotifier<int> {
///   @override
///   int build() => hydrate() ?? 0;
///
///   void increment() => state++;
///
///   @override
///   Map<String, dynamic>? toJson(int state) => {'value': state};
///
///   @override
///   int? fromJson(Map<String, dynamic> json) => json['value'] as int?;
/// }
/// ```
/// {@endtemplate}
mixin HydratedMixinBase<State> on Notifier<State> {
  /// Storage key for this notifier.
  /// Customize via [storageKeySuffix] or override this getter entirely.
  @protected
  String get storageKey {
    final suffix = storageKeySuffix;
    if (suffix == null || suffix.isEmpty) return baseStorageKey;
    return '$baseStorageKey$storageKeySeparator$suffix';
  }

  /// Base part of the storage key. Override if you want something other than runtimeType.
  @protected
  String get baseStorageKey => runtimeType.toString();

  /// Separator used between base key and suffix.
  @protected
  String get storageKeySeparator => ':';

  /// Optional suffix to differentiate multiple instances of the same notifier.
  @protected
  String? get storageKeySuffix => null;

  /// Converts state to JSON
  @protected
  Map<String, dynamic>? toJson(State state);

  /// Converts JSON to state
  @protected
  State? fromJson(Map<String, dynamic> json);

  /// Current version of the state structure.
  ///
  /// Increment this number when making breaking changes to your state structure.
  /// When a stored state has an older version, [migrate] will be called automatically.
  ///
  /// Defaults to 1.
  @protected
  int get version => 1;

  /// Migrates state data from an older version to the current [version].
  ///
  /// This method is called automatically when loading persisted state
  /// that was saved with an older version number.
  ///
  /// Return null if migration fails or the data is incompatible.
  /// The default implementation returns the json unchanged (no migration).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// int get version => 2;
  ///
  /// @override
  /// Map<String, dynamic>? migrate(Map<String, dynamic> json, int fromVersion) {
  ///   if (fromVersion == 1) {
  ///     // Migration from v1 to v2: rename 'count' field to 'value'
  ///     return {'value': json['count']};
  ///   }
  ///   return json;
  /// }
  /// ```
  @protected
  Map<String, dynamic>? migrate(Map<String, dynamic> json, int fromVersion) {
    return json; // Default: no migration, return as-is
  }

  /// Debounce duration for persistence. Defaults to immediate write.
  @protected
  Duration get writeDebounce => Duration.zero;

  /// Hook invoked after a successful persist; override to log/trace.
  @protected
  void onPersist(Map<String, dynamic> json) {}

  Timer? _debounceTimer;
  Map<String, dynamic>? _pendingPersist;
  bool _disposeRegistered = false;
  static const _equality = DeepCollectionEquality();

  void _registerDispose() {
    if (_disposeRegistered) return;
    _disposeRegistered = true;
    ref.onDispose(() async {
      _debounceTimer?.cancel();
      final payload = _pendingPersist;
      _pendingPersist = null;
      if (payload != null) {
        await _flushPendingAsync(payload);
      }
    });
  }

  /// Attempts to restore persisted state and ensures pending writes flush on dispose.
  /// Returns null when there is no saved state.
  @protected
  State? hydrate() {
    _registerDispose();
    return _loadState();
  }

  State? _loadState() {
    try {
      final cached = readFromCache(storageKey);
      if (cached != null) {
        return _deserializeWithMigration(Map<String, dynamic>.from(cached));
      }

      final json = _storage.read(storageKey);
      if (json == null) return null;
      if (json is Map) {
        final mapped = Map<String, dynamic>.from(json);
        final state = _deserializeWithMigration(mapped);
        // Cache the (possibly migrated) state
        if (state != null) {
          final serialized = toJson(state);
          if (serialized != null) {
            writeToCache(storageKey, serialized);
          }
        }
        return state;
      }
      return null;
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      return null;
    }
  }

  State? _deserializeWithMigration(Map<String, dynamic> json) {
    // Check for stored version (defaults to 1 if not present)
    final storedVersion = json['__version__'] as int? ?? 1;
    final currentVersion = version;

    var dataToDeserialize = json;

    // Perform migration if needed
    if (storedVersion < currentVersion) {
      final migrated = migrate(json, storedVersion);
      if (migrated == null) {
        // Migration failed
        return null;
      }
      dataToDeserialize = migrated;
    }

    return fromJson(dataToDeserialize);
  }

  void _flushPending(Map<String, dynamic> payload) {
    try {
      writeToCache(storageKey, payload);
      _storage.write(storageKey, payload);
      onPersist(payload);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  Future<void> _flushPendingAsync(Map<String, dynamic> payload) async {
    try {
      writeToCache(storageKey, payload);
      await _storage.write(storageKey, payload);
      onPersist(payload);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  void _saveState(State state) {
    try {
      _registerDispose();
      final json = toJson(state);
      if (json == null) return;

      final mapped = Map<String, dynamic>.from(json as Map);
      // Add version metadata
      mapped['__version__'] = version;

      final previous = readFromCache(storageKey);
      if (previous != null && _equality.equals(previous, mapped)) {
        return;
      }

      final debounce = writeDebounce;
      _pendingPersist = mapped;

      if (debounce == Duration.zero) {
        _pendingPersist = null;
        _flushPending(mapped);
        return;
      }

      writeToCache(storageKey, mapped);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounce, () {
        final payload = _pendingPersist;
        _pendingPersist = null;
        if (payload != null) {
          _flushPending(payload);
        }
      });
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  @override
  set state(State value) {
    final previous = super.state;
    super.state = value;

    if (updateShouldNotify(previous, value)) {
      _saveState(value);
    }
  }

  @override
  @protected
  bool updateShouldNotify(State previous, State next) => previous != next;

  /// Called when an error occurs during serialization/deserialization
  @protected
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) {
    developer.log(
      'HydratedRiverpod error: $error',
      name: 'HydratedRiverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Clears the persisted state
  Future<void> clear() async {
    removeFromCache(storageKey);
    await _storage.delete(storageKey);
  }

  HydratedStorage get _storage;
}

mixin HydratedMixin<State> on HydratedMixinBase<State> {
  @override
  HydratedStorage get _storage {
    final storage = HydratedStorage.instance;
    if (storage == null) {
      throw const StorageException(
        'HydratedStorage is not initialized. '
        'Please call HydratedStorage.instance = storage before using HydratedMixin',
      );
    }
    return storage;
  }
}

/// Base class for hydrated notifiers with Notifier
abstract class HydratedNotifier<State> extends Notifier<State>
    with HydratedMixinBase<State>, HydratedMixin<State> {}

// ============================================================================
// AutoDispose Support
// ============================================================================

/// Mixin for auto-dispose notifiers with hydration support.
///
/// Note: In Riverpod 3.x, "AutoDispose" is a property of the provider, not the notifier.
/// Both regular and auto-dispose notifiers use the same Notifier base class.
/// This mixin is identical to HydratedMixinBase but kept separate for clarity.
mixin AutoDisposeHydratedMixin<State> on Notifier<State> {
  /// Storage key for this notifier.
  /// Customize via [storageKeySuffix] or override this getter entirely.
  @protected
  String get storageKey {
    final suffix = storageKeySuffix;
    if (suffix == null || suffix.isEmpty) return baseStorageKey;
    return '$baseStorageKey$storageKeySeparator$suffix';
  }

  /// Base part of the storage key. Override if you want something other than runtimeType.
  @protected
  String get baseStorageKey => runtimeType.toString();

  /// Separator used between base key and suffix.
  @protected
  String get storageKeySeparator => ':';

  /// Optional suffix to differentiate multiple instances of the same notifier.
  @protected
  String? get storageKeySuffix => null;

  /// Converts state to JSON
  @protected
  Map<String, dynamic>? toJson(State state);

  /// Converts JSON to state
  @protected
  State? fromJson(Map<String, dynamic> json);

  /// Current version of the state structure.
  ///
  /// Increment this number when making breaking changes to your state structure.
  /// When a stored state has an older version, [migrate] will be called automatically.
  ///
  /// Defaults to 1.
  @protected
  int get version => 1;

  /// Migrates state data from an older version to the current [version].
  ///
  /// This method is called automatically when loading persisted state
  /// that was saved with an older version number.
  ///
  /// Return null if migration fails or the data is incompatible.
  /// The default implementation returns the json unchanged (no migration).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// int get version => 2;
  ///
  /// @override
  /// Map<String, dynamic>? migrate(Map<String, dynamic> json, int fromVersion) {
  ///   if (fromVersion == 1) {
  ///     // Migration from v1 to v2: rename 'count' field to 'value'
  ///     return {'value': json['count']};
  ///   }
  ///   return json;
  /// }
  /// ```
  @protected
  Map<String, dynamic>? migrate(Map<String, dynamic> json, int fromVersion) {
    return json; // Default: no migration, return as-is
  }

  /// Debounce duration for persistence. Defaults to immediate write.
  @protected
  Duration get writeDebounce => Duration.zero;

  /// Hook invoked after a successful persist; override to log/trace.
  @protected
  void onPersist(Map<String, dynamic> json) {}

  Timer? _debounceTimer;
  Map<String, dynamic>? _pendingPersist;
  bool _disposeRegistered = false;
  static const _equality = DeepCollectionEquality();

  void _registerDispose() {
    if (_disposeRegistered) return;
    _disposeRegistered = true;
    ref.onDispose(() async {
      _debounceTimer?.cancel();
      final payload = _pendingPersist;
      _pendingPersist = null;
      if (payload != null) {
        await _flushPendingAsync(payload);
      }
    });
  }

  /// Attempts to restore persisted state and ensures pending writes flush on dispose.
  /// Returns null when there is no saved state.
  @protected
  State? hydrate() {
    _registerDispose();
    return _loadState();
  }

  State? _loadState() {
    try {
      final cached = readFromCache(storageKey);
      if (cached != null) {
        return _deserializeWithMigration(Map<String, dynamic>.from(cached));
      }

      final json = _storage.read(storageKey);
      if (json == null) return null;
      if (json is Map) {
        final mapped = Map<String, dynamic>.from(json);
        final state = _deserializeWithMigration(mapped);
        // Cache the (possibly migrated) state
        if (state != null) {
          final serialized = toJson(state);
          if (serialized != null) {
            writeToCache(storageKey, serialized);
          }
        }
        return state;
      }
      return null;
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      return null;
    }
  }

  State? _deserializeWithMigration(Map<String, dynamic> json) {
    // Check for stored version (defaults to 1 if not present)
    final storedVersion = json['__version__'] as int? ?? 1;
    final currentVersion = version;

    var dataToDeserialize = json;

    // Perform migration if needed
    if (storedVersion < currentVersion) {
      final migrated = migrate(json, storedVersion);
      if (migrated == null) {
        // Migration failed
        return null;
      }
      dataToDeserialize = migrated;
    }

    return fromJson(dataToDeserialize);
  }

  void _flushPending(Map<String, dynamic> payload) {
    try {
      writeToCache(storageKey, payload);
      _storage.write(storageKey, payload);
      onPersist(payload);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  Future<void> _flushPendingAsync(Map<String, dynamic> payload) async {
    try {
      writeToCache(storageKey, payload);
      await _storage.write(storageKey, payload);
      onPersist(payload);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  void _saveState(State state) {
    try {
      _registerDispose();
      final json = toJson(state);
      if (json == null) return;

      final mapped = Map<String, dynamic>.from(json as Map);
      // Add version metadata
      mapped['__version__'] = version;

      final previous = readFromCache(storageKey);
      if (previous != null && _equality.equals(previous, mapped)) {
        return;
      }

      final debounce = writeDebounce;
      _pendingPersist = mapped;

      if (debounce == Duration.zero) {
        _pendingPersist = null;
        _flushPending(mapped);
        return;
      }

      writeToCache(storageKey, mapped);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounce, () {
        final payload = _pendingPersist;
        _pendingPersist = null;
        if (payload != null) {
          _flushPending(payload);
        }
      });
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  @override
  set state(State value) {
    final previous = super.state;
    super.state = value;

    if (updateShouldNotify(previous, value)) {
      _saveState(value);
    }
  }

  @override
  @protected
  bool updateShouldNotify(State previous, State next) => previous != next;

  /// Called when an error occurs during serialization/deserialization
  @protected
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) {
    developer.log(
      'HydratedRiverpod error: $error',
      name: 'HydratedRiverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Clears the persisted state
  Future<void> clear() async {
    removeFromCache(storageKey);
    await _storage.delete(storageKey);
  }

  HydratedStorage get _storage {
    final storage = HydratedStorage.instance;
    if (storage == null) {
      throw const StorageException('HydratedStorage is not initialized.');
    }
    return storage;
  }
}

/// Base class for auto-dispose hydrated notifiers.
///
/// Use this with NotifierProvider to create auto-dispose providers:
/// ```dart
/// final provider = NotifierProvider<MyNotifier, int>(MyNotifier.new);
/// ```
abstract class AutoDisposeHydratedNotifier<State> extends Notifier<State>
    with AutoDisposeHydratedMixin<State> {}
