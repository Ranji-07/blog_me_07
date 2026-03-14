import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/widgets/template.dart';
import 'package:portfolio/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Map<String, dynamic>? aboutData;
  Map<String, dynamic>? contactData;
  bool isLoading = true;

  List<String> get roles => aboutData?['roles'] != null
      ? List<String>.from(aboutData!['roles'])
      : ['AI & ML Engineer', 'Full Stack Developer', 'DevOps Specialist'];

  int _currentRoleIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimations.entranceFade,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppCurves.smoothDecelerate,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: AppAnimations.floatCycle,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: AppCurves.ease),
    );

    loadData();
    _startRoleAnimation();
  }

  void _startRoleAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentRoleIndex = (_currentRoleIndex + 1) % roles.length;
        });
        _startRoleAnimation();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final about = await ApiService.getAbout();
      final contact = await ApiService.getContact();
      setState(() {
        aboutData = about;
        contactData = contact;
        isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _fadeController.forward();
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
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: t.backgroundGradient),
          ),
          // Particle background
          const Positioned.fill(
            child: RepaintBoundary(child: _ParticleBackground()),
          ),
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 1200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                      vertical: isMobile ? 40 : 80,
                    ),
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: t.primary))
                        : isMobile
                            ? _buildMobileLayout(context, t)
                            : _buildDesktopLayout(context, t),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppThemeData t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Text content
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
        const SizedBox(width: 60),
        // Right: Avatar with tech stack
        Expanded(
          flex: 4,
          child: _HeroAvatar(
            aboutData: aboutData,
            floatAnimation: _floatAnimation,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppThemeData t) {
    return Column(
      children: [
        _HeroAvatar(
          aboutData: aboutData,
          floatAnimation: _floatAnimation,
          maxSize: 280,
        ),
        const SizedBox(height: 40),
        _HeroTextContent(
          aboutData: aboutData,
          contactData: contactData,
          roles: roles,
          currentRoleIndex: _currentRoleIndex,
          onLaunchUrl: _launchUrl,
          isMobile: true,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Text Content
// ─────────────────────────────────────────────────────────────────────────────
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
    final bio = aboutData?['bio'] ?? 'Building intelligent systems that make a difference.';
    final stats = aboutData?['stats'] as Map<String, dynamic>? ?? {};
    final socialLinks = contactData?['social_links'] as Map<String, dynamic>? ?? {};
    final isAvailable = aboutData?['is_available'] ?? true;

    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Availability badge
        _AvailabilityBadge(isAvailable: isAvailable),
        const SizedBox(height: 24),
        
        // Greeting
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
        
        // Name
        Text(
          name,
          style: TextStyle(
            fontSize: isMobile ? 40 : 56,
            fontWeight: FontWeight.w800,
            color: t.text,
            height: 1.1,
            letterSpacing: -1,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 12),
        
        // Animated role
        AnimatedSwitcher(
          duration: AppAnimations.slower,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppCurves.appleEaseOut,
                )),
                child: child,
              ),
            );
          },
          child: ShaderMask(
            key: ValueKey(currentRoleIndex),
            shaderCallback: (bounds) => t.primaryGradient.createShader(bounds),
            child: Text(
              roles[currentRoleIndex],
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Bio
        Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 520),
          child: Text(
            bio,
            style: t.bodyLG.copyWith(height: 1.7),
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
          ),
        ),
        const SizedBox(height: 40),
        
        // Stats
        if (stats.isNotEmpty) ...[
          Wrap(
            alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatItem(
                value: '${stats['projects'] ?? 10}+',
                label: 'Projects',
              ),
              _StatItem(
                value: '${stats['experience'] ?? 3}+',
                label: 'Years Exp.',
              ),
              _StatItem(
                value: '${stats['technologies'] ?? 15}+',
                label: 'Technologies',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
        
        // CTA Buttons
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
        const SizedBox(height: 40),
        
        // Social links
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (socialLinks['github'] != null)
              _SocialIcon(
                icon: FontAwesomeIcons.github,
                onTap: () => onLaunchUrl(socialLinks['github']),
              ),
            if (socialLinks['linkedin'] != null) ...[
              const SizedBox(width: 16),
              _SocialIcon(
                icon: FontAwesomeIcons.linkedin,
                onTap: () => onLaunchUrl(socialLinks['linkedin']),
              ),
            ],
            if (socialLinks['twitter'] != null) ...[
              const SizedBox(width: 16),
              _SocialIcon(
                icon: FontAwesomeIcons.xTwitter,
                onTap: () => onLaunchUrl(socialLinks['twitter']),
              ),
            ],
            if (contactData?['email'] != null) ...[
              const SizedBox(width: 16),
              _SocialIcon(
                icon: Icons.email_outlined,
                onTap: () => onLaunchUrl('mailto:${contactData!['email']}'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Avatar Section
// ─────────────────────────────────────────────────────────────────────────────
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
    final techStack = aboutData?['tech_stack'] as List? ?? [];
    final size = maxSize ?? 380.0;

    return Column(
      children: [
        // Avatar with glow
        AnimatedBuilder(
          animation: floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, floatAnimation.value),
              child: child,
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.25),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Gradient ring
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        t.primary.withValues(alpha: 0.3),
                        t.accent.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Avatar image
                Container(
                  width: size - 16,
                  height: size - 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.primary.withValues(alpha: 0.4),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: t.card,
                        child: Icon(
                          Icons.person,
                          size: size * 0.4,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Tech stack tags (clean grid below avatar)
        if (techStack.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxWidth: size + 40),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: techStack.take(7).map((tech) {
                return _TechTag(label: tech.toString());
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────────

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
          color: _hovered ? t.primary.withValues(alpha: 0.1) : t.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hovered ? t.primary.withValues(alpha: 0.4) : t.border,
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
                color: t.primary.withValues(alpha: _hovered ? 0.5 : 0.3),
                blurRadius: _hovered ? 24 : 16,
                offset: const Offset(0, 4),
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
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
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
            color: _hovered ? t.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: _hovered ? t.primary : t.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: _hovered ? t.primary : t.text,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? t.primary : t.text,
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

class _TechTag extends StatefulWidget {
  final String label;

  const _TechTag({required this.label});

  @override
  State<_TechTag> createState() => _TechTagState();
}

class _TechTagState extends State<_TechTag> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? t.primary.withValues(alpha: 0.15) : t.card,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: _hovered ? t.primary.withValues(alpha: 0.5) : t.border,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _hovered ? t.primary : t.text,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle Background
// ─────────────────────────────────────────────────────────────────────────────
class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();

  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _rnd = math.Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    if (_initialized) return;
    _initialized = true;
    int count = (size.width * size.height / 40000).clamp(12, 50).toInt();
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _rnd.nextDouble() * size.width,
        y: _rnd.nextDouble() * size.height,
        vx: (_rnd.nextDouble() - 0.5) * 0.15,
        vy: (_rnd.nextDouble() - 0.5) * 0.15,
        radius: _rnd.nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initParticles(size);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            _updateParticles(size);
            return CustomPaint(
              size: size,
              painter: _ParticlePainter(_particles, t.primary),
            );
          },
        );
      },
    );
  }

  void _updateParticles(Size size) {
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0) p.x = size.width;
      if (p.x > size.width) p.x = 0;
      if (p.y < 0) p.y = size.height;
      if (p.y > size.height) p.y = 0;
    }
  }
}

class _Particle {
  double x, y, vx, vy, radius;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color primaryColor;

  _ParticlePainter(this.particles, this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius, dotPaint);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final distSq = dx * dx + dy * dy;

        if (distSq < 25000) {
          final alpha = (1.0 - distSq / 25000) * 0.15;
          linePaint.color = primaryColor.withValues(alpha: alpha);
          canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
