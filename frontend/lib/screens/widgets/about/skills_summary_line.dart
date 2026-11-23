import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/technology.dart';
import 'technology_icon.dart';

/// One calm line of every skill name, separated by middle dots, that drifts
/// sideways only when it cannot fit. The plain arrow at its end opens the
/// full skills view.
class SkillsSummaryLine extends StatefulWidget {
  final List<Technology> technologies;
  final FocusNode focusNode;
  final VoidCallback onOpen;

  const SkillsSummaryLine({
    super.key,
    required this.technologies,
    required this.focusNode,
    required this.onOpen,
  });

  @override
  State<SkillsSummaryLine> createState() => _SkillsSummaryLineState();
}

class _SkillsSummaryLineState extends State<SkillsSummaryLine>
    with SingleTickerProviderStateMixin {
  late final _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 34));
  final GlobalKey _cycleKey = GlobalKey();
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  int _touches = 0;
  double _cycleWidth = 0;
  double _availableWidth = 0;

  String get _names => widget.technologies
      .map((technology) => technology.canonicalName)
      .join(' · ');

  bool get _overflowing =>
      _cycleWidth > 0 &&
      _availableWidth > 0 &&
      _cycleWidth - 28 > _availableWidth;

  void _sync() {
    if (!mounted) return;
    if (_hovered ||
        _focused ||
        _touches > 0 ||
        !_overflowing ||
        MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measure();
    _sync();
  }

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _cycleKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return;
      final width = box.size.width;
      if (width > 0 && width != _cycleWidth) {
        setState(() => _cycleWidth = width);
        _sync();
      }
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final names = _names;
    final text = Text(names,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: aboutMono(t, size: 12, color: t.textMuted));

    Widget line = LayoutBuilder(builder: (context, constraints) {
      _availableWidth = constraints.maxWidth;
      if (!_overflowing || MediaQuery.disableAnimationsOf(context)) {
        return SingleChildScrollView(
            scrollDirection: Axis.horizontal, child: text);
      }
      return ClipRect(
          child: AnimatedBuilder(
        animation: _motion,
        builder: (_, child) => Transform.translate(
            offset: Offset(-_cycleWidth * _motion.value, 0), child: child),
        child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            child: Row(children: [
              for (var copy = 0; copy < 3; copy++)
                Padding(
                    key: copy == 0 ? _cycleKey : null,
                    padding: const EdgeInsets.only(right: 28),
                    child: text),
            ])),
      ));
    });

    return Row(children: [
      Expanded(
          child: Focus(
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
            child: ExcludeSemantics(
                child: Semantics(
                    label: 'Skills overview: $names',
                    child: SizedBox(height: 22, child: line))),
          ),
        ),
      )),
      const SizedBox(width: 10),
      Semantics(
        button: true,
        label: 'Open all skills',
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          enabled: true,
          mouseCursor: SystemMouseCursors.click,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onOpen();
              return null;
            }),
          },
          child: Listener(
            onPointerDown: (_) {
              setState(() => _pressed = true);
              _touches++;
              _sync();
            },
            onPointerUp: (_) {
              setState(() => _pressed = false);
              if (_touches > 0) _touches--;
              _sync();
            },
            onPointerCancel: (_) {
              setState(() => _pressed = false);
              if (_touches > 0) _touches--;
              _sync();
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 20, color: _pressed ? t.textMuted : aboutAccent(t)),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
