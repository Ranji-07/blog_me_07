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

  /// Axial (q, r) coordinates for a full hexagon of cells: the centre, then
  /// one ring at a time, so every technology with a logo keeps a slot no
  /// matter how many the profile lists.
  static List<Offset> _cellsFor(int count) {
    final cells = <Offset>[Offset.zero];
    for (var ring = 1; cells.length < count; ring++) {
      for (var q = -ring; q <= ring; q++) {
        for (var r = -ring; r <= ring; r++) {
          final distance = (q.abs() + r.abs() + (q + r).abs()) ~/ 2;
          if (distance == ring && cells.length < count) {
            cells.add(Offset(q.toDouble(), r.toDouble()));
          }
        }
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final cells = _cellsFor(widget.technologies.length);
    final count = cells.length;
    if (count == 0) return const SizedBox.shrink();
    // Wide fields (a third ring) tighten the pitch so every icon stays
    // inside the frame; one or two rings keep the roomier spacing.
    final pitch = count > 19 ? 44.0 : 56.0;
    final pitchY = count > 19 ? 38.5 : 49.0;
    Offset point(int index) {
      final cell = cells[index];
      return Offset(cell.dx * pitch + cell.dy * pitch / 2, cell.dy * pitchY);
    }

    var selected = 0;
    for (var i = 1; i < count; i++) {
      if ((point(i) + _pan).distance < (point(selected) + _pan).distance) {
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
          final relative = point(i) + _pan;
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
                    _pan = -point(i);
                  }),
                  child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        TechnologyIcon(
                            technology: technology,
                            size: selected == i ? 36 : 30,
                            selected: selected == i,
                            removeServiceBackground: true),
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
