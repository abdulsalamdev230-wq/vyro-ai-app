/// VYRO AI — Midnight Future Design System
///
/// Visual identity:
///   Background:        #0B1220  midnight navy
///   Sidebar/elevated:  #101B35
///   Cards:             #17243B
///   Primary accent:    Electric Cyan #00D5FF
///   Secondary accent:  Violet #8855FF
///   Text:              #F8FAFC primary, #94A3B8 secondary
///   Borders:           #263750
///   Premium futuristic SaaS — clean surfaces, cyan highlights used
///   sparingly, no heavy neon or gradient noise.


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class VyroColors {
  // Backgrounds
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color backgroundDeep = Color(0xFF0A101C);
  static const Color surfaceCard = Color(0xFF17243B);
  static const Color surfaceElevated = Color(0xFF101B35);
  static const Color surfaceInput = Color(0xFF101B35);

  // Secondary accent — violet
  static const Color primaryPurple = Color(0xFF8855FF);
  static const Color primaryPurpleLight = Color(0xFFA585FF);
  static const Color primaryPurpleDim = Color(0xFF6233EE);

  // Primary accent — electric cyan
  static const Color electricBlue = Color(0xFF00D5FF);
  static const Color electricBlueDim = Color(0xFF0284C7);

  // Accent pink
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPinkDim = Color(0xFFDB2777);

  // Gradients (used sparingly — hero moments only)
  static const List<Color> gradientPrimary = [
    Color(0xFF8855FF),
    Color(0xFF00D5FF),
  ];
  static const List<Color> gradientSunset = [
    Color(0xFF8855FF),
    Color(0xFFEC4899),
  ];
  static const List<Color> gradientOcean = [
    Color(0xFF00D5FF),
    Color(0xFF0EA5E9),
  ];
  static const List<Color> gradientNeon = [
    Color(0xFF8855FF),
    Color(0xFF00D5FF),
    Color(0xFFEC4899),
  ];

  // Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status / semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF00D5FF);

  // Accent borders / glows (kept subtle)
  static const Color neonPurple = Color(0x338855FF); // 20% opacity
  static const Color neonBlue = Color(0x3300D5FF);
  static const Color neonPink = Color(0x33EC4899);

  static const Color divider = Color(0xFF263750);
}

abstract class VyroBorderRadius {
  static const double cardSm = 16.0;
  static const double card = 20.0;
  static const double cardLg = 24.0;
  static const double cardXl = 28.0;
  static const double pill = 999.0;
  static const double button = 16.0;
}

abstract class VyroSpacing {
  static const double xs = 6.0;
  static const double sm = 12.0;
  static const double md = 18.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

abstract class VyroShadows {
  static const BoxShadow cardGlow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );
  static const BoxShadow neonPurpleGlow = BoxShadow(
    color: Color(0x148B5CF6),
    blurRadius: 14,
    spreadRadius: 0,
    offset: Offset(0, 0),
  );
  static const BoxShadow neonBlueGlow = BoxShadow(
    color: Color(0x1438BDF8),
    blurRadius: 14,
    spreadRadius: 0,
    offset: Offset(0, 0),
  );
  static const BoxShadow floatingOrb = BoxShadow(
    color: Color(0x258B5CF6),
    blurRadius: 28,
    spreadRadius: 1,
    offset: Offset(0, 0),
  );
}

abstract class VyroTypography {
  static const double h1 = 32;
  static const double h2 = 24;
    static const double h3 = 20;
  static const double title = 18;
  static const double body = 16;
  static const double caption = 13;
  static const double overline = 11;

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: h1,
    fontWeight: FontWeight.w700,
    color: VyroColors.textWhite,
    letterSpacing: -0.8,
    height: 1.1,
  );
  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: h2,
    fontWeight: FontWeight.w700,
    color: VyroColors.textWhite,
    letterSpacing: -0.6,
    height: 1.15,
  );
  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: h3,
    fontWeight: FontWeight.w700,
    color: VyroColors.textWhite,
    height: 1.2,
  );
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: title,
    fontWeight: FontWeight.w700,
    color: VyroColors.textWhite,
    height: 1.3,
  );
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: VyroColors.textWhite,
    height: 1.4,
  );
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: body,
    fontWeight: FontWeight.w400,
    color: VyroColors.textWhite.withValues(alpha: 0.9),
    height: 1.5,
  );
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: VyroColors.textMuted,
    height: 1.5,
  );
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: VyroColors.textWhite,
    letterSpacing: 0.2,
  );
  static TextStyle get captionMedium => GoogleFonts.inter(
    fontSize: caption,
    fontWeight: FontWeight.w400,
    color: VyroColors.textDim,
    height: 1.4,
  );
  static TextStyle get overlineSmall => GoogleFonts.inter(
    fontSize: overline,
    fontWeight: FontWeight.w600,
    color: VyroColors.primaryPurple,
    letterSpacing: 1.2,
  );
}

/// Builds the Vyro AI theme (dark, futuristic).
ThemeData vyroTheme(BuildContext context) {
  final brightness = Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: VyroColors.backgroundDark,
    colorScheme: ColorScheme.dark(
      brightness: brightness,
      primary: VyroColors.primaryPurple,
      secondary: VyroColors.electricBlue,
      tertiary: VyroColors.accentPink,
      surface: VyroColors.surfaceCard,
      onPrimary: VyroColors.textOnPrimary,
      onSecondary: VyroColors.textWhite,
      onTertiary: VyroColors.textWhite,
      onSurface: VyroColors.textWhite,
      error: VyroColors.error,
      onError: VyroColors.textWhite,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VyroColors.primaryPurple,
        foregroundColor: VyroColors.textWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VyroBorderRadius.button),
        ),
        textStyle: VyroTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: VyroColors.textWhite,
        side: const BorderSide(color: VyroColors.divider, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VyroBorderRadius.button),
        ),
        textStyle: VyroTypography.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VyroColors.primaryPurple,
        textStyle: VyroTypography.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VyroColors.surfaceInput,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      hintStyle: VyroTypography.bodyMedium.copyWith(
        color: VyroColors.textDim,
      ),
      labelStyle: VyroTypography.bodyMedium.copyWith(
        color: VyroColors.textMuted,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VyroBorderRadius.card),
        borderSide: const BorderSide(color: VyroColors.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VyroBorderRadius.card),
        borderSide: const BorderSide(
          color: VyroColors.primaryPurple,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VyroBorderRadius.card),
        borderSide: const BorderSide(color: VyroColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VyroBorderRadius.card),
        borderSide: const BorderSide(color: VyroColors.error, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: VyroColors.divider,
      space: 1,
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: VyroColors.backgroundDeep,
      selectedItemColor: VyroColors.primaryPurple,
      unselectedItemColor: VyroColors.textDim,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedIconTheme: IconThemeData(color: VyroColors.primaryPurple, size: 26),
      unselectedIconTheme: IconThemeData(color: VyroColors.textDim, size: 24),
    ),
    textTheme: TextTheme(
      displayLarge: VyroTypography.displayLarge,
      displayMedium: VyroTypography.displayMedium,
      headlineSmall: VyroTypography.headlineSmall,
      titleLarge: VyroTypography.titleLarge,
      titleMedium: VyroTypography.titleMedium,
      bodyLarge: VyroTypography.bodyLarge,
      bodyMedium: VyroTypography.bodyMedium,
      labelLarge: VyroTypography.labelLarge,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

/// Premium card decoration — solid surface, subtle border, soft shadow.
BoxDecoration vyroGlassCardDecoration({
  Color color = VyroColors.surfaceCard,
  double borderRadius = VyroBorderRadius.cardLg,
  BoxBorder? border,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(borderRadius),
    border: border ??
        Border.all(
          color: VyroColors.divider,
          width: 1,
        ),
    boxShadow: shadows ?? [VyroShadows.cardGlow],
  );
}

/// Accent border decoration — subtle, no glow halo.
BoxDecoration vyroNeonBorderDecoration({
  required double borderRadius,
  List<Color> colors = VyroColors.gradientPrimary,
  double strokeWidth = 1.5,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(borderRadius),
    gradient: LinearGradient(colors: colors),
  );
}
