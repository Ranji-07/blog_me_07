import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/app_theme.dart';

class InteractiveSpotlight extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool enabled;
  final Color? color;
  final double opacity;
  final double radius;

  const InteractiveSpotlight({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.enabled = true,
    this.color,
    this.opacity = 0.18,
    this.radius = 220,
  });

  @override
  State<InteractiveSpotlight> createState() => _InteractiveSpotlightState();
}

class _InteractiveSpotlightState extends State<InteractiveSpotlight> {
  Offset? _position;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final spotlightColor = widget.color ?? t.accent;

    if (!widget.enabled) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onHover: (event) => setState(() => _position = event.localPosition),
      onExit: (_) => setState(() {
        _hovered = false;
        _position = null;
      }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            IgnorePointer(
              child: AnimatedOpacity(
                duration: AppAnimations.fast,
                opacity: _hovered && _position != null ? 1 : 0,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    position: _position ?? Offset.zero,
                    color: spotlightColor.withValues(alpha: widget.opacity),
                    radius: widget.radius,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset position;
  final Color color;
  final double radius;

  const _SpotlightPainter({
    required this.position,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: Alignment(
        ((position.dx / math.max(size.width, 1)) * 2) - 1,
        ((position.dy / math.max(size.height, 1)) * 2) - 1,
      ),
      radius: radius / math.max(size.width, size.height),
      colors: [
        color,
        color.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0, 0.35, 1],
    );

    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}
