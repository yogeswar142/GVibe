import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/services/api_service.dart';
import '../../core/services/socket_service.dart';
import 'community_profile_screen.dart';

// ── Local message model ────────────────────────────────────────────────────────

class _ComMsg {
  final String? id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final bool isMe;
  final bool isSystem;
  final String text;
  final String time;

  const _ComMsg({
    this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.isMe,
    this.isSystem = false,
    required this.text,
    required this.time,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class CommunityChatScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_ComMsg> _messages = [];
  Map<String, dynamic>? _communityInfo;
  String? _myId;

  bool _loading     = true;
  bool _sending     = false;
  bool _hasMore     = false;
  bool _loadingMore = false;
  String? _oldestId;
  String? _error;

  // Typing state: userId → timer
  final Map<String, Timer> _typingTimers = {};
  final Set<String> _typingUsers = {};

  StreamSubscription<CommunityMessage>? _msgSub;
  StreamSubscription<TypingEvent>?      _typingSub;

  Timer? _myTypingTimer;

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
    _msgSub?.cancel();
    _typingSub?.cancel();
    _myTypingTimer?.cancel();
    for (final t in _typingTimers.values) { t.cancel(); }
    super.dispose();
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('user_id');

    // Join the socket room for this community
    SocketService.instance.joinCommunityRoom(widget.communityId);

    await Future.wait([_loadHistory(), _loadCommunityInfo()]);
    _subscribeToSocket();
  }

  // ── Scroll → older messages ───────────────────────────────────────────────

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 50 && _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _loadCommunityInfo() async {
    try {
      // We already have the name from the route. Fetch member count etc.
      final r = await ApiService().dio.get(
        '/messages/communities',
      );
      if (r.data['success'] == true) {
        final communities = r.data['data'] as List;
        final match = communities.firstWhere(
          (c) => c['_id']?.toString() == widget.communityId,
          orElse: () => null,
        );
        if (match != null && mounted) {
          setState(() => _communityInfo = Map<String, dynamic>.from(match));
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await ApiService().dio.get(
        '/messages/communities/${widget.communityId}/messages',
      );
      if (r.data['success'] == true) {
        final raw = List<Map<String, dynamic>>.from(r.data['data'] ?? []);
        _hasMore  = r.data['hasMore'] == true;
        _oldestId = raw.isNotEmpty ? raw.first['_id']?.toString() : null;

        setState(() {
          _messages
            ..clear()
            ..add(_systemMarker('Community chat · messages visible to all members'))
            ..addAll(raw.map(_buildFromRaw));
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
        '/messages/communities/${widget.communityId}/messages',
        queryParameters: {'before': _oldestId},
      );
      if (r.data['success'] == true) {
        final raw = List<Map<String, dynamic>>.from(r.data['data'] ?? []);
        _hasMore  = r.data['hasMore'] == true;
        if (raw.isNotEmpty) _oldestId = raw.first['_id']?.toString();

        final prevLen = _messages.length;
        setState(() {
          _messages.insertAll(1, raw.map(_buildFromRaw));
          _loadingMore = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final added = _messages.length - prevLen;
          if (_scrollCtrl.hasClients && added > 0) {
            _scrollCtrl.jumpTo(_scrollCtrl.offset + added * 68.0);
          }
        });
      }
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  _ComMsg _systemMarker(String text) => _ComMsg(
    senderId: '', senderName: '', isMe: false, isSystem: true,
    text: text, time: '',
  );

  _ComMsg _buildFromRaw(Map<String, dynamic> m) {
    final sender   = m['sender'] is Map ? m['sender'] as Map<String, dynamic> : <String, dynamic>{};
    final senderId = sender['_id']?.toString() ?? m['sender']?.toString() ?? '';
    return _ComMsg(
      id:           m['_id']?.toString(),
      senderId:     senderId,
      senderName:   sender['name']?.toString() ?? 'Unknown',
      senderAvatar: sender['avatar']?.toString(),
      isMe:         senderId == _myId,
      text:         m['content']?.toString() ?? '',
      time:         _formatTime(m['createdAt']?.toString() ?? ''),
    );
  }

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

  // ── Socket ────────────────────────────────────────────────────────────────

  void _subscribeToSocket() {
    _msgSub = SocketService.instance.communityStream.listen((msg) {
      if (msg.communityId != widget.communityId) return;
      if (mounted) {
        setState(() {
          _messages.add(_ComMsg(
            id:           msg.id,
            senderId:     msg.senderId,
            senderName:   msg.senderName,
            senderAvatar: msg.senderAvatar,
            isMe:         msg.senderId == _myId,
            text:         msg.content,
            time:         _formatTime(msg.createdAt.toString()),
          ));
        });
        _scrollToBottom();
      }
    });

    _typingSub = SocketService.instance.comTypingStream.listen((t) {
      if (t.senderId == _myId) return;
      _typingTimers[t.senderId]?.cancel();
      if (t.isTyping) {
        if (mounted) setState(() => _typingUsers.add(t.senderId));
        _typingTimers[t.senderId] = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _typingUsers.remove(t.senderId));
        });
      } else {
        if (mounted) setState(() => _typingUsers.remove(t.senderId));
      }
    });
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();
    _myTypingTimer?.cancel();
    SocketService.instance.sendCommunityTyping(widget.communityId, isTyping: false);

    final ok = await SocketService.instance.sendCommunityMessage(
      communityId: widget.communityId,
      content: text,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send — please retry')),
      );
    }
    if (mounted) setState(() => _sending = false);
  }

  void _onTextChanged(String val) {
    SocketService.instance.sendCommunityTyping(widget.communityId, isTyping: val.isNotEmpty);
    _myTypingTimer?.cancel();
    if (val.isNotEmpty) {
      _myTypingTimer = Timer(const Duration(milliseconds: 1500), () {
        SocketService.instance.sendCommunityTyping(widget.communityId, isTyping: false);
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final nameColor   = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subColor    = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final errorColor  = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);

    final memberCount = _communityInfo?['memberCount'] ?? '...';
    final avatar      = _communityInfo?['avatar']?.toString();

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
                imageUrl: avatar,
                initials: widget.communityName.isNotEmpty ? widget.communityName[0] : '#',
                size: 40,
                showGlow: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.communityName,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: nameColor, fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    _typingUsers.isNotEmpty
                        ? Text(
                            '${_typingUsers.length == 1 ? 'Someone' : '${_typingUsers.length} people'} typing...',
                            style: AppTextStyles.bodyXs.copyWith(color: accentColor, fontWeight: FontWeight.w600),
                          )
                        : Text(
                            '$memberCount members',
                            style: AppTextStyles.bodyXs.copyWith(color: subColor),
                          ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline_rounded, color: nameColor, size: 22),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityProfileScreen(
                        communityId: widget.communityId,
                        communityName: widget.communityName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accentColor)))
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
                      LinearProgressIndicator(color: accentColor, backgroundColor: borderColor, minHeight: 2),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          if (msg.isSystem) return _buildSystemMarker(msg.text, context);
                          // Group consecutive messages from same sender
                          final prev = i > 0 ? _messages[i - 1] : null;
                          final showSender = prev == null || prev.isSystem || prev.senderId != msg.senderId;
                          return _buildBubble(msg, context, showSender: showSender);
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.groups_rounded, color: textColor, size: 10),
              const SizedBox(width: 4),
              Text(text, style: AppTextStyles.bodyXs.copyWith(color: textColor)),
            ]),
          ),
          Expanded(child: Divider(color: borderColor)),
        ],
      ),
    );
  }

  Widget _buildBubble(_ComMsg msg, BuildContext context, {required bool showSender}) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final double radius = isDark ? 8 : 16;

    final sentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final recColor  = isDark ? const Color(0xFF121315) : const Color(0xFFF3F4F6);
    final recBorder = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final timeColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final senderLabelColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Padding(
      padding: EdgeInsets.only(bottom: showSender ? 12 : 4),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar — only show on first message in a group, else spacer
          if (!msg.isMe) ...[
            if (showSender)
              GVibeAvatar(
                imageUrl: msg.senderAvatar,
                initials: msg.senderName.isNotEmpty ? msg.senderName[0] : '?',
                size: 30,
              )
            else
              const SizedBox(width: 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (only on first in group, not for self)
                if (showSender && !msg.isMe) ...[
                  Text(
                    msg.senderName,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: senderLabelColor, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
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
                            color: msg.isMe ? Colors.white : textColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(msg.time, style: AppTextStyles.monoXs.copyWith(color: timeColor, fontSize: 10)),
                  ],
                ),
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
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(isDark ? 8 : 22),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  onChanged: _onTextChanged,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  style: AppTextStyles.bodyMd.copyWith(color: inputColor),
                  decoration: InputDecoration(
                    hintText: 'Message #${widget.communityName}...',
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
                  borderRadius: BorderRadius.circular(isDark ? 8 : 22),
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
