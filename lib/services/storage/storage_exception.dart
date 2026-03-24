/// Exception thrown when storage operations fail
class StorageException implements Exception {
  const StorageException(this.message, [this.error, this.stackTrace]);

  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'StorageException: $message${error != null ? '\nError: $error' : ''}';
  }
}
