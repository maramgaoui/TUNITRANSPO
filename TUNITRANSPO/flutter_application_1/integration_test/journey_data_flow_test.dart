import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tuni_transport/main.dart' as app;
import 'package:tuni_transport/screens/home_screen.dart';
import 'package:tuni_transport/screens/journey_details_screen.dart';
import 'package:tuni_transport/screens/journey_input_screen.dart';
import 'package:tuni_transport/screens/journey_results_screen.dart';
import 'package:tuni_transport/widgets/metro_sahel_card.dart';

const authLoginTabKey = Key('auth_login_tab');
const authLoginEmailFieldKey = Key('auth_login_email_field');
const authLoginPasswordFieldKey = Key('auth_login_password_field');
const authLoginSubmitButtonKey = Key('auth_login_submit_button');
const authScreenKey = Key('auth_screen');
const homeScreenKey = Key('home_screen');
const journeyInputScreenKey = Key('journey_input_screen');

const _enabled = bool.fromEnvironment('IT_RUN_DATA_FLOW', defaultValue: false);
const _testUserEmail = String.fromEnvironment('IT_USER_EMAIL');
const _testUserPassword = String.fromEnvironment('IT_USER_PASSWORD');

const _banlieueOperator = 'Trains des Banlieues sud et ouest de Tunis';
const _metroSahelOperator = 'Métro du Sahel - SNCFT';

bool get _hasUserCredentials =>
    _testUserEmail.isNotEmpty && _testUserPassword.isNotEmpty;

class _RouteCandidate {
  const _RouteCandidate(this.routeId, this.operatorName);

  final String routeId;
  final String operatorName;
}

class _StationStop {
  const _StationStop({required this.stationId, required this.stopOrder});

  final String stationId;
  final int stopOrder;
}

class _JourneyExpectation {
  const _JourneyExpectation({
    required this.departureName,
    required this.arrivalName,
    required this.operatorName,
    required this.routeId,
  });

  final String departureName;
  final String arrivalName;
  final String operatorName;
  final String routeId;
}

Future<void> _pumpApp(WidgetTester tester) async {
  app.main();
  await _waitForOneOf(
    tester,
    find.byKey(authScreenKey),
    find.byKey(homeScreenKey),
    timeout: const Duration(seconds: 20),
  );
  await tester.pumpAndSettle();
}

Future<void> _ensureSignedOut(WidgetTester tester) async {
  await firebase_auth.FirebaseAuth.instance.signOut();
  await _waitForFinder(tester, find.byKey(authScreenKey));
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
  await _waitForOneOf(
    tester,
    find.byKey(homeScreenKey),
    find.byKey(authScreenKey),
    timeout: const Duration(seconds: 20),
  );
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

Future<void> _selectStation(
  WidgetTester tester, {
  required int fieldIndex,
  required String stationName,
}) async {
  final field = find.byType(TextField).at(fieldIndex);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, stationName);
  await tester.pumpAndSettle();

  final suggestion = find.widgetWithText(ListTile, stationName);
  if (suggestion.evaluate().isNotEmpty) {
    await tester.tap(suggestion.first);
    await tester.pumpAndSettle();
  } else {
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
}

Future<_JourneyExpectation> _findJourneyExpectation() async {
  final db = FirebaseFirestore.instance;
  final dayOfWeek = DateTime.now().weekday % 7;
  const candidates = <_RouteCandidate>[
    _RouteCandidate('route_bs_south', _banlieueOperator),
    _RouteCandidate('route_bs_north', _banlieueOperator),
    _RouteCandidate('route_rd_line_d_forward', _banlieueOperator),
    _RouteCandidate('route_rd_line_d_reverse', _banlieueOperator),
    _RouteCandidate('route_line_e_forward', _banlieueOperator),
    _RouteCandidate('route_line_e_reverse', _banlieueOperator),
    _RouteCandidate('route_ms_504', _metroSahelOperator),
    _RouteCandidate('route_ms_503', _metroSahelOperator),
  ];

  for (final candidate in candidates) {
    final tripsSnapshot = await db
        .collection('trips')
        .where('routeId', isEqualTo: candidate.routeId)
        .where('daysOfWeek', arrayContains: dayOfWeek)
        .limit(1)
        .get();

    if (tripsSnapshot.docs.isEmpty) {
      continue;
    }

    final routeStopsSnapshot = await db
        .collection('route_stops')
        .where('routeId', isEqualTo: candidate.routeId)
        .get();

    final orderedStops = routeStopsSnapshot.docs
        .map(
          (doc) => _StationStop(
            stationId: doc.data()['stationId'] as String,
            stopOrder: doc.data()['stopOrder'] as int,
          ),
        )
        .toList()
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    if (orderedStops.length < 2) {
      continue;
    }

    final departureDoc = await db
        .collection('stations')
        .doc(orderedStops.first.stationId)
        .get();
    final arrivalDoc = await db
        .collection('stations')
        .doc(orderedStops.last.stationId)
        .get();

    final departureName = departureDoc.data()?['name'] as String?;
    final arrivalName = arrivalDoc.data()?['name'] as String?;

    if (departureName == null ||
        departureName.isEmpty ||
        arrivalName == null ||
        arrivalName.isEmpty) {
      continue;
    }

    return _JourneyExpectation(
      departureName: departureName,
      arrivalName: arrivalName,
      operatorName: candidate.operatorName,
      routeId: candidate.routeId,
    );
  }

  fail('No seeded rail route with trips available for today was found in Firestore.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'seeded journey data is visible through the app flow',
    (tester) async {
      await _pumpApp(tester);
      await _ensureSignedOut(tester);
      expect(find.byKey(authScreenKey), findsOneWidget);

      await _loginUser(
        tester,
        email: _testUserEmail,
        password: _testUserPassword,
      );
      await _waitForFinder(
        tester,
        find.byType(HomeScreen),
        timeout: const Duration(seconds: 20),
      );
      await _waitForFinder(
        tester,
        find.byType(JourneyInputScreen),
        timeout: const Duration(seconds: 20),
      );

      final expected = await _findJourneyExpectation();

      await _selectStation(
        tester,
        fieldIndex: 0,
        stationName: expected.departureName,
      );
      await _selectStation(
        tester,
        fieldIndex: 1,
        stationName: expected.arrivalName,
      );

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.search));
      await tester.pump();

      await _waitForFinder(
        tester,
        find.byType(JourneyResultsScreen),
        timeout: const Duration(seconds: 20),
      );
      await _waitForFinder(
        tester,
        find.byType(MetroSahelCard),
        timeout: const Duration(seconds: 20),
      );

      expect(find.text(expected.operatorName), findsWidgets);
      expect(find.textContaining(expected.departureName), findsWidgets);
      expect(find.textContaining(expected.arrivalName), findsWidgets);

      await tester.tap(find.byType(MetroSahelCard).first);
      await tester.pump();

      await _waitForFinder(
        tester,
        find.byType(JourneyDetailsScreen),
        timeout: const Duration(seconds: 20),
      );

      expect(find.text(expected.operatorName), findsWidgets);
      expect(find.textContaining(expected.departureName), findsWidgets);
      expect(find.textContaining(expected.arrivalName), findsWidgets);
      expect(find.textContaining('Train'), findsWidgets,
          reason: 'Expected trip details to render for ${expected.routeId}.');
    },
    skip: !_enabled || !_hasUserCredentials,
  );
}