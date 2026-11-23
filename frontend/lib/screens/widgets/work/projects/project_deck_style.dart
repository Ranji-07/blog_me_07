import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';

class ProjectDeckStyle {
  ProjectDeckStyle._();
  static const background = Color(0xFF0B0A09);
  static const surface = Color(0xFF131110);
  static const raised = Color(0xFF1B1815);
  static const text = Color(0xFFECE8E2);
  static const muted = Color(0xFF8F8A82);
  static const hairline = Color(0x17FFFFFF);
  // One orange accent for the whole app: the deck reads the theme token.
  static const accent = AppColors.button;

  static TextStyle heading({double size = 20}) => GoogleFonts.outfit(
      fontSize: size, fontWeight: FontWeight.w600, color: text, height: 1.16);
  static TextStyle body({double size = 14}) =>
      GoogleFonts.inter(fontSize: size, color: text, height: 1.6);
  static TextStyle mono({double size = 11, Color color = muted}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color, height: 1.5);
}
