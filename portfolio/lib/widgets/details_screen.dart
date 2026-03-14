import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/app_buttons.dart';

/// Reusable contact form section.
/// Uses [AppColors] and [AppButton] for consistent theming.
class DetailSection extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? contactController;
  final TextEditingController? messageController;

  const DetailSection({
    super.key,
    required this.text,
    required this.onPressed,
    this.nameController,
    this.emailController,
    this.contactController,
    this.messageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(context, 'Your name',    nameController),
        const SizedBox(height: 14),
        _field(context, 'Your email',   emailController),
        const SizedBox(height: 14),
        _field(context, 'Your contact', contactController),
        const SizedBox(height: 14),
        _field(context, 'Message',      messageController, maxLines: 5),
        const SizedBox(height: 24),
        AppButton(
          label: text,
          onPressed: onPressed,
          style: AppButtonStyle.primary,
          icon: Icons.send_rounded,
          width: double.infinity,
          height: 52,
        ),
      ],
    );
  }

  Widget _field(BuildContext context, String label, TextEditingController? ctrl, {int maxLines = 1}) {
    final t = AppTheme.of(context);
    return TextField(
      controller: ctrl,
      cursorColor: t.primary,
      maxLines: maxLines,
      style: TextStyle(color: t.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: t.textMuted),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: t.border),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: t.primary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: t.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}