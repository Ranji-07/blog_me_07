import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/template.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Map<String, dynamic>? aboutData;
  Map<String, dynamic>? contactData;
  bool isLoading = true;
  String? loadError;
  int _currentRoleIndex = 0;

  List<String> get roles => aboutData?['roles'] != null
      ? List<String>.from(aboutData!['roles'])
      : const [
          'AI & ML Engineer',
          'Full Stack Developer',
          'Cloud Native Builder'
        ];

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: AppCurves.ease),
    );
    loadData();
    _startRoleAnimation();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _startRoleAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _currentRoleIndex = (_currentRoleIndex + 1) % roles.length;
      });
      _startRoleAnimation();
    });
  }

  Future<void> loadData() async {
    try {
      final about = await ApiService.getAbout();
      final contact = await ApiService.getContact();
      if (!mounted) return;
      setState(() {
        aboutData = about;
        contactData = contact;
        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = 'Using fallback content. API data could not be loaded.';
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final useStackedHero = screenWidth < 1180;
    final heroRadius = isMobile ? 28.0 : 40.0;

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: t.backgroundGradient),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.85),
                    radius: 1.25,
                    colors: [
                      t.accent.withValues(alpha: 0.12),
                      t.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: _AiParticleBackground(
                density: isMobile ? 14 : (isTablet ? 20 : 28),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 18 : (isTablet ? 34 : 52),
                  vertical: isMobile ? 20 : 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1260),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(heroRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          t.card.withValues(alpha: 0.9),
                          t.surface.withValues(alpha: 0.78),
                        ],
                      ),
                      border: Border.all(
                        color: t.border.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: t.accent.withValues(alpha: 0.08),
                          blurRadius: 80,
                          spreadRadius: -20,
                        ),
                      ],
                    ),
                    child: isLoading
                        ? _buildLoadingState(context)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (loadError != null) ...[
                                _InlineStatusBanner(message: loadError!),
                                const SizedBox(height: 18),
                              ],
                              useStackedHero
                                  ? _buildMobileLayout(context)
                                  : _buildDesktopLayout(context),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = width < 1320 ? 24.0 : 36.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: _HeroTextContent(
            aboutData: aboutData,
            contactData: contactData,
            roles: roles,
            currentRoleIndex: _currentRoleIndex,
            onLaunchUrl: _launchUrl,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          flex: 4,
          child: _HeroAvatar(
            aboutData: aboutData,
            floatAnimation: _floatAnimation,
            maxSize: width < 1400 ? 400 : 480,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        _HeroTextContent(
          aboutData: aboutData,
          contactData: contactData,
          roles: roles,
          currentRoleIndex: _currentRoleIndex,
          onLaunchUrl: _launchUrl,
          isMobile: true,
        ),
        const SizedBox(height: 24),
        _HeroAvatar(
          aboutData: aboutData,
          floatAnimation: _floatAnimation,
          maxSize: width < 420 ? width - 96 : 280,
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: t.primary),
        const SizedBox(height: 18),
        Text(
          'Loading portfolio...',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: t.textMuted,
          ),
        ),
      ],
    );
  }
}

class _InlineStatusBanner extends StatelessWidget {
  final String message;

  const _InlineStatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: t.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTextContent extends StatelessWidget {
  final Map<String, dynamic>? aboutData;
  final Map<String, dynamic>? contactData;
  final List<String> roles;
  final int currentRoleIndex;
  final Function(String) onLaunchUrl;
  final bool isMobile;

  const _HeroTextContent({
    required this.aboutData,
    required this.contactData,
    required this.roles,
    required this.currentRoleIndex,
    required this.onLaunchUrl,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final name = aboutData?['name'] ?? 'Developer';
    final bio = aboutData?['bio'] ??
        'I design AI-native products, machine learning workflows, and resilient cloud systems with a focus on production quality.';
    final stats = aboutData?['stats'] as Map<String, dynamic>? ?? {};
    final socialLinks =
        contactData?['social_links'] as Map<String, dynamic>? ?? {};
    final isAvailable = aboutData?['is_available'] ?? true;

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _AvailabilityBadge(isAvailable: isAvailable),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            color: t.accent.withValues(alpha: 0.08),
            border: Border.all(color: t.accent.withValues(alpha: 0.25)),
          ),
          child: Text(
            'AI systems • ML pipelines • Developer tooling',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: t.accent,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Hi, I'm",
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w500,
            color: t.textMuted,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: isMobile ? 42 : 62,
            fontWeight: FontWeight.w800,
            color: t.text,
            height: 1.02,
            letterSpacing: -1.4,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: AppAnimations.slower,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.28),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: AppCurves.appleEaseOut)),
                child: child,
              ),
            );
          },
          child: ShaderMask(
            key: ValueKey(currentRoleIndex),
            shaderCallback: (bounds) => t.accentGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              roles[currentRoleIndex],
              style: TextStyle(
                fontSize: isMobile ? 23 : 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isMobile ? double.infinity : 560),
          child: Text(
            bio,
            style: t.bodyLG.copyWith(
              height: 1.75,
              color: t.text.withValues(alpha: 0.8),
            ),
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: const [
            _SignalChip(label: 'LLM integrations'),
            _SignalChip(label: 'MLOps ready'),
            _SignalChip(label: 'Cloud deployment'),
          ],
        ),
        const SizedBox(height: 34),
        if (stats.isNotEmpty) ...[
          Wrap(
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatItem(
                  value: '${stats['projects'] ?? 10}+', label: 'Projects'),
              _StatItem(
                  value: '${stats['experience'] ?? 3}+', label: 'Years Exp.'),
              _StatItem(
                  value: '${stats['technologies'] ?? 15}+',
                  label: 'Technologies'),
            ],
          ),
          const SizedBox(height: 34),
        ],
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 12,
          children: [
            _PrimaryButton(
              label: 'View Projects',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileTemplate()),
                );
              },
            ),
            _SecondaryButton(
              label: 'Download CV',
              icon: Icons.download_rounded,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 12,
          children: [
            if (socialLinks['github'] != null)
              _SocialIcon(
                icon: FontAwesomeIcons.github,
                onTap: () => onLaunchUrl(socialLinks['github']),
              ),
            if (socialLinks['linkedin'] != null)
              _SocialIcon(
                icon: FontAwesomeIcons.linkedinIn,
                onTap: () => onLaunchUrl(socialLinks['linkedin']),
              ),
            if (socialLinks['twitter'] != null)
              _SocialIcon(
                icon: FontAwesomeIcons.xTwitter,
                onTap: () => onLaunchUrl(socialLinks['twitter']),
              ),
            if (contactData?['email'] != null)
              _SocialIcon(
                icon: Icons.email_outlined,
                onTap: () => onLaunchUrl('mailto:${contactData!['email']}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final Map<String, dynamic>? aboutData;
  final Animation<double> floatAnimation;
  final double? maxSize;

  const _HeroAvatar({
    required this.aboutData,
    required this.floatAnimation,
    this.maxSize,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final sourceStack = aboutData?['tech_stack'] as List? ?? [];
    final techStack = {
      ...sourceStack.map((e) => e.toString()),
      'Python',
      'Flutter',
      'FastAPI',
      'TensorFlow',
      'AWS',
      'Docker',
      'PostgreSQL',
    }.take(isMobile ? 5 : 7).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final double resolvedMaxSize = maxSize ??
        (Responsive.isDesktop(context)
            ? screenWidth.clamp(0.0, 1480.0) * 0.28
            : screenWidth * 0.52);
    final double size = resolvedMaxSize.clamp(260.0, 480.0);

    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, floatAnimation.value),
          child: child,
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        t.primary.withValues(alpha: 0.18),
                        t.accent.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _OrbitingTechStack(
              size: size,
              labels: techStack,
            ),
            Container(
              width: size * 0.76,
              height: size * 0.76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    t.surface.withValues(alpha: 0.95),
                    t.card.withValues(alpha: 0.98),
                  ],
                ),
                border: Border.all(
                    color: t.accent.withValues(alpha: 0.35), width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: t.primary.withValues(alpha: 0.14),
                    blurRadius: 42,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _HeroCorePainter(theme: t)),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              t.background.withValues(alpha: 0.12),
                              t.background.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: size * 0.1,
                      left: size * 0.12,
                      child: const _MiniInsightCard(
                        icon: Icons.memory_rounded,
                        title: 'Model Ops',
                        subtitle: 'Optimized inference',
                      ),
                    ),
                    Positioned(
                      right: size * 0.1,
                      bottom: size * 0.16,
                      child: const _MiniInsightCard(
                        icon: Icons.hub_rounded,
                        title: 'Data Flow',
                        subtitle: 'Realtime pipelines',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitingTechStack extends StatefulWidget {
  final double size;
  final List<String> labels;

  const _OrbitingTechStack({
    required this.size,
    required this.labels,
  });

  @override
  State<_OrbitingTechStack> createState() => _OrbitingTechStackState();
}

class _OrbitingTechStackState extends State<_OrbitingTechStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final baseRadius = widget.size * (isMobile ? 0.37 : 0.42);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value * math.pi * 2;
        return Stack(
          children: widget.labels.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final angle =
                progress + (index * ((math.pi * 2) / widget.labels.length));
            final dynamicRadius = baseRadius + math.sin(angle * 2) * 8;
            final offset = Offset(
              widget.size / 2 + math.cos(angle) * dynamicRadius,
              widget.size / 2 + math.sin(angle) * (dynamicRadius * 0.82),
            );

            return Positioned(
              left: offset.dx - 40,
              top: offset.dy - 16,
              child: Transform.scale(
                scale: 0.96 + ((math.sin(angle + 1.2) + 1) * 0.04),
                child: _OrbitTag(label: label),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _OrbitTag extends StatelessWidget {
  final String label;

  const _OrbitTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: t.accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.text,
        ),
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MiniInsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: t.surface.withValues(alpha: 0.85),
        border: Border.all(color: t.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 14, color: t.primary),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCorePainter extends CustomPainter {
  final AppThemeData theme;

  const _HeroCorePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = theme.accent.withValues(alpha: 0.16);
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..color = theme.primary.withValues(alpha: 0.12);

    canvas.drawCircle(center, size.width * 0.34, glowPaint);
    canvas.drawCircle(center, size.width * 0.34, ringPaint);
    canvas.drawCircle(center, size.width * 0.27,
        ringPaint..color = theme.primary.withValues(alpha: 0.12));

    final deskPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          theme.surface.withValues(alpha: 0.9),
          theme.card.withValues(alpha: 0.65),
        ],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.66, size.width, size.height * 0.18));
    final desk = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.19, size.height * 0.67, size.width * 0.62,
          size.height * 0.1),
      const Radius.circular(18),
    );
    canvas.drawRRect(desk, deskPaint);

    final monitorFrame = Paint()..color = theme.card.withValues(alpha: 0.95);
    final monitorGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.accent.withValues(alpha: 0.55),
          theme.primary.withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromLTWH(size.width * 0.28, size.height * 0.28,
          size.width * 0.44, size.height * 0.28));
    final monitor = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.28, size.width * 0.44,
          size.height * 0.28),
      const Radius.circular(24),
    );
    canvas.drawRRect(monitor, monitorFrame);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.305, size.height * 0.305,
            size.width * 0.39, size.height * 0.23),
        const Radius.circular(18),
      ),
      monitorGlow,
    );

    final silhouette = Paint()..color = theme.text.withValues(alpha: 0.92);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.46),
        size.width * 0.062, silhouette);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.41, size.height * 0.5, size.width * 0.18,
          size.height * 0.16),
      const Radius.circular(60),
    );
    canvas.drawRRect(
        body, silhouette..color = theme.text.withValues(alpha: 0.82));

    final linePaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = theme.background.withValues(alpha: 0.35);
    final codeBaseX = size.width * 0.35;
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.35 + i * 0.05);
      canvas.drawLine(
        Offset(codeBaseX, y),
        Offset(codeBaseX + size.width * (0.16 + (i.isEven ? 0.07 : 0.0)), y),
        linePaint,
      );
    }

    final nodePaint = Paint()..color = theme.primary.withValues(alpha: 0.85);
    final connector = Paint()
      ..color = theme.accent.withValues(alpha: 0.22)
      ..strokeWidth = 1.2;
    final p1 = Offset(size.width * 0.2, size.height * 0.24);
    final p2 = Offset(size.width * 0.32, size.height * 0.18);
    final p3 = Offset(size.width * 0.68, size.height * 0.2);
    canvas.drawLine(p1, p2, connector);
    canvas.drawLine(p2, p3, connector);
    canvas.drawCircle(p1, 4, nodePaint);
    canvas.drawCircle(p2, 5, Paint()..color = theme.accent);
    canvas.drawCircle(p3, 4, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _HeroCorePainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}

class _SignalChip extends StatelessWidget {
  final String label;

  const _SignalChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        color: t.primary.withValues(alpha: 0.08),
        border: Border.all(color: t.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: t.text,
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.success : t.textMuted,
              shape: BoxShape.circle,
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isAvailable ? 'Open to opportunities' : 'Currently unavailable',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isAvailable ? t.text : t.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatefulWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered ? t.primary.withValues(alpha: 0.12) : t.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hovered ? t.primary.withValues(alpha: 0.34) : t.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: t.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: t.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: _hovered ? 0.44 : 0.26),
                blurRadius: _hovered ? 28 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: AppAnimations.fast,
                transform: Matrix4.translationValues(_hovered ? 4 : 0, 0, 0),
                child: const Icon(Icons.arrow_forward_rounded,
                    size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: _hovered
                ? t.accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: _hovered ? t.accent : t.border,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: _hovered ? t.accent : t.text),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? t.accent : t.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.icon, required this.onTap});

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered ? t.primary.withValues(alpha: 0.1) : t.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered ? t.primary.withValues(alpha: 0.4) : t.border,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: _hovered ? t.primary : t.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AiParticleBackground extends StatefulWidget {
  final int density;

  const _AiParticleBackground({required this.density});

  @override
  State<_AiParticleBackground> createState() => _AiParticleBackgroundState();
}

class _AiParticleBackgroundState extends State<_AiParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncParticles(Size size) {
    if (_lastSize == size && _particles.length == widget.density) return;
    _lastSize = size;
    _particles
      ..clear()
      ..addAll(List.generate(widget.density, (_) {
        return _Particle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          vx: (_random.nextDouble() - 0.5) * 0.22,
          vy: (_random.nextDouble() - 0.5) * 0.22,
          radius: _random.nextDouble() * 1.8 + 1.1,
          accent: _random.nextBool(),
        );
      }));
  }

  void _update(Size size) {
    for (final particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      if (particle.x < 0) particle.x = size.width;
      if (particle.x > size.width) particle.x = 0;
      if (particle.y < 0) particle.y = size.height;
      if (particle.y > size.height) particle.y = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _syncParticles(size);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            _update(size);
            return CustomPaint(
              painter: _AiParticlePainter(
                particles: _particles,
                primary: t.primary,
                accent: t.accent,
              ),
              size: size,
            );
          },
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  bool accent;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.accent,
  });
}

class _AiParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color primary;
  final Color accent;

  const _AiParticlePainter({
    required this.particles,
    required this.primary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 1;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      final p1Color = p1.accent ? accent : primary;
      dotPaint.color = p1Color.withValues(alpha: 0.32);
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius, dotPaint);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final distSq = dx * dx + dy * dy;
        if (distSq > 20000) continue;

        final mix = (1.0 - (distSq / 20000)).clamp(0.0, 1.0);
        linePaint.color = Color.lerp(primary, accent, j / particles.length)!
            .withValues(alpha: 0.025 + (mix * 0.12));
        canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AiParticlePainter oldDelegate) => true;
}
