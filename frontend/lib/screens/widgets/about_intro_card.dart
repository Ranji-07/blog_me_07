import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class AboutIntroCard extends StatelessWidget {
  final List<String> paragraphs;

  const AboutIntroCard({super.key, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: t.card.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABOUT ME', style: t.label.copyWith(color: t.button)),
          const SizedBox(height: AppSpacing.lg),
          ...paragraphs.map((paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(paragraph, style: t.body.copyWith(fontSize: 16)),
              )),
        ],
      ),
    );
  }
}
