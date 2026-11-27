import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_paths.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/unauthorized_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/payments/presentation/pages/payments_list_page.dart';
import '../../features/profiles/presentation/pages/profiles_list_page.dart';
import '../../features/users/presentation/pages/users_list_page.dart';
import '../../shell/admin_shell.dart';
import 'go_router_refresh.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = FirebaseAuth.instance;
  final refresh = GoRouterRefreshStream(auth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    initialLocation: AdminRoutes.login,
    redirect: (BuildContext context, GoRouterState state) async {
      final path = state.uri.path;
      final user = auth.currentUser;

      final onLogin = path == AdminRoutes.login;
      final onUnauthorized = path == AdminRoutes.unauthorized;
      final onAdminEntry = isAdminEntryPath(path);

      if (onLogin) {
        if (user == null) return null;
        final isAdmin = await _hasAdminClaim(user);
        if (isAdmin) return AdminRoutes.dashboard;
        return AdminRoutes.unauthorized;
      }

      if (onUnauthorized) {
        if (user == null) return AdminRoutes.login;
        final isAdmin = await _hasAdminClaim(user);
        if (isAdmin) return AdminRoutes.dashboard;
        return null;
      }

      if (onAdminEntry) {
        if (user == null) return AdminRoutes.login;
        final isAdmin = await _hasAdminClaim(user);
        if (isAdmin) return AdminRoutes.dashboard;
        return AdminRoutes.login;
      }

      if (isProtectedAdminPath(path)) {
        if (user == null) return AdminRoutes.login;
        final isAdmin = await _hasAdminClaim(user);
        if (!isAdmin) return AdminRoutes.unauthorized;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AdminRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AdminRoutes.unauthorized,
        name: 'unauthorized',
        builder: (context, state) => const UnauthorizedPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AdminRoutes.users,
            name: 'users',
            builder: (context, state) => const UsersListPage(),
          ),
          GoRoute(
            path: AdminRoutes.profiles,
            name: 'profiles',
            builder: (context, state) => const ProfilesListPage(),
          ),
          GoRoute(
            path: AdminRoutes.payments,
            name: 'payments',
            builder: (context, state) => const PaymentsListPage(),
          ),
        ],
      ),
    ],
  );
});

Future<bool> _hasAdminClaim(User user) async {
  final result = await user.getIdTokenResult(true);
  final claim = result.claims?['superuser'];
  return claim == true;
}
