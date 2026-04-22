import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../admin/screens/admin_dashboard.dart';
import '../admin/screens/admin_login_screen.dart';
import '../admin/screens/admin_profile_screen.dart';
import '../admin/screens/manage_users_screen.dart';
import '../admin/screens/manage_journeys_screen.dart';
import '../admin/screens/manage_stations_screen.dart';
import '../admin/screens/send_notifications_screen.dart';
import '../controllers/auth_controller.dart';
import '../models/journey_model.dart';
import '../models/metro_sahel_result.dart';
import '../models/session_result.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/active_journey_screen.dart';
import '../screens/journey_details_screen.dart';
import '../screens/journey_results_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/route_map_screen.dart';
import 'package:tuni_transport/services/settings_service.dart';

class AppRouter {
  AppRouter._();

  static const Set<String> _restorableRoutes = {
    '/home/journey-input',
    '/home/favorites',
    '/home/notifications',
    '/home/chat',
    '/home/profile',
    '/admin',
    '/admin/manage-users',
    '/admin/manage-journeys',
    '/admin/manage-stations',
    '/admin/send-notifications',
    '/admin/profile',
  };

  static bool _isRestorableRoute(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return _restorableRoutes.contains(path);
  }

  static GoRouter create({
    required AuthController authController,
    required SettingsService settingsService,
  }) {
    final refresh = _GoRouterRefreshStream(authController.authStateChanges);

    // Admin route — no sensitive data in URL (#25).
    const adminLocation = '/admin';

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
          if (path == '/splash') {
            return '/auth';
          }
          if (isPublic) {
            return null;
          }
          return '/auth';
        }

        SessionResult session;
        try {
          session = await authController.resolveSession(user);
        } catch (_) {
          // Session policy (transient vs definitive failures) is centralized
          // in AuthController.resolveSession.
          return '/auth';
        }
        if (session.isGuest) {
          return '/auth';
        }

        if (session.isAdmin) {
          if (path == '/splash') {
            if (savedRoute != null && _isRestorableRoute(savedRoute) && savedRoute.startsWith('/admin')) {
              return savedRoute;
            }
            return adminLocation;
          }

          if (path == '/admin/login') {
            return adminLocation;
          }
          if (path == '/auth' || path == '/splash' || path.startsWith('/home')) {
            return adminLocation;
          }
          return null;
        }

        if (path.startsWith('/admin')) {
          return '/home/journey-input';
        }

        if (path == '/splash') {
          if (savedRoute != null && _isRestorableRoute(savedRoute) && savedRoute.startsWith('/home')) {
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
          builder: (context, state) => const AuthScreen(),
        ),
        // All /home/* tab routes render HomeScreen, which derives the
        // active tab from GoRouterState.uri.path — so deep links work.
        for (final tabPath in const [
          '/home',
          '/home/journey-input',
          '/home/favorites',
          '/home/notifications',
          '/home/chat',
          '/home/profile',
        ])
          GoRoute(
            path: tabPath,
            builder: (context, state) => const HomeScreen(),
          ),
        GoRoute(
          path: '/home/journey-results',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return JourneyResultsScreen(
                departure: (extra['departure'] ?? '').toString(),
                arrival: (extra['arrival'] ?? '').toString(),
                fromStationId: extra['fromStationId']?.toString(),
                toStationId: extra['toStationId']?.toString(),
              );
            }
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/home/journey-details',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Journey) {
              return JourneyDetailsScreen(journey: extra);
            }
            if (extra is MetroSahelResult) {
              return JourneyDetailsScreen(metroResult: extra);
            }
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/home/active-journey',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Journey) {
              return ActiveJourneyScreen(journey: extra);
            }
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/home/route-map',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return RouteMapScreen(
                stationIds: List<String>.from(extra['stationIds'] ?? []),
                routeTitle: extra['routeTitle']?.toString(),
                lineNumber: extra['lineNumber']?.toString(),
              );
            }
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin/manage-users',
          builder: (context, state) => const ManageUsersScreen(),
        ),
        GoRoute(
          path: '/admin/manage-journeys',
          builder: (context, state) => const ManageJourneysScreen(),
        ),
        GoRoute(
          path: '/admin/manage-stations',
          builder: (context, state) => const ManageStationsScreen(),
        ),
        GoRoute(
          path: '/admin/send-notifications',
          builder: (context, state) => const SendNotificationsScreen(),
        ),
        GoRoute(
          path: '/admin/profile',
          builder: (context, state) => const AdminProfileScreen(),
        ),
      ],
    );
  }
}

/// Bridges a [Stream] into a [ChangeNotifier] so [GoRouter.refreshListenable]
/// can react to auth-state changes.
///
/// **Lifecycle:** GoRouter calls [dispose] on its [refreshListenable] when the
/// router itself is disposed (e.g. when the owning widget is unmounted).
/// If GoRouter ever changes this contract, the owning widget must call
/// `dispose()` explicitly.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
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
