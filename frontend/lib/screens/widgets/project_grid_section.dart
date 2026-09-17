import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/screens/widgets/project_card.dart';
import 'package:portfolio/screens/widgets/project_filter_bar.dart';
import 'package:portfolio/services/portfolio_api.dart';

class ProjectGridSection extends StatefulWidget {
  final Map<String, dynamic>? cachedContent;

  const ProjectGridSection({super.key, this.cachedContent});

  @override
  State<ProjectGridSection> createState() => _ProjectGridSectionState();
}

class _ProjectGridSectionState extends State<ProjectGridSection> {
  static const _allProjects = 'All';
  late Future<List<Project>> _projectsFuture;
  List<Project>? _cachedProjects;
  var _selectedCategory = _allProjects;
  List<String> _categories = const [_allProjects];

  @override
  void initState() {
    super.initState();
    _cachedProjects = _projectsFrom(widget.cachedContent);
    _projectsFuture = _cachedProjects == null
        ? _loadProjects()
        : Future.value(_cachedProjects!);
    _setCategories(_cachedProjects ?? const []);
  }

  @override
  void didUpdateWidget(covariant ProjectGridSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_cachedProjects != null || oldWidget.cachedContent != null) return;
    final cachedProjects = _projectsFrom(widget.cachedContent);
    if (cachedProjects == null) return;
    setState(() {
      _cachedProjects = cachedProjects;
      _projectsFuture = Future.value(cachedProjects);
      _setCategories(cachedProjects);
    });
  }

  List<Project>? _projectsFrom(Map<String, dynamic>? content) {
    final section = content?['projects'];
    if (section is! Map<String, dynamic>) return null;
    final values = section['projects'];
    if (values is! List<dynamic>) return null;
    return values
        .whereType<Map<String, dynamic>>()
        .map(Project.fromJson)
        .toList();
  }

  void _setCategories(List<Project> projects) {
    final categories = projects
        .map((project) => project.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    _categories = [_allProjects, ...categories];
  }

  Future<List<Project>> _loadProjects({String? category}) async {
    final projects = (await PortfolioApi.fetchProjects(category: category))
        .map(Project.fromJson)
        .toList();
    if (category == null && mounted) {
      _setCategories(projects);
    }
    return projects;
  }

  void _selectCategory(String category) {
    if (category == _selectedCategory) return;
    setState(() {
      _selectedCategory = category;
      if (_cachedProjects != null) {
        _projectsFuture = Future.value(
          category == _allProjects
              ? _cachedProjects!
              : _cachedProjects!
                  .where((project) => project.category == category)
                  .toList(),
        );
      } else {
        _projectsFuture =
            _loadProjects(category: category == _allProjects ? null : category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProjectFilterBar(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onSelected: _selectCategory),
      const SizedBox(height: AppSpacing.lg),
      FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(color: t.button)));
          }
          if (snapshot.hasError) {
            return Text('Unable to load projects right now.', style: t.body);
          }
          final projects = snapshot.data ?? const <Project>[];
          if (projects.isEmpty) {
            return Text('No projects found in this category.', style: t.body);
          }
          return AdaptiveGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: projects
                .map((project) => ProjectCard(project: project))
                .toList(),
          );
        },
      ),
    ]);
  }
}
