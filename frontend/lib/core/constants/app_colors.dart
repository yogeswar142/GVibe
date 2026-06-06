import 'package:flutter/material.dart';

/// GITAM Forest Green — GVibe Premium Design System
/// Semantic design tokens for both light and dark modes.
class AppColors {
  AppColors._();

  // ─── Primitive Palette ─────────────────────────────────────────────────────

  // GITAM Green scale
  static const Color gitamGreen = Color(0xFF007366);
  static const Color gitamGreenDark = Color(0xFF005C52);
  static const Color gitamGreenLight = Color(0xFF009688);
  static const Color gitamGreenMint = Color(0xFFE0F2F1);

  // Black / Dark Slate scale (dark mode = Green + Black)
  static const Color darkBg = Color(0xFF050706);
  static const Color darkCard = Color(0xFF0F1413);
  static const Color darkCardHigh = Color(0xFF191F1E);
  static const Color darkCardHighest = Color(0xFF222B29);
  static const Color darkOutlineColor = Color(0xFF2B3633);

  // White / Light Slate scale (light mode = Green + White)
  static const Color lightBg = Color(0xFFFAFBFB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHigh = Color(0xFFEDF2F1);
  static const Color lightCardHighest = Color(0xFFE1EAE7);
  static const Color lightOutlineColor = Color(0xFFCFDCD9);

  // Text colors
  static const Color darkTextPrimary = Color(0xFFF1F3F2);
  static const Color darkTextSecondary = Color(0xFFA5B2AF);
  static const Color darkTextMuted = Color(0xFF6E7D7A);

  static const Color lightTextPrimary = Color(0xFF0C1312);
  static const Color lightTextSecondary = Color(0xFF4A5A57);
  static const Color lightTextMuted = Color(0xFF819591);

  // Like / social
  static const Color orange = Color(0xFFE65100);
  static const Color red = Color(0xFFD32F2F);

  // Utility
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ─── Semantic Tokens (Dark) ─────────────────────────────────────────────────
  static const Color background      = darkBg;
  static const Color surface         = darkCard;
  static const Color surfaceHigh     = darkCardHigh;
  static const Color surfaceHighest  = darkCardHighest;

  static const Color primary         = gitamGreen;
  static const Color primaryDark     = gitamGreenDark;
  static const Color primaryContainer= Color(0xFF003D37);

  static const Color secondary       = gitamGreenLight;
  static const Color like            = orange;

  static const Color outline         = darkOutlineColor;

  static const Color textPrimary     = darkTextPrimary;
  static const Color textSecondary   = darkTextSecondary;
  static const Color textMuted       = darkTextMuted;

  // Accent kept for backward compat (maps to primary)
  static const Color accent          = gitamGreen;
  static const Color accentDark      = gitamGreenDark;
  static const Color pink            = orange;
  static const Color cyberCyan       = gitamGreenLight;
  static const Color error           = red;

  // ─── Semantic Tokens (Light) ────────────────────────────────────────────────
  static const Color lightBackground      = lightBg;
  static const Color lightSurface         = lightCard;
  static const Color lightSurfaceHigh     = lightCardHigh;
  static const Color lightSurfaceHighest  = lightCardHighest;

  static const Color lightPrimary         = gitamGreen;
  static const Color lightPrimaryDark     = gitamGreenDark;
  static const Color lightPrimaryContainer= gitamGreenMint;

  static const Color lightSecondary       = gitamGreenLight;
  static const Color lightLike            = orange;

  static const Color lightOutline         = lightOutlineColor;

  // ─── Gradient Definitions ───────────────────────────────────────────────────
  // No gradients: we make them single-color gradients (both colors are the same)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gitamGreen, gitamGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [gitamGreen, gitamGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleDarkGradient = LinearGradient(
    colors: [darkBg, darkBg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient subtleLightGradient = LinearGradient(
    colors: [lightBg, lightBg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient profileHeaderGradientDark = LinearGradient(
    colors: [darkCard, darkCard],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profileHeaderGradientLight = LinearGradient(
    colors: [lightCardHigh, lightCardHigh],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: gitamGreen.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glowShadowDark = [
    BoxShadow(
      color: gitamGreen.withOpacity(0.2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glowShadowLight = [
    BoxShadow(
      color: gitamGreen.withOpacity(0.15),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> avatarGlowDark = [
    BoxShadow(
      color: gitamGreen.withOpacity(0.35),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> avatarGlowLight = [
    BoxShadow(
      color: gitamGreen.withOpacity(0.25),
      blurRadius: 8,
      spreadRadius: 0.5,
    ),
  ];
}
