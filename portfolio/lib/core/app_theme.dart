import 'package:flutter/material.dart';

// ─────────────────────────── Color Tokens ────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Dark palette ──────────────────────────────────
  static const Color darkBackground = Color(0xFF0B0F14);
  static const Color darkCard = Color(0xFF141A22);
  static const Color darkPrimary = Color(0xFF22C55E); // green
  static const Color darkAccent = Color(0xFFF97316); // orange
  static const Color darkText = Color(0xFFE6EDF3);
  static const Color darkTextMuted = Color(0xFF8B9EB7);
  static const Color darkBorder = Color(0xFF2A3441);

  // ── Light palette ─────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF2563EB); // blue
  static const Color lightAccent = Color(0xFF64748B); // grey
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ── Semantic helpers ──────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color error = Color(0xFFEF4444);
}

// ─────────────────────────── Runtime resolver ─────────────────────────────────
/// Use [AppTheme.of(context)] anywhere in the widget tree to get the correct
/// color set for the current OS mode without writing conditionals everywhere.
class AppThemeData {
  final bool isDark;
  const AppThemeData(this.isDark);

  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get card => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get primary => isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get accent => isDark ? AppColors.darkAccent : AppColors.lightAccent;
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
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);

  LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(
          colors: [Color(0xFF0B0F14), Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight)
      : const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight);

  // ── Glows ─────────────────────────────────────────
  BoxShadow get primaryGlow => isDark
      ? BoxShadow(
          color: AppColors.darkPrimary.withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 2)
      : BoxShadow(
          color: AppColors.lightPrimary.withValues(alpha: 0.2),
          blurRadius: 16,
          spreadRadius: 1);

  BoxShadow get accentGlow => isDark
      ? BoxShadow(
          color: AppColors.darkAccent.withValues(alpha: 0.35), blurRadius: 15)
      : BoxShadow(
          color: AppColors.lightAccent.withValues(alpha: 0.15), blurRadius: 12);

  BoxShadow get cardShadow => BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      blurRadius: 20);
}

// ─────────────────────────── AppTheme ─────────────────────────────────────────
class AppTheme {
  AppTheme._();

  /// Resolves the correct [AppThemeData] from the build context.
  static AppThemeData of(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return AppThemeData(isDark);
  }

  static ThemeData light() => _buildTheme(isDark: false);
  static ThemeData dark() => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final colors = AppThemeData(isDark);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    // Use fromSeed to auto-generate all required Material3 ColorScheme fields.
    // Then override specific slots with our design tokens.
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
      textTheme: TextTheme(
        displayLarge:
            TextStyle(color: colors.text, fontWeight: FontWeight.w800),
        displayMedium:
            TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        headlineLarge:
            TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        headlineMedium:
            TextStyle(color: colors.text, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: colors.text),
        bodyMedium: TextStyle(color: colors.textMuted),
        labelLarge: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerColor: colors.border,
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
    );
  }
}
