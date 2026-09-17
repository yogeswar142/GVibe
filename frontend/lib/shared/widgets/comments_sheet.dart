import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import 'gvibe_widgets.dart';
import 'discord_hyperlink.dart';
import 'emoji_picker_panel.dart';

class CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final ValueChanged<int>? onCommentsCountChanged;

  const CommentsSheet({
    super.key,
    required this.post,
    this.onCommentsCountChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> post,
    ValueChanged<int>? onCommentsCountChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(
        post: post,
        onCommentsCountChanged: onCommentsCountChanged,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  String? _currentUserId;
  String? _currentUserAvatar;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post['comments'] as List? ?? []);
    _loadCurrentUserAndComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserAndComments() async {
    final cached = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _currentUserId = cached?['_id']?.toString();
        _currentUserAvatar = cached?['avatar']?.toString();
      });
    }

    final postId = widget.post['_id']?.toString() ?? widget.post['id']?.toString();
    if (postId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final res = await ApiService().dio.get('/posts/$postId/comments');
      if (res.data['success'] == true && mounted) {
        setState(() {
          _comments = res.data['data'] ?? [];
          _loading = false;
        });
        widget.onCommentsCountChanged?.call(_comments.length);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _submitting) return;

    final postId = widget.post['_id']?.toString() ?? widget.post['id']?.toString();
    if (postId == null) return;

    setState(() => _submitting = true);
    _textController.clear();

    try {
      final res = await ApiService().dio.post(
        '/posts/$postId/comment',
        data: {'text': text},
      );

      if (res.data['success'] == true && mounted) {
        final updatedPost = res.data['data'];
        setState(() {
          _comments = updatedPost['comments'] ?? [];
          _submitting = false;
        });
        widget.onCommentsCountChanged?.call(_comments.length);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final postId = widget.post['_id']?.toString() ?? widget.post['id']?.toString();
    if (postId == null) return;

    try {
      final res = await ApiService().dio.delete('/posts/$postId/comments/$commentId');
      if (res.data['success'] == true && mounted) {
        final updatedPost = res.data['data'];
        setState(() {
          _comments = updatedPost['comments'] ?? [];
        });
        widget.onCommentsCountChanged?.call(_comments.length);
      }
    } catch (_) {}
  }

  String _timeAgo(String dateString) {
    if (dateString.isEmpty) return 'just now';
    try {
      final dt = DateTime.parse(dateString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1011) : Colors.white;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final inputBg = isDark ? const Color(0xFF16191E) : const Color(0xFFF4F5F7);

    final postAuthor = widget.post['author'] is Map ? widget.post['author'] as Map : null;
    final postAuthorName = postAuthor?['name']?.toString() ?? 'Student';
    final postContent = widget.post['content']?.toString() ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: subtitleColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: AppTextStyles.headlineSm.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_comments.length}',
                    style: AppTextStyles.monoXs.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: subtitleColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // Mini Post Reference Banner (Reddit / X style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF13161C) : const Color(0xFFF9FAFB),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ',
                  style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                ),
                Text(
                  '@$postAuthorName: ',
                  style: AppTextStyles.bodyXs.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    postContent.replaceAll('\n', ' '),
                    style: AppTextStyles.bodyXs.copyWith(color: titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: borderColor, height: 1),

          // Comments List
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(accentColor),
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 44,
                              color: subtitleColor.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: AppTextStyles.headlineSm.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to share your thoughts!',
                              style: AppTextStyles.bodySm.copyWith(color: subtitleColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (ctx, idx) {
                          final c = _comments[idx];
                          final user = c['user'] is Map ? c['user'] as Map : null;
                          final authorName = user?['name']?.toString() ?? 'Student';
                          final avatar = user?['avatar']?.toString();
                          final initials = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
                          final text = c['text']?.toString() ?? '';
                          final createdAt = c['createdAt']?.toString() ?? '';
                          final timeAgo = _timeAgo(createdAt);
                          final commentId = c['_id']?.toString();
                          final isMyComment = _currentUserId != null &&
                              (user?['_id']?.toString() == _currentUserId || c['user']?.toString() == _currentUserId);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GVibeAvatar(
                                imageUrl: avatar,
                                size: 34,
                                initials: initials,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          authorName,
                                          style: AppTextStyles.headlineSm.copyWith(
                                            color: titleColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeAgo,
                                          style: AppTextStyles.bodyXs.copyWith(
                                            color: subtitleColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (isMyComment && commentId != null)
                                          GestureDetector(
                                            onTap: () => _deleteComment(commentId),
                                            child: Icon(
                                              Icons.delete_outline_rounded,
                                              color: subtitleColor.withValues(alpha: 0.6),
                                              size: 15,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    RichContentText(
                                      text: text,
                                      style: AppTextStyles.bodyMd.copyWith(
                                        color: isDark ? const Color(0xFFE2E4E9) : const Color(0xFF2C2C2E),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                GVibeAvatar(
                  imageUrl: _currentUserAvatar,
                  size: 32,
                  initials: 'ME',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _showEmoji
                        ? Icons.keyboard_alt_outlined
                        : Icons.sentiment_satisfied_alt_rounded,
                    color: _showEmoji ? accentColor : subtitleColor,
                    size: 22,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    if (_showEmoji) {
                      _focusNode.requestFocus();
                      setState(() => _showEmoji = false);
                    } else {
                      FocusScope.of(context).unfocus();
                      setState(() => _showEmoji = true);
                    }
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = false);
                      },
                      style: TextStyle(color: titleColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final canSend = value.text.trim().isNotEmpty && !_submitting;
                    return IconButton(
                      icon: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(accentColor),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              color: canSend ? Colors.white : subtitleColor.withValues(alpha: 0.4),
                              size: 18,
                            ),
                      onPressed: canSend ? _submitComment : null,
                      style: IconButton.styleFrom(
                        backgroundColor: canSend ? accentColor : borderColor,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_showEmoji)
            EmojiPickerPanel(
              onEmojiSelected: (emoji) =>
                  EmojiPickerPanel.insertEmoji(_textController, emoji),
              onBackspace: () =>
                  EmojiPickerPanel.backspace(_textController),
            ),
        ],
      ),
    );
  }
}
