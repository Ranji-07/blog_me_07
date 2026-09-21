import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const adminContactEmail = String.fromEnvironment(
  'ADMIN_CONTACT_EMAIL',
  defaultValue: 'ranjithvijay1225@gmail.com',
);

Future<void> openAdminRequestEmail(BuildContext context,
    {required String source}) async {
  final email = adminContactEmail.trim();
  if (email.isEmpty) return;

  const subject = 'Hello from your portfolio';
  final body = 'Hello,\n\nI would like to connect.\n\n'
      'Page: $source\n'
      'Message: \n';
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    query:
        'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );

  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Offer a usable fallback when the device has no configured mail app.
  }

  await Clipboard.setData(ClipboardData(text: email));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No email app found. Owner email copied.')),
    );
  }
}
