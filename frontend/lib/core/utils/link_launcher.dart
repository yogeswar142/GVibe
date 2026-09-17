import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'web_launcher_stub.dart'
    if (dart.library.js_interop) 'web_launcher_web.dart';

/// Production-grade dynamic link launcher.
///
/// Dispatches URLs directly to the OS to open:
/// - Play Store links -> native Google Play Store app
/// - Social deep links (WhatsApp, Telegram, Discord, Instagram) -> target app
/// - Web domains -> default browser / new tab
class LinkLauncher {
  LinkLauncher._();

  /// Dynamically launches any URL according to its scheme and OS intent
  static Future<void> launch(BuildContext context, String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;

    String url = trimmed;
    // Normalize web URLs that miss protocol
    if (!url.contains('://') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('tel:') &&
        !url.startsWith('market:')) {
      url = 'https://$url';
    }

    try {
      final uri = Uri.parse(url);

      // Web platform handler: open directly via DOM window.open
      // This bypasses Flutter method channel and prevents MissingPluginException
      if (kIsWeb) {
        try {
          openInWebBrowser(url);
          return;
        } catch (_) {
          // Fallback to url_launcher on web if needed
          await launchUrl(uri, webOnlyWindowName: '_blank');
          return;
        }
      }

      // Mobile/Desktop: Try external application intent resolver first
      // (Handles Play Store, native apps, or external browser)
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('[LinkLauncher] externalApplication mode failed: $e');
        launched = false;
      }

      // Fallback to platform default if external intent was unhandled
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('[LinkLauncher] platformDefault fallback failed: $e');
          launched = false;
        }
      }

      if (!launched && context.mounted) {
        _showError(context, url);
      }
    } catch (e) {
      debugPrint('[LinkLauncher] Unexpected launch failure for $url: $e');
      if (context.mounted) {
        _showError(context, url);
      }
    }
  }

  static void _showError(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open link: $url'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  /// Copies link with haptic confirmation and toast
  static void copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
