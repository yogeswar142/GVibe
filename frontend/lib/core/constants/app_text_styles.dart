import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// GVibe Typography System — Bay & Gold Coastal (V3)
/// Display / Headline face: Space Grotesk (bold, tracked) — headers, scores, nav hero.
/// Body / Label face: Plus Jakarta Sans (humanistic, readable) — feeds, chat, profile.
///
/// Weight discipline: 700 display · 600 headlines · 600 labels · 400 body. 
/// All existing variable names preserved — call sites unchanged.
class AppTextStyles {
  AppTextStyles._();

  // ─── Display — Space Grotesk 700 ─────────────────────────────────────────────
  // spec: display-lg 36px/44px w700, mobile 28px/34px
  static TextStyle displayXl = GoogleFonts.spaceGrotesk(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.68, // -0.02em tight for large headings
    height: 1.18,
    color: AppColors.textPrimary,
  );

  static TextStyle displayLg = GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
    height: 34 / 28,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMd = GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.56,
    height: 34 / 28,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySm = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.44,
    height: 28 / 22,
    color: AppColors.textPrimary,
  );

  // ─── Headlines — Space Grotesk 600 ───────────────────────────────────────────
  // spec: headline-lg 24px/30px w700, headline-md 20px/26px w600
  static TextStyle headlineLg = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.18,
    height: 24 / 18,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMd = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 22 / 16,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineSm = GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // ─── Body — Plus Jakarta Sans 400 ────────────────────────────────────────────
  // spec: body-lg 16px/24px w400, body-md 14px/20px w400
  static TextStyle bodyLg = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMd = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // spec: body-sm 12px/16px w400
  static TextStyle bodySm = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  static TextStyle bodyXs = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // ─── Mono — kept for @handles, timestamps (Space Grotesk tabular fallback) ───
  static TextStyle monoLg = GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  static TextStyle monoMd = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  static TextStyle monoSm = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.textSecondary,
    letterSpacing: 0,
  );

  static TextStyle monoXs = GoogleFonts.spaceGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0,
  );

  // ─── UI Labels — Plus Jakarta Sans 600 ───────────────────────────────────────
  // spec: label-md 12px/16px w600, label-lg 14px/20px w600
  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  static TextStyle labelLg = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─── Button — Plus Jakarta Sans 600 ──────────────────────────────────────────
  static TextStyle buttonPrimary = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    letterSpacing: 0,
    color: AppColors.white,
  );

  static TextStyle buttonSecondary = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    letterSpacing: 0,
    color: AppColors.primary,
  );

  // ─── Tab Labels — Plus Jakarta Sans ──────────────────────────────────────────
  static TextStyle tabActive = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.primary,
  );

  static TextStyle tabInactive = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textMuted,
  );
}
