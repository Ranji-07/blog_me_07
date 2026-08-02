import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/navigation.dart';

void main() {
  final base = AppTheme.dark();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Portfolio',
      theme: base.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      ),
      home: const AppShell(),
    ),
  );
}
