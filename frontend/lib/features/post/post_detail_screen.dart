import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../shared/widgets/share_post_sheet.dart';
import '../../shared/widgets/discord_hyperlink.dart';
import '../../shared/widgets/emoji_picker_panel.dart';

/// Twitter/Reddit-style Post Detail & Continuous Thread Discussion screen.
class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic>? initialPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  String? _currentUserId;
  String? _currentUserAvatar;
  int _likesCount = 0;
  bool _isLiked = false;
  int _sharesCount = 0;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = Map<String, dynamic>.from(widget.initialPost!);
      _initPostState(_post!);
    }
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initPostState(Map<String, dynamic> post) {
    final likes = (post['likes'] as List?) ?? [];
    _likesCount = likes.length;
    _sharesCount = (post['sharesCount'] is num) ? (post['sharesCount'] as num).toInt() : 0;
    _comments = List.from(post['comments'] as List? ?? []);
  }

  Future<void> _loadData() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?['_id']?.toString() ?? user?['id']?.toString();
        _currentUserAvatar = user?['avatar']?.toString();
      });
    }

    try {
      final res = await ApiService().dio.get('/posts/${widget.postId}/comments');
      if (res.data != null && res.data['data'] != null) {
        if (mounted) {
          setState(() {
            _comments = List.from(res.data['data'] as List);
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // Refresh like status if we have current user
    if (_post != null && _currentUserId != null) {
      final likes = (_post!['likes'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _isLiked = likes.any((id) => id.toString() == _currentUserId);
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    final prevLiked = _isLiked;
    final prevCount = _likesCount;

    setState(() {
      _isLiked = !prevLiked;
      _likesCount = _isLiked ? prevCount + 1 : (prevCount - 1).clamp(0, 999999);
    });
    HapticFeedback.lightImpact();

    try {
      final res = await ApiService().dio.put('/posts/${widget.postId}/like');
      if (res.data != null && res.data['data'] != null) {
        final updatedLikes = (res.data['data']['likes'] as List?) ?? [];
        if (mounted) {
          setState(() {
            _likesCount = updatedLikes.length;
            _isLiked = updatedLikes.any((id) => id.toString() == _currentUserId);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = prevLiked;
          _likesCount = prevCount;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    HapticFeedback.lightImpact();

    try {
      final res = await ApiService().dio.post(
        '/posts/${widget.postId}/comment',
        data: {'text': text},
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        _commentController.clear();
        _focusNode.unfocus();

        final postData = res.data['data'];
        if (postData != null && postData['comments'] != null) {
          if (mounted) {
            setState(() {
              _comments = List.from(postData['comments'] as List);
            });
          }
        }

        // Scroll to bottom smoothly to see new comment
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.getErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ApiService().dio.delete('/posts/${widget.postId}/comments/$commentId');
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c['_id']?.toString() == commentId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.getErrorMessage(e))),
        );
      }
    }
  }

  void _openShare() {
    if (_post == null) return;
    SharePostSheet.show(
      context,
      post: _post!,
      onShared: (count) {
        if (mounted) setState(() => _sharesCount = count);
      },
    );
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final actionColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final inputBg = isDark ? const Color(0xFF161B26) : const Color(0xFFF1F3F7);

    final author = _post?['author'] is Map ? _post!['author'] as Map : null;
    final authorName = author?['name']?.toString() ?? 'Student';
    final avatar = author?['avatar']?.toString();
    final initials = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
    final content = _post?['content']?.toString() ?? '';
    final tags = (_post?['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final createdAt = _post?['createdAt']?.toString();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Thread',
          style: AppTextStyles.headlineSm.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleColor, size: 20),
          onPressed: () => Navigator.of(context).pop(_comments.length),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: titleColor, size: 20),
            onPressed: _openShare,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Continuous scrollable view (Post + Comments below)
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // ─── 1. Anchored Original Post ──────────────────────────────
                Container(
                  color: cardBg,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author Row
                      Row(
                        children: [
                          GVibeAvatar(
                            imageUrl: avatar,
                            size: 46,
                            initials: initials,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: AppTextStyles.headlineSm.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _timeAgo(createdAt),
                                  style: AppTextStyles.bodyXs.copyWith(
                                    color: subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Rich Post Content (Discord-style clickable hyperlinks)
                      RichContentText(
                        text: content,
                        style: (isDark ? AppTextStyles.bodyMd : AppTextStyles.bodyMd.copyWith(color: const Color(0xFF1E2229))).copyWith(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      // Tags
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3)).withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#$t',
                                style: AppTextStyles.monoXs.copyWith(
                                  color: isDark ? const Color(0xFF8792FF) : const Color(0xFF0070F3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Divider(color: borderColor, height: 1),
                      const SizedBox(height: 12),

                      // Action bar
                      Row(
                        children: [
                          AnimatedLikeButton(
                            count: _likesCount,
                            isLiked: _isLiked,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 20),
                          InkWell(
                            onTap: () => _focusNode.requestFocus(),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, color: actionColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_comments.length}',
                                    style: AppTextStyles.monoSm.copyWith(
                                      color: actionColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _openShare,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, color: actionColor, size: 18),
                                  if (_sharesCount > 0) ...[
                                    const SizedBox(width: 5),
                                    Text(
                                      '$_sharesCount',
                                      style: AppTextStyles.monoSm.copyWith(
                                        color: actionColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Thread Section Separator
                Container(
                  color: bg,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                  child: Row(
                    children: [
                      Text(
                        'DISCUSSIONS',
                        style: AppTextStyles.monoXs.copyWith(
                          color: subtitleColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2638) : const Color(0xFFEBEFF7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: AppTextStyles.monoXs.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── 2. Continuous Comments Flow ────────────────────────────
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat_outlined, size: 36, color: subtitleColor.withAlpha(128)),
                          const SizedBox(height: 10),
                          Text(
                            'No replies yet',
                            style: AppTextStyles.headlineSm.copyWith(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to join the conversation!',
                            style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._comments.map((comment) {
                    final commentId = comment['_id']?.toString() ?? '';
                    final user = comment['user'] is Map ? comment['user'] as Map : null;
                    final commenterName = user?['name']?.toString() ?? 'Student';
                    final commenterAvatar = user?['avatar']?.toString();
                    final commenterInitials = commenterName.isNotEmpty ? commenterName[0].toUpperCase() : '?';
                    final commentText = comment['text']?.toString() ?? '';
                    final commentTime = _timeAgo(comment['createdAt']?.toString());
                    final isOwnComment = _currentUserId != null &&
                        user?['_id']?.toString() == _currentUserId;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor.withAlpha(100), width: 0.8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GVibeAvatar(
                            imageUrl: commenterAvatar,
                            size: 34,
                            initials: commenterInitials,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      commenterName,
                                      style: AppTextStyles.headlineSm.copyWith(
                                        color: titleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• $commentTime',
                                      style: AppTextStyles.bodyXs.copyWith(
                                        color: subtitleColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isOwnComment)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: subtitleColor),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _deleteComment(commentId),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Comment text formatted with Discord-style clickable hyperlinks
                                RichContentText(
                                  text: commentText,
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: isDark ? const Color(0xFFD6DAE3) : const Color(0xFF333333),
                                    height: 1.4,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // ─── 3. Docked Sticky Comment Composer ─────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                GVibeAvatar(
                  imageUrl: _currentUserAvatar,
                  size: 34,
                  initials: 'ME',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _showEmoji
                        ? Icons.keyboard_alt_outlined
                        : Icons.sentiment_satisfied_alt_rounded,
                    color: _showEmoji ? AppColors.primary : subtitleColor,
                    size: 24,
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
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = false);
                      },
                      style: AppTextStyles.bodySm.copyWith(color: titleColor),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                      decoration: InputDecoration(
                        hintText: 'Reply to $authorName...',
                        hintStyle: AppTextStyles.bodySm.copyWith(color: subtitleColor),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_showEmoji)
            EmojiPickerPanel(
              onEmojiSelected: (emoji) =>
                  EmojiPickerPanel.insertEmoji(_commentController, emoji),
              onBackspace: () =>
                  EmojiPickerPanel.backspace(_commentController),
            ),
        ],
      ),
    );
  }
}
