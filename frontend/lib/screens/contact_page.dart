import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:portfolio/widgets/contact_links_section.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<_ContactPageContent> _fetchContactPageContent() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/portfolio/all'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load portfolio content.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid portfolio response.');
    }

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
    final horizontalPadding = Responsive.value(
      context,
      mobile: 18.0,
      tablet: 24.0,
      desktop: 28.0,
    );
    final topPadding = Responsive.value(
      context,
      mobile: 92.0,
      tablet: 104.0,
      desktop: 108.0,
    );
    final bottomPadding = Responsive.value(
      context,
      mobile: 32.0,
      tablet: 28.0,
      desktop: 24.0,
    );
    final iconSpacing = Responsive.value(
      context,
      mobile: 18.0,
      tablet: 22.0,
      desktop: 24.0,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.background,
            t.surface,
            t.background,
          ],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_ContactPageContent>(
          future: _fetchContactPageContent(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(color: t.button),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'Unable to load contact details right now.',
                    textAlign: TextAlign.center,
                    style: t.body.copyWith(color: t.text),
                  ),
                ),
              );
            }

            final content = snapshot.data!;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: ContactLinksSection(
                      email: content.email,
                      githubUrl: content.githubUrl,
                      linkedinUrl: content.linkedinUrl,
                      spacing: iconSpacing,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ContactFooterLine(
                    ownerName: content.ownerName,
                    buildYear: content.buildYear,
                    builtWith: content.builtWith,
                    appVersion: content.appVersion,
                    note: content.footerNote,
                  ),
                ],
              ),
            );
          },
        ),
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
