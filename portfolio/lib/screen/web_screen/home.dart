import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/widgets/template.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? aboutData;
  Map<String, dynamic>? contactData;
  bool isLoading = true;

  List<String> get roles => aboutData?['roles'] != null
      ? List<String>.from(aboutData!['roles'])
      : ['Developer', 'Engineer', 'Creator'];

  int _currentRoleIndex = 0;

  @override
  void initState() {
    super.initState();
    loadData();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentRoleIndex = (_currentRoleIndex + 1) % roles.length;
        });
        _startAnimation();
      }
    });
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
    } catch (e) {
      setState(() {
        isLoading = false;
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
    final isMobile = Responsive.isMobile(context);
    final name = aboutData?['name'] ?? 'Developer';
    final bio = aboutData?['bio'] ?? 'Passionate about building great software.';
    final socialLinks = contactData?['social_links'] ?? {};

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: t.backgroundGradient),
          ),
          // Particle background
          const Positioned.fill(
            child: RepaintBoundary(child: CinematicBackground()),
          ),
          // Scrollable Foreground
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60),
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: t.primary))
                    : Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 40,
                          runSpacing: 40,
                          children: [
                            // Hero image with badges
                            _HeroImageSection(
                              aboutData: aboutData,
                              isMobile: isMobile,
                            ),
                            // Content card
                            _ContentCard(
                              name: name,
                              bio: bio,
                              roles: roles,
                              currentRoleIndex: _currentRoleIndex,
                              aboutData: aboutData,
                              socialLinks: socialLinks,
                              contactData: contactData,
                              isMobile: isMobile,
                              onLaunchUrl: _launchUrl,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImageSection extends StatelessWidget {
  final Map<String, dynamic>? aboutData;
  final bool isMobile;

  const _HeroImageSection({
    required this.aboutData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = isMobile ? screenWidth * 0.85 : 400.0;
    final imageHeight = isMobile ? screenWidth * 1.05 : 550.0;

    return SizedBox(
      width: isMobile ? screenWidth * 0.85 : 450,
      height: isMobile ? screenWidth * 1.1 : 600,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(80),
              boxShadow: [
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.3),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: Image.asset(
                'assets/images.png',
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: imageWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(80),
                      color: t.card,
                    ),
                    child: Icon(Icons.person, size: 150, color: t.textMuted),
                  );
                },
              ),
            ),
          ),
          if (!isMobile) ..._buildDynamicBadges(context),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicBadges(BuildContext context) {
    final techStack = aboutData?['tech_stack'] as List?;
    if (techStack == null || techStack.isEmpty) return [];

    final positions = [
      {'top': 40.0, 'left': 10.0, 'right': null, 'delay': 0.0},
      {'top': 120.0, 'left': null, 'right': 10.0, 'delay': 0.5},
      {'top': 300.0, 'left': 0.0, 'right': null, 'delay': 1.0},
      {'top': 450.0, 'left': null, 'right': 20.0, 'delay': 1.5},
      {'top': 550.0, 'left': 40.0, 'right': null, 'delay': 0.8},
      {'top': 600.0, 'left': null, 'right': 30.0, 'delay': 0.2},
      {'top': 200.0, 'left': 60.0, 'right': null, 'delay': 1.2},
    ];

    List<Widget> badges = [];
    for (int i = 0; i < techStack.length && i < positions.length; i++) {
      final pos = positions[i];
      badges.add(FloatingBadge(
        text: techStack[i].toString(),
        top: pos['top'],
        left: pos['left'],
        right: pos['right'],
        delay: pos['delay'] ?? 0.0,
      ));
    }
    return badges;
  }
}

class _ContentCard extends StatelessWidget {
  final String name;
  final String bio;
  final List<String> roles;
  final int currentRoleIndex;
  final Map<String, dynamic>? aboutData;
  final Map<String, dynamic> socialLinks;
  final Map<String, dynamic>? contactData;
  final bool isMobile;
  final Function(String) onLaunchUrl;

  const _ContentCard({
    required this.name,
    required this.bio,
    required this.roles,
    required this.currentRoleIndex,
    required this.aboutData,
    required this.socialLinks,
    required this.contactData,
    required this.isMobile,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return GlassContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 50,
        vertical: isMobile ? 30 : 40,
      ),
      width: isMobile ? screenWidth * 0.9 : 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Availability badge
          _AvailabilityBadge(isAvailable: aboutData?['is_available'] ?? true),
          const SizedBox(height: 20),
          // Name
          Text(
            "Hi, I'm $name",
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              color: t.text,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Animated role
          AnimatedSwitcher(
            duration: AppAnimations.slower,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: AppCurves.appleEaseOut,
                  )),
                  child: child,
                ),
              );
            },
            child: Text(
              roles[currentRoleIndex],
              key: ValueKey<int>(currentRoleIndex),
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w600,
                color: t.primary,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Bio
          _GradientText(
            text: bio,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          // Stats
          if (aboutData?['stats'] != null) ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 15,
              children: [
                _AnimatedStatCard(
                  label: "Projects",
                  value: aboutData!['stats']['projects']?.toString() ?? "10+",
                ),
                _AnimatedStatCard(
                  label: "Experience",
                  value: "${aboutData!['stats']['experience']?.toString() ?? '1+'} Yrs",
                ),
                _AnimatedStatCard(
                  label: "Tech Stack",
                  value: aboutData!['stats']['technologies']?.toString() ?? "12+",
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
          // CTA Button
          _DiscoverMeButton(),
          const SizedBox(height: 40),
          // Social icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (contactData?['phone'] != null)
                _AnimatedSocialIcon(
                  icon: FontAwesomeIcons.squarePhone,
                  onPressed: () => onLaunchUrl('tel:${contactData!['phone']}'),
                ),
              if (contactData?['phone'] != null) const SizedBox(width: 20),
              if (socialLinks['instagram'] != null)
                _AnimatedSocialIcon(
                  icon: FontAwesomeIcons.instagram,
                  onPressed: () => onLaunchUrl(socialLinks['instagram']),
                ),
              if (socialLinks['instagram'] != null) const SizedBox(width: 20),
              if (socialLinks['github'] != null)
                _AnimatedSocialIcon(
                  icon: FontAwesomeIcons.github,
                  onPressed: () => onLaunchUrl(socialLinks['github']),
                ),
              if (socialLinks['github'] != null) const SizedBox(width: 20),
              if (socialLinks['linkedin'] != null)
                _AnimatedSocialIcon(
                  icon: FontAwesomeIcons.linkedin,
                  onPressed: () => onLaunchUrl(socialLinks['linkedin']),
                ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.card.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: t.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? Colors.greenAccent : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isAvailable
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isAvailable ? "Available for opportunities" : "Currently unavailable",
            style: TextStyle(
              color: isAvailable ? t.text : t.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _GradientText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DiscoverMeButton extends StatefulWidget {
  @override
  State<_DiscoverMeButton> createState() => _DiscoverMeButtonState();
}

class _DiscoverMeButtonState extends State<_DiscoverMeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileTemplate()),
          );
        },
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: t.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: _hovered ? 0.5 : 0.4),
                blurRadius: _hovered ? 20 : 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            "Discover Me",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSocialIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedSocialIcon({required this.icon, required this.onPressed});

  @override
  State<_AnimatedSocialIcon> createState() => _AnimatedSocialIconState();
}

class _AnimatedSocialIconState extends State<_AnimatedSocialIcon>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
    final t = AppTheme.of(context);

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
        onTap: widget.onPressed,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? t.primary.withValues(alpha: 0.15)
                  : t.card.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered
                    ? t.primary.withValues(alpha: 0.5)
                    : t.border.withValues(alpha: 0.3),
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: t.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: FaIcon(
              widget.icon,
              color: _isHovered ? t.primary : t.textMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final String value;

  const _AnimatedStatCard({required this.label, required this.value});

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
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
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          decoration: BoxDecoration(
            color: _isHovered
                ? t.primary.withValues(alpha: 0.1)
                : t.card.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? t.primary.withValues(alpha: 0.4)
                  : t.border.withValues(alpha: 0.3),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: t.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w400,
                  color: _isHovered ? t.text : t.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FloatingBadge extends StatefulWidget {
  final String text;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double delay;

  const FloatingBadge({
    super.key,
    required this.text,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.delay,
  });

  @override
  State<FloatingBadge> createState() => _FloatingBadgeState();
}

class _FloatingBadgeState extends State<FloatingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.floatCycle,
      vsync: this,
    )..repeat(reverse: true);

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });

    _animation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.ease),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: t.card.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: t.text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class CinematicBackground extends StatefulWidget {
  const CinematicBackground({super.key});

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
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
    int count = (size.width * size.height / 35000).clamp(15, 60).toInt();
    for (int i = 0; i < count; i++) {
      _particles.add(Particle(
        x: _rnd.nextDouble() * size.width,
        y: _rnd.nextDouble() * size.height,
        vx: (_rnd.nextDouble() - 0.5) * 0.2,
        vy: (_rnd.nextDouble() - 0.5) * 0.2,
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
              painter: CinematicPainter(_particles, t.primary),
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

class Particle {
  double x, y, vx, vy, radius;
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class CinematicPainter extends CustomPainter {
  final List<Particle> particles;
  final Color primaryColor;

  CinematicPainter(this.particles, this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius, dotPaint);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final double dx = p1.x - p2.x;
        final double dy = p1.y - p2.y;
        final double distSq = dx * dx + dy * dy;

        if (distSq < 20000) {
          final double alpha = (1.0 - distSq / 20000) * 0.25;
          linePaint.color = primaryColor.withValues(alpha: alpha);
          canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), linePaint);
        }
      }
    }

    final centerGlow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 1.5,
      height: size.height * 1.5,
    );

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0F172A).withValues(alpha: 0.85),
          Colors.transparent,
        ],
        stops: const [0.15, 0.7],
      ).createShader(centerGlow);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CinematicPainter oldDelegate) => true;
}
