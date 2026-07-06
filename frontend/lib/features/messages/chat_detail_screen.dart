import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/services/api_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/encryption_service.dart';

// ── Local message model ───────────────────────────────────────────────────────

class _ChatMsg {
  final String? id;
  final bool isMe;
  final bool isSystem;
  final String text;         // decrypted plaintext (or system label)
  final String time;
  final bool decryptFailed;

  const _ChatMsg({
    this.id,
    required this.isMe,
    this.isSystem = false,
    required this.text,
    required this.time,
    this.decryptFailed = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class ChatDetailScreen extends StatefulWidget {
  final String threadId; // recipient's userId
  const ChatDetailScreen({super.key, required this.threadId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_ChatMsg> _messages = [];
  Map<String, dynamic>? _recipientProfile;
  String? _recipientPublicKey; // Base64 X25519 key for encrypting outbound msgs
  String? _myId;

  bool _loading      = true;
  bool _sending      = false;
  bool _isTyping     = false;   // recipient is typing
  bool _isOnline     = false;
  bool _hasMore      = false;
  bool _loadingMore  = false;
  String? _oldestId;            // cursor for pagination
  String? _error;

  // Subscriptions
  StreamSubscription<DmMessage>?   _dmSub;
  StreamSubscription<TypingEvent>? _typingSub;
  StreamSubscription<String>?      _readSub;
  StreamSubscription<String>?      _onlineSub;
  StreamSubscription<String>?      _offlineSub;

  Timer? _typingTimer;          // debounce "stopped typing"
  Timer? _typingClearTimer;     // hide "... is typing" after 3 s

  @override
  void initState() {
    super.initState();
    _init();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _dmSub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    _typingTimer?.cancel();
    _typingClearTimer?.cancel();
    super.dispose();
  }

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('user_id');

    // Fetch recipient's public key FIRST so it is guaranteed available for decryption
    await _fetchRecipientPublicKey();

    await Future.wait([
      _loadProfile(),
      _loadHistory(),
      _uploadMyPublicKey(),
    ]);

    _subscribeToSocket();
    // Send read receipt once we open the conversation
    SocketService.instance.sendReadAck(widget.threadId);
  }

  // ── Scroll → load older messages ─────────────────────────────────────────

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 50 && _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final r = await ApiService().dio.get('/users/${widget.threadId}');
      if (r.data['success'] == true) {
        final p = r.data['data'];
        setState(() => _recipientProfile = p);
      }
    } catch (_) {}
  }

  Future<void> _fetchRecipientPublicKey() async {
    try {
      final r = await ApiService().dio.get('/messages/keys/${widget.threadId}');
      if (r.data['success'] == true) {
        _recipientPublicKey = r.data['data']?['x25519']?.toString();
      }
    } catch (_) {}
  }

  Future<void> _uploadMyPublicKey() async {
    try {
      final myPub = await EncryptionService.instance.getMyPublicKeyBase64();
      await ApiService().dio.put('/messages/keys/public', data: {'x25519': myPub});
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_recipientPublicKey == null) {
        await _fetchRecipientPublicKey();
      }
      final r = await ApiService().dio.get('/messages/dms/${widget.threadId}');
      if (r.data['success'] == true) {
        final rawMsgs = List<Map<String, dynamic>>.from(r.data['data'] ?? []);
        _hasMore  = r.data['hasMore'] == true;
        _oldestId = rawMsgs.isNotEmpty ? rawMsgs.first['_id']?.toString() : null;

        final built = await _buildMessages(rawMsgs);
        setState(() {
          _messages
            ..clear()
            ..add(const _ChatMsg(isMe: false, isSystem: true, text: 'End-to-end encrypted · only you can read these messages', time: ''))
            ..addAll(built);
          _loading = false;
        });
        _scrollToBottom();
      }
    } on DioException catch (e) {
      setState(() { _error = ApiService.getErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _oldestId == null) return;
    setState(() => _loadingMore = true);
    try {
      final r = await ApiService().dio.get(
        '/messages/dms/${widget.threadId}',
        queryParameters: {'before': _oldestId},
      );
      if (r.data['success'] == true) {
        final rawMsgs = List<Map<String, dynamic>>.from(r.data['data'] ?? []);
        _hasMore  = r.data['hasMore'] == true;
        if (rawMsgs.isNotEmpty) _oldestId = rawMsgs.first['_id']?.toString();

        final built = await _buildMessages(rawMsgs);
        final prevLen = _messages.length;
        setState(() {
          _messages.insertAll(1, built); // after system marker
          _loadingMore = false;
        });
        // Keep scroll position stable after prepend
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final added = _messages.length - prevLen;
          if (_scrollCtrl.hasClients && added > 0) {
            _scrollCtrl.jumpTo(_scrollCtrl.offset + (added * 72.0));
          }
        });
      }
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  /// Decrypts a batch of raw messages from the API.
  Future<List<_ChatMsg>> _buildMessages(List<Map<String, dynamic>> rawMsgs) async {
    final results = <_ChatMsg>[];
    for (final m in rawMsgs) {
      final senderId = (m['sender'] is Map ? m['sender']['_id'] : m['sender'])?.toString() ?? '';
      final isMe     = senderId == _myId;
      final time     = _formatTime(m['createdAt']?.toString() ?? '');

      // E2EE message
      if (m['ciphertext'] != null) {
        String text;
        bool failed = false;

        if (_recipientPublicKey == null) {
          text   = '🔒 Cannot decrypt (missing key)';
          failed = true;
        } else {
          final decrypted = await EncryptionService.instance.decrypt(
            ciphertextBase64:          m['ciphertext'].toString(),
            nonceBase64:               m['nonce'].toString(),
            macBase64:                 m['mac'].toString(),
            remotePartyPublicKeyBase64: _recipientPublicKey!,
          );
          text   = decrypted ?? '🔒 Could not decrypt';
          failed = decrypted == null;
        }

        results.add(_ChatMsg(id: m['_id']?.toString(), isMe: isMe, text: text, time: time, decryptFailed: failed));
      } else {
        // Legacy plaintext (before E2EE was active)
        results.add(_ChatMsg(id: m['_id']?.toString(), isMe: isMe, text: m['content']?.toString() ?? '', time: time));
      }
    }
    return results;
  }

  // ── Socket Subscriptions ──────────────────────────────────────────────────

  void _subscribeToSocket() {
    _dmSub = SocketService.instance.dmStream.listen((dm) async {
      if (dm.senderId != widget.threadId && dm.receiverId != widget.threadId) return;

      final isMe = dm.senderId == _myId;

      // If we are the sender, check if we already have an optimistic message in the list
      if (isMe) {
        final optIndex = _messages.indexWhere((m) => m.isMe && m.id == null);
        if (optIndex != -1) {
          if (mounted) {
            setState(() {
              _messages[optIndex] = _ChatMsg(
                id:             dm.id,
                isMe:           true,
                text:           _messages[optIndex].text, // Keep already decrypted text
                time:           _formatTime(dm.createdAt.toString()),
                decryptFailed:  false,
              );
            });
          }
          return;
        }
      }

      if (_recipientPublicKey == null) {
        await _fetchRecipientPublicKey();
      }

      final decoded = _recipientPublicKey == null ? null : await EncryptionService.instance.decrypt(
        ciphertextBase64:          dm.ciphertext,
        nonceBase64:               dm.nonce,
        macBase64:                 dm.mac,
        remotePartyPublicKeyBase64: _recipientPublicKey!,
      );

      final msg = _ChatMsg(
        id:             dm.id,
        isMe:           isMe,
        text:           decoded ?? '🔒 Could not decrypt',
        time:           _formatTime(dm.createdAt.toString()),
        decryptFailed:  decoded == null,
      );

      if (mounted) setState(() => _messages.add(msg));
      _scrollToBottom();

      // Auto read receipt if the message is from them
      if (!isMe) SocketService.instance.sendReadAck(widget.threadId);
    });

    _typingSub = SocketService.instance.dmTypingStream.listen((t) {
      if (t.senderId != widget.threadId) return;
      _typingClearTimer?.cancel();
      if (mounted) setState(() => _isTyping = t.isTyping);
      if (t.isTyping) {
        _typingClearTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isTyping = false);
        });
      }
    });

    _readSub = SocketService.instance.readAckStream.listen((readBy) {
      if (readBy != widget.threadId) return;
      // Could mark messages as read here — kept simple for MVP
    });

    _onlineSub = SocketService.instance.onlineStream.listen((uid) {
      if (uid == widget.threadId && mounted) setState(() => _isOnline = true);
    });

    _offlineSub = SocketService.instance.offlineStream.listen((uid) {
      if (uid == widget.threadId && mounted) setState(() => _isOnline = false);
    });
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    if (_recipientPublicKey == null) {
      await _fetchRecipientPublicKey();
    }

    if (_recipientPublicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipient's encryption key not found. Try again.")),
      );
      return;
    }

    setState(() => _sending = true);
    _msgCtrl.clear();
    _typingTimer?.cancel();
    SocketService.instance.sendDmTyping(widget.threadId, isTyping: false);

    // BUG-06 fix: Optimistically add the message immediately so the user
    // gets instant feedback. We'll remove it only on an explicit server error.
    final optimisticMsg = _ChatMsg(
      id:            null,
      isMe:          true,
      text:          text,
      time:          _formatTime(DateTime.now().toLocal().toString()),
      decryptFailed: false,
    );
    if (mounted) {
      setState(() => _messages.add(optimisticMsg));
      _scrollToBottom();
    }

    try {
      final encrypted = await EncryptionService.instance.encrypt(
        plaintext:                text,
        recipientPublicKeyBase64: _recipientPublicKey!,
      );

      final ok = await SocketService.instance.sendDM(
        receiverId: widget.threadId,
        ciphertext: encrypted['ciphertext']!,
        nonce:      encrypted['nonce']!,
        mac:        encrypted['mac']!,
      );

      if (!ok && mounted) {
        // Explicit failure (not a timeout) — remove the optimistic message
        setState(() => _messages.remove(optimisticMsg));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send — please retry')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.remove(optimisticMsg));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onTextChanged(String value) {
    // Debounce typing indicator: emit "typing" immediately, then "stopped" after 1.5 s
    SocketService.instance.sendDmTyping(widget.threadId, isTyping: value.isNotEmpty);
    _typingTimer?.cancel();
    if (value.isNotEmpty) {
      _typingTimer = Timer(const Duration(milliseconds: 1500), () {
        SocketService.instance.sendDmTyping(widget.threadId, isTyping: false);
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m  = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return ''; }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final nameColor    = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final statusColor  = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final borderColor  = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final iconColor    = isDark ? const Color(0xFF838EA6) : const Color(0xFF666666);
    final errorColor   = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);

    final displayName = _recipientProfile?['name']?.toString() ?? 'Loading...';
    final avatarUrl   = _recipientProfile?['avatar']?.toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 48, 16, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: nameColor, size: 22),
                onPressed: () => context.pop(),
              ),
              GVibeAvatar(
                imageUrl: avatarUrl,
                initials: displayName.isNotEmpty ? displayName[0] : '?',
                size: 40,
                showGlow: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(displayName,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: nameColor, fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 6, height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _isOnline ? const Color(0xFF34C77B) : const Color(0xFF888888),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isTyping ? 'typing...' : (_isOnline ? 'Online' : 'Offline'),
                          style: AppTextStyles.bodyXs.copyWith(
                            color: _isTyping ? statusColor : (_isOnline ? statusColor : iconColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert_rounded, color: iconColor),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(statusColor)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: errorColor)),
                      const SizedBox(height: 16),
                      GVibeButton(label: 'Retry', onPressed: _loadHistory),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_loadingMore)
                      LinearProgressIndicator(
                        color: statusColor,
                        backgroundColor: borderColor,
                        minHeight: 2,
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          if (msg.isSystem) return _buildSystemMarker(msg.text, context);
                          return _buildBubble(msg, context);
                        },
                      ),
                    ),
                    _buildInputBar(context),
                  ],
                ),
    );
  }

  Widget _buildSystemMarker(String text, BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor   = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: textColor, size: 10),
                const SizedBox(width: 4),
                Text(text, style: AppTextStyles.bodyXs.copyWith(color: textColor)),
              ],
            ),
          ),
          Expanded(child: Divider(color: borderColor)),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMsg msg, BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final displayName = _recipientProfile?['name']?.toString() ?? '';
    final avatarUrl   = _recipientProfile?['avatar']?.toString();

    final double radius = isDark ? 8 : 16;
    final sentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final recColor  = isDark ? const Color(0xFF121315) : const Color(0xFFF3F4F6);
    final recBorder = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final timeColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final failColor = isDark ? const Color(0xFF838EA6) : const Color(0xFFAAAAAA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            GVibeAvatar(
              imageUrl: avatarUrl,
              initials: displayName.isNotEmpty ? displayName[0] : '?',
              size: 30,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isMe ? sentColor : recColor,
                    border: msg.isMe ? null : Border.all(color: recBorder, width: 1),
                    borderRadius: BorderRadius.only(
                      topLeft:     Radius.circular(radius),
                      topRight:    Radius.circular(radius),
                      bottomLeft:  Radius.circular(msg.isMe ? radius : 4),
                      bottomRight: Radius.circular(msg.isMe ? 4 : radius),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: msg.decryptFailed ? failColor : (msg.isMe ? Colors.white : textColor),
                      fontSize: 14,
                      fontStyle: msg.decryptFailed ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(msg.time, style: AppTextStyles.monoXs.copyWith(color: timeColor)),
              ],
            ),
          ),
          if (msg.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final inputBg     = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final buttonBg    = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final inputColor  = isDark ? Colors.white : const Color(0xFF171717);
    final hintColor   = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            // Attachment placeholder
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Icon(Icons.add_rounded, color: hintColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _sendMessage(),
                  style: AppTextStyles.bodyMd.copyWith(color: inputColor),
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    hintStyle: AppTextStyles.bodyMd.copyWith(color: hintColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _sending ? buttonBg.withValues(alpha: 0.5) : buttonBg,
                  borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
