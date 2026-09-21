import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import 'dart:async';
import '../../core/services/socket_service.dart';
import 'community_sheet.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _convos       = []; // real DM conversations (inbox)
  List<dynamic> _communities  = [];
  List<dynamic> _following    = []; // users this user is following
  bool _loading               = true;
  bool _commLoading           = true;
  String? _error;
  String? _commError;
  String? _myId;

  StreamSubscription<DmMessage>? _dmSub;
  StreamSubscription<String>? _onlineSub;
  StreamSubscription<String>? _offlineSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyId();
    _fetchConversations();
    _fetchCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dmSub?.cancel();
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myId = prefs.getString('user_id');
    });
    _subscribeToSockets();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    if (_myId == null) return;
    try {
      final r = await ApiService().dio.get('/users/$_myId/following');
      if (r.data['success'] == true) {
        setState(() {
          _following = r.data['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  void _subscribeToSockets() {
    _dmSub?.cancel();
    _dmSub = SocketService.instance.dmStream.listen((dm) {
      if (!mounted) return;
      _handleIncomingDm(dm);
    });

    _onlineSub?.cancel();
    _onlineSub = SocketService.instance.onlineStream.listen((userId) {
      if (!mounted) return;
      _updateUserOnlineStatus(userId, true);
    });

    _offlineSub?.cancel();
    _offlineSub = SocketService.instance.offlineStream.listen((userId) {
      if (!mounted) return;
      _updateUserOnlineStatus(userId, false);
    });
  }

  void _handleIncomingDm(DmMessage dm) {
    // Only process the message if it belongs to the current user
    if (dm.senderId != _myId && dm.receiverId != _myId) return;
    
    final partnerId = dm.senderId == _myId ? dm.receiverId : dm.senderId;

    setState(() {
      final index = _convos.indexWhere((convo) {
        final sender = convo['sender'] is Map ? convo['sender'] : null;
        final receiver = convo['receiver'] is Map ? convo['receiver'] : null;
        final sId = sender?['_id']?.toString() ?? '';
        final rId = receiver?['_id']?.toString() ?? '';
        final pId = sId == _myId ? rId : sId;
        return pId == partnerId;
      });

      final newConvo = {
        '_id': dm.id,
        'sender': dm.senderId == _myId 
            ? {'_id': _myId, 'name': 'You'} 
            : {'_id': dm.senderId, 'name': dm.senderName, 'avatar': dm.senderAvatar},
        'receiver': dm.senderId == _myId
            ? {'_id': dm.receiverId}
            : {'_id': _myId},
        'ciphertext': dm.ciphertext,
        'nonce': dm.nonce,
        'mac': dm.mac,
        'createdAt': dm.createdAt.toIso8601String(),
        'read': false, // Socket message starts as unread
      };

      if (index != -1) {
        final existingConvo = _convos[index];
        newConvo['sender'] = existingConvo['sender'];
        newConvo['receiver'] = existingConvo['receiver'];
        
        _convos.removeAt(index);
        _convos.insert(0, newConvo);
      } else {
        _convos.insert(0, newConvo);
      }
    });
  }

  void _updateUserOnlineStatus(String userId, bool isOnline) {
    setState(() {
      for (var convo in _convos) {
        final sender = convo['sender'] is Map ? convo['sender'] : null;
        final receiver = convo['receiver'] is Map ? convo['receiver'] : null;
        final sId = sender?['_id']?.toString() ?? '';
        final p = sId == _myId ? receiver : sender;
        if (p != null && p['_id']?.toString() == userId) {
          final updatedPartner = Map<String, dynamic>.from(p);
          updatedPartner['lastSeen'] = isOnline ? null : DateTime.now().toIso8601String();
          if (sId == _myId) {
            convo['receiver'] = updatedPartner;
          } else {
            convo['sender'] = updatedPartner;
          }
        }
      }

      for (var i = 0; i < _following.length; i++) {
        final user = _following[i];
        if (user['_id']?.toString() == userId) {
          final updatedUser = Map<String, dynamic>.from(user);
          updatedUser['lastSeen'] = isOnline ? null : DateTime.now().toIso8601String();
          _following[i] = updatedUser;
        }
      }
    });
  }

  // BUG-05 fix: fetch real DM conversations instead of all users
  Future<void> _fetchConversations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService().dio.get('/messages/conversations');
      if (response.data['success'] == true) {
        setState(() { _convos = response.data['data'] ?? []; _loading = false; });
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
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          const BrandTitle(
            'Messages',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          const Spacer(),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.edit_square,
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
    if (_following.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final titleColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final avatarBg = isDark ? const Color(0xFF1A2624) : const Color(0xFFEDF7F5);
    final tealColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    final goldColor = isDark ? const Color(0xFFD97706) : const Color(0xFFB45309);
    final dividerColor = isDark ? const Color(0xFF1E2E2B) : const Color(0xFFE0F0ED);

    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Text(
              'ONLINE NOW',
              style: AppTextStyles.label.copyWith(
                color: titleColor,
                fontSize: 11,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _following.length,
              itemBuilder: (context, index) {
                final user = _following[index];
                final name = user['name']?.toString() ?? '';
                final avatar = user['avatar']?.toString();
                final uid = user['_id']?.toString() ?? '';
                final isOnline = user['lastSeen'] == null;
                final firstName = name.split(' ').first;

                return GestureDetector(
                  onTap: () => context.push('/chat/$uid'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: avatarBg,
                                border: Border.all(
                                  color: isOnline
                                      ? tealColor.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: avatar != null && avatar.isNotEmpty
                                    ? Image.network(
                                        avatar,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              color: tealColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: tealColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: goldColor,
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
                        const SizedBox(height: 4),
                        Text(
                          firstName,
                          style: AppTextStyles.bodyXs.copyWith(
                            color: nameColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                          ),
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
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF182220) : const Color(0xFFDDF0EC);
    final activeColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    final inactiveColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: activeColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.tabActive.copyWith(
          fontWeight: FontWeight.w600,
          color: activeColor,
          fontSize: 13,
        ),
        unselectedLabelStyle: AppTextStyles.tabInactive.copyWith(
          fontSize: 13,
          color: inactiveColor,
        ),
        labelColor: activeColor,
        unselectedLabelColor: inactiveColor,
        tabs: const [
          Tab(text: 'direct'),
          Tab(text: 'communities'),
        ],
      ),
    );
  }

  Widget _buildDirectList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final separatorColor = isDark ? const Color(0xFF182220) : const Color(0xFFE0F0ED);
    final emptyColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final accentColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    final iconBg      = isDark ? const Color(0xFF0D1412) : const Color(0xFFEDF7F5);
    final titleColor  = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);

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
            GVibeButton(label: 'Retry', onPressed: _fetchConversations),
          ],
        ),
      );
    }
    if (_convos.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.chat_bubble_outline_rounded, color: accentColor, size: 36),
          ),
          const SizedBox(height: 20),
          Text('No messages yet', style: AppTextStyles.headlineMd.copyWith(color: titleColor, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Find someone on campus to start a conversation', style: AppTextStyles.bodyMd.copyWith(color: emptyColor)),
        ]),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: _fetchConversations,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _convos.length + 1,
        separatorBuilder: (_, index) {
          if (index == 0) return const SizedBox.shrink();
          return Divider(
            color: separatorColor,
            height: 0.5,
            indent: 80,
          );
        },
        itemBuilder: (_, i) {
          if (i == 0) {
            return _buildOnlineRow(context);
          }
          final convo = _convos[i - 1];

          // The conversation has sender + receiver populated objects.
          // Find which one is NOT the current user = the partner.
          final sender   = convo['sender']   is Map ? convo['sender']   : null;
          final receiver = convo['receiver'] is Map ? convo['receiver'] : null;
          final senderId   = sender?['_id']?.toString() ?? '';

          final Map<String, dynamic>? partner =
              senderId == _myId ? receiver : sender;

          final name      = partner?['name']?.toString() ?? 'Unknown';
          final avatar    = partner?['avatar']?.toString();
          final partnerId = partner?['_id']?.toString() ?? senderId;

          // Online: lastSeen == null means currently online
          final lastSeen  = partner?['lastSeen'];
          final isOnline  = lastSeen == null;

          // Last message preview
          final hasCiphertext = convo['ciphertext'] != null;
          final lastPreview = hasCiphertext
              ? '🔒 Encrypted message'
              : (convo['content']?.toString() ?? '');

          // Timestamp
          final createdAt = convo['createdAt']?.toString() ?? '';
          String timeLabel = '';
          if (createdAt.isNotEmpty) {
            try {
              final dt = DateTime.parse(createdAt).toLocal();
              final now = DateTime.now();
              if (now.difference(dt).inDays == 0) {
                final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                final m = dt.minute.toString().padLeft(2, '0');
                timeLabel = '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
              } else if (now.difference(dt).inDays < 7) {
                const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
                timeLabel = days[dt.weekday - 1];
              } else {
                timeLabel = '${dt.day}/${dt.month}';
              }
            } catch (_) {}
          }

          final senderIdStr = sender is Map ? sender['_id']?.toString() : sender?.toString();
          final isLastMessageFromPartner = senderIdStr != _myId;
          final isUnread = convo['read'] == false;
          final hasUnread = isLastMessageFromPartner && isUnread;

          return _ChatRow(
            name:       name,
            avatarUrl:  avatar,
            time:       timeLabel,
            message:    lastPreview,
            hasUnread:  hasUnread,
            unreadCount: hasUnread ? 1 : 0,
            isOnline:   isOnline,
            onTap: () => context.push('/chat/$partnerId'),
          );
        },
      ),
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
  final String? avatarUrl; // added for BUG-05 fix
  final String time;
  final String message;
  final bool hasUnread;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatRow({
    required this.name,
    this.avatarUrl,
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
    final nameColor = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);
    final msgColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final timeColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF6B9E99);
    final tealColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    final goldColor = isDark ? const Color(0xFFD97706) : const Color(0xFFB45309);
    final avatarBg = isDark ? const Color(0xFF131C1A) : const Color(0xFFEDF7F5);

    final isEncrypted = message.contains('Encrypted') || message.startsWith('🔒');
    final displayText = isEncrypted ? 'Encrypted message' : message;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Left: 46px avatar with 2px teal ring
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tealColor, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Container(
                      color: avatarBg,
                      child: avatarUrl != null && avatarUrl!.isNotEmpty
                          ? Image.network(
                              avatarUrl!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: tealColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: tealColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0.5,
                    bottom: 0.5,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: goldColor,
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
            const SizedBox(width: 12),

            // Middle: Name and message preview
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: nameColor,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (isEncrypted) ...[
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: tealColor,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          displayText,
                          style: AppTextStyles.bodySm.copyWith(
                            fontSize: 13,
                            fontStyle: isEncrypted ? FontStyle.italic : FontStyle.normal,
                            color: msgColor,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Right: Time and unread badge
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: AppTextStyles.bodyXs.copyWith(
                    color: timeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: tealColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 0 ? '$unreadCount' : '1',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
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
