import 'package:flutter/material.dart';

/// Fallback stub for non-web platforms (Android, iOS, Desktop).
Widget buildWebGoogleSignInButton({
  required BuildContext context,
  required String action,
}) {
  return const SizedBox.shrink();
}
