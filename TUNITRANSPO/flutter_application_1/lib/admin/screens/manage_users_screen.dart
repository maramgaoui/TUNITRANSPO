import 'dart:async';

import 'package:avatar_plus/avatar_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/admin/mixins/admin_moderation_mixin.dart';
import 'package:tuni_transport/admin/mixins/admin_user_status_mixin.dart';
import '../../l10n/app_localizations.dart';

/// Filter options shown in the chip bar above the list.
enum _UserFilter { all, active, banned, blocked }

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({
    super.key,
    this.firestore,
    this.pageSize = 25,
    this.initialLoadDelay,
  });

  final FirebaseFirestore? firestore;
  final int pageSize;
  final Duration? initialLoadDelay;

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
  with AdminModerationMixin, AdminUserStatusMixin {
  static const String _usersCollection = 'users';

  _UserFilter _activeFilter = _UserFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _loadedDocs = [];
  Timer? _searchDebounce;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _loadError;
  String _searchQuery = '';

  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final nextQuery = _searchController.text.trim();
      if (nextQuery == _searchQuery) return;
      setState(() => _searchQuery = nextQuery);
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        unawaited(_loadInitialUsers());
      });
    });
    _scrollController.addListener(_onScroll);
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String? get _statusValueFilter {
    return switch (_activeFilter) {
      _UserFilter.active => 'active',
      _UserFilter.banned => 'banned',
      _UserFilter.blocked => 'blocked',
      _UserFilter.all => null,
    };
  }

  Query<Map<String, dynamic>> _buildQuery({
    required bool forLoadMore,
    bool preferServerPrefixSearch = true,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(_usersCollection);

    final statusFilter = _statusValueFilter;
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    final trimmedQuery = _searchQuery.trim();
    final canUseServerPrefix = trimmedQuery.isNotEmpty && preferServerPrefixSearch;
    if (canUseServerPrefix) {
      // Prefix search stays Firestore-side to reduce scanned documents.
      query = query
          .orderBy('username')
          .startAt([trimmedQuery])
          .endAt(['$trimmedQuery\uf8ff']);
    } else {
      query = query.orderBy(FieldPath.documentId);
    }

    query = query.limit(widget.pageSize);
    if (forLoadMore && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    return query;
  }

  Future<void> _loadInitialUsers() async {
    setState(() {
      _isInitialLoading = true;
      _loadError = null;
      _loadedDocs.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      if (widget.initialLoadDelay != null) {
        await Future<void>.delayed(widget.initialLoadDelay!);
      }
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _buildQuery(forLoadMore: false).get();
      } on FirebaseException {
        // Index/schema fallback: keep pagination with documentId ordering.
        snapshot = await _buildQuery(
          forLoadMore: false,
          preferServerPrefixSearch: false,
        ).get();
      }
      if (!mounted) return;
      setState(() {
        _loadedDocs.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == widget.pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore || _lastDocument == null) {
      return;
    }

    setState(() => _isLoadingMore = true);
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _buildQuery(forLoadMore: true).get();
      } on FirebaseException {
        snapshot = await _buildQuery(
          forLoadMore: true,
          preferServerPrefixSearch: false,
        ).get();
      }
      if (!mounted) return;
      setState(() {
        _loadedDocs.addAll(snapshot.docs);
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _hasMore = snapshot.docs.length == widget.pageSize;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  /// Returns true when a document passes both the status filter and search query.
  bool _matchesFilters(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'active').toString();
    final normalizedQuery = _searchQuery.toLowerCase();

    // Status filter
    if (_activeFilter != _UserFilter.all) {
      if (_activeFilter == _UserFilter.active && status != 'active') return false;
      if (_activeFilter == _UserFilter.banned && status != 'banned') return false;
      if (_activeFilter == _UserFilter.blocked && status != 'blocked') return false;
    }

    // Search query — match username or email (case-insensitive)
    if (normalizedQuery.isNotEmpty) {
      final username = (data['username'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      if (!username.contains(normalizedQuery) && !email.contains(normalizedQuery)) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageUsers),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
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
                    onSelected: (_) {
                      setState(() => _activeFilter = filter);
                      unawaited(_loadInitialUsers());
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // ── User list ───────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isInitialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_loadError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Unable to load users. $_loadError',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = _loadedDocs.where((d) => _matchesFilters(d.data())).toList();

                if (_loadedDocs.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noUsersFound));
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noUsersMatchFilter),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadInitialUsers,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= docs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

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
                                          adminStatusLabel(context, status, banUntil),
                                          style: TextStyle(
                                            color: adminStatusColor(status),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
                await banUserWithFeedback(context, userId, days: 3);
                await _loadInitialUsers();
              },
              child: Text(l10n.banFor3Days),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await banUserWithFeedback(context, userId, days: 7);
                await _loadInitialUsers();
              },
              child: Text(l10n.banFor7Days),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await blockUserWithFeedback(context, userId);
                await _loadInitialUsers();
              },
              child: Text(l10n.blockPermanently),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await unblockUserWithFeedback(context, userId);
                await _loadInitialUsers();
              },
              child: Text(l10n.unblockUser),
            ),
          ],
        );
      },
    );
  }
}
