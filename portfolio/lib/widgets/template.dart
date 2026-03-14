import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/app_buttons.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/screen/web_screen/about.dart';
import 'package:portfolio/screen/web_screen/contact.dart';
import 'package:portfolio/screen/web_screen/experiance_page.dart';
import 'package:portfolio/screen/web_screen/project.dart';

class ProfileTemplate extends StatefulWidget {
  const ProfileTemplate({super.key});
  @override
  State<ProfileTemplate> createState() => _ProfileTemplateState();
}

class _ProfileTemplateState extends State<ProfileTemplate>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    _headerAnimController = AnimationController(
      vsync: this,
      duration: AppAnimations.entranceFade,
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: AppCurves.smoothDecelerate),
    );
    
    // Start header animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  double _sectionHeight(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return MediaQuery.of(context).size.height * 1.2;
    }
    return MediaQuery.of(context).size.height - 80;
  }

  void _onScroll() {
    if (!mounted) return;
    final pos = _scrollController.offset;
    final height = _sectionHeight(context);
    int newIndex = 0;
    if (pos >= height * 3 - 200) {
      newIndex = 3;
    } else if (pos >= height * 2 - 200) {
      newIndex = 2;
    } else if (pos >= height - 200) {
      newIndex = 1;
    }
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
    }
  }

  void _scrollToSection(int index) {
    _scrollController.animateTo(
      index * _sectionHeight(context),
      duration: AppAnimations.slow,
      curve: AppCurves.appleEaseInOut,
    );
    setState(() => _selectedIndex = index);
    if (Responsive.isMobile(context)) Navigator.of(context).pop();
  }

  Future<void> _downloadResume() async {
    try {
      final uri = Uri.parse('assets/resume.pdf');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: Responsive.isMobile(context) ? _buildDrawer(t) : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.backgroundGradient),
        child: Column(children: [
          _buildHeader(context, t),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(children: [
                _buildSection(context, const AboutPage(), t, fitContent: true),
                _buildSection(context, const ProjectPage(), t, fitContent: true),
                _buildSection(context, const ExperiancePage(), t, fitContent: true),
                _buildSection(context, const ContactPage(), t),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSection(BuildContext context, Widget child, AppThemeData t, {bool fitContent = false}) {
    return Container(
      constraints: fitContent ? null : BoxConstraints(minHeight: _sectionHeight(context)),
      padding: Responsive.pagePadding(context),
      child: child,
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeData t) {
    return AnimatedBuilder(
      animation: _headerFadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _headerFadeAnimation.value)),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: Responsive.padding(
              context,
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              desktop: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            ),
            decoration: BoxDecoration(
              color: t.card.withValues(alpha: 0.6),
              border: Border(bottom: BorderSide(color: t.border)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15), blurRadius: 20)
              ],
            ),
            child: Responsive.isMobile(context)
                ? _mobileHeader(t)
                : _desktopHeader(context, t),
          ),
        ),
      ),
    );
  }

  Widget _mobileHeader(AppThemeData t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Portfolio',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: t.primary)),
        IconButton(
          icon: Icon(Icons.menu_rounded, color: t.text),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
    );
  }

  Widget _desktopHeader(BuildContext context, AppThemeData t) {
    final gap = Responsive.isTablet(context) ? 12.0 : 24.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShaderMask(
          shaderCallback: (b) => t.primaryGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text('Portfolio',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ),
        Row(children: [
          _navItem(context, t, 'About', 0),
          SizedBox(width: gap),
          _navItem(context, t, 'Projects', 1),
          SizedBox(width: gap),
          _navItem(context, t, 'Experience', 2),
          SizedBox(width: gap),
          _navItem(context, t, 'Contact', 3),
          SizedBox(width: gap * 1.5),
          AppButton(
            label: 'Resume',
            onPressed: _downloadResume,
            icon: Icons.download_rounded,
            style: AppButtonStyle.primary,
            height: 40,
            fontSize: 14,
          ),
        ]),
      ],
    );
  }

  Widget _navItem(
      BuildContext context, AppThemeData t, String text, int index) {
    final active = _selectedIndex == index;
    return _AnimatedNavItem(
      text: text,
      isActive: active,
      theme: t,
      onTap: () => _scrollToSection(index),
    );
  }

  Widget _buildDrawer(AppThemeData t) {
    return Drawer(
      backgroundColor: t.card,
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 32),
          Text('Portfolio',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: t.primary)),
          const SizedBox(height: 8),
          Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              color: t.border),
          const SizedBox(height: 24),
          _drawerItem(t, 'About', Icons.person_rounded, 0),
          _drawerItem(t, 'Projects', Icons.work_rounded, 1),
          _drawerItem(t, 'Experience', Icons.timeline_rounded, 2),
          _drawerItem(t, 'Contact', Icons.mail_rounded, 3),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(
              label: 'Download Resume',
              onPressed: _downloadResume,
              icon: Icons.download_rounded,
              style: AppButtonStyle.primary,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(AppThemeData t, String text, IconData icon, int index) {
    final active = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: active ? t.primary : t.textMuted, size: 22),
      title: Text(text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? t.primary : t.text,
          )),
      selected: active,
      selectedTileColor: t.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () => _scrollToSection(index),
    );
  }
}

// Animated navigation item with hover effects
class _AnimatedNavItem extends StatefulWidget {
  final String text;
  final bool isActive;
  final AppThemeData theme;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.text,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.spring),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final active = widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppCurves.spring,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: active
                  ? t.primary.withValues(alpha: 0.15)
                  : (_isHovered
                      ? t.primary.withValues(alpha: 0.08)
                      : Colors.transparent),
              border: Border.all(
                color: active
                    ? t.primary.withValues(alpha: 0.4)
                    : (_isHovered
                        ? t.primary.withValues(alpha: 0.2)
                        : Colors.transparent),
                width: 1.5,
              ),
              boxShadow: active || _isHovered
                  ? [
                      BoxShadow(
                        color: t.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: active || _isHovered ? FontWeight.w700 : FontWeight.w600,
                color: active || _isHovered ? t.primary : t.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
