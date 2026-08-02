import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/widgets/outline_card.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onEnter;

  const LandingScreen({
    super.key,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: OutlineCard(
            radius: AppRadius.xl,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portfolio', style: t.label.copyWith(color: t.button)),
                const SizedBox(height: AppSpacing.lg),
                Text('New Landing Screen', style: t.display),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'This is the fresh starting point. No navigation bar appears on landing. We will build the new design from here, page by page.',
                  style: t.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                GestureDetector(
                  onTap: onEnter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: t.button,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'Enter',
                      style: t.subheading.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
