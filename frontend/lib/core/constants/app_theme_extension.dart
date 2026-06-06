import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom ThemeExtension holding semantic tokens beyond standard Material ColorScheme.
/// Used for: outline, textMuted, like, surfaceHighest, gradients, shadows.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.outline,
    required this.textMuted,
    required this.like,
    required this.surfaceHighest,
    required this.primaryContainer,
    required this.primaryGradient,
    required this.profileHeaderGradient,
    required this.cardShadow,
    required this.glowShadow,
    required this.avatarGlow,
    required this.subtleBackground,
  });

  final Color outline;
  final Color textMuted;
  final Color like;
  final Color surfaceHighest;
  final Color primaryContainer;
  final LinearGradient primaryGradient;
  final LinearGradient profileHeaderGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> glowShadow;
  final List<BoxShadow> avatarGlow;
  final LinearGradient subtleBackground;

  // ─── Dark Theme Extension ──────────────────────────────────────────────────
  static const AppThemeExtension dark = AppThemeExtension(
    outline:              AppColors.outline,
    textMuted:            AppColors.textMuted,
    like:                 AppColors.like,
    surfaceHighest:       AppColors.surfaceHighest,
    primaryContainer:     AppColors.primaryContainer,
    primaryGradient:      AppColors.primaryGradient,
    profileHeaderGradient: AppColors.profileHeaderGradientDark,
    cardShadow:           const [
      BoxShadow(color: Color(0x59000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
    glowShadow:           const [
      BoxShadow(color: Color(0x33007366), blurRadius: 20),
    ],
    avatarGlow:           const [
      BoxShadow(color: Color(0x59007366), blurRadius: 12, spreadRadius: 2),
    ],
    subtleBackground:     AppColors.subtleDarkGradient,
  );

  // ─── Light Theme Extension ─────────────────────────────────────────────────
  static const AppThemeExtension light = AppThemeExtension(
    outline:              AppColors.lightOutline,
    textMuted:            AppColors.lightTextMuted,
    like:                 AppColors.lightLike,
    surfaceHighest:       AppColors.lightSurfaceHighest,
    primaryContainer:     AppColors.lightPrimaryContainer,
    primaryGradient:      AppColors.primaryGradientLight,
    profileHeaderGradient: AppColors.profileHeaderGradientLight,
    cardShadow:           const [
      BoxShadow(color: Color(0x0F007366), blurRadius: 20, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x0A000000), blurRadius: 8,  offset: Offset(0, 2)),
    ],
    glowShadow:           const [
      BoxShadow(color: Color(0x26007366), blurRadius: 16),
    ],
    avatarGlow:           const [
      BoxShadow(color: Color(0x3D007366), blurRadius: 10, spreadRadius: 1),
    ],
    subtleBackground:     AppColors.subtleLightGradient,
  );

  @override
  AppThemeExtension copyWith({
    Color? outline,
    Color? textMuted,
    Color? like,
    Color? surfaceHighest,
    Color? primaryContainer,
    LinearGradient? primaryGradient,
    LinearGradient? profileHeaderGradient,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? glowShadow,
    List<BoxShadow>? avatarGlow,
    LinearGradient? subtleBackground,
  }) {
    return AppThemeExtension(
      outline:              outline ?? this.outline,
      textMuted:            textMuted ?? this.textMuted,
      like:                 like ?? this.like,
      surfaceHighest:       surfaceHighest ?? this.surfaceHighest,
      primaryContainer:     primaryContainer ?? this.primaryContainer,
      primaryGradient:      primaryGradient ?? this.primaryGradient,
      profileHeaderGradient: profileHeaderGradient ?? this.profileHeaderGradient,
      cardShadow:           cardShadow ?? this.cardShadow,
      glowShadow:           glowShadow ?? this.glowShadow,
      avatarGlow:           avatarGlow ?? this.avatarGlow,
      subtleBackground:     subtleBackground ?? this.subtleBackground,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other == null) return this;
    return AppThemeExtension(
      outline:          Color.lerp(outline, other.outline, t)!,
      textMuted:        Color.lerp(textMuted, other.textMuted, t)!,
      like:             Color.lerp(like, other.like, t)!,
      surfaceHighest:   Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      primaryGradient:  LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      profileHeaderGradient: LinearGradient.lerp(
        profileHeaderGradient, other.profileHeaderGradient, t)!,
      cardShadow:       t < 0.5 ? cardShadow : other.cardShadow,
      glowShadow:       t < 0.5 ? glowShadow : other.glowShadow,
      avatarGlow:       t < 0.5 ? avatarGlow : other.avatarGlow,
      subtleBackground: LinearGradient.lerp(subtleBackground, other.subtleBackground, t)!,
    );
  }
}

/// Convenience extension to access AppThemeExtension from BuildContext.
extension AppThemeExtensionX on BuildContext {
  AppThemeExtension get ext =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.dark;
}
