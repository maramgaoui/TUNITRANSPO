import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:tuni_transport/admin/mixins/admin_moderation_mixin.dart';
import 'package:tuni_transport/admin/mixins/admin_user_status_mixin.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.isAdminMode = false,
    this.adminMatricule,
    this.adminName,
    this.adminRole,
    this.firestore,
    this.authController,
  });

  final bool isAdminMode;
  final String? adminMatricule;
  final String? adminName;
  final String? adminRole;
  final FirebaseFirestore? firestore;
  final AuthController? authController;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
  with AdminModerationMixin, AdminUserStatusMixin {
  static const int _kInitialMessagesLimit = 50;
  static const int _kMessagesPageSize = 30;

  late final AuthController _authController;
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSubscription;

  late final CollectionReference<Map<String, dynamic>> _messagesRef;
  late final CollectionReference<Map<String, dynamic>> _usersRef;

  Map<String, dynamic>? _replyingTo;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _liveMessages =
      const [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _olderMessages =
      const [];
  DocumentSnapshot<Map<String, dynamic>>? _oldestLoadedDoc;
  String? _lastNewestMessageId;
  Object? _messagesError;
  bool _isMessagesLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  bool _isSending = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _visibleMessages {
    final seen = <String>{};
    final merged = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in _liveMessages) {
      if (seen.add(doc.id)) {
        merged.add(doc);
      }
    }
    for (final doc in _olderMessages) {
      if (seen.add(doc.id)) {
        merged.add(doc);
      }
    }
    return merged;
  }

  @override
  void initState() {
    super.initState();
    final firestore = widget.firestore ?? FirebaseFirestore.instance;
    _authController = widget.authController ?? AuthController.instance;
    _messagesRef = firestore.collection('community_messages');
    _usersRef = firestore.collection('users');
    _startMessagesListener();
    _scrollController.addListener(_handleScrollForPagination);
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        _ensureLatestMessageVisible();
      }
    });
  }

  String? get _chatSessionUid {
    return _authController.currentUser?.uid;
  }

  String get _adminUid {
    return _chatSessionUid ?? 'admin_unknown';
  }

  String get _adminDisplayName {
    final fallback = (widget.adminRole?.trim().isNotEmpty ?? false)
        ? 'Admin (${widget.adminRole!.trim()})'
        : 'Admin';
    final name = widget.adminName?.trim();
    if (name == null || name.isEmpty) return fallback;
    return name;
  }

  bool get _canParticipateInChat {
    return _chatSessionUid != null;
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _scrollController.removeListener(_handleScrollForPagination);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startMessagesListener() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _messagesRef
        .orderBy('timestamp', descending: true)
        .limit(_kInitialMessagesLimit)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            final liveDocs = snapshot.docs;
            final liveIds = liveDocs.map((d) => d.id).toSet();
            final filteredOlder =
                _olderMessages.where((d) => !liveIds.contains(d.id)).toList();
            final mergedDocs = [...liveDocs, ...filteredOlder];
            final newestId = mergedDocs.isNotEmpty ? mergedDocs.first.id : null;

            setState(() {
              _isMessagesLoading = false;
              _messagesError = null;
              _liveMessages = liveDocs;
              _olderMessages = filteredOlder;
              _oldestLoadedDoc =
                  mergedDocs.isNotEmpty ? mergedDocs.last : null;
              if (_olderMessages.isEmpty) {
                _hasMoreMessages = liveDocs.length == _kInitialMessagesLimit;
              }
            });

            if (newestId != null && newestId != _lastNewestMessageId) {
              _lastNewestMessageId = newestId;
              _scheduleScrollToBottom();
            }
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isMessagesLoading = false;
              _messagesError = error;
            });
          },
        );
  }

  void _handleScrollForPagination() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        !_hasMoreMessages ||
        _oldestLoadedDoc == null) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 180) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _oldestLoadedDoc == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await _messagesRef
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_oldestLoadedDoc!)
          .limit(_kMessagesPageSize)
          .get();

      if (!mounted) return;

      if (page.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
        return;
      }

      final liveIds = _liveMessages.map((d) => d.id).toSet();
      final olderIds = _olderMessages.map((d) => d.id).toSet();
      final toAppend = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in page.docs) {
        if (!liveIds.contains(doc.id) && !olderIds.contains(doc.id)) {
          toAppend.add(doc);
        }
      }

      setState(() {
        _olderMessages = [..._olderMessages, ...toAppend];
        final mergedDocs = [..._liveMessages, ..._olderMessages];
        _oldestLoadedDoc =
            mergedDocs.isNotEmpty ? mergedDocs.last : _oldestLoadedDoc;
        if (page.docs.length < _kMessagesPageSize) {
          _hasMoreMessages = false;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messagesError = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.minScrollExtent;
      if ((_scrollController.offset - target).abs() < 4) return;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _ensureLatestMessageVisible() {
    _scheduleScrollToBottom();

    // Keyboard animation changes viewport height after focus; scroll again
    // once that resize has settled to keep the latest message visible.
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      _scheduleScrollToBottom();
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '--:--';
    final dt = timestamp.toDate();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _showAdminUserProfile(
    BuildContext context, {
    required String userId,
    required String fallbackUsername,
    required String fallbackAvatarId,
  }) async {
    if (!widget.isAdminMode || userId.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final userDoc = await _usersRef.doc(userId).get();
    if (!context.mounted) return;

    final data = userDoc.data() ?? <String, dynamic>{};
    final username = ((data['username'] ?? fallbackUsername).toString()).trim();
    final email = (data['email'] ?? '').toString().trim();
    final avatarRaw = ((data['avatar'] ?? data['avatarId']) ?? fallbackAvatarId)
        .toString()
        .trim();
    final avatarId = avatarRaw.isEmpty ? 'avatar-01' : avatarRaw;
    final status = (data['status'] ?? 'active').toString();
    final banUntilRaw = data['banUntil'];
    final banUntil = banUntilRaw is Timestamp
        ? banUntilRaw.toDate()
        : (banUntilRaw is DateTime ? banUntilRaw : null);
    final canModerate = userDoc.exists;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AvatarPlus(avatarId, width: 52, height: 52, fit: BoxFit.cover),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username.isEmpty ? l10n.username : username,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: TextStyle(
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            adminStatusLabel(sheetContext, status, banUntil),
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
                if (!canModerate) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.noUsersFound,
                    style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: canModerate
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await banUserWithFeedback(context, userId, days: 3);
                            }
                          : null,
                      child: Text(l10n.banFor3Days),
                    ),
                    FilledButton.tonal(
                      onPressed: canModerate
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await banUserWithFeedback(context, userId, days: 7);
                            }
                          : null,
                      child: Text(l10n.banFor7Days),
                    ),
                    FilledButton(
                      onPressed: canModerate
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await blockUserWithFeedback(context, userId);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.blockPermanently),
                    ),
                    OutlinedButton(
                      onPressed: canModerate
                          ? () async {
                              Navigator.of(sheetContext).pop();
                              await unblockUserWithFeedback(context, userId);
                            }
                          : null,
                      child: Text(l10n.unblockUser),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _previewText(String text) {
    final compact = text.trim().replaceAll('\n', ' ');
    if (compact.length <= 60) return compact;
    return '${compact.substring(0, 60)}...';
  }

  String _displayNameFromRaw(String raw) {
    final l10n = AppLocalizations.of(context)!;
    final value = raw.trim();
    if (value.isEmpty) return l10n.username;

    // Avoid exposing full email addresses in message headers.
    if (value.contains('@')) {
      final local = value.split('@').first.trim();
      return local.isEmpty ? l10n.username : local;
    }

    return value;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (!_canParticipateInChat || text.isEmpty || _isSending) return;

    // Ensure we have the current authenticated user's uid
    final authUid = _chatSessionUid;
    if (authUid == null) return;

    // Fetch the full profile so username/avatarId are populated.
    final currentUser = await _authController.fetchCurrentUser();

    setState(() => _isSending = true);

    try {
      final fullName = currentUser == null
          ? ''
          : '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'
                .trim();
      final username = widget.isAdminMode
          ? _adminDisplayName
          : (currentUser?.username != null &&
                currentUser!.username!.trim().isNotEmpty)
          ? currentUser.username!.trim()
          : fullName.isNotEmpty
          ? fullName
          : _displayNameFromRaw(currentUser?.email ?? '');

      // Always use authenticated user's uid - never use empty string
      final payload = <String, dynamic>{
        'uid': authUid,
        'username': username,
        'avatarId': widget.isAdminMode
            ? 'avatar-02'
            : (currentUser?.avatarId != null &&
                  currentUser!.avatarId!.trim().isNotEmpty)
            ? currentUser.avatarId!.trim()
            : 'avatar-01',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_replyingTo != null) {
        payload['replyTo'] = {
          'messageId': _replyingTo!['messageId'],
          'text': _replyingTo!['text'],
          'username': _replyingTo!['username'],
        };
      }

      await _messagesRef.add(payload);

      if (!mounted) return;
      setState(() {
        _messageController.clear();
        _replyingTo = null;
      });
      _scheduleScrollToBottom();
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.unableSendMessage)));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startReply(String messageId, String username, String text) {
    setState(() {
      _replyingTo = {
        'messageId': messageId,
        'username': username,
        'text': _previewText(text),
      };
    });
  }

  Widget _buildReplySnippet(
    BuildContext context,
    Map<String, dynamic> replyTo,
    bool isMine,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMine
            ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.14)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMine
              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.22)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.replyToUser((replyTo['username'] ?? l10n.username).toString()),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (replyTo['text'] ?? '').toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final currentUser = _authController.currentUser;

    final uid = (data['uid'] ?? '').toString();
    final myUid = widget.isAdminMode ? _adminUid : currentUser?.uid;
    final isMine = myUid != null && uid == myUid;

    final usernameRaw = (data['username'] ?? '').toString().trim();
    final username = _displayNameFromRaw(usernameRaw);

    final avatarRaw = (data['avatarId'] ?? '').toString().trim();
    final avatarId = avatarRaw.isEmpty ? 'avatar-01' : avatarRaw;

    final text = (data['text'] ?? '').toString();
    final timestamp = data['timestamp'] is Timestamp
        ? data['timestamp'] as Timestamp
        : null;

    final hasReply = data['replyTo'] is Map<String, dynamic>;
    final replyTo = hasReply
        ? data['replyTo'] as Map<String, dynamic>
        : <String, dynamic>{};

    final bubbleColor = isMine
        ? AppTheme.primaryTeal
        : Theme.of(context).colorScheme.surface;
    final textColor = isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            GestureDetector(
              onTap: widget.isAdminMode
                  ? () => _showAdminUserProfile(
                        context,
                        userId: uid,
                        fallbackUsername: username,
                        fallbackAvatarId: avatarId,
                      )
                  : null,
              child: AvatarPlus(avatarId, width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: GestureDetector(
              onLongPress: () => _startReply(doc.id, username, text),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 0),
                        bottomRight: Radius.circular(isMine ? 0 : 16),
                      ),
                      border: isMine
                          ? null
                          : Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasReply)
                          _buildReplySnippet(context, replyTo, isMine),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isAuthenticated) {
    final l10n = AppLocalizations.of(context)!;
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    if (!isAuthenticated) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: borderColor.withValues(alpha: 0.8)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.mediumGrey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.signInToParticipate,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.mediumGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final canSend = _messageController.text.trim().isNotEmpty && !_isSending;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: borderColor.withValues(alpha: 0.8)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.replyToUser(_replyingTo!['username'].toString()),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          (_replyingTo!['text'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.cancelReply,
                    onPressed: () => setState(() => _replyingTo = null),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  // Pull message input text from localization for live language switching.
                  decoration: InputDecoration(hintText: l10n.writeMessageHint),
                  onTap: _ensureLatestMessageVisible,
                  onChanged: (_) {
                    setState(() {});
                    _ensureLatestMessageVisible();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: canSend ? _sendMessage : null,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: canSend
                            ? Theme.of(context).colorScheme.primary
                            : AppTheme.mediumGrey,
                      ),
                tooltip: l10n.send,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated = _canParticipateInChat;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          AppHeader(
            title: l10n.community,
            subtitle: l10n.publicDiscussion,
            leading: Icon(
              Icons.forum,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isMessagesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_messagesError != null && _visibleMessages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.messagesLoadError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final docs = _visibleMessages;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.beFirstToWrite,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.mediumGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(top: 10, bottom: 16),
                  itemCount: docs.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == docs.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return _buildMessageTile(context, docs[index]);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: _buildInputArea(context, isAuthenticated),
          ),
        ],
      ),
    );
  }
}
