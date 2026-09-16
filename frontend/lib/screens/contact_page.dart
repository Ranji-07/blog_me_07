import 'package:flutter/material.dart';
import 'package:portfolio/common/social/social_links.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/screens/widgets/contact_form.dart';
import 'package:portfolio/services/portfolio_api.dart';

class ContactScreen extends StatefulWidget {
  final Map<String, dynamic>? cachedContent;

  const ContactScreen({super.key, this.cachedContent});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final Future<_ContactPageContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadContent();
  }

  Future<_ContactPageContent> _loadContent() async {
    final decoded = widget.cachedContent ?? await PortfolioApi.fetchAll();
    final about = (decoded['about'] as Map<String, dynamic>?) ?? const {};
    final contact = (decoded['contact'] as Map<String, dynamic>?) ?? const {};
    final social = (contact['social'] as Map<String, dynamic>?) ?? const {};
    final footer = (contact['footer'] as Map<String, dynamic>?) ?? const {};
    return _ContactPageContent(
      ownerName: (about['name'] as String?) ?? '',
      email: (contact['email'] as String?) ?? '',
      githubUrl: (social['github'] as String?) ?? '',
      linkedinUrl: (social['linkedin'] as String?) ?? '',
      buildYear: footer['build_year'] as int?,
      builtWith: (footer['built_with'] as String?) ?? '',
      appVersion: (footer['app_version'] as String?) ?? '',
      footerNote: (footer['note'] as String?) ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? AppSpacing.md : AppSpacing.xxl;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.background, t.surface, t.background],
        ),
      ),
      child: FutureBuilder<_ContactPageContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(padding),
              child: Text('Unable to load contact details right now.',
                  style: t.body),
            );
          }

          final content = snapshot.data!;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              isMobile ? 96 : 128,
              padding,
              isMobile ? AppSpacing.xl : AppSpacing.xxl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Let's Build Something",
                      style: t.display.copyWith(color: t.button),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        'Reach out about a project, collaboration, opportunity, or simply to connect.',
                        style: t.body.copyWith(fontSize: isMobile ? 15 : 16),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ContactForm(
                      ownerName: content.ownerName,
                      recipientEmail: content.email,
                    ),
                    const SizedBox(height: 40),
                    ContactLinksSection(
                      email: content.email,
                      githubUrl: content.githubUrl,
                      linkedinUrl: content.linkedinUrl,
                      spacing: isMobile ? 22 : 28,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ContactFooterLine(
                      ownerName: content.ownerName,
                      buildYear: content.buildYear,
                      builtWith: content.builtWith,
                      appVersion: content.appVersion,
                      note: content.footerNote,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactPageContent {
  final String ownerName;
  final String email;
  final String githubUrl;
  final String linkedinUrl;
  final int? buildYear;
  final String builtWith;
  final String appVersion;
  final String footerNote;

  const _ContactPageContent({
    required this.ownerName,
    required this.email,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.buildYear,
    required this.builtWith,
    required this.appVersion,
    required this.footerNote,
  });
}
