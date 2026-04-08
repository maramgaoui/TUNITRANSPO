import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuni_transport/admin/screens/admin_dashboard.dart';
import 'package:tuni_transport/admin/screens/admin_profile_screen.dart';
import 'package:tuni_transport/admin/screens/manage_journeys_screen.dart';
import 'package:tuni_transport/admin/screens/manage_stations_screen.dart';
import 'package:tuni_transport/admin/screens/manage_users_screen.dart';
import 'package:tuni_transport/admin/screens/send_notifications_screen.dart';
import 'package:tuni_transport/screens/chat_screen.dart';
import 'package:tuni_transport/screens/favorites_screen.dart';
import 'package:tuni_transport/screens/home_screen.dart';
import 'package:tuni_transport/screens/journey_details_screen.dart';
import 'package:tuni_transport/screens/journey_input_screen.dart';
import 'package:tuni_transport/screens/journey_results_screen.dart';
import 'package:tuni_transport/screens/notification_screen.dart';
import 'package:tuni_transport/screens/profile_screen.dart';
import 'package:tuni_transport/main.dart' as app;
import 'package:tuni_transport/widgets/journey_card.dart';

const authLoginTabKey = Key('auth_login_tab');
const authSignupTabKey = Key('auth_signup_tab');
const authLoginEmailFieldKey = Key('auth_login_email_field');
const authLoginPasswordFieldKey = Key('auth_login_password_field');
const authLoginSubmitButtonKey = Key('auth_login_submit_button');
const authSignupFirstNameFieldKey = Key('auth_signup_first_name_field');
const authSignupLastNameFieldKey = Key('auth_signup_last_name_field');
const authSignupUsernameFieldKey = Key('auth_signup_username_field');
const authSignupEmailFieldKey = Key('auth_signup_email_field');
const authSignupPasswordFieldKey = Key('auth_signup_password_field');
const authSignupConfirmPasswordFieldKey = Key('auth_signup_confirm_password_field');
const authSignupSubmitButtonKey = Key('auth_signup_submit_button');
const authAdminLoginNavButtonKey = Key('auth_admin_login_nav_button');
const adminLoginMatriculeFieldKey = Key('admin_login_matricule_field');
const adminLoginPasswordFieldKey = Key('admin_login_password_field');
const adminLoginSubmitButtonKey = Key('admin_login_submit_button');
const profileLogoutButtonKey = Key('profile_logout_button');
const profileLogoutConfirmButtonKey = Key('profile_logout_confirm_button');
const authScreenKey = Key('auth_screen');
const homeScreenKey = Key('home_screen');
const journeyInputScreenKey = Key('journey_input_screen');
const homeNavProfileIconKey = Key('home_nav_profile_icon');
const adminDashboardScreenKey = Key('admin_dashboard_screen');

const _enabled = bool.fromEnvironment('IT_RUN_AUTH_FLOW', defaultValue: false);
const _testUserEmail = String.fromEnvironment('IT_USER_EMAIL');
const _testUserPassword = String.fromEnvironment('IT_USER_PASSWORD');
const _bannedEmail = String.fromEnvironment('IT_BANNED_EMAIL');
const _bannedPassword = String.fromEnvironment('IT_BANNED_PASSWORD');
const _adminMatricule = String.fromEnvironment('IT_ADMIN_MATRICULE');
const _adminPassword = String.fromEnvironment('IT_ADMIN_PASSWORD');
const _signupPassword = String.fromEnvironment(
  'IT_SIGNUP_PASSWORD',
  defaultValue: 'Test123!A',
);
const _signupEmailDomain = String.fromEnvironment(
  'IT_SIGNUP_EMAIL_DOMAIN',
  defaultValue: 'example.com',
);

bool get _hasCredentials =>
    _testUserEmail.isNotEmpty &&
    _testUserPassword.isNotEmpty &&
    _bannedEmail.isNotEmpty &&
    _bannedPassword.isNotEmpty &&
    _adminMatricule.isNotEmpty &&
    _adminPassword.isNotEmpty;

Future<void> _pumpApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _ensureSignedOut(WidgetTester tester) async {
  await firebase_auth.FirebaseAuth.instance.signOut();
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _loginUser(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await _tapByKey(tester, authLoginTabKey);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(authLoginEmailFieldKey), email);
  await tester.enterText(find.byKey(authLoginPasswordFieldKey), password);
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _pressElevatedButtonByKey(tester, authLoginSubmitButtonKey);
  await tester.pumpAndSettle(const Duration(seconds: 4));
}

Future<void> _tapByKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pressElevatedButtonByKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final button = tester.widget<ElevatedButton>(finder);
  expect(button.onPressed, isNotNull);
  button.onPressed!.call();
  await tester.pumpAndSettle();
}

Future<void> _logoutFromProfile(WidgetTester tester) async {
  await tester.tap(find.byKey(homeNavProfileIconKey));
  await tester.pumpAndSettle();
  await _pressElevatedButtonByKey(tester, profileLogoutButtonKey);
  await _tapByKey(tester, profileLogoutConfirmButtonKey);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for finder: $finder');
}

Future<void> _waitForOneOf(
  WidgetTester tester,
  Finder primary,
  Finder secondary, {
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (primary.evaluate().isNotEmpty || secondary.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for either finder: $primary OR $secondary');
}

Future<void> _goToRoute(
  WidgetTester tester,
  Finder contextFinder,
  String route,
) async {
  final context = tester.element(contextFinder.first);
  GoRouter.of(context).go(route);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _waitForType<T extends Widget>(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  await _waitForFinder(tester, find.byType(T), timeout: timeout);
}

String _latestSnackBarText(WidgetTester tester) {
  final textWidgets = find.descendant(
    of: find.byType(SnackBar),
    matching: find.byType(Text),
  );
  if (textWidgets.evaluate().isEmpty) {
    return 'no snackbar text';
  }
  final last = textWidgets.evaluate().last.widget;
  if (last is Text) {
    return last.data ?? 'non-text snackbar content';
  }
  return 'unknown snackbar content';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    testWidgets(
      'signup -> login -> logout -> redirection correcte',
      (tester) async {
        final suffix = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
        final username = 'it_$suffix';
        final email =
          'it_${DateTime.now().millisecondsSinceEpoch}@$_signupEmailDomain';

        await _pumpApp(tester);
        await _ensureSignedOut(tester);
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _tapByKey(tester, authSignupTabKey);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(authSignupFirstNameFieldKey), 'Integration');
        await tester.enterText(find.byKey(authSignupLastNameFieldKey), 'Flow');
        await tester.enterText(find.byKey(authSignupUsernameFieldKey), username);
        await tester.enterText(find.byKey(authSignupEmailFieldKey), email);
        await tester.enterText(find.byKey(authSignupPasswordFieldKey), _signupPassword);
        await tester.enterText(find.byKey(authSignupConfirmPasswordFieldKey), _signupPassword);
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _pressElevatedButtonByKey(tester, authSignupSubmitButtonKey);
        await _waitForOneOf(
          tester,
          find.byKey(homeScreenKey),
          find.byKey(authScreenKey),
        );

        if (find.byKey(homeScreenKey).evaluate().isEmpty) {
          fail(
            'Signup did not navigate to home. Snackbar: ${_latestSnackBarText(tester)}',
          );
        }

        expect(find.byKey(homeScreenKey), findsOneWidget);
        expect(find.byKey(journeyInputScreenKey), findsOneWidget);

        await _logoutFromProfile(tester);
        await _waitForFinder(tester, find.byKey(authScreenKey));
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _loginUser(tester, email: email, password: _signupPassword);
        await _waitForFinder(tester, find.byKey(homeScreenKey));
        expect(find.byKey(homeScreenKey), findsOneWidget);
        expect(find.byKey(journeyInputScreenKey), findsOneWidget);
      },
      skip: !_enabled,
    );

    testWidgets(
      'utilisateur banni redirigé vers /auth',
      (tester) async {
        await _pumpApp(tester);
        await _ensureSignedOut(tester);
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _loginUser(tester, email: _bannedEmail, password: _bannedPassword);

        expect(find.byKey(authScreenKey), findsOneWidget);
        expect(find.byKey(homeScreenKey), findsNothing);
      },
      skip: !_enabled || !_hasCredentials,
    );

    testWidgets(
      'user main routes smoke test',
      (tester) async {
        await _pumpApp(tester);
        await _ensureSignedOut(tester);
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _loginUser(
          tester,
          email: _testUserEmail,
          password: _testUserPassword,
        );
        await _waitForType<HomeScreen>(tester);
        await _waitForType<JourneyInputScreen>(tester);

        await _goToRoute(tester, find.byType(HomeScreen), '/home/favorites');
        await _waitForType<FavoritesScreen>(tester);

        await _goToRoute(tester, find.byType(HomeScreen), '/home/notifications');
        await _waitForType<NotificationScreen>(tester);

        await _goToRoute(tester, find.byType(HomeScreen), '/home/chat');
        await _waitForType<ChatScreen>(tester);

        await _goToRoute(tester, find.byType(HomeScreen), '/home/profile');
        await _waitForType<ProfileScreen>(tester);

        await _goToRoute(tester, find.byType(HomeScreen), '/home/journey-input');
        await _waitForType<JourneyInputScreen>(tester);
      },
      skip: !_enabled || !_hasCredentials,
    );

    testWidgets(
      'journey search opens results and details',
      (tester) async {
        await _pumpApp(tester);
        await _ensureSignedOut(tester);

        await _loginUser(
          tester,
          email: _testUserEmail,
          password: _testUserPassword,
        );
        await _waitForType<JourneyInputScreen>(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Tunis');
        await tester.enterText(find.byType(TextField).at(1), 'Ariana');
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.search));
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _waitForType<JourneyResultsScreen>(tester);

        await tester.tap(find.byType(JourneyCard).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _waitForType<JourneyDetailsScreen>(tester);
      },
      skip: !_enabled || !_hasCredentials,
    );

    testWidgets(
      'admin management routes smoke test',
      (tester) async {
        await _pumpApp(tester);
        await _ensureSignedOut(tester);
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _tapByKey(tester, authAdminLoginNavButtonKey);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(adminLoginMatriculeFieldKey), _adminMatricule);
        await tester.enterText(find.byKey(adminLoginPasswordFieldKey), _adminPassword);
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _pressElevatedButtonByKey(tester, adminLoginSubmitButtonKey);
        await _waitForType<AdminDashboard>(tester);

        await _goToRoute(tester, find.byType(AdminDashboard), '/admin/manage-users');
        await _waitForType<ManageUsersScreen>(tester);

        await _goToRoute(tester, find.byType(ManageUsersScreen), '/admin/manage-journeys');
        await _waitForType<ManageJourneysScreen>(tester);

        await _goToRoute(tester, find.byType(ManageJourneysScreen), '/admin/manage-stations');
        await _waitForType<ManageStationsScreen>(tester);

        await _goToRoute(tester, find.byType(ManageStationsScreen), '/admin/send-notifications');
        await _waitForType<SendNotificationsScreen>(tester);

        await _goToRoute(
          tester,
          find.byType(SendNotificationsScreen),
          '/admin/profile?role=superadmin&matricule=9001&name=Integration%20Admin',
        );
        await _waitForType<AdminProfileScreen>(tester);
      },
      skip: !_enabled || !_hasCredentials,
    );
  });
}
