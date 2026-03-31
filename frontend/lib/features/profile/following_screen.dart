import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<dynamic> _following = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ApiService().dio.get('/users/${widget.userId}/following');
      if (response.data['success'] == true) {
        setState(() {
          _following = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load following';
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
                    'FOLLOWING',
                    style: AppTextStyles.displaySm.copyWith(
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    color: AppColors.accent.withOpacity(0.1),
                    child: Text(
                      '${_following.length}',
                      style: AppTextStyles.monoMd
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.outline),
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
                                  onPressed: _fetchFollowing),
                            ],
                          ),
                        )
                      : _following.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline,
                                      color: AppColors.textMuted,
                                      size: 40),
                                  const SizedBox(height: 16),
                                  Text('NOT FOLLOWING ANYONE',
                                      style: AppTextStyles.monoMd.copyWith(
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchFollowing,
                              color: AppColors.accent,
                              backgroundColor: AppColors.surface,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _following.length,
                                separatorBuilder: (_, __) =>
                                    Container(
                                        height: 1,
                                        color: AppColors.outline),
                                itemBuilder: (context, index) {
                                  final user = _following[index];
                                  return _FollowUserTile(user: user);
                                },
                              ),
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
                    border:
                        Border.all(color: AppColors.accent, width: 1),
                  ),
                  child:
                      CutCornerAvatar(imageUrl: avatar, size: 48),
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
                      style: AppTextStyles.bodySm
                          .copyWith(fontSize: 12),
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
