import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';

class SkillCategoryGrid extends StatefulWidget {
  final Map<String, List<String>> categories;

  const SkillCategoryGrid({super.key, required this.categories});

  @override
  State<SkillCategoryGrid> createState() => _SkillCategoryGridState();
}

class _SkillCategoryGridState extends State<SkillCategoryGrid> {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What I Work With', style: t.heading.copyWith(color: t.button)),
        const SizedBox(height: AppSpacing.md),
        if (Responsive.isDesktop(context))
          SizedBox(
            height: 440,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VisualSkillWall(
                    categories: widget.categories,
                    onTap: _showCategoryDialog,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _TerminalSkillsView(
                    categories: widget.categories,
                    fixedHeight: true,
                  ),
                ),
              ],
            ),
          )
        else
          _TerminalSkillsView(categories: widget.categories),
      ],
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    String title,
    List<String> skills,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _SkillsDialog(title: title, categories: {title: skills}),
    );
  }
}

class _VisualSkillWall extends StatelessWidget {
  final Map<String, List<String>> categories;
  final void Function(BuildContext, String, List<String>) onTap;

  const _VisualSkillWall({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 3;
        final width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: entries
              .map(
                (entry) => SizedBox(
                  width: width,
                  child: _SkillCard(
                    title: entry.key,
                    skills: entry.value,
                    expanded: false,
                    showIcon: true,
                    onTap: () => onTap(context, entry.key, entry.value),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SkillCard extends StatefulWidget {
  final String title;
  final List<String> skills;
  final bool expanded;
  final bool showIcon;
  final VoidCallback onTap;

  const _SkillCard({
    required this.title,
    required this.skills,
    required this.expanded,
    this.showIcon = false,
    required this.onTap,
  });

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Semantics(
      button: true,
      expanded: widget.expanded,
      label: '${widget.title}, ${widget.skills.length} skills',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
            height: widget.expanded ? 162 : 94,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.expanded || _hovered
                    ? [t.buttonSoft, t.card]
                    : [t.card.withValues(alpha: 0.76), t.surface],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.expanded || _hovered ? t.button : t.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.showIcon) ...[
                      Icon(_skillIcon(widget.title), size: 16, color: t.button),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: t.subheading.copyWith(fontSize: 15),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _hovered || widget.expanded ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        widget.expanded ? Icons.remove : Icons.arrow_forward,
                        size: 16,
                        color: t.button,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.expanded)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.skills
                        .map((skill) => _SkillChip(skill: skill))
                        .toList(),
                  )
                else
                  Text(
                    '${widget.skills.length} technologies',
                    style: t.label.copyWith(color: t.button),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _skillIcon(String title) => switch (title) {
      'Programming & Scripting' => Icons.code_rounded,
      'Cloud & Infrastructure' => Icons.cloud_outlined,
      'Containers & Orchestration' => Icons.inventory_2_outlined,
      'CI/CD & Automation' => Icons.precision_manufacturing_outlined,
      'Infrastructure as Code' => Icons.account_tree_outlined,
      'Monitoring & Observability' => Icons.monitor_heart_outlined,
      'Backend & APIs' => Icons.api_outlined,
      'AI / ML' => Icons.smart_toy_outlined,
      'Frontend' => Icons.devices_outlined,
      'Embedded / IoT' => Icons.memory_outlined,
      _ => Icons.source_outlined,
    };

class _TerminalSkillsView extends StatefulWidget {
  final Map<String, List<String>> categories;
  final bool fixedHeight;

  const _TerminalSkillsView({
    required this.categories,
    this.fixedHeight = false,
  });

  @override
  State<_TerminalSkillsView> createState() => _TerminalSkillsViewState();
}

class _TerminalSkillsViewState extends State<_TerminalSkillsView> {
  Timer? _timer;
  final _scrollController = ScrollController();
  int _visibleCategories = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted || _visibleCategories >= widget.categories.length) {
        timer.cancel();
        return;
      }
      setState(() => _visibleCategories += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final mono = GoogleFonts.jetBrainsMono(
      fontSize: Responsive.isMobile(context) ? 12 : 13,
      height: 1.65,
      color: t.text,
    );
    final entries = widget.categories.entries.toList();
    final terminalHeight = widget.fixedHeight
        ? 440.0
        : (132.0 + _visibleCategories * 34).clamp(156.0, 440.0).toDouble();
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 880),
      height: terminalHeight,
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                _TerminalLight(color: const Color(0xFFEF6A5B)),
                const SizedBox(width: 5),
                _TerminalLight(color: const Color(0xFFF4BE4F)),
                const SizedBox(width: 5),
                _TerminalLight(color: t.neonGreen),
                const Spacer(),
                Text('skills',
                    style: mono.copyWith(fontSize: 11, color: t.textMuted)),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r'$ skills --list',
                        style: mono.copyWith(color: t.button)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('> Loading technical toolkit...',
                        style: mono.copyWith(color: t.textMuted)),
                    const SizedBox(height: AppSpacing.md),
                    ...entries.take(_visibleCategories).map(
                          (entry) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _TerminalCategory(entry: entry, style: mono),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(r'$ _', style: mono.copyWith(color: t.neonGreen)),
          ),
        ],
      ),
    );
  }
}

class _TerminalLight extends StatelessWidget {
  final Color color;

  const _TerminalLight({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _TerminalCategory extends StatelessWidget {
  final MapEntry<String, List<String>> entry;
  final TextStyle style;

  const _TerminalCategory({required this.entry, required this.style});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Text('${entry.key.toUpperCase()} ---',
            style: style.copyWith(color: t.button)),
        ...entry.value.map(
          (skill) => Text(
            skill.replaceAll(' - ', ' [') + (skill.contains(' - ') ? ']' : ''),
            style: style,
          ),
        ),
      ],
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
