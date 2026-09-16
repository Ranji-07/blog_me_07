import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSuccessDialog extends StatelessWidget {
  final Uri mailtoUri;

  const ContactSuccessDialog({super.key, required this.mailtoUri});

  static Future<void> show(BuildContext context, Uri mailtoUri) {
    return showDialog<void>(
      context: context,
      builder: (_) => ContactSuccessDialog(mailtoUri: mailtoUri),
    );
  }

  Future<void> _openEmail(BuildContext context) async {
    final launched = await launchUrl(mailtoUri);
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open your email application.')),
      );
      return;
    }
    Navigator.of(context).pop();
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
      title: Text('Message Ready', style: t.heading),
      content: Text(
        'Your message was saved and an email draft is ready. Review it in your email application, then select Send.',
        style: t.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => _openEmail(context),
          style: FilledButton.styleFrom(
            backgroundColor: t.button,
            foregroundColor: Colors.black,
          ),
          child: const Text('Open Email'),
        ),
      ],
    );
  }
}
