import 'package:flutter/material.dart';
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
  final _searchController = TextEditingController();
  List<dynamic> _people = [];
  List<dynamic> _communities = [];
  List<dynamic> _trending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService().dio.get('/discovery/people'),
        ApiService().dio.get('/messages/communities'),
        ApiService().dio.get('/discovery/trending'),
      ]);

      setState(() {
        _people = results[0].data['data'] ?? [];
        _communities = results[1].data['data'] ?? [];
        _trending = results[2].data['data'] ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['message'] ?? 'Failed to load discovery';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: AppTextStyles.monoMd.copyWith(color: AppColors.pink)),
                          const SizedBox(height: 16),
                          GVibeButton(label: 'RETRY', onPressed: _fetchAll),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAll,
                      color: AppColors.accent,
                      backgroundColor: AppColors.surface,
                      child: ListView(
                        children: [
                          // Big DISCOVER heading
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: Text(
                              'DISCOVER',
                              style: AppTextStyles.displayXl.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 64,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: AppColors.outline)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search,
                                      color: AppColors.accent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: AppTextStyles.monoSm,
                                      decoration: InputDecoration(
                                        hintText: 'search people, communities...',
                                        hintStyle: AppTextStyles.monoSm
                                            .copyWith(color: AppColors.textMuted),
                                        border: InputBorder.none,
                                        filled: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // COMMUNITIES
                          if (_communities.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: const SectionHeader(title: 'YOUR COMMUNITIES'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _communities.length,
                                itemBuilder: (context, index) {
                                  final c = _communities[index];
                                  return _CommunityCard(
                                    name: c['name']?.toString().toUpperCase() ?? 'COMMUNITY',
                                    description: c['description']?.toString() ?? '',
                                    members: '${(c['members'] as List?)?.length ?? 0}',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          // PEOPLE YOU MAY KNOW
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const SectionHeader(title: 'PEOPLE YOU MAY KNOW'),
                          ),
                          const SizedBox(height: 12),
                          if (_people.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text('No people found yet', style: AppTextStyles.monoSm.copyWith(color: AppColors.textMuted)),
                              ),
                            )
                          else
                            ..._people.map((p) => _PersonRow(person: p)),
                          const SizedBox(height: 32),
                          // HOT VIBES TODAY
                          if (_trending.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: const SectionHeader(title: 'HOT VIBES TODAY'),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GridView.builder(
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
                                  final handle = '@${author?['name']?.toString().toUpperCase().replaceAll(' ', '_') ?? 'UNKNOWN'}';
                                  final post = vibe['post']?.toString() ?? '';
                                  return _VibeThumb(handle, post.length > 20 ? '${post.substring(0, 20)}...' : post,
                                      _thumbColors[index % _thumbColors.length]);
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  static const _thumbColors = [
    Color(0xFF0D1018),
    Color(0xFF101010),
    Color(0xFF0A0A0A),
    Color(0xFF121218),
  ];
}

class _CommunityCard extends StatelessWidget {
  final String name;
  final String description;
  final String members;

  const _CommunityCard({
    required this.name,
    required this.description,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      color: AppColors.surfaceHigh,
      child: Stack(
        children: [
          Container(
            height: 200,
            color: const Color(0xFF0F1015),
            child: const Center(
              child: Icon(Icons.group,
                  color: AppColors.textMuted, size: 40),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.background.withOpacity(0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.monoMd),
                  if (description.isNotEmpty)
                    Text(description,
                        style: AppTextStyles.monoXs.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  Text('$members MEMBERS',
                      style: AppTextStyles.monoXs
                          .copyWith(color: AppColors.accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatefulWidget {
  final Map<String, dynamic> person;

  const _PersonRow({required this.person});

  @override
  State<_PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<_PersonRow> {
  bool _connected = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.person['name']?.toString().toUpperCase().replaceAll(' ', '_') ?? 'UNKNOWN';
    final dept = widget.person['dept']?.toString().toUpperCase() ?? '';
    final bio = widget.person['bio']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CutCornerAvatar(imageUrl: widget.person['avatar'], size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.monoMd
                        .copyWith(color: AppColors.textPrimary)),
                Text(
                    '${dept.isNotEmpty ? dept : 'STUDENT'}${bio.isNotEmpty ? ' · $bio' : ''}',
                    style: AppTextStyles.monoXs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _connected = !_connected),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.accent,
                  width: 1,
                ),
                color: _connected
                    ? AppColors.accent.withOpacity(0.15)
                    : Colors.transparent,
              ),
              child: Text(
                _connected ? 'CONNECTED' : '+ CONNECT',
                style: AppTextStyles.monoXs.copyWith(
                  color: AppColors.accent,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VibeThumb extends StatelessWidget {
  final String handle;
  final String filename;
  final Color color;

  const _VibeThumb(this.handle, this.filename, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Stack(
        children: [
          const Center(
            child:
                Icon(Icons.bolt, color: AppColors.textMuted, size: 32),
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
                  Text(handle,
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
