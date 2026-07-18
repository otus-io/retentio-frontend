/// Created on 2026/2/6
/// Description:
enum AppRoutes {
  login('/login'),
  main('/'),
  register('/register'),
  study('/study'),
  discoveryDetail('/discovery/:id');

  final String path;
  const AppRoutes(this.path);

  /// Routes that can be visited without authentication.
  static const Set<String> authExemptPaths = {'/login', '/register', '/'};

  /// Normalizes paths to keep routing checks compatible with trailing slash input.
  static String normalizePath(String path) {
    if (path.isEmpty) {
      return main.path;
    }
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  static bool isAuthExemptPath(String path) {
    final normalized = normalizePath(path);
    return authExemptPaths.contains(normalized) ||
        normalized.startsWith('/discovery/');
  }
}
