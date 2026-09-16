import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';

class SkillCategoryGrid extends StatefulWidget {
  final Map<String, List<String>> categories;

  const SkillCategoryGrid({super.key, required this.categories});

  @override
  State<SkillCategoryGrid> createState() => _SkillCategoryGridState();
}

class _SkillCategoryGridState extends State<SkillCategoryGrid> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final entries = widget.categories.entries.toList();
    if (Responsive.isMobile(context)) {
      return Stack(
        children: [
          SizedBox(
            height: 132,
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 68),
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, index) => SizedBox(
                width: 188,
                child: _SkillCard(
                  title: entries[index].key,
                  skills: entries[index].value,
                  expanded: false,
                  onTap: () => _showCategoryDialog(
                    context,
                    entries[index].key,
                    entries[index].value,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 0,
            child: _AllSkillsButton(categories: widget.categories),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.isDesktop(context) ? 5 : 3;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: entries
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: _SkillCard(
                    title: entry.key,
                    skills: entry.value,
                    expanded: _expanded == entry.key,
                    onTap: () => setState(
                      () =>
                          _expanded = _expanded == entry.key ? null : entry.key,
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    String title,
    List<String> skills,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _SkillsDialog(
        title: title,
        categories: {title: skills},
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  final String title;
  final List<String> skills;
  final bool expanded;
  final VoidCallback onTap;

  const _SkillCard({
    required this.title,
    required this.skills,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Semantics(
      button: true,
      expanded: expanded,
      label: '$title, ${skills.length} skills',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: expanded ? 178 : 118,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: expanded
                  ? [t.buttonSoft, t.card]
                  : [t.card.withValues(alpha: 0.76), t.surface],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: expanded ? t.button : t.border),
            boxShadow: expanded
                ? [
                    BoxShadow(
                      color: t.button.withValues(alpha: 0.12),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.subheading.copyWith(fontSize: 15)),
              const Spacer(),
              if (expanded)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: skills.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (_, index) => _SkillChip(skill: skills[index]),
                  ),
                )
              else
                Text(
                  '${skills.length} technologies',
                  style: t.label.copyWith(color: t.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String skill;

  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final learning = skill.endsWith(' - Learning');
    final familiar = skill.endsWith(' - Familiar');
    final label = skill.replaceFirst(RegExp(r' - (Learning|Familiar)$'), '');
    final status = learning
        ? 'Learning'
        : familiar
            ? 'Familiar'
            : null;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: status == null ? t.surface : t.buttonSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: status == null ? t.border : t.button),
      ),
      child: Text(
        status == null ? label : '$label - $status',
        style: t.label.copyWith(color: status == null ? t.text : t.button),
      ),
    );
  }
}

class _AllSkillsButton extends StatelessWidget {
  final Map<String, List<String>> categories;

  const _AllSkillsButton({required this.categories});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Tooltip(
      message: 'View all skills',
      child: Material(
        color: t.card,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _SkillsDialog(
              title: 'Core Skills',
              categories: categories,
            ),
          ),
          icon: const Icon(Icons.more_horiz),
          color: t.button,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        ),
      ),
    );
  }
}

class _SkillsDialog extends StatelessWidget {
  final String title;
  final Map<String, List<String>> categories;

  const _SkillsDialog({required this.title, required this.categories});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: t.heading)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (_, index) {
                    final entry = categories.entries.elementAt(index);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: t.subheading),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: entry.value
                              .map((skill) => _SkillChip(skill: skill))
                              .toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
