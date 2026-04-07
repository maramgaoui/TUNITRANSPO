import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/screens/journey_results_screen.dart';

void main() {
  testWidgets('affiche une liste de trajets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const JourneyResultsScreen(
          departure: 'Tunis',
          arrival: 'La Marsa',
          preloadFavorites: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.textContaining('options trouvées'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('Navigator.pop ou context.pop fonctionne sans crash', (tester) async {
    final router = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(
          path: '/home/journey-input',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Journey Input')),
          ),
        ),
        GoRoute(
          path: '/results',
          builder: (context, state) => const JourneyResultsScreen(
            departure: 'Tunis',
            arrival: 'Sfax',
            preloadFavorites: false,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Journey Input'), findsOneWidget);
  });
}
