import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().dio.get('/users');
      if (response.data['success'] == true) {
        setState(() {
          _users = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Column(
          children: [
            // Top bar
            Container(
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
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary, size: 22),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      color: AppColors.accent,
                      backgroundColor: AppColors.surface,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildTrendingCommunities(),
                          _buildPeopleSection(),
                          _buildHotVibesSection(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // TRENDING COMMUNITIES — horizontal scroller
  Widget _buildTrendingCommunities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Container(width: 3, height: 24, color: AppColors.accent),
              const SizedBox(width: 12),
              Text(
                'TRENDING COMMUNITIES',
                style: AppTextStyles.displaySm.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _communityCard('TECHNO_NIGHTS', 'THE_VOID_RAVE', '12.4K MEMBERS',
                  const Color(0xFF1A1A28)),
              const SizedBox(width: 12),
              _communityCard('DESIGN_LAB', 'PIXEL_COLLECTIVE', '8.2K MEMBERS',
                  const Color(0xFF181820)),
              const SizedBox(width: 12),
              _communityCard('CODE_CREW', 'HACK_SPACE', '5.1K MEMBERS',
                  const Color(0xFF151518)),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _communityCard(
      String tag, String name, String members, Color bg) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          // Placeholder image area
          Positioned.fill(
            child: Container(
              color: bg,
              child: Center(
                child: Icon(Icons.group_outlined,
                    color: AppColors.textMuted.withValues(alpha: 0.3), size: 48),
              ),
            ),
          ),
          // Bottom overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background.withValues(alpha: 0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: AppColors.accent,
                    child: Text(
                      tag,
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: AppTextStyles.displaySm.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    members,
                    style: AppTextStyles.monoXs.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PEOPLE YOU MAY KNOW
  Widget _buildPeopleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(width: 3, height: 24, color: AppColors.accent),
              const SizedBox(width: 12),
              Text(
                'PEOPLE YOU MAY KNOW',
                style: AppTextStyles.displaySm.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ..._users.take(5).map((user) => _PersonRow(user: user)),
        if (_users.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'NO USERS FOUND',
                style: AppTextStyles.monoMd.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
      ],
    );
  }

  // HOT VIBES TODAY — 2x2 grid
  Widget _buildHotVibesSection() {
    final vibes = [
      {'handle': '@URBAN_EXPLORE', 'file': 'CITY_GLOW.JPG'},
      {'handle': '@MOTION_FREEZE', 'file': 'RHYTHM_STUDY.MOV'},
      {'handle': '@SYNTH_FACE', 'file': 'VISION_QUEST.PNG'},
      {'handle': '@ERROR_CORE', 'file': 'SYSTEM_FAILURE.UI'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(width: 3, height: 24, color: AppColors.accent),
              const SizedBox(width: 12),
              Text(
                'HOT VIBES TODAY',
                style: AppTextStyles.displaySm.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _hotVibeTile(vibes[0], const Color(0xFF1A1A28))),
                  const SizedBox(width: 4),
                  Expanded(child: _hotVibeTile(vibes[1], const Color(0xFF181820))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: _hotVibeTile(vibes[2], const Color(0xFF151518))),
                  const SizedBox(width: 4),
                  Expanded(child: _hotVibeTile(vibes[3], const Color(0xFF1A1A24))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hotVibeTile(Map<String, String> data, Color bg) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          Center(
              child: Icon(Icons.image_outlined,
                  color: AppColors.textMuted.withValues(alpha: 0.2), size: 32)),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.pink,
                  child: Text(
                    data['handle']!,
                    style: AppTextStyles.monoXs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['file']!,
                  style: AppTextStyles.monoSm.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// PERSON ROW — with CONNECT button
class _PersonRow extends StatefulWidget {
  final Map<String, dynamic> user;
  const _PersonRow({required this.user});

  @override
  State<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<_PersonRow> {
  bool _connected = false;

  @override
  Widget build(BuildContext context) {
    final name =
        widget.user['name']?.toString().toUpperCase().replaceAll(' ', '_') ?? 'USER';
    final dept = widget.user['dept']?.toString().toUpperCase() ?? 'CAMPUS';
    final avatar = widget.user['avatar']?.toString();
    final userId = widget.user['_id']?.toString() ?? '';
    final mutuals = (widget.user['mutuals'] ?? 14).toString();

    return GestureDetector(
      onTap: () {
        if (userId.isNotEmpty) context.push('/profile/$userId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outline, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              child: CutCornerAvatar(imageUrl: avatar, size: 48),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.monoLg.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dept • $mutuals MUTUALS',
                    style: AppTextStyles.monoXs.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (userId.isEmpty) return;
                try {
                  await ApiService().dio.post('/users/$userId/follow');
                  setState(() => _connected = !_connected);
                } catch (_) {}
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _connected ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: _connected ? AppColors.accent : AppColors.accent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_connected) ...[
                      Text(
                        '+',
                        style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _connected ? 'CONNECTED' : 'CONNECT',
                      style: AppTextStyles.monoXs.copyWith(
                        color: _connected
                            ? AppColors.accentDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
