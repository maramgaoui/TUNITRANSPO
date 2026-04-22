import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/screens/journey_input_screen.dart';
import 'package:tuni_transport/services/station_repository.dart';

Future<void> _seedStation(
  FakeFirebaseFirestore firestore, {
  required String id,
  required String name,
  required String cityId,
}) async {
  await firestore.collection('stations').doc(id).set({
    'name': name,
    'cityId': cityId,
    'latitude': 35.5,
    'longitude': 10.8,
    'address': null,
    'transportTypes': ['train'],
    'operatorsHere': ['sncft_sahel'],
    'services': {
      'wifi': false,
      'toilet': true,
      'cafe': false,
      'parking': false,
    },
    'isMainHub': false,
    'createdAt': Timestamp.now(),
  });
}

Widget _buildTestApp(StationRepository repository) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: JourneyInputScreen(stationRepository: repository),
  );
}

void main() {
  testWidgets('shows localized station-not-found message for unknown departure',
      (tester) async {
    final firestore = FakeFirebaseFirestore();
    await _seedStation(
      firestore,
      id: 'ms_mahdia',
      name: 'Mahdia',
      cityId: 'mahdia',
    );
    await _seedStation(
      firestore,
      id: 'ms_monastir',
      name: 'Monastir',
      cityId: 'monastir',
    );

    final repository = StationRepository(firestore);

    await tester.pumpWidget(_buildTestApp(repository));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'zzzz');
    await tester.enterText(fields.at(1), 'Monastir');

    await tester.tap(find.text('Search journey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text("No station found for 'zzzz'."), findsOneWidget);
  });
}
