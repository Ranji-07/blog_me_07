import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/technology.dart';
import 'technology_icon.dart';

class TechnologyFeeder extends StatefulWidget {
  final List<Technology> technologies;
  final bool paused;
  const TechnologyFeeder(
      {super.key, required this.technologies, required this.paused});
  @override
  State<TechnologyFeeder> createState() => _TechnologyFeederState();
}

class _TechnologyFeederState extends State<TechnologyFeeder>
    with SingleTickerProviderStateMixin {
  late final _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 42));
  bool _hovered = false;
  bool _focused = false;
  int _touches = 0;

  void _sync() {
    if (widget.paused ||
        _hovered ||
        _focused ||
        _touches > 0 ||
        MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant TechnologyFeeder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _row(List<Technology> items, bool reverse) {
    if (items.isEmpty) return const SizedBox.shrink();
    final t = AppTheme.of(context);
    Widget strip(int copies) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var copy = 0; copy < copies; copy++)
            for (final technology in items)
              ExcludeSemantics(
                excluding: copy > 0,
                child: SizedBox(
                  width: 104,
                  height: 54,
                  child: Tooltip(
                    message: technology.name,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TechnologyIcon(technology: technology),
                          const SizedBox(height: 5),
                          Text(technology.canonicalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aboutMono(t, size: 11)),
                        ]),
                  ),
                ),
              ),
        ]);
    if (MediaQuery.disableAnimationsOf(context)) {
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal, child: strip(1));
    }
    final cycleWidth = items.length * 104.0;
    return ClipRect(
        child: SizedBox(
            height: 54,
            child: AnimatedBuilder(
              animation: _motion,
              builder: (_, child) => Transform.translate(
                offset: Offset(
                    reverse
                        ? -cycleWidth + cycleWidth * _motion.value
                        : -cycleWidth * _motion.value,
                    0),
                child: child,
              ),
              child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: double.infinity,
                  child: strip(3)),
            )));
  }

  @override
  Widget build(BuildContext context) {
    final split = (widget.technologies.length / 2).ceil();
    return Focus(
      onFocusChange: (focused) {
        _focused = focused;
        _sync();
      },
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _sync();
        },
        onExit: (_) {
          _hovered = false;
          _sync();
        },
        child: Listener(
          onPointerDown: (_) {
            _touches++;
            _sync();
          },
          onPointerUp: (_) {
            if (_touches > 0) _touches--;
            _sync();
          },
          onPointerCancel: (_) {
            if (_touches > 0) _touches--;
            _sync();
          },
          child: Semantics(
              label: 'Also familiar with. Additional technologies.',
              child: Column(children: [
                _row(widget.technologies.take(split).toList(), false),
                _row(widget.technologies.skip(split).toList(), true),
              ])),
        ),
      ),
    );
  }
}
