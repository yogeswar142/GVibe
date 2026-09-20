import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'gsi_web_button_stub.dart'
    if (dart.library.js_interop) 'gsi_web_button_web.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/gvibe_widgets.dart';

/// A platform-adaptive Google Sign-In button that renders:
/// - Google's official Web SDK button (iframe) when running on Chrome/Web
///   (required by Google Identity Services to securely open the account popup)
/// - GVibe's custom themed button on Mobile (Android / iOS)
class AdaptiveGoogleSignInButton extends StatefulWidget {
  final String action; // 'login' or 'register'
  final ValueChanged<Map<String, dynamic>> onAuthSuccess;
  final ValueChanged<String> onError;

  const AdaptiveGoogleSignInButton({
    super.key,
    required this.action,
    required this.onAuthSuccess,
    required this.onError,
  });

  @override
  State<AdaptiveGoogleSignInButton> createState() =>
      _AdaptiveGoogleSignInButtonState();
}

class _AdaptiveGoogleSignInButtonState extends State<AdaptiveGoogleSignInButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebListener();
    }
  }

  void _initWebListener() {
    // Ensure plugin is initialized
    AuthService.ensureGoogleInitialized();

    // Listen to web authentication events (fires when user completes sign-in via Google button)
    final stream = GoogleSignInPlatform.instance.authenticationEvents;
    if (stream != null) {
      stream.listen(
        (event) async {
          if (!mounted) return;
          if (event is AuthenticationEventSignIn) {
            final idToken = event.authenticationTokens.idToken;
            if (idToken != null && idToken.isNotEmpty) {
              setState(() => _isLoading = true);
              final res = await AuthService.authenticateGoogleIdToken(
                idToken: idToken,
                action: widget.action,
              );
              if (!mounted) return;
              setState(() => _isLoading = false);

              if (res != null && res['success'] == true) {
                widget.onAuthSuccess(res);
              } else {
                widget.onError(res?['message'] ?? 'Google sign-in failed');
              }
            }
          }
        },
        onError: (e) {
          if (mounted) {
            widget.onError(e.toString());
          }
        },
      );
    }
  }

  Future<void> _handleMobileClick() async {
    setState(() => _isLoading = true);
    final response = await AuthService.triggerGoogleAuth(
      context: context,
      action: widget.action,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response != null && response['success'] == true) {
      widget.onAuthSuccess(response);
    } else if (response != null) {
      widget.onError(response['message'] ?? 'Google authentication failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On Web: Render Google's official GSI button widget (via conditional web import)
      return buildWebGoogleSignInButton(
        context: context,
        action: widget.action,
      );
    }

    // On Mobile (or fallback): Render custom GVibe button
    return GVibeButton(
      label: widget.action == 'register'
          ? 'Continue with Google'
          : 'Google Account',
      isPrimary: widget.action == 'register',
      isLoading: _isLoading,
      icon: Icons.g_mobiledata_rounded,
      onPressed: _isLoading ? null : _handleMobileClick,
    );
  }
}
