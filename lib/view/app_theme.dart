import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConstants {
  static const cardBorderRadius = 24.0;
  static const pillPadding = EdgeInsets.symmetric(vertical: 22, horizontal: 28);
}

class AppColors {
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F4);
  static const outline = Color(0xFFE8EAED);

  static const primary = Color(0xFF323232);
  static const secondary = Color(0xFF5F6368);
  static const dark = Color(0xFF202124);

  static const darkSurface = Color(0xFF3C4043);

  static const onSurface = Color(0xFF202124);
  static const onSurfaceVar = Color(0xFF5F6368);
  static const onSurfaceLight = Color(0xFF9AA0A6);

  static const error = Color(0xFFEA4335);
  static const onError = Colors.white;

  static const bgMid = Color(0xFFe5e5e7);
  static const bgEnd = Color(0xFFd6d7e0);
  static const backgroundGradient = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.5,
    stops: [0.0, 1.0],
    colors: [bgMid, bgEnd],
  );
}

final appTheme = ThemeData.light().copyWith(
  primaryTextTheme: GoogleFonts.poppinsTextTheme(),
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.dark,
    onTertiary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVar,
    error: AppColors.error,
    onError: AppColors.onError,
    outline: AppColors.outline,
  ),
  scaffoldBackgroundColor: Colors.transparent,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      textStyle: GoogleFonts.poppins().copyWith(fontWeight: FontWeight.w500),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: ThemeConstants.pillPadding,
    ).copyWith(elevation: WidgetStateProperty.all(0)),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  ),
  textTheme: ThemeData.light().textTheme.copyWith(
    bodyLarge: TextStyle(
      color: AppColors.onSurface,
      fontFamily: GoogleFonts.poppins().fontFamily,
    ),
    bodyMedium: TextStyle(
      color: AppColors.onSurfaceVar,
      fontFamily: GoogleFonts.poppins().fontFamily,
    ),
    bodySmall: TextStyle(
      color: AppColors.onSurfaceLight,
      fontFamily: GoogleFonts.poppins().fontFamily,
    ),
    headlineLarge: TextStyle(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w600,
      fontFamily: GoogleFonts.poppins().fontFamily,
    ),
    headlineMedium: TextStyle(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w500,
      fontFamily: GoogleFonts.poppins().fontFamily,
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      backgroundColor: Colors.white.withAlpha(80),
      foregroundColor: AppColors.onSurfaceVar,
      selectedBackgroundColor: AppColors.primary,
      selectedForegroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      side: BorderSide.none,
    ).copyWith(elevation: WidgetStateProperty.all(0)),
  ),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: AppColors.darkSurface,
  ),
);
