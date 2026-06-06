import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_extension.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/gvibe_widgets.dart';
import '../../../core/providers/theme_provider.dart';

class HomeFeedTab extends StatefulWidget {
  const HomeFeedTab({super.key});
  @override
  State<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<HomeFeedTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().dio.get('/posts');
      if (response.data['success'] == true) {
        setState(() {
          _posts = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildTopBar(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsFeed(),
                _buildVibesFeed(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: cs.background,
      child: Row(
        children: [
          GradientText(
            'GVibe',
            style: AppTextStyles.displaySm.copyWith(fontSize: 26),
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _IconButton(
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
              );
            },
          ),
          _IconButton(icon: Icons.notifications_outlined, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Container(
      decoration: BoxDecoration(
        color: cs.background,
        border: Border(bottom: BorderSide(color: ext.outline, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: cs.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.tabActive,
        unselectedLabelStyle: AppTextStyles.tabInactive,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Vibes'),
        ],
      ),
    );
  }

  Widget _buildPostsFeed() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: PostCardSkeleton(),
        ),
      );
    }
    if (_posts.isEmpty) {
      return _buildEmptyState('No posts yet', Icons.article_outlined);
    }
    return RefreshIndicator(
      onRefresh: _fetchPosts,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _PostCard(post: _posts[i]),
      ),
    );
  }

  Widget _buildVibesFeed(BuildContext context) {
    final vibes = [
      {'handle': 'tech.district', 'caption': 'Late night grind session 💻'},
      {'handle': 'analog.dream', 'caption': 'Sound frequencies 🎵'},
      {'handle': 'urban.explore', 'caption': 'Campus after dark 🌙'},
      {'handle': 'motion.freeze', 'caption': 'Rhythm study 🎶'},
      {'handle': 'code.vibes', 'caption': 'When the code finally works ✨'},
      {'handle': 'campus.life', 'caption': 'Friday vibes only 🎉'},
    ];
    return RefreshIndicator(
      onRefresh: _fetchPosts,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: vibes.length,
        itemBuilder: (_, i) => _VibeTile(data: vibes[i], index: i),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.1),
              blurRadius: 24,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: cs.primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'No posts to display',
              style: AppTextStyles.headlineMd.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share what is happening on campus right now.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            GVibeButton(
              label: 'Share a Post',
              onPressed: () => _showCreatePostSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    final ext = context.ext;
    return GestureDetector(
      onTap: () => _showCreatePostSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: ext.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: ext.glowShadow,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CreatePostSheet(onPostCreated: _fetchPosts),
    );
  }
}

// ═══════════════════════ POST CARD ═══════════════════════════════════════════
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    final author = post['author'];
    final name = author?['name']?.toString() ?? 'Anonymous';
    final avatar = author?['avatar']?.toString();
    final initials = name.isNotEmpty ? name[0] : '?';
    final content = post['content']?.toString() ?? '';
    final likes = (post['likes'] as List?)?.length ?? 0;
    final comments = (post['comments'] as List?)?.length ?? 0;
    final createdAt = post['createdAt']?.toString() ?? '';
    final timeAgo = _timeAgo(createdAt);
    final isTrending = likes > 5;

    return GVibeCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GVibeAvatar(
                  imageUrl: avatar,
                  size: 42,
                  initials: initials,
                  showGlow: isTrending,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.headlineSm.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: AppTextStyles.bodyXs.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTrending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ext.like.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔥 Trending',
                      style: AppTextStyles.monoXs.copyWith(
                        color: ext.like,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Text(
              content,
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 14),
            // Actions
            Row(
              children: [
                AnimatedLikeButton(count: likes),
                const SizedBox(width: 20),
                Icon(Icons.chat_bubble_outline_rounded,
                    color: cs.onSurfaceVariant, size: 17),
                const SizedBox(width: 4),
                Text(
                  '$comments',
                  style: AppTextStyles.monoSm.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(Icons.share_outlined,
                    color: cs.onSurfaceVariant, size: 17),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(String dateString) {
    if (dateString.isEmpty) return 'just now';
    try {
      final dt = DateTime.parse(dateString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'just now';
    }
  }
}

// ═══════════════════════ VIBE TILE ════════════════════════════════════════════
class _VibeTile extends StatelessWidget {
  final Map<String, String> data;
  final int index;
  const _VibeTile({required this.data, required this.index});

  static const _gradients = [
    LinearGradient(
        colors: [Color(0xFF007366), Color(0xFF007366)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF005C52), Color(0xFF005C52)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFF00897B), Color(0xFF00897B)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF004D40), Color(0xFF004D40)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
    LinearGradient(
        colors: [Color(0xFF009688), Color(0xFF009688)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(
        colors: [Color(0xFF00695C), Color(0xFF00695C)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Glass overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.15),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '@${data['handle']}',
                    style: AppTextStyles.monoXs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  data['caption'] ?? '',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${(index + 1) * 12}',
                      style: AppTextStyles.monoXs.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ CREATE POST SHEET ════════════════════════════════════
class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onPostCreated;
  const _CreatePostSheet({required this.onPostCreated});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _contentController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _posting = true);
    try {
      final response = await ApiService().dio.post('/posts', data: {
        'content': content,
        'type': 'text',
      });
      if (response.data['success'] == true) {
        widget.onPostCreated();
        if (mounted) Navigator.of(context).pop();
      }
    } on DioException catch (_) {
      // handle silently
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'New Post',
                  style: AppTextStyles.headlineLg.copyWith(color: cs.onSurface),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close_rounded,
                      color: cs.onSurfaceVariant, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: ext.outline, height: 1),
          // Composer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GVibeAvatar(size: 40, showGlow: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      autofocus: true,
                      style: AppTextStyles.bodyLg.copyWith(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: "What's happening on campus?",
                        hintStyle: AppTextStyles.bodyLg.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.image_outlined,
                      color: cs.onSurfaceVariant, size: 22),
                  const SizedBox(width: 16),
                  Icon(Icons.gif_box_outlined,
                      color: cs.onSurfaceVariant, size: 22),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on_outlined,
                      color: cs.onSurfaceVariant, size: 22),
                  const Spacer(),
                  GestureDetector(
                    onTap: _posting ? null : _submitPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: ext.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _posting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Post',
                              style: AppTextStyles.buttonPrimary.copyWith(
                                fontSize: 13,
                              ),
                            ),
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
}

// ─── Local icon button ────────────────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: cs.onSurface, size: 20),
      ),
    );
  }
}
