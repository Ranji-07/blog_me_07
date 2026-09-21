import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/app_shell.dart';
import 'package:portfolio/screens/admin_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initialPath = Uri.base.path;
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
      home: initialPath == '/admin/login'
          ? const AdminLoginPage()
          : initialPath.startsWith('/admin/')
              ? AdminPanel(section: initialPath.split('/').last)
              : const AppShell(),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/admin/login') return MaterialPageRoute(builder: (_) => const AdminLoginPage());
        if (name.startsWith('/admin/')) return MaterialPageRoute(builder: (_) => AdminPanel(section: name.split('/').last));
        return MaterialPageRoute(builder: (_) => const AppShell());
      },
    ),
  );
}
