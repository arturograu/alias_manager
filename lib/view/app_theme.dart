import 'package:flutter/material.dart';

class ThemeConstants {
  static const cardBorderRadius = 24.0;
  static const pillPadding = EdgeInsets.symmetric(vertical: 22, horizontal: 28);
}

class AppColors {
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F4);
  static const outline = Color(0xFFE8EAED);

  static const primary = Color(0xFF1A73E8); // blue accent
  static const secondary = Color(0xFF8AB4F8); // light blue
  static const tertiary = Color(0xFFC58AF9); // purple accent
  static const success = Color(0xFF81C995); // green from the interface
  static const accent = Color(0xFF9AA0A6); // neutral gray

  static const dark = Color(0xFF323232); // dark button/text
  static const darkSurface = Color(0xFF3C4043); // dark surfaces

  static const onSurface = Color(0xFF202124); // dark gray
  static const onSurfaceVar = Color(0xFF5F6368); // medium gray
  static const onSurfaceLight = Color(0xFF9AA0A6); // light gray

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

var appTheme = ThemeData.light().copyWith(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.dark,
    tertiary: AppColors.tertiary,
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
      backgroundColor: AppColors.dark,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: ThemeConstants.pillPadding,
    ).copyWith(elevation: WidgetStateProperty.all(0)),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      backgroundColor: AppColors.dark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  ),
  textTheme: ThemeData.light().textTheme.copyWith(
    bodyLarge: TextStyle(color: AppColors.onSurface),
    bodyMedium: TextStyle(color: AppColors.onSurfaceVar),
    bodySmall: TextStyle(color: AppColors.onSurfaceLight),
    headlineLarge: TextStyle(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w500,
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
);
