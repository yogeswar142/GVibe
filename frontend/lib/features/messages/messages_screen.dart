import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.get('/users');
      if (response.data['success'] == true) {
        setState(() {
          _users = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = ApiService.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildTopBar(context),
          _buildOnlineRow(context),
          _buildTabBar(context, ext),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDirectList(context),
                _buildCommunitiesEmpty(context),
              ],
            ),
          ),
        ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Messages',
                  style: AppTextStyles.displayMd.copyWith(color: cs.onSurface)),
              Text(_loading ? 'Loading...' : '${_users.length} on campus',
                  style: AppTextStyles.bodySm.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
          const Spacer(),
          // Compose button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: context.ext.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: ext.outline, width: 0.5)),
      ),
      child: SizedBox(
        height: 80,
        child: _loading
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : _users.isEmpty
                ? Center(child: Text('No users online', style: AppTextStyles.bodyXs.copyWith(color: cs.onSurfaceVariant)))
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
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cs.surface, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name.split(' ').first,
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: cs.onSurfaceVariant),
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

  Widget _buildTabBar(BuildContext context, AppThemeExtension ext) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: ext.outline, width: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: cs.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTextStyles.tabActive,
        unselectedLabelStyle: AppTextStyles.tabInactive,
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        tabs: const [
          Tab(text: 'Direct'),
          Tab(text: 'Communities'),
        ],
      ),
    );
  }

  Widget _buildDirectList(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: cs.error)),
            const SizedBox(height: 16),
            GVibeButton(label: 'Retry', onPressed: _fetchUsers),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text('No users on campus yet.',
            style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _users.length,
      separatorBuilder: (_, __) => Divider(
        color: context.ext.outline,
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

  Widget _buildCommunitiesEmpty(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.group_rounded, color: cs.primary, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No communities yet',
              style: AppTextStyles.headlineMd.copyWith(color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Join a community to start vibing',
              style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: GVibeButton(
              label: 'Browse Communities',
              onPressed: () {},
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;

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
                  initials: name[0],
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
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
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
                          color: cs.onSurface,
                          fontWeight: hasUnread
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: AppTextStyles.monoXs.copyWith(
                          color: hasUnread ? cs.primary : cs.onSurfaceVariant,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
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
                            color: hasUnread
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread && unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(12),
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
