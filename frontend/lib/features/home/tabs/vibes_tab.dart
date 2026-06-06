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
        _error = ApiService.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
            color: cs.background,
            child: Row(
              children: [
                Text('Trending Vibes',
                    style: AppTextStyles.headlineLg.copyWith(
                        color: cs.onSurface)),
                const Spacer(),
                if (_trending.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_trending.length} vibes',
                      style: AppTextStyles.monoXs.copyWith(
                          color: cs.primary),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) =>
                        const SkeletonBox(width: double.infinity,
                            height: double.infinity, borderRadius: 16),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                color: cs.onSurfaceVariant, size: 48),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: AppTextStyles.bodyMd.copyWith(
                                    color: cs.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            GVibeButton(
                                label: 'Retry',
                                onPressed: _fetchTrending),
                          ],
                        ),
                      )
                    : _trending.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded,
                                    color: cs.primary, size: 48),
                                const SizedBox(height: 16),
                                Text('No trending vibes yet',
                                    style: AppTextStyles.headlineMd
                                        .copyWith(color: cs.onSurface)),
                                const SizedBox(height: 8),
                                Text('Post something to get started!',
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTrending,
                            color: AppColors.primary,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 100),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _trending.length,
                              itemBuilder: (context, index) =>
                                  _TrendingVibeCard(
                                vibe: _trending[index],
                                colorIndex: index,
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TrendingVibeCard extends StatelessWidget {
  final Map<String, dynamic> vibe;
  final int colorIndex;

  const _TrendingVibeCard(
      {required this.vibe, required this.colorIndex});

  static const _gradients = [
    LinearGradient(colors: [Color(0xFF007366), Color(0xFF007366)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF005C52), Color(0xFF005C52)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
    LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00897B)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF004D40), Color(0xFF004D40)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
    LinearGradient(colors: [Color(0xFF009688), Color(0xFF009688)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
    LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00695C)],
        begin: Alignment.topRight, end: Alignment.bottomLeft),
  ];

  @override
  Widget build(BuildContext context) {
    final author = vibe['author'] as Map<String, dynamic>?;
    final handle =
        '@${author?['name']?.toString().replaceAll(' ', '.').toLowerCase() ?? 'unknown'}';
    final post = vibe['post']?.toString() ?? '';
    final likes = (vibe['likes'] as List?)?.length ?? 0;
    final gradient = _gradients[colorIndex % _gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: Colors.white70, size: 10),
                          const SizedBox(width: 3),
                          Text('$likes',
                              style: AppTextStyles.monoXs.copyWith(
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  post,
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  handle,
                  style: AppTextStyles.monoXs.copyWith(
                    color: Colors.white70,
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
