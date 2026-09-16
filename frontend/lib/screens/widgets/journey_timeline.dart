import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/services/secure_link_opener.dart';

class JourneyTimeline extends StatefulWidget {
  final List<JourneyEvent> entries;
  const JourneyTimeline({super.key, required this.entries});

  @override
  State<JourneyTimeline> createState() => _JourneyTimelineState();
}

class _JourneyTimelineState extends State<JourneyTimeline> {
  JourneyEvent? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final mobile = Responsive.isMobile(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (mobile)
        _MobileTimeline(
            entries: widget.entries, selected: _selected, onSelect: _select)
      else
        _DesktopTimeline(
            entries: widget.entries, selected: _selected, onSelect: _select),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _selected == null
            ? const SizedBox(height: AppSpacing.md)
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: _JourneyDetail(
                    entry: _selected!,
                    onClose: () => setState(() => _selected = null)),
              ),
      ),
    ]);
  }

  void _select(JourneyEvent entry) => setState(() => _selected = entry);
}

class _DesktopTimeline extends StatelessWidget {
  final List<JourneyEvent> entries;
  final JourneyEvent? selected;
  final ValueChanged<JourneyEvent> onSelect;
  const _DesktopTimeline(
      {required this.entries, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth / entries.length;
      return SizedBox(
          height: 182,
          child: Stack(children: [
            Positioned(
              left: width / 2,
              right: 0,
              top: 48,
              child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [t.border, t.border, Colors.transparent]))),
            ),
            Row(
                children: entries
                    .map((entry) => SizedBox(
                          width: width,
                          child: _DesktopEvent(
                              entry: entry,
                              selected: selected == entry,
                              onSelect: onSelect),
                        ))
                    .toList()),
            Positioned(
                right: 2,
                top: 39,
                child: Icon(Icons.arrow_forward_rounded,
                    size: 20, color: t.textMuted)),
          ]));
    });
  }
}

class _DesktopEvent extends StatelessWidget {
  final JourneyEvent entry;
  final bool selected;
  final ValueChanged<JourneyEvent> onSelect;
  const _DesktopEvent(
      {required this.entry, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(children: [
      Icon(_iconFor(entry.kind),
          size: 20,
          color: selected || entry.isCurrent ? t.button : t.textMuted),
      const SizedBox(height: 15),
      _Node(entry: entry, selected: selected, onSelect: onSelect),
      const SizedBox(height: AppSpacing.sm),
      Text(entry.shortDate,
          style: t.label.copyWith(
              fontSize: 11, color: selected ? t.button : t.textMuted)),
      const SizedBox(height: 3),
      Text(entry.organization,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.label,
          textAlign: TextAlign.center),
      Text(entry.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.body.copyWith(fontSize: 12, color: t.textMuted),
          textAlign: TextAlign.center),
      if (entry.isCurrent)
        Text('PRESENT', style: t.label.copyWith(fontSize: 10, color: t.button)),
    ]);
  }
}

class _MobileTimeline extends StatelessWidget {
  final List<JourneyEvent> entries;
  final JourneyEvent? selected;
  final ValueChanged<JourneyEvent> onSelect;
  const _MobileTimeline(
      {required this.entries, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
        children: entries
            .map((entry) => IntrinsicHeight(
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      SizedBox(
                          width: 44,
                          child: Column(children: [
                            _Node(
                                entry: entry,
                                selected: selected == entry,
                                onSelect: onSelect),
                            Expanded(
                                child: Container(width: 2, color: t.border)),
                          ])),
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.only(
                            left: AppSpacing.sm, bottom: AppSpacing.lg),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(_iconFor(entry.kind),
                                    size: 17,
                                    color: entry.isCurrent
                                        ? t.button
                                        : t.textMuted),
                                const SizedBox(width: 6),
                                Text(entry.shortDate,
                                    style: t.label.copyWith(color: t.textMuted))
                              ]),
                              Text(entry.organization, style: t.subheading),
                              Text(entry.label,
                                  style: t.body.copyWith(
                                      fontSize: 13, color: t.textMuted)),
                              if (entry.isCurrent)
                                Text('PRESENT',
                                    style: t.label.copyWith(
                                        fontSize: 10, color: t.button)),
                            ]),
                      )),
                    ])))
            .toList());
  }
}

class _Node extends StatelessWidget {
  final JourneyEvent entry;
  final bool selected;
  final ValueChanged<JourneyEvent> onSelect;
  const _Node(
      {required this.entry, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Tooltip(
      message: 'Show details for ${entry.title}',
      child: Semantics(
        button: true,
        label: 'Show details for ${entry.title}',
        child: InkResponse(
          onTap: () => onSelect(entry),
          radius: 22,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected || entry.isCurrent ? t.button : t.surface,
                border: Border.all(
                    color: selected || entry.isCurrent ? t.button : t.border,
                    width: 3)),
            child: selected
                ? Icon(Icons.check_rounded, size: 13, color: t.background)
                : null,
          ),
        ),
      ),
    );
  }
}

class _JourneyDetail extends StatelessWidget {
  final JourneyEvent entry;
  final VoidCallback onClose;
  const _JourneyDetail({required this.entry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: t.card.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: t.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_iconFor(entry.kind), color: t.button, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
              child: Text('${entry.kind.toUpperCase()}  ·  ${entry.date}',
                  style: t.label.copyWith(color: t.button))),
          IconButton(
              tooltip: 'Close details',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: t.textMuted),
        ]),
        Text(entry.title, style: t.subheading),
        if (entry.organization.isNotEmpty)
          Text(entry.organization, style: t.label),
        const SizedBox(height: AppSpacing.sm),
        Text(entry.description, style: t.body),
        if (entry.technologies.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.technologies
                  .map((item) => _TechChip(label: item))
                  .toList()),
        ],
        if (entry.highlights.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ...entry.highlights.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $item', style: t.body.copyWith(fontSize: 13)))),
        ],
        if (entry.link.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
              onPressed: () => openSecureExternalLink(entry.link),
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('View Credential')),
        ],
      ]),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip({required this.label});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: t.label.copyWith(fontSize: 11)));
  }
}

IconData _iconFor(String kind) => switch (kind) {
      'Education' => Icons.school_outlined,
      'Work' => Icons.work_outline_rounded,
      'Certification' => Icons.school_outlined,
      _ => Icons.circle_outlined,
    };
