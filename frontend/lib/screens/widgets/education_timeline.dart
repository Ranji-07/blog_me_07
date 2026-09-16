import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/about_profile.dart';
import 'package:url_launcher/url_launcher.dart';

class EducationTimeline extends StatefulWidget {
  final List<EducationTimelineEntry> entries;
  const EducationTimeline({super.key, required this.entries});
  @override
  State<EducationTimeline> createState() => _EducationTimelineState();
}

class _EducationTimelineState extends State<EducationTimeline> {
  int _selected = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    if (widget.entries.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted && Responsive.isMobile(context)) {
          setState(() => _selected = (_selected + 1) % widget.entries.length);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final mobile = Responsive.isMobile(context);
    final selected = widget.entries[_selected];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (mobile)
        _MobileEntry(entry: selected, onTap: () => _showTimelineDialog(context))
      else
        _DesktopTimeline(
            entries: widget.entries,
            selected: _selected,
            onSelect: (value) => setState(() => _selected = value)),
      const SizedBox(height: AppSpacing.md),
      _TimelineDetail(entry: selected),
    ]);
  }

  void _showTimelineDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Education & Certifications'),
        content: SizedBox(
          width: 360,
          height: 420,
          child: ListView.separated(
            itemCount: widget.entries.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final item = widget.entries[index];
              return ListTile(
                leading: CircleAvatar(child: Text(item.year)),
                title: Text(item.title),
                subtitle: Text(item.type),
                onTap: () {
                  setState(() => _selected = index);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DesktopTimeline extends StatelessWidget {
  final List<EducationTimelineEntry> entries;
  final int selected;
  final ValueChanged<int> onSelect;
  const _DesktopTimeline(
      {required this.entries, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Row(
        children: List.generate(
            entries.length,
            (index) => Expanded(
                    child: Column(children: [
                  Text(entries[index].year, style: t.label),
                  Row(children: [
                    Expanded(
                        child: Container(
                            height: 1,
                            color: index == 0 ? Colors.transparent : t.border)),
                    IconButton(
                        onPressed: () => onSelect(index),
                        color: index == selected ? t.button : t.textMuted,
                        icon: Icon(index == selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked)),
                    Expanded(
                        child: Container(
                            height: 1,
                            color: index == entries.length - 1
                                ? Colors.transparent
                                : t.border))
                  ]),
                  Text(entries[index].type,
                      style: t.label, textAlign: TextAlign.center)
                ]))));
  }
}

class _MobileEntry extends StatelessWidget {
  final EducationTimelineEntry entry;
  final VoidCallback onTap;
  const _MobileEntry({required this.entry, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(Icons.radio_button_checked, color: t.button),
          const SizedBox(width: AppSpacing.sm),
          Text(entry.year, style: t.heading),
          const SizedBox(width: AppSpacing.sm),
          Text(entry.type, style: t.label),
          const Spacer(),
          const Icon(Icons.unfold_more)
        ]));
  }
}

class _TimelineDetail extends StatelessWidget {
  final EducationTimelineEntry entry;
  const _TimelineDetail({required this.entry});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Container(
            key: ValueKey(entry.year + entry.title),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
                color: t.card.withValues(alpha: 0.55),
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.year, style: t.label.copyWith(color: t.button)),
              const SizedBox(height: AppSpacing.xs),
              Text(entry.title, style: t.subheading),
              Text(entry.organization, style: t.body),
              Text(entry.date, style: t.label),
              const SizedBox(height: AppSpacing.sm),
              Text(entry.description, style: t.body),
              if (entry.credentialId.isNotEmpty)
                Text('Credential ID: ${entry.credentialId}', style: t.label),
              if (entry.certificateUrl.isNotEmpty)
                TextButton(
                    onPressed: () => launchUrl(Uri.parse(entry.certificateUrl),
                        mode: LaunchMode.externalApplication),
                    child: const Text('View Certificate'))
            ])));
  }
}
