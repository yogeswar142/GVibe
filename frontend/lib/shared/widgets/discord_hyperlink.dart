import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/link_launcher.dart';

/// Discord-inspired hyperlink style tokens
class DiscordLinkColors {
  DiscordLinkColors._();

  // Discord blurple & cyan accent colors
  static const Color darkLink = Color(0xFF00A8FC);   // Discord light-blue link color
  static const Color lightLink = Color(0xFF5865F2);  // Discord blurple link color
  static const Color pillBgDark = Color(0x1A00A8FC);
  static const Color pillBgLight = Color(0x145865F2);
}

/// Renders a Discord-style clickable hyperlink card.
///
/// Features:
/// - Smart destination detection (Play Store, Discord, Telegram, Web, etc.)
/// - 1-tap dynamic redirection to target app or browser
/// - Integrated copy and open actions
/// - Click-counter badge
class DiscordHyperlinkCard extends StatelessWidget {
  final String shortUrl;
  final String? destinationUrl;
  final int totalClicks;
  final EdgeInsetsGeometry? margin;

  const DiscordHyperlinkCard({
    super.key,
    required this.shortUrl,
    this.destinationUrl,
    this.totalClicks = 0,
    this.margin,
  });

  IconData _detectIcon(String target) {
    final lower = target.toLowerCase();
    if (lower.contains('play.google.com') || lower.startsWith('market:')) {
      return Icons.shop_rounded;
    }
    if (lower.contains('discord.gg') || lower.contains('discord.com')) {
      return Icons.forum_rounded;
    }
    if (lower.contains('t.me') || lower.contains('telegram')) {
      return Icons.send_rounded;
    }
    if (lower.contains('whatsapp') || lower.contains('wa.me')) {
      return Icons.chat_rounded;
    }
    if (lower.contains('instagram.com')) {
      return Icons.camera_alt_rounded;
    }
    if (lower.contains('github.com')) {
      return Icons.code_rounded;
    }
    return Icons.link_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? DiscordLinkColors.darkLink : DiscordLinkColors.lightLink;
    final pillBg = isDark ? DiscordLinkColors.pillBgDark : DiscordLinkColors.pillBgLight;
    final borderColor = isDark ? const Color(0xFF212A3D) : const Color(0xFFE7E8EC);
    final cardBg = isDark ? const Color(0xFF131722) : const Color(0xFFF7F8FA);
    final subtitleColor = isDark ? const Color(0xFF838EA6) : const Color(0xFF888888);

    final targetToOpen = (destinationUrl != null && destinationUrl!.isNotEmpty)
        ? destinationUrl!
        : shortUrl;

    final icon = _detectIcon(targetToOpen);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: linkColor, size: 16),
          ),
          const SizedBox(width: 10),

          // Clickable link text
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => LinkLauncher.launch(context, targetToOpen),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            shortUrl,
                            style: AppTextStyles.monoSm.copyWith(
                              color: linkColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: linkColor.withAlpha(128),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: linkColor,
                        ),
                      ],
                    ),
                    if (destinationUrl != null && destinationUrl!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        destinationUrl!,
                        style: AppTextStyles.bodyXs.copyWith(
                          color: subtitleColor,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Clicks count badge
          if (totalClicks > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2638) : const Color(0xFFEBEFF7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$totalClicks clicks',
                style: AppTextStyles.monoXs.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          const SizedBox(width: 6),

          // Copy button
          IconButton(
            icon: Icon(Icons.copy_rounded, color: subtitleColor, size: 16),
            tooltip: 'Copy short link',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => LinkLauncher.copyToClipboard(context, shortUrl),
          ),
        ],
      ),
    );
  }
}

/// Rich text widget that automatically detects URLs and formats them as Discord hyperlinks.
class RichContentText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const RichContentText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+|market:\/\/[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = style ??
        (isDark ? AppTextStyles.bodyMd : AppTextStyles.bodyMd.copyWith(color: const Color(0xFF222222)));
    final linkColor = isDark ? DiscordLinkColors.darkLink : DiscordLinkColors.lightLink;

    final linkStyle = defaultStyle.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: linkColor.withAlpha(160),
    );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      String cleanUrl = match.group(0)!;
      String trailingPunctuation = '';
      while (cleanUrl.isNotEmpty &&
          RegExp(r'[.,!?:;)"\]\}'']').hasMatch(cleanUrl[cleanUrl.length - 1])) {
        trailingPunctuation = cleanUrl[cleanUrl.length - 1] + trailingPunctuation;
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }

      final urlToLaunch = cleanUrl;
      spans.add(
        TextSpan(
          text: '$cleanUrl ↗',
          style: linkStyle,
          mouseCursor: SystemMouseCursors.click,
          recognizer: TapGestureRecognizer()
            ..onTap = () => LinkLauncher.launch(context, urlToLaunch),
        ),
      );

      if (trailingPunctuation.isNotEmpty) {
        spans.add(TextSpan(
          text: trailingPunctuation,
          style: defaultStyle,
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
