import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/widgets/outline_card.dart';

class EducationTimelineSection extends StatelessWidget {
  const EducationTimelineSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return OutlineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Education Timeline', style: t.subheading),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Placeholder section. We will build the education timeline here in a dedicated widget file.',
            style: t.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: t.button,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      index == 0
                          ? 'Education item placeholder'
                          : 'Another education milestone placeholder',
                      style: t.body.copyWith(color: t.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
