import 'package:flutter/material.dart';
import 'package:portfolio/widgets/page_frame.dart';
import 'package:portfolio/widgets/section_placeholder_card.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'Projects',
      description:
          'Project cards, filters, and detail sections will be rebuilt here.',
      children: [
        SectionPlaceholderCard(
          title: 'Featured Projects',
          description:
              'Placeholder for the main project list and highlighted case studies.',
        ),
        SizedBox(height: 24),
        SectionPlaceholderCard(
          title: 'Project Categories',
          description:
              'Placeholder for filters, grouping, or stack-based browsing.',
        ),
        SizedBox(height: 24),
        SectionPlaceholderCard(
          title: 'Project Details',
          description:
              'Placeholder for the selected project story, metrics, and links.',
        ),
      ],
    );
  }
}
