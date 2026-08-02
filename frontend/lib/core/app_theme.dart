import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color card = Color(0xFF111111);
  static const Color border = Color(0xFF2A2A2A);
  static const Color text = Color(0xFFF6F4EF);
  static const Color textMuted = Color(0xFFB9B4AA);
  static const Color button = Color(0xFFFFB067);
  static const Color buttonSoft = Color(0x33FFB067);
  static const Color neonGreen = Color(0xFF7DFF6A);
  static const Color danger = Color(0xFFFF6B6B);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

class AppThemeData {
  const AppThemeData();

  Color get background => AppColors.background;
  Color get surface => AppColors.surface;
  Color get card => AppColors.card;
  Color get border => AppColors.border;
  Color get text => AppColors.text;
  Color get textMuted => AppColors.textMuted;
  Color get button => AppColors.button;
  Color get buttonSoft => AppColors.buttonSoft;
  Color get neonGreen => AppColors.neonGreen;

  TextStyle get display => const TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1,
        letterSpacing: -1.8,
      );

  TextStyle get heading => const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.1,
      );

  TextStyle get subheading => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      );

  TextStyle get body => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.6,
      );

  TextStyle get label => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.3,
      );
}

class AppTheme {
  AppTheme._();

  static AppThemeData of(BuildContext context) => const AppThemeData();

  static ThemeData dark() {
    const colors = AppThemeData();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.card,
        primary: AppColors.button,
        secondary: AppColors.neonGreen,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: AppColors.textMuted,
          height: 1.6,
        ),
      ),
    );
  }
}
