import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (role != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.connectedRole(role!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            _buildActionButton(context, l10n.manageUsers, Icons.people_outline),
            _buildActionButton(context, l10n.manageJourneys, Icons.route_outlined),
            _buildActionButton(context, l10n.manageStations, Icons.train_outlined),
            _buildActionButton(
              context,
              l10n.sendNotifications,
              Icons.notifications_active_outlined,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                // Return to the normal authentication screen.
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.featureReadyToBeConnected(label))),
          );
        },
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
