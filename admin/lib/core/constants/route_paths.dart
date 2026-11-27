/// All in-app routes use the `/admin/...` prefix to match Firebase Hosting
/// and `flutter build web --base-href /admin/`.
abstract final class AdminRoutes {
  static const login = '/admin/login';
  static const unauthorized = '/admin/unauthorized';
  static const dashboard = '/admin/dashboard';
  static const users = '/admin/users';
  static const profiles = '/admin/profiles';
  static const payments = '/admin/payments';

  /// Normalized entry: `/admin` or `/admin/`
  static const adminRoot = '/admin';
}

bool isAdminEntryPath(String path) {
  return path == AdminRoutes.adminRoot || path == '${AdminRoutes.adminRoot}/';
}

bool isProtectedAdminPath(String path) {
  if (!path.startsWith(AdminRoutes.adminRoot)) return false;
  if (path == AdminRoutes.login) return false;
  if (path == AdminRoutes.unauthorized) return false;
  if (isAdminEntryPath(path)) return false;
  return true;
}
