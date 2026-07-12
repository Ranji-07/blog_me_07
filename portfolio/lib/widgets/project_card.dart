import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/project_model.dart';
import 'package:portfolio/widgets/interactive_effects.dart';
import 'package:portfolio/widgets/project_modal.dart';

/// Modern project card with hover effects and micro-interactions
class ProjectCard extends StatefulWidget {
  final ProjectModel project;
  final int index;
  final Duration animationDelay;

  const ProjectCard({
    super.key,
    required this.project,
    this.index = 0,
    this.animationDelay = Duration.zero,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _liftAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );

    _liftAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: AppCurves.spring),
    );

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _hoverController, curve: AppCurves.smoothDecelerate),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChange(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _openProjectModal() {
    ProjectModal.show(context, widget.project);
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'agriculture':
        return Icons.agriculture;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'delete':
        return Icons.delete_outline;
      case 'groups':
        return Icons.groups_rounded;
      case 'camera':
        return Icons.camera_alt_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'phone':
        return Icons.phone_android_rounded;
      case 'web':
        return Icons.web_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'data':
        return Icons.storage_rounded;
      case 'ai':
        return Icons.psychology_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final project = widget.project;
    final isMobile = Responsive.isMobile(context);

    return EntranceAnimation(
      delay: widget.animationDelay,
      duration: AppAnimations.entranceSlide,
      curve: AppCurves.smoothDecelerate,
      slideOffset: const Offset(0, 0.04),
      child: MouseRegion(
        onEnter: (_) => _onHoverChange(true),
        onExit: (_) => _onHoverChange(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _openProjectModal,
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_liftAnimation.value),
                child: InteractiveSpotlight(
                  enabled: !isMobile,
                  borderRadius: 20,
                  radius: 240,
                  opacity: 0.14,
                  color: t.accent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isHovered
                            ? t.primary.withValues(alpha: 0.4)
                            : t.border,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: _isHovered ? 0.15 : 0.08),
                          blurRadius: _isHovered ? 30 : 16,
                          offset: Offset(0, _isHovered ? 12 : 4),
                          spreadRadius: _isHovered ? 2 : 0,
                        ),
                        if (_isHovered && t.isDark)
                          BoxShadow(
                            color: t.primary
                                .withValues(alpha: 0.2 * _glowAnimation.value),
                            blurRadius: 40,
                            spreadRadius: -5,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: child,
                    ),
                  ),
                ),
              );
            },
            child: _buildCardContent(context, t, project, isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
    bool isMobile,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactMobile = isMobile && screenWidth < 430;
    final cardPadding = isCompactMobile ? 18.0 : (isMobile ? 20.0 : 24.0);
    final iconPadding = isCompactMobile ? 12.0 : 14.0;
    final iconSize = isCompactMobile ? 24.0 : (isMobile ? 28.0 : 32.0);
    final titleSize = isCompactMobile ? 16.0 : (isMobile ? 18.0 : 20.0);
    final bodySize = isCompactMobile ? 12.5 : (isMobile ? 13.0 : 14.0);
    final visibleTechCount = isCompactMobile ? 3 : 4;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.surface.withValues(alpha: 0.12),
            Colors.transparent,
            t.accent.withValues(alpha: 0.04),
          ],
        ),
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon and category row
          Row(
            children: [
              // Project icon
              AnimatedContainer(
                duration: AppAnimations.fast,
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered
                        ? [
                            t.primary.withValues(alpha: 0.25),
                            t.primary.withValues(alpha: 0.1)
                          ]
                        : [
                            t.primary.withValues(alpha: 0.12),
                            t.primary.withValues(alpha: 0.05)
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHovered
                        ? t.primary.withValues(alpha: 0.4)
                        : t.primary.withValues(alpha: 0.15),
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: t.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: -4,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _getIconData(project.icon),
                  size: iconSize,
                  color: t.primary,
                ),
              ),
              const Spacer(),
              // Category badge
              if (project.category != null)
                AnimatedContainer(
                  duration: AppAnimations.fast,
                  padding:
                      EdgeInsets.symmetric(
                        horizontal: isCompactMobile ? 10 : 12,
                        vertical: isCompactMobile ? 5 : 6,
                      ),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? t.accent.withValues(alpha: 0.2)
                        : t.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isHovered
                          ? t.accent.withValues(alpha: 0.5)
                          : t.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    project.category!,
                    style: TextStyle(
                      fontSize: isCompactMobile ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: t.accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompactMobile ? 14 : (isMobile ? 18 : 22)),
          // Title
          AnimatedDefaultTextStyle(
            duration: AppAnimations.fast,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: _isHovered ? t.primary : t.text,
              height: 1.3,
            ),
            child: Text(
              project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isCompactMobile ? 8 : 10),
          // Short description
          Text(
            project.shortDescription,
            style: TextStyle(
              fontSize: bodySize,
              color: t.textMuted,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompactMobile ? 16 : (isMobile ? 18 : 22)),
          // Technology tags
          Wrap(
            spacing: isCompactMobile ? 6 : 8,
            runSpacing: isCompactMobile ? 6 : 8,
            children: project.technologies.take(visibleTechCount).map((tech) {
              return _TechTag(
                label: tech,
                theme: t,
                isHovered: _isHovered,
                compact: isCompactMobile,
              );
            }).toList(),
          ),
          SizedBox(height: isCompactMobile ? 12 : (isMobile ? 16 : 20)),
          // View details indicator
          AnimatedContainer(
            duration: AppAnimations.fast,
            child: Row(
              children: [
                Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: isCompactMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: _isHovered ? t.primary : t.textMuted,
                  ),
                ),
                SizedBox(width: isCompactMobile ? 4 : 6),
                AnimatedContainer(
                  duration: AppAnimations.fast,
                  transform: Matrix4.translationValues(
                    _isHovered ? 4 : 0,
                    0,
                    0,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: isCompactMobile ? 14 : 16,
                    color: _isHovered ? t.primary : t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechTag extends StatelessWidget {
  final String label;
  final AppThemeData theme;
  final bool isHovered;
  final bool compact;

  const _TechTag({
    required this.label,
    required this.theme,
    required this.isHovered,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: isHovered
            ? theme.primary.withValues(alpha: 0.15)
            : theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHovered
              ? theme.primary.withValues(alpha: 0.4)
              : theme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w500,
          color: isHovered ? theme.primary : theme.textMuted,
        ),
      ),
    );
  }
}

/// Grid of project cards with staggered animations
class ProjectGrid extends StatelessWidget {
  final List<ProjectModel> projects;
  final bool isLoading;

  const ProjectGrid({
    super.key,
    required this.projects,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    final childAspectRatio = isMobile ? 1.35 : (isTablet ? 1.15 : 1.1);

    if (isLoading) {
      return _buildLoadingGrid(context, crossAxisCount, childAspectRatio);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isMobile ? 16 : 24,
        mainAxisSpacing: isMobile ? 16 : 24,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(
          project: projects[index],
          index: index,
          animationDelay: Duration(milliseconds: 100 + (index * 80)),
        );
      },
    );
  }

  Widget _buildLoadingGrid(
    BuildContext context,
    int crossAxisCount,
    double childAspectRatio,
  ) {
    final t = AppTheme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerEffect(
          baseColor: t.card,
          highlightColor: t.border,
          child: Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
          ),
        );
      },
    );
  }
}
