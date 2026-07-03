import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/providers/theme_provider.dart';

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

  final List<String> _tabs = ['POSTS', 'VIBES', 'DIRECT', 'COMMUNIT'];

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

      if (targetId == null || targetId == _loggedInUserId) {
        _isOwnProfile = true;
        final response = await ApiService().dio.get('/users/profile');
        if (response.data['success'] == true) {
          final data = response.data['data'];
          setState(() {
            _user = data;
            _followersCount = (data['followers'] as List?)?.length ?? 0;
            _followingCount = (data['following'] as List?)?.length ?? 0;
            _loading = false;
          });
        }
      } else {
        _isOwnProfile = false;
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
    } on DioException catch (e) {
      setState(() {
        _error = ApiService.getErrorMessage(e);
        _loading = false;
      });
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
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Text(
            'GVibe',
            style: AppTextStyles.displaySm.copyWith(
              color: logoColor,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              letterSpacing: isDark ? -0.8 : -1.2,
            ),
          ),
          const Spacer(),
          _IconButton(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          if (_isOwnProfile) ...[          
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          _statCard('128', 'Posts'),
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
        return _buildEmptyTab('DIRECT', Icons.chat_bubble_outline);
      case 3:
        return _buildEmptyTab('COMMUNITY', Icons.group_outlined);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPostsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCodeSnippetCard(),
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildCodeSnippetCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final editorBg = isDark ? const Color(0xFF070809) : const Color(0xFFF9F9FB);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final labelColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code editor header with colored dots
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: editorBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isDark ? 8 : 6),
                topRight: Radius.circular(isDark ? 8 : 6),
              ),
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Window dots + close
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5F56), // red dot
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFBD2E), // yellow dot
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF27C93F), // green dot
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.close_rounded, color: labelColor, size: 14),
                  ],
                ),
                const SizedBox(height: 12),
                // Code title
                Text(
                  'CODE_TOTEM_HOME_01_+_FREQUENCY/FUNC&RESULT',
                  style: AppTextStyles.monoXs.copyWith(
                    color: labelColor,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Code lines
                ..._buildCodeLines(),
              ],
            ),
          ),
          // FEATURED badge + title
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isDark ? 4 : 999),
                    border: Border.all(color: accentColor, width: 1.2),
                  ),
                  child: Text(
                    'FEATURED',
                    style: AppTextStyles.monoXs.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SYSTEM OVERRIDE V.01',
                  style: AppTextStyles.displaySm.copyWith(
                    fontSize: 22,
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCodeLines() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF4C566A) : const Color(0xFF9E9E9E);
    
    final lines = [
      '  fn main() {',
      '    let system = Engine::new();',
      '    system.override(Config {',
      '      mode: "gitam-green",',
      '      freq: 42.0,',
      '    });',
      '    system.run();',
      '  }',
    ];
    return lines.asMap().entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${e.key + 1}',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Text(
                e.value,
                style: AppTextStyles.monoXs.copyWith(
                  color: _codeLineColor(e.value),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _codeLineColor(String line) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (line.contains('fn ') || line.contains('let ')) {
      return isDark ? const Color(0xFFB48EAD) : const Color(0xFF800080);
    }
    if (line.contains('"')) {
      return isDark ? const Color(0xFFA3BE8C) : const Color(0xFF032F62);
    }
    if (line.contains('42')) {
      return isDark ? const Color(0xFF88C0D0) : const Color(0xFF005CC5);
    }
    return isDark ? const Color(0xFFD8DEE9) : const Color(0xFF24292E);
  }

  Widget _buildImageGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final tileColor = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _gridTile(tileColor, 180, icon: Icons.person_outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _gridTile(tileColor, 180, icon: Icons.radio),
              ),
            ],
          ),
          const SizedBox(width: 8, height: 8),
          Row(
            children: [
              Expanded(
                child: _gridTile(tileColor, 180, icon: Icons.water_drop_outlined),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _gridTile(tileColor, 180, icon: Icons.waves),
              ),
            ],
          ),
          const SizedBox(width: 8, height: 8),
          // CAMPUS LIFE accent tile
          _gridTile(
            primaryColor,
            200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CAMPUS',
                  style: AppTextStyles.monoLg.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'LIFE',
                  style: AppTextStyles.displayLg.copyWith(
                    color: Colors.white,
                    fontSize: 52,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _gridTile(Color color, double height, {IconData? icon, Widget? child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final iconColor = isDark ? const Color(0xFF4C566A) : const Color(0xFF9E9E9E);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isDark ? 8 : 6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child ??
          Center(
            child: icon != null
                ? Icon(
                    icon,
                    color: iconColor.withValues(alpha: 0.4),
                    size: 32,
                  )
                : null,
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
    super.key,
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
    final level = widget.user?['level'] ?? 42;
    final name = widget.user?['name']?.toString().toUpperCase().replaceAll(' ', '_') ?? 'USER_NAME';
    final dept = widget.user?['dept']?.toString().toUpperCase() ?? 'COMPUTER_SCIENCE';
    final year = widget.user?['year']?.toString() ?? '2024';
    final hub = widget.user?['hub']?.toString().toUpperCase() ?? 'ENGINEERING_QUAD';

    // Vibe rating calculations
    final double ratingVal = 0.85 + ((level * 3) % 15) / 100.0;
    final ratingPercent = (ratingVal * 100).toStringAsFixed(1);
    
    String rank = 'ARCHMAGE';
    if (level < 10) {
      rank = 'INITIATE';
    } else if (level < 25) {
      rank = 'ACOLYTE';
    } else if (level < 40) {
      rank = 'WIZARD';
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
                  ? _buildFront(avatar, level, name, dept, year, hub, ratingVal, ratingPercent, rank)
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
                'GVIBE STUDENT ID // FRONT_SIDE',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 8,
                  letterSpacing: 1.0,
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
                'GRID_ACTIVE',
                style: AppTextStyles.monoXs.copyWith(
                  color: accentColor,
                  fontSize: 8,
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
                          'LVL_$level',
                          style: AppTextStyles.monoXs.copyWith(
                            color: Colors.white,
                            fontSize: 8,
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
                              '@$name',
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
                      const SizedBox(height: 6),
                      _detailRow('MAJOR:', dept),
                      const SizedBox(height: 3),
                      _detailRow('CLASS:', year),
                      const SizedBox(height: 3),
                      _detailRow('STATUS:', '📍 $hub'),
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
                    'VIBE_RATING: $ratingPercent%',
                    style: AppTextStyles.monoXs.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RANK: $rank',
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
    final sigHash = '0x${('${name.hashCode.abs()}FEED42').padRight(16, 'A').substring(0, 16).toUpperCase()}';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F1011) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
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
              Icon(Icons.security, color: labelColor, size: 14),
              const SizedBox(width: 6),
              Text(
                'GVIBE STUDENT ID // BACK_SIDE',
                style: AppTextStyles.monoXs.copyWith(
                  color: labelColor,
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                'NODE_SECURE',
                style: AppTextStyles.monoXs.copyWith(
                  color: accentColor,
                  fontSize: 8,
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
              'MAGNETIC_DATA_TRACK_02_SECURED',
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
                      _detailRow('SIGNATURE:', sigHash),
                      const SizedBox(height: 4),
                      _detailRow('CIPHER:', 'AES_256_GCM'),
                      const SizedBox(height: 4),
                      _detailRow('VERIFY:', 'APPROVED'),
                      const SizedBox(height: 4),
                      _detailRow('EXPIRES:', '31_DEC_2026'),
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
              'TAP CARD TO FLIP FRONT',
              style: AppTextStyles.monoXs.copyWith(
                color: labelColor,
                fontSize: 8,
                letterSpacing: 1.5,
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
