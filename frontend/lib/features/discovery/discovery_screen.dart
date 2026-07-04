import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/providers/theme_provider.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // States
  List<dynamic> _people = [];
  List<dynamic> _communities = [];
  List<dynamic> _tags = [];
  bool _loading = true;

  // Search Results
  bool _isSearching = false;
  List<dynamic> _searchPeople = [];
  List<dynamic> _searchCommunities = [];
  bool _searchLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDiscoveryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchDiscoveryData() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        ApiService().dio.get('/discovery/people'),
        ApiService().dio.get('/discovery/communities'),
        ApiService().dio.get('/discovery/tags/trending'),
      ]);

      if (mounted) {
        setState(() {
          _people = futures[0].data['success'] == true ? futures[0].data['data'] ?? [] : [];
          _communities = futures[1].data['success'] == true ? futures[1].data['data'] ?? [] : [];
          _tags = futures[2].data['success'] == true ? futures[2].data['data'] ?? [] : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        setState(() {
          _isSearching = false;
          _searchPeople = [];
          _searchCommunities = [];
        });
        return;
      }
      _executeSearch(query.trim());
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchLoading = true;
    });

    try {
      final r = await ApiService().dio.get('/discovery/search', queryParameters: {'q': query});
      if (r.data['success'] == true && mounted) {
        final data = r.data['data'];
        setState(() {
          _searchPeople = data['users'] ?? [];
          _searchCommunities = data['communities'] ?? [];
          _searchLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _showTagPosts(String tag) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagPostsSheet(tag: tag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchDiscoveryData,
        color: cs.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            if (_isSearching) ...[
              if (_searchLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else ...[
                // Search Results Sections
                if (_searchCommunities.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SectionHeader(title: 'Matching Communities'),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final c = _searchCommunities[i];
                        return _CommunitySearchCard(community: c);
                      },
                      childCount: _searchCommunities.length,
                    ),
                  ),
                ],
                if (_searchPeople.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: SectionHeader(title: 'Matching People'),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _UserCard(user: _searchPeople[i]),
                      childCount: _searchPeople.length,
                    ),
                  ),
                ],
                if (_searchPeople.isEmpty && _searchCommunities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No results found for "${_searchController.text}"',
                          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
              ],
            ] else ...[
              // Standard Discovery sections
              SliverToBoxAdapter(child: _buildCommunitiesSection(context)),
              SliverToBoxAdapter(child: _buildTagsSection(context)),
              SliverToBoxAdapter(child: _buildPeopleHeader(context)),
              _loading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _UserCardSkeleton(),
                        ),
                        childCount: 4,
                      ),
                    )
                  : _people.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                'No people discovered yet.',
                                style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _UserCard(user: _people[i]),
                            childCount: _people.length,
                          ),
                        ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Text(
            'Discover',
            style: AppTextStyles.displaySm.copyWith(
              color: titleColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: isDark ? -0.8 : -1.2,
            ),
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
          _IconButton(
            icon: Icons.explore_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final hintColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(isDark ? 8 : 6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: hintColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyMd.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search students, communities...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(color: hintColor),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear_rounded, color: hintColor, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitiesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Campus Communities',
            trailing: Text('Live',
                style: AppTextStyles.bodyXs
                    .copyWith(color: liveColor, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          _loading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : _communities.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'No communities created yet.',
                          style: AppTextStyles.bodySm.copyWith(color: liveColor),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _communities.length > 4 ? 4 : _communities.length,
                      itemBuilder: (_, i) => _CommunityCard(
                        community: _communities[i],
                        index: i,
                        onTap: () {
                          final c = _communities[i];
                          context.push('/community/${c['_id']}', extra: c['name']);
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Top Trending Tags'),
          const SizedBox(height: 12),
          _tags.isEmpty
              ? Text(
                  'No tags trending yet. Post with #tag to start.',
                  style: AppTextStyles.bodyXs.copyWith(color: subColor),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((t) {
                    final tagText = t['tag']?.toString() ?? '';
                    final count = t['count'] ?? 0;
                    return GestureDetector(
                      onTap: () => _showTagPosts(tagText),
                      child: GVibeTag(label: '#$tagText ($count)', isActive: true),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildPeopleHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SectionHeader(title: 'Campus People'),
    );
  }
}

class _CommunityCard extends StatefulWidget {
  final Map<String, dynamic> community;
  final int index;
  final VoidCallback onTap;
  const _CommunityCard({required this.community, required this.index, required this.onTap});

  @override
  State<_CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<_CommunityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  static const _tileColorsDark = [
    Color(0xFF0F1011),
    Color(0xFF1A1F4D),
    Color(0xFF121315),
    Color(0xFF1F2560),
  ];

  static const _tileColorsLight = [
    Color(0xFFFFFFFF),
    Color(0xFFF9F9FB),
    Color(0xFFF3F4F6),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? _tileColorsDark[widget.index % _tileColorsDark.length]
        : _tileColorsLight[widget.index % _tileColorsLight.length];

    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF171717);
    final count = widget.community['memberCount'] ?? 0;
    final description = widget.community['description']?.toString() ?? 'Tap to chat';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(isDark ? 8 : 12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3), size: 16),
                const SizedBox(width: 6),
                Text(
                  '$count members',
                  style: AppTextStyles.bodyXs.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.community['name']?.toString() ?? '',
                  style: AppTextStyles.headlineSm.copyWith(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodyXs.copyWith(
                    color: isDark ? const Color(0xFF838EA6) : const Color(0xFF888888),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunitySearchCard extends StatelessWidget {
  final Map<String, dynamic> community;

  const _CommunitySearchCard({required this.community});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFF9F9FB);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);

    final name = community['name']?.toString() ?? '';
    final desc = community['description']?.toString() ?? 'Tap to chat';
    final memberCount = community['memberCount'] ?? 0;

    return GVibeCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      onTap: () {
        context.push('/community/${community['_id']}', extra: name);
      },
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '#',
                style: AppTextStyles.headlineMd.copyWith(color: accentColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.headlineSm.copyWith(color: nameColor, fontWeight: FontWeight.w700)),
                Text(desc, style: AppTextStyles.bodyXs.copyWith(color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$memberCount members', style: AppTextStyles.bodyXs.copyWith(color: subColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final bioColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);

    final name = user['name']?.toString() ?? 'Anonymous';
    final dept = user['dept']?.toString() ?? '';
    final year = user['year']?.toString() ?? '';
    final bio = user['bio']?.toString() ?? '';
    final avatar = user['avatar']?.toString();
    final followers = user['followersCount'] ?? (user['followers'] as List?)?.length ?? 0;
    final userId = user['_id']?.toString() ?? '';

    return GVibeCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      onTap: () {
        if (userId.isNotEmpty) context.push('/profile/$userId');
      },
      child: Row(
        children: [
          GVibeAvatar(
            imageUrl: avatar,
            size: 52,
            initials: name.isNotEmpty ? name[0] : '?',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.headlineSm.copyWith(
                    color: nameColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dept.isNotEmpty || year.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (dept.isNotEmpty)
                        _Chip(label: dept, context: context),
                      if (year.isNotEmpty)
                        _Chip(label: 'Year $year', context: context),
                    ],
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    bio,
                    style: AppTextStyles.bodyXs.copyWith(color: bioColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '$followers followers',
                  style: AppTextStyles.monoXs.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final BuildContext context;
  const _Chip({required this.label, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyXs.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UserCardSkeleton extends StatelessWidget {
  const _UserCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GVibeCard(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          SkeletonBox(width: 52, height: 52, borderRadius: 26),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 130, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 10),
                SizedBox(height: 6),
                SkeletonBox(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class _TagPostsSheet extends StatefulWidget {
  final String tag;
  const _TagPostsSheet({required this.tag});

  @override
  State<_TagPostsSheet> createState() => _TagPostsSheetState();
}

class _TagPostsSheetState extends State<_TagPostsSheet> {
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final r = await ApiService().dio.get('/discovery/tags/${widget.tag}/posts');
      if (r.data['success'] == true && mounted) {
        setState(() {
          _posts = r.data['data'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0D0F) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '#${widget.tag}',
                    style: AppTextStyles.headlineMd.copyWith(
                      color: nameColor, fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: nameColor, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                      ? Center(
                          child: Text(
                            'No posts found with #${widget.tag}',
                            style: AppTextStyles.bodyMd.copyWith(color: nameColor),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _TagPostCard(post: _posts[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _TagPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final author = post['author'];
    final name = author?['name']?.toString() ?? 'Anonymous';
    final avatar = author?['avatar']?.toString();
    final initials = name.isNotEmpty ? name[0] : '?';
    final content = post['content']?.toString() ?? '';
    final likes = (post['likes'] as List?)?.length ?? 0;
    final comments = (post['comments'] as List?)?.length ?? 0;

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
            Row(
              children: [
                GVibeAvatar(
                  imageUrl: avatar,
                  size: 40,
                  initials: initials,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.headlineSm.copyWith(
                        color: nameColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Post details',
                      style: AppTextStyles.bodyXs.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: AppTextStyles.bodyMd.copyWith(
                color: contentColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.favorite_border_rounded, color: actionColor, size: 17),
                const SizedBox(width: 5),
                Text(
                  '$likes',
                  style: AppTextStyles.monoSm.copyWith(
                    color: actionColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.chat_bubble_outline_rounded, color: actionColor, size: 17),
                const SizedBox(width: 5),
                Text(
                  '$comments',
                  style: AppTextStyles.monoSm.copyWith(
                    color: actionColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
