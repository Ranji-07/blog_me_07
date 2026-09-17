import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

class ContactSuccessDialog extends StatelessWidget {
  final bool visitorCopySent;

  const ContactSuccessDialog({super.key, required this.visitorCopySent});

  static Future<void> show(BuildContext context,
      {required bool visitorCopySent}) {
    return showDialog<void>(
      context: context,
      builder: (_) => ContactSuccessDialog(visitorCopySent: visitorCopySent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return AlertDialog(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: t.border),
      ),
      icon: Icon(Icons.mark_email_read_outlined, color: t.button, size: 36),
      title: Text('Message sent', style: t.heading),
      content: Text(
        visitorCopySent
            ? 'Your message reached the portfolio owner. A copy was sent to your email, and you can reply there to continue the conversation.'
            : 'Your message reached the portfolio owner, but the copy to your email could not be delivered.',
        style: t.body,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: t.button,
            foregroundColor: Colors.black,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
