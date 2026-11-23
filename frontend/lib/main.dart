import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/app_shell.dart';
import 'package:portfolio/screens/admin_panel.dart';

/// Drives the root navigator so the Escape fallback can pop overlays.
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final initialPath = Uri.base.path;
  runApp(
    // Escape dismissal of overlays. Flutter maps Escape to DismissIntent but
    // its route-level action only resolves when primary focus sits inside the
    // route content, and a freshly pushed dialog parks focus on its scope
    // node. This root-level handler catches the (then unhandled) intent and
    // pops the topmost route. The public site never pushes page routes - the
    // shell scrolls one home route - so the only poppable routes are the
    // overlays (resume dialog, project dialogs, deck sheet), and Escape is a
    // harmless no-op while none is open.
    _RootEscape(
      child: MaterialApp(
        navigatorKey: _rootNavigatorKey,
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
    ),
  );
}

class _RootEscape extends StatelessWidget {
  final Widget child;
  const _RootEscape({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _rootNavigatorKey.currentState?.maybePop();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
