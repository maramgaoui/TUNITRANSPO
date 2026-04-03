import 'package:avatar_plus/avatar_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Filter options shown in the chip bar above the list.
enum _UserFilter { all, active, banned, blocked }

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  static const String _usersCollection = 'users';

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
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email…',
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
                final label = switch (filter) {
                  _UserFilter.all     => 'All',
                  _UserFilter.active  => 'Active',
                  _UserFilter.banned  => 'Banned',
                  _UserFilter.blocked => 'Blocked',
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
                  return const Center(child: Text('No users found.'));
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No users match the current filter.'),
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
                                        _statusLabel(status, banUntil),
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
                                label: const Text('Admin Actions'),
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

  String _statusLabel(String status, DateTime? banUntil) {
    switch (status) {
      case 'blocked':
        return 'Status: Blocked';
      case 'banned':
        if (banUntil == null) return 'Status: Banned';
        return 'Status: Banned until ${_formatDateTime(banUntil)}';
      default:
        return 'Status: Active';
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
      builder: (context) => AlertDialog(
        title: const Text('Admin Actions'),
        content: const Text('Select an action for this user.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _banUser(context, userId, days: 3);
            },
            child: const Text('Ban for 3 days'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _banUser(context, userId, days: 7);
            },
            child: const Text('Ban for 7 days'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _blockUser(context, userId);
            },
            child: const Text('Block permanently'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _unblockUser(context, userId);
            },
            child: const Text('Unblock user'),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(
    BuildContext context,
    String userId, {
    required int days,
  }) async {
    try {
      final until = DateTime.now().add(Duration(days: days));
      // Ban logic: user remains banned until `banUntil`, then app logic auto-reactivates.
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId)
          .update({'status': 'banned', 'banUntil': Timestamp.fromDate(until)});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User banned for $days days.')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to update user. Check Firestore permissions.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _blockUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId)
          .update({'status': 'blocked', 'banUntil': null});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User blocked permanently.')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to update user. Check Firestore permissions.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unblockUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(userId)
          .update({'status': 'active', 'banUntil': null});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unblocked successfully.')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to update user. Check Firestore permissions.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
