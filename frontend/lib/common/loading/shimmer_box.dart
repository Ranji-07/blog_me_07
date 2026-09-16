import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final bool circle;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.circle = false,
    this.radius = AppRadius.sm,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              widget.circle ? null : BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1.5 + (_controller.value * 3), 0),
            end: Alignment(-0.5 + (_controller.value * 3), 0),
            colors: [t.surface, t.border, t.surface],
          ),
        ),
      ),
    );
  }
}
