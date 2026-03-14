import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/project_model.dart';

/// Apple/Stripe-style project detail modal with smooth animations
class ProjectModal extends StatefulWidget {
  final ProjectModel project;

  const ProjectModal({super.key, required this.project});

  static Future<void> show(BuildContext context, ProjectModel project) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Project Modal',
      barrierColor: Colors.transparent,
      transitionDuration: AppAnimations.modalEnter,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectModal(project: project);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  @override
  State<ProjectModal> createState() => _ProjectModalState();
}

class _ProjectModalState extends State<ProjectModal>
    with TickerProviderStateMixin {
  late AnimationController _backdropController;
  late AnimationController _modalController;
  late Animation<double> _backdropAnimation;
  late Animation<double> _modalScaleAnimation;
  late Animation<double> _modalFadeAnimation;
  late Animation<Offset> _modalSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Backdrop animation
    _backdropController = AnimationController(
      vsync: this,
      duration: AppAnimations.modalEnter,
    );
    _backdropAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backdropController, curve: AppCurves.smoothDecelerate),
    );

    // Modal animation
    _modalController = AnimationController(
      vsync: this,
      duration: AppAnimations.modalEnter,
    );
    _modalScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _modalController, curve: AppCurves.modalEnter),
    );
    _modalFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _modalController, curve: AppCurves.smoothDecelerate),
    );
    _modalSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _modalController, curve: AppCurves.modalEnter));

    // Start animations
    _backdropController.forward();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _modalController.forward();
    });
  }

  @override
  void dispose() {
    _backdropController.dispose();
    _modalController.dispose();
    super.dispose();
  }

  Future<void> _closeModal() async {
    await Future.wait([
      _modalController.reverse(),
      _backdropController.reverse(),
    ]);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Backdrop with blur
          AnimatedBuilder(
            animation: _backdropAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: _closeModal,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12 * _backdropAnimation.value,
                    sigmaY: 12 * _backdropAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6 * _backdropAnimation.value),
                  ),
                ),
              );
            },
          ),
          // Modal content
          Center(
            child: AnimatedBuilder(
              animation: _modalController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _modalSlideAnimation.value.dx * MediaQuery.of(context).size.width,
                    _modalSlideAnimation.value.dy * MediaQuery.of(context).size.height,
                  ),
                  child: Transform.scale(
                    scale: _modalScaleAnimation.value,
                    child: Opacity(
                      opacity: _modalFadeAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: isMobile
                  ? _buildMobileModal(context, t)
                  : _buildDesktopModal(context, t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopModal(BuildContext context, AppThemeData t) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.85;
    final maxHeight = screenSize.height * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(600.0, 1100.0),
        maxHeight: maxHeight,
      ),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: t.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 60,
            spreadRadius: 10,
          ),
          if (t.isDark)
            BoxShadow(
              color: t.primary.withValues(alpha: 0.1),
              blurRadius: 40,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _buildModalContent(context, t, isDesktop: true),
      ),
    );
  }

  Widget _buildMobileModal(BuildContext context, AppThemeData t) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: t.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: _buildModalContent(context, t, isDesktop: false),
      ),
    );
  }

  Widget _buildModalContent(BuildContext context, AppThemeData t, {required bool isDesktop}) {
    final project = widget.project;

    return Column(
      children: [
        // Header bar
        _buildHeader(context, t),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 20),
            child: StaggeredList(
              initialDelay: const Duration(milliseconds: 100),
              staggerDelay: AppAnimations.staggerDelay,
              spacing: isDesktop ? 32 : 24,
              children: [
                // Hero section
                _buildHeroSection(context, t, project, isDesktop),
                // Full description
                _buildDescriptionSection(context, t, project),
                // Technology stack
                if (project.technologies.isNotEmpty)
                  _buildTechSection(context, t, project, isDesktop),
                // Workflow/Architecture
                if (project.workflow.isNotEmpty)
                  _buildWorkflowSection(context, t, project, isDesktop),
                // Key features
                if (project.features.isNotEmpty)
                  _buildFeaturesSection(context, t, project, isDesktop),
                // Links
                if (project.links.hasAnyLink)
                  _buildLinksSection(context, t, project, isDesktop),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(bottom: BorderSide(color: t.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Drag indicator for mobile
          if (Responsive.isMobile(context)) ...[
            Expanded(
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                widget.project.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
            ),
          ],
          // Close button
          PressableScale(
            onTap: _closeModal,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.textMuted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: t.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
    bool isDesktop,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project icon
        Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                t.primary.withValues(alpha: 0.15),
                t.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.primary.withValues(alpha: 0.2)),
          ),
          child: Icon(
            _getIconData(project.icon),
            size: isDesktop ? 48 : 36,
            color: t.primary,
          ),
        ),
        const SizedBox(width: 20),
        // Title and category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Responsive.isMobile(context))
                Text(
                  project.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                    height: 1.2,
                  ),
                ),
              if (!Responsive.isMobile(context))
                Text(
                  project.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: t.text,
                    height: 1.2,
                  ),
                ),
              const SizedBox(height: 8),
              if (project.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    project.category!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(t, 'Overview', Icons.description_outlined),
        const SizedBox(height: 12),
        Text(
          project.fullDescription,
          style: TextStyle(
            fontSize: 15,
            color: t.textMuted,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildTechSection(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(t, 'Technology Stack', Icons.code_rounded),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: project.technologies.map((tech) {
            return _TechBadge(label: tech, theme: t);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkflowSection(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(t, 'System Workflow', Icons.account_tree_rounded),
        const SizedBox(height: 16),
        ...project.workflow.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == project.workflow.length - 1;

          return _WorkflowStepCard(
            step: step,
            theme: t,
            isLast: isLast,
            delay: Duration(milliseconds: 200 + (index * 80)),
          );
        }),
      ],
    );
  }

  Widget _buildFeaturesSection(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(t, 'Key Features', Icons.star_rounded),
        const SizedBox(height: 16),
        ...project.features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;

          return EntranceAnimation(
            delay: Duration(milliseconds: 250 + (index * 60)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: t.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLinksSection(
    BuildContext context,
    AppThemeData t,
    ProjectModel project,
    bool isDesktop,
  ) {
    final links = project.links;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(t, 'Links', Icons.link_rounded),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (links.github != null)
              _LinkButton(
                label: 'GitHub',
                icon: Icons.code_rounded,
                url: links.github!,
                theme: t,
                onTap: () => _launchUrl(links.github!),
              ),
            if (links.liveDemo != null)
              _LinkButton(
                label: 'Live Demo',
                icon: Icons.open_in_new_rounded,
                url: links.liveDemo!,
                theme: t,
                isPrimary: true,
                onTap: () => _launchUrl(links.liveDemo!),
              ),
            if (links.documentation != null)
              _LinkButton(
                label: 'Docs',
                icon: Icons.menu_book_rounded,
                url: links.documentation!,
                theme: t,
                onTap: () => _launchUrl(links.documentation!),
              ),
            if (links.video != null)
              _LinkButton(
                label: 'Video',
                icon: Icons.play_circle_outline_rounded,
                url: links.video!,
                theme: t,
                onTap: () => _launchUrl(links.video!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(AppThemeData t, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: t.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: t.text,
          ),
        ),
      ],
    );
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
}

// ─────────────────────────── Sub-widgets ─────────────────────────────────────

class _TechBadge extends StatefulWidget {
  final String label;
  final AppThemeData theme;

  const _TechBadge({required this.label, required this.theme});

  @override
  State<_TechBadge> createState() => _TechBadgeState();
}

class _TechBadgeState extends State<_TechBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppCurves.spring,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? t.primary.withValues(alpha: 0.2)
              : t.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _hovered
                ? t.primary.withValues(alpha: 0.6)
                : t.primary.withValues(alpha: 0.2),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: t.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
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

class _WorkflowStepCard extends StatefulWidget {
  final WorkflowStep step;
  final AppThemeData theme;
  final bool isLast;
  final Duration delay;

  const _WorkflowStepCard({
    required this.step,
    required this.theme,
    required this.isLast,
    required this.delay,
  });

  @override
  State<_WorkflowStepCard> createState() => _WorkflowStepCardState();
}

class _WorkflowStepCardState extends State<_WorkflowStepCard> {
  bool _hovered = false;

  IconData _getStepIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'sensors':
        return Icons.sensors_rounded;
      case 'cell_tower':
        return Icons.cell_tower_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'dashboard':
        return Icons.dashboard_rounded;
      case 'input':
        return Icons.input_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'design_services':
        return Icons.design_services_rounded;
      case 'rocket_launch':
        return Icons.rocket_launch_rounded;
      case 'monitor':
        return Icons.monitor_rounded;
      case 'route':
        return Icons.route_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      case 'link':
        return Icons.link_rounded;
      case 'edit':
        return Icons.edit_rounded;
      case 'video_call':
        return Icons.video_call_rounded;
      case 'task_alt':
        return Icons.task_alt_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final step = widget.step;

    return EntranceAnimation(
      delay: widget.delay,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator and line
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: t.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${step.step}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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
                              t.primary.withValues(alpha: 0.5),
                              t.primary.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Step content
            Expanded(
              child: MouseRegion(
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
                      color: _hovered
                          ? t.primary.withValues(alpha: 0.4)
                          : t.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.06),
                        blurRadius: _hovered ? 16 : 8,
                        offset: Offset(0, _hovered ? 6 : 2),
                      ),
                      if (_hovered)
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: t.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStepIcon(step.icon),
                          size: 20,
                          color: t.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: t.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: t.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _LinkButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final String url;
  final AppThemeData theme;
  final bool isPrimary;
  final VoidCallback onTap;

  const _LinkButton({
    required this.label,
    required this.icon,
    required this.url,
    required this.theme,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressableScale(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? t.primaryGradient : null,
            color: widget.isPrimary
                ? null
                : (_hovered
                    ? t.primary.withValues(alpha: 0.15)
                    : t.primary.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isPrimary
                  ? Colors.transparent
                  : (_hovered
                      ? t.primary.withValues(alpha: 0.6)
                      : t.primary.withValues(alpha: 0.2)),
            ),
            boxShadow: widget.isPrimary || _hovered
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary ? Colors.white : t.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isPrimary ? Colors.white : t.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
