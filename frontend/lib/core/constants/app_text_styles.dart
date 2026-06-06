import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// GVibe Premium Typography System
/// Display: DM Serif Display — royal, editorial weight for headlines
/// Body: Inter — clean, readable, warm
/// Mono: DM Mono — technical precision for timestamps/counts
class AppTextStyles {
  AppTextStyles._();

  // ─── Display — DM Serif Display ─────────────────────────────────────────────
  static TextStyle displayXl = GoogleFonts.dmSerifDisplay(
    fontSize: 48,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
  );

  static TextStyle displayLg = GoogleFonts.dmSerifDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMd = GoogleFonts.dmSerifDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySm = GoogleFonts.dmSerifDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // ─── Headlines — Inter Bold ───────────────────────────────────────────────
  static TextStyle headlineLg = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineSm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  // ─── Body — Inter ─────────────────────────────────────────────────────────
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static TextStyle bodyXs = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // ─── Mono — DM Mono ───────────────────────────────────────────────────────
  static TextStyle monoLg = GoogleFonts.dmMono(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle monoMd = GoogleFonts.dmMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle monoSm = GoogleFonts.dmMono(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle monoXs = GoogleFonts.dmMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.1,
  );

  // ─── UI Labels — Inter Semibold ───────────────────────────────────────────
  static TextStyle label = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  // ─── Button ───────────────────────────────────────────────────────────────
  static TextStyle buttonPrimary = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.white,
  );

  static TextStyle buttonSecondary = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.primary,
  );

  // ─── Tab Labels ───────────────────────────────────────────────────────────
  static TextStyle tabActive = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.primary,
  );

  static TextStyle tabInactive = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textMuted,
  );
}
