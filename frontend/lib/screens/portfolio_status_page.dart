import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/services/admin_contact.dart';

const _fallbackSiteName = String.fromEnvironment(
  'PORTFOLIO_NAME',
  defaultValue: 'Tarzan',
);

class PortfolioStatusPage extends StatelessWidget {
  final String code;
  final String title;
  final String description;
  final IconData icon;
  final bool homeAvailable;

  const PortfolioStatusPage({
    super.key,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    this.homeAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Email the portfolio owner',
                    child: TextButton(
                      onPressed: () async {
                        await openAdminRequestEmail(context, source: code);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: t.text,
                      ),
                      child: Text(_fallbackSiteName, style: t.subheading),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(icon, color: t.button, size: 50),
                  const SizedBox(height: 28),
                  Text(code, style: t.label.copyWith(color: t.button)),
                  const SizedBox(height: 10),
                  Text(title, style: t.display),
                  const SizedBox(height: 16),
                  Text(description, style: t.body),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: homeAvailable
                        ? () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (_) => false)
                        : () async {
                            await openAdminRequestEmail(context, source: code);
                          },
                    icon: Icon(homeAvailable
                        ? Icons.arrow_back_rounded
                        : Icons.mail_outline_rounded),
                    label: Text(
                        homeAvailable ? 'Back to portfolio' : 'Email owner'),
                    style: FilledButton.styleFrom(
                      backgroundColor: t.button,
                      foregroundColor: t.background,
                      minimumSize: const Size(180, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
