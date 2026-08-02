import 'package:flutter/material.dart';

class InteractiveSpotlight extends StatelessWidget {
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
  Widget build(BuildContext context) => child;
}
