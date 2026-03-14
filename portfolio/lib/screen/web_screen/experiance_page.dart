import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class ExperiancePage extends StatefulWidget {
  const ExperiancePage({super.key});

  @override
  State<ExperiancePage> createState() => _ExperiancePageState();
}

class _ExperiancePageState extends State<ExperiancePage>
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
    setState(() {
      isLoading = true;
      error = null;
    });

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: t.primary),
      );
    }

    if (error != null) {
      return _ErrorView(error: error!, onRetry: loadExperienceData);
    }

    final careers = experienceData?['careers'] as List<dynamic>? ?? [];
    final internships = experienceData?['internships'] as List<dynamic>? ?? [];
    final certifications = experienceData?['certifications'] as List<dynamic>? ?? [];
    final academic = experienceData?['academic'] as List<dynamic>? ?? [];

    if (careers.isEmpty && internships.isEmpty && certifications.isEmpty && academic.isEmpty) {
      return Center(
        child: Text(
          'No experience timeline data available',
          style: TextStyle(fontSize: 18, color: t.text),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (careers.isNotEmpty) ...[
            _buildCategoryHeader(context, "Professional Experience", Icons.work),
            _buildCompanyTimeline(context, careers),
            const SizedBox(height: 40),
          ],
          if (internships.isNotEmpty) ...[
            _buildCategoryHeader(context, "Internships", Icons.handshake),
            _buildCompanyTimeline(context, internships),
            const SizedBox(height: 40),
          ],
          if (certifications.isNotEmpty) ...[
            _buildCategoryHeader(context, "Certifications", Icons.workspace_premium),
            _buildAchievementTimeline(context, certifications),
            const SizedBox(height: 40),
          ],
          if (academic.isNotEmpty) ...[
            _buildCategoryHeader(context, "Academic Highlights", Icons.school),
            _buildAchievementTimeline(context, academic),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title, IconData icon) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
      child: Row(
        children: [
          Icon(icon, color: t.primary, size: isMobile ? 24 : 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: t.text,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyTimeline(BuildContext context, List<dynamic> items) {
    return Column(
      children: List.generate(items.length, (index) {
        final companyData = items[index];
        final bool isLast = index == items.length - 1;

        return EntranceAnimation(
          delay: Duration(milliseconds: 100 + (index * 80)),
          child: TimelineNode(
            isLast: isLast,
            child: CompanyExperienceCard(data: companyData),
          ),
        );
      }),
    );
  }

  Widget _buildAchievementTimeline(BuildContext context, List<dynamic> items) {
    final t = AppTheme.of(context);

    return Column(
      children: List.generate(items.length, (index) {
        final achievementData = items[index];
        final bool isLast = index == items.length - 1;

        return EntranceAnimation(
          delay: Duration(milliseconds: 100 + (index * 80)),
          child: TimelineNode(
            isLast: isLast,
            nodeColor: t.accent,
            child: AchievementCard(data: achievementData),
          ),
        );
      }),
    );
  }
}

class TimelineNode extends StatelessWidget {
  final Widget child;
  final bool isLast;
  final Color? nodeColor;

  const TimelineNode({
    super.key,
    required this.child,
    this.isLast = false,
    this.nodeColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final color = nodeColor ?? t.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 32, left: 8, right: 8),
                decoration: BoxDecoration(
                  color: t.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.3),
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class CompanyExperienceCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CompanyExperienceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    final String companyName = data['company'] ?? 'Unknown Company';
    final String companyLogo = data['logo'] ?? 'default.png';
    final List<dynamic> positions = data['positions'] ?? [];

    return GlassContainer(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/$companyLogo',
                    width: isMobile ? 40 : 50,
                    height: isMobile ? 40 : 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isMobile ? 40 : 50,
                        height: isMobile ? 40 : 50,
                        decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.business, color: t.textMuted),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  companyName,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          if (positions.isNotEmpty) const SizedBox(height: 24),
          ...List.generate(positions.length, (index) {
            final pos = positions[index];
            final bool isLastPos = index == positions.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, left: 16, right: 16),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: t.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLastPos)
                        Expanded(
                          child: Container(
                            width: 1,
                            color: t.border,
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLastPos ? 0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pos['position'] ?? 'Role',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: t.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${pos['startDate'] ?? ''} - ${pos['endDate'] ?? ''}",
                            style: TextStyle(
                              fontSize: 14,
                              color: t.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pos['description'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              pos['description'],
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color: t.text.withValues(alpha: 0.85),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const AchievementCard({super.key, required this.data});

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'certificate':
        return Icons.card_membership;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'military_tech':
        return Icons.military_tech;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return GlassContainer(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.accent.withValues(alpha: 0.3)),
            ),
            child: Icon(
              _getIconData(data['icon']),
              size: 32,
              color: t.accent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Achievement',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      data['issuer'] ?? data['institution'] ?? 'Organization',
                      style: TextStyle(
                        fontSize: 15,
                        color: t.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("•", style: TextStyle(color: t.textMuted)),
                    ),
                    Text(
                      data['date'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
                if (data['description'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    data['description'],
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: t.text.withValues(alpha: 0.85),
                      height: 1.5,
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

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: t.accent),
            const SizedBox(height: 20),
            Text(
              'Error Loading Experience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: t.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: t.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: t.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [t.primaryGlow],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
