import 'package:flutter/material.dart';

/// GVibe Design System — Deep-Navy Cinematic Palette
/// Merges Linear's dark-surface-ladder with Vercel's hairline-on-white restraint,
/// tuned toward clstr.in's #070B14 theme tone.
/// Semantic tokens for both dark (default) and light modes.
class AppColors {
  AppColors._();

  // ─── Primitive Palette — Dark (Linear-inspired) ─────────────────────────────

  // Canvas / surface ladder
  static const Color darkCanvas       = Color(0xFF010102);
  static const Color darkSurface1     = Color(0xFF0F1011);
  static const Color darkSurface2     = Color(0xFF141516);
  static const Color darkSurface3     = Color(0xFF18191A);

  // Hairlines
  static const Color darkHairline     = Color(0xFF23252A);
  static const Color darkHairlineStrong = Color(0xFF34343A);

  // Ink scale
  static const Color darkInk          = Color(0xFFF7F8F8);
  static const Color darkInkMuted     = Color(0xFFD0D6E0);
  static const Color darkInkSubtle    = Color(0xFF8A8F98);
  static const Color darkInkFaint     = Color(0xFF62666D);

  // Accent
  static const Color accentIndigo     = Color(0xFF5E6AD2);
  static const Color accentIndigoHover   = Color(0xFF828FFF);
  static const Color accentIndigoPressed = Color(0xFF5E69D1);
  static const Color accentContainer  = Color(0xFF1A1F4D); // dark accent bg

  // Status
  static const Color statusSuccess    = Color(0xFF27A644);
  static const Color statusWarning    = Color(0xFFF5B942);
  static const Color statusDanger     = Color(0xFFF0555A);

  // Overlay
  static const Color darkOverlay      = Color(0xB7000000); // rgba(0,0,0,0.72)

  // ─── Primitive Palette — Light (Vercel-inspired) ────────────────────────────

  static const Color lightCanvas      = Color(0xFFFAFAFA);
  static const Color lightSurface0    = Color(0xFFFFFFFF);
  static const Color lightSurfaceSunken = Color(0xFFF2F2F2);

  static const Color lightHairline    = Color(0xFFEBEBEB);
  static const Color lightHairlineStrong = Color(0xFFD7D9E0);

  static const Color lightInk         = Color(0xFF171717);
  static const Color lightInkMuted    = Color(0xFF4D4D4D);
  static const Color lightInkSubtle   = Color(0xFF8F8F8F);
  static const Color lightInkFaint    = Color(0xFFA1A1A1);

  static const Color lightAccent      = Color(0xFF171717); // Stark black primary
  static const Color lightAccentHover = Color(0xFF333333);
  static const Color lightAccentPressed = Color(0xFF000000);
  static const Color lightAccentContainer = Color(0xFFEAEAEA);

  static const Color lightStatusSuccess = Color(0xFF0070F3); // Vercel blue
  static const Color lightStatusWarning = Color(0xFFF5A623);
  static const Color lightStatusDanger  = Color(0xFFEE0000);

  static const Color lightOverlay     = Color(0x80171717); // rgba(23,23,23,0.50)

  // ─── Utility ────────────────────────────────────────────────────────────────
  static const Color white            = Color(0xFFFFFFFF);
  static const Color black            = Color(0xFF000000);
  static const Color transparent      = Colors.transparent;

  // ─── Semantic Tokens (Dark) — names kept for backward compatibility ─────────
  static const Color background       = darkCanvas;       // 0xFF070B14
  static const Color surface          = darkSurface1;     // 0xFF0D1220
  static const Color surfaceHigh      = darkSurface2;     // 0xFF131A2B
  static const Color surfaceHighest   = darkSurface3;     // 0xFF1A2236

  static const Color primary          = accentIndigo;     // 0xFF6C7BF7
  static const Color primaryDark      = accentIndigoPressed;
  static const Color primaryContainer = accentContainer;  // 0xFF1A1F4D
  static const Color secondary        = accentIndigoHover;

  static const Color outline          = darkHairline;     // 0xFF212A3D
  static const Color outlineStrong    = darkHairlineStrong;

  static const Color textPrimary      = darkInk;          // 0xFFF4F6FA
  static const Color textSecondary    = darkInkMuted;     // 0xFFC2C9D9
  static const Color textMuted        = darkInkSubtle;    // 0xFF838EA6
  static const Color textFaint        = darkInkFaint;     // 0xFF545E75

  // Legacy aliases
  static const Color accent           = accentIndigo;
  static const Color accentDark       = accentIndigoPressed;
  static const Color like             = statusDanger;     // heart = danger red
  static const Color orange           = statusDanger;
  static const Color pink             = accentIndigo;
  static const Color cyberCyan        = accentIndigoHover;
  static const Color error            = statusDanger;

  // ─── Semantic Tokens (Light) ─────────────────────────────────────────────────
  static const Color lightBackground       = lightCanvas;
  static const Color lightSurface          = lightSurface0;
  static const Color lightSurfaceHigh      = lightSurfaceSunken;
  static const Color lightSurfaceHighest   = Color(0xFFE8EAF0);

  static const Color lightPrimary          = lightAccent;
  static const Color lightPrimaryDark      = lightAccentPressed;
  static const Color lightPrimaryContainer = lightAccentContainer;
  static const Color lightSecondary        = lightAccentHover;

  static const Color lightOutline          = lightHairline;
  static const Color lightOutlineStrong    = lightHairlineStrong;

  static const Color lightTextPrimary      = lightInk;
  static const Color lightTextSecondary    = lightInkMuted;
  static const Color lightTextMuted        = lightInkSubtle;
  static const Color lightTextFaint        = lightInkFaint;

  static const Color lightLike             = lightStatusDanger;

  // ─── Gradient Definitions ────────────────────────────────────────────────────
  // Spec: flat fills everywhere — no decorative gradients on components.
  // Kept as single-stop flat for backward compat with call sites.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentIndigo, accentIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [lightAccent, lightAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleDarkGradient = LinearGradient(
    colors: [darkCanvas, darkCanvas],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient subtleLightGradient = LinearGradient(
    colors: [lightCanvas, lightCanvas],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient profileHeaderGradientDark = LinearGradient(
    colors: [darkSurface1, darkSurface1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient profileHeaderGradientLight = LinearGradient(
    colors: [lightSurfaceSunken, lightSurfaceSunken],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows — accent-colored glow, no heavy drop shadows on flat cards ─────
  static List<BoxShadow> cardShadowDark = const [];  // flat + hairline, spec says no shadows on cards

  static List<BoxShadow> cardShadowLight = const []; // flat + hairline

  static List<BoxShadow> glowShadowDark = [
    BoxShadow(
      color: accentIndigo.withValues(alpha: 0.18),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glowShadowLight = [
    BoxShadow(
      color: lightAccent.withValues(alpha: 0.14),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> avatarGlowDark = [
    BoxShadow(
      color: accentIndigo.withValues(alpha: 0.35),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> avatarGlowLight = [
    BoxShadow(
      color: lightAccent.withValues(alpha: 0.25),
      blurRadius: 8,
      spreadRadius: 0.5,
    ),
  ];

  // Bottom sheet / dialog shadow — spec allows this one floating shadow
  static const List<BoxShadow> sheetShadow = [
    BoxShadow(
      color: Color(0x33000000), // ~20% black
      blurRadius: 24,
      offset: Offset(0, -8),
      spreadRadius: -8,
    ),
  ];

  static const List<BoxShadow> sheetShadowLight = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, -8),
      spreadRadius: -8,
    ),
  ];
}
