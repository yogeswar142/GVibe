import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeTab = 0;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  bool _isOwnProfile = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  String? _loggedInUserId;

  final List<String> _tabs = ['POSTS', 'VIBES', 'DIRECT', 'COMMUNITY'];

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
      // Get the logged-in user's data to check ownership
      final cachedUser = await AuthService.getUser();
      _loggedInUserId = cachedUser?['_id']?.toString();

      final targetId = widget.userId;

      if (targetId == null || targetId == _loggedInUserId) {
        // Fetch own profile
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
        // Fetch another user's profile
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
        _error = e.response?.data?['message'] ?? 'Failed to load profile';
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
    } on DioException catch (_) {
      // silently fail – could add snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!,
                                  style: AppTextStyles.monoMd
                                      .copyWith(color: AppColors.pink)),
                              const SizedBox(height: 16),
                              GVibeButton(
                                  label: 'RETRY',
                                  onPressed: _loadProfile),
                            ],
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildAvatarSection(),
                            _buildUserInfo(),
                            _buildStatsGrid(),
                            _buildTabBar(),
                            _buildTabContent(),
                          ],
                        ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      color: AppColors.background,
      child: Row(
        children: [
          // Hamburger menu
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 24, height: 2, color: AppColors.textPrimary),
                const SizedBox(height: 5),
                Container(width: 18, height: 2, color: AppColors.textPrimary),
                const SizedBox(height: 5),
                Container(width: 24, height: 2, color: AppColors.textPrimary),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'GVIBE',
            style: AppTextStyles.displaySm.copyWith(
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary, size: 22),
        ],
      ),
    );
  }

  // ─── AVATAR SECTION ──────────────────────────────────────
  Widget _buildAvatarSection() {
    final avatar = _user?['avatar']?.toString();
    final level = _user?['level'] ?? 1;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with level badge
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Neon border container
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: CutCornerAvatar(imageUrl: avatar, size: 110),
                  ),
                  // LVL badge
                  Positioned(
                    bottom: -14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        color: AppColors.pink,
                        child: Text(
                          'LVL_$level',
                          style: AppTextStyles.monoXs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Edit pencil icon OR follow button
          if (_isOwnProfile)
            GestureDetector(
              onTap: () {
                // TODO: navigate to edit profile
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  border: Border.all(color: AppColors.outline, width: 1),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary, size: 18),
              ),
            )
          else
            GestureDetector(
              onTap: _toggleFollow,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      _isFollowing ? Colors.transparent : AppColors.accent,
                  border: Border.all(
                    color: _isFollowing
                        ? AppColors.textSecondary
                        : AppColors.accent,
                    width: 1,
                  ),
                ),
                child: Text(
                  _isFollowing ? 'UNFOLLOW' : 'FOLLOW',
                  style: AppTextStyles.monoSm.copyWith(
                    color: _isFollowing
                        ? AppColors.textPrimary
                        : AppColors.accentDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── USER INFO ───────────────────────────────────────────
  Widget _buildUserInfo() {
    final name =
        _user?['name']?.toString().toUpperCase() ?? 'USER_NAME';
    final dept = _user?['dept']?.toString().toUpperCase() ?? '';
    final year = _user?['year']?.toString() ?? '';
    final bio = _user?['bio']?.toString() ?? '';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER_NAME — massive display
          Text(
            name,
            style: AppTextStyles.displayLg.copyWith(
              fontSize: 42,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          // BRANCH / YEAR row
          Row(
            children: [
              if (dept.isNotEmpty) ...[
                Text('BRANCH:',
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 4),
              ],
              if (dept.isNotEmpty)
                Text(dept,
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textPrimary)),
              if (dept.isNotEmpty && year.isNotEmpty) ...[
                const SizedBox(width: 16),
                Text('/',
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 16),
              ],
              if (year.isNotEmpty) ...[
                Text('YEAR:',
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Text(year,
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: AppTextStyles.bodyMd.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── STATS GRID ──────────────────────────────────────────
  Widget _buildStatsGrid() {
    final userId = widget.userId ?? _loggedInUserId;
    final connections = _followersCount + _followingCount;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatBox('128', 'POSTS'),
              const SizedBox(width: 8),
              _buildStatBox(
                _formatCount(_followersCount + _followingCount),
                'VIBES',
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              if (userId != null) {
                context.push('/profile/$userId/followers');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCount(connections),
                    style: AppTextStyles.displaySm.copyWith(
                      fontSize: 28,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text('CONNECTIONS', style: AppTextStyles.monoXs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTextStyles.displaySm.copyWith(
                    fontSize: 28, color: AppColors.textPrimary)),
            Text(label, style: AppTextStyles.monoXs),
          ],
        ),
      ),
    );
  }

  // ─── TAB BAR ─────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outline, width: 1),
          ),
        ),
        child: Row(
          children: _tabs.asMap().entries.map((e) {
            final isActive = e.key == _activeTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: AppTextStyles.monoSm.copyWith(
                        color: isActive
                            ? AppColors.accentDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── TAB CONTENT ─────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildPostsTab();
      case 1:
        return _buildEmptyTab('VIBES');
      case 2:
        return _buildEmptyTab('DIRECT');
      case 3:
        return _buildEmptyTab('COMMUNITY');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPostsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured post card — code snippet style
        _buildFeaturedPost(),
        // Image grid
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildFeaturedPost() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code snippet area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0D0D14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title bar dots
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.pink, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle)),
                    const Spacer(),
                    Icon(Icons.close,
                        color: AppColors.textMuted, size: 14),
                  ],
                ),
                const SizedBox(height: 12),
                // Code lines
                ..._buildCodeLines(),
              ],
            ),
          ),
          // Featured label + title
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: Text(
                    'FEATURED',
                    style: AppTextStyles.monoXs.copyWith(
                      color: AppColors.accent,
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
    final lines = [
      '  fn main() {',
      '    let system = Engine::new();',
      '    system.override(Config {',
      '      mode: "neo-brutal",',
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
                  color: AppColors.textMuted,
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
    if (line.contains('fn ') || line.contains('let ')) {
      return AppColors.pink;
    }
    if (line.contains('"')) return AppColors.accent;
    if (line.contains('42')) return const Color(0xFF80BFFF);
    return AppColors.textSecondary;
  }

  Widget _buildImageGrid() {
    // Placeholder grid images using colored containers
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _gridTile(const Color(0xFF1A1A28), 180,
                    icon: Icons.person_outline),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _gridTile(const Color(0xFF1C1C1C), 180,
                    icon: Icons.radio),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _gridTile(const Color(0xFF181820), 180,
                    icon: Icons.water_drop_outlined),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _gridTile(const Color(0xFF151518), 180,
                    icon: Icons.waves),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _gridTile(
            AppColors.pink,
            200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CAMUI',
                    style: AppTextStyles.monoLg.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 3)),
                Text('LIFE',
                    style: AppTextStyles.displayLg.copyWith(
                        color: Colors.white, fontSize: 52, height: 1.0)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _gridTile(Color color, double height,
      {IconData? icon, Widget? child}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: child ??
          Center(
            child: icon != null
                ? Icon(icon, color: AppColors.textMuted, size: 32)
                : null,
          ),
    );
  }

  Widget _buildEmptyTab(String label) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text('NO ${label.toUpperCase()} YET',
          style:
              AppTextStyles.monoMd.copyWith(color: AppColors.textMuted)),
    );
  }

  // ─── BOTTOM NAV ──────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          _bottomNavItem(Icons.grid_view, 'POSTS', 0),
          _bottomNavItem(Icons.bolt, 'VIBES', 1),
          _bottomNavItem(Icons.chat_bubble_outline, 'DIRECT', 2),
          _bottomNavItem(Icons.group_outlined, 'CREW', 3),
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigate to home with tab index if needed
          context.go(AppRouter.home);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.monoXs.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
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
