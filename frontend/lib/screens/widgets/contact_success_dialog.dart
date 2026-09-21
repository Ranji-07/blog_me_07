import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class ContactSuccessDialog extends StatelessWidget {
  final String? error;
  const ContactSuccessDialog({super.key, this.error});
  static Future<void> show(BuildContext context) => showDialog<void>(
      context: context, builder: (_) => const ContactSuccessDialog());
  static Future<void> showError(BuildContext context, String message) =>
      showDialog<void>(
          context: context,
          builder: (_) => ContactSuccessDialog(error: message));
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final failed = error != null;
    final accent = failed ? AppColors.danger : t.neonGreen;
    final title = failed ? 'Email app unavailable' : 'Email draft opened';
    final body = failed
        ? error!
        : 'Your message is ready in your email app. Review it and press Send to contact the portfolio owner.';
    return Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF10100F),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: t.border)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: const Color(0xFF191815),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.md)),
                        border: Border(bottom: BorderSide(color: t.border))),
                    child: Row(children: [
                      const _Dot(Color(0xFFFF6B6B)),
                      const SizedBox(width: 6),
                      const _Dot(Color(0xFFFFC75A)),
                      const SizedBox(width: 6),
                      const _Dot(Color(0xFF7DFF6A)),
                      const Spacer(),
                      Text('contact-status',
                          style: t.label.copyWith(color: t.textMuted))
                    ])),
                Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              failed
                                  ? r'$ mailto --status=failed'
                                  : r'$ mailto --status=draft-opened',
                              style: t.label.copyWith(color: accent)),
                          const SizedBox(height: AppSpacing.md),
                          Text(title,
                              style: t.subheading.copyWith(color: t.text)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(body, style: t.body),
                          const SizedBox(height: AppSpacing.lg),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(failed ? 'Close' : 'Done',
                                      style: TextStyle(color: t.button))))
                        ])),
              ]),
            )));
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
