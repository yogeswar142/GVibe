import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme_extension.dart';

/// GVibe ThemeData — Dark-navy cinematic + Vercel hairline-on-white light mode.
/// Design tokens from GVIBE_REDESIGN.md.
/// Radius: xs=6 · sm=10 · md=14 · lg=20 · pill=999.
/// Spacing base 4px. Screen edge 20. Card padding 16.
/// Elevation: flat + hairline everywhere; only sheets/dialogs float.
class AppTheme {
  AppTheme._();

  // ─── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background, // #070B14

      colorScheme: const ColorScheme.dark(
        surface:                   AppColors.surface,          // #0D1220
        surfaceContainerHighest:   AppColors.surfaceHighest,   // #1A2236
        surfaceContainerHigh:      AppColors.surfaceHigh,      // #131A2B
        primary:                   AppColors.primary,          // #6C7BF7
        primaryContainer:          AppColors.primaryContainer, // #1A1F4D
        secondary:                 AppColors.secondary,        // #8792FF
        onPrimary:                 AppColors.white,
        onSecondary:               AppColors.white,
        onSurface:                 AppColors.textPrimary,      // #F4F6FA
        onSurfaceVariant:          AppColors.textSecondary,    // #C2C9D9
        error:                     AppColors.error,            // #F0555A
        outline:                   AppColors.outline,          // #212A3D
        outlineVariant:            AppColors.outlineStrong,    // #2E3850
      ),

      extensions: const [AppThemeExtension.dark],

      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // ── AppBar: canvas bg, zero elevation; hairline shown by scroll ────────
      appBarTheme: const AppBarTheme(
        backgroundColor:     AppColors.background,  // canvas
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

      // ── Input: surface-2 fill, hairline border, radius sm=8, accent focus ─
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh, // surface-2
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // sm
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // 2px accent ring at 30% opacity — no fill-color change on focus
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
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted, // ink-subtle
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary, // ink-muted
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Button (primary): accent fill, on-accent text, radius md=8, 44px ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,   // #5E6AD2
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 44), // spec: 44px min tap
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // md
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500, // button token
          ),
        ),
      ),

      // ── Button (secondary): surface-2 fill, ink text, 1px hairline ────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surfaceHigh, // surface-2
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Card: surface-1 bg, 1px hairline, radius lg=12, 0 elevation ────────
      cardTheme: CardThemeData(
        color: AppColors.surface, // surface-1 #0F1011
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // lg
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Divider: hairline everywhere ───────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,  // #212A3D
        thickness: 1,
        space: 1,
      ),

      // ── Chip: pill radius, selected = accent fill ──────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,  // surface-2 default
        selectedColor:   AppColors.primary,       // accent when selected
        disabledColor:   AppColors.surfaceHighest,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.white, // on-accent
        ),
        side: const BorderSide(color: AppColors.outline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999), // pill
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Bottom sheet: surface-3 bg, floating shadow per spec ──────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceHighest, // surface-3 #1A2236
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        dragHandleColor: AppColors.outlineStrong,
      ),

      // ── Navigation bar: surface-1 bg, hairline top, active = accent only ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface, // surface-1
        indicatorColor: Colors.transparent, // no pill bg — just color shift
        indicatorShape: const RoundedRectangleBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
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
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground, // #FAFAFA

      colorScheme: const ColorScheme.light(
        surface:                   AppColors.lightSurface,           // #FFFFFF
        surfaceContainerHighest:   AppColors.lightSurfaceHighest,
        surfaceContainerHigh:      AppColors.lightSurfaceHigh,       // #F2F3F5
        primary:                   AppColors.lightPrimary,           // #5B63F0
        primaryContainer:          AppColors.lightPrimaryContainer,  // #EBEBFD
        secondary:                 AppColors.lightSecondary,         // #4750D6
        onPrimary:                 AppColors.white,
        onSecondary:               AppColors.white,
        onSurface:                 AppColors.lightTextPrimary,       // #14161C
        onSurfaceVariant:          AppColors.lightTextSecondary,     // #4B4F5A
        error:                     AppColors.lightStatusDanger,      // #D93A3F
        outline:                   AppColors.lightOutline,           // #E7E8EC
        outlineVariant:            AppColors.lightOutlineStrong,     // #D7D9E0
      ),

      extensions: const [AppThemeExtension.light],

      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:     AppColors.lightBackground, // #FAFAFA canvas
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
        fillColor: AppColors.lightSurface, // Vercel: clean white card elevated input
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), // sm
          borderSide: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: AppColors.lightPrimary.withValues(alpha: 0.30),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.lightStatusDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.lightStatusDanger, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.lightTextMuted, // ink-subtle
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.lightTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,  // #171717 (stark black)
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Vercel pill
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          backgroundColor: AppColors.lightSurface, // Vercel: white button
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppColors.lightOutline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Vercel pill
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface, // #FFFFFF
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Vercel md card
          side: const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightOutline, // #E7E8EC
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceHigh,   // surface-sunken default
        selectedColor:   AppColors.lightPrimary,        // accent when selected
        disabledColor:   AppColors.lightSurfaceHighest,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        side: const BorderSide(color: AppColors.lightOutline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999), // pill
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface, // #FFFFFF
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        dragHandleColor: AppColors.lightOutlineStrong,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface, // #FFFFFF
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
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
