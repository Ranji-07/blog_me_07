import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Padding(
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
              Text('Projects', style: t.heading),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Selected work and case studies.',
                style: t.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
