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

  void _showShareDigitalPassPopup() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _user?['name']?.toString() ?? 'Student';
    final username = _user?['username']?.toString() ?? name.toLowerCase().replaceAll(' ', '_');
    final regNo = _user?['registrationNumber']?.toString();
    final hub = _user?['hub']?.toString() ?? 'GITAM Campus';
    final email = _user?['email']?.toString() ?? '$username@student.gitam.edu';
    final bool isVerified = _user?['isVerified'] == true;
    final displayRegNo = (regNo != null && regNo.isNotEmpty) ? regNo : 'Pending';

    final cardBg = isDark ? const Color(0xFF0D1412) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF182220) : const Color(0xFFC4E4E0);
    final labelColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final textColor = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);
    final tealColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
                  Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 16, color: tealColor),
                      const SizedBox(width: 8),
                      Text(
                        'CAMPUS PASS · ACCESS ID',
                        style: AppTextStyles.label.copyWith(
                          color: textColor,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Middle Row: Credential details + Mock QR
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _passField('Registration:', displayRegNo, labelColor, textColor),
                            const SizedBox(height: 8),
                            _passField('Student:', name, labelColor, textColor),
                            const SizedBox(height: 8),
                            _passField('Email:', email, labelColor, textColor),
                            const SizedBox(height: 8),
                            _passField('Campus Hub:', hub, labelColor, textColor),
                            const SizedBox(height: 8),
                            _passField(
                              'Account Status:',
                              isVerified ? 'Verified Student' : 'Standard Member',
                              labelColor,
                              isVerified ? tealColor : textColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _buildMockQRCode(username, isDark, borderColor),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 10),

                  // Footer
                  Center(
                    child: Text(
                      'Official GITAM Student Digital Pass',
                      style: AppTextStyles.bodyXs.copyWith(
                        color: labelColor,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Close Symbol ('X') Button at top-right
            Positioned(
              top: -12,
              right: -12,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131C1A) : const Color(0xFFEDF7F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: tealColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passField(String label, String value, Color labelColor, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.monoXs.copyWith(
            color: labelColor,
            fontSize: 9.5,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTextStyles.bodySm.copyWith(
            color: valueColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMockQRCode(String username, bool isDark, Color borderColor) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
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
                color: isPixel ? const Color(0xFF0F1012) : Colors.white,
              );
            }),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
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
                            _buildStudentIdentityHeader(),
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

  void _showProfileSettingsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1412) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF182220) : const Color(0xFFE0F0ED);
    final textColor = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);
    final mutedColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final dangerColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F3835) : const Color(0xFFB8DDD8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const BrandTitle(
              'Settings',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined, color: textColor, size: 22),
              title: Text(
                'Privacy Settings',
                style: AppTextStyles.bodyMd.copyWith(color: textColor, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Control profile visibility and messaging preferences',
                style: AppTextStyles.bodyXs.copyWith(color: mutedColor),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: mutedColor),
              onTap: () {
                Navigator.of(ctx).pop();
                _showPrivacySettingsDialog();
              },
            ),
            Divider(color: borderColor, height: 1),
            if (_isOwnProfile)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded, color: dangerColor, size: 22),
                title: Text(
                  'Log Out',
                  style: AppTextStyles.bodyMd.copyWith(color: dangerColor, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Sign out of your account on this device',
                  style: AppTextStyles.bodyXs.copyWith(color: mutedColor),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _logout();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoColor = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);

    return Container(
      padding: EdgeInsets.fromLTRB(_isOwnProfile ? 20 : 8, MediaQuery.of(context).padding.top + 12, 20, 10),
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
          const BrandTitle(
            'Profile',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          const Spacer(),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.menu_rounded,
            onTap: _showProfileSettingsMenu,
          ),
        ],
      ),
    );
  }

  String _getShortBranch(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'CSE';
    final upper = raw.toUpperCase().trim();
    if (upper.contains('COMPUTER') || upper.contains('CSE')) return 'CSE';
    if (upper.contains('COMMUNICATION') || upper.contains('ECE')) return 'ECE';
    if (upper.contains('MECHANICAL') || upper.contains('MECH')) return 'MECH';
    if (upper.contains('CIVIL')) return 'CIVIL';
    if (upper.contains('INFORMATION') || upper.contains('IT')) return 'IT';
    if (upper.contains('ELECTRICAL') || upper.contains('EEE')) return 'EEE';
    if (upper.contains('BIOTECH')) return 'BT';
    if (upper.contains('AERO')) return 'AERO';
    if (upper.contains('DATA SCIENCE')) return 'DS';
    if (upper.contains('AI')) return 'AI';
    if (raw.length <= 6) return raw.toUpperCase();
    return raw.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
  }

  Widget _buildStudentIdentityHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);
    final handleColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final bioColor = isDark ? const Color(0xFFC4D9D6) : const Color(0xFF2C4844);
    final tealColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    final btnBg = isDark ? const Color(0xFF131C1A) : const Color(0xFFEDF7F5);
    final btnBorder = isDark ? const Color(0xFF1A2E2B) : const Color(0xFFC4E4E0);

    final avatar = _user?['avatar']?.toString();
    final name = _user?['name']?.toString() ?? 'Student';
    final username = _user?['username']?.toString() ?? name.toLowerCase().replaceAll(' ', '_');
    final dept = _user?['branch']?.toString() ?? _user?['dept']?.toString() ?? 'CSE';
    final rawYear = _user?['academicLevel']?.toString() ?? _user?['year']?.toString() ?? '';
    final shortBranch = _getShortBranch(dept);
    final cleanYear = rawYear.replaceAll(RegExp(r'[^0-9]'), '');
    final yearSuffix = cleanYear.length >= 2 ? " '${cleanYear.substring(cleanYear.length - 2)}" : '';
    final branchDisplay = '$shortBranch$yearSuffix';

    final bio = _user?['bio']?.toString() ?? 'building things, breaking things 🛠️';
    final initials = name.trim().isNotEmpty
        ? (name.trim().split(' ').length > 1
            ? '${name.trim().split(' ')[0][0]}${name.trim().split(' ')[1][0]}'.toUpperCase()
            : name.trim().substring(0, name.trim().length.clamp(0, 2)).toUpperCase())
        : 'AG';

    // Interests
    final userInterests = (_user?['interests'] as List?)?.map((e) => e.toString()).toList() ??
        ['Technology', 'Coding', 'Art', 'Music', 'Coffee'];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Avatar: 78px with 2.5px teal border and 3px padding
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tealColor, width: 2.5),
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Container(
                    color: isDark ? const Color(0xFF131C1A) : const Color(0xFFEDF7F5),
                    child: avatar != null && avatar.isNotEmpty
                        ? Image.network(
                            avatar,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                initials,
                                style: AppTextStyles.headlineMd.copyWith(
                                  color: tealColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: AppTextStyles.headlineMd.copyWith(
                                color: tealColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Name (Space Grotesk 600, 20px)
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMd.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),

              // Handle + shortform branch: <username> · <shortformofbranch>
              Text(
                '@$username · $branchDisplay',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(
                  color: handleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),

              // Bio
              if (bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: bioColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16),

              // Stats Row: following | followers | posts
              _buildStatsRow(),
              const SizedBox(height: 16),

              // Action Buttons: edit profile & share profile
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Row(
                    children: [
                      if (_isOwnProfile) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Profile editing coming soon'),
                                  backgroundColor: tealColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: btnBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: btnBorder, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'edit profile',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showShareDigitalPassPopup,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: btnBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: btnBorder, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'share profile',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: _toggleFollow,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isFollowing ? btnBg : tealColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _isFollowing ? btnBorder : tealColor, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _isFollowing ? 'following' : 'follow',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: _isFollowing ? textColor : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final targetId = widget.userId;
                              if (targetId != null) context.push('/chat/$targetId');
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: btnBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: btnBorder, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'message',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tags (interests): box size based on text length, multiple per line in Wrap
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: userInterests.map((interest) {
                    return Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: tealColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tealColor.withValues(alpha: 0.40), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            interest,
                            style: AppTextStyles.bodyXs.copyWith(
                              color: tealColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numColor = isDark ? const Color(0xFFE8F4F2) : const Color(0xFF0C1F1D);
    final labelColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final dividerColor = isDark ? const Color(0xFF182220) : const Color(0xFFE0F0ED);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final userId = widget.userId ?? _loggedInUserId;
                  if (userId != null) context.push('/profile/$userId/following');
                },
                child: Column(
                  children: [
                    Text(
                      _formatCount(_followingCount),
                      style: AppTextStyles.headlineSm.copyWith(
                        color: numColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FOLLOWING',
                      style: AppTextStyles.monoXs.copyWith(
                        color: labelColor,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 32, color: dividerColor),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final userId = widget.userId ?? _loggedInUserId;
                  if (userId != null) context.push('/profile/$userId/followers');
                },
                child: Column(
                  children: [
                    Text(
                      _formatCount(_followersCount),
                      style: AppTextStyles.headlineSm.copyWith(
                        color: numColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'FOLLOWERS',
                      style: AppTextStyles.monoXs.copyWith(
                        color: labelColor,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 32, color: dividerColor),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _formatCount(_userPosts.length),
                    style: AppTextStyles.headlineSm.copyWith(
                      color: numColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'POSTS',
                    style: AppTextStyles.monoXs.copyWith(
                      color: labelColor,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E);
    final inactiveColor = isDark ? const Color(0xFF7A9E9A) : const Color(0xFF3D6B66);
    final borderColor = isDark ? const Color(0xFF182220) : const Color(0xFFE0F0ED);

    final tabs = ['posts', 'vibes', 'analytics'];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isActive = _activeTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? activeColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
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
    final name = widget.user?['name']?.toString() ?? 'Student';
    final username = widget.user?['username']?.toString() ?? name.toLowerCase().replaceAll(' ', '_');
    final dept = widget.user?['branch']?.toString() ?? widget.user?['dept']?.toString() ?? 'Student';
    final year = widget.user?['academicLevel']?.toString() ?? widget.user?['year']?.toString() ?? '1st Year';
    final regNo = widget.user?['registrationNumber']?.toString();
    final hub = widget.user?['hub']?.toString() ?? 'GITAM Campus';
    final email = widget.user?['email']?.toString() ?? '$username@student.gitam.edu';
    final bool isVerified = widget.user?['isVerified'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () => setState(() => _showFront = !_showFront),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _showFront ? 0 : 3.1415926535),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          builder: (context, val, child) {
            final isFront = val < 3.1415926535 / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(val),
              child: isFront
                  ? _buildFront(avatar, name, username, dept, year, regNo, hub, isVerified)
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.1415926535),
                      child: _buildBack(name, username, dept, regNo, hub, email, isVerified),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront(
    String? avatar,
    String name,
    String username,
    String dept,
    String year,
    String? regNo,
    String hub,
    bool isVerified,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF22242B) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF7F8F8) : const Color(0xFF171717);
    final labelColor = isDark ? const Color(0xFF8A8F98) : const Color(0xFF737373);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';
    final displayRegNo = (regNo != null && regNo.isNotEmpty) ? regNo : 'Pending';

    return Container(
      width: double.infinity,
      height: 235,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 14 : 12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF010102).withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: University credential & Verified Badge
          Row(
            children: [
              Icon(Icons.school_outlined, size: 14, color: labelColor),
              const SizedBox(width: 6),
              Text(
                'GITAM UNIVERSITY',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _buildVerificationBadge(isVerified, accentColor, isDark),
            ],
          ),
          const SizedBox(height: 14),

          // Middle Profile Section
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GVibeAvatar(
                  imageUrl: avatar,
                  size: 64,
                  initials: initials,
                  showGlow: isVerified,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: AppTextStyles.headlineMd.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 5),
                                  Icon(
                                    Icons.verified_rounded,
                                    color: accentColor,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildCardActionBtn(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: AppTextStyles.monoXs.copyWith(
                          color: labelColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Academic badges row
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _buildPill(dept, isDark),
                          _buildPill(year, isDark),
                          _buildPill(hub, isDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: borderColor, height: 16),

          // Bottom Bar: Roll number & Flip hint
          Row(
            children: [
              Text(
                'ROLL NO  ',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  displayRegNo,
                  style: AppTextStyles.monoSm.copyWith(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161820) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flip_camera_android_rounded, size: 12, color: labelColor),
                    const SizedBox(width: 4),
                    Text(
                      'Digital Pass',
                      style: AppTextStyles.monoXs.copyWith(
                        color: labelColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(
    String name,
    String username,
    String dept,
    String? regNo,
    String hub,
    String email,
    bool isVerified,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1012) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF22242B) : const Color(0xFFE5E7EB);
    final labelColor = isDark ? const Color(0xFF8A8F98) : const Color(0xFF737373);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final displayRegNo = (regNo != null && regNo.isNotEmpty) ? regNo : 'Pending';

    return Container(
      width: double.infinity,
      height: 235,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 14 : 12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF010102).withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 14, color: labelColor),
              const SizedBox(width: 6),
              Text(
                'CAMPUS PASS · ACCESS ID',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.flip_to_front_rounded, size: 12, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    'Front',
                    style: AppTextStyles.monoXs.copyWith(
                      color: accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Body: Credential details + QR pass
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _detailRow('Registration:', displayRegNo),
                      const SizedBox(height: 6),
                      _detailRow('Email:', email),
                      const SizedBox(height: 6),
                      _detailRow('Campus Hub:', hub),
                      const SizedBox(height: 6),
                      _detailRow('Account Status:', isVerified ? 'Verified Student' : 'Standard Member'),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _buildMockQRCode(username, isDark, borderColor),
              ],
            ),
          ),

          // Divider
          Divider(color: borderColor, height: 16),

          // Footer
          Center(
            child: Text(
              'Tap anywhere to flip card',
              style: AppTextStyles.monoXs.copyWith(
                color: labelColor.withValues(alpha: 0.7),
                fontSize: 9,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified, Color accentColor, bool isDark) {
    if (isVerified) {
      final greenColor = isDark ? const Color(0xFF27A644) : const Color(0xFF16A34A);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: greenColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: greenColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: greenColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'VERIFIED',
              style: AppTextStyles.monoXs.copyWith(
                color: greenColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'STUDENT PASS',
              style: AppTextStyles.monoXs.copyWith(
                color: accentColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPill(String text, bool isDark) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final borderColor = isDark ? const Color(0xFF22242B) : const Color(0xFFE5E7EB);
    final bg = isDark ? const Color(0xFF161820) : const Color(0xFFF9FAFB);
    final textColor = isDark ? const Color(0xFFD0D6E0) : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: AppTextStyles.monoXs.copyWith(
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF8A8F98) : const Color(0xFF737373);
    final valueColor = isDark ? const Color(0xFFF7F8F8) : const Color(0xFF171717);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.monoXs.copyWith(
            color: labelColor,
            fontSize: 9,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTextStyles.monoSm.copyWith(
            color: valueColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCardActionBtn() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF22242B) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF7F8F8) : const Color(0xFF171717);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    if (widget.isOwnProfile) {
      return GestureDetector(
        onTap: widget.onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isDark ? 6 : 4),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: textColor, size: 13),
              const SizedBox(width: 4),
              Text(
                'Edit',
                style: AppTextStyles.label.copyWith(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onToggleFollow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isFollowing ? Colors.transparent : accentColor,
            borderRadius: BorderRadius.circular(isDark ? 6 : 4),
            border: Border.all(
              color: widget.isFollowing ? borderColor : accentColor,
              width: 1,
            ),
          ),
          child: Text(
            widget.isFollowing ? 'Following' : 'Follow',
            style: AppTextStyles.label.copyWith(
              color: widget.isFollowing ? textColor : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMockQRCode(String username, bool isDark, Color borderColor) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
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
                color: isPixel ? const Color(0xFF0F1012) : Colors.white,
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
