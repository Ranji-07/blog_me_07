import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/secure_link_opener.dart';

class BlogWorkspaceEntry {
  final String title;
  final String path;
  final String status;
  final String url;

  const BlogWorkspaceEntry({
    required this.title,
    required this.path,
    required this.status,
    required this.url,
  });

  factory BlogWorkspaceEntry.fromJson(Map<String, dynamic> json) =>
      BlogWorkspaceEntry(
        title: json['title'] as String? ?? '',
        path: json['path'] as String? ?? '',
        status: json['status'] as String? ?? 'Planned',
        url: json['url'] as String? ?? '',
      );
}

class WorkWorkspaceSection extends StatelessWidget {
  final List<Project> projects;
  final List<BlogWorkspaceEntry> blogEntries;

  const WorkWorkspaceSection({
    super.key,
    required this.projects,
    required this.blogEntries,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return _MobileWorkspace(projects: projects, blogEntries: blogEntries);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final split = constraints.maxWidth >= 880;
        final projectsPanel = _ProjectsTerminal(projects: projects);
        final blogPanel = _BlogTerminal(entries: blogEntries);
        if (!split) {
          return Column(
            children: [
              projectsPanel,
              const SizedBox(height: AppSpacing.md),
              blogPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 12, child: projectsPanel),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 9, child: blogPanel),
          ],
        );
      },
    );
  }
}

class _MobileWorkspace extends StatefulWidget {
  final List<Project> projects;
  final List<BlogWorkspaceEntry> blogEntries;

  const _MobileWorkspace({required this.projects, required this.blogEntries});

  @override
  State<_MobileWorkspace> createState() => _MobileWorkspaceState();
}

class _MobileWorkspaceState extends State<_MobileWorkspace> {
  bool _showProjects = true;

  @override
  Widget build(BuildContext context) {
    return _TerminalFrame(
      title: _showProjects ? '~/projects' : '~/blog',
      tabs: [
        _TerminalTab(
          label: 'Projects',
          selected: _showProjects,
          onTap: () => setState(() => _showProjects = true),
        ),
        _TerminalTab(
          label: 'Blog',
          selected: !_showProjects,
          onTap: () => setState(() => _showProjects = false),
        ),
      ],
      child: _showProjects
          ? _ProjectDirectory(projects: widget.projects)
          : _BlogDirectory(entries: widget.blogEntries),
    );
  }
}

class _ProjectsTerminal extends StatelessWidget {
  final List<Project> projects;
  const _ProjectsTerminal({required this.projects});

  @override
  Widget build(BuildContext context) => _TerminalFrame(
        title: '~/projects',
        trailing: 'workspace',
        child: _ProjectDirectory(projects: projects),
      );
}

class _BlogTerminal extends StatelessWidget {
  final List<BlogWorkspaceEntry> entries;
  const _BlogTerminal({required this.entries});

  @override
  Widget build(BuildContext context) => _TerminalFrame(
        title: '~/blog',
        trailing: 'workspace',
        child: _BlogDirectory(entries: entries),
      );
}

class _TerminalTab {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TerminalTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _TerminalFrame extends StatelessWidget {
  final String title;
  final String? trailing;
  final List<_TerminalTab>? tabs;
  final Widget child;
  const _TerminalFrame({
    required this.title,
    required this.child,
    this.trailing,
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border))),
            child: Row(
              children: [
                _TerminalDots(),
                const SizedBox(width: AppSpacing.sm),
                if (tabs != null)
                  ...tabs!.map((tab) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: _TabButton(tab: tab),
                      ))
                else
                  Expanded(
                      child: Text(title,
                          style: t.subheading.copyWith(fontSize: 16))),
                if (tabs != null) const Spacer(),
                if (trailing != null)
                  Text(trailing!, style: t.label.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _TerminalDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Row(
      children: [
        _dot(t.button),
        const SizedBox(width: 5),
        _dot(t.textMuted.withValues(alpha: 0.65)),
        const SizedBox(width: 5),
        _dot(t.textMuted.withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _TabButton extends StatelessWidget {
  final _TerminalTab tab;
  const _TabButton({required this.tab});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return TextButton(
      onPressed: tab.onTap,
      style: TextButton.styleFrom(
        foregroundColor: tab.selected ? t.text : t.textMuted,
        backgroundColor: tab.selected ? t.buttonSoft : Colors.transparent,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: const StadiumBorder(),
      ),
      child: Text(tab.label, style: t.label.copyWith(fontSize: 11)),
    );
  }
}

class _ProjectDirectory extends StatelessWidget {
  final List<Project> projects;
  const _ProjectDirectory({required this.projects});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Project>>{
      'academic': [],
      'boodskap': [],
      'devops': [],
    };
    for (final project in projects) {
      final category = project.category.toLowerCase();
      final group = category == 'ai'
          ? 'academic'
          : category == 'mobile' || category == 'iot'
              ? 'boodskap'
              : 'devops';
      groups[group]!.add(project);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PromptLine(),
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty) ...[
            _DirectoryLabel(label: '${entry.key}/'),
            for (final project in entry.value) _ProjectRow(project: project),
          ],
        const SizedBox(height: AppSpacing.sm),
        const _TerminalNote(
          text:
              'Some work is private or hands-on; public links appear when available.',
        ),
      ],
    );
  }
}

class _BlogDirectory extends StatelessWidget {
  final List<BlogWorkspaceEntry> entries;
  const _BlogDirectory({required this.entries});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PromptLine(),
          for (final entry in entries) _BlogRow(entry: entry),
          const SizedBox(height: AppSpacing.sm),
          const _TerminalNote(
              text: 'Notes are listed here as they are ready to publish.'),
        ],
      );
}

class _PromptLine extends StatelessWidget {
  const _PromptLine();
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(r'$ ls', style: t.label.copyWith(color: t.button)),
    );
  }
}

class _DirectoryLabel extends StatelessWidget {
  final String label;
  const _DirectoryLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 3),
      child: Text('├── $label', style: t.label.copyWith(color: t.button)),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Project project;
  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final hasLink = project.githubUrl.startsWith('https://') ||
        project.demoUrl.startsWith('https://');
    return InkWell(
      onTap: () => _showProjectDetails(context, project),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '└── ${_fileName(project.title)}',
                overflow: TextOverflow.ellipsis,
                style: t.label.copyWith(color: t.text),
              ),
            ),
            Text(
              hasLink ? 'source ↗' : 'details →',
              style: t.label.copyWith(fontSize: 10, color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogRow extends StatelessWidget {
  final BlogWorkspaceEntry entry;
  const _BlogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return InkWell(
      onTap: () {
        if (entry.url.startsWith('https://')) {
          openSecureExternalLink(entry.url);
        } else {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(entry.title),
              content: const Text(
                  'This note is planned and will be published here later.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
                child: Text('├── ${entry.path}',
                    style: t.label.copyWith(color: t.text))),
            Text(entry.status,
                style: t.label.copyWith(fontSize: 10, color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _TerminalNote extends StatelessWidget {
  final String text;
  const _TerminalNote({required this.text});
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.of(context).label.copyWith(fontSize: 9),
      );
}

String _fileName(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

Future<void> _showProjectDetails(BuildContext context, Project project) {
  final t = AppTheme.of(context);
  final description = project.description.isEmpty
      ? project.shortDescription
      : project.description;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(project.title, style: t.subheading),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.category.toUpperCase(),
                  style: t.label.copyWith(color: t.button)),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: t.body),
              if (project.technologies.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.technologies
                      .map((technology) => Chip(label: Text(technology)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (project.githubUrl.startsWith('https://'))
          TextButton.icon(
            onPressed: () => openSecureExternalLink(project.githubUrl),
            icon: const Icon(Icons.code_rounded, size: 16),
            label: const Text('Source'),
          ),
        if (project.demoUrl.startsWith('https://'))
          TextButton.icon(
            onPressed: () => openSecureExternalLink(project.demoUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Live demo'),
          ),
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close')),
      ],
    ),
  );
}
