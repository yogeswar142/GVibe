import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/api_service.dart';

class SharePostSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final ValueChanged<int>? onShared;

  const SharePostSheet({
    super.key,
    required this.post,
    this.onShared,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> post,
    ValueChanged<int>? onShared,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SharePostSheet(
        post: post,
        onShared: onShared,
      ),
    );
  }

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  String? _shareUrl;
  bool _loading = true;
  bool _copied = false;
  int _sharesCount = 0;

  @override
  void initState() {
    super.initState();
    _sharesCount = widget.post['sharesCount'] ?? 0;
    _generateShareLink();
  }

  Future<void> _generateShareLink() async {
    final postId = widget.post['_id']?.toString() ?? widget.post['id']?.toString();
    if (postId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final res = await ApiService().dio.post('/posts/$postId/share');
      if (res.data['success'] == true && mounted) {
        setState(() {
          _shareUrl = res.data['data']['shareUrl'];
          _sharesCount = res.data['data']['sharesCount'] ?? (_sharesCount + 1);
          _loading = false;
        });
        widget.onShared?.call(_sharesCount);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shareUrl = 'https://gvibe.onrender.com/api/posts/$postId';
          _loading = false;
        });
      }
    }
  }

  void _copyToClipboard() {
    if (_shareUrl == null) return;
    Clipboard.setData(ClipboardData(text: _shareUrl!));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Short link copied to clipboard! 🚀'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1011) : Colors.white;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF171717);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);
    final accentColor = isDark ? const Color(0xFF5E6AD2) : const Color(0xFF0070F3);
    final linkBg = isDark ? const Color(0xFF16191E) : const Color(0xFFF4F5F7);

    final author = widget.post['author'] is Map ? widget.post['author'] as Map : null;
    final authorName = author?['name']?.toString() ?? 'Student';
    final content = widget.post['content']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: subtitleColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              Icon(Icons.share_outlined, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Share Post',
                style: AppTextStyles.headlineSm.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close_rounded, color: subtitleColor, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Mini Preview Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13161C) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post by $authorName',
                  style: AppTextStyles.bodyXs.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.bodySm.copyWith(color: titleColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'SHORT LINK (AUTO-TRACKED)',
            style: AppTextStyles.monoXs.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),

          const SizedBox(height: 8),

          // Short Link Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: linkBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: subtitleColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: _loading
                      ? Text('Generating short link...', style: TextStyle(color: subtitleColor, fontSize: 13))
                      : Text(
                          _shareUrl ?? '',
                          style: AppTextStyles.monoSm.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _copied ? const Color(0xFF27C93F) : accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: AppTextStyles.bodyXs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'This link tracks clicks, device analytics, and country metrics in your Profile Analytics.',
            style: AppTextStyles.bodyXs.copyWith(color: subtitleColor, fontSize: 11),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
