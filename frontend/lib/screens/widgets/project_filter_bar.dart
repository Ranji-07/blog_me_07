import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class ProjectFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const ProjectFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category == selectedCategory;
          return Semantics(
            button: true,
            selected: active,
            label: 'Show $category projects',
            child: ChoiceChip(
              label: Text(category),
              selected: active,
              onSelected: (_) => onSelected(category),
              selectedColor: t.buttonSoft,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: active ? t.button : t.border),
              labelStyle: t.label.copyWith(color: active ? t.button : t.text),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          );
        },
      ),
    );
  }
}
