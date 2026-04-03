// Firestore rule: allow read: if true; allow write: if request.auth != null;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _authController = AuthController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final CollectionReference<Map<String, dynamic>> _messagesRef =
      FirebaseFirestore.instance.collection('community_messages');

  Map<String, dynamic>? _replyingTo;
  int _lastMessageCount = -1;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '--:--';
    final dt = timestamp.toDate();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _previewText(String text) {
    final compact = text.trim().replaceAll('\n', ' ');
    if (compact.length <= 60) return compact;
    return '${compact.substring(0, 60)}...';
  }

  String _displayNameFromRaw(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Utilisateur';

    // Avoid exposing full email addresses in message headers.
    if (value.contains('@')) {
      final local = value.split('@').first.trim();
      return local.isEmpty ? 'Utilisateur' : local;
    }

    return value;
  }

  Future<void> _sendMessage() async {
    final currentUser = _authController.currentUser;
    final text = _messageController.text.trim();

    if (currentUser == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final fullName =
        '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim();
      final username = (currentUser.username != null &&
          currentUser.username!.trim().isNotEmpty)
        ? currentUser.username!.trim()
        : fullName.isNotEmpty
          ? fullName
          : _displayNameFromRaw(currentUser.email);

      final payload = <String, dynamic>{
        'uid': currentUser.uid,
        'username': username,
        'avatarId': (currentUser.avatarId != null &&
                currentUser.avatarId!.trim().isNotEmpty)
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer le message.'),
        ),
      );
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

  Widget _buildHeader(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal,
            AppTheme.lightTeal,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.forum, color: onPrimary, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communauté',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: onPrimary,
                  ),
                ),
                Text(
                  'Discussion publique',
                  style: TextStyle(
                    fontSize: 12,
                    color: onPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplySnippet(
    BuildContext context,
    Map<String, dynamic> replyTo,
    bool isMine,
  ) {
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
            'Réponse à ${replyTo['username'] ?? 'Utilisateur'}',
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
    final isMine = currentUser != null && uid == currentUser.uid;

    final usernameRaw = (data['username'] ?? '').toString().trim();
    final username = _displayNameFromRaw(usernameRaw);

    final avatarRaw = (data['avatarId'] ?? '').toString().trim();
    final avatarId = avatarRaw.isEmpty ? 'avatar-01' : avatarRaw;

    final text = (data['text'] ?? '').toString();
    final timestamp = data['timestamp'] is Timestamp
        ? data['timestamp'] as Timestamp
        : null;

    final hasReply = data['replyTo'] is Map<String, dynamic>;
    final replyTo =
        hasReply ? data['replyTo'] as Map<String, dynamic> : <String, dynamic>{};

    final bubbleColor = isMine
        ? AppTheme.primaryTeal
        : Theme.of(context).colorScheme.surface;
    final textColor = isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            AvatarPlus(
              avatarId,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
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
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            Icon(
              Icons.info_outline,
              color: AppTheme.mediumGrey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connectez-vous pour participer',
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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
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
                          'Réponse à ${_replyingTo!['username']}',
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Annuler la réponse',
                    onPressed: () => setState(() => _replyingTo = null),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
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
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Écrire un message...',
                  ),
                  onChanged: (_) => setState(() {}),
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
                tooltip: 'Envoyer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authController.currentUser != null;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesRef.orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur de chargement des messages',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.length != _lastMessageCount) {
                  _lastMessageCount = docs.length;
                  _scheduleScrollToBottom();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Soyez le premier à écrire!',
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
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return _buildMessageTile(context, docs[index]);
                  },
                );
              },
            ),
          ),
          _buildInputArea(context, isAuthenticated),
        ],
      ),
    );
  }
}
