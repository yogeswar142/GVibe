import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/services/api_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String threadId;
  const ChatDetailScreen({super.key, required this.threadId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _recipientProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profileRes = await ApiService().dio.get('/users/${widget.threadId}');
      final messagesRes = await ApiService().dio.get('/messages/dms/${widget.threadId}');
      
      if (profileRes.data['success'] == true && messagesRes.data['success'] == true) {
        final profile = profileRes.data['data'];
        final List<dynamic> rawMsgs = messagesRes.data['data'] ?? [];
        
        setState(() {
          _recipientProfile = profile;
          _messages.clear();
          
          _messages.add({
            'sender': 'system',
            'text': 'Encryption enabled · messages are private',
            'time': '',
            'isMe': false
          });
          
          for (final m in rawMsgs) {
            final senderId = m['sender'] is Map ? m['sender']['_id'] : m['sender'];
            final isMe = senderId != widget.threadId;
            final dateStr = m['createdAt']?.toString() ?? '';
            _messages.add({
              'sender': isMe ? 'me' : widget.threadId,
              'text': m['content'] ?? '',
              'time': _formatTime(dateStr),
              'isMe': isMe,
            });
          }
          _loading = false;
        });
        
        _scrollToBottom();
      }
    } on DioException catch (e) {
      setState(() {
        _error = ApiService.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  String _formatTime(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    try {
      final response = await ApiService().dio.post('/messages/send', data: {
        'receiverId': widget.threadId,
        'content': text,
      });
      
      if (response.data['success'] == true) {
        final m = response.data['data'];
        final dateStr = m['createdAt']?.toString() ?? '';
        setState(() {
          _messages.add({
            'sender': 'me',
            'text': m['content'] ?? '',
            'time': _formatTime(dateStr),
            'isMe': true,
          });
        });
        _scrollToBottom();
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final statusColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final iconColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF666666);
    final errorColor = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);

    final displayName = _recipientProfile?['name']?.toString() ?? 'Loading...';
    final avatarUrl = _recipientProfile?['avatar']?.toString();

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
                icon: Icon(Icons.arrow_back_rounded,
                    color: nameColor, size: 22),
                onPressed: () => context.pop(),
              ),
              GVibeAvatar(
                  imageUrl: avatarUrl,
                  initials: displayName.isNotEmpty ? displayName[0] : '?',
                  size: 40,
                  showGlow: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: nameColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF34C77B), // success
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online',
                          style: AppTextStyles.bodyXs.copyWith(
                            color: statusColor,
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
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMd.copyWith(color: errorColor),
                      ),
                      const SizedBox(height: 16),
                      GVibeButton(label: 'Retry', onPressed: _loadChatData),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          if (msg['sender'] == 'system') {
                            return _buildSystemMarker(msg['text'], context);
                          }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

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
                Text(text,
                    style: AppTextStyles.bodyXs.copyWith(color: textColor)),
              ],
            ),
          ),
          Expanded(child: Divider(color: borderColor)),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, BuildContext context) {
    final isMe = msg['isMe'] as bool;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = _recipientProfile?['name']?.toString() ?? '';
    final avatarUrl = _recipientProfile?['avatar']?.toString();

    final double radius = isDark ? 8 : 16;
    final sentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final recColor = isDark ? const Color(0xFF121315) : const Color(0xFFF3F4F6);
    final recBorder = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final timeColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GVibeAvatar(
                imageUrl: avatarUrl,
                initials: displayName.isNotEmpty ? displayName[0] : '?',
                size: 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? sentColor : recColor,
                    border: isMe ? null : Border.all(color: recBorder, width: 1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                      topRight: Radius.circular(radius),
                      bottomLeft: Radius.circular(isMe ? radius : 4),
                      bottomRight: Radius.circular(isMe ? 4 : radius),
                    ),
                  ),
                  child: Text(
                    msg['text'],
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isMe ? Colors.white : textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg['time'],
                  style: AppTextStyles.monoXs.copyWith(color: timeColor),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final inputBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final buttonBg = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final inputColor = isDark ? Colors.white : const Color(0xFF171717);
    final hintColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            // Attachment
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Icon(Icons.add_rounded,
                  color: hintColor, size: 20),
            ),
            const SizedBox(width: 10),
            // Input
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
                  controller: _messageController,
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
            // Send
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: buttonBg,
                  borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
