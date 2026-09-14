import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as gsi_web;
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
      // On Web: Render Google's official GSI button widget (required by Google Web GIS SDK)
      final plugin = GoogleSignInPlatform.instance;
      if (plugin is gsi_web.GoogleSignInPlugin) {
        return SizedBox(
          height: 48,
          width: double.infinity,
          child: Center(
            child: plugin.renderButton(
              configuration: gsi_web.GSIButtonConfiguration(
                theme: Theme.of(context).brightness == Brightness.dark
                    ? gsi_web.GSIButtonTheme.filledBlack
                    : gsi_web.GSIButtonTheme.outline,
                size: gsi_web.GSIButtonSize.large,
                shape: gsi_web.GSIButtonShape.rectangular,
                text: widget.action == 'register'
                    ? gsi_web.GSIButtonText.signupWith
                    : gsi_web.GSIButtonText.signinWith,
              ),
            ),
          ),
        );
      }
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
