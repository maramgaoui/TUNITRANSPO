import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/admin/mixins/admin_user_status_mixin.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';

class _AdminStatusHost extends StatefulWidget {
  const _AdminStatusHost({super.key});

  @override
  State<_AdminStatusHost> createState() => _AdminStatusHostState();
}

class _AdminStatusHostState extends State<_AdminStatusHost>
    with AdminUserStatusMixin<_AdminStatusHost> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('AdminUserStatusMixin', () {
    testWidgets('formatAdminDateTime returns yyyy-mm-dd hh:mm', (tester) async {
      final key = GlobalKey<_AdminStatusHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _AdminStatusHost(key: key),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      final state = key.currentState!;
      final formatted = state.formatAdminDateTime(DateTime(2026, 4, 7, 9, 5));
      expect(formatted, '2026-04-07 09:05');
    });

    testWidgets('adminStatusLabel returns localized blocked status', (tester) async {
      final key = GlobalKey<_AdminStatusHostState>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: _AdminStatusHost(key: key),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      final state = key.currentState!;
      final label = state.adminStatusLabel(state.context, 'blocked', null);
      expect(label, 'Statut : Bloqué');
    });

    testWidgets('adminStatusLabel adds ban-until date when provided', (tester) async {
      final key = GlobalKey<_AdminStatusHostState>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: _AdminStatusHost(key: key),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      final state = key.currentState!;
      final label = state.adminStatusLabel(
        state.context,
        'banned',
        DateTime(2026, 4, 7, 16, 30),
      );

      expect(label.contains('2026-04-07 16:30'), isTrue);
      expect(label.contains('Banni'), isTrue);
    });

    testWidgets('adminStatusColor maps each status to expected palette', (tester) async {
      final key = GlobalKey<_AdminStatusHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: _AdminStatusHost(key: key),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );

      final state = key.currentState!;
      expect(state.adminStatusColor('blocked'), Colors.red.shade700);
      expect(state.adminStatusColor('banned'), Colors.orange.shade700);
      expect(state.adminStatusColor('active'), Colors.green.shade700);
    });
  });
}
