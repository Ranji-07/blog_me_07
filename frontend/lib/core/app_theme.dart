import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color backgroundDark = Color(0xFF090909);
  static const Color surfaceDark = Color(0xFF10100F);
  static const Color cardDark = Color(0xFF151412);
  static const Color borderDark = Color(0xFF302E2A);
  static const Color textDark = Color(0xFFF3F0E9);
  static const Color textMutedDark = Color(0xFFA9A49A);

  static const Color backgroundLight = Color(0xFFF7F3EC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFCF7);
  static const Color borderLight = Color(0xFFD8CCBC);
  static const Color textLight = Color(0xFF181512);
  static const Color textMutedLight = Color(0xFF62584B);

  static const Color button = Color(0xFFFFA85B);
  static const Color buttonSoft = Color(0x24FFA85B);
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
  final bool isDark;

  const AppThemeData.dark() : isDark = true;
  const AppThemeData.light() : isDark = false;

  Color get background =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get card => isDark ? AppColors.cardDark : AppColors.cardLight;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get text => isDark ? AppColors.textDark : AppColors.textLight;
  Color get textMuted =>
      isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
  Color get button => AppColors.button;
  Color get buttonSoft => AppColors.buttonSoft;
  Color get neonGreen => AppColors.neonGreen;

  TextStyle get display => GoogleFonts.outfit(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        color: text,
        height: 0.98,
        letterSpacing: -1.7,
      );

  TextStyle get heading => GoogleFonts.outfit(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.1,
      );

  TextStyle get subheading => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: text,
      );

  TextStyle get body => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.6,
      );

  TextStyle get label => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.3,
      );
}

class AppTheme {
  AppTheme._();

  static AppThemeData of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const AppThemeData.dark()
        : const AppThemeData.light();
  }

  static ThemeData dark() {
    return _themeData(const AppThemeData.dark(), Brightness.dark);
  }

  static ThemeData light() {
    return _themeData(const AppThemeData.light(), Brightness.light);
  }

  static ThemeData _themeData(AppThemeData colors, Brightness brightness) {
    final baseScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            surface: colors.card,
            primary: colors.button,
            secondary: colors.neonGreen,
            error: AppColors.danger,
          )
        : ColorScheme.light(
            surface: colors.card,
            primary: colors.button,
            secondary: colors.neonGreen,
            error: AppColors.danger,
          );

    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.manrope().fontFamily,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: baseScheme,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.card,
        contentTextStyle: TextStyle(color: colors.text),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colors.border),
        ),
        textStyle: TextStyle(
          color: colors.text,
          fontSize: 12,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        floatingLabelStyle: TextStyle(color: colors.button),
      ),
      textTheme: TextTheme(
        displayLarge: colors.display,
        headlineMedium: colors.heading,
        titleMedium: colors.subheading,
        bodyLarge: colors.body,
        labelLarge: colors.label,
      ),
    );
  }
}
