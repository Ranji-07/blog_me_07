import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        120,
        AppSpacing.xl,
        140,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About', style: t.heading),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Profile, background, and experience.',
                style: t.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
