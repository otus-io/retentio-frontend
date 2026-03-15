/// Created on 2026/2/6
/// Description:
enum AppRoutes {
  login('/login'),
  main('/'),
  register('/register'),
  learn('/learn');

  final String path;
  const AppRoutes(this.path);
}
