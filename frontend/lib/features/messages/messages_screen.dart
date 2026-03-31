import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/gvibe_widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _activeTab = 0; // 0 = DIRECT, 1 = COMMUNITIES

  // Mock data matching the design mockup exactly
  final List<Map<String, dynamic>> _directMessages = [
    {
      'name': 'NEO_WITCH',
      'time': '12:45 PM',
      'message': 'That set at the basement was wild...',
      'isHighlighted': true,
      'hasUnread': false,
    },
    {
      'name': 'VIBE_CHECKER',
      'time': '09:12 AM',
      'message': 'Yo, did you get the community invite?',
      'isHighlighted': false,
      'hasUnread': true,
    },
    {
      'name': 'LUNAR_ECHO',
      'time': 'YESTERDAY',
      'message': 'See you at the quad later.',
      'isHighlighted': false,
      'hasUnread': false,
    },
    {
      'name': 'THE_LOUNGE',
      'time': 'YESTERDAY',
      'message': '#general: New event dropped!',
      'isHighlighted': false,
      'hasUnread': false,
      'isCommunity': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NoiseOverlay(
        child: Column(
          children: [
            // Top bar
            Container(
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
            ),
            Container(height: 1, color: AppColors.outline),
            // DIRECT / COMMUNITIES tab bar
            _buildTabBar(),
            // Message list
            Expanded(
              child: _activeTab == 0
                  ? _buildDirectList()
                  : _buildCommunitiesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _tabButton('DIRECT', 0),
          _tabButton('COMMUNITIES', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.transparent,
            border: isActive
                ? null
                : Border.all(color: AppColors.outline, width: 0.5),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.monoSm.copyWith(
                color: isActive ? AppColors.accentDark : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _directMessages.length,
      itemBuilder: (context, index) {
        final msg = _directMessages[index];
        return _ChatRow(
          name: msg['name'],
          time: msg['time'],
          message: msg['message'],
          isHighlighted: msg['isHighlighted'] ?? false,
          hasUnread: msg['hasUnread'] ?? false,
          isCommunity: msg['isCommunity'] ?? false,
        );
      },
    );
  }

  Widget _buildCommunitiesList() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_outlined, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 16),
          Text(
            'NO COMMUNITIES YET',
            style: AppTextStyles.monoMd.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            'Join a community to start vibing',
            style:
                AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  final String name;
  final String time;
  final String message;
  final bool isHighlighted;
  final bool hasUnread;
  final bool isCommunity;

  const _ChatRow({
    required this.name,
    required this.time,
    required this.message,
    this.isHighlighted = false,
    this.hasUnread = false,
    this.isCommunity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: isHighlighted ? AppColors.accent : Colors.transparent,
      child: Row(
        children: [
          // Unread dot
          if (hasUnread && !isHighlighted)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              color: AppColors.accent,
            ),
          // Avatar
          isCommunity
              ? Container(
                  width: 52,
                  height: 52,
                  color: isHighlighted
                      ? AppColors.accentDark.withValues(alpha: 0.2)
                      : AppColors.surfaceHigh,
                  child: Icon(
                    Icons.groups,
                    color: isHighlighted ? AppColors.accentDark : AppColors.accent,
                    size: 24,
                  ),
                )
              : CutCornerAvatar(size: 52),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.displaySm.copyWith(
                    fontSize: 16,
                    color: isHighlighted
                        ? AppColors.accentDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontSize: 13,
                    color: isHighlighted
                        ? AppColors.accentDark.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time
          Text(
            time,
            style: AppTextStyles.monoXs.copyWith(
              color: isHighlighted
                  ? AppColors.accentDark.withValues(alpha: 0.7)
                  : AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
