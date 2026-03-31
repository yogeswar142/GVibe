import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/widgets/gvibe_widgets.dart';

class VibesTab extends StatefulWidget {
  const VibesTab({super.key});

  @override
  State<VibesTab> createState() => _VibesTabState();
}

class _VibesTabState extends State<VibesTab> {
  List<dynamic> _trending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService().dio.get('/discovery/trending');
      if (response.data['success'] == true) {
        setState(() {
          _trending = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error =
            e.response?.data?['message'] ?? 'Failed to load trending vibes';
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
            GVibeAppBar(showAvatar: true),
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const SectionHeader(title: 'TRENDING VIBES'),
                  const Spacer(),
                  Text(
                    '${_trending.length} VIBES',
                    style: AppTextStyles.monoXs.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                                  onPressed: _fetchTrending),
                            ],
                          ),
                        )
                      : _trending.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt,
                                      color: AppColors.accent, size: 48),
                                  const SizedBox(height: 16),
                                  Text('NO TRENDING VIBES',
                                      style: AppTextStyles.displaySm
                                          .copyWith(
                                              color:
                                                  AppColors.textSecondary)),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Post something to get started!',
                                      style: AppTextStyles.monoSm.copyWith(
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchTrending,
                              color: AppColors.accent,
                              backgroundColor: AppColors.surface,
                              child: GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: _trending.length,
                                itemBuilder: (context, index) {
                                  return _TrendingVibeCard(
                                    vibe: _trending[index],
                                    colorIndex: index,
                                  );
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

class _TrendingVibeCard extends StatelessWidget {
  final Map<String, dynamic> vibe;
  final int colorIndex;

  const _TrendingVibeCard({
    required this.vibe,
    required this.colorIndex,
  });

  static const _bgColors = [
    Color(0xFF0D1018),
    Color(0xFF101014),
    Color(0xFF0F0F18),
    Color(0xFF121218),
    Color(0xFF0E0E16),
    Color(0xFF141420),
  ];

  @override
  Widget build(BuildContext context) {
    final author = vibe['author'] as Map<String, dynamic>?;
    final handle =
        '@${author?['name']?.toString().toUpperCase().replaceAll(' ', '_') ?? 'UNKNOWN'}';
    final post = vibe['post']?.toString() ?? '';
    final likes = (vibe['likes'] as List?)?.length ?? 0;
    final bgColor = _bgColors[colorIndex % _bgColors.length];

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Like count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  color: AppColors.pink.withOpacity(0.2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite,
                          color: AppColors.pink, size: 10),
                      const SizedBox(width: 4),
                      Text('$likes',
                          style: AppTextStyles.monoXs.copyWith(
                              color: AppColors.pink, fontSize: 9)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Post text
                Expanded(
                  child: Text(
                    post,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Bottom handle
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              color: AppColors.background.withOpacity(0.85),
              child: Text(
                handle,
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.accent,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
