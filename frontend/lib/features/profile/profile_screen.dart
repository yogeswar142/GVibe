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
    } on DioException catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) context.go(AppRouter.login);
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
                      child: CircularProgressIndicator(color: AppColors.accent))
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
                                  label: 'RETRY', onPressed: _loadProfile),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProfile,
                          color: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          child: ListView(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: AppColors.background,
      child: Row(
        children: [
          Text(
            'GVIBE',
            style: AppTextStyles.displaySm.copyWith(
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (_isOwnProfile)
            GestureDetector(
              onTap: _logout,
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.textPrimary, size: 22),
            )
          else
            const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 22),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final avatar = _user?['avatar']?.toString();
    final level = _user?['level'] ?? 42;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with LVL badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: CutCornerAvatar(imageUrl: avatar, size: 100),
              ),
              Positioned(
                bottom: -10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  color: AppColors.pink,
                  child: Text(
                    'LVL_$level',
                    style: AppTextStyles.monoXs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Edit or Follow button
          if (_isOwnProfile)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary, size: 18),
            )
          else
            GestureDetector(
              onTap: _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
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

  Widget _buildUserInfo() {
    final name = _user?['name']?.toString().toUpperCase().replaceAll(' ', '_') ??
        'USER_NAME';
    final dept = _user?['dept']?.toString().toUpperCase() ?? 'DESIGN_LAB';
    final year = _user?['year']?.toString() ?? '2024';
    final bio = _user?['bio']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.displayXl.copyWith(
              fontSize: 42,
              letterSpacing: -1,
              height: 1.0,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'BRANCH:',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                dept,
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                '/',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'YEAR:',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                year,
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              bio,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final connections = _followersCount + _followingCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _statBox('128', 'POSTS'),
              const SizedBox(width: 8),
              _statBox(_formatCount(_followersCount + _followingCount), 'VIBES'),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              final userId = widget.userId ?? _loggedInUserId;
              if (userId != null) context.push('/profile/$userId/followers');
            },
            child: _statBox(_formatCount(connections), 'CONNECTIONS',
                isWide: true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, {bool isWide = false}) {
    final widget = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.displaySm.copyWith(
              fontSize: 28,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.monoXs),
        ],
      ),
    );

    return isWide ? widget : Expanded(child: widget);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: AppTextStyles.monoXs.copyWith(
                      color: isActive
                          ? AppColors.accentDark
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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

  // Featured code snippet card — matches profile.png exactly
  Widget _buildCodeSnippetCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code editor header with colored dots
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0D0D14),
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
                            color: AppColors.pink, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle)),
                    const Spacer(),
                    Icon(Icons.close, color: AppColors.textMuted, size: 12),
                  ],
                ),
                const SizedBox(height: 12),
                // Code title
                Text(
                  'CODE_TOTEM_HOME_01_+_FREQUENCY/FUNC&RESULT',
                  style: AppTextStyles.monoXs.copyWith(
                    color: AppColors.textMuted,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
                  style: AppTextStyles.displaySm.copyWith(fontSize: 22),
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
    if (line.contains('fn ') || line.contains('let ')) return AppColors.pink;
    if (line.contains('"')) return AppColors.accent;
    if (line.contains('42')) return const Color(0xFF80BFFF);
    return AppColors.textSecondary;
  }

  // Image grid matching profile.png — 2x2 + wide CAMPUS LIFE tile
  Widget _buildImageGrid() {
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
          // CAMUI LIFE pink tile
          _gridTile(
            AppColors.pink,
            200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CAMUI',
                    style: AppTextStyles.monoLg.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 3)),
                Text('LIFE',
                    style: AppTextStyles.displayLg.copyWith(
                        color: Colors.white,
                        fontSize: 52,
                        height: 1.0)),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                ? Icon(icon,
                    color: AppColors.textMuted.withValues(alpha: 0.3), size: 32)
                : null,
          ),
    );
  }

  Widget _buildEmptyTab(String label, IconData icon) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 12),
          Text('NO ${label.toUpperCase()} YET',
              style: AppTextStyles.monoMd
                  .copyWith(color: AppColors.textMuted)),
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
