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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    loadAboutData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadAboutData() async {
    try {
      final data = await ApiService.getAbout();
      setState(() {
        aboutData = data;
        isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: t.primary),
      );
    }

    if (error != null) {
      return _ErrorView(error: error!, onRetry: loadAboutData);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _SectionHeader(
            title: 'About Me',
            subtitle: 'Get to know my background and expertise',
          ),
          SizedBox(height: isMobile ? 32 : 48),

          // About Content
          _AboutContent(aboutData: aboutData, isMobile: isMobile),
          SizedBox(height: isMobile ? 48 : 64),

          // Skills Section
          _SectionHeader(
            title: 'Core Competencies',
            subtitle: 'Technologies and tools I work with',
          ),
          SizedBox(height: isMobile ? 24 : 32),
          _SkillsGrid(skillsData: aboutData?['skills'], isMobile: isMobile),
          SizedBox(height: isMobile ? 48 : 64),

          // Education Section
          _SectionHeader(
            title: 'Education',
            subtitle: 'My academic background',
          ),
          SizedBox(height: isMobile ? 24 : 32),
          _EducationTimeline(
            education: aboutData?['education'] as List? ?? [],
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: isMobile ? 28 : 36,
              decoration: BoxDecoration(
                gradient: t.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            ShaderMask(
              shaderCallback: (bounds) => t.primaryGradient.createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: t.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About Content
// ─────────────────────────────────────────────────────────────────────────────
class _AboutContent extends StatelessWidget {
  final Map<String, dynamic>? aboutData;
  final bool isMobile;

  const _AboutContent({required this.aboutData, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final bio = aboutData?['bio'] ??
        'Passionate software engineer with expertise in building scalable applications.';

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: t.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Who I Am',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            bio,
            style: t.bodyLG.copyWith(height: 1.8),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skills Grid
// ─────────────────────────────────────────────────────────────────────────────
class _SkillsGrid extends StatelessWidget {
  final dynamic skillsData;
  final bool isMobile;

  const _SkillsGrid({required this.skillsData, required this.isMobile});

  Map<String, List<Map<String, dynamic>>> _parseSkills() {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    if (skillsData == null) {
      groups['Languages'] = [
        {'name': 'Python', 'level': 90},
        {'name': 'Dart', 'level': 85},
        {'name': 'JavaScript', 'level': 80},
      ];
      return groups;
    }

    if (skillsData is Map) {
      final skillsMap = skillsData as Map<String, dynamic>;
      for (final entry in skillsMap.entries) {
        final categoryName = entry.key;
        final skillsList = entry.value as List? ?? [];
        groups[categoryName] = skillsList.map((s) {
          if (s is Map) {
            return {
              'name': s['name']?.toString() ?? '',
              'level': s['level'] ?? 80,
            };
          }
          return {'name': s.toString(), 'level': 80};
        }).toList();
      }
    }

    return groups;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'languages':
        return Icons.code_rounded;
      case 'frameworks':
        return Icons.layers_rounded;
      case 'tools & platforms':
        return Icons.build_rounded;
      case 'iot & embedded':
        return Icons.memory_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _parseSkills();
    final crossAxisCount = isMobile ? 1 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 2.2 : 2.0,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final entry = groups.entries.elementAt(index);
        return _SkillCategoryCard(
          title: entry.key,
          icon: _getCategoryIcon(entry.key),
          skills: entry.value,
        );
      },
    );
  }
}

class _SkillCategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> skills;

  const _SkillCategoryCard({
    required this.title,
    required this.icon,
    required this.skills,
  });

  @override
  State<_SkillCategoryCard> createState() => _SkillCategoryCardState();
}

class _SkillCategoryCardState extends State<_SkillCategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered ? t.cardHover : t.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hovered ? t.primary.withValues(alpha: 0.3) : t.border,
          ),
          boxShadow: _hovered ? [t.cardShadowHover] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(widget.icon, size: 20, color: t.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                ),
                Text(
                  '${widget.skills.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Skills wrap
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.skills.map((skill) {
                    return _SkillTag(
                      name: skill['name'] ?? '',
                      level: skill['level'] ?? 80,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTag extends StatefulWidget {
  final String name;
  final int level;

  const _SkillTag({required this.name, required this.level});

  @override
  State<_SkillTag> createState() => _SkillTagState();
}

class _SkillTagState extends State<_SkillTag> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered
              ? t.primary.withValues(alpha: 0.15)
              : t.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: _hovered
                ? t.primary.withValues(alpha: 0.4)
                : t.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          widget.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _hovered ? t.primary : t.text,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Education Timeline
// ─────────────────────────────────────────────────────────────────────────────
class _EducationTimeline extends StatelessWidget {
  final List education;
  final bool isMobile;

  const _EducationTimeline({required this.education, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (education.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(education.length, (index) {
        final item = education[index] as Map<String, dynamic>;
        final isLast = index == education.length - 1;

        return EntranceAnimation(
          delay: Duration(milliseconds: 100 + (index * 80)),
          child: _TimelineItem(
            year: item['year'] ?? '',
            title: item['title'] ?? '',
            subtitle: item['subtitle'] ?? '',
            institution: item['institution'] ?? '',
            isLast: isLast,
          ),
        );
      }),
    );
  }
}

class _TimelineItem extends StatefulWidget {
  final String year;
  final String title;
  final String subtitle;
  final String institution;
  final bool isLast;

  const _TimelineItem({
    required this.year,
    required this.title,
    required this.subtitle,
    required this.institution,
    required this.isLast,
  });

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: AppAnimations.fast,
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _hovered ? t.primary : t.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: t.primary,
                        width: 3,
                      ),
                      boxShadow: _hovered
                          ? [
                              BoxShadow(
                                color: t.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  if (!widget.isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: t.border,
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _hovered ? t.cardHover : t.card,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _hovered ? t.primary.withValues(alpha: 0.3) : t.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: t.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        widget.year,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: t.textMuted,
                      ),
                    ),
                    if (widget.institution.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: t.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.institution,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: t.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: t.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: t.accentAlt),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: t.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
