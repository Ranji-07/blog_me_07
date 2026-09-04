import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/app_shell.dart';

void main() {
  final light = AppTheme.light();
  final dark = AppTheme.dark();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portfolio',
      theme: light.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(light.textTheme),
      ),
      darkTheme: dark.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(dark.textTheme),
      ),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    ),
  );
}
