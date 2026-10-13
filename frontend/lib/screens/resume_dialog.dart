// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter, unused_element, unused_element_parameter

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumePreviewDialog extends StatelessWidget {
  static const String _resumeAssetPath = 'assets/assets/V_P_Ranjith_resume.pdf';
  static final Uri _resumeAssetUri = Uri.parse(_resumeAssetPath);
  final VoidCallback? onActionComplete;
  final VoidCallback? onClose;
  final VoidCallback? onDownload;

  const ResumePreviewDialog({
    super.key,
    this.onActionComplete,
    this.onClose,
    this.onDownload,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onActionComplete,
  }) async {
    final exitMotion = ValueNotifier<_PaperExit>(_PaperExit.close);
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Resume preview',
        barrierColor: Colors.black.withValues(alpha: 0.72),
        transitionDuration: const Duration(milliseconds: 1100),
        pageBuilder: (dialogContext, _, __) => ResumePreviewDialog(
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
                          child: const _ResumePage(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset,
                    right: sideInset,
                    child: _FloatingIconButton(
                      icon: Icons.close_rounded,
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

const String _resumePreviewViewType = 'ranjith-resume-pdf-preview';
bool _resumePreviewRegistered = false;

class _ResumePdfPreview extends StatelessWidget {
  const _ResumePdfPreview();

  @override
  Widget build(BuildContext context) {
    if (!_resumePreviewRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _resumePreviewViewType,
        (viewId) => html.IFrameElement()
          ..src = ResumePreviewDialog._resumeAssetPath
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..title = 'Ranjith V P resume preview',
      );
      _resumePreviewRegistered = true;
    }
    return const HtmlElementView(viewType: _resumePreviewViewType);
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

class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: t.surface,
          shape: BoxShape.circle,
          border: Border.all(color: t.border),
        ),
        child: Icon(
          icon,
          color: t.text,
          size: 20,
        ),
      ),
    );
  }
}

class _ResumeActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final bool compact;

  const _ResumeActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: t.button,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: Colors.black,
            ),
            SizedBox(width: compact ? 6 : AppSpacing.sm),
            Text(
              label,
              style: t.label.copyWith(
                fontSize: compact ? 12 : 13,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumePage extends StatelessWidget {
  const _ResumePage();

  @override
  Widget build(BuildContext context) {
    const headingColor = Color(0xFF111111);
    const bodyColor = Color(0xFF404040);
    const accentColor = Color(0xFFE58B34);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Ranjith V P',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: headingColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Software Development Engineer • AI Engineer • India',
          style: TextStyle(
            fontSize: 13,
            color: bodyColor,
            height: 1.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Portfolio contact details are available in the contact section.',
          style: TextStyle(
            fontSize: 12,
            color: bodyColor,
            height: 1.5,
          ),
        ),
        SizedBox(height: 24),
        _ResumeSection(
          title: 'Profile',
          content:
              'Software Development Engineer with experience building AI-integrated systems, Python data pipelines, and cloud infrastructure. I work across Flutter, APIs, Docker, Kubernetes, and AWS.',
        ),
        SizedBox(height: 18),
        _ResumeSection(
          title: 'Experience',
          content:
              'Software Development Engineer — Buddi.AI\nNov 2025 - Present\nBuild AI-integrated production systems, data workflows, and LLM processing features.\n\nSoftware Engineer — Boodskap\nSep 2024 - Oct 2025\nBuilt connected IoT products across device, cloud, and Flutter application layers.',
        ),
        SizedBox(height: 18),
        _ResumeSection(
          title: 'Education',
          content:
              'B.E. Information Technology — Annamalai University\nGraduated May 2024 • CGPA 7',
        ),
        SizedBox(height: 18),
        _ResumeSection(
          title: 'Skills',
          content:
              'Python, Scala, Flutter, Dart, REST APIs, Docker, Kubernetes, Terraform, AWS, CI/CD, LLM Integration, and IoT.',
        ),
        SizedBox(height: 18),
        Text(
          'This preview summarizes the resume available for download.',
          style: TextStyle(
            fontSize: 11,
            color: accentColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 12),
        Text(
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
