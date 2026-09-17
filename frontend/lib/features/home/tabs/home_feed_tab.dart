import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_theme_extension.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/gvibe_widgets.dart';
import '../../../shared/widgets/share_post_sheet.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
import '../../../shared/widgets/discord_hyperlink.dart';
import '../../../shared/widgets/location_picker_sheet.dart';
import '../../../shared/widgets/emoji_picker_panel.dart';

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
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'all', 'label': 'All Posts', 'icon': Icons.all_inclusive_rounded},
    {'id': 'general', 'label': 'General', 'icon': Icons.chat_bubble_outline_rounded},
    {'id': 'lost_found', 'label': 'Lost & Found', 'icon': Icons.search_rounded},
    {'id': 'ride_share', 'label': 'Ride Share', 'icon': Icons.directions_car_rounded},
    {'id': 'teammate', 'label': 'Teammates', 'icon': Icons.group_rounded},
  ];

  List<dynamic> get _displayedPosts {
    if (_selectedCategory == 'all') return _posts;
    return _posts.where((p) {
      final cat = p['category']?.toString();
      if (_selectedCategory == 'general') {
        return cat == null || cat.isEmpty || cat == 'general';
      }
      return cat == _selectedCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      final query = <String, dynamic>{};
      if (_selectedCategory != 'all') {
        query['category'] = _selectedCategory;
      }
      final response = await ApiService().dio.get('/posts', queryParameters: query);
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

  void _onSelectCategory(String catId) {
    if (_selectedCategory == catId) return;
    setState(() {
      _selectedCategory = catId;
    });
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Text(
            'GVibe',
            style: AppTextStyles.displaySm.copyWith(
              color: titleColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: isDark ? -0.8 : -1.2,
            ),
          ),
          const Spacer(),
          const ThemeToggleButton(
            margin: EdgeInsets.only(right: 10),
          ),
          _IconButton(icon: Icons.notifications_outlined, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final inactiveColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final indicatorColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: indicatorColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.tabActive.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: AppTextStyles.tabInactive.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        labelColor: activeColor,
        unselectedLabelColor: inactiveColor,
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Vibes'),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterHeader(bool isDark, Color borderColor) {
    final activeCat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    final isFiltered = _selectedCategory != 'all';
    final labelColor = isDark ? const Color(0xFF8A8F98) : const Color(0xFF737373);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            isFiltered ? activeCat['label'].toString().toUpperCase() : 'CAMPUS FEED',
            style: AppTextStyles.monoXs.copyWith(
              color: labelColor,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _buildCategoryFilterPill(isDark, borderColor),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterPill(bool isDark, Color borderColor) {
    final activeCat = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => _categories.first,
    );
    final isFiltered = _selectedCategory != 'all';
    final pillColor = isFiltered
        ? (isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3))
        : (isDark ? const Color(0xFF838EA6) : const Color(0xFF666666));

    final menuBg = isDark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
    final menuBorder = isDark ? const Color(0xFF22242B) : const Color(0xFFE5E7EB);
    final menuText = isDark ? const Color(0xFFF7F8F8) : const Color(0xFF171717);

    return PopupMenuButton<String>(
      tooltip: 'Filter posts by category',
      elevation: 8,
      color: menuBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: menuBorder, width: 1),
      ),
      offset: const Offset(0, 34),
      onSelected: _onSelectCategory,
      itemBuilder: (context) {
        return _categories.map((cat) {
          final isSelected = cat['id'] == _selectedCategory;
          return PopupMenuItem<String>(
            value: cat['id'] as String,
            height: 40,
            child: Row(
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 15,
                  color: isSelected
                      ? (isDark ? const Color(0xFF828FFF) : const Color(0xFF0070F3))
                      : (isDark ? const Color(0xFF8A8F98) : const Color(0xFF737373)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat['label'] as String,
                    style: AppTextStyles.bodySm.copyWith(
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0070F3))
                          : menuText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF828FFF) : const Color(0xFF0070F3),
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isFiltered
              ? (isDark ? const Color(0xFF5E6AD2).withValues(alpha: 0.16) : const Color(0xFF0070F3).withValues(alpha: 0.08))
              : (isDark ? const Color(0xFF161820) : const Color(0xFFF5F6F8)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFiltered ? pillColor.withValues(alpha: 0.5) : borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFiltered) ...[
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: pillColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Icon(
              activeCat['icon'] as IconData,
              size: 12,
              color: pillColor,
            ),
            const SizedBox(width: 5),
            Text(
              activeCat['label'] as String,
              style: AppTextStyles.monoXs.copyWith(
                color: pillColor,
                fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: pillColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsFeed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final displayed = _displayedPosts;

    return Column(
      children: [
        _buildCategoryFilterHeader(isDark, borderColor),
        Expanded(
          child: _loading
              ? ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  itemCount: 4,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: PostCardSkeleton(),
                  ),
                )
              : displayed.isEmpty
                  ? _buildEmptyState(
                      _selectedCategory == 'all'
                          ? 'No posts yet'
                          : 'No ${_categories.firstWhere((c) => c['id'] == _selectedCategory, orElse: () => _categories.first)['label']} posts yet',
                      Icons.article_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPosts,
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: displayed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _PostCard(post: displayed[i]),
                      ),
                    ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fabColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final borderRadius = isDark ? BorderRadius.circular(14) : BorderRadius.circular(28);

    return GestureDetector(
      onTap: () => _showCreatePostSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: fabColor,
          borderRadius: borderRadius,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: const Color(0xFF5E6AD2).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0070F3).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
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
class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late int _likesCount;
  late int _commentsCount;
  late int _sharesCount;
  bool _isLiked = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final likesList = (widget.post['likes'] as List?) ?? [];
    _likesCount = likesList.length;
    _commentsCount = (widget.post['comments'] as List?)?.length ?? 0;
    _sharesCount = widget.post['sharesCount'] ?? 0;
    _checkLikedStatus(likesList);
  }

  Future<void> _checkLikedStatus(List likesList) async {
    final cached = await AuthService.getUser();
    if (mounted) {
      final myId = cached?['_id']?.toString();
      setState(() {
        _currentUserId = myId;
        if (myId != null) {
          _isLiked = likesList.any((id) => id.toString() == myId);
        }
      });
    }
  }

  Future<void> _toggleLike() async {
    final postId = widget.post['_id']?.toString() ?? widget.post['id']?.toString();
    if (postId == null) return;

    // Optimistic update
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount = (_likesCount - 1).clamp(0, 999999);
      } else {
        _isLiked = true;
        _likesCount += 1;
      }
    });

    try {
      final res = await ApiService().dio.put('/posts/$postId/like');
      if (res.data['success'] == true && mounted) {
        final updatedPost = res.data['data'];
        final updatedLikes = (updatedPost['likes'] as List?) ?? [];
        setState(() {
          _likesCount = updatedLikes.length;
          if (_currentUserId != null) {
            _isLiked = updatedLikes.any((id) => id.toString() == _currentUserId);
          }
        });
      }
    } catch (_) {
      // Revert if request fails
      if (mounted) {
        setState(() {
          if (_isLiked) {
            _isLiked = false;
            _likesCount = (_likesCount - 1).clamp(0, 999999);
          } else {
            _isLiked = true;
            _likesCount += 1;
          }
        });
      }
    }
  }

  Future<void> _openComments() async {
    final postId = widget.post['_id']?.toString() ?? widget.post['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    final newCount = await context.push<int>(
      '/post/$postId',
      extra: widget.post,
    );
    if (newCount != null && mounted) {
      setState(() => _commentsCount = newCount);
    }
  }

  void _openShare() {
    SharePostSheet.show(
      context,
      post: widget.post,
      onShared: (count) {
        if (mounted) setState(() => _sharesCount = count);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = context.ext;
    final author = widget.post['author'];
    final name = author?['name']?.toString() ?? 'Anonymous';
    final avatar = author?['avatar']?.toString();
    final initials = name.isNotEmpty ? name[0] : '?';
    final content = widget.post['content']?.toString() ?? '';
    final createdAt = widget.post['createdAt']?.toString() ?? '';
    final timeAgo = _timeAgo(createdAt);
    final isTrending = _likesCount > 5;

    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final contentColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);
    final actionColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.headlineSm.copyWith(
                                color: nameColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildPostCategoryBadge(widget.post['category']?.toString() ?? 'general', isDark),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: AppTextStyles.bodyXs.copyWith(
                          color: subtitleColor,
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
                      color: ext.like.withValues(alpha: isDark ? 0.12 : 0.08),
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
            // Content with Discord-style hyperlinks
            RichContentText(
              text: content,
              style: AppTextStyles.bodyMd.copyWith(
                color: contentColor,
                height: 1.5,
                letterSpacing: isDark ? 0.15 : 0.1,
              ),
            ),
            const SizedBox(height: 14),
            // Actions
            Row(
              children: [
                AnimatedLikeButton(
                  count: _likesCount,
                  isLiked: _isLiked,
                  onTap: _toggleLike,
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _openComments,
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: actionColor, size: 17),
                      const SizedBox(width: 5),
                      Text(
                        '$_commentsCount',
                        style: AppTextStyles.monoSm.copyWith(
                          color: actionColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _openShare,
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined,
                          color: actionColor, size: 17),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCategoryBadge(String cat, bool isDark) {
    String label = 'General';
    Color color = const Color(0xFF5E6AD2);
    IconData icon = Icons.chat_bubble_outline_rounded;

    if (cat == 'lost_found') {
      label = 'Lost & Found';
      color = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);
      icon = Icons.search_rounded;
    } else if (cat == 'ride_share') {
      label = 'Ride Share';
      color = isDark ? const Color(0xFF30A46C) : const Color(0xFF16A34A);
      icon = Icons.directions_car_rounded;
    } else if (cat == 'teammate') {
      label = 'Teammate';
      color = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
      icon = Icons.group_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.monoXs.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 9.5,
            ),
          ),
        ],
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

  // Linear dark backgrounds
  static const _tileColorsDark = [
    Color(0xFF0F1011),
    Color(0xFF1A1F4D),
    Color(0xFF121315),
    Color(0xFF1F2560),
    Color(0xFF0A0A0C),
    Color(0xFF151936),
  ];

  // Vercel light backgrounds
  static const _tileColorsLight = [
    Color(0xFFFFFFFF),
    Color(0xFFF9F9FB),
    Color(0xFFF3F4F6),
    Color(0xFFFFFFFF),
    Color(0xFFF5F7FA),
    Color(0xFFFAFAFA),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? _tileColorsDark[index % _tileColorsDark.length]
        : _tileColorsLight[index % _tileColorsLight.length];

    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final handleBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF171717).withValues(alpha: 0.06);
    final handleTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final captionColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF222222);
    final actionsColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isDark ? 14 : 12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
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
                    color: handleBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '@${data['handle']}',
                    style: AppTextStyles.monoXs.copyWith(
                      color: handleTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  data['caption'] ?? '',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: captionColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        color: actionsColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${(index + 1) * 12}',
                      style: AppTextStyles.monoXs.copyWith(
                        color: actionsColor,
                        fontWeight: FontWeight.w500,
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
  final _contentFocusNode = FocusNode();
  bool _posting = false;
  bool _showEmoji = false;
  String _selectedCategory = 'general';

  final List<Map<String, dynamic>> _postCategories = const [
    {'id': 'general', 'label': 'General', 'icon': Icons.chat_bubble_outline_rounded},
    {'id': 'lost_found', 'label': 'Lost & Found', 'icon': Icons.search_rounded},
    {'id': 'ride_share', 'label': 'Ride Share', 'icon': Icons.directions_car_rounded},
    {'id': 'teammate', 'label': 'Teammate', 'icon': Icons.group_rounded},
  ];

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _openLocationPicker() {
    LocationPickerSheet.show(
      context,
      onLocationSelected: (locationText) {
        final current = _contentController.text.trim();
        final updated = current.isEmpty ? locationText : '$current\n$locationText';
        _contentController.value = TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(offset: updated.length),
        );
      },
    );
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _posting = true);
    try {
      final response = await ApiService().dio.post('/posts', data: {
        'content': content,
        'type': 'text',
        'category': _selectedCategory,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final inputColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    
    final buttonBg = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final buttonRadius = isDark ? BorderRadius.circular(8) : BorderRadius.circular(100);

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
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
                  style: AppTextStyles.headlineLg.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close_rounded,
                      color: subtitleColor, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Category selector chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _postCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _postCategories[i];
                final isSelected = cat['id'] == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF5E6AD2).withValues(alpha: 0.18) : const Color(0xFF0070F3).withValues(alpha: 0.1))
                          : (isDark ? const Color(0xFF161820) : const Color(0xFFF5F6F8)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3))
                            : borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 13,
                          color: isSelected
                              ? (isDark ? const Color(0xFF828FFF) : const Color(0xFF0070F3))
                              : subtitleColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          cat['label'] as String,
                          style: AppTextStyles.monoXs.copyWith(
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF0070F3))
                                : subtitleColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
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
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      autofocus: true,
                      onTap: () {
                        if (_showEmoji) setState(() => _showEmoji = false);
                      },
                      style: AppTextStyles.bodyLg.copyWith(color: inputColor),
                      decoration: InputDecoration(
                        hintText: "What's happening on campus?",
                        hintStyle: AppTextStyles.bodyLg.copyWith(
                          color: subtitleColor,
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
                      color: subtitleColor, size: 22),
                  const SizedBox(width: 16),
                  Icon(Icons.gif_box_outlined,
                      color: subtitleColor, size: 22),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: _openLocationPicker,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      if (_showEmoji) {
                        _contentFocusNode.requestFocus();
                        setState(() => _showEmoji = false);
                      } else {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = true);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _showEmoji
                            ? Icons.keyboard_alt_outlined
                            : Icons.sentiment_satisfied_alt_rounded,
                        color: _showEmoji ? AppColors.primary : subtitleColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _posting ? null : _submitPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: buttonBg,
                        borderRadius: buttonRadius,
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
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showEmoji)
            EmojiPickerPanel(
              onEmojiSelected: (emoji) =>
                  EmojiPickerPanel.insertEmoji(_contentController, emoji),
              onBackspace: () =>
                  EmojiPickerPanel.backspace(_contentController),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(isDark ? 8 : 6),
          border: Border.all(
            color: isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? const Color(0xFFE2E4E9) : const Color(0xFF666666),
          size: 19,
        ),
      ),
    );
  }
}
