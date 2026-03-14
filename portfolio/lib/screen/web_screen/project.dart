import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/models/project_model.dart';
import 'package:portfolio/widgets/project_card.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage>
    with TickerProviderStateMixin {
  List<ProjectModel> projects = [];
  bool isLoading = true;
  String? error;

  late AnimationController _headerController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: AppAnimations.entranceSlide,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: AppCurves.smoothDecelerate),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: AppCurves.smoothDecelerate));

    loadProjectData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> loadProjectData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService.getProjects();
      final List<dynamic> projectList = data['projects'] ?? [];

      setState(() {
        projects = projectList.map((p) => ProjectModel.fromJson(p)).toList();
        // If no projects from API, use sample projects
        if (projects.isEmpty) {
          projects = SampleProjects.projects;
        }
        isLoading = false;
      });

      _headerController.forward();
    } catch (e) {
      setState(() {
        // Use sample projects on error
        projects = SampleProjects.projects;
        isLoading = false;
      });
      _headerController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        AnimatedBuilder(
          animation: _headerController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                _headerSlideAnimation.value.dy * 50,
              ),
              child: Opacity(
                opacity: _headerFadeAnimation.value,
                child: child,
              ),
            );
          },
          child: _buildHeader(context, t, isMobile),
        ),
        SizedBox(height: isMobile ? 24 : 40),
        // Project grid
        if (isLoading)
          ProjectGrid(projects: const [], isLoading: true)
        else if (error != null)
          _buildErrorView(t)
        else
          ProjectGrid(projects: projects),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeData t, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    t.primary.withValues(alpha: 0.2),
                    t.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.primary.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.work_rounded,
                size: 24,
                color: t.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        t.primaryGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'My Projects',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A showcase of my technical work and creative solutions',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: t.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Category filter chips (optional enhancement)
        _buildCategoryFilters(t),
      ],
    );
  }

  Widget _buildCategoryFilters(AppThemeData t) {
    final categories = ['All', 'IoT', 'AI/ML', 'Web', 'Mobile'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = index == 0; // Default to "All"

          return Padding(
            padding: EdgeInsets.only(right: index < categories.length - 1 ? 10 : 0),
            child: EntranceAnimation(
              delay: Duration(milliseconds: 200 + (index * 50)),
              child: _CategoryChip(
                label: category,
                isSelected: isSelected,
                theme: t,
                onTap: () {
                  // Filter logic can be added here
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorView(AppThemeData t) {
    return Center(
      child: EntranceAnimation(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: t.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Projects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'An unexpected error occurred',
                style: TextStyle(
                  fontSize: 14,
                  color: t.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _RetryButton(
                theme: t,
                onTap: loadProjectData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final AppThemeData theme;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? t.primaryGradient : null,
            color: widget.isSelected
                ? null
                : (_isHovered
                    ? t.primary.withValues(alpha: 0.15)
                    : t.primary.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : (_isHovered
                      ? t.primary.withValues(alpha: 0.5)
                      : t.primary.withValues(alpha: 0.15)),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.35),
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
              color: widget.isSelected
                  ? Colors.white
                  : (_isHovered ? t.primary : t.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final AppThemeData theme;
  final VoidCallback onTap;

  const _RetryButton({
    required this.theme,
    required this.onTap,
  });

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: t.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: _isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 20 : 12,
                spreadRadius: _isHovered ? 0 : -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
