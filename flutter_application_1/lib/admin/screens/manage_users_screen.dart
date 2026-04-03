import 'package:avatar_plus/avatar_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuni_transport/services/admin_user_service.dart';
import '../../l10n/app_localizations.dart';

/// Filter options shown in the chip bar above the list.
enum _UserFilter { all, active, banned, blocked }

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  static const String _usersCollection = 'users';
  final AdminUserService _adminUserService = AdminUserService();

  _UserFilter _activeFilter = _UserFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns true when a document passes both the status filter and search query.
  bool _matchesFilters(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'active').toString();

    // Status filter
    if (_activeFilter != _UserFilter.all) {
      if (_activeFilter == _UserFilter.active && status != 'active') return false;
      if (_activeFilter == _UserFilter.banned && status != 'banned') return false;
      if (_activeFilter == _UserFilter.blocked && status != 'blocked') return false;
    }

    // Search query — match username or email (case-insensitive)
    if (_searchQuery.isNotEmpty) {
      final username = (data['username'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      if (!username.contains(_searchQuery) && !email.contains(_searchQuery)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageUsers)),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByNameOrEmail,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Filter chips ────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: _UserFilter.values.map((filter) {
                final l10n = AppLocalizations.of(context)!;
                final label = switch (filter) {
                  _UserFilter.all     => l10n.filterAll,
                  _UserFilter.active  => l10n.filterActive,
                  _UserFilter.banned  => l10n.filterBanned,
                  _UserFilter.blocked => l10n.filterBlocked,
                };
                final color = switch (filter) {
                  _UserFilter.active  => Colors.green.shade700,
                  _UserFilter.banned  => Colors.orange.shade700,
                  _UserFilter.blocked => Colors.red.shade700,
                  _UserFilter.all     => Colors.blueGrey.shade700,
                };
                final selected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    selectedColor: color.withValues(alpha: 0.18),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      color: selected ? color : null,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    onSelected: (_) =>
                        setState(() => _activeFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // ── User list ───────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(_usersCollection)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Unable to load users. ${snapshot.error ?? ''}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs
                    .where((d) => _matchesFilters(d.data()))
                    .toList();

                if (allDocs.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noUsersFound));
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noUsersMatchFilter),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final username =
                        (data['username'] ?? 'Unknown user').toString();
                    final email = (data['email'] ?? '').toString();
                    final avatar =
                        ((data['avatar'] ?? data['avatarId']) ?? 'avatar-01')
                            .toString();
                    final status = (data['status'] ?? 'active').toString();
                    final banUntilRaw = data['banUntil'];
                    final banUntil = banUntilRaw is Timestamp
                        ? banUntilRaw.toDate()
                        : (banUntilRaw is DateTime ? banUntilRaw : null);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AvatarPlus(
                                  avatar,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(email),
                                      const SizedBox(height: 4),
                                      Text(
                                        _statusLabel(context, status, banUntil),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonalIcon(
                                onPressed: () =>
                                    _showAdminActions(context, doc.id),
                                icon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                                label: Text(
                                  AppLocalizations.of(context)!.adminActions,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, String status, DateTime? banUntil) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'blocked':
        return l10n.statusBlocked;
      case 'banned':
        if (banUntil == null) return l10n.statusBanned;
        return l10n.statusBannedUntil(_formatDateTime(banUntil));
      default:
        return l10n.statusActive;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'blocked':
        return Colors.red.shade700;
      case 'banned':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  String _formatDateTime(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  Future<void> _showAdminActions(BuildContext context, String userId) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.adminActions),
          content: Text(l10n.adminActionsPrompt),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _banUser(context, userId, days: 3);
              },
              child: Text(l10n.banFor3Days),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _banUser(context, userId, days: 7);
              },
              child: Text(l10n.banFor7Days),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _blockUser(context, userId);
              },
              child: Text(l10n.blockPermanently),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _unblockUser(context, userId);
              },
              child: Text(l10n.unblockUser),
            ),
          ],
        );
      },
    );
  }

  Future<void> _banUser(
    BuildContext context,
    String userId, {
    required int days,
  }) async {
    try {
      await _adminUserService.banUser(userId, days: days);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userBannedDays(days))),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? l10n.firestoreUpdateError,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _blockUser(BuildContext context, String userId) async {
    try {
      await _adminUserService.blockUser(userId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userBlockedPermanently)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? l10n.firestoreUpdateError,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unblockUser(BuildContext context, String userId) async {
    try {
      await _adminUserService.unblockUser(userId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.userUnblocked)),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? l10n.firestoreUpdateError,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
