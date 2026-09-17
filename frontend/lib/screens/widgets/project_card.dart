import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/secure_link_opener.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovered = false;

  Uri? _safeHttpsUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        !uri.hasAuthority) {
      return null;
    }
    return uri;
  }

  Future<void> _openLink(String url) async {
    final uri = _safeHttpsUri(url);
    if (uri == null) return;
    final opened = await openSecureExternalLink(uri.toString());
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link right now')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final project = widget.project;
    final githubAvailable = _safeHttpsUri(project.githubUrl) != null;
    final demoAvailable = _safeHttpsUri(project.demoUrl) != null;
    final summary = project.shortDescription.isEmpty
        ? project.description
        : project.shortDescription;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 300,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: t.card.withValues(alpha: _hovered ? 0.92 : 0.72),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: _hovered ? t.button : t.border),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: t.button.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8))
                ]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(project.category.toUpperCase(),
              style: t.label.copyWith(color: t.button, fontSize: 11)),
          const SizedBox(height: AppSpacing.sm),
          Text(project.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.subheading),
          const SizedBox(height: AppSpacing.sm),
          Text(summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: t.body.copyWith(fontSize: 13)),
          const Spacer(),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: project.technologies
                .take(5)
                .map((tech) => _TechnologyChip(label: tech))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Tooltip(
              message: githubAvailable
                  ? 'Open ${project.title} on GitHub'
                  : 'GitHub link unavailable',
              child: IconButton(
                onPressed:
                    githubAvailable ? () => _openLink(project.githubUrl) : null,
                icon: const FaIcon(FontAwesomeIcons.github, size: 18),
                color: githubAvailable ? t.text : t.textMuted,
              ),
            ),
            const Spacer(),
            if (demoAvailable)
              TextButton.icon(
                onPressed: () => _openLink(project.demoUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Live Demo'),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _TechnologyChip extends StatelessWidget {
  final String label;
  const _TechnologyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: t.label.copyWith(fontSize: 10)),
    );
  }
}
