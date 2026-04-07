import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuni_transport/main.dart' as app;

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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow', () {
    testWidgets(
      'signup -> login -> logout -> redirection correcte',
      (tester) async {
        final email =
          'it_${DateTime.now().millisecondsSinceEpoch}@$_signupEmailDomain';

        await _pumpApp(tester);
        await _ensureSignedOut(tester);
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _tapByKey(tester, authSignupTabKey);
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(authSignupFirstNameFieldKey), 'Integration');
        await tester.enterText(find.byKey(authSignupLastNameFieldKey), 'Flow');
        await tester.enterText(find.byKey(authSignupUsernameFieldKey), 'it_flow_user');
        await tester.enterText(find.byKey(authSignupEmailFieldKey), email);
        await tester.enterText(find.byKey(authSignupPasswordFieldKey), _signupPassword);
        await tester.enterText(find.byKey(authSignupConfirmPasswordFieldKey), _signupPassword);
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _pressElevatedButtonByKey(tester, authSignupSubmitButtonKey);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.byKey(homeScreenKey), findsOneWidget);
        expect(find.byKey(journeyInputScreenKey), findsOneWidget);

        await _logoutFromProfile(tester);
        expect(find.byKey(authScreenKey), findsOneWidget);

        await _loginUser(tester, email: email, password: _signupPassword);
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
      'admin login redirigé vers /admin',
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
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.byKey(adminDashboardScreenKey), findsOneWidget);
      },
      skip: !_enabled || !_hasCredentials,
    );
  });
}
