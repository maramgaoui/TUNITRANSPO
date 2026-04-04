import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../admin/screens/admin_dashboard.dart';
import '../admin/screens/admin_login_screen.dart';
import '../admin/screens/admin_profile_screen.dart';
import '../admin/screens/manage_users_screen.dart';
import '../controllers/auth_controller.dart';
import '../models/journey_model.dart';
import '../models/session_result.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/journey_details_screen.dart';
import '../screens/journey_results_screen.dart';
import '../screens/splash_screen.dart';
import '../services/settings_service.dart';

class AppRouter {
  AppRouter._();

  static bool _isRestorableRoute(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return path == '/home/journey-input' ||
        path == '/home/favorites' ||
        path == '/home/notifications' ||
        path == '/home/chat' ||
        path == '/home/profile' ||
        path == '/admin' ||
        path == '/admin/manage-users' ||
        path == '/admin/profile';
  }

  static GoRouter create({
    required AuthController authController,
    required SettingsService settingsService,
    required Function(ThemeMode) onThemeChanged,
    required ValueChanged<String> onLanguageChanged,
  }) {
    final refresh = _GoRouterRefreshStream(authController.authStateChanges);

    String adminLocation(SessionResult session) {
      final role = Uri.encodeComponent(session.adminRole ?? '');
      final matricule = Uri.encodeComponent(session.adminMatricule ?? '');
      final name = Uri.encodeComponent(session.adminName ?? '');
      return '/admin?role=$role&matricule=$matricule&name=$name';
    }

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: refresh,
      redirect: (context, state) async {
        final path = state.uri.path;
        final location = state.uri.toString();
        final user = authController.currentUser;
        final savedRoute = settingsService.getLastRoute();

        final isPublic = path == '/auth' || path == '/admin/login' || path == '/splash';

        if (_isRestorableRoute(location)) {
          unawaited(settingsService.setLastRoute(location));
        }

        if (user == null) {
          if (isPublic) {
            return null;
          }
          return '/auth';
        }

        final session = await authController.resolveSession(user);
        if (session.isGuest) {
          return '/auth';
        }

        if (session.isAdmin) {
          if (path == '/splash') {
            if (savedRoute != null && savedRoute.startsWith('/admin')) {
              return savedRoute;
            }
            return adminLocation(session);
          }

          // Keep admin context intact when query params are missing.
          if (path == '/admin/profile' && state.uri.queryParameters.isEmpty) {
            return '/admin/profile?role=${Uri.encodeComponent(session.adminRole ?? '')}&matricule=${Uri.encodeComponent(session.adminMatricule ?? '')}&name=${Uri.encodeComponent(session.adminName ?? '')}';
          }

          if (path == '/admin/login') {
            return adminLocation(session);
          }
          if (path == '/auth' || path == '/splash' || path.startsWith('/home')) {
            return adminLocation(session);
          }
          return null;
        }

        if (path.startsWith('/admin')) {
          return '/home/journey-input';
        }

        if (path == '/splash') {
          if (savedRoute != null && savedRoute.startsWith('/home')) {
            return savedRoute;
          }
          return '/home/journey-input';
        }

        if (path == '/auth' || path == '/') {
          return '/home/journey-input';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => AuthScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home/journey-input',
          builder: (context, state) => HomeScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home/favorites',
          builder: (context, state) => HomeScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home/notifications',
          builder: (context, state) => HomeScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home/chat',
          builder: (context, state) => HomeScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home/profile',
          builder: (context, state) => HomeScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/home/journey-results',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return JourneyResultsScreen(
                departure: (extra['departure'] ?? '').toString(),
                arrival: (extra['arrival'] ?? '').toString(),
              );
            }
            return const SplashScreen();
          },
        ),
        GoRoute(
          path: '/home/journey-details',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Journey) {
              return JourneyDetailsScreen(journey: extra);
            }
            return const SplashScreen();
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => AdminDashboard(
            role: state.uri.queryParameters['role'],
            matricule: state.uri.queryParameters['matricule'],
            adminName: state.uri.queryParameters['name'],
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => AdminLoginScreen(
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
        GoRoute(
          path: '/admin/manage-users',
          builder: (context, state) => const ManageUsersScreen(),
        ),
        GoRoute(
          path: '/admin/profile',
          builder: (context, state) => AdminProfileScreen(
            matricule: state.uri.queryParameters['matricule'],
            role: state.uri.queryParameters['role'],
            adminName: state.uri.queryParameters['name'],
            settingsService: settingsService,
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
          ),
        ),
      ],
    );
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
