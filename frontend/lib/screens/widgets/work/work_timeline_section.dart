import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/screens/widgets/journey_timeline.dart';

class WorkTimelineSection extends StatelessWidget {
  final JourneyContent journey;

  const WorkTimelineSection({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final mobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          journey.title,
          style: t.heading.copyWith(
            color: t.button,
            fontSize: mobile ? 29 : 34,
          ),
        ),
        if (journey.subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(journey.subtitle, style: t.body),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (journey.events.isEmpty)
          Text('Timeline details will appear here.', style: t.body)
        else
          JourneyTimeline(entries: journey.events),
      ],
    );
  }
}
