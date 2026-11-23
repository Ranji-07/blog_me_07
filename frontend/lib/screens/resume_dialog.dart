// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/services/about_motion_preference.dart';
import 'package:portfolio/services/portfolio_api.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumePreviewDialog extends StatelessWidget {
  static const String _resumeAssetPath = 'assets/assets/V_P_Ranjith_resume.pdf';
  static final Uri _resumeAssetUri = Uri.parse(_resumeAssetPath);
  final ResumeContent content;
  final VoidCallback? onActionComplete;
  final VoidCallback? onClose;
  final VoidCallback? onDownload;

  const ResumePreviewDialog({
    super.key,
    required this.content,
    this.onActionComplete,
    this.onClose,
    this.onDownload,
  });

  static Future<ResumeContent> _loadResumeContent() async {
    try {
      return ResumeContent.fromPortfolio(await PortfolioApi.fetchAll());
    } catch (_) {
      return ResumeContent.fallback();
    }
  }

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onActionComplete,
  }) async {
    final exitMotion = ValueNotifier<_PaperExit>(_PaperExit.close);
    final reduced = prefersReducedMotion(context);
    final content = await _loadResumeContent();
    if (!context.mounted) {
      exitMotion.dispose();
      return;
    }
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Resume preview',
        barrierColor: Colors.black.withValues(alpha: 0.72),
        transitionDuration: reduced
            ? Duration.zero
            : const Duration(milliseconds: 1100),
        pageBuilder: (dialogContext, _, __) => ResumePreviewDialog(
          content: content,
          onActionComplete: onActionComplete,
          onClose: () => exitMotion.value = _PaperExit.close,
          onDownload: () => exitMotion.value = _PaperExit.download,
        ),
        transitionBuilder: (dialogContext, animation, _, child) =>
            _PaperTransition(
                animation: animation, exitMotion: exitMotion, child: child),
      );
    } finally {
      exitMotion.dispose();
    }
  }

  Future<void> _shareResume(BuildContext context) async {
    final shared = await _shareResumeWeb(
      title: 'Resume',
      text: 'Portfolio resume preview',
      url: _resumeAssetPath,
    );

    if (shared) {
      onActionComplete?.call();
      return;
    }

    await Clipboard.setData(
      const ClipboardData(
        text:
            'Resume preview: open assets/assets/V_P_Ranjith_resume.pdf from the portfolio app.',
      ),
    );
    onActionComplete?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Share popup unavailable, copied resume link instead')),
      );
    }
  }

  Future<void> _savePdf(BuildContext context) async {
    final saved = await _saveResumeWeb(
      url: _resumeAssetPath,
      fileName: 'V_P_Ranjith_resume.pdf',
    );

    if (saved) {
      onActionComplete?.call();
      onDownload?.call();
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume download started')),
        );
      }
      return;
    }

    final launched = await launchUrl(
      _resumeAssetUri,
      webOnlyWindowName: '_blank',
    );

    if (launched) {
      onActionComplete?.call();
      onDownload?.call();
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened resume PDF')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save resume PDF')),
      );
    }
  }

  Future<bool> _shareResumeWeb({
    required String title,
    required String text,
    required String url,
  }) async {
    final navigator = html.window.navigator;
    final share = js_util.getProperty<Object?>(navigator, 'share');
    if (share == null) {
      return false;
    }

    try {
      await js_util.promiseToFuture<void>(
        js_util.callMethod<Object?>(
          navigator,
          'share',
          [
            {
              'title': title,
              'text': text,
              'url': url,
            },
          ],
        ) as Object,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _saveResumeWeb({
    required String url,
    required String fileName,
  }) async {
    try {
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 760 ? size.width - 32 : 760.0;
    final pageWidth = size.width < 760 ? dialogWidth - 16 : 560.0;
    final pageHeight = pageWidth * 1.414;
    final maxPageHeight = size.height * 0.72;
    final effectivePageHeight =
        pageHeight > maxPageHeight ? maxPageHeight : pageHeight;
    final topInset = size.width < 760 ? 14.0 : 18.0;
    final sideInset = size.width < 760 ? 14.0 : 18.0;
    final bottomInset = size.width < 760 ? 18.0 : 22.0;

    return PopScope(
      onPopInvokedWithResult: (_, __) => onClose?.call(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: dialogWidth,
          height: size.height * 0.9,
          child: Center(
            child: SizedBox(
              width: pageWidth,
              height: effectivePageHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
                          child: _ResumePage(content: content),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset,
                    right: sideInset,
                    child: _FloatingIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close resume preview',
                      onTap: () {
                        onClose?.call();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Positioned(
                    left: sideInset,
                    right: sideInset,
                    bottom: bottomInset,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ResumeActionButton(
                          label: 'Share',
                          icon: Icons.share_outlined,
                          onTap: () => _shareResume(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _ResumeActionButton(
                          label: 'Download',
                          icon: Icons.download_rounded,
                          filled: true,
                          onTap: () => _savePdf(context),
                        ),
                      ],
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

enum _PaperExit { close, download }

class _PaperTransition extends StatelessWidget {
  final Animation<double> animation;
  final ValueNotifier<_PaperExit> exitMotion;
  final Widget child;

  const _PaperTransition({
    required this.animation,
    required this.exitMotion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_PaperExit>(
        valueListenable: exitMotion,
        builder: (context, exit, _) {
          final reverse = animation.status == AnimationStatus.reverse;
          final reduced = MediaQuery.of(context).disableAnimations;
          final progress = Curves.easeInOutCubic.transform(animation.value);
          final fold = reverse ? 1 - progress : 1 - progress;
          final target = exit == _PaperExit.download
              ? const Offset(230, -280)
              : const Offset(210, 330);
          final movement = reverse
              ? Offset(target.dx * fold, target.dy * fold)
              : Offset(250 * (1 - progress), -210 * (1 - progress));
          final scale =
              reduced ? progress : (reverse ? progress : 0.2 + 0.8 * progress);
          final rotation = reduced
              ? 0.0
              : (reverse
                  ? (exit == _PaperExit.download ? -0.28 : 0.34) * fold
                  : 0.28 * (1 - progress));
          return Stack(
            fit: StackFit.expand,
            children: [
              if (reverse && exit == _PaperExit.close)
                Positioned(
                  right: 34,
                  bottom: 30,
                  child: Opacity(
                    opacity: fold.clamp(0.0, 1.0),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.button, size: 42),
                  ),
                ),
              Center(
                child: Transform.translate(
                  offset: movement,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(14 + 96 * (1 - progress)),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _FloatingIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _FloatingIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_FloatingIconButton> createState() => _FloatingIconButtonState();
}

class _FloatingIconButtonState extends State<_FloatingIconButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        excludeFromSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _focused ? t.button : t.border,
                width: _focused ? 1.6 : 1,
              ),
            ),
            child: Icon(widget.icon, color: t.text, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ResumeActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ResumeActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  State<_ResumeActionButton> createState() => _ResumeActionButtonState();
}

class _ResumeActionButtonState extends State<_ResumeActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: t.button,
            borderRadius: BorderRadius.circular(AppRadius.full),
            // Transparent until focused, so the pill keeps its silhouette.
            border: Border.all(
              color: _focused ? Colors.white : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: t.label.copyWith(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview content derived from the same portfolio config the public site
/// reads, so the resume summary can never drift from the CMS.
class ResumeContent {
  final String name;
  final String headline;
  final String profile;
  final List<String> experience;
  final List<String> education;
  final String skills;

  const ResumeContent({
    required this.name,
    required this.headline,
    required this.profile,
    required this.experience,
    required this.education,
    required this.skills,
  });

  factory ResumeContent.fromPortfolio(Map<String, dynamic> portfolio) {
    final about = (portfolio['about'] as Map<String, dynamic>?) ?? const {};
    final contact =
        (portfolio['contact'] as Map<String, dynamic>?) ?? const {};
    final journey =
        (portfolio['journey'] as Map<String, dynamic>?) ?? const {};
    final events = JourneyContent.fromJson(journey).events;

    final roles =
        (about['roles'] as List<dynamic>? ?? const []).whereType<String>();
    var currentTitle = '';
    for (final event in events) {
      if (event.isCurrent && event.title.isNotEmpty) currentTitle = event.title;
    }
    final location = (contact['location'] as String?) ?? '';
    final headlineParts = <String>[
      if (currentTitle.isNotEmpty) currentTitle,
      if (roles.isNotEmpty && roles.first != currentTitle) roles.first,
      if (location.isNotEmpty) location,
    ];

    final aboutMe =
        (about['about_me'] as List<dynamic>? ?? const []).whereType<String>();
    final profile = aboutMe.isEmpty ? '' : aboutMe.first;

    final experience = <String>[];
    final education = <String>[];
    for (final event in events) {
      final entry = [
        if (event.title.isNotEmpty)
          event.organization.isEmpty
              ? event.title
              : '${event.title} — ${event.organization}',
        if (event.date.isNotEmpty) event.date,
        if (event.description.isNotEmpty) event.description,
      ].join('\n');
      if (entry.isEmpty) continue;
      switch (event.kind.toLowerCase()) {
        case 'work':
          experience.add(entry);
        case 'education':
          education.add(entry);
      }
    }

    final categories =
        (about['skill_categories'] as Map<String, dynamic>?) ?? const {};
    final seen = <String>{};
    final skills = <String>[];
    for (final value in categories.values) {
      for (final skill
          in (value as List<dynamic>? ?? const []).whereType<String>()) {
        final trimmed = skill.trim();
        if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
          skills.add(trimmed);
        }
      }
    }

    return ResumeContent(
      name: (about['name'] as String?) ?? '',
      headline: headlineParts.join(' • '),
      profile: profile,
      experience: experience,
      education: education,
      skills: skills.join(', '),
    );
  }

  factory ResumeContent.fallback() => ResumeContent(
        name: String.fromEnvironment('PORTFOLIO_NAME',
            defaultValue: 'Ranjith V P'),
        headline: '',
        profile: '',
        experience: const [],
        education: const [],
        skills: '',
      );
}

class _ResumePage extends StatelessWidget {
  final ResumeContent content;
  const _ResumePage({required this.content});

  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF404040);
    const accentColor = Color(0xFFE58B34);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: headingColor,
          ),
        ),
        if (content.headline.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content.headline,
            style: const TextStyle(
              fontSize: 13,
              color: bodyColor,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 6),
        const Text(
          'Portfolio contact details are available in the contact section.',
          style: TextStyle(
            fontSize: 12,
            color: bodyColor,
            height: 1.5,
          ),
        ),
        if (content.profile.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ResumeSection(title: 'Profile', content: content.profile),
        ],
        if (content.experience.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ResumeSection(
              title: 'Experience', content: content.experience.join('\n\n')),
        ],
        if (content.education.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ResumeSection(
              title: 'Education', content: content.education.join('\n\n')),
        ],
        if (content.skills.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ResumeSection(title: 'Skills', content: content.skills),
        ],
        const SizedBox(height: 18),
        const Text(
          'This preview summarizes the resume available for download.',
          style: TextStyle(
            fontSize: 11,
            color: accentColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Share opens the browser share sheet when supported. Download saves the PDF using the browser default download location.',
          style: TextStyle(
            fontSize: 11,
            color: bodyColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ResumeSection extends StatelessWidget {
  final String title;
  final String content;

  const _ResumeSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    const bodyColor = Color(0xFF404040);
    const accentColor = Color(0xFFE58B34);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: const Color(0xFFE6E1DA),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12.5,
            color: bodyColor,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
