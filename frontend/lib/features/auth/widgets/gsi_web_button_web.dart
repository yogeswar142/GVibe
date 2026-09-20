import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as gsi_web;

/// Web implementation that renders Google's official GSI button iframe.
Widget buildWebGoogleSignInButton({
  required BuildContext context,
  required String action,
}) {
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
            text: action == 'register'
                ? gsi_web.GSIButtonText.signupWith
                : gsi_web.GSIButtonText.signinWith,
          ),
        ),
      ),
    );
  }
  return const SizedBox.shrink();
}
