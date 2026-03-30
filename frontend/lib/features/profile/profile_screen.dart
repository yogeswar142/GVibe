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
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeTab = 0;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.get('/users/profile');
      if (response.data['success'] == true) {
        setState(() {
          _user = response.data['data'];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load profile';
        _loading = false;
      });
    }
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
            // App bar area
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'GVIBE',
                    style: AppTextStyles.displaySm.copyWith(
                        color: AppColors.accent.withOpacity(0.4),
                        fontStyle: FontStyle.italic),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _logout,
                    child: Text('LOGOUT',
                        style: AppTextStyles.monoXs.copyWith(color: AppColors.pink)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: AppTextStyles.monoMd.copyWith(color: AppColors.pink)),
                              const SizedBox(height: 16),
                              GVibeButton(label: 'RETRY', onPressed: _fetchProfile),
                            ],
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildProfileHeader(),
                            _buildStats(),
                            _buildTabBar(),
                            _buildTabContent(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _user?['name']?.toString().toUpperCase() ?? 'USER';
    final dept = _user?['dept']?.toString().toUpperCase() ?? '';
    final year = _user?['year']?.toString() ?? '';
    final bio = _user?['bio']?.toString() ?? '';
    final avatar = _user?['avatar']?.toString();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CutCornerAvatar(imageUrl: avatar, size: 80),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                color: AppColors.surfaceHigh,
                child: const Icon(Icons.edit,
                    color: AppColors.textSecondary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: AppTextStyles.displayMd),
          const SizedBox(height: 4),
          Row(
            children: [
              if (dept.isNotEmpty) ...[
                Text('BRANCH:',
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(dept,
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(width: 16),
                Text('/',
                    style:
                        AppTextStyles.monoSm.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 16),
              ],
              if (year.isNotEmpty) ...[
                Text('YEAR:',
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Text(year,
                    style: AppTextStyles.monoSm
                        .copyWith(color: AppColors.textPrimary)),
              ],
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(bio, style: AppTextStyles.bodyMd.copyWith(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatBox(value: '0', label: 'POSTS'),
              const SizedBox(width: 8),
              _StatBox(value: '0', label: 'VIBES'),
            ],
          ),
          const SizedBox(height: 8),
          _StatBox(value: '0', label: 'CONNECTIONS', wide: true),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['POSTS', 'VIBES', 'ABOUT'];
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final isActive = e.key == _activeTab;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.accent : Colors.transparent,
                ),
                child: Text(
                  e.value,
                  style: AppTextStyles.monoSm.copyWith(
                    color: isActive ? AppColors.accentDark : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_activeTab == 2) return _buildAboutContent();
    return _buildEmptyContent();
  }

  Widget _buildAboutContent() {
    final email = _user?['email']?.toString() ?? '';
    final createdAt = _user?['createdAt']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'EMAIL', value: email),
          if (createdAt.isNotEmpty)
            _InfoRow(label: 'JOINED', value: createdAt.substring(0, 10)),
        ],
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text('NO CONTENT YET',
          style: AppTextStyles.monoMd.copyWith(color: AppColors.textMuted)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.monoXs.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.monoSm.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final bool wide;

  const _StatBox({
    required this.value,
    required this.label,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: wide ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          border: Border.all(color: AppColors.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTextStyles.displaySm
                    .copyWith(fontSize: 28, color: AppColors.textPrimary)),
            Text(label, style: AppTextStyles.monoXs),
          ],
        ),
      ),
    );
  }
}
