import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/widgets/outline_card.dart';

class SectionPlaceholderCard extends StatelessWidget {
  final String title;
  final String description;

  const SectionPlaceholderCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return OutlineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.subheading),
          const SizedBox(height: AppSpacing.sm),
          Text(description, style: t.body),
        ],
      ),
    );
  }
}
