import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class OutlineCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const OutlineCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.border),
      ),
      child: child,
    );
  }
}
