import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'technology_icon.dart';

/// Keeps a single offset when the inventory moves between two route subtrees.
/// PageStorage alone cannot preserve it across the inline and dialog buckets.
class SkillsScrollController extends ScrollController {
  double _rememberedOffset = 0;
  SkillsScrollController() : super(keepScrollOffset: false);

  void _remember() {
    if (hasClients && position.hasPixels) _rememberedOffset = position.pixels;
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      ScrollPositionWithSingleContext(
        physics: physics,
        context: context,
        initialPixels: _rememberedOffset,
        keepScrollOffset: false,
        oldPosition: oldPosition,
      );

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    position.addListener(_remember);
  }

  @override
  void detach(ScrollPosition position) {
    if (position.hasPixels) _rememberedOffset = position.pixels;
    position.removeListener(_remember);
    super.detach(position);
  }
}

/// Full inventory: readable at every width, without animated reveal or truncation.
class SkillsInventory extends StatelessWidget {
  final Map<String, List<String>> categories;
  final ScrollController controller;
  const SkillsInventory(
      {super.key, required this.categories, required this.controller});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: SelectionArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(r'$ ls -la ./skills',
                    style: aboutMono(t, size: 13, color: t.text)),
                const SizedBox(height: 20),
                for (final entry in categories.entries) ...[
                  Text(entry.key.toUpperCase(),
                      style: aboutMono(t, size: 11, color: aboutAccent(t))),
                  const SizedBox(height: 6),
                  Text(
                      entry.value
                          .map((s) => s.replaceAll(' - ', ' · '))
                          .join('  /  '),
                      style: aboutMono(t, size: 12, color: t.text)),
                  const SizedBox(height: 20),
                ],
              ])),
        ));
  }
}

class SkillsTerminal extends StatefulWidget {
  final Map<String, List<String>> categories;
  final ScrollController controller;
  final VoidCallback onExpand;
  final FocusNode expandFocus;
  const SkillsTerminal(
      {super.key,
      required this.categories,
      required this.controller,
      required this.onExpand,
      required this.expandFocus});
  @override
  State<SkillsTerminal> createState() => _SkillsTerminalState();
}

class _SkillsTerminalState extends State<SkillsTerminal> {
  Timer? _dwell;
  bool _armed = false;
  void _disarm() {
    _dwell?.cancel();
    if (_armed && mounted) setState(() => _armed = false);
  }

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
          color: t.card,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: t.textMuted.withValues(alpha: .5),
                            shape: BoxShape.circle))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextButton(
                      focusNode: widget.expandFocus,
                      onPressed: widget.onExpand,
                      style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: Text('~/portfolio/skills',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: aboutMono(t, size: 13, color: t.text)))),
            ])),
        Divider(height: 1, color: t.border),
        Expanded(
            child: MouseRegion(
          onEnter: (_) {
            _dwell?.cancel();
            _dwell = Timer(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _armed = true);
            });
          },
          onExit: (_) => _disarm(),
          child: Listener(
              onPointerSignal: (event) {
                if (!_armed ||
                    event is! PointerScrollEvent ||
                    !widget.controller.hasClients) {
                  return;
                }
                final position = widget.controller.position;
                final target = (position.pixels + event.scrollDelta.dy)
                    .clamp(position.minScrollExtent, position.maxScrollExtent);
                if ((target - position.pixels).abs() > .5) {
                  _disarm();
                  // Let this wheel event finish on the original inventory, then move it.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) widget.onExpand();
                  });
                }
              },
              child: SkillsInventory(
                  categories: widget.categories,
                  controller: widget.controller)),
        )),
      ]),
    );
  }
}
