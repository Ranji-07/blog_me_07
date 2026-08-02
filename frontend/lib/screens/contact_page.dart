import 'package:flutter/material.dart';
import 'package:portfolio/widgets/page_frame.dart';
import 'package:portfolio/widgets/section_placeholder_card.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: 'Contact',
      description:
          'Contact details, form, and links will be rebuilt on this screen.',
      children: [
        SectionPlaceholderCard(
          title: 'Contact Details',
          description:
              'Placeholder for email, phone, location, and social links.',
        ),
        SizedBox(height: 24),
        SectionPlaceholderCard(
          title: 'Contact Form',
          description:
              'Placeholder for the new form layout and submission states.',
        ),
      ],
    );
  }
}
