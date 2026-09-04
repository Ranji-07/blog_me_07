import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: t.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portfolio', style: t.label.copyWith(color: t.button)),
                const SizedBox(height: AppSpacing.lg),
                Text('Full Stack Developer & AI Engineer', style: t.display),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Building mobile apps, backend systems, cloud infrastructure, and AI-powered products.',
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
