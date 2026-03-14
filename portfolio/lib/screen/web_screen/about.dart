import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  Map<String, dynamic>? aboutData;
  bool isLoading = true;
  String? error;

  late final AnimationController _avatarCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _fadeAnim;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _avatarCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.floatCycle,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _avatarCtrl, curve: AppCurves.ease),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.slower,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: AppCurves.easeOut);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: AppCurves.easeOut));

    loadAboutData();
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> loadAboutData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ApiService.getAbout();
      setState(() {
        aboutData = data;
        isLoading = false;
      });
      _fadeCtrl.forward();
      _slideCtrl.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }

    if (error != null) {
      return _ErrorView(error: error!, onRetry: loadAboutData);
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: isDesktop
            ? _DesktopLayout(
                aboutData: aboutData,
                floatAnim: _floatAnim,
                avatarCtrl: _avatarCtrl,
              )
            : _MobileLayout(
                aboutData: aboutData,
                isMobile: isMobile,
                floatAnim: _floatAnim,
                avatarCtrl: _avatarCtrl,
              ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Map<String, dynamic>? aboutData;
  final Animation<double> floatAnim;
  final AnimationController avatarCtrl;

  const _DesktopLayout({
    required this.aboutData,
    required this.floatAnim,
    required this.avatarCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _ContentColumn(aboutData: aboutData),
        ),
        const SizedBox(width: 48),
        SizedBox(
          width: 340,
          child: _AvatarCard(floatAnim: floatAnim, avatarCtrl: avatarCtrl),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Map<String, dynamic>? aboutData;
  final bool isMobile;
  final Animation<double> floatAnim;
  final AnimationController avatarCtrl;

  const _MobileLayout({
    required this.aboutData,
    required this.isMobile,
    required this.floatAnim,
    required this.avatarCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _AvatarCard(
            floatAnim: floatAnim,
            avatarCtrl: avatarCtrl,
            maxWidth: isMobile ? 260 : 320,
          ),
        ),
        const SizedBox(height: 32),
        _ContentColumn(aboutData: aboutData),
      ],
    );
  }
}

class _ContentColumn extends StatelessWidget {
  final Map<String, dynamic>? aboutData;

  const _ContentColumn({required this.aboutData});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final bio = aboutData?['bio'] ??
        'Passionate Flutter & AI developer building impactful digital experiences.';
    final skills = aboutData?['skills'] as List? ?? [];
    final education = aboutData?['education'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GradientHeading('About Me'),
        const SizedBox(height: 16),
        Text(
          bio,
          style: TextStyle(fontSize: 16, color: t.textMuted, height: 1.8),
        ),
        const SizedBox(height: 40),
        _SectionLabel('Core Competencies'),
        const SizedBox(height: 16),
        _ExpandableSkillGroups(skills: skills),
        const SizedBox(height: 40),
        _SectionLabel('Education & Timeline'),
        const SizedBox(height: 16),
        _EducationTimeline(education: education),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _AvatarCard extends StatefulWidget {
  final Animation<double> floatAnim;
  final AnimationController avatarCtrl;
  final double? maxWidth;

  const _AvatarCard({
    required this.floatAnim,
    required this.avatarCtrl,
    this.maxWidth,
  });

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return AnimatedBuilder(
      animation: widget.floatAnim,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, widget.floatAnim.value),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppAnimations.medium,
          constraints: BoxConstraints(maxWidth: widget.maxWidth ?? 340),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: t.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              t.primaryGlow,
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
              ),
              if (_hovered)
                BoxShadow(
                  color: t.primary.withValues(alpha: 0.25),
                  blurRadius: 60,
                  spreadRadius: 4,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          t.primary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: AppAnimations.medium,
                  transform: _hovered
                      ? (Matrix4.identity()..rotateZ(0.015))
                      : Matrix4.identity(),
                  child: Image.asset(
                    'assets/images.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 400,
                      color: t.card,
                      child: Icon(
                        Icons.person,
                        size: 120,
                        color: t.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableSkillGroups extends StatefulWidget {
  final List skills;
  const _ExpandableSkillGroups({required this.skills});

  @override
  State<_ExpandableSkillGroups> createState() => _ExpandableSkillGroupsState();
}

class _ExpandableSkillGroupsState extends State<_ExpandableSkillGroups> {
  final Map<String, bool> _expanded = {};

  Map<String, List<String>> _groupSkills(List skills) {
    final Map<String, List<String>> groups = {
      'Languages': [],
      'Frameworks': [],
      'Tools & Platforms': [],
    };
    for (final s in skills) {
      if (s is Map) {
        final cat = s['category']?.toString() ?? '';
        final name = s['name']?.toString() ?? '';
        if (cat.toLowerCase().contains('language')) {
          groups['Languages']!.add(name);
        } else if (cat.toLowerCase().contains('framework') ||
            cat.toLowerCase().contains('sdk')) {
          groups['Frameworks']!.add(name);
        } else {
          groups['Tools & Platforms']!.add(name);
        }
      } else {
        groups['Tools & Platforms']!.add(s.toString());
      }
    }
    return groups;
  }

  @override
  void initState() {
    super.initState();
    _expanded['Languages'] = true;
    _expanded['Frameworks'] = true;
    _expanded['Tools & Platforms'] = true;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupSkills(widget.skills);

    if (groups.values.every((v) => v.isEmpty)) {
      groups['Languages'] = ['Dart', 'Python', 'JavaScript', 'TypeScript', 'SQL'];
      groups['Frameworks'] = ['Flutter', 'FastAPI', 'React', 'Node.js', 'TensorFlow'];
      groups['Tools & Platforms'] = ['Docker', 'Firebase', 'PostgreSQL', 'Git', 'AWS', 'Figma'];
    }

    return Column(
      children: groups.entries.map((entry) {
        final isOpen = _expanded[entry.key] ?? true;
        return _SkillGroupCard(
          title: entry.key,
          skills: entry.value,
          isOpen: isOpen,
          onToggle: () => setState(() => _expanded[entry.key] = !isOpen),
        );
      }).toList(),
    );
  }
}

class _SkillGroupCard extends StatelessWidget {
  final String title;
  final List<String> skills;
  final bool isOpen;
  final VoidCallback onToggle;

  const _SkillGroupCard({
    required this.title,
    required this.skills,
    required this.isOpen,
    required this.onToggle,
  });

  IconData _groupIcon() {
    switch (title) {
      case 'Languages':
        return Icons.code;
      case 'Frameworks':
        return Icons.developer_board;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_groupIcon(), size: 18, color: t.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${skills.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: t.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: isOpen ? 0.5 : 0,
                      duration: AppAnimations.normal,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: t.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: skills.map((s) => _SkillBadge(label: s)).toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isOpen ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: AppAnimations.normal,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillBadge extends StatefulWidget {
  final String label;
  const _SkillBadge({required this.label});

  @override
  State<_SkillBadge> createState() => _SkillBadgeState();
}

class _SkillBadgeState extends State<_SkillBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _hovered
              ? t.primary.withValues(alpha: 0.18)
              : t.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _hovered ? t.primary.withValues(alpha: 0.7) : t.border,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: t.primary.withValues(alpha: 0.3), blurRadius: 10)]
              : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _hovered ? t.primary : t.text,
          ),
        ),
      ),
    );
  }
}

class _EducationTimeline extends StatelessWidget {
  final List education;
  const _EducationTimeline({required this.education});

  List<Map<String, String>> _defaultEducation() => [
        {
          'degree': 'School (10th)',
          'institution': 'State Board',
          'year': '2018',
          'description': 'Completed secondary education with distinction.'
        },
        {
          'degree': 'Higher Secondary (12th)',
          'institution': 'State Board',
          'year': '2020',
          'description': 'Studied Computer Science & Mathematics.'
        },
        {
          'degree': 'B.Tech / B.E.',
          'institution': 'University',
          'year': '2024',
          'description': 'Bachelor\'s in Computer Science Engineering with AI specialization.'
        },
      ];

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final items = education.isNotEmpty
        ? education
            .map((e) => {
                  'degree': (e['degree'] ?? e['title'] ?? '').toString(),
                  'institution': (e['institution'] ?? e['school'] ?? '').toString(),
                  'year': (e['year'] ?? e['date'] ?? '').toString(),
                  'description': (e['description'] ?? '').toString(),
                })
            .toList()
        : _defaultEducation();

    return Column(
      children: List.generate(items.length, (i) {
        final isLast = i == items.length - 1;
        final item = items[i];

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.card,
                        border: Border.all(color: t.primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: t.primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.primary,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: t.primary.withValues(alpha: 0.25),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _TimelineCard(item: item, isAccent: i % 2 == 1),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineCard extends StatefulWidget {
  final Map<String, String> item;
  final bool isAccent;

  const _TimelineCard({required this.item, required this.isAccent});

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final accentColor = widget.isAccent ? t.accent : t.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? accentColor.withValues(alpha: 0.6) : t.border,
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 20,
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item['degree'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: t.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.item['year'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.item['institution'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((widget.item['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.item['description']!,
                style: TextStyle(
                  fontSize: 13,
                  color: t.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientHeading extends StatelessWidget {
  final String text;
  const _GradientHeading(this.text);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return ShaderMask(
      shaderCallback: (bounds) => t.primaryGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: t.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: t.text,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, size: 60, color: t.accent),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 13, color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: t.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [t.primaryGlow],
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
