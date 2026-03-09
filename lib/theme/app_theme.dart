import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const gold = Color(0xFFCBA830);
  static const goldLight = Color(0xFFE5C85A);
  static const goldDark = Color(0xFF8B6914);
  static const goldDim = Color(0xFFB8972A);
  static const warmWhite = Color(0xFFF5EDD8);
  static const warmBg = Color(0xFFF9F3E8);
  static const paperBg = Color(0xFFF5EDD8);
  static const darkBg = Color(0xFF0D0A04);
}

extension AppThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.darkBg : AppColors.warmBg;
  Color get surface => isDark ? const Color(0xFF1A1508) : Colors.white;
  Color get surface2 => isDark ? const Color(0xFF120F04) : const Color(0xFFF0E8D4);
  Color get text => isDark ? AppColors.warmWhite : const Color(0xFF1A1208);
  Color get textDim => isDark ? const Color(0xFF706050) : const Color(0xFF9A8060);
  Color get border => isDark ? const Color(0xFF2A2010) : const Color(0xFFD4C090);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.warmBg,
    textTheme: GoogleFonts.notoSerifTextTheme(),
    colorScheme: const ColorScheme.light(
      primary: AppColors.gold,
      secondary: AppColors.goldDark,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    textTheme: GoogleFonts.notoSerifTextTheme(ThemeData.dark().textTheme),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      secondary: AppColors.goldLight,
    ),
  );
}
