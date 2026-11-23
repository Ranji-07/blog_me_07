import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/technology.dart';
import 'technology_icon.dart';

class CoreStackHoneycomb extends StatefulWidget {
  final List<Technology> technologies;
  const CoreStackHoneycomb({super.key, required this.technologies});
  @override
  State<CoreStackHoneycomb> createState() => _CoreStackHoneycombState();
}

class _CoreStackHoneycombState extends State<CoreStackHoneycomb> {
  Offset _pan = Offset.zero;
  bool _dragging = false;
  static const _axial = [
    Offset(0, 0),
    Offset(1, 0),
    Offset(0, 1),
    Offset(-1, 1),
    Offset(-1, 0),
    Offset(0, -1),
    Offset(1, -1),
    Offset(0, -2),
    Offset(2, -2),
    Offset(2, 0),
    Offset(0, 2),
    Offset(-2, 2),
    Offset(-2, 0),
    Offset(1, -2)
  ];

  Offset _point(int index) {
    final a = _axial[index];
    return Offset(a.dx * 56 + a.dy * 28, a.dy * 49);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final count = math.min(widget.technologies.length, _axial.length);
    if (count == 0) return const SizedBox.shrink();
    var selected = 0;
    for (var i = 1; i < count; i++) {
      if ((_point(i) + _pan).distance < (_point(selected) + _pan).distance) {
        selected = i;
      }
    }
    final duration = _dragging || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    return Semantics(
      label:
          'Core technology explorer. Drag to pan or select a named technology.',
      child: LayoutBuilder(builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, 154);
        Widget bubble(int i) {
          final technology = widget.technologies[i];
          final relative = _point(i) + _pan;
          // Leave breathing room below the focused icon for its name chip.
          final labelSpace =
              relative.dy > 0 ? math.min(18.0, relative.dy * .37) : 0.0;
          final position = center + relative + Offset(0, labelSpace);
          return AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOut,
            left: position.dx - 24,
            top: position.dy - 24,
            width: 48,
            height: 48,
            child: MergeSemantics(
                child: Semantics(
              label: 'Select ${technology.canonicalName}',
              selected: selected == i,
              child: Tooltip(
                message: technology.canonicalName,
                excludeFromSemantics: true,
                child: TextButton(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor:
                          selected == i ? t.buttonSoft : Colors.transparent),
                  onPressed: () => setState(() {
                    _dragging = false;
                    _pan = -_point(i);
                  }),
                  child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        TechnologyIcon(
                            technology: technology,
                            size: selected == i ? 36 : 30,
                            selected: selected == i),
                        if (selected == i)
                          Positioned(
                              top: 47,
                              child: ExcludeSemantics(
                                  child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1),
                                decoration: BoxDecoration(
                                    color: t.card,
                                    border: Border.all(
                                        color: aboutAccent(t)
                                            .withValues(alpha: .5)),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(technology.canonicalName,
                                    style: aboutMono(t,
                                        size: 11, color: aboutAccent(t))),
                              ))),
                      ]),
                ),
              ),
            )),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => setState(() => _dragging = true),
          onPanUpdate: (event) => setState(() {
            _pan = Offset((_pan.dx + event.delta.dx).clamp(-140.0, 140.0),
                (_pan.dy + event.delta.dy).clamp(-130.0, 130.0));
          }),
          onPanEnd: (_) => setState(() => _dragging = false),
          onPanCancel: () => setState(() => _dragging = false),
          child: SizedBox(
              height: 328,
              child: ClipRect(
                  child: Stack(children: [
                for (var i = 0; i < count; i++)
                  if (i != selected) bubble(i),
                bubble(selected),
              ]))),
        );
      }),
    );
  }
}
