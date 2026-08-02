import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class PageFrame extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> children;

  const PageFrame({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

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
              Text(title, style: t.heading),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: t.body),
              const SizedBox(height: AppSpacing.xl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
