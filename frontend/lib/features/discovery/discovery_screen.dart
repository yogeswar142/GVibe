import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _hubs = [
    {'name': 'Engineering Quad', 'activity': 89, 'status': 'High Vibe', 'tag': '#tech-grind'},
    {'name': 'Central Library', 'activity': 32, 'status': 'Calm', 'tag': '#prep'},
    {'name': 'Student Union', 'activity': 65, 'status': 'Active', 'tag': '#lounge'},
    {'name': 'Athletics Dome', 'activity': 18, 'status': 'Quiet', 'tag': '#cardio'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().dio.get('/users');
      if (response.data['success'] == true) {
        setState(() {
          _users = response.data['data'] ?? [];
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
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            SliverToBoxAdapter(child: _buildHubsSection(context)),
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
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _UserCard(user: _users[i]),
                      childCount: _users.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: cs.surface,
      child: Row(
        children: [
          Text('Discover',
              style: AppTextStyles.displayMd.copyWith(color: cs.onSurface)),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.explore_rounded, color: cs.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ext.outline, width: 0.8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search students, hubs...',
                  hintStyle: AppTextStyles.bodyMd
                      .copyWith(color: cs.onSurfaceVariant),
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
    );
  }

  Widget _buildHubsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Campus Hubs',
            trailing: Text('Live',
                style: AppTextStyles.bodyXs
                    .copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
            ),
            itemCount: _hubs.length,
            itemBuilder: (_, i) => _HubCard(
              hub: _hubs[i],
              index: i,
              onTap: () => _showHubSheet(context, _hubs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Vibe Clusters'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              GVibeTag(label: '#coffee_run  14', isActive: false),
              GVibeTag(label: '#exam_crunch  98', isActive: true),
              GVibeTag(label: '#sunset_lounge  4', isActive: false),
              GVibeTag(label: '#synth_jam  8', isActive: false),
              GVibeTag(label: '#night_grind  32', isActive: false),
            ],
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

  void _showHubSheet(BuildContext context, Map<String, dynamic> hub) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: cs.primary, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hub['name'],
                      style: AppTextStyles.displaySm
                          .copyWith(color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: cs.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('${hub['activity']}% activity · ${hub['status']}',
                          style: AppTextStyles.bodySm
                              .copyWith(color: cs.primary)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(hub['tag'],
                            style: AppTextStyles.monoXs
                                .copyWith(color: cs.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: ext.outline, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('Students here',
                  style: AppTextStyles.label
                      .copyWith(color: cs.onSurfaceVariant)),
            ),
            SizedBox(
              height: 80,
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: cs.primary))
                  : _users.isEmpty
                      ? Center(
                          child: Text('No students present',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: cs.onSurfaceVariant)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final s = _users[i];
                            final name =
                                s['name']?.toString() ?? 'Anonymous';
                            final userId = s['_id']?.toString() ?? '';
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                if (userId.isNotEmpty) {
                                  context.push('/profile/$userId');
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    GVibeAvatar(
                                      imageUrl: s['avatar'],
                                      size: 46,
                                      initials: name[0],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name.split(' ').first,
                                      style: AppTextStyles.bodyXs.copyWith(
                                          color: cs.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),
            Divider(color: ext.outline, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('Trending here',
                  style: AppTextStyles.label
                      .copyWith(color: cs.onSurfaceVariant)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _HubPostRow('neo.witch', 'Setting up the server 🔧', '10m', context),
                  _HubPostRow('code.runner', 'Coffee machine refilled! ☕', '25m', context),
                  _HubPostRow('grid.runner', 'Anyone up for code jam? 💻', '1h', context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _HubPostRow(
      String handle, String text, String time, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return GVibeCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GVibeAvatar(size: 32, initials: handle[0].toUpperCase()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$handle',
                    style: AppTextStyles.headlineSm
                        .copyWith(color: cs.onSurface, fontSize: 12)),
                Text(text,
                    style: AppTextStyles.bodyXs
                        .copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time,
              style:
                  AppTextStyles.monoXs.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ─── Hub Card ─────────────────────────────────────────────────────────────────
class _HubCard extends StatefulWidget {
  final Map<String, dynamic> hub;
  final int index;
  final VoidCallback onTap;
  const _HubCard({required this.hub, required this.index, required this.onTap});

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF007366), Color(0xFF007366)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF005C52), Color(0xFF005C52)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
    LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00897B)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF004D40), Color(0xFF004D40)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
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
    final gradient = _gradients[widget.index % _gradients.length];
    final activity = widget.hub['activity'] as int;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0x507C6FFF),
                blurRadius: 8 + (_pulse.value * 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.hub['status'],
                    style: AppTextStyles.bodyXs.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hub['name'],
                    style: AppTextStyles.headlineSm.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: activity / 100,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$activity%',
                        style: AppTextStyles.monoXs.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = user['name']?.toString() ?? 'Anonymous';
    final dept = user['dept']?.toString() ?? '';
    final year = user['year']?.toString() ?? '';
    final bio = user['bio']?.toString() ?? '';
    final avatar = user['avatar']?.toString();
    final followers = (user['followers'] as List?)?.length ?? 0;
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
                Text(name,
                    style: AppTextStyles.headlineSm
                        .copyWith(color: cs.onSurface)),
                if (dept.isNotEmpty || year.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
                  Text(bio,
                      style: AppTextStyles.bodyXs
                          .copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(
                  '$followers followers',
                  style: AppTextStyles.monoXs
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _FollowButton(userId: userId),
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
    final cs = Theme.of(ctx).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppTextStyles.bodyXs
              .copyWith(color: cs.primary, fontWeight: FontWeight.w500)),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final String userId;
  const _FollowButton({required this.userId});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return GestureDetector(
      onTap: () => setState(() => _following = !_following),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: _following ? null : ext.primaryGradient,
          color: _following ? cs.surfaceContainerHighest : null,
          borderRadius: BorderRadius.circular(10),
          border: _following
              ? Border.all(color: cs.outline, width: 1)
              : null,
        ),
        child: Text(
          _following ? 'Following' : 'Follow',
          style: AppTextStyles.labelLg.copyWith(
            color: _following ? cs.onSurfaceVariant : Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── User Card Skeleton ────────────────────────────────────────────────────────
class _UserCardSkeleton extends StatelessWidget {
  const _UserCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GVibeCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const SkeletonBox(width: 52, height: 52, borderRadius: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
