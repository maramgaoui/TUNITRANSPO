import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';

mixin AdminUserStatusMixin<T extends StatefulWidget> on State<T> {
  String formatAdminDateTime(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  String adminStatusLabel(
    BuildContext context,
    String status,
    DateTime? banUntil,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'blocked':
        return l10n.statusBlocked;
      case 'banned':
        if (banUntil == null) return l10n.statusBanned;
        return l10n.statusBannedUntil(formatAdminDateTime(banUntil));
      default:
        return l10n.statusActive;
    }
  }

  Color adminStatusColor(String status) {
    switch (status) {
      case 'blocked':
        return Colors.red.shade700;
      case 'banned':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }
}
