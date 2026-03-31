import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<dynamic> _followers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ApiService().dio.get('/users/${widget.userId}/followers');
      if (response.data['success'] == true) {
        setState(() {
          _followers = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load followers';
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
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
              color: AppColors.background,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'FOLLOWERS',
                    style: AppTextStyles.displaySm.copyWith(
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_followers.length}',
                    style: AppTextStyles.monoMd
                        .copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
            // Divider
            Container(height: 1, color: AppColors.outline),
            // List
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
                                  onPressed: _fetchFollowers),
                            ],
                          ),
                        )
                      : _followers.isEmpty
                          ? Center(
                              child: Text('NO FOLLOWERS YET',
                                  style: AppTextStyles.monoMd.copyWith(
                                      color: AppColors.textMuted)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _followers.length,
                              separatorBuilder: (_, __) =>
                                  Container(height: 1, color: AppColors.outline),
                              itemBuilder: (context, index) {
                                final user = _followers[index];
                                return _FollowUserTile(user: user);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _FollowUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name']?.toString().toUpperCase() ?? 'USER';
    final bio = user['bio']?.toString() ?? '';
    final avatar = user['avatar']?.toString();
    final userId = user['_id']?.toString() ?? '';
    final level = user['level'] ?? 1;

    return GestureDetector(
      onTap: () {
        if (userId.isNotEmpty) {
          context.push('/profile/$userId');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: CutCornerAvatar(imageUrl: avatar, size: 48),
                ),
                Positioned(
                  bottom: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: AppColors.pink,
                      child: Text(
                        'LV$level',
                        style: AppTextStyles.monoXs.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 8,
                        ),
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
                children: [
                  Text(name,
                      style: AppTextStyles.monoLg
                          .copyWith(fontSize: 14)),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: AppTextStyles.bodySm.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
