import 'package:flutter/material.dart';

/// GVibe Design System — Bay & Gold Coastal Palette (V3)
/// Primary: Deep Bay Teal (#0D9488) · Secondary: Turmeric Gold (#D97706)
/// Dark canvas: #080C0B · Light canvas: #F5FAF9
/// 60-30-10 rule: deep mineral surfaces / seafoam text / teal accents
class AppColors {
  AppColors._();

  // ─── Primitive Palette — Dark (Bay & Gold Coastal) ───────────────────────────

  // Canvas / surface ladder
  static const Color darkCanvas             = Color(0xFF080C0B);
  static const Color darkSurface1           = Color(0xFF0D1412);
  static const Color darkSurface2           = Color(0xFF131C1A);
  static const Color darkSurface3           = Color(0xFF182220);

  // Hairlines (teal-tinted translucent borders)
  static const Color darkHairline           = Color(0xFF1A2E2B); // approx rgba(13,148,136,0.14) on #080C0B
  static const Color darkHairlineStrong     = Color(0xFF1F3835); // approx rgba(13,148,136,0.18)
  static const Color darkHairlineElevated   = Color(0xFF263F3A); // approx rgba(13,148,136,0.28)

  // Ink scale (seafoam white family)
  static const Color darkInk                = Color(0xFFE8F4F2); // on-surface primary
  static const Color darkInkMuted           = Color(0xFF7A9E9A); // secondary text
  static const Color darkInkSubtle          = Color(0xFF3D5C58); // placeholder
  static const Color darkInkFaint           = Color(0xFF2A3F3C); // faint hints

  // Bay Teal Accents
  static const Color bayTeal                = Color(0xFF0D9488); // primary interactive
  static const Color bayTealHover           = Color(0xFF0F766E); // pressed/hover state
  static const Color bayTealContainer       = Color(0xFF0A2D2A); // dark accent bg
  static const Color bayTealLight           = Color(0xFF4FDBC8); // tertiary teal glow

  // Turmeric Gold Accents (micro-accent only)
  static const Color turmericGold           = Color(0xFFD97706); // secondary accent
  static const Color turmericGoldLight      = Color(0xFFF59E0B); // lighter gold
  static const Color turmericGoldMuted      = Color(0xFF432100); // gold container dark

  // Status
  static const Color statusSuccess          = Color(0xFF27A644);
  static const Color statusWarning          = Color(0xFFF59E0B);
  static const Color statusDanger           = Color(0xFFFF6B6B);

  // Overlay
  static const Color darkOverlay            = Color(0xA6000000); // rgba(0,0,0,0.65)

  // ─── Primitive Palette — Light (Bay & Gold Coastal) ──────────────────────────

  static const Color lightCanvas            = Color(0xFFF5FAF9);
  static const Color lightSurface0          = Color(0xFFFFFFFF);
  static const Color lightSurfaceSunken     = Color(0xFFEDF7F5);
  static const Color lightSurfaceHighestVal = Color(0xFFE0EFEC);

  static const Color lightHairline          = Color(0xFFDDF0EC);
  static const Color lightHairlineStrong    = Color(0xFFB8DDD8);

  static const Color lightInk               = Color(0xFF0C1F1D); // primary text
  static const Color lightInkMuted          = Color(0xFF3D6B66); // secondary text
  static const Color lightInkSubtle         = Color(0xFF6B9E99); // placeholder
  static const Color lightInkFaint          = Color(0xFF9BBFBB); // faint

  static const Color lightTeal              = Color(0xFF0F766E); // primary teal on light
  static const Color lightTealHover         = Color(0xFF0D6B63);
  static const Color lightTealContainer     = Color(0xFFCCF0EB);

  static const Color lightGold              = Color(0xFFB45309); // deepened gold on light
  static const Color lightGoldContainer     = Color(0xFFFEF3C7);

  static const Color lightStatusSuccess     = Color(0xFF059669);
  static const Color lightStatusWarning     = Color(0xFFD97706);
  static const Color lightStatusDanger      = Color(0xFFDC2626);

  static const Color lightOverlay           = Color(0x330C1F1D);

  // ─── Utility ─────────────────────────────────────────────────────────────────
  static const Color white                  = Color(0xFFFFFFFF);
  static const Color black                  = Color(0xFF000000);
  static const Color transparent            = Colors.transparent;

  // ─── Semantic Tokens (Dark) ──────────────────────────────────────────────────
  static const Color background             = darkCanvas;
  static const Color surface               = darkSurface1;
  static const Color surfaceHigh           = darkSurface2;
  static const Color surfaceHighest        = darkSurface3;

  static const Color primary               = bayTeal;
  static const Color primaryDark           = bayTealHover;
  static const Color primaryContainer      = bayTealContainer;
  static const Color secondary             = turmericGold;

  static const Color outline               = darkHairline;
  static const Color outlineStrong         = darkHairlineStrong;
  static const Color outlineElevated       = darkHairlineElevated;

  static const Color textPrimary           = darkInk;
  static const Color textSecondary         = darkInkMuted;
  static const Color textMuted             = darkInkSubtle;
  static const Color textFaint             = darkInkFaint;

  // Legacy aliases (kept for call-site compatibility)
  static const Color accent                = bayTeal;
  static const Color accentDark            = bayTealHover;
  static const Color like                  = turmericGold;   // heart = gold
  static const Color orange                = turmericGold;
  static const Color pink                  = bayTealLight;
  static const Color cyberCyan             = bayTealLight;
  static const Color error                 = statusDanger;

  // Legacy indigo aliases (redirected to teal)
  static const Color accentIndigo          = bayTeal;
  static const Color accentIndigoHover     = bayTealLight;
  static const Color accentIndigoPressed   = bayTealHover;
  static const Color accentContainer       = bayTealContainer;

  // ─── Semantic Tokens (Light) ─────────────────────────────────────────────────
  static const Color lightBackground       = lightCanvas;
  static const Color lightSurface          = lightSurface0;
  static const Color lightSurfaceHigh      = lightSurfaceSunken;
  static const Color lightSurfaceHighest   = lightSurfaceHighestVal;

  static const Color lightPrimary          = lightTeal;
  static const Color lightPrimaryDark      = lightTealHover;
  static const Color lightPrimaryContainer = lightTealContainer;
  static const Color lightSecondary        = lightGold;

  static const Color lightOutline          = lightHairline;
  static const Color lightOutlineStrong    = lightHairlineStrong;

  static const Color lightTextPrimary      = lightInk;
  static const Color lightTextSecondary    = lightInkMuted;
  static const Color lightTextMuted        = lightInkSubtle;
  static const Color lightTextFaint        = lightInkFaint;

  static const Color lightLike             = lightGold;

  // ─── Gradient Definitions ────────────────────────────────────────────────────
  /// Brand gradient: Deep Bay Teal → Turmeric Gold (used for avatar halos, brand G)
  static const LinearGradient brandGradient = LinearGradient(
    colors: [bayTeal, turmericGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [bayTeal, bayTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
    colors: [lightTeal, lightTeal],
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

  // ─── Shadows — teal glow per Bay & Gold Coastal spec ─────────────────────────
  static List<BoxShadow> cardShadowDark = const [];   // flat + teal hairline

  static List<BoxShadow> cardShadowLight = const [];  // flat + teal hairline

  static List<BoxShadow> glowShadowDark = [
    BoxShadow(
      color: bayTeal.withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glowShadowLight = [
    BoxShadow(
      color: lightTeal.withValues(alpha: 0.18),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> avatarGlowDark = [
    BoxShadow(
      color: bayTeal.withValues(alpha: 0.35),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> avatarGlowLight = [
    BoxShadow(
      color: lightTeal.withValues(alpha: 0.25),
      blurRadius: 8,
      spreadRadius: 0.5,
    ),
  ];

  // Bottom sheet / dialog shadow
  static const List<BoxShadow> sheetShadow = [
    BoxShadow(
      color: Color(0xA6000000), // ~65% black per spec
      blurRadius: 32,
      offset: Offset(0, -12),
      spreadRadius: -4,
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
