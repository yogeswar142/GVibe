import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../shared/widgets/share_post_sheet.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import '../../shared/widgets/discord_hyperlink.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _activeTab = 0;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  bool _isOwnProfile = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  String? _loggedInUserId;
  List<dynamic> _userPosts = [];
  bool _postsLoading = false;
  Map<String, dynamic>? _analyticsData;
  bool _analyticsLoading = false;

  final List<String> _tabs = ['POSTS', 'VIBES', 'ANALYTICS'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cachedUser = await AuthService.getUser();
      _loggedInUserId = cachedUser?['_id']?.toString();

      final targetId = widget.userId;
      String? profileUserId;

      if (targetId == null || targetId == _loggedInUserId) {
        _isOwnProfile = true;
        final response = await ApiService().dio.get('/users/profile');
        if (response.data['success'] == true) {
          final data = response.data['data'];
          profileUserId = data['_id']?.toString() ?? _loggedInUserId;
          setState(() {
            _user = data;
            _followersCount = (data['followers'] as List?)?.length ?? 0;
            _followingCount = (data['following'] as List?)?.length ?? 0;
            _loading = false;
          });
        }
      } else {
        _isOwnProfile = false;
        profileUserId = targetId;
        final response = await ApiService().dio.get('/users/$targetId');
        if (response.data['success'] == true) {
          final data = response.data['data'];
          setState(() {
            _user = data;
            _isFollowing = data['isFollowing'] ?? false;
            _followersCount = data['followersCount'] ?? 0;
            _followingCount = data['followingCount'] ?? 0;
            _loading = false;
          });
        }
      }

      // Fetch user's dynamic posts
      if (profileUserId != null) {
        setState(() => _postsLoading = true);
        try {
          final postsRes = await ApiService().dio.get(
            '/posts',
            queryParameters: {'author': profileUserId},
          );
          if (postsRes.data['success'] == true && mounted) {
            setState(() {
              _userPosts = (postsRes.data['data'] as List?) ?? [];
              _postsLoading = false;
            });
          }
        } catch (_) {
          if (mounted) setState(() => _postsLoading = false);
        }
      }

      // Fetch user analytics if own profile
      if (_isOwnProfile) {
        try {
          final analyticsRes = await ApiService().dio.get('/analytics/me');
          if (analyticsRes.data['success'] == true && mounted) {
            setState(() {
              _analyticsData = analyticsRes.data['data'];
            });
          }
        } catch (_) {}
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiService.getErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
    try {
      final res = await ApiService().dio.get('/analytics/me');
      if (res.data['success'] == true && mounted) {
        setState(() {
          _analyticsData = res.data['data'];
          _analyticsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _analyticsLoading = false);
    }
  }

  Future<void> _togglePostLike(int index) async {
    if (index < 0 || index >= _userPosts.length) return;
    final post = _userPosts[index];
    final postId = post['_id']?.toString() ?? post['id']?.toString();
    if (postId == null) return;
    try {
      final res = await ApiService().dio.put('/posts/$postId/like');
      if (res.data['success'] == true && mounted) {
        setState(() {
          _userPosts[index] = res.data['data'];
        });
      }
    } catch (_) {}
  }

  Future<void> _deletePost(String postId) async {
    try {
      final response = await ApiService().dio.delete('/posts/$postId');
      if (response.data['success'] == true && mounted) {
        setState(() {
          _userPosts.removeWhere((p) => (p['_id'] ?? p['id'])?.toString() == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post')),
        );
      }
    }
  }

  Future<void> _confirmDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePost(postId);
    }
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

  Future<void> _toggleFollow() async {
    final targetId = widget.userId;
    if (targetId == null) return;
    try {
      final response =
          await ApiService().dio.post('/users/$targetId/follow');
      if (response.data['success'] == true) {
        setState(() {
          _isFollowing = response.data['data']['isFollowing'];
          _followersCount = response.data['data']['followersCount'];
        });
      }
    } on DioException catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go(AppRouter.login);
  }

  Future<void> _showPrivacySettingsDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1011) : Colors.white;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    String currentPrivacy = _user?['privacy']?.toString() ?? 'public';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
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
                Text(
                  'Privacy Settings',
                  style: AppTextStyles.headlineMd.copyWith(color: nameColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: Text('Public Profile', style: TextStyle(color: nameColor)),
                  subtitle: const Text('Anyone can message you and see your campus activity', style: TextStyle(fontSize: 11)),
                  value: 'public',
                  groupValue: currentPrivacy,
                  activeColor: accentColor,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentPrivacy = val);
                  },
                ),
                RadioListTile<String>(
                  title: Text('Private Profile', style: TextStyle(color: nameColor)),
                  subtitle: const Text('New or non-friend messages will be filtered and sorted separately', style: TextStyle(fontSize: 11)),
                  value: 'private',
                  groupValue: currentPrivacy,
                  activeColor: accentColor,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => currentPrivacy = val);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: accentColor)),
                    ),
                    const SizedBox(width: 8),
                    GVibeButton(
                      label: 'Save',
                      onPressed: () async {
                        try {
                          final response = await ApiService().dio.put(
                            '/users/profile',
                            data: {'privacy': currentPrivacy},
                          );
                          if (response.data['success'] == true) {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            if (mounted) {
                              setState(() {
                                _user = response.data['data'];
                              });
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Privacy settings updated successfully')),
                              );
                            }
                          }
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final errorColor = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(primaryColor),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: AppTextStyles.bodyMd.copyWith(color: errorColor),
                            ),
                            const SizedBox(height: 16),
                            GVibeButton(
                              label: 'Retry',
                              onPressed: _loadProfile,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProfile,
                        color: primaryColor,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _DigitalStudentIDCard(
                              user: _user,
                              isOwnProfile: _isOwnProfile,
                              onEdit: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Profile editing coming soon'),
                                    backgroundColor: primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                                    ),
                                  ),
                                );
                              },
                              onToggleFollow: _toggleFollow,
                              isFollowing: _isFollowing,
                            ),
                            _buildUserBio(),
                            _buildStatsGrid(),
                            _buildTabBar(),
                            _buildTabContent(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final logoColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final errorColor = isDark ? const Color(0xFFE5484D) : const Color(0xFFD93D42);

    return Container(
      padding: EdgeInsets.fromLTRB(_isOwnProfile ? 20 : 8, MediaQuery.of(context).padding.top + 12, 20, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          if (!_isOwnProfile) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: logoColor, size: 22),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _isOwnProfile ? 'GVibe' : 'Profile',
            style: AppTextStyles.displaySm.copyWith(
              color: logoColor,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              letterSpacing: isDark ? -0.8 : -1.2,
            ),
          ),
          const Spacer(),
          const ThemeToggleButton(),
          if (_isOwnProfile) ...[          
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.settings_outlined,
              onTap: _showPrivacySettingsDialog,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(isDark ? 8 : 6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: errorColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: AppTextStyles.labelLg.copyWith(
                        color: errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 8),
            _IconButton(
              icon: Icons.notifications_outlined,
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserBio() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bioColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);
    final bio = _user?['bio']?.toString() ?? '';
    if (bio.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        bio,
        style: AppTextStyles.bodyMd.copyWith(
          color: bioColor,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(_formatCount(_userPosts.length), 'Posts'),
          const SizedBox(width: 10),
          _statCard(_formatCount(_followersCount), 'Followers', onTap: () {
            final userId = widget.userId ?? _loggedInUserId;
            if (userId != null) context.push('/profile/$userId/followers');
          }),
          const SizedBox(width: 10),
          _statCard(_formatCount(_followingCount), 'Following', onTap: () {
            final userId = widget.userId ?? _loggedInUserId;
            if (userId != null) context.push('/profile/$userId/following');
          }),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final labelColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: GVibeCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Text(
                value,
                style: AppTextStyles.displaySm.copyWith(
                  color: valueColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.bodyXs.copyWith(color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final activeColor = isDark ? Colors.white : const Color(0xFF171717);
    final inactiveColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final activeBorderColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: _tabs.asMap().entries.map((e) {
          final isActive = e.key == _activeTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? activeBorderColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: AppTextStyles.label.copyWith(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildPostsTab();
      case 1:
        return _buildEmptyTab('VIBES', Icons.bolt);
      case 2:
        return _buildAnalyticsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPostsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final labelColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    if (_postsLoading && _userPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
        ),
      );
    }

    if (_userPosts.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(isDark ? 8 : 6),
          border: Border.all(
            color: isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 44, color: labelColor.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(
              'No posts yet',
              style: AppTextStyles.headlineSm.copyWith(
                color: nameColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isOwnProfile
                  ? 'Your shared vibes and campus posts will appear here.'
                  : 'This student hasn\'t published any posts yet.',
              style: AppTextStyles.bodySm.copyWith(color: labelColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: _userPosts.asMap().entries.map((entry) {
          final index = entry.key;
          final post = entry.value is Map<String, dynamic>
              ? entry.value as Map<String, dynamic>
              : Map<String, dynamic>.from(entry.value as Map);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPostCard(post, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final nameColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final contentColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF333333);
    final actionColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    final postId = post['_id']?.toString() ?? post['id']?.toString() ?? '';
    final author = post['author'] is Map ? post['author'] as Map : null;
    final authorName = author?['name']?.toString() ?? _user?['name']?.toString() ?? 'Student';
    final avatar = author?['avatar']?.toString() ?? _user?['avatar']?.toString();
    final initials = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
    final content = post['content']?.toString() ?? '';
    final tags = (post['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];
    final likesList = (post['likes'] as List?) ?? [];
    final likes = likesList.length;
    final isLiked = _loggedInUserId != null && likesList.any((id) => id.toString() == _loggedInUserId);
    final comments = (post['comments'] as List?)?.length ?? 0;
    final shares = (post['sharesCount'] is num) ? (post['sharesCount'] as num).toInt() : 0;
    final createdAt = post['createdAt']?.toString() ?? '';
    final timeAgo = _timeAgo(createdAt);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GVibeAvatar(
                imageUrl: avatar,
                size: 38,
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
                        color: nameColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: AppTextStyles.bodyXs.copyWith(
                        color: subtitleColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isOwnProfile && postId.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: subtitleColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: () => _confirmDeletePost(postId),
                ),
            ],
          ),
          const SizedBox(height: 12),
          RichContentText(
            text: content,
            style: AppTextStyles.bodyMd.copyWith(
              color: contentColor,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$t',
                    style: AppTextStyles.monoXs.copyWith(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              AnimatedLikeButton(
                count: likes,
                isLiked: isLiked,
                onTap: () => _togglePostLike(index),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () async {
                  final newCount = await context.push<int>(
                    '/post/$postId',
                    extra: post,
                  );
                  if (newCount != null && mounted) {
                    setState(() {
                      _userPosts[index]['comments'] = List.generate(newCount, (_) => {});
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: actionColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$comments',
                      style: AppTextStyles.monoSm.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  SharePostSheet.show(
                    context,
                    post: post,
                    onShared: (newShares) {
                      setState(() {
                        _userPosts[index]['sharesCount'] = newShares;
                      });
                    },
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, color: actionColor, size: 16),
                    if (shares > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$shares',
                        style: AppTextStyles.monoSm.copyWith(
                          color: actionColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
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
    );
  }

  Widget _buildAnalyticsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final innerBg = isDark ? const Color(0xFF16191E) : const Color(0xFFF6F7F9);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    if (!_isOwnProfile) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(isDark ? 8 : 6),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 44, color: subtitleColor.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(
              'Private Analytics',
              style: AppTextStyles.headlineSm.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profile and link analytics are only accessible to the account owner.',
              style: AppTextStyles.bodySm.copyWith(color: subtitleColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_analyticsLoading && _analyticsData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(accentColor),
          ),
        ),
      );
    }

    final pData = _analyticsData?['profileAnalytics'] as Map? ?? {};
    final cData = _analyticsData?['contentAnalytics'] as Map? ?? {};
    final sData = _analyticsData?['shortLinkAnalytics'] as Map? ?? {};

    final profileViews = (pData['profileViews'] is num) ? (pData['profileViews'] as num).toInt() : 0;
    final searchAppearances = (pData['searchAppearances'] is num) ? (pData['searchAppearances'] as num).toInt() : 0;
    final profileClicks = (pData['profileClicks'] is num) ? (pData['profileClicks'] as num).toInt() : 0;
    final tagsFound = (pData['tagsFound'] as List?) ?? [];

    final totalViews = (cData['totalViews'] is num) ? (cData['totalViews'] as num).toInt() : 0;
    final uniqueViewers = (cData['uniqueViewers'] is num) ? (cData['uniqueViewers'] as num).toInt() : 0;
    final totalLikes = (cData['totalLikes'] is num) ? (cData['totalLikes'] as num).toInt() : 0;
    final totalComments = (cData['totalComments'] is num) ? (cData['totalComments'] as num).toInt() : 0;
    final totalShares = (cData['totalShares'] is num) ? (cData['totalShares'] as num).toInt() : 0;
    final followersGained = (cData['followersGained'] is num) ? (cData['followersGained'] as num).toInt() : 0;
    final linkClicks = (cData['linkClicks'] is num) ? (cData['linkClicks'] as num).toInt() : 0;
    final ctr = cData['ctr']?.toString() ?? '0.0%';

    final totalShortClicks = (sData['totalClicks'] is num) ? (sData['totalClicks'] as num).toInt() : 0;
    final uniqueShortVisitors = (sData['uniqueVisitors'] is num) ? (sData['uniqueVisitors'] as num).toInt() : 0;
    final timeBreakdown = sData['timeBreakdown'] as Map? ?? {};
    final todayClicks = (timeBreakdown['today'] is num) ? (timeBreakdown['today'] as num).toInt() : 0;
    final thisWeekClicks = (timeBreakdown['thisWeek'] is num) ? (timeBreakdown['thisWeek'] as num).toInt() : 0;
    final thisMonthClicks = (timeBreakdown['thisMonth'] is num) ? (timeBreakdown['thisMonth'] as num).toInt() : 0;

    final devices = sData['devices'] as Map? ?? {};
    final androidPct = (devices['android'] is num) ? (devices['android'] as num).toInt() : 0;
    final iphonePct = (devices['iphone'] is num) ? (devices['iphone'] as num).toInt() : 0;
    final desktopPct = (devices['desktop'] is num) ? (devices['desktop'] as num).toInt() : 0;
    final hasDeviceClicks = (androidPct + iphonePct + desktopPct) > 0;

    final topCountries = (sData['topCountries'] as List?) ?? [];
    final recentLinks = (sData['recentLinks'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with refresh button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'LIVE ANALYTICS',
                  style: AppTextStyles.monoXs.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: subtitleColor, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _loadAnalytics,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 1. Top KPI Grid (2x2) ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _analyticsKpiCard(
                  title: 'Profile Views',
                  value: _formatCount(profileViews),
                  icon: Icons.visibility_outlined,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analyticsKpiCard(
                  title: 'Search Finds',
                  value: _formatCount(searchAppearances),
                  icon: Icons.search_rounded,
                  color: const Color(0xFF27C93F),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10, height: 10),
          Row(
            children: [
              Expanded(
                child: _analyticsKpiCard(
                  title: 'Profile Clicks',
                  value: _formatCount(profileClicks),
                  icon: Icons.ads_click_rounded,
                  color: const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analyticsKpiCard(
                  title: 'Content Views',
                  value: _formatCount(totalViews),
                  icon: Icons.auto_graph_rounded,
                  color: const Color(0xFFAF52DE),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 2. People Found You For (Tags with %) ───────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(isDark ? 8 : 6),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tag_rounded, color: accentColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'PEOPLE FOUND YOU FOR',
                      style: AppTextStyles.monoXs.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (tagsFound.isEmpty)
                  Text(
                    'Search appearance tags will populate as campus peers discover you.',
                    style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                  )
                else
                  ...tagsFound.map((item) {
                    final tag = item['tag']?.toString() ?? '';
                    final pct = (item['percentage'] is num) ? (item['percentage'] as num).toInt() : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tag,
                                style: AppTextStyles.monoSm.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: AppTextStyles.monoXs.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (pct / 100.0).clamp(0.05, 1.0),
                              backgroundColor: innerBg,
                              valueColor: AlwaysStoppedAnimation(accentColor),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 3. Content Engagement Dashboard ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(isDark ? 8 : 6),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: Color(0xFF27C93F), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'CONTENT ENGAGEMENT & REACH',
                      style: AppTextStyles.monoXs.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metricStatItem('Unique Viewers', _formatCount(uniqueViewers), titleColor, subtitleColor),
                    _metricStatItem('Likes', _formatCount(totalLikes), titleColor, subtitleColor),
                    _metricStatItem('Comments', _formatCount(totalComments), titleColor, subtitleColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _metricStatItem('Shares', _formatCount(totalShares), titleColor, subtitleColor),
                    _metricStatItem('Followers+', _formatCount(followersGained), titleColor, subtitleColor),
                    _metricStatItem('Link Clicks', _formatCount(linkClicks), titleColor, subtitleColor),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Overall Click-Through Rate (CTR):',
                        style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                      ),
                      const Spacer(),
                      Text(
                        ctr,
                        style: AppTextStyles.monoSm.copyWith(
                          color: const Color(0xFF27C93F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 4. Short Link Analytics (LinkedIn / Twitter Style) ─────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(isDark ? 8 : 6),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link_rounded, color: accentColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'LINK ANALYTICS (/s/:code)',
                      style: AppTextStyles.monoXs.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Link summary numbers
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total clicks', style: AppTextStyles.bodyXs.copyWith(color: subtitleColor)),
                          const SizedBox(height: 2),
                          Text(
                            _formatCount(totalShortClicks),
                            style: AppTextStyles.headlineSm.copyWith(color: titleColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unique visitors', style: AppTextStyles.bodyXs.copyWith(color: subtitleColor)),
                          const SizedBox(height: 2),
                          Text(
                            _formatCount(uniqueShortVisitors),
                            style: AppTextStyles.headlineSm.copyWith(color: titleColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),

                // Clicks over time (Today / Week / Month)
                Row(
                  children: [
                    _timeColumn('Today', '$todayClicks', titleColor, subtitleColor),
                    _timeColumn('This week', '$thisWeekClicks', titleColor, subtitleColor),
                    _timeColumn('This month', '$thisMonthClicks', titleColor, subtitleColor),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),

                // Devices Breakdown
                Text(
                  'DEVICES',
                  style: AppTextStyles.monoXs.copyWith(color: subtitleColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (!hasDeviceClicks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No device data yet. Platform statistics will record as peers open your links.',
                      style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      _devicePill('Android', '$androidPct%', const Color(0xFF27C93F)),
                      const SizedBox(width: 8),
                      _devicePill('iPhone', '$iphonePct%', const Color(0xFF0070F3)),
                      const SizedBox(width: 8),
                      _devicePill('Desktop', '$desktopPct%', const Color(0xFFAF52DE)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Segmented visual bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (androidPct > 0)
                          Flexible(
                            flex: androidPct,
                            child: Container(height: 6, color: const Color(0xFF27C93F)),
                          ),
                        if (iphonePct > 0)
                          Flexible(
                            flex: iphonePct,
                            child: Container(height: 6, color: const Color(0xFF0070F3)),
                          ),
                        if (desktopPct > 0)
                          Flexible(
                            flex: desktopPct,
                            child: Container(height: 6, color: const Color(0xFFAF52DE)),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),

                // Top Countries Breakdown
                Text(
                  'TOP COUNTRIES',
                  style: AppTextStyles.monoXs.copyWith(color: subtitleColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (topCountries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No geo click data yet. Visitor locations will show here when peers click your links.',
                      style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
                    ),
                  )
                else
                  ...topCountries.map((c) {
                    final flag = c['flag']?.toString() ?? '🌐';
                    final name = c['country']?.toString() ?? '';
                    final pct = c['percentage'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(name, style: AppTextStyles.bodySm.copyWith(color: titleColor)),
                          const Spacer(),
                          Text('$pct%', style: AppTextStyles.monoXs.copyWith(color: subtitleColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),

                if (recentLinks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'RECENT SHORTENED LINKS',
                    style: AppTextStyles.monoXs.copyWith(color: subtitleColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...recentLinks.map((link) {
                    final shortUrl = link['shortUrl']?.toString() ?? '';
                    final destUrl = link['destinationUrl']?.toString();
                    final clicks = link['totalClicks'];
                    final clicksCount = clicks is num ? clicks.toInt() : 0;
                    return DiscordHyperlinkCard(
                      shortUrl: shortUrl,
                      destinationUrl: destUrl,
                      totalClicks: clicksCount,
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _analyticsKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.displaySm.copyWith(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.bodyXs.copyWith(color: subtitleColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _metricStatItem(String label, String value, Color titleColor, Color subtitleColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodyXs.copyWith(color: subtitleColor, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _timeColumn(String label, String value, Color titleColor, Color subtitleColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyXs.copyWith(color: subtitleColor)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.monoSm.copyWith(color: titleColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _devicePill(String label, String pct, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$label $pct',
              style: AppTextStyles.monoXs.copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final textColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 12),
          Text(
            'No $label yet',
            style: AppTextStyles.bodyMd.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _DigitalStudentIDCard extends StatefulWidget {
  final Map<String, dynamic>? user;
  final bool isOwnProfile;
  final VoidCallback onEdit;
  final VoidCallback onToggleFollow;
  final bool isFollowing;

  const _DigitalStudentIDCard({
    required this.user,
    required this.isOwnProfile,
    required this.onEdit,
    required this.onToggleFollow,
    required this.isFollowing,
  });

  @override
  State<_DigitalStudentIDCard> createState() => _DigitalStudentIDCardState();
}

class _DigitalStudentIDCardState extends State<_DigitalStudentIDCard> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    final avatar = widget.user?['avatar']?.toString();
    final level = (widget.user?['level'] is num) ? (widget.user!['level'] as num).toInt() : 1;
    final name = widget.user?['name']?.toString() ?? 'Student';
    final username = widget.user?['username']?.toString() ?? name.toLowerCase().replaceAll(' ', '_');
    final dept = widget.user?['branch']?.toString() ?? widget.user?['dept']?.toString() ?? 'Student';
    final year = widget.user?['academicLevel']?.toString() ?? widget.user?['year']?.toString() ?? '1st Year';
    final regNo = widget.user?['registrationNumber']?.toString();
    final hub = (regNo != null && regNo.isNotEmpty) ? regNo : (widget.user?['hub']?.toString() ?? 'GITAM Campus');

    // Vibe rating calculations
    final double ratingVal = ((level * 18 + 40).clamp(20, 100)) / 100.0;
    final ratingPercent = (ratingVal * 100).toStringAsFixed(0);
    
    String rank = 'INITIATE';
    if (level >= 40) {
      rank = 'ARCHMAGE';
    } else if (level >= 25) {
      rank = 'WIZARD';
    } else if (level >= 10) {
      rank = 'ACOLYTE';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showFront = !_showFront;
          });
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _showFront ? 0 : 3.1415926535),
          duration: const Duration(milliseconds: 600),
          builder: (context, val, child) {
            final isFront = val < 3.1415926535 / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(val),
              child: isFront
                  ? _buildFront(avatar, level, name, username, dept, year, hub, ratingVal, ratingPercent, rank)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.1415926535),
                      child: _buildBack(name, level),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront(
    String? avatar,
    int level,
    String name,
    String username,
    String dept,
    String year,
    String hub,
    double ratingVal,
    String ratingPercent,
    String rank,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final labelColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF5E6AD2).withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nfc, color: labelColor, size: 14),
              const SizedBox(width: 6),
              Text(
                'Student ID Card',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active',
                style: AppTextStyles.monoXs.copyWith(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: CutCornerAvatar(imageUrl: avatar, size: 76),
                    ),
                    Positioned(
                      bottom: -8,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: accentColor,
                        child: Text(
                          'Level $level',
                          style: AppTextStyles.monoXs.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.displaySm.copyWith(
                                fontSize: 18,
                                color: textColor,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildCardActionBtn(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: AppTextStyles.monoXs.copyWith(
                          color: labelColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _detailRow('Major:', dept),
                      const SizedBox(height: 3),
                      _detailRow('Class:', year),
                      const SizedBox(height: 3),
                      _detailRow(
                        widget.user?['registrationNumber'] != null && widget.user!['registrationNumber'].toString().isNotEmpty
                            ? 'ID:'
                            : 'Campus:',
                        hub,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vibe Rating: $ratingPercent%',
                    style: AppTextStyles.monoXs.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rank: $rank',
                    style: AppTextStyles.monoXs.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(isDark ? 4 : 99),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1A1B1F) : const Color(0xFFE7E8EC),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratingVal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final valueColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: AppTextStyles.monoXs.copyWith(
            color: labelColor,
            fontSize: 9,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.monoSm.copyWith(
              color: valueColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCardActionBtn() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final textColor = isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);

    if (widget.isOwnProfile) {
      return GestureDetector(
        onTap: widget.onEdit,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isDark ? 6 : 4),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Icon(Icons.edit_outlined, color: textColor, size: 14),
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onToggleFollow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isFollowing ? Colors.transparent : accentColor,
            borderRadius: BorderRadius.circular(isDark ? 6 : 4),
            border: Border.all(
              color: widget.isFollowing ? borderColor : accentColor,
              width: 1,
            ),
          ),
          child: Text(
            widget.isFollowing ? 'UNFOLLOW' : 'FOLLOW',
            style: AppTextStyles.monoXs.copyWith(
              color: widget.isFollowing ? textColor : Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBack(String name, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final labelColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    final regNo = widget.user?['registrationNumber']?.toString();
    final bool isVerified = widget.user?['isVerified'] == true;
    final createdAtStr = widget.user?['createdAt']?.toString();
    String memberSince = 'Active';
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtStr);
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        memberSince = '${months[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }
    final rawHash = (name + (widget.user?['_id']?.toString() ?? 'GVIBE')).hashCode.abs();
    final sigHash = '0x${rawHash.toRadixString(16).padRight(12, '0').toUpperCase()}';

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0xFF5E6AD2).withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: labelColor, size: 14),
              const SizedBox(width: 6),
              Text(
                'Security Details',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                isVerified ? 'Verified' : 'Pending',
                style: AppTextStyles.monoXs.copyWith(
                  color: isVerified ? accentColor : labelColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 28,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF19201E) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(isDark ? 4 : 3),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Encrypted Security Track',
              style: AppTextStyles.monoXs.copyWith(color: labelColor, fontSize: 8),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _detailRow('Reg No:', (regNo != null && regNo.isNotEmpty) ? regNo : 'Pending'),
                      const SizedBox(height: 4),
                      _detailRow('Signature:', sigHash),
                      const SizedBox(height: 4),
                      _detailRow('Status:', isVerified ? 'Verified' : 'Pending'),
                      const SizedBox(height: 4),
                      _detailRow('Member Since:', memberSince),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildMockQRCode(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap card to flip',
              style: AppTextStyles.monoXs.copyWith(
                color: labelColor,
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockQRCode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDark ? 6 : 4),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(8, (r) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (c) {
              bool isCorner = (r < 3 && c < 3) || (r < 3 && c >= 5) || (r >= 5 && c < 3);
              bool isInnerCorner = (r == 1 && c == 1) || (r == 1 && c == 6) || (r == 6 && c == 1);
              bool isPixel = (isCorner && !isInnerCorner) || (!isCorner && ((r + c) % 3 == 0 || (r * c) % 2 == 0));
              return Container(
                width: 7,
                height: 7,
                color: isPixel ? Colors.black : Colors.white,
              );
            }),
          );
        }),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.onTap,
  });

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
          color: isDark ? const Color(0xFFE2E4E9) : const Color(0xFF171717),
          size: 20,
        ),
      ),
    );
  }
}
