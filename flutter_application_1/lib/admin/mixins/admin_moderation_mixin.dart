import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/services/admin_user_service.dart';

mixin AdminModerationMixin<T extends StatefulWidget> on State<T> {
  final AdminUserService _adminUserService = AdminUserService();

  Future<void> banUserWithFeedback(
    BuildContext context,
    String userId, {
    required int days,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _adminUserService.banUser(userId, days: days);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBannedDays(days))),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? l10n.firestoreUpdateError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> blockUserWithFeedback(BuildContext context, String userId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _adminUserService.blockUser(userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userBlockedPermanently)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? l10n.firestoreUpdateError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> unblockUserWithFeedback(
    BuildContext context,
    String userId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _adminUserService.unblockUser(userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userUnblocked)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? l10n.firestoreUpdateError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
