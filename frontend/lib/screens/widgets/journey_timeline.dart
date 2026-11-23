import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/services/secure_link_opener.dart';

/// Opens the journey sideways. The floating detail lives in the overlay so
/// opening even a long entry never changes the layout of the Work section.
class JourneyTimeline extends StatefulWidget {
  final List<JourneyEvent> entries;
  const JourneyTimeline({super.key, required this.entries});

  @override
  State<JourneyTimeline> createState() => _JourneyTimelineState();
}

class _JourneyTimelineState extends State<JourneyTimeline> {
  final _scroll = ScrollController();
  final _portal = OverlayPortalController();
  final _frame = GlobalKey();
  ScrollPosition? _pageScroll;
  _JourneyLayout? _target;
  int? _selected;
  int _lastSelected = 0;
  int _selectionRevision = 0;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _selected != null) {
      _close();
      return true;
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (_pageScroll != position) {
      _pageScroll?.removeListener(_onPageScroll);
      _pageScroll = position?..addListener(_onPageScroll);
    }
  }

  void _onPageScroll() {
    if (_selected != null) _close();
  }

  @override
  void didUpdateWidget(covariant JourneyTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null && _selected! >= widget.entries.length) _close();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _pageScroll?.removeListener(_onPageScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _close() {
    _selectionRevision++;
    _portal.hide();
    if (_selected != null) setState(() => _selected = null);
  }

  void _select(int index) {
    if (_selected == index) {
      _close();
      return;
    }
    final revision = ++_selectionRevision;
    _portal.hide();
    setState(() {
      _selected = index;
      _lastSelected = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || revision != _selectionRevision || !_scroll.hasClients) {
        return;
      }
      final target = _target!;
      final offset = (target.cardCenter - _viewportWidth / 2)
          .clamp(0.0, math.max(0.0, target.width - _viewportWidth))
          .toDouble();
      await _scroll.animateTo(offset,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 360),
          curve: Curves.easeInOutCubic);
      if (mounted && revision == _selectionRevision) _portal.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final t = AppTheme.of(context);
    final mobile = Responsive.isMobile(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final cardWidth = math.min(320.0, MediaQuery.sizeOf(context).width - 24);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 360);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) => _floatingCard(cardWidth),
        child: LayoutBuilder(builder: (context, constraints) {
          _viewportWidth = constraints.maxWidth;
          final count = widget.entries.length;
          final width = math.max(constraints.maxWidth, count * 148.0);
          final closed = _JourneyLayout.closed(width, count, _lastSelected);
          _target = _selected == null
              ? closed
              : _JourneyLayout.open(width, count, _selected!, cardWidth);
          return SizedBox(
            key: _frame,
            height: mobile ? 162 : 154,
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (notification) {
                if (notification.dragDetails != null) _close();
                return false;
              },
              child: Scrollbar(
                controller: _scroll,
                // Mobile keeps the curved strip clean: swipe alone navigates.
                thumbVisibility: !mobile && width > constraints.maxWidth,
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  child: TweenAnimationBuilder<_JourneyLayout>(
                    tween: _JourneyLayoutTween(begin: closed, end: _target!),
                    duration: duration,
                    curve: Curves.easeInOutCubic,
                    builder: (context, layout, _) => SizedBox(
                      width: layout.width,
                      height: mobile ? 162 : 154,
                      child: Stack(children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _close,
                            child: CustomPaint(
                              painter: _JourneyLinePainter(
                                layout: layout,
                                color: t.border,
                                accent: t.button,
                                selected: _selected ?? _lastSelected,
                              ),
                            ),
                          ),
                        ),
                        for (var i = 0; i < count; i++)
                          Positioned(
                            left: layout.centers[i] - 68,
                            top: 0,
                            width: 136,
                            height: 150,
                            child: _JourneyMarker(
                              entry: widget.entries[i],
                              lineY: _snakeY(i, count),
                              labelAbove: i.isEven,
                              selected: _selected == i,
                              onTap: () => _select(i),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _floatingCard(double width) {
    if (_selected == null || _selected! >= widget.entries.length) {
      return const SizedBox.shrink();
    }
    final size = MediaQuery.sizeOf(context);
    final safeTop =
        math.min(MediaQuery.paddingOf(context).top + 88, size.height * .2);
    final height = math.min(300.0, math.max(80.0, size.height - safeTop - 24));
    return AnimatedBuilder(
      animation: _scroll,
      builder: (context, _) {
        final box = _frame.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return const SizedBox.shrink();
        final point = box.localToGlobal(Offset.zero) +
            Offset(
              _target!.cardCenter - _scroll.offset,
              _snakeY(_selected!, widget.entries.length),
            );
        final centerX =
            point.dx.clamp(12 + width / 2, size.width - 12 - width / 2);
        final centerY =
            point.dy.clamp(safeTop + height / 2, size.height - 20 - height / 2);
        return Positioned(
          left: centerX - width / 2,
          top: centerY - height / 2,
          child: SizedBox(
            width: width,
            height: height,
            child: _FloatingJourneyCard(
              key: ValueKey(widget.entries[_selected!].sortDate),
              entry: widget.entries[_selected!],
              onClose: _close,
            ),
          ),
        );
      },
    );
  }
}

class _JourneyLayout {
  final double width;
  final List<double> centers;
  final double cardCenter;
  final double gapWidth;
  const _JourneyLayout(
      this.width, this.centers, this.cardCenter, this.gapWidth);

  factory _JourneyLayout.closed(double width, int count, int lastSelected) {
    final centers = List.generate(count, (i) => width * (i + .5) / count);
    return _JourneyLayout(
        width, centers, centers[lastSelected.clamp(0, count - 1)], 0);
  }

  factory _JourneyLayout.open(
      double baseWidth, int count, int selected, double cardWidth) {
    final gap = cardWidth + 32;
    final width = math.max(baseWidth, (count - 1) * 136.0 + gap + 48);
    final leftCount = selected;
    final rightCount = count - selected - 1;
    final minimum = leftCount * 136 + gap / 2 + 24;
    final maximum = width - rightCount * 136 - gap / 2 - 24;
    final center =
        (baseWidth * (selected + .5) / count).clamp(minimum, maximum);
    final leftEnd = center - gap / 2;
    final rightStart = center + gap / 2;
    return _JourneyLayout(
        width,
        List.generate(count, (i) {
          if (i < selected) return leftEnd * (i + .5) / leftCount;
          if (i > selected) {
            return rightStart +
                (width - rightStart) * (i - selected - .5) / rightCount;
          }
          return center;
        }),
        center,
        gap);
  }
}

class _JourneyLayoutTween extends Tween<_JourneyLayout> {
  _JourneyLayoutTween(
      {required _JourneyLayout begin, required _JourneyLayout end})
      : super(begin: begin, end: end);

  @override
  _JourneyLayout lerp(double t) => _JourneyLayout(
        lerpDouble(begin!.width, end!.width, t)!,
        List.generate(
            end!.centers.length,
            (i) => lerpDouble(
                i < begin!.centers.length ? begin!.centers[i] : end!.centers[i],
                end!.centers[i],
                t)!),
        lerpDouble(begin!.cardCenter, end!.cardCenter, t)!,
        lerpDouble(begin!.gapWidth, end!.gapWidth, t)!,
      );
}

double _snakeY(int index, int count) =>
    72 + (count < 2 ? 0 : math.sin(index / (count - 1) * math.pi * 2) * 13);

class _JourneyMarker extends StatelessWidget {
  final JourneyEvent entry;
  final double lineY;
  final bool labelAbove;
  final bool selected;
  final VoidCallback onTap;
  const _JourneyMarker(
      {required this.entry,
      required this.lineY,
      required this.labelAbove,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final accent = selected || entry.isCurrent;
    final label = Column(mainAxisSize: MainAxisSize.min, children: [
      Text(entry.shortDate,
          style: t.label
              .copyWith(fontSize: 11, color: accent ? t.button : t.textMuted)),
      const SizedBox(height: 3),
      Text(entry.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: t.label.copyWith(color: t.text)),
      if (entry.isCurrent)
        Text('PRESENT', style: t.label.copyWith(fontSize: 10, color: t.button)),
    ]);
    return MergeSemantics(
        child: Semantics(
      selected: selected,
      label: 'Show details for ${entry.title}',
      child: Tooltip(
        excludeFromSemantics: true,
        message: '${entry.title} · ${entry.organization}',
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: t.button,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: ExcludeSemantics(
              child: Stack(children: [
            Positioned(
                left: 0,
                right: 0,
                top: labelAbove ? math.max(0, lineY - 66) : lineY + 18,
                child: label),
            Positioned(
                left: 59,
                top: lineY - 9,
                child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent ? t.button : t.background,
                        border: Border.all(
                            color: accent ? t.button : t.textMuted,
                            width: 1.5)))),
          ])),
        ),
      ),
    ));
  }
}

class _JourneyLinePainter extends CustomPainter {
  final _JourneyLayout layout;
  final Color color;
  final Color accent;
  final int? selected;
  const _JourneyLinePainter(
      {required this.layout,
      required this.color,
      required this.accent,
      required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, 72);
    var previous = const Offset(0, 72);
    for (var i = 0; i < layout.centers.length; i++) {
      final next = Offset(layout.centers[i], _snakeY(i, layout.centers.length));
      final middle = (previous.dx + next.dx) / 2;
      path.cubicTo(middle, previous.dy, middle, next.dy, next.dx, next.dy);
      previous = next;
    }
    path.cubicTo((previous.dx + size.width) / 2, previous.dy,
        (previous.dx + size.width) / 2, 72, size.width, 72);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = color;
    if (layout.gapWidth < 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final left = layout.cardCenter - layout.gapWidth / 2;
    final right = layout.cardCenter + layout.gapWidth / 2;
    for (final rect in [
      Rect.fromLTWH(0, 0, left, size.height),
      Rect.fromLTWH(right, 0, size.width - right, size.height)
    ]) {
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
    // The two rounded endpoints make the opening visible even before the card
    // arrives; the original curved path remains on either side.
    final y = _snakeY(selected ?? 0, layout.centers.length);
    canvas.drawCircle(Offset(left, y), 3, Paint()..color = accent);
    canvas.drawCircle(Offset(right, y), 3, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _JourneyLinePainter old) =>
      old.layout != layout ||
      old.color != color ||
      old.accent != accent ||
      old.selected != selected;
}

class _FloatingJourneyCard extends StatelessWidget {
  final JourneyEvent entry;
  final VoidCallback onClose;
  const _FloatingJourneyCard(
      {super.key, required this.entry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Material(
      key: const ValueKey('journey-floating-card'),
      color: t.card,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: .3),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: t.button.withValues(alpha: .65))),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: t.button, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(entry.kind.toUpperCase(),
                    style: t.label.copyWith(fontSize: 11, color: t.button))),
            IconButton(
                tooltip: 'Close journey details',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 20)),
          ]),
        ),
        Expanded(
            child: SingleChildScrollView(
          key: ValueKey('journey-details-${entry.sortDate}-${entry.title}'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.date,
                style: t.label.copyWith(fontSize: 11, color: t.button)),
            const SizedBox(height: 6),
            Text(entry.title, style: t.subheading.copyWith(fontSize: 16)),
            if (entry.organization.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.organization, style: t.label),
            ],
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.description, style: t.body.copyWith(fontSize: 13)),
            ],
            for (final item in entry.highlights)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('• $item', style: t.body.copyWith(fontSize: 12))),
            if (entry.technologies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.technologies.join(' · '),
                  style: t.label.copyWith(fontSize: 12)),
            ],
            if (entry.link.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: () => openSecureExternalLink(entry.link),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View Credential')),
            ],
          ]),
        )),
      ]),
    );
  }
}
