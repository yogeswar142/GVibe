import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme_extension.dart';

/// GVibe ThemeData — Bay & Gold Coastal (V3)
/// Primary: Deep Bay Teal #0D9488 · Secondary micro-accent: Turmeric Gold #D97706
/// Dark canvas: #080C0B · Light canvas: #F5FAF9
/// Radius: base=8 · container=16 · sheet=24 · pill=999
/// Elevation: flat + teal hairline everywhere; only sheets/dialogs float.
class AppTheme {
  AppTheme._();

  // ─── Dark Theme ─────────────────────────────────────────────────────────────
  static final ThemeData darkTheme = _buildDarkTheme();
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background, // #080C0B

      colorScheme: const ColorScheme.dark(
        surface:                   AppColors.surface,          // #0D1412
        surfaceContainerHighest:   AppColors.surfaceHighest,   // #182220
        surfaceContainerHigh:      AppColors.surfaceHigh,      // #131C1A
        primary:                   AppColors.primary,          // #0D9488 Bay Teal
        primaryContainer:          AppColors.primaryContainer, // #0A2D2A
        secondary:                 AppColors.secondary,        // #D97706 Turmeric Gold
        onPrimary:                 AppColors.white,
        onSecondary:               AppColors.darkCanvas,
        onSurface:                 AppColors.textPrimary,      // #E8F4F2
        onSurfaceVariant:          AppColors.textSecondary,    // #7A9E9A
        error:                     AppColors.error,            // #FF6B6B
        outline:                   AppColors.outline,          // teal hairline
        outlineVariant:            AppColors.outlineStrong,
      ),

      extensions: const [AppThemeExtension.dark],

      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // ── AppBar: canvas bg, zero elevation ─────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:     AppColors.background,
        foregroundColor:     AppColors.textPrimary,
        elevation:           0,
        scrolledUnderElevation: 0,
        surfaceTintColor:    Colors.transparent,
        shadowColor:         Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:               Colors.transparent,
          statusBarIconBrightness:      Brightness.light,
          systemNavigationBarColor:     AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      // ── Input: surface-2 fill, teal hairline border, radius 8px, teal focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh, // #131C1A
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // 2px teal ring at 15% opacity + focus ring per spec
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMuted, // #3D5C58
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Button (primary): Bay Teal fill, white text, radius 8px ──────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,   // #0D9488
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Button (secondary): surface-2 fill, teal outline ─────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surfaceHigh,
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.outlineElevated, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Card: surface-1 bg, teal hairline, radius 16px (container) ────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Divider: teal hairline ─────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // ── Chip: pill radius, selected = teal fill ───────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,  // #131C1A inactive
        selectedColor:   AppColors.primary,       // #0D9488 active fill
        disabledColor:   AppColors.surfaceHighest,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary, // #7A9E9A
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        side: const BorderSide(color: AppColors.outline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999), // pill
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Bottom sheet: surface-3 bg, teal elevated border, large radius ────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHighest, // #182220
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // large per spec
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        dragHandleColor: AppColors.outlineStrong,
      ),

      // ── Navigation bar: canvas bg, teal active, no pill indicator ─────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,  // canvas so it blends
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primary : AppColors.textMuted,
            size: 22,
          );
        }),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = _buildLightTheme();
  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground, // #F5FAF9

      colorScheme: const ColorScheme.light(
        surface:                   AppColors.lightSurface,           // #FFFFFF
        surfaceContainerHighest:   AppColors.lightSurfaceHighest,    // #E0EFEC
        surfaceContainerHigh:      AppColors.lightSurfaceHigh,       // #EDF7F5
        primary:                   AppColors.lightPrimary,           // #0F766E
        primaryContainer:          AppColors.lightPrimaryContainer,  // #CCF0EB
        secondary:                 AppColors.lightSecondary,         // #B45309
        onPrimary:                 AppColors.white,
        onSecondary:               AppColors.white,
        onSurface:                 AppColors.lightTextPrimary,       // #0C1F1D
        onSurfaceVariant:          AppColors.lightTextSecondary,     // #3D6B66
        error:                     AppColors.lightStatusDanger,      // #DC2626
        outline:                   AppColors.lightOutline,           // #DDF0EC
        outlineVariant:            AppColors.lightOutlineStrong,     // #B8DDD8
      ),

      extensions: const [AppThemeExtension.light],

      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:     AppColors.lightBackground, // #F5FAF9
        foregroundColor:     AppColors.lightTextPrimary,
        elevation:           0,
        scrolledUnderElevation: 0,
        surfaceTintColor:    Colors.transparent,
        shadowColor:         Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:               Colors.transparent,
          statusBarIconBrightness:      Brightness.dark,
          systemNavigationBarColor:     AppColors.lightBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface, // clean white input
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.lightPrimary.withValues(alpha: 0.30),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightStatusDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightStatusDanger, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,  // #0F766E
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // consistent 8px both themes
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          backgroundColor: AppColors.lightSurface,
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.lightOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightOutline,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceHigh,
        selectedColor:   AppColors.lightPrimary,     // #0F766E active
        disabledColor:   AppColors.lightSurfaceHighest,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        side: const BorderSide(color: AppColors.lightOutline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        dragHandleColor: AppColors.lightOutlineStrong,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground, // #F5FAF9
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColors.lightPrimary : AppColors.lightTextMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.lightPrimary : AppColors.lightTextMuted,
            size: 22,
          );
        }),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
