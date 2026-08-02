import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/models/project_model.dart';
import 'package:portfolio/widgets/project_card.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage>
    with TickerProviderStateMixin {
  List<ProjectModel> projects = [];
  bool isLoading = true;
  String? error;
  String _selectedCategory = 'All';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = ['All', 'IoT', 'AI/ML', 'Web', 'Mobile'];

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
    loadProjectData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
        if (projects.isEmpty) {
          projects = SampleProjects.projects;
        }
        isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      setState(() {
        projects = SampleProjects.projects;
        isLoading = false;
      });
      _fadeController.forward();
    }
  }

  List<ProjectModel> get _filteredProjects {
    if (_selectedCategory == 'All') return projects;
    return projects
        .where((p) =>
            p.category?.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _SectionHeader(
            title: 'Projects',
            subtitle: 'A showcase of my technical work and creative solutions',
          ),
          SizedBox(height: isMobile ? 24 : 32),

          // Category filters
          _CategoryFilters(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) {
              setState(() => _selectedCategory = cat);
            },
          ),
          SizedBox(height: isMobile ? 24 : 32),

          // Project grid
          if (isLoading)
            _LoadingGrid()
          else if (_filteredProjects.isEmpty)
            _EmptyState()
          else
            _ProjectGrid(projects: _filteredProjects),
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
    final titleSize =
        Responsive.fontSize(context, mobile: 28, tablet: 32, desktop: 36);
    final subtitleSize =
        Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16);

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
                  fontSize: titleSize,
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
              fontSize: subtitleSize,
              color: t.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Filters
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryFilters extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _CategoryFilters({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = category == selectedCategory;

          return Padding(
            padding: EdgeInsets.only(right: index < categories.length - 1 ? 10 : 0),
            child: _CategoryChip(
              label: category,
              isSelected: isSelected,
              onTap: () => onCategorySelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? t.primaryGradient : null,
            color: widget.isSelected
                ? null
                : (_hovered
                    ? t.primary.withValues(alpha: 0.1)
                    : t.card),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : (_hovered ? t.primary.withValues(alpha: 0.4) : t.border),
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isSelected
                  ? Colors.white
                  : (_hovered ? t.primary : t.text),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Project Grid
// ─────────────────────────────────────────────────────────────────────────────
class _ProjectGrid extends StatelessWidget {
  final List<ProjectModel> projects;

  const _ProjectGrid({required this.projects});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1280 ? 3 : (width >= 760 ? 2 : 1);
        return AdaptiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: columns,
          spacing: 20,
          runSpacing: 20,
          children: List.generate(projects.length, (index) {
            return EntranceAnimation(
              delay: Duration(milliseconds: 80 + (index * 60)),
              child: ProjectCard(
                project: projects[index],
                index: index,
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading Grid
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1280 ? 3 : (width >= 760 ? 2 : 1);
        return AdaptiveGrid(
          mobileColumns: 1,
          tabletColumns: 2,
          desktopColumns: columns,
          spacing: 20,
          runSpacing: 20,
          children: List.generate(6, (index) {
            return SizedBox(
              height: width >= 760 ? 330 : 280,
              child: ShimmerEffect(
                baseColor: t.card,
                highlightColor: t.cardHover,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: t.border),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: t.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(
                fontSize: 14,
                color: t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
