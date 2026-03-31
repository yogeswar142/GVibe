import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/gvibe_widgets.dart';

class HomeFeedTab extends StatefulWidget {
  const HomeFeedTab({super.key});

  @override
  State<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<HomeFeedTab> {
  int _activeTab = 0; // 0 = POSTS, 1 = VIBES
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().dio.get('/posts');
      if (response.data['success'] == true) {
        setState(() {
          _posts = response.data['data'] ?? [];
          _loading = false;
        });
      }
    } on DioException catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : RefreshIndicator(
                      onRefresh: _fetchPosts,
                      color: AppColors.accent,
                      backgroundColor: AppColors.surface,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (_activeTab == 0) ...[
                            ..._posts.map((p) => _PostCard(post: p)),
                            if (_posts.isEmpty)
                              _buildEmptyState('NO POSTS YET', Icons.article_outlined),
                          ] else ...[
                            _buildVibesSection(),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      // FAB — acid yellow + icon
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: AppColors.accent),
        child: IconButton(
          icon: const Icon(Icons.add, color: AppColors.accentDark, size: 28),
          onPressed: () => _showCreatePostSheet(context),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      color: AppColors.background,
      child: Row(
        children: [
          Text(
            'GVIBE',
            style: AppTextStyles.displaySm.copyWith(
              color: AppColors.accent,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary, size: 22),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Row(
        children: [
          _tab('POSTS', 0),
          _tab('VIBES', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.monoSm.copyWith(
                color: isActive ? AppColors.accent : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVibesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LATEST VIBES',
            style: AppTextStyles.displaySm.copyWith(
              fontSize: 28,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // 2-column grid of vibe image tiles
          _buildVibeGrid(),
        ],
      ),
    );
  }

  Widget _buildVibeGrid() {
    final vibes = [
      {'handle': '@TECH_DISTRICT', 'caption': 'Late night grind session.'},
      {'handle': '@ANALOG_DREAM', 'caption': 'Sound frequencies.'},
      {'handle': '@URBAN_EXPLORE', 'caption': 'Campus after dark.'},
      {'handle': '@MOTION_FREEZE', 'caption': 'Rhythm study.'},
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _vibeTile(vibes[0], const Color(0xFF1F1F2A))),
            const SizedBox(width: 4),
            Expanded(child: _vibeTile(vibes[1], const Color(0xFF181820))),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _vibeTile(vibes[2], const Color(0xFF151518))),
            const SizedBox(width: 4),
            Expanded(child: _vibeTile(vibes[3], const Color(0xFF1A1A24))),
          ],
        ),
      ],
    );
  }

  Widget _vibeTile(Map<String, String> data, Color bg) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.outline, width: 0.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 32),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.background.withValues(alpha: 0.85),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: AppColors.accent,
                        child: Text(
                          data['handle']!,
                          style: AppTextStyles.monoXs.copyWith(
                            color: AppColors.accentDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.bolt, color: AppColors.accent, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['caption']!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 16),
          Text(text,
              style: AppTextStyles.monoMd.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CreatePostSheet(onPostCreated: _fetchPosts),
    );
  }
}

// ===== POST CARD =====
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final author = post['author'];
    final name = author?['name']?.toString().toUpperCase() ?? 'ANON';
    final avatar = author?['avatar']?.toString();
    final content = post['content']?.toString() ?? '';
    final likes = (post['likes'] as List?)?.length ?? 0;
    final comments = (post['comments'] as List?)?.length ?? 0;
    final createdAt = post['createdAt']?.toString() ?? '';
    final timeAgo = _timeAgo(createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline, width: 1),
                ),
                child: CutCornerAvatar(imageUrl: avatar, size: 42),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.replaceAll(' ', '_'),
                      style: AppTextStyles.monoLg.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$timeAgo • Engineering Block',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // TRENDING badge (show on first few)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.pink,
                child: Text(
                  'TRENDING',
                  style: AppTextStyles.monoXs.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.more_vert, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          Text(
            content,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          // Actions row: likes, comments, RETWEET
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.accent, size: 16),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.accent,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.textMuted, size: 16),
              const SizedBox(width: 4),
              Text(
                '$comments',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'RETWEET',
                style: AppTextStyles.displaySm.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '12',
                style: AppTextStyles.monoSm.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(String dateString) {
    if (dateString.isEmpty) return 'now';
    try {
      final dt = DateTime.parse(dateString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'now';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

// ===== CREATE POST SHEET =====
class _CreatePostSheet extends StatefulWidget {
  final VoidCallback onPostCreated;
  const _CreatePostSheet({required this.onPostCreated});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  int _mode = 0; // 0 = selector, 1 = text post
  final _contentController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _posting = true);
    try {
      final response = await ApiService().dio.post('/posts', data: {
        'content': content,
        'type': 'text',
      });
      if (response.data['success'] == true) {
        widget.onPostCreated();
        if (mounted) Navigator.of(context).pop();
      }
    } on DioException catch (_) {
      // handle error
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == 0) return _buildSelector();
    return _buildTextPostEditor();
  }

  // SELECT INPUT → NEW_ENTRY bottom sheet
  Widget _buildSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 120),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 3),
          right: BorderSide(color: AppColors.accent, width: 3),
          top: BorderSide(color: AppColors.accent, width: 3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT INPUT',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NEW_ENTRY',
                      style: AppTextStyles.displaySm.copyWith(
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close,
                      color: AppColors.textPrimary, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // NORMAL POST card
          _postTypeCard(
            icon: Icons.subject,
            number: '01',
            title: 'NORMAL POST',
            description: 'Text-heavy layouts with kinetic\nzine typography and raw layouts.',
            onTap: () => setState(() => _mode = 1),
          ),
          const SizedBox(height: 12),
          // VIBE POST card
          _postTypeCard(
            icon: Icons.camera_alt_outlined,
            number: '02',
            title: 'VIBE POST',
            description: 'Immersive full-screen imagery\nwith high-contrast toxic overlays.',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: AppColors.outline),
          ),
          const SizedBox(height: 16),
          // DRAFTS SAVED AUTOMATICALLY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'DRAFTS SAVED AUTOMATICALLY',
                  style: AppTextStyles.monoXs.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // RESUME draft
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'RESUME: CAMPUS_NIGHTS.LOG',
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _postTypeCard({
    required IconData icon,
    required String number,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        color: AppColors.surfaceHigh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  color: AppColors.accent,
                  child: Icon(icon, color: AppColors.accentDark, size: 18),
                ),
                const Spacer(),
                Text(
                  number,
                  style: AppTextStyles.monoSm.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.displaySm.copyWith(
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-screen text post editor
  Widget _buildTextPostEditor() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar: X - GVIBE - POST
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: AppColors.textPrimary, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    'GVIBE',
                    style: AppTextStyles.displaySm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _posting ? null : _submitPost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      color: AppColors.accent,
                      child: _posting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.accentDark),
                            )
                          : Text(
                              'POST',
                              style: AppTextStyles.monoSm.copyWith(
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Avatar + NORMAL POST label + text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CutCornerAvatar(size: 48),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'NORMAL POST',
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                    width: 32, height: 2, color: AppColors.accent),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 60),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: "What's happening?",
                            hintStyle: AppTextStyles.bodyLg.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 20,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    // Dashed border area for media
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom: EVERYONE CAN REPLY + media toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                color: AppColors.accent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, color: AppColors.accentDark, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'EVERYONE CAN REPLY',
                      style: AppTextStyles.monoXs.copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: AppColors.outline),
            // Media toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 22),
                  Text('GIF',
                      style: AppTextStyles.monoSm.copyWith(
                          color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                  const Icon(Icons.bar_chart, color: AppColors.textMuted, size: 22),
                  const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
