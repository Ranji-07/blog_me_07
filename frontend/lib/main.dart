import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/app_shell.dart';
import 'package:portfolio/screens/admin_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initialPath = Uri.base.path;
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'R/07 — Ranjith V P',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // The public site is a dark-first design; the Work deck, its detail
      // sheet, and the hero gradients are all built for the dark canvas.
      themeMode: ThemeMode.dark,
      home: initialPath == '/admin/login'
          ? const AdminLoginPage()
          : initialPath.startsWith('/admin/')
              ? AdminPanel(section: initialPath.split('/').last)
              : const AppShell(),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/admin/login') {
          return MaterialPageRoute(builder: (_) => const AdminLoginPage());
        }
        if (name.startsWith('/admin/')) {
          return MaterialPageRoute(
              builder: (_) => AdminPanel(section: name.split('/').last));
        }
        return MaterialPageRoute(builder: (_) => const AppShell());
      },
    ),
  );
}
