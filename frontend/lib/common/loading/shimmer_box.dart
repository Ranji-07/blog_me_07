import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool circle;
  final double radius;

  /// Shared sweep driver so a skeleton can animate every box from one
  /// controller. When omitted, the box animates on its own and pauses
  /// automatically for reduced-motion users.
  final Animation<double>? animation;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.circle = false,
    this.radius = AppRadius.sm,
    this.animation,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _ownController;

  @override
  void initState() {
    super.initState();
    if (widget.animation == null) {
      _ownController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _ownController;
    if (controller == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final animation = widget.animation ?? _ownController!;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              widget.circle ? null : BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + (animation.value * 3), 0),
            end: Alignment(-0.5 + (animation.value * 3), 0),
            colors: [t.surface, t.border, t.surface],
          ),
        ),
      ),
    );
  }
}
