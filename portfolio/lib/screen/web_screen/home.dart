import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final name = aboutData?['name'] ?? 'Developer';
    final title = aboutData?['title'] ?? 'Software Engineer';
    final bio = aboutData?['bio'] ?? 'Passionate about building great software.';
    final socialLinks = contactData?['social_links'] ?? {};

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1E2C), Color(0xFF020617)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned.fill(
            child: CinematicBackground(),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C6FF)))
                : Center(
                    child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 60,
                  runSpacing: 40,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 800 ? 500 : MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.width > 800 ? 650 : 450,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(80),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C6FF).withOpacity(0.3),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(80),
                              child: Image.asset(
                                'assets/images.png',
                                width: MediaQuery.of(context).size.width > 800 ? 400 : MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.width > 800 ? 600 : 400,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width > 800 ? 400 : MediaQuery.of(context).size.width * 0.9,
                                    height: MediaQuery.of(context).size.width > 800 ? 600 : 400,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(80),
                                      color: const Color(0xFF1E293B),
                                    ),
                                    child: const Icon(Icons.person, size: 150, color: Colors.blueGrey),
                                  );
                                },
                              ),
                            ),
                          ),
                            ..._buildDynamicBadges(),
                          ],
                        ),
                      ),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
                      width: MediaQuery.of(context).size.width > 800 ? 600 : MediaQuery.of(context).size.width * 0.9,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: (aboutData?['is_available'] ?? true) ? Colors.greenAccent : Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (aboutData?['is_available'] ?? true)
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                    ]
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  (aboutData?['is_available'] ?? true) ? "Available for opportunities" : "Currently unavailable",
                                  style: TextStyle(
                                    color: (aboutData?['is_available'] ?? true) ? Colors.white : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Hi, I'm $name",
                            style: const TextStyle(
                              fontSize: 42,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.5),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              roles[_currentRoleIndex],
                              key: ValueKey<int>(_currentRoleIndex),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00C6FF),
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          gradientText3(bio),
                          const SizedBox(height: 40),
                          if (aboutData?['stats'] != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatCard("Projects", aboutData!['stats']['projects']?.toString() ?? "10+"),
                                _buildStatCard("Experience", "${aboutData!['stats']['experience']?.toString() ?? '1+'} Yrs"),
                                _buildStatCard("Tech Stack", aboutData!['stats']['technologies']?.toString() ?? "12+"),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ProfileTemplate()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C6FF).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Discover Me",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (contactData?['phone'] != null)
                                _buildSocialIcon(FontAwesomeIcons.squarePhone, () => _launchUrl('tel:${contactData!['phone']}')),
                              const SizedBox(width: 20),
                              if (socialLinks['instagram'] != null)
                                _buildSocialIcon(FontAwesomeIcons.instagram, () => _launchUrl(socialLinks['instagram'])),
                              const SizedBox(width: 20),
                              if (socialLinks['github'] != null)
                                _buildSocialIcon(FontAwesomeIcons.github, () => _launchUrl(socialLinks['github'])),
                              const SizedBox(width: 20),
                              if (socialLinks['linkedin'] != null)
                                _buildSocialIcon(FontAwesomeIcons.linkedin, () => _launchUrl(socialLinks['linkedin'])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicBadges() {
    if (MediaQuery.of(context).size.width <= 800) return [];
    
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
    for (int i = 0; i < techStack.length; i++) {
        if (i >= positions.length) break;
        final pos = positions[i];
        badges.add(FloatingBadge(
            text: techStack[i].toString(),
            top: pos['top'] as double?,
            left: pos['left'] as double?,
            right: pos['right'] as double?,
            delay: pos['delay'] as double,
        ));
    }
    return badges;
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: FaIcon(icon, color: const Color(0xFF00C6FF), size: 24),
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
  }
  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00C6FF),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

Widget gradientText3(String text) {
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
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    ),
  );
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

class _FloatingBadgeState extends State<FloatingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });

    _animation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C6FF).withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
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

class _CinematicBackgroundState extends State<CinematicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _rnd = math.Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
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
              painter: CinematicPainter(_particles),
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
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.radius});
}

class CinematicPainter extends CustomPainter {
  final List<Particle> particles;

  CinematicPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF00C6FF).withOpacity(0.15)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFF00C6FF).withOpacity(0.4)
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
          linePaint.color = const Color(0xFF00C6FF).withOpacity(alpha);
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
          const Color(0xFF0F172A).withOpacity(0.85), 
          Colors.transparent,
        ],
        stops: const [0.15, 0.7],
      ).createShader(centerGlow);
      
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CinematicPainter oldDelegate) => true;
}
