import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// GVibe Typography System
/// UI face: Inter (google_fonts) — matches spec exactly.
/// Mono face: JetBrains Mono (google_fonts) — reserved for @handles,
/// timestamps, counts only. Not a workhorse face.
///
/// Weight discipline: 600 headers · 500 buttons/labels · 400 body. No others.
/// All existing variable names preserved — call sites unchanged.
class AppTextStyles {
  AppTextStyles._();

  // ─── Display — Inter 600 ─────────────────────────────────────────────────────
  // spec: display 28/34 w600 -0.4 (Tighter tracking for premium feel)
  static TextStyle displayXl = GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    height: 1.18,
    color: AppColors.textPrimary,
  );

  static TextStyle displayLg = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    height: 34 / 28,
    color: AppColors.textPrimary,
  );

  // Mapped to spec "display" token: 28/34 w600 -0.4
  static TextStyle displayMd = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    height: 34 / 28,
    color: AppColors.textPrimary,
  );

  // Mapped to spec "title-lg" token: 22/28 w600 -0.3
  static TextStyle displaySm = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 28 / 22,
    color: AppColors.textPrimary,
  );

  // ─── Headlines — Inter 600 ────────────────────────────────────────────────────
  // spec: title 18/24 w600 -0.2
  static TextStyle headlineLg = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 24 / 18,
    color: AppColors.textPrimary,
  );

  // spec: body-lg 16/22 w400 0 (used as sub-section heading here)
  static TextStyle headlineMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 22 / 16,
    color: AppColors.textPrimary,
  );

  // spec: body 14/20 label variant
  static TextStyle headlineSm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // ─── Body — Inter 400 ─────────────────────────────────────────────────────────
  // spec: body-lg 16/22 w400 0
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 22 / 16,
    color: AppColors.textPrimary,
  );

  // spec: body 14/20 w400 0
  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // spec: caption 12/16 w400 0
  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  // Sub-caption / helper
  static TextStyle bodyXs = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // ─── Mono — JetBrains Mono 500 ────────────────────────────────────────────────
  // spec: mono-tag 12/16 w500 mono — @handles, timestamps, counters ONLY
  static TextStyle monoLg = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  static TextStyle monoMd = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0,
  );

  // spec: mono-tag 12/16 w500
  static TextStyle monoSm = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.textSecondary,
    letterSpacing: 0,
  );

  static TextStyle monoXs = GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0,
  );

  // ─── UI Labels — Inter 500 ────────────────────────────────────────────────────
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ─── Button — Inter 500, spec: button 15/20 w500 ──────────────────────────────
  static TextStyle buttonPrimary = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 20 / 15,
    letterSpacing: 0,
    color: AppColors.white,
  );

  static TextStyle buttonSecondary = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 20 / 15,
    letterSpacing: 0,
    color: AppColors.primary,
  );

  // ─── Tab Labels ───────────────────────────────────────────────────────────────
  static TextStyle tabActive = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.primary,
  );

  static TextStyle tabInactive = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textMuted,
  );
}
