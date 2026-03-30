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
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final response = await ApiService().dio.get('/discovery/trending');
      if (response.data['success'] == true) {
        setState(() {
          _trending = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load trending';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GVibeAppBar(),
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
                        GVibeButton(label: 'RETRY', onPressed: _fetchTrending),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchTrending,
                    color: AppColors.accent,
                    backgroundColor: AppColors.surface,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('HOT VIBES', style: AppTextStyles.displayMd),
                        const SizedBox(height: 16),
                        if (_trending.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                const Icon(Icons.bolt, color: AppColors.accent, size: 48),
                                const SizedBox(height: 16),
                                Text('NO TRENDING VIBES', style: AppTextStyles.monoMd.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: _trending.length > 4 ? 4 : _trending.length,
                            itemBuilder: (context, index) {
                              final vibe = _trending[index];
                              final author = vibe['author'] as Map<String, dynamic>?;
                              final label = '@${author?['name']?.toString().toUpperCase().replaceAll(' ', '_') ?? 'UNKNOWN'}';
                              final post = vibe['post']?.toString() ?? '';
                              final likesCount = (vibe['likesCount'] ?? (vibe['likes'] as List?)?.length ?? 0);
                              return _VibeGridCard(
                                label: label,
                                filename: '${likesCount}⚡ · ${post.length > 20 ? '${post.substring(0, 20)}...' : post}',
                                color: _gridColors[index % _gridColors.length],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  static const _gridColors = [
    Color(0xFF0D1018),
    Color(0xFF101010),
    Color(0xFF0A0A0A),
    Color(0xFF121218),
  ];
}

class _VibeGridCard extends StatelessWidget {
  final String label;
  final String filename;
  final Color color;

  const _VibeGridCard({
    required this.label,
    required this.filename,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.bolt,
                color: AppColors.textMuted, size: 40),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              color: AppColors.background.withOpacity(0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.accent, fontSize: 9)),
                  Text(filename,
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.textPrimary, fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
