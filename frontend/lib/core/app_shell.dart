import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portfolio/core/app_navigation.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/screens/about_page.dart';
import 'package:portfolio/screens/contact_page.dart';
import 'package:portfolio/screens/landing_page.dart';
import 'package:portfolio/screens/projects_page.dart';
import 'package:portfolio/screens/resume_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const String _brandLabel = 'Tarzan';
  final _scrollController = ScrollController();
  final _sectionKeys = {
    PortfolioSection.landing: GlobalKey(),
    PortfolioSection.about: GlobalKey(),
    PortfolioSection.projects: GlobalKey(),
    PortfolioSection.contact: GlobalKey(),
  };

  PortfolioSection _current = PortfolioSection.landing;
  Map<String, dynamic>? _portfolioContent;
  Timer? _resumeSuccessTimer;
  bool _showResumeDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveSection);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateActiveSection)
      ..dispose();
    _resumeSuccessTimer?.cancel();
    super.dispose();
  }

  void _cachePortfolioContent(Map<String, dynamic> content) {
    _portfolioContent = content;
  }

  void _updateActiveSection() {
    if (!mounted) return;
    final viewportTarget = MediaQuery.of(context).padding.top + 100;
    PortfolioSection nearest = _current;
    var closestDistance = double.infinity;
    for (final entry in _sectionKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final distance =
          (box.localToGlobal(Offset.zero).dy - viewportTarget).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        nearest = entry.key;
      }
    }
    if (nearest != _current) setState(() => _current = nearest);
  }

  Future<void> _scrollTo(PortfolioSection section) async {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
  }

  Future<void> _openResume() => ResumePreviewDialog.show(
        context,
        onActionComplete: _showResumeSavedState,
      );

  void _showResumeSavedState() {
    _resumeSuccessTimer?.cancel();
    setState(() => _showResumeDone = true);
    _resumeSuccessTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showResumeDone = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final showNavigation = _current != PortfolioSection.landing;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  SizedBox(
                    key: _sectionKeys[PortfolioSection.landing],
                    height: constraints.maxHeight,
                    child: LandingScreen(
                      onEnter: () => _scrollTo(PortfolioSection.about),
                      onProjects: () => _scrollTo(PortfolioSection.projects),
                      onPortfolioContentLoaded: _cachePortfolioContent,
                    ),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[PortfolioSection.about],
                    child: AboutScreen(cachedContent: _portfolioContent),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[PortfolioSection.projects],
                    child: const ProjectsScreen(),
                  ),
                  ConstrainedBox(
                    key: _sectionKeys[PortfolioSection.contact],
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: ContactScreen(cachedContent: _portfolioContent),
                  ),
                ],
              ),
            ),
          ),
          if (showNavigation) const _BrandMark(label: _brandLabel),
          if (showNavigation && !isMobile)
            _FloatingTopNav(
              current: _current,
              onSelect: _scrollTo,
              onResumeTap: _openResume,
            ),
          if (showNavigation && isMobile)
            _FloatingMobileNav(
              current: _current,
              onSelect: _scrollTo,
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
  const _BrandMark({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Positioned(
      top: Responsive.isMobile(context) ? 22 : 28,
      left: Responsive.isMobile(context) ? 20 : 32,
      child: Text(label,
          style: t.subheading.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _FloatingTopNav extends StatelessWidget {
  final PortfolioSection current;
  final ValueChanged<PortfolioSection> onSelect;
  final VoidCallback onResumeTap;
  const _FloatingTopNav(
      {required this.current,
      required this.onSelect,
      required this.onResumeTap});

  @override
  Widget build(BuildContext context) => Positioned(
        top: 28,
        right: 32,
        child: Wrap(
          spacing: AppSpacing.xl,
          children: [
            _TopNavText(
                label: 'About',
                active: current == PortfolioSection.about,
                onTap: () => onSelect(PortfolioSection.about)),
            _TopNavText(
                label: 'Work',
                active: current == PortfolioSection.projects,
                onTap: () => onSelect(PortfolioSection.projects)),
            _TopNavText(
                label: 'Contact',
                active: current == PortfolioSection.contact,
                onTap: () => onSelect(PortfolioSection.contact)),
            _TopNavText(label: 'Resume', active: false, onTap: onResumeTap),
          ],
        ),
      );
}

class _FloatingMobileNav extends StatelessWidget {
  final PortfolioSection current;
  final ValueChanged<PortfolioSection> onSelect;
  final VoidCallback onResumeTap;
  final bool showResumeDone;
  const _FloatingMobileNav(
      {required this.current,
      required this.onSelect,
      required this.onResumeTap,
      required this.showResumeDone});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Positioned(
      top: 18,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavIcon(
              icon: Icons.person_outline_rounded,
              active: current == PortfolioSection.about,
              color: t.button,
              onTap: () => onSelect(PortfolioSection.about)),
          _NavIcon(
              icon: Icons.work_outline_rounded,
              active: current == PortfolioSection.projects,
              color: t.button,
              onTap: () => onSelect(PortfolioSection.projects)),
          _NavIcon(
              icon: Icons.mail_outline_rounded,
              active: current == PortfolioSection.contact,
              color: t.button,
              onTap: () => onSelect(PortfolioSection.contact)),
          _NavIcon(
              icon: showResumeDone
                  ? Icons.download_done_outlined
                  : Icons.document_scanner,
              active: showResumeDone,
              color: t.button,
              onTap: onResumeTap),
        ],
      ),
    );
  }
}

class _TopNavText extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TopNavText(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      child: Text(label,
          style: t.subheading.copyWith(color: active ? t.button : t.text)),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _NavIcon(
      {required this.icon,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return IconButton(
      onPressed: onTap,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      color: active ? color : t.text,
      icon: Icon(icon),
    );
  }
}
