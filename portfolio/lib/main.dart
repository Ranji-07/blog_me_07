import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/screen/web_screen/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portfolio',
      // System-adaptive: uses OS dark/light preference automatically
      themeMode: ThemeMode.system,
      theme:     _applyFonts(AppTheme.light()),
      darkTheme: _applyFonts(AppTheme.dark()),
      home: const HomePage(),
    );
  }

  ThemeData _applyFonts(ThemeData base) {
    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
    );
  }
}