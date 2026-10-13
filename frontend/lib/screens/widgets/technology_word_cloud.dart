import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/technology.dart';

/// Desktop and tablet word cloud. It renders only a subset at any moment, but
/// cycles every technology from the categories through the same stable slots.
class TechnologyWordCloud extends StatefulWidget {
  final Map<String, List<String>> categories;

  const TechnologyWordCloud({super.key, required this.categories});

  @override
  State<TechnologyWordCloud> createState() => _TechnologyWordCloudState();
}

class _TechnologyWordCloudState extends State<TechnologyWordCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;
  var _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _flowController.stop();
      _flowController.value = 0;
    } else if (!_flowController.isAnimating) {
      _flowController.repeat();
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final technologies = widget.categories.values
        .expand((skills) => skills)
        .map(TechnologyCatalog.fromSkill)
        .where((technology) => seen.add(technology.canonicalName))
        .toList();
    final compact = Responsive.isTablet(context);

    if (_reduceMotion) {
      return _StableTechnologyCloud(
        technologies: technologies,
        compact: compact,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 440,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (var slot = 0;
                slot < math.min(_cloudPositions.length, technologies.length);
                slot++)
              _positionedWord(
                constraints: constraints,
                position: _cloudPositions[slot],
                child: _CloudWord(
                  technologies: technologies,
                  slot: slot,
                  animation: _flowController,
                  compact: compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _positionedWord({
    required BoxConstraints constraints,
    required Offset position,
    required Widget child,
  }) =>
      Positioned(
        left: constraints.maxWidth * position.dx,
        top: 440 * position.dy,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: child,
        ),
      );
}

const _cloudPositions = [
  Offset(0.50, 0.08),
  Offset(0.20, 0.16),
  Offset(0.77, 0.18),
  Offset(0.49, 0.25),
  Offset(0.74, 0.31),
  Offset(0.14, 0.35),
  Offset(0.35, 0.41),
  Offset(0.84, 0.43),
  Offset(0.55, 0.50),
  Offset(0.20, 0.55),
  Offset(0.73, 0.58),
  Offset(0.45, 0.64),
  Offset(0.14, 0.70),
  Offset(0.82, 0.71),
  Offset(0.29, 0.78),
  Offset(0.58, 0.81),
  Offset(0.84, 0.86),
  Offset(0.46, 0.89),
  Offset(0.20, 0.93),
  Offset(0.72, 0.94),
];

class _CloudWord extends StatefulWidget {
  final List<Technology> technologies;
  final int slot;
  final Animation<double> animation;
  final bool compact;

  const _CloudWord({
    required this.technologies,
    required this.slot,
    required this.animation,
    required this.compact,
  });

  @override
  State<_CloudWord> createState() => _CloudWordState();
}

class _CloudWordState extends State<_CloudWord> {
  var _hovered = false;
  var _focused = false;
  double? _pausedAt;

  bool get _isPaused => _hovered || _focused;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() {
      _hovered = value;
      _updatePausedValue();
    });
  }

  void _setFocused(bool value) {
    if (_focused == value) return;
    setState(() {
      _focused = value;
      _updatePausedValue();
    });
  }

  void _updatePausedValue() {
    _pausedAt = _isPaused ? widget.animation.value : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: _setFocused,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, _) {
            final motionValue = _pausedAt ?? widget.animation.value;
            final flow = motionValue * 3 + widget.slot * 0.19;
            final cycle = flow.floor();
            final phase = flow - cycle;
            final technology = widget.technologies[
                (widget.slot + cycle * _cloudPositions.length) %
                    widget.technologies.length];
            final prominence = _prominenceFor(technology.canonicalName);
            final baseColor = _colorFor(t, widget.slot, prominence);
            final color = Color.lerp(
              t.textMuted.withValues(alpha: 0.78),
              baseColor,
              Curves.easeOut.transform((phase / .25).clamp(0, 1)),
            )!;
            final floatPhase = widget.slot * 0.73;
            final offset = Offset(
              math.cos(motionValue * math.pi * 2 + floatPhase) * 2,
              math.sin(motionValue * math.pi * 2 + floatPhase) * 3,
            );
            return Semantics(
              label: '${technology.name} skill',
              child: Opacity(
                opacity: _flowOpacity(phase),
                child: Transform.translate(
                  offset: offset,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    scale: _isPaused ? 1.06 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isPaused ? t.buttonSoft : null,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: _focused
                            ? Border.all(color: t.button.withValues(alpha: .9))
                            : null,
                      ),
                      child: Text(
                        technology.name,
                        style: t.subheading.copyWith(
                          color: _isPaused ? t.text : color,
                          fontSize: _fontSizeFor(prominence, widget.compact),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double _flowOpacity(double phase) {
  if (phase < 0.16) return Curves.easeOut.transform(phase / 0.16);
  if (phase < 0.62) return 1;
  if (phase < 0.82) {
    return 1 - Curves.easeIn.transform((phase - 0.62) / 0.20);
  }
  return 0;
}

_Prominence _prominenceFor(String name) => switch (name) {
      'Python' ||
      'AWS' ||
      'Docker' ||
      'Kubernetes' ||
      'Terraform' ||
      'LLM Integration' ||
      'Generative AI' =>
        _Prominence.high,
      'C++' ||
      'Scala' ||
      'Dart' ||
      'Jenkins' ||
      'Flutter' ||
      'Ansible' ||
      'Prometheus' ||
      'Grafana' ||
      'Django' ||
      'AI Automation' =>
        _Prominence.medium,
      _ => _Prominence.standard,
    };

double _fontSizeFor(_Prominence prominence, bool compact) =>
    switch (prominence) {
      _Prominence.high => compact ? 18.0 : 23.0,
      _Prominence.medium => compact ? 14.0 : 17.0,
      _Prominence.standard => compact ? 11.0 : 13.0,
    };

Color _colorFor(AppThemeData t, int index, _Prominence prominence) {
  if (prominence == _Prominence.high) return t.button;
  if (index % 3 == 0) return const Color(0xFF62C5BC);
  return t.textMuted.withValues(alpha: 0.92);
}

enum _Prominence { high, medium, standard }

class _StableTechnologyCloud extends StatelessWidget {
  final List<Technology> technologies;
  final bool compact;

  const _StableTechnologyCloud({
    required this.technologies,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Wrap(
      spacing: compact ? AppSpacing.sm : AppSpacing.md,
      runSpacing: compact ? AppSpacing.sm : AppSpacing.md,
      children: technologies
          .map(
            (technology) => Text(
              technology.name,
              style: t.label.copyWith(
                color: _colorFor(
                  t,
                  technology.canonicalName.hashCode,
                  _prominenceFor(technology.canonicalName),
                ),
                fontSize: _fontSizeFor(
                    _prominenceFor(technology.canonicalName), compact),
              ),
            ),
          )
          .toList(),
    );
  }
}

class DesktopTabletSkillsLayout extends StatefulWidget {
  final Map<String, List<String>> categories;

  const DesktopTabletSkillsLayout({super.key, required this.categories});

  @override
  State<DesktopTabletSkillsLayout> createState() =>
      _DesktopTabletSkillsLayoutState();
}

class _DesktopTabletSkillsLayoutState extends State<DesktopTabletSkillsLayout> {
  var _terminalExpanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wordCloud = TechnologyWordCloud(categories: widget.categories);
          final terminal = _SkillsTerminal(categories: widget.categories);
          if (constraints.maxWidth < 880) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                wordCloud,
                const SizedBox(height: AppSpacing.lg),
                terminal,
              ],
            );
          }
          final t = AppTheme.of(context);
          final reduceMotion = MediaQuery.of(context).disableAnimations;
          final panelWidth = (constraints.maxWidth - AppSpacing.lg) / 2;
          return SizedBox(
            height: 440,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: panelWidth,
                  child: IgnorePointer(
                    ignoring: _terminalExpanded,
                    child: wordCloud,
                  ),
                ),
                AnimatedPositioned(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  curve: Curves.easeInOutCubicEmphasized,
                  top: _terminalExpanded ? -10 : 0,
                  bottom: _terminalExpanded ? -10 : 0,
                  // Keep the word cloud calm and visible. The terminal grows
                  // into a centred 60% viewport, with breathing room on both
                  // sides, then gains depth.
                  left: _terminalExpanded
                      ? constraints.maxWidth * .20
                      : panelWidth + AppSpacing.lg,
                  right: _terminalExpanded ? constraints.maxWidth * .20 : null,
                  width: _terminalExpanded ? null : panelWidth,
                  child: _SkillsTerminal(
                    categories: widget.categories,
                    fillParent: true,
                    expanded: _terminalExpanded,
                    onExpandedChanged: (expanded) {
                      if (_terminalExpanded == expanded) return;
                      setState(() => _terminalExpanded = expanded);
                    },
                  ),
                ),
                if (_terminalExpanded)
                  Positioned(
                    top: -10,
                    right: constraints.maxWidth * .20 + AppSpacing.md,
                    child: IgnorePointer(
                      child: Text(
                        'ESC to close',
                        style: t.label.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _SkillsTerminal extends StatefulWidget {
  final Map<String, List<String>> categories;
  final bool fillParent;
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  const _SkillsTerminal({
    required this.categories,
    this.fillParent = false,
    this.expanded = false,
    this.onExpandedChanged,
  });

  @override
  State<_SkillsTerminal> createState() => _SkillsTerminalState();
}

class _SkillsTerminalState extends State<_SkillsTerminal> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  Timer? _timer;
  Timer? _collapseTimer;
  Timer? _cursorTimer;
  var _visibleCategories = 0;
  var _started = false;
  var _cursorVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _visibleCategories = widget.categories.length;
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted || _visibleCategories >= widget.categories.length) {
        timer.cancel();
        return;
      }
      setState(() => _visibleCategories += 1);
    });
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      if (!mounted || MediaQuery.of(context).disableAnimations) return;
      setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _collapseTimer?.cancel();
    _cursorTimer?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setExpanded(bool value) {
    if (widget.onExpandedChanged == null) return;
    _collapseTimer?.cancel();
    widget.onExpandedChanged!(value);
  }

  void _scheduleCollapse() {
    if (widget.onExpandedChanged == null) return;
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) widget.onExpandedChanged!(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final mono = GoogleFonts.jetBrainsMono(
      fontSize: Responsive.isTablet(context) ? 11.5 : 13,
      height: 1.48,
      color: t.text,
    );
    final entries = widget.categories.entries.toList();
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _setExpanded,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            widget.expanded) {
          _setExpanded(false);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) => Listener(
          onPointerSignal: (event) {
            if (event is! PointerScrollEvent) return;
            // The outer 12.5% on each side remains inactive. Scrolling inside
            // the central 75% is deliberate intent to inspect the inventory.
            final inset = constraints.maxWidth * .125;
            final insideActivationArea = event.localPosition.dx >= inset &&
                event.localPosition.dx <= constraints.maxWidth - inset;
            if (insideActivationArea) _setExpanded(true);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.basic,
            onExit: (_) => _scheduleCollapse(),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _focusNode.requestFocus();
                _setExpanded(true);
              },
              child: Container(
                height: widget.fillParent ? null : 440,
                decoration: BoxDecoration(
                  color: t.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.border),
                  boxShadow: widget.expanded
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .42),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 34,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
                          Text('~/portfolio/skills — zsh',
                              style: mono.copyWith(
                                  fontSize: 10, color: t.textMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: mono.copyWith(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: 'ranjith@portfolio',
                                    style: mono.copyWith(
                                      color: t.neonGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ':',
                                    style: mono.copyWith(color: t.textMuted),
                                  ),
                                  TextSpan(
                                    text: '~/profile/skills',
                                    style: mono.copyWith(color: t.button),
                                  ),
                                  TextSpan(
                                    text: r' $ ',
                                    style: mono.copyWith(
                                      color: t.neonGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ls -la',
                                    style: mono.copyWith(
                                      color: t.text,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _TerminalInventoryHeader(
                              style: mono,
                              expanded: widget.expanded,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...entries.take(_visibleCategories).map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _TerminalCategory(
                                      entry: entry,
                                      style: mono,
                                      expanded: widget.expanded,
                                    ),
                                  ),
                                ),
                          ],
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
                      child: Text(
                        _cursorVisible ||
                                MediaQuery.of(context).disableAnimations
                            ? r'$ _'
                            : r'$  ',
                        style: mono.copyWith(color: t.neonGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
  final bool expanded;
  const _TerminalCategory({
    required this.entry,
    required this.style,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final groupWidth = Responsive.isTablet(context)
        ? 146.0
        : expanded
            ? 230.0
            : 216.0;
    final groupStyle = style.copyWith(
      color: t.button,
      fontSize: Responsive.isTablet(context)
          ? 10
          : expanded
              ? 12.5
              : 12,
    );
    final toolkitStyle = style.copyWith(
      color: t.text,
      fontSize: Responsive.isTablet(context)
          ? 10.5
          : expanded
              ? 12.5
              : 11.5,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: groupWidth,
          child: Text(
            _terminalGroupName(entry.key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: groupStyle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: toolkitStyle,
              children: [
                for (var index = 0; index < entry.value.length; index++) ...[
                  if (index > 0)
                    TextSpan(
                      text: '\u2009•\u2009',
                      style: toolkitStyle.copyWith(
                        color: t.button.withValues(alpha: .58),
                      ),
                    ),
                  TextSpan(text: _terminalSkillName(entry.value[index])),
                ],
              ],
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TerminalInventoryHeader extends StatelessWidget {
  final TextStyle style;
  final bool expanded;

  const _TerminalInventoryHeader({
    required this.style,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final groupWidth = Responsive.isTablet(context)
        ? 146.0
        : expanded
            ? 230.0
            : 216.0;
    return Row(
      children: [
        SizedBox(
          width: groupWidth,
          child: Text('GROUP', style: style.copyWith(color: t.textMuted)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('TOOLKIT', style: style.copyWith(color: t.textMuted)),
        ),
      ],
    );
  }
}

String _terminalGroupName(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
}

String _terminalSkillName(String value) {
  final parts = value.split(' - ');
  return parts.length == 2 ? '${parts.first} (${parts.last})' : value;
}
