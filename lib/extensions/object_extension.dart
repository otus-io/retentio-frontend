extension ObjectExtension on Object? {
  T asT<T>(T t) {
    return this as T? ?? t;
  }

  Map asMap() {
    return this is Map ? this as Map : {};
  }
}
