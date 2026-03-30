import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _tab = 0; // 0 = DIRECT, 1 = COMMUNITIES
  List<dynamic> _communities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.get('/messages/communities');
      if (response.data['success'] == true) {
        setState(() {
          _communities = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load messages';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Column(
          children: [
            // App bar with avatar
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              child: Row(
                children: [
                  // Hamburger
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 24, height: 2, color: AppColors.textPrimary),
                      const SizedBox(height: 5),
                      Container(width: 20, height: 2, color: AppColors.textPrimary),
                      const SizedBox(height: 5),
                      Container(width: 24, height: 2, color: AppColors.textPrimary),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'GVIBE',
                    style: AppTextStyles.displaySm.copyWith(
                        color: AppColors.accent, fontStyle: FontStyle.italic),
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary, size: 22),
                  const SizedBox(width: 12),
                  CutCornerAvatar(size: 36),
                ],
              ),
            ),
            // DIRECT / COMMUNITIES tab bar
            Container(
              color: AppColors.background,
              child: Row(
                children: [
                  _buildTabItem('DIRECT', 0),
                  _buildTabItem('COMMUNITIES', 1),
                ],
              ),
            ),
            // Content
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
                              GVibeButton(label: 'RETRY', onPressed: _fetchData),
                            ],
                          ),
                        )
                      : _tab == 0
                          ? _buildDirectTab()
                          : _buildCommunitiesTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppColors.accent, size: 48),
            const SizedBox(height: 16),
            Text('NO DIRECT MESSAGES YET',
                style: AppTextStyles.displaySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Discover people and start a conversation!',
                style: AppTextStyles.monoSm.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitiesTab() {
    if (_communities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_outlined, color: AppColors.accent, size: 48),
              const SizedBox(height: 16),
              Text('NO COMMUNITIES',
                  style: AppTextStyles.displaySm.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Join or create a community!',
                  style: AppTextStyles.monoSm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _communities.length,
      itemBuilder: (context, index) {
        final c = _communities[index];
        return _buildCommunityRow(c);
      },
    );
  }

  Widget _buildCommunityRow(Map<String, dynamic> community) {
    final name = community['name']?.toString().toUpperCase() ?? 'COMMUNITY';
    final description = community['description']?.toString() ?? '';
    final memberCount = (community['members'] as List?)?.length ?? 0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Container(
            width: 52,
            height: 52,
            color: AppColors.surfaceHigh,
            child: const Icon(Icons.group,
                color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.monoMd
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  description.isNotEmpty ? description : '$memberCount members',
                  style: AppTextStyles.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text('$memberCount',
              style: AppTextStyles.monoXs.copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isActive = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          border: isActive
              ? null
              : const Border(
                  right: BorderSide(color: AppColors.outline, width: 0.5)),
        ),
        child: Text(
          label,
          style: AppTextStyles.monoMd.copyWith(
            color: isActive ? AppColors.accentDark : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
