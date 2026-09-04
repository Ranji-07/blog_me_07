import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/screens/about_page.dart';
import 'package:portfolio/screens/contact_page.dart';
import 'package:portfolio/screens/landing_page.dart';
import 'package:portfolio/screens/projects_page.dart';
import 'package:portfolio/widgets/resume_section.dart';

enum PortfolioSection {
  landing,
  about,
  projects,
  contact,
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const String _brandLabel = 'Tarzan';
  PortfolioSection _current = PortfolioSection.landing;
  Timer? _resumeSuccessTimer;
  bool _showResumeDone = false;

  void _goTo(PortfolioSection section) {
    setState(() => _current = section);
  }

  Future<void> _openResume() {
    return ResumePreviewDialog.show(
      context,
      onActionComplete: _showResumeSavedState,
    );
  }

  void _showResumeSavedState() {
    _resumeSuccessTimer?.cancel();
    setState(() => _showResumeDone = true);
    _resumeSuccessTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showResumeDone = false);
      }
    });
  }

  Widget _currentPage() {
    switch (_current) {
      case PortfolioSection.landing:
        return LandingScreen(
          onEnter: () => _goTo(PortfolioSection.about),
        );
      case PortfolioSection.about:
        return const AboutScreen();
      case PortfolioSection.projects:
        return const ProjectsScreen();
      case PortfolioSection.contact:
        return const ContactScreen();
    }
  }

  bool get _showNavigation => _current != PortfolioSection.landing;

  @override
  void dispose() {
    _resumeSuccessTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(_current),
                child: _currentPage(),
              ),
            ),
          ),
          const _BrandMark(label: _brandLabel),
          if (_showNavigation && !isMobile)
            _FloatingTopNav(
              current: _current,
              onSelect: _goTo,
              onResumeTap: _openResume,
            ),
          if (_showNavigation && isMobile)
            _FloatingMobileNav(
              current: _current,
              onSelect: _goTo,
              onResumeTap: _openResume,
              showResumeDone: _showResumeDone,
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String label;

  const _BrandMark({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Positioned(
      top: isMobile ? 22 : 28,
      left: isMobile ? 20 : 32,
      child: Text(
        label,
        style: t.subheading.copyWith(
          color: t.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FloatingTopNav extends StatelessWidget {
  final PortfolioSection current;
  final ValueChanged<PortfolioSection> onSelect;
  final VoidCallback onResumeTap;

  const _FloatingTopNav({
    required this.current,
    required this.onSelect,
    required this.onResumeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 28,
      right: 32,
      child: Wrap(
        spacing: AppSpacing.xl,
        children: [
          _TopNavText(
            label: 'About',
            active: current == PortfolioSection.about,
            onTap: () => onSelect(PortfolioSection.about),
          ),
          _TopNavText(
            label: 'Work',
            active: current == PortfolioSection.projects,
            onTap: () => onSelect(PortfolioSection.projects),
          ),
          _TopNavText(
            label: 'Contact',
            active: current == PortfolioSection.contact,
            onTap: () => onSelect(PortfolioSection.contact),
          ),
          _TopNavText(
            label: 'Resume',
            active: false,
            onTap: onResumeTap,
          ),
        ],
      ),
    );
  }
}

class _FloatingMobileNav extends StatelessWidget {
  final PortfolioSection current;
  final ValueChanged<PortfolioSection> onSelect;
  final VoidCallback onResumeTap;
  final bool showResumeDone;

  const _FloatingMobileNav({
    required this.current,
    required this.onSelect,
    required this.onResumeTap,
    required this.showResumeDone,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Positioned(
      top: 18,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomNavIcon(
            icon: Icons.person_outline_rounded,
            active: current == PortfolioSection.about,
            activeColor: t.button,
            onTap: () => onSelect(PortfolioSection.about),
          ),
          const SizedBox(width: 14),
          _BottomNavIcon(
            icon: Icons.work_outline_rounded,
            active: current == PortfolioSection.projects,
            activeColor: t.button,
            onTap: () => onSelect(PortfolioSection.projects),
          ),
          const SizedBox(width: 14),
          _BottomNavIcon(
            icon: Icons.mail_outline_rounded,
            active: current == PortfolioSection.contact,
            activeColor: t.button,
            onTap: () => onSelect(PortfolioSection.contact),
          ),
          const SizedBox(width: 14),
          _BottomNavIcon(
            icon: showResumeDone
                ? Icons.download_done_outlined
                : Icons.document_scanner,
            active: showResumeDone,
            activeColor: t.button,
            onTap: onResumeTap,
          ),
        ],
      ),
    );
  }
}

class _TopNavText extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TopNavText({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        foregroundColor: active ? t.button : t.text,
      ),
      child: Text(
        label,
        style: t.subheading.copyWith(color: active ? t.button : t.text),
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _BottomNavIcon({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return IconButton(
      onPressed: onTap,
      iconSize: 26,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      tooltip: active ? 'Current section' : 'Open section',
      color: active ? activeColor : t.text,
      icon: Icon(icon),
    );
  }
}
