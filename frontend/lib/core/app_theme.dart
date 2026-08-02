import 'package:flutter/material.dart';

// ─────────────────────────── Color Tokens ────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Dark palette (AI/ML Engineer - Professional Green Theme) ──────────────
  static const Color darkBackground = Color(0xFF020617);      // Deep dark
  static const Color darkSurface = Color(0xFF0B1220);         // Slightly lighter
  static const Color darkCard = Color(0xFF0F172A);            // Card surfaces
  static const Color darkCardHover = Color(0xFF1E293B);       // Card hover state
  static const Color darkPrimary = Color(0xFF22C55E);         // Professional green
  static const Color darkPrimaryLight = Color(0xFF4ADE80);    // Light green
  static const Color darkAccent = Color(0xFF06B6D4);          // Cyan/Teal
  static const Color darkAccentAlt = Color(0xFFF97316);       // Orange for highlights
  static const Color darkText = Color(0xFFE5E7EB);            // Primary text
  static const Color darkTextMuted = Color(0xFF9CA3AF);       // Secondary text
  static const Color darkBorder = Color(0xFF1E293B);          // Borders

  // ── Light palette ─────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightPrimary = Color(0xFF16A34A);        // Green
  static const Color lightPrimaryLight = Color(0xFF22C55E);
  static const Color lightAccent = Color(0xFF0891B2);         // Cyan
  static const Color lightAccentAlt = Color(0xFFEA580C);      // Orange
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ── Semantic helpers ──────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
}

// ─────────────────────────── Spacing System ──────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 80;      // Section padding
  static const double sectionMobile = 48;

  // Card padding
  static const double cardPadding = 24;
  static const double cardPaddingMobile = 16;

  // Grid spacing
  static const double gridGap = 24;
  static const double gridGapMobile = 16;
}

// ─────────────────────────── Border Radius ───────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;
}

// ─────────────────────────── Runtime resolver ─────────────────────────────────
class AppThemeData {
  final bool isDark;
  const AppThemeData(this.isDark);

  // ── Colors ────────────────────────────────────────
  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get surface =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get card => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get cardHover =>
      isDark ? AppColors.darkCardHover : AppColors.lightCardHover;
  Color get primary => isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get primaryLight =>
      isDark ? AppColors.darkPrimaryLight : AppColors.lightPrimaryLight;
  Color get accent => isDark ? AppColors.darkAccent : AppColors.lightAccent;
  Color get accentAlt =>
      isDark ? AppColors.darkAccentAlt : AppColors.lightAccentAlt;
  Color get text => isDark ? AppColors.darkText : AppColors.lightText;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;

  // ── Gradients ─────────────────────────────────────
  LinearGradient get primaryGradient => isDark
      ? const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight)
      : const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);

  LinearGradient get accentGradient => isDark
      ? const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight)
      : const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);

  LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF0B1220), Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter)
      : const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);

  LinearGradient get heroGradient => isDark
      ? const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight)
      : const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);

  // ── Glows & Shadows ───────────────────────────────
  BoxShadow get primaryGlow => isDark
      ? BoxShadow(
          color: AppColors.darkPrimary.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 0)
      : BoxShadow(
          color: AppColors.lightPrimary.withValues(alpha: 0.2),
          blurRadius: 16,
          spreadRadius: 0);

  BoxShadow get accentGlow => isDark
      ? BoxShadow(
          color: AppColors.darkAccent.withValues(alpha: 0.25), blurRadius: 16)
      : BoxShadow(
          color: AppColors.lightAccent.withValues(alpha: 0.15), blurRadius: 12);

  BoxShadow get cardShadow => BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4));

  BoxShadow get cardShadowHover => BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
      blurRadius: 30,
      offset: const Offset(0, 8));

  // ── Text Styles ───────────────────────────────────
  TextStyle get headingXL => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: text,
        height: 1.1,
        letterSpacing: -1,
      );

  TextStyle get headingLG => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.2,
        letterSpacing: -0.5,
      );

  TextStyle get headingMD => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: text,
        height: 1.3,
      );

  TextStyle get headingSM => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: text,
        height: 1.4,
      );

  TextStyle get bodyLG => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.7,
      );

  TextStyle get bodyMD => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.6,
      );

  TextStyle get bodySM => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.5,
      );

  TextStyle get labelMD => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: text,
        letterSpacing: 0.5,
      );

  TextStyle get labelSM => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.5,
      );
}

// ─────────────────────────── AppTheme ─────────────────────────────────────────
class AppTheme {
  AppTheme._();

  /// Resolves the correct [AppThemeData] from the build context.
  static AppThemeData of(BuildContext context) {
    // Force dark mode for this portfolio
    return const AppThemeData(true);
  }

  static ThemeData light() => _buildTheme(isDark: false);
  static ThemeData dark() => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final colors = AppThemeData(isDark);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      surface: colors.card,
      onSurface: colors.text,
      error: AppColors.error,
      onError: Colors.white,
    ).copyWith(
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.accent,
      onSecondary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme,
      fontFamily: 'Inter',
      textTheme: TextTheme(
        displayLarge: colors.headingXL,
        displayMedium: colors.headingLG,
        headlineLarge: colors.headingLG,
        headlineMedium: colors.headingMD,
        headlineSmall: colors.headingSM,
        bodyLarge: colors.bodyLG,
        bodyMedium: colors.bodyMD,
        bodySmall: colors.bodySM,
        labelLarge: colors.labelMD,
        labelMedium: colors.labelSM,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerColor: colors.border,
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
    );
  }
}
