import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class CommunityProfileScreen extends StatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityProfileScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  Map<String, dynamic>? _communityDetails;
  bool _loading = true;
  String? _error;
  String? _myId;
  String _myRole = 'member';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _myId = prefs.getString('user_id');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final r = await ApiService().dio.get(
        '/messages/communities/${widget.communityId}/details',
      );
      if (r.data['success'] == true) {
        final data = r.data['data'];
        setState(() {
          _communityDetails = data;
          _loading = false;
        });

        // Determine current user's role
        final members = data['members'] as List? ?? [];
        final me = members.firstWhere(
          (m) => m['user'] != null && m['user']['_id']?.toString() == _myId,
          orElse: () => null,
        );
        if (me != null) {
          setState(() {
            _myRole = me['role']?.toString() ?? 'member';
          });
        }
      }
    } on DioException catch (e) {
      setState(() {
        _error = ApiService.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _kickMember(String userId) async {
    try {
      final r = await ApiService().dio.delete(
        '/messages/communities/${widget.communityId}/members/$userId',
      );
      if (r.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member kicked successfully')),
        );
        _loadData();
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.getErrorMessage(e))),
      );
    }
  }

  Future<void> _toggleModerator(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'member' : 'admin';
    try {
      final r = await ApiService().dio.put(
        '/messages/communities/${widget.communityId}/members/$userId/role',
        data: {'role': newRole},
      );
      if (r.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member role updated to $newRole')),
        );
        _loadData();
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.getErrorMessage(e))),
      );
    }
  }

  void _showUserProfileBox(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _UserProfileBox(
        user: user,
        myId: _myId,
        onRelationshipChanged: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    final members = _communityDetails?['members'] as List? ?? [];
    final description = _communityDetails?['description']?.toString() ?? 'No description provided.';
    final isPrivate = _communityDetails?['isPrivate'] == true;
    final inviteCode = _communityDetails?['inviteCode']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 30, 16, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: nameColor, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Community Details',
                style: AppTextStyles.headlineMd.copyWith(
                  color: nameColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(accentColor)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodyMd.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    // Community Banner/Avatar card
                    Center(
                      child: GVibeAvatar(
                        initials: widget.communityName.isNotEmpty ? widget.communityName[0] : '#',
                        size: 96,
                        showGlow: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        widget.communityName,
                        style: AppTextStyles.displaySm.copyWith(color: nameColor, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPrivate 
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15) 
                              : accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPrivate ? '🔒 PRIVATE COMMUNITY' : '🌍 PUBLIC COMMUNITY',
                          style: AppTextStyles.monoXs.copyWith(
                            color: isPrivate ? const Color(0xFFF59E0B) : accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (isPrivate && inviteCode.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1011) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Invite Code: ',
                                style: AppTextStyles.bodySm.copyWith(color: subColor),
                              ),
                              Text(
                                inviteCode,
                                style: AppTextStyles.monoSm.copyWith(
                                  color: nameColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invite code copied to clipboard')),
                                  );
                                },
                                child: Icon(Icons.copy_rounded, color: accentColor, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    GVibeCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: AppTextStyles.label.copyWith(color: subColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: AppTextStyles.bodyMd.copyWith(color: nameColor, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Members',
                          style: AppTextStyles.headlineSm.copyWith(color: nameColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${members.length}',
                            style: AppTextStyles.monoXs.copyWith(color: nameColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Member rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                      itemBuilder: (_, i) {
                        final member = members[i];
                        final user = member['user'] as Map<String, dynamic>?;
                        if (user == null) return const SizedBox.shrink();

                        final mId = user['_id']?.toString() ?? '';
                        final mName = user['name']?.toString() ?? 'Anonymous';
                        final mAvatar = user['avatar']?.toString();
                        final mDept = user['dept']?.toString() ?? '';
                        final mRole = member['role']?.toString() ?? 'member';

                        final isMe = mId == _myId;
                        final isOwner = mRole == 'owner';
                        final isModerator = mRole == 'admin';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GVibeAvatar(
                            imageUrl: mAvatar,
                            initials: mName.isNotEmpty ? mName[0] : '?',
                            size: 40,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showUserProfileBox(user),
                                  child: Text(
                                    mName,
                                    style: AppTextStyles.headlineSm.copyWith(
                                      color: nameColor,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('OWNER', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ] else if (isModerator) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('MODERATOR', style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            mDept,
                            style: AppTextStyles.bodyXs.copyWith(color: subColor),
                          ),
                          trailing: !isMe && (_myRole == 'owner' || (_myRole == 'admin' && mRole == 'member'))
                              ? PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded, color: subColor),
                                  color: isDark ? const Color(0xFF0F1011) : Colors.white,
                                  onSelected: (action) {
                                    if (action == 'kick') {
                                      _kickMember(mId);
                                    } else if (action == 'mod') {
                                      _toggleModerator(mId, mRole);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (_myRole == 'owner')
                                      PopupMenuItem(
                                        value: 'mod',
                                        child: Text(
                                          isModerator ? 'Remove Moderator' : 'Make Moderator',
                                          style: AppTextStyles.bodySm.copyWith(color: nameColor),
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: 'kick',
                                      child: Text(
                                        'Kick Member',
                                        style: AppTextStyles.bodySm.copyWith(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

class _UserProfileBox extends StatefulWidget {
  final Map<String, dynamic> user;
  final String? myId;
  final VoidCallback onRelationshipChanged;

  const _UserProfileBox({
    required this.user,
    required this.myId,
    required this.onRelationshipChanged,
  });

  @override
  State<_UserProfileBox> createState() => _UserProfileBoxState();
}

class _UserProfileBoxState extends State<_UserProfileBox> {
  bool _isFollowing = false;
  int _followersCount = 0;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    final followersList = widget.user['followers'] as List? ?? [];
    _isFollowing = followersList.any((f) => f.toString() == widget.myId || (f is Map && f['_id']?.toString() == widget.myId));
    _followersCount = followersList.length;
  }

  Future<void> _toggleFollow() async {
    setState(() => _toggling = true);
    try {
      final r = await ApiService().dio.post('/users/${widget.user['_id']}/follow');
      if (r.data['success'] == true) {
        setState(() {
          _isFollowing = r.data['data']['isFollowing'];
          _followersCount = r.data['data']['followersCount'];
          _toggling = false;
        });
        widget.onRelationshipChanged();
      }
    } catch (_) {
      setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1011) : Colors.white;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    final name = widget.user['name']?.toString() ?? 'User';
    final bio = widget.user['bio']?.toString() ?? 'No bio shared yet.';
    final dept = widget.user['dept']?.toString() ?? '';
    final year = widget.user['year']?.toString() ?? '';
    final avatar = widget.user['avatar']?.toString();
    final followingCount = (widget.user['following'] as List?)?.length ?? 0;

    // Check relationship level
    final followingList = widget.user['following'] as List? ?? [];
    final theyFollowMe = followingList.any((f) => f.toString() == widget.myId || (f is Map && f['_id']?.toString() == widget.myId));
    final isMutual = _isFollowing && theyFollowMe;

    String relationLabel = 'FAN';
    if (isMutual) {
      relationLabel = '🤝 FRIEND';
    } else if (_isFollowing) {
      relationLabel = '⭐️ FOLLOWING';
    } else if (theyFollowMe) {
      relationLabel = '👤 FOLLOWER';
    }

    final isMe = widget.user['_id']?.toString() == widget.myId;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GVibeAvatar(
                  imageUrl: avatar,
                  initials: name.isNotEmpty ? name[0] : '?',
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.headlineMd.copyWith(color: nameColor, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dept + (year.isNotEmpty ? ' · Year $year' : ''),
                        style: AppTextStyles.bodyXs.copyWith(color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (relationLabel.isNotEmpty && !isMe) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isMutual 
                      ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                      : accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  relationLabel,
                  style: AppTextStyles.monoXs.copyWith(
                    color: isMutual ? const Color(0xFF10B981) : accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Bio',
              style: AppTextStyles.label.copyWith(color: subColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              bio,
              style: AppTextStyles.bodyMd.copyWith(color: nameColor),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$_followersCount', style: AppTextStyles.headlineSm.copyWith(color: nameColor, fontWeight: FontWeight.bold)),
                    Text('Followers', style: AppTextStyles.bodyXs.copyWith(color: subColor)),
                  ],
                ),
                Column(
                  children: [
                    Text('$followingCount', style: AppTextStyles.headlineSm.copyWith(color: nameColor, fontWeight: FontWeight.bold)),
                    Text('Following', style: AppTextStyles.bodyXs.copyWith(color: subColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: AppTextStyles.bodyMd.copyWith(color: subColor)),
                  ),
                ),
                if (!isMe)
                  Expanded(
                    child: _toggling
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : GVibeButton(
                            label: _isFollowing ? 'Unfollow' : 'Follow',
                            onPressed: _toggleFollow,
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
