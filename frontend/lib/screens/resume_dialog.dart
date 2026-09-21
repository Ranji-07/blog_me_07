// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ResumePreviewDialog extends StatelessWidget {
  static const String _resumeAssetPath = 'assets/assets/resume.pdf';
  static final Uri _resumeAssetUri = Uri.parse(_resumeAssetPath);
  final VoidCallback? onActionComplete;

  const ResumePreviewDialog({
    super.key,
    this.onActionComplete,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onActionComplete,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => ResumePreviewDialog(
        onActionComplete: onActionComplete,
      ),
    );
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
            'Resume preview: open assets/assets/resume.pdf from the portfolio app.',
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
      fileName: 'resume.pdf',
    );

    if (saved) {
      onActionComplete?.call();
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

    return Dialog(
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
                        padding: const EdgeInsets.all(32),
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
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  left: sideInset,
                  right: sideInset,
                  bottom: bottomInset,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: compact ? 8 : 10,
                        runSpacing: compact ? 8 : 10,
                        children: [
                          _ResumeActionButton(
                            label: 'Share',
                            icon: Icons.share_outlined,
                            compact: compact,
                            onTap: () => _shareResume(context),
                          ),
                          _ResumeActionButton(
                            label: 'Save',
                            icon: Icons.save_alt_rounded,
                            filled: true,
                            compact: compact,
                            onTap: () => _savePdf(context),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          'Tarzan',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: headingColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Full Stack Developer • AI Engineer • India',
          style: TextStyle(
            fontSize: 13,
            color: bodyColor,
            height: 1.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Portfolio contact details available in the app contact section',
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
              'I build scalable mobile applications, backend APIs, cloud infrastructure, and AI-powered systems using Flutter, FastAPI, Docker, Kubernetes, and AWS.',
        ),
        SizedBox(height: 18),
        _ResumeSection(
          title: 'Experience',
          content:
              'Full Stack, AI, cloud, and DevOps-focused project experience.\n2024 - Present\nApplication delivery, infrastructure setup, automation, and product execution across modern web and mobile stacks.',
        ),
        SizedBox(height: 18),
        _ResumeSection(
          title: 'Education',
          content: 'Bachelor of Technology in Computer Science\n2021 - 2025',
        ),
        SizedBox(height: 18),
        _ResumeSection(
          title: 'Skills',
          content:
              'Flutter, Dart, FastAPI, UI Architecture, REST APIs, Responsive Design, State Management.',
        ),
        SizedBox(height: 18),
        Text(
          'This preview summarizes the resume experience available in the portfolio.',
          style: TextStyle(
            fontSize: 11,
            color: accentColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Share uses the browser share sheet when supported. Save downloads the PDF using the browser default download location.',
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
