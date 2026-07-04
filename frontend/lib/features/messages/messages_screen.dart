import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/providers/theme_provider.dart';
import 'community_sheet.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users       = [];
  List<dynamic> _communities = [];
  bool _loading          = true;
  bool _commLoading      = true;
  String? _error;
  String? _commError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
    _fetchCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService().dio.get('/users');
      if (response.data['success'] == true) {
        setState(() { _users = response.data['data'] ?? []; _loading = false; });
      }
    } on DioException catch (e) {
      setState(() { _error = ApiService.getErrorMessage(e); _loading = false; });
    }
  }

  Future<void> _fetchCommunities() async {
    setState(() { _commLoading = true; _commError = null; });
    try {
      final r = await ApiService().dio.get('/messages/communities');
      if (r.data['success'] == true) {
        setState(() { _communities = r.data['data'] ?? []; _commLoading = false; });
      }
    } on DioException catch (e) {
      setState(() { _commError = ApiService.getErrorMessage(e); _commLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildTopBar(context),
          _buildOnlineRow(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDirectList(context),
                _buildCommunitiesList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final countColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: AppTextStyles.displayMd.copyWith(
                  color: nameColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: isDark ? -0.8 : -1.2,
                ),
              ),
              Text(
                _loading ? 'Loading...' : '${_users.length} on campus',
                style: AppTextStyles.bodySm.copyWith(
                  color: countColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconButton(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.edit_outlined,
            onTap: () async {
              final result = await showCommunitySheet(context);
              if (result != null) _fetchCommunities();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final subColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: SizedBox(
        height: 80,
        child: _loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3),
                    ),
                  ),
                ),
              )
            : _users.isEmpty
                ? Center(
                    child: Text(
                      'No users online',
                      style: AppTextStyles.bodyXs.copyWith(color: subColor),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final user = _users[i];
                      final name = user['name']?.toString() ?? 'User';
                      final avatar = user['avatar']?.toString();
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GVibeAvatar(
                                  imageUrl: avatar,
                                  initials: name.isNotEmpty ? name[0] : '?',
                                  size: 48,
                                  showGlow: true,
                                ),
                                Positioned(
                                  right: 1,
                                  bottom: 1,
                                  child: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34C77B), // success
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name.split(' ').first,
                              style: AppTextStyles.bodyXs.copyWith(color: textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final activeColor = isDark ? Colors.white : const Color(0xFF171717);
    final inactiveColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final indicatorColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: indicatorColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.tabActive.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.tabInactive,
        labelColor: activeColor,
        unselectedLabelColor: inactiveColor,
        tabs: const [
          Tab(text: 'Direct'),
          Tab(text: 'Communities'),
        ],
      ),
    );
  }

  Widget _buildDirectList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final separatorColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final emptyColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(accentColor),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: AppTextStyles.bodyMd.copyWith(
                color: isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42),
              ),
            ),
            const SizedBox(height: 16),
            GVibeButton(label: 'Retry', onPressed: _fetchUsers),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users on campus yet.',
          style: AppTextStyles.bodyMd.copyWith(color: emptyColor),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _users.length,
      separatorBuilder: (_, __) => Divider(
        color: separatorColor,
        height: 0.5,
        indent: 82,
      ),
      itemBuilder: (_, i) {
        final user = _users[i];
        final name = user['name']?.toString() ?? 'User';
        final bio = user['bio']?.toString() ?? 'Tap to start chatting';
        final level = user['level'] ?? 1;
        return _ChatRow(
          name: name,
          time: 'LVL $level',
          message: bio,
          hasUnread: false,
          unreadCount: 0,
          isOnline: true,
          onTap: () => context.push('/chat/${user['_id']}'),
        );
      },
    );
  }

  Widget _buildCommunitiesList(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final accentColor  = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final errorColor   = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);
    final separatorColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final emptyColor   = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final titleColor   = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final iconBg       = isDark ? const Color(0xFF1A1F4D) : const Color(0xFFF3F4F6);

    if (_commLoading) {
      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accentColor)));
    }
    if (_commError != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_commError!, style: AppTextStyles.bodyMd.copyWith(color: errorColor)),
          const SizedBox(height: 16),
          GVibeButton(label: 'Retry', onPressed: _fetchCommunities),
        ]),
      );
    }
    if (_communities.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.group_rounded, color: accentColor, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No communities yet', style: AppTextStyles.headlineMd.copyWith(color: titleColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Join a community to start vibing', style: AppTextStyles.bodyMd.copyWith(color: emptyColor)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: GVibeButton(
              label: 'Browse Communities',
              onPressed: () async {
                final result = await showCommunitySheet(context);
                if (result != null) _fetchCommunities();
              },
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: accentColor,
      onRefresh: _fetchCommunities,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _communities.length,
        separatorBuilder: (_, __) => Divider(color: separatorColor, height: 0.5, indent: 82),
        itemBuilder: (_, i) {
          final c = _communities[i];
          final name        = c['name']?.toString() ?? 'Community';
          final desc        = c['description']?.toString() ?? '';
          final memberCount = c['memberCount'] ?? 0;
          final isPrivate   = c['isPrivate'] == true;
          final id          = c['_id']?.toString() ?? '';
          return _ChatRow(
            name: name,
            time: '$memberCount members',
            message: isPrivate ? '🔒 Private · $desc' : desc.isEmpty ? 'Tap to open chat' : desc,
            hasUnread: false,
            unreadCount: 0,
            isOnline: false,
            onTap: () => context.push('/community/$id', extra: name),
          );
        },
      ),
    );
  }
}

// ─── Chat Row ─────────────────────────────────────────────────────────────────
class _ChatRow extends StatelessWidget {
  final String name;
  final String time;
  final String message;
  final bool hasUnread;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatRow({
    required this.name,
    required this.time,
    required this.message,
    this.hasUnread = false,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final msgColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);
    final timeColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final unreadBadgeBg = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Stack(
              children: [
                GVibeAvatar(
                  initials: name.isNotEmpty ? name[0] : '?',
                  size: 52,
                  showGlow: isOnline,
                ),
                if (isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C77B), // success
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.headlineSm.copyWith(
                          color: nameColor,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: AppTextStyles.monoXs.copyWith(
                          color: hasUnread ? unreadBadgeBg : timeColor,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 13,
                            color: hasUnread ? nameColor : msgColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread && unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: unreadBadgeBg,
                            borderRadius: BorderRadius.circular(999), // pill
                          ),
                          child: Text(
                            '$unreadCount',
                            style: AppTextStyles.monoXs.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
