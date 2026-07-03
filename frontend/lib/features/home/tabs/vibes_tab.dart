import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final countBgColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFF3F4F6);
    final countTextColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF171717);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Text(
                  'Trending Vibes',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: isDark ? -0.8 : -1.2,
                  ),
                ),
                const Spacer(),
                if (_trending.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: countBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_trending.length} vibes',
                      style: AppTextStyles.monoXs.copyWith(
                        color: countTextColor,
                        fontWeight: FontWeight.w600,
                      ),
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
                                color: isDark ? const Color(0xFF838EA6) : const Color(0xFF888888), size: 48),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: AppTextStyles.bodyMd.copyWith(
                                    color: isDark ? const Color(0xFF838EA6) : const Color(0xFF888888))),
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
                                    color: isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3), size: 48),
                                const SizedBox(height: 16),
                                Text('No trending vibes yet',
                                    style: AppTextStyles.headlineMd
                                        .copyWith(color: titleColor, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Text('Post something to get started!',
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: isDark ? const Color(0xFF838EA6) : const Color(0xFF888888))),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTrending,
                            color: isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3),
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

  // Linear dark backgrounds
  static const _tileColorsDark = [
    Color(0xFF0F1011),
    Color(0xFF1A1F4D),
    Color(0xFF121315),
    Color(0xFF1F2560),
    Color(0xFF0A0A0C),
    Color(0xFF151936),
  ];

  // Vercel light backgrounds
  static const _tileColorsLight = [
    Color(0xFFFFFFFF),
    Color(0xFFF9F9FB),
    Color(0xFFF3F4F6),
    Color(0xFFFFFFFF),
    Color(0xFFF5F7FA),
    Color(0xFFFAFAFA),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? _tileColorsDark[colorIndex % _tileColorsDark.length]
        : _tileColorsLight[colorIndex % _tileColorsLight.length];

    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final handleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final likesBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFF171717).withValues(alpha: 0.06);
    final likesTextColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
    final captionColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF222222);

    final author = vibe['author'] as Map<String, dynamic>?;
    final handle =
        '@${author?['name']?.toString().replaceAll(' ', '.').toLowerCase() ?? 'unknown'}';
    final post = vibe['post']?.toString() ?? '';
    final likes = (vibe['likes'] as List?)?.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isDark ? 14 : 12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: likesBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded,
                              color: likesTextColor, size: 10),
                          const SizedBox(width: 4),
                          Text('$likes',
                              style: AppTextStyles.monoXs.copyWith(
                                  color: likesTextColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  post,
                  style: AppTextStyles.bodySm.copyWith(
                    color: captionColor,
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
                    color: handleColor,
                    fontWeight: FontWeight.w500,
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
