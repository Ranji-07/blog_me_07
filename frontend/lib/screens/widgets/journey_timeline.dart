import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/services/secure_link_opener.dart';

class JourneyTimeline extends StatelessWidget {
  final List<JourneyEvent> entries;

  const JourneyTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Responsive.isMobile(context)
        ? _MobileTimeline(entries: entries)
        : _DesktopTimeline(entries: entries);
  }
}

class _DesktopTimeline extends StatefulWidget {
  final List<JourneyEvent> entries;

  const _DesktopTimeline({required this.entries});

  @override
  State<_DesktopTimeline> createState() => _DesktopTimelineState();
}

class _DesktopTimelineState extends State<_DesktopTimeline> {
  int? _activeIndex;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _show(int index) {
    _dismissTimer?.cancel();
    if (_activeIndex != index) setState(() => _activeIndex = index);
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _activeIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth / widget.entries.length;
        const lineCenter = 84.0;
        const lineDepth = 16.0;
        const dotSize = 16.0;
        final detailWidth = math.min(280.0, math.max(220.0, laneWidth * 1.75));
        final active =
            _activeIndex == null ? null : widget.entries[_activeIndex!];
        final activeCenter =
            _activeIndex == null ? 0.0 : laneWidth * (_activeIndex! + 0.5);
        final detailLeft = _activeIndex == null
            ? 0.0
            : (activeCenter - detailWidth / 2)
                .clamp(0.0, math.max(0.0, constraints.maxWidth - detailWidth))
                .toDouble();

        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: active == null ? 174 : 372,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _DesktopSnakeLinePainter(
                        color: t.border,
                        centers: List<double>.generate(
                          widget.entries.length,
                          (index) => laneWidth * (index + 0.5),
                        ),
                        lineCenter: lineCenter,
                        depth: lineDepth,
                        glowColor: t.button,
                        glow: active != null,
                      ),
                    ),
                  ),
                ),
                if (active != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    left: detailLeft,
                    top: 154,
                    width: detailWidth,
                    child: MouseRegion(
                      onEnter: (_) => _show(_activeIndex!),
                      onExit: (_) => _scheduleDismiss(),
                      child: _AnimatedDetailCard(entry: active),
                    ),
                  ),
                for (var index = 0; index < widget.entries.length; index++)
                  _DesktopMarker(
                    entry: widget.entries[index],
                    center: laneWidth * (index + 0.5),
                    lineY: _snakeY(
                      index,
                      widget.entries.length,
                      lineCenter,
                      lineDepth,
                    ),
                    dotSize: dotSize,
                    active: _activeIndex == index,
                    labelAbove: index.isEven,
                    onEnter: () => _show(index),
                    onExit: _scheduleDismiss,
                    onTap: () => _show(index),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopMarker extends StatelessWidget {
  final JourneyEvent entry;
  final double center;
  final double lineY;
  final double dotSize;
  final bool active;
  final bool labelAbove;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  const _DesktopMarker({
    required this.entry,
    required this.center,
    required this.lineY,
    required this.dotSize,
    required this.active,
    required this.labelAbove,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final accent = active || entry.isCurrent;
    return Stack(
      children: [
        Positioned(
          left: center - 24,
          top: lineY - 24,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => onEnter(),
            onExit: (_) => onExit(),
            child: Semantics(
              button: true,
              label: 'Show details for ${entry.title}',
              child: InkResponse(
                onTap: onTap,
                radius: 24,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: accent ? dotSize + 2 : dotSize,
                      height: accent ? dotSize + 2 : dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent ? t.button : t.background,
                        border: Border.all(
                          color: accent ? t.button : t.textMuted,
                          width: accent ? 2 : 1.5,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: t.button.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: center - 62,
          top: labelAbove ? math.max(0, lineY - 66) : lineY + 20,
          width: 124,
          child: IgnorePointer(
            child: Column(
              children: [
                Text(
                  entry.shortDate,
                  style: t.label.copyWith(
                    fontSize: 11,
                    color: accent ? t.button : t.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: t.label.copyWith(color: t.text),
                ),
                if (entry.isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'PRESENT',
                      style: t.label.copyWith(fontSize: 10, color: t.button),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _snakeY(int index, int count, double center, double depth) {
  if (count < 2) return center;
  final progress = index / (count - 1);
  return center + math.sin(progress * math.pi * 2) * depth;
}

class _DesktopSnakeLinePainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final List<double> centers;
  final double lineCenter;
  final double depth;
  final bool glow;

  const _DesktopSnakeLinePainter({
    required this.color,
    required this.glowColor,
    required this.centers,
    required this.lineCenter,
    required this.depth,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [color, color, color, Colors.transparent],
        stops: const [0, 0.7, 0.9, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()..moveTo(0, lineCenter);
    var previous =
        Offset(centers.first, _snakeY(0, centers.length, lineCenter, depth));
    path.cubicTo(
      previous.dx * 0.5,
      lineCenter,
      previous.dx * 0.5,
      previous.dy,
      previous.dx,
      previous.dy,
    );

    for (var index = 1; index < centers.length; index++) {
      final next = Offset(
        centers[index],
        _snakeY(index, centers.length, lineCenter, depth),
      );
      final middle = (previous.dx + next.dx) / 2;
      path.cubicTo(middle, previous.dy, middle, next.dy, next.dx, next.dy);
      previous = next;
    }

    path.cubicTo(
      (previous.dx + size.width) / 2,
      previous.dy,
      (previous.dx + size.width) / 2,
      lineCenter,
      size.width,
      lineCenter,
    );
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = glowColor.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DesktopSnakeLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.centers != centers ||
        oldDelegate.lineCenter != lineCenter ||
        oldDelegate.depth != depth ||
        oldDelegate.glow != glow;
  }
}

class _MobileTimeline extends StatefulWidget {
  final List<JourneyEvent> entries;

  const _MobileTimeline({required this.entries});

  @override
  State<_MobileTimeline> createState() => _MobileTimelineState();
}

class _MobileTimelineState extends State<_MobileTimeline> {
  int? _activeIndex;
  Timer? _interactionTimer;
  bool _isInteracting = false;

  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  void _toggle(int index) {
    setState(() => _activeIndex = _activeIndex == index ? null : index);
  }

  void _engageLine() {
    _interactionTimer?.cancel();
    if (!_isInteracting) setState(() => _isInteracting = true);
  }

  void _releaseLine() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _isInteracting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final hasDetail = _activeIndex != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineWidth =
            math.max(constraints.maxWidth, widget.entries.length * 148.0);
        final laneWidth = timelineWidth / widget.entries.length;
        const lineTop = 80.0;
        const lineDepth = 10.0;
        const detailWidth = 280.0;
        final active = hasDetail ? widget.entries[_activeIndex!] : null;
        final detailLeft = !hasDetail
            ? 0.0
            : (laneWidth * (_activeIndex! + 0.5) - detailWidth / 2)
                .clamp(0.0, math.max(0.0, timelineWidth - detailWidth))
                .toDouble();

        return AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: hasDetail ? 398 : 180,
            child: MouseRegion(
              onEnter: (_) => _engageLine(),
              onHover: (_) => _engageLine(),
              onExit: (_) => _releaseLine(),
              child: Listener(
                onPointerDown: (_) => _engageLine(),
                onPointerMove: (_) => _engageLine(),
                onPointerUp: (_) => _releaseLine(),
                onPointerCancel: (_) => _releaseLine(),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: timelineWidth,
                      height: hasDetail ? 398 : 180,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _DesktopSnakeLinePainter(
                                  color: t.border,
                                  glowColor: t.button,
                                  glow: _isInteracting,
                                  centers: List<double>.generate(
                                    widget.entries.length,
                                    (index) => laneWidth * (index + 0.5),
                                  ),
                                  lineCenter: lineTop,
                                  depth: lineDepth,
                                ),
                              ),
                            ),
                          ),
                          if (active != null)
                            Positioned(
                              left: detailLeft,
                              top: 180,
                              width: detailWidth,
                              child: _AnimatedDetailCard(entry: active),
                            ),
                          for (var index = 0;
                              index < widget.entries.length;
                              index++)
                            _MobileMarker(
                              entry: widget.entries[index],
                              center: laneWidth * (index + 0.5),
                              lineY: _snakeY(
                                index,
                                widget.entries.length,
                                lineTop,
                                lineDepth,
                              ),
                              active: _activeIndex == index,
                              labelAbove: index.isEven,
                              onTap: () => _toggle(index),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MobileMarker extends StatelessWidget {
  final JourneyEvent entry;
  final double center;
  final double lineY;
  final bool active;
  final bool labelAbove;
  final VoidCallback onTap;

  const _MobileMarker({
    required this.entry,
    required this.center,
    required this.lineY,
    required this.active,
    required this.labelAbove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final accent = active || entry.isCurrent;
    return Stack(
      children: [
        Positioned(
          left: center - 24,
          top: lineY - 24,
          child: Semantics(
            button: true,
            label: 'Show details for ${entry.title}',
            child: InkResponse(
              onTap: onTap,
              radius: 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: accent ? 18 : 16,
                    height: accent ? 18 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent ? t.button : t.background,
                      border: Border.all(
                        color: accent ? t.button : t.textMuted,
                        width: accent ? 2 : 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: center - 62,
          top: labelAbove ? math.max(0, lineY - 66) : lineY + 20,
          width: 124,
          child: Column(
            children: [
              Text(
                entry.shortDate,
                style: t.label.copyWith(
                  fontSize: 11,
                  color: accent ? t.button : t.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: t.label.copyWith(color: t.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedDetailCard extends StatelessWidget {
  final JourneyEvent entry;

  const _AnimatedDetailCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${entry.sortDate}-${entry.title}'),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: _JourneyDetailCard(entry: entry),
    );
  }
}

class _JourneyDetailCard extends StatelessWidget {
  final JourneyEvent entry;

  const _JourneyDetailCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 206),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.kind.toUpperCase()} · ${entry.date}',
              style: t.label.copyWith(fontSize: 11, color: t.button),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(entry.title, style: t.subheading.copyWith(fontSize: 16)),
            if (entry.organization.isNotEmpty)
              Text(entry.organization,
                  style: t.label.copyWith(color: t.textMuted)),
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(entry.description, style: t.body.copyWith(fontSize: 13)),
            ],
            if (entry.highlights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...entry.highlights.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $item', style: t.body.copyWith(fontSize: 12)),
                ),
              ),
            ],
            if (entry.technologies.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: entry.technologies
                    .map((item) => _TechChip(label: item))
                    .toList(),
              ),
            ],
            if (entry.link.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: () => openSecureExternalLink(entry.link),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('View Credential'),
              ),
            ],
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: t.label.copyWith(fontSize: 10)),
    );
  }
}
