import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_theme_extension.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';
import '../../core/providers/theme_provider.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: cs.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: AppTextStyles.bodyMd.copyWith(
                                    color: cs.error)),
                            const SizedBox(height: 16),
                            GVibeButton(
                                label: 'Retry',
                                onPressed: _loadProfile),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProfile,
                        color: AppColors.primary,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _DigitalStudentIDCard(
                              user: _user,
                              isOwnProfile: _isOwnProfile,
                              onEdit: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Profile editing coming soon'),
                                    backgroundColor: cs.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
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
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: cs.surface,
      child: Row(
        children: [
          GradientText(
            'GVibe',
            style: AppTextStyles.displaySm.copyWith(fontSize: 26),
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: cs.onSurface,
                    size: 20,
                  ),
                ),
              );
            },
          ),
          if (_isOwnProfile) ...[          
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.logout_rounded, color: cs.error, size: 15),
                  const SizedBox(width: 6),
                  Text('Logout', style: AppTextStyles.labelLg.copyWith(
                      color: cs.error, fontSize: 12)),
                ]),
              ),
            ),
          ] else ...[
            const SizedBox(width: 12),
            Icon(Icons.notifications_outlined, color: cs.onSurface, size: 22),
          ],
        ],
      ),
    );
  }

  Widget _buildUserBio() {
    final cs = Theme.of(context).colorScheme;
    final bio = _user?['bio']?.toString() ?? '';
    if (bio.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        bio,
        style: AppTextStyles.bodyMd.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('128', 'Posts', cs),
          const SizedBox(width: 10),
          _statCard(_formatCount(_followersCount), 'Followers', cs, onTap: () {
            final userId = widget.userId ?? _loggedInUserId;
            if (userId != null) context.push('/profile/$userId/followers');
          }),
          const SizedBox(width: 10),
          _statCard(_formatCount(_followingCount), 'Following', cs, onTap: () {
            final userId = widget.userId ?? _loggedInUserId;
            if (userId != null) context.push('/profile/$userId/following');
          }),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, ColorScheme cs,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: GVibeCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Text(value,
                  style: AppTextStyles.displaySm.copyWith(
                    color: cs.onSurface,
                    fontSize: 22,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: AppTextStyles.bodyXs.copyWith(
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final cs = Theme.of(context).colorScheme;
    final ext = context.ext;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ext.outline, width: 1),
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
                      color: isActive ? cs.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: AppTextStyles.label.copyWith(
                      color: isActive ? cs.primary : cs.onSurfaceVariant,
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
    if (line.contains('fn ') || line.contains('let ')) return AppColors.secondary;
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
          // CAMUI LIFE green tile
          _gridTile(
            AppColors.primary,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 36),
          const SizedBox(height: 12),
          Text('No $label yet',
              style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant)),
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
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceHigh : AppColors.lightSurfaceHigh,
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nfc, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'GVIBE STUDENT ID // FRONT_SIDE',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'GRID_ACTIVE',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.primary,
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
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: CutCornerAvatar(imageUrl: avatar, size: 76),
                    ),
                    Positioned(
                      bottom: -8,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: AppColors.primary,
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
                                color: AppColors.textPrimary,
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
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'RANK: $rank',
                    style: AppTextStyles.monoXs.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: AppColors.outline,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratingVal,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: AppTextStyles.monoXs.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.monoSm.copyWith(
              color: AppColors.textSecondary,
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
    if (widget.isOwnProfile) {
      return GestureDetector(
        onTap: widget.onEdit,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          child: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 14),
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onToggleFollow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isFollowing ? Colors.transparent : AppColors.accent,
            border: Border.all(
              color: widget.isFollowing ? AppColors.outline : AppColors.accent,
              width: 1,
            ),
          ),
          child: Text(
            widget.isFollowing ? 'UNFOLLOW' : 'FOLLOW',
            style: AppTextStyles.monoXs.copyWith(
              color: widget.isFollowing ? AppColors.textPrimary : AppColors.accentDark,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBack(String name, int level) {
    final sigHash = '0x${(name.hashCode.abs().toString() + 'FEED42').padRight(16, 'A').substring(0, 16).toUpperCase()}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceHigh : AppColors.lightSurfaceHigh,
        border: Border.all(color: AppColors.outline, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'GVIBE STUDENT ID // BACK_SIDE',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                'NODE_SECURE',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.primary,
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
            color: isDark ? const Color(0xFF19201E) : const Color(0xFFE1EAE7),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'MAGNETIC_DATA_TRACK_02_SECURED',
              style: AppTextStyles.monoXs.copyWith(color: AppColors.textMuted, fontSize: 8),
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
                color: AppColors.textMuted,
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
    return Container(
      width: 76,
      height: 76,
      color: Colors.white,
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
