import 'package:flutter/material.dart';
import 'package:portfolio/widgets/page_frame.dart';
import 'package:portfolio/widgets/section_placeholder_card.dart';
import 'package:portfolio/widgets/timeline_section.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'About',
      description:
          'Bio, education, experience timeline, and skills will live on this page.',
      children: [
        SectionPlaceholderCard(
          title: 'Bio',
          description:
              'Placeholder card for biography summary and personal intro.',
        ),
        SizedBox(height: 24),
        EducationTimelineSection(),
        SizedBox(height: 24),
        SectionPlaceholderCard(
          title: 'Experience Timeline',
          description:
              'Placeholder card for work and experience timeline content.',
        ),
        SizedBox(height: 24),
        SectionPlaceholderCard(
          title: 'Skills',
          description:
              'Placeholder card for grouped skills, tools, and stack.',
        ),
      ],
    );
  }
}
