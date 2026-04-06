import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const gold = Color(0xFFCBA830);
  static const goldLight = Color(0xFFE5C85A);
  static const goldDark = Color(0xFF8B6914);
  static const goldDim = Color(0xFFB8972A);
  static const goldFaint = Color(0xFFF5E8C0);
  static const warmWhite = Color(0xFFF5EDD8);
  static const warmBg = Color(0xFFF9F3E8);
  static const paperBg = Color(0xFFF5EDD8);
  static const darkBg = Color(0xFF0D0A04);
  static const lightBorder2 = Color(0xFFE8D4A0);

  // Unified border colors — use these instead of raw hex
  static const goldBorder = Color(0xFFCEB060);      // light-mode gold border
  static const darkGoldBorder = Color(0xFF3A2E10);  // dark-mode gold border
  static const deepText = Color(0xFF2A1E08);        // deep warm text (light mode)
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 22;
}

class AppShadows {
  /// Subtle warm shadow for light-mode cards
  static List<BoxShadow> card(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFFCBA830).withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];

  /// Stronger shadow for elevated elements (popups, bottom sheets)
  static List<BoxShadow> elevated(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFFCBA830).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
}

class AppTextStyles {
  // Label styles (caps, spaced)
  static TextStyle label(Color color) =>
      TextStyle(fontSize: 9, letterSpacing: 2, fontFamily: 'sans-serif', color: color);

  // Section headers
  static TextStyle sectionHeader(Color color) =>
      TextStyle(fontSize: 16, fontFamily: 'serif', fontWeight: FontWeight.w600, color: color);

  // Card title
  static TextStyle cardTitle(Color color) =>
      TextStyle(fontSize: 14, fontFamily: 'serif', fontWeight: FontWeight.w600, color: color);

  // Body text
  static TextStyle body(Color color, {double fontSize = 13}) =>
      TextStyle(fontSize: fontSize, fontFamily: 'sans-serif', color: color);

  // Arabic display
  static TextStyle arabic(Color color, {double fontSize = 22}) =>
      TextStyle(fontSize: fontSize, fontFamily: 'Scheherazade', color: color);
}

extension AppThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.darkBg : AppColors.warmBg;
  Color get surface => isDark ? const Color(0xFF1A1508) : Colors.white;
  Color get surface2 => isDark ? const Color(0xFF120F04) : const Color(0xFFF0E8D4);
  Color get text => isDark ? AppColors.warmWhite : const Color(0xFF1A1208);
  Color get text2 => isDark ? AppColors.warmWhite : const Color(0xFF2A1E0E);
  Color get textDim => isDark ? const Color(0xFF706050) : const Color(0xFF9A8060);
  Color get border => isDark ? const Color(0xFF2A2010) : const Color(0xFFD4C090);
  Color get arabic => isDark ? const Color(0xFFF0E8D4) : const Color(0xFF1A0E00);
  Color get translit => isDark ? const Color(0xFF8A7A60) : const Color(0xFF5A4A30);
  Color get urduText => isDark ? const Color(0xFF908070) : const Color(0xFF4A3A20);
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
