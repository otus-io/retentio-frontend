/// Created on 2026/2/6
/// Description:
enum AppRoutes {
  login('/login'),
  main('/'),
  register('/register'),
  study('/study');

  final String path;
  const AppRoutes(this.path);
}
