import 'package:flutter/material.dart';
import 'package:portfolio/common/loading/section_skeletons.dart';
import 'package:portfolio/common/social/social_links.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final titleSize = Responsive.value<double>(
      context,
      mobile: 38,
      tablet: 46,
      desktop: 52,
    );

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
            return const ContactSectionSkeleton();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Padding(
              padding: EdgeInsets.all(padding),
              child: Text('Unable to load contact details right now.',
                  style: t.body),
            );
          }

          final content = snapshot.data!;
          return SafeArea(
            top: false,
            left: false,
            right: false,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      isMobile ? 96 : 128,
                      padding,
                      isMobile ? 0 : AppSpacing.xxl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ContactIntro(
                                    titleSize: titleSize,
                                    isMobile: true,
                                  ),
                                  // Breathing room, then the robot sits
                                  // between the paragraphs and the icons.
                                  const SizedBox(height: AppSpacing.lg),
                                  Center(
                                    child: Image.asset('assets/1698535.png',
                                        height: 132,
                                        excludeFromSemantics: true),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ContactLinksSection(
                                    email: content.email,
                                    githubUrl: content.githubUrl,
                                    linkedinUrl: content.linkedinUrl,
                                    spacing: 20,
                                  ),
                                ],
                              )
                            : LayoutBuilder(builder: (context, constraints) {
                                if (constraints.maxWidth < 880) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _ContactIntro(
                                            titleSize: titleSize,
                                            isMobile: false),
                                        const SizedBox(height: AppSpacing.xl),
                                        _ContactActions(content: content),
                                      ]);
                                }
                                // The right column keeps its designed 420px stance
                                // while it is wide enough for the contact links to
                                // pair up two per row. Narrower desktop widths
                                // (small tablets in landscape) stack the links
                                // three rows tall, so the column sizes naturally
                                // there instead of clipping.
                                final rightWidth =
                                    (constraints.maxWidth - AppSpacing.xxl) *
                                        10 /
                                        22;
                                final roomy = rightWidth >= 400;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Expanded(
                                      flex: 12,
                                      child: _ContactKeyboard(),
                                    ),
                                    const SizedBox(width: AppSpacing.xxl),
                                    Expanded(
                                      flex: 10,
                                      child: roomy
                                          ? SizedBox(
                                              height: 420,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _ContactIntro(
                                                    titleSize: titleSize,
                                                    isMobile: false,
                                                  ),
                                                  const Spacer(),
                                                  _ContactActions(
                                                      content: content),
                                                ],
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _ContactIntro(
                                                  titleSize: titleSize,
                                                  isMobile: false,
                                                ),
                                                const SizedBox(height: 48),
                                                _ContactActions(
                                                    content: content),
                                              ],
                                            ),
                                    ),
                                  ],
                                );
                              }),
                      ),
                    ),
                  ),
                  _ContactLandscape(details: isMobile ? content : null),
                  if (!isMobile)
                    Padding(
                        padding: EdgeInsets.fromLTRB(padding, AppSpacing.md,
                            padding, AppSpacing.xxl + bottomInset),
                        child: ContactFooterLine(
                          ownerName: content.ownerName,
                          buildYear: content.buildYear,
                          builtWith: content.builtWith,
                          appVersion: content.appVersion,
                          note: content.footerNote,
                        )),
                ]),
          );
        },
      ),
    );
  }
}

class _ContactKeyboard extends StatelessWidget {
  const _ContactKeyboard();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: IgnorePointer(
        child: Center(
          child: SizedBox.square(
              dimension: 420,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const RadialGradient(
                  radius: .72,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, .65, 1],
                ).createShader(bounds),
                child: Image.asset('assets/about_keyboard_orange.png',
                    fit: BoxFit.contain, excludeFromSemantics: true),
              )),
        ),
      ));
}

/// Full-width artwork is outside the contact copy's padded content column.
/// On mobile the copyright and build details sit in the artwork's open sky,
/// between the tree and the traveller above the ground line, so no separate
/// footer block follows the illustration.
class _ContactLandscape extends StatelessWidget {
  final _ContactPageContent? details;

  const _ContactLandscape({this.details});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final height = constraints.maxWidth / (compact ? 2 : 3);
      final detailLines = <Widget>[
        if (details != null) ...[
          if (details!.buildYear != null ||
              details!.ownerName.trim().isNotEmpty)
            Text(
              '© ${details!.buildYear?.toString() ?? ''} ${details!.ownerName.trim()}'
                  .trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.label
                  .copyWith(fontSize: 10, color: t.textMuted, height: 1.5),
            ),
          if (details!.builtWith.trim().isNotEmpty ||
              details!.appVersion.trim().isNotEmpty)
            Text(
              [
                if (details!.builtWith.trim().isNotEmpty)
                  'Built with ${details!.builtWith.trim()}',
                if (details!.appVersion.trim().isNotEmpty)
                  'Version ${details!.appVersion.trim()}',
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.label
                  .copyWith(fontSize: 10, color: t.textMuted, height: 1.5),
            ),
          if (details!.footerNote.trim().isNotEmpty)
            Text(
              details!.footerNote.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.label
                  .copyWith(fontSize: 10, color: t.textMuted, height: 1.5),
            ),
        ],
      ];
      return RepaintBoundary(
        child: AspectRatio(
          aspectRatio: compact ? 2 : 3,
          child: Stack(children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: Image.asset(
                      compact
                          ? 'assets/contact_tree_traveller_mobile.png'
                          : 'assets/contact_tree_traveller_desktop.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true),
                ),
              ),
            ),
            if (compact && detailLines.isNotEmpty && height >= 120)
              // The mobile artwork's open sky spans roughly 42-84% across,
              // above the ground line at about 65% of its height. Viewports
              // too narrow to hold the lines skip the overlay entirely
              // rather than overflowing it.
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth * .42,
                    height * .12,
                    constraints.maxWidth * .16,
                    height * .36,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: detailLines,
                  ),
                ),
              ),
          ]),
        ),
      );
    });
  }
}

class _ContactIntro extends StatelessWidget {
  final double titleSize;
  final bool isMobile;

  const _ContactIntro({
    required this.titleSize,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            "Let's Build Something",
            style: t.display.copyWith(color: t.button, fontSize: titleSize),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Have an idea, opportunity, or project to discuss?',
          style: t.body.copyWith(
              fontSize: isMobile ? 13 : 16, height: isMobile ? 1.6 : 1.4),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'I’m open to full-time roles, collaborations, and practical AI work.',
          style: t.body.copyWith(
              fontSize: isMobile ? 13 : 16, height: isMobile ? 1.6 : 1.4),
        ),
      ],
    );
  }
}

class _ContactActions extends StatelessWidget {
  final _ContactPageContent content;

  const _ContactActions({required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContactLinksSection(
          email: content.email,
          githubUrl: content.githubUrl,
          linkedinUrl: content.linkedinUrl,
          spacing: AppSpacing.sm,
          showLabels: true,
          alignment: WrapAlignment.start,
        ),
      ],
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
