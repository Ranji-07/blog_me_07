import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';

class ExperiencePage extends StatefulWidget {
  const ExperiencePage({super.key});

  @override
  State<ExperiencePage> createState() => _ExperiencePageState();
}

class _ExperiencePageState extends State<ExperiencePage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? experienceData;
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
    loadExperienceData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadExperienceData() async {
    try {
      final data = await ApiService.getExperience();
      setState(() {
        experienceData = data;
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
      return Center(child: CircularProgressIndicator(color: t.primary));
    }

    if (error != null) {
      return _ErrorView(error: error!, onRetry: loadExperienceData);
    }

    final careers = experienceData?['careers'] as List<dynamic>? ?? [];
    final internships = experienceData?['internships'] as List<dynamic>? ?? [];
    final certifications = experienceData?['certifications'] as List<dynamic>? ?? [];
    final academic = experienceData?['academic'] as List<dynamic>? ?? [];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Experience
          if (careers.isNotEmpty || internships.isNotEmpty) ...[
            _SectionHeader(
              title: 'Professional Experience',
              subtitle: 'My career journey and work history',
              icon: Icons.work_rounded,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            _ExperienceTimeline(
              careers: careers,
              internships: internships,
              isMobile: isMobile,
            ),
            SizedBox(height: isMobile ? 48 : 64),
          ],

          // Certifications
          if (certifications.isNotEmpty) ...[
            _SectionHeader(
              title: 'Certifications',
              subtitle: 'Professional credentials and achievements',
              icon: Icons.workspace_premium_rounded,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            _CertificationsGrid(
              certifications: certifications,
              isMobile: isMobile,
            ),
            SizedBox(height: isMobile ? 48 : 64),
          ],

          // Academic Highlights
          if (academic.isNotEmpty) ...[
            _SectionHeader(
              title: 'Academic Highlights',
              subtitle: 'Awards, publications, and achievements',
              icon: Icons.emoji_events_rounded,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            _AcademicHighlights(
              achievements: academic,
              isMobile: isMobile,
            ),
          ],
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
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: t.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        t.primaryGradient.createShader(bounds),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Experience Timeline
// ─────────────────────────────────────────────────────────────────────────────
class _ExperienceTimeline extends StatelessWidget {
  final List<dynamic> careers;
  final List<dynamic> internships;
  final bool isMobile;

  const _ExperienceTimeline({
    required this.careers,
    required this.internships,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final allExperience = [...careers, ...internships];

    return Column(
      children: List.generate(allExperience.length, (index) {
        final company = allExperience[index] as Map<String, dynamic>;
        final isLast = index == allExperience.length - 1;
        final isInternship = index >= careers.length;

        return EntranceAnimation(
          delay: Duration(milliseconds: 100 + (index * 80)),
          child: _CompanyCard(
            company: company,
            isLast: isLast,
            isInternship: isInternship,
            isMobile: isMobile,
          ),
        );
      }),
    );
  }
}

class _CompanyCard extends StatefulWidget {
  final Map<String, dynamic> company;
  final bool isLast;
  final bool isInternship;
  final bool isMobile;

  const _CompanyCard({
    required this.company,
    required this.isLast,
    required this.isInternship,
    required this.isMobile,
  });

  @override
  State<_CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<_CompanyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final companyName = widget.company['company'] ?? 'Company';
    final positions = widget.company['positions'] as List? ?? [];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            SizedBox(
              width: widget.isMobile ? 40 : 60,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: AppAnimations.fast,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _hovered ? t.primary : t.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isInternship ? t.accent : t.primary,
                        width: 3,
                      ),
                      boxShadow: _hovered
                          ? [
                              BoxShadow(
                                color: t.primary.withValues(alpha: 0.4),
                                blurRadius: 10,
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              t.primary.withValues(alpha: 0.4),
                              t.border,
                            ],
                          ),
                        ),
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
                padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
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
                    // Company header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md - 2),
                            child: Image.asset(
                              'assets/${widget.company['logo'] ?? 'default.png'}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: t.card,
                                child: Icon(
                                  Icons.business_rounded,
                                  color: t.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyName,
                                style: TextStyle(
                                  fontSize: widget.isMobile ? 18 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: t.text,
                                ),
                              ),
                              if (widget.isInternship)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    'Internship',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: t.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (positions.isNotEmpty) const SizedBox(height: 20),
                    // Positions
                    ...positions.asMap().entries.map((entry) {
                      final pos = entry.value as Map<String, dynamic>;
                      return _PositionItem(
                        position: pos,
                        isMobile: widget.isMobile,
                      );
                    }),
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

class _PositionItem extends StatelessWidget {
  final Map<String, dynamic> position;
  final bool isMobile;

  const _PositionItem({required this.position, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, left: 4, right: 16),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: t.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position['position'] ?? 'Role',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: t.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${position['startDate'] ?? ''} - ${position['endDate'] ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textMuted,
                  ),
                ),
                if (position['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    position['description'],
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: t.text.withValues(alpha: 0.85),
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Certifications Grid
// ─────────────────────────────────────────────────────────────────────────────
class _CertificationsGrid extends StatelessWidget {
  final List<dynamic> certifications;
  final bool isMobile;

  const _CertificationsGrid({
    required this.certifications,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isMobile ? 1 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 3.0 : 2.8,
      ),
      itemCount: certifications.length,
      itemBuilder: (context, index) {
        final cert = certifications[index] as Map<String, dynamic>;
        return EntranceAnimation(
          delay: Duration(milliseconds: 100 + (index * 60)),
          child: _CertificationCard(certification: cert),
        );
      },
    );
  }
}

class _CertificationCard extends StatefulWidget {
  final Map<String, dynamic> certification;

  const _CertificationCard({required this.certification});

  @override
  State<_CertificationCard> createState() => _CertificationCardState();
}

class _CertificationCardState extends State<_CertificationCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final cert = widget.certification;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hovered ? t.cardHover : t.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hovered ? t.accent.withValues(alpha: 0.4) : t.border,
          ),
          boxShadow: _hovered ? [t.cardShadowHover] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: t.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cert['title'] ?? 'Certification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cert['issuer'] ?? 'Issuer',
                    style: TextStyle(
                      fontSize: 13,
                      color: t.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cert['date'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Academic Highlights
// ─────────────────────────────────────────────────────────────────────────────
class _AcademicHighlights extends StatelessWidget {
  final List<dynamic> achievements;
  final bool isMobile;

  const _AcademicHighlights({
    required this.achievements,
    required this.isMobile,
  });

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(achievements.length, (index) {
        final achievement = achievements[index] as Map<String, dynamic>;
        return EntranceAnimation(
          delay: Duration(milliseconds: 100 + (index * 60)),
          child: _AchievementCard(
            achievement: achievement,
            icon: _getIcon(achievement['icon']),
            isMobile: isMobile,
          ),
        );
      }),
    );
  }
}

class _AchievementCard extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final IconData icon;
  final bool isMobile;

  const _AchievementCard({
    required this.achievement,
    required this.icon,
    required this.isMobile,
  });

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final ach = widget.achievement;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: _hovered ? t.cardHover : t.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hovered ? t.accentAlt.withValues(alpha: 0.4) : t.border,
          ),
          boxShadow: _hovered ? [t.cardShadowHover] : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.accentAlt.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(widget.icon, color: t.accentAlt, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ach['title'] ?? 'Achievement',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: t.text,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: t.accentAlt.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          ach['date'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.accentAlt,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ach['institution'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.accent,
                    ),
                  ),
                  if (ach['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      ach['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: t.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
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
              'Failed to load experience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
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
