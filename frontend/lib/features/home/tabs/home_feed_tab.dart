import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/gvibe_widgets.dart';

class HomeFeedTab extends StatefulWidget {
  const HomeFeedTab({super.key});

  @override
  State<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<HomeFeedTab> {
  List<dynamic> _vibes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final response = await ApiService().dio.get('/vibes/feed');
      if (response.data['success'] == true) {
        setState(() {
          _vibes = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load feed';
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike(String vibeId) async {
    try {
      await ApiService().dio.put('/vibes/$vibeId/like');
      _fetchFeed(); // Refresh
    } catch (e) {
      // Silently handle
    }
  }

  Future<void> _createVibe(String text) async {
    try {
      await ApiService().dio.post('/vibes', data: {'post': text});
      _fetchFeed();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Failed to post'),
            backgroundColor: AppColors.pink,
          ),
        );
      }
    }
  }

  void _showCreateVibeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('NEW VIBE', style: AppTextStyles.displaySm.copyWith(color: AppColors.accent)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
            hintStyle: AppTextStyles.monoSm.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceHigh,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTextStyles.monoSm.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _createVibe(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: Text('POST', style: AppTextStyles.monoSm.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GVibeAppBar(
        showNotification: true,
        showAvatar: true,
        onMenuTap: () => context.push('/profile'),
      ),
      body: NoiseOverlay(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: AppTextStyles.monoMd.copyWith(color: AppColors.pink)),
                        const SizedBox(height: 16),
                        GVibeButton(label: 'RETRY', onPressed: _fetchFeed),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchFeed,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Tab bar
                        Container(
                          color: AppColors.background,
                          child: Row(
                            children: [
                              _TabItem(label: 'POSTS', isActive: true, onTap: () {}),
                              _TabItem(label: 'VIBES', isActive: false, onTap: () {}),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_vibes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                const Icon(Icons.bolt, color: AppColors.accent, size: 48),
                                const SizedBox(height: 16),
                                Text('NO VIBES YET', style: AppTextStyles.displaySm.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Text('Be the first to post!', style: AppTextStyles.monoSm.copyWith(color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        else
                          ..._vibes.map((vibe) => _PostCard(
                                vibe: vibe,
                                onLike: () => _toggleLike(vibe['_id']),
                              )),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showCreateVibeDialog,
        child: Container(
          width: 52,
          height: 52,
          color: AppColors.accent,
          child: Stack(
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.pink.withOpacity(0.5),
                ),
              ),
              const Center(
                child: Icon(Icons.add, color: AppColors.accentDark, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.monoMd.copyWith(
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(height: 2, width: 40, color: AppColors.accent)
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> vibe;
  final VoidCallback onLike;

  const _PostCard({required this.vibe, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final author = vibe['author'] as Map<String, dynamic>?;
    final authorName = author?['name']?.toString().toUpperCase() ?? 'ANONYMOUS';
    final authorDept = author?['dept']?.toString() ?? '';
    final post = vibe['post']?.toString() ?? '';
    final likes = (vibe['likes'] as List?)?.length ?? 0;
    final comments = (vibe['comments'] as List?)?.length ?? 0;
    final createdAt = vibe['createdAt']?.toString() ?? '';
    final timeAgo = _formatTimeAgo(createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
      ),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CutCornerAvatar(imageUrl: author?['avatar'], size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: AppTextStyles.monoMd
                              .copyWith(color: AppColors.accent)),
                      Text('$timeAgo${authorDept.isNotEmpty ? ' · $authorDept' : ''}',
                          style: AppTextStyles.monoXs),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(post, style: AppTextStyles.bodyMd),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Row(
                    children: [
                      Icon(likes > 0 ? Icons.favorite : Icons.favorite_border,
                          color: likes > 0 ? AppColors.pink : AppColors.textSecondary, size: 16),
                      const SizedBox(width: 4),
                      Text('$likes',
                          style: AppTextStyles.monoXs
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 4),
                    Text('$comments',
                        style: AppTextStyles.monoXs
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }
}
