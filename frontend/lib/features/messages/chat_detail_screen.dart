import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';
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
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    
    final displayName = _recipientProfile?['name']?.toString() ?? 'Loading...';
    final avatarUrl = _recipientProfile?['avatar']?.toString();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 48, 16, 10),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: ext.outline, width: 0.5)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: cs.onSurface, size: 22),
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
                      style: AppTextStyles.headlineMd
                          .copyWith(color: cs.onSurface),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text('Online',
                            style: AppTextStyles.bodyXs.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: cs.error)),
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
                          return _buildBubble(msg, context, ext);
                        },
                      ),
                    ),
                    _buildInputBar(context, ext),
                  ],
                ),
    );
  }

  Widget _buildSystemMarker(String text, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: ext.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: cs.onSurfaceVariant, size: 10),
                const SizedBox(width: 4),
                Text(text,
                    style: AppTextStyles.bodyXs
                        .copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(child: Divider(color: ext.outline)),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, BuildContext context,
      AppThemeExtension ext) {
    final isMe = msg['isMe'] as bool;
    final cs = Theme.of(context).colorScheme;
    final displayName = _recipientProfile?['name']?.toString() ?? '';
    final avatarUrl = _recipientProfile?['avatar']?.toString();

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
                    gradient: isMe ? ext.primaryGradient : null,
                    color: isMe ? null : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg['text'],
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isMe ? Colors.white : cs.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg['time'],
                  style: AppTextStyles.monoXs
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, AppThemeExtension ext) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: ext.outline, width: 0.5)),
        ),
        child: Row(
          children: [
            // Attachment
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_rounded,
                  color: cs.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 10),
            // Input
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ext.outline, width: 0.5),
                ),
                child: TextField(
                  controller: _messageController,
                  onSubmitted: (_) => _sendMessage(),
                  style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    hintStyle: AppTextStyles.bodyMd
                        .copyWith(color: cs.onSurfaceVariant),
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
                  gradient: ext.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
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
