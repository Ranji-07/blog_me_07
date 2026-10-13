import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

/// Temporary presentation layer for Work terminals while their detail views are
/// being designed. Remove this widget when those views are ready.
class WorkInProgressOverlay extends StatelessWidget {
  final bool visible;
  final Widget child;

  const WorkInProgressOverlay({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        IgnorePointer(ignoring: visible, child: child),
        if (visible)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                child: ColoredBox(
                  color: t.background.withValues(alpha: 0.72),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.construction_rounded,
                            color: t.button, size: 30),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'In progress of designing',
                          style: t.label.copyWith(color: t.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
