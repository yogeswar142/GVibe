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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchUsers,
        color: cs.primary,
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
                style: AppTextStyles.bodyMd.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search students, hubs...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(color: hintColor),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Campus Hubs',
            trailing: Text('Live',
                style: AppTextStyles.bodyXs
                    .copyWith(color: liveColor, fontWeight: FontWeight.w600)),
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Vibe Clusters'),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
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
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hub['name'],
                    style: AppTextStyles.displaySm.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: accentColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${hub['activity']}% activity · ${hub['status']}',
                        style: AppTextStyles.bodySm.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hub['tag'],
                          style: AppTextStyles.monoXs.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                'Students here',
                style: AppTextStyles.label.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: accentColor))
                  : _users.isEmpty
                      ? Center(
                          child: Text(
                            'No students present',
                            style: AppTextStyles.bodySm.copyWith(color: subtitleColor),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _users.length,
                          itemBuilder: (_, i) {
                            final s = _users[i];
                            final name = s['name']?.toString() ?? 'Anonymous';
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
                                      style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
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
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text(
                'Trending here',
                style: AppTextStyles.label.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _hubPostRow('neo.witch', 'Setting up the server 🔧', '10m', context),
                  _hubPostRow('code.runner', 'Coffee machine refilled! ☕', '25m', context),
                  _hubPostRow('grid.runner', 'Anyone up for code jam? 💻', '1h', context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hubPostRow(
      String handle, String text, String time, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final contentColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

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
                Text(
                  '@$handle',
                  style: AppTextStyles.headlineSm.copyWith(
                    color: nameColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AppTextStyles.bodyXs.copyWith(color: contentColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTextStyles.monoXs.copyWith(color: subtitleColor),
          ),
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
    final statusColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final titleColor = isDark ? Colors.white : const Color(0xFF171717);
    final progressBg = isDark ? Colors.white24 : const Color(0xFFE2E4E9);
    final progressColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final glowColor = isDark
        ? const Color(0xFF5E6AD2).withValues(alpha: 0.15 + (_pulse.value * 0.1))
        : const Color(0xFF0070F3).withValues(alpha: 0.04 + (_pulse.value * 0.04));

    final activity = widget.hub['activity'] as int;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(isDark ? 8 : 12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: isDark ? 8 + (_pulse.value * 8) : 6 + (_pulse.value * 4),
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
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.hub['status'],
                    style: AppTextStyles.bodyXs.copyWith(
                      color: statusColor,
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
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                            backgroundColor: progressBg,
                            valueColor: AlwaysStoppedAnimation(progressColor),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$activity%',
                        style: AppTextStyles.monoXs.copyWith(
                          color: titleColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final bioColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);

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
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(999), // pill
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final double radius = isDark ? 8 : 999;
    final Color buttonColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);
    final Color borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final Color textColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF666666);

    return GestureDetector(
      onTap: () => setState(() => _following = !_following),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _following ? Colors.transparent : buttonColor,
          borderRadius: BorderRadius.circular(radius),
          border: _following ? Border.all(color: borderColor, width: 1) : null,
        ),
        child: Text(
          _following ? 'Following' : 'Follow',
          style: AppTextStyles.labelLg.copyWith(
            color: _following ? textColor : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
