import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display — Clash Display (using Google Fonts: Bebas Neue as closest available)
  static TextStyle displayXl = GoogleFonts.bebasNeue(
    fontSize: 72,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle displayLg = GoogleFonts.bebasNeue(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMd = GoogleFonts.bebasNeue(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySm = GoogleFonts.bebasNeue(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // Body — Syne
  static TextStyle bodyLg = GoogleFonts.syne(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMd = GoogleFonts.syne(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySm = GoogleFonts.syne(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Mono — Space Mono
  static TextStyle monoLg = GoogleFonts.spaceMono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );

  static TextStyle monoMd = GoogleFonts.spaceMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle monoSm = GoogleFonts.spaceMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle monoXs = GoogleFonts.spaceMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );

  // Button text — Space Mono, all-caps
  static TextStyle buttonPrimary = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
    color: AppColors.accentDark,
  );

  static TextStyle buttonSecondary = GoogleFonts.spaceMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.0,
    color: AppColors.accent,
  );

  // Label
  static TextStyle label = GoogleFonts.spaceMono(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );
}
