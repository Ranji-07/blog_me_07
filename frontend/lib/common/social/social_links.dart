import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/secure_link_opener.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLinksSection extends StatelessWidget {
  final String email;
  final String githubUrl;
  final String linkedinUrl;
  final double spacing;

  const ContactLinksSection({
    super.key,
    required this.email,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.spacing,
  });

  Future<void> _copyValue(
    BuildContext context,
    String label,
    String value,
  ) async {
    if (value.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label is not available yet')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('✓ $label copied'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _externalTooltip(String label, String value) {
    if (value.trim().isEmpty) {
      return label;
    }
    return '$value\nOpens in a new tab';
  }

  Uri? _validatedExternalUri(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return null;
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }

    return uri;
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final launched = await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open this link right now'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _openExternal(BuildContext context, String value) async {
    final uri = _validatedExternalUri(value);
    if (uri == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('This external link is unavailable or invalid'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    final launched = await openSecureExternalLink(uri.toString());
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open this link right now'),
            duration: Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _openQuickEmail(BuildContext context) async {
    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Email address is not available yet'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    final mailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: const {
        'subject': 'Portfolio Contact',
      },
    );

    await _launchUri(context, mailUri);
  }

  Future<void> _showEmailDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Email',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, animation, _, __) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return Transform.scale(
          scale: Tween<double>(begin: 0.94, end: 1).evaluate(curved),
          child: Opacity(
            opacity: curved.value,
            child: _ContactActionDialog(
              title: 'Contact via Email',
              icon: Icons.mail_outline_rounded,
              description:
                  "I'd love to hear from you. Feel free to send me a message.",
              body: SelectionArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.of(dialogContext)
                        .surface
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border:
                        Border.all(color: AppTheme.of(dialogContext).border),
                  ),
                  child: Text(
                    email.isEmpty
                        ? 'Email address available on request'
                        : email,
                    style: AppTheme.of(dialogContext).subheading,
                  ),
                ),
              ),
              primaryLabel: 'Mail Him',
              onPrimaryTap: () async {
                Navigator.of(dialogContext).pop();
                await _openQuickEmail(context);
              },
              tertiaryLabel: 'Copy Email',
              onTertiaryTap: () => _copyValue(
                context,
                'Email',
                email,
              ),
              secondaryLabel: 'Close',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: 12,
      children: [
        _ContactIconButton(
          semanticLabel: 'Email',
          tooltip: email.isEmpty ? 'Email' : email,
          icon: Icons.mail_outline_rounded,
          showBackground: false,
          enabled: email.trim().isNotEmpty,
          onPrimaryTap: () => _showEmailDialog(context),
          onSecondaryTap: () => _copyValue(
            context,
            'Email',
            email,
          ),
          onLongPress: () => _copyValue(context, 'Email', email),
        ),
        _ContactIconButton(
          semanticLabel: 'GitHub',
          tooltip: _externalTooltip('GitHub', githubUrl),
          faIcon: FontAwesomeIcons.github,
          showBackground: false,
          enabled: githubUrl.trim().isNotEmpty,
          onPrimaryTap: () => _openExternal(context, githubUrl),
          onSecondaryTap: () => _copyValue(
            context,
            'GitHub profile',
            githubUrl,
          ),
          onLongPress: () => _copyValue(context, 'GitHub profile', githubUrl),
        ),
        _ContactIconButton(
          semanticLabel: 'LinkedIn',
          tooltip: _externalTooltip('LinkedIn', linkedinUrl),
          faIcon: FontAwesomeIcons.linkedinIn,
          showBackground: false,
          enabled: linkedinUrl.trim().isNotEmpty,
          onPrimaryTap: () => _openExternal(context, linkedinUrl),
          onSecondaryTap: () => _copyValue(
            context,
            'LinkedIn profile',
            linkedinUrl,
          ),
          onLongPress: () =>
              _copyValue(context, 'LinkedIn profile', linkedinUrl),
        ),
      ],
    );
  }
}

class _ContactIconButton extends StatefulWidget {
  final String semanticLabel;
  final String tooltip;
  final IconData? icon;
  final FaIconData? faIcon;
  final Future<void> Function() onPrimaryTap;
  final Future<void> Function() onSecondaryTap;
  final Future<void> Function()? onLongPress;
  final bool showBackground;
  final bool enabled;

  const _ContactIconButton({
    required this.semanticLabel,
    required this.tooltip,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    this.onLongPress,
    this.icon,
    this.faIcon,
    this.showBackground = true,
    this.enabled = true,
  });

  @override
  State<_ContactIconButton> createState() => _ContactIconButtonState();
}

class _ContactIconButtonState extends State<_ContactIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  bool _busy = false;

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy || !widget.enabled) {
      return;
    }
    setState(() => _busy = true);
    final stopwatch = Stopwatch()..start();
    try {
      await action();
    } finally {
      final remaining = 900 - stopwatch.elapsedMilliseconds;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final baseScale = _pressed ? 0.95 : (_hovered ? 1.10 : 1.0);
    final effectiveScale = widget.enabled ? baseScale : 1.0;
    final iconColor = !widget.enabled
        ? t.text.withValues(alpha: 0.35)
        : (_hovered && !widget.showBackground ? t.button : t.text);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 3),
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        enabled: widget.enabled,
        child: FocusableActionDetector(
          enabled: widget.enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          mouseCursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _runAction(widget.onPrimaryTap);
                return null;
              },
            ),
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() {
              _hovered = false;
              _pressed = false;
            }),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapCancel: widget.enabled
                  ? () => setState(() => _pressed = false)
                  : null,
              onTapUp: widget.enabled
                  ? (_) => setState(() => _pressed = false)
                  : null,
              onTap:
                  widget.enabled ? () => _runAction(widget.onPrimaryTap) : null,
              onSecondaryTap: widget.enabled
                  ? () => _runAction(widget.onSecondaryTap)
                  : null,
              onLongPress: widget.enabled && widget.onLongPress != null
                  ? () => _runAction(widget.onLongPress!)
                  : null,
              child: AnimatedScale(
                scale: effectiveScale,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  offset: _hovered ? const Offset(0, -0.08) : Offset.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.showBackground
                          ? (_hovered
                              ? t.buttonSoft
                              : t.surface.withValues(alpha: 0.32))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: _focused
                          ? Border.all(color: t.button, width: 1.6)
                          : (widget.showBackground
                              ? Border.all(
                                  color: _hovered ? t.button : t.border,
                                )
                              : null),
                      boxShadow: _hovered && widget.enabled
                          ? [
                              BoxShadow(
                                color: t.button.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: iconColor,
                              ),
                            )
                          : widget.faIcon != null
                              ? FaIcon(
                                  widget.faIcon,
                                  color: iconColor,
                                  size: 22,
                                )
                              : Icon(
                                  widget.icon,
                                  color: iconColor,
                                  size: 22,
                                ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ContactFooterLine extends StatelessWidget {
  final String ownerName;
  final int? buildYear;
  final String builtWith;
  final String appVersion;
  final String note;

  const ContactFooterLine({
    super.key,
    required this.ownerName,
    required this.buildYear,
    required this.builtWith,
    required this.appVersion,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final parts = <String>[
      if (buildYear != null || ownerName.trim().isNotEmpty)
        '© ${buildYear?.toString() ?? ''} ${ownerName.trim()}'.trim(),
      if (builtWith.trim().isNotEmpty) 'Built with ${builtWith.trim()}',
      if (appVersion.trim().isNotEmpty) 'Version ${appVersion.trim()}',
      if (note.trim().isNotEmpty) note.trim(),
    ];

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        parts.join(' • '),
        maxLines: 1,
        textAlign: TextAlign.center,
        style: (isMobile ? t.body : t.label).copyWith(
          color: t.text,
          fontSize: isMobile ? 12 : 13,
        ),
      ),
    );
  }
}

class _ContactActionDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final Widget? body;
  final String primaryLabel;
  final Future<void> Function() onPrimaryTap;
  final String? tertiaryLabel;
  final Future<void> Function()? onTertiaryTap;
  final String secondaryLabel;

  const _ContactActionDialog({
    required this.title,
    required this.icon,
    required this.description,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.tertiaryLabel,
    this.onTertiaryTap,
    required this.secondaryLabel,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: t.surface.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(color: t.border),
                  ),
                  child: Icon(
                    icon,
                    color: t.button,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: t.subheading.copyWith(color: t.text)),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: t.body),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.lg),
                body!,
              ],
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: 120,
                    child: FilledButton(
                      onPressed: onPrimaryTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.button,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      child: Text(primaryLabel),
                    ),
                  ),
                  if (tertiaryLabel != null && onTertiaryTap != null)
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed: onTertiaryTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.text,
                          side: BorderSide(color: t.border),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        child: Text(tertiaryLabel!),
                      ),
                    ),
                  SizedBox(
                    width: 120,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.text,
                        side: BorderSide(color: t.border),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      child: Text(secondaryLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
