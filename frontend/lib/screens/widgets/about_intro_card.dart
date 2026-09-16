import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class AboutIntroCard extends StatelessWidget {
  final List<String> paragraphs;

  const AboutIntroCard({super.key, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...paragraphs.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              paragraph,
              style: t.body.copyWith(fontSize: 16, height: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
