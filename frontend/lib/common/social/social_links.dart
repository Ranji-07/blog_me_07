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

  String get _mailSubject => 'Portfolio enquiry';

  String get _mailBody =>
      'Hello,\n\nI found your portfolio and would like to connect about ';

  String _maskedEmail(String value) {
    final parts = value.trim().split('@');
    if (parts.length != 2 || parts.first.length < 5) return value;
    final local = parts.first;
    return '${local.substring(0, 3)}********${local.substring(local.length - 1)}@${parts.last}';
  }

  Future<void> _openQuickEmail(BuildContext context, _MailApp app) async {
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

    final query = <String, String>{
      'subject': _mailSubject,
      'body': _mailBody,
    };
    final mailUri = switch (app) {
      _MailApp.defaultApp => Uri(
          scheme: 'mailto',
          path: email,
          queryParameters: query,
        ),
      _MailApp.gmail => Uri.https('mail.google.com', '/mail/', {
          'view': 'cm',
          'fs': '1',
          'to': email,
          'su': _mailSubject,
          'body': _mailBody,
        }),
      _MailApp.outlook => Uri.https(
          'outlook.office.com',
          '/mail/deeplink/compose',
          {
            'to': email,
            ...query,
          },
        ),
    };

    await _launchUri(context, mailUri);
  }

  Future<void> _showMailAppPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final t = AppTheme.of(sheetContext);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: t.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your mail app', style: t.subheading),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    'Your message will open with the recipient and a draft ready.',
                    style: t.body.copyWith(fontSize: 13)),
                const SizedBox(height: AppSpacing.md),
                _MailAppOption(
                  icon: Icons.open_in_new_rounded,
                  title: 'Default mail app',
                  subtitle: 'Use your device email preference',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openQuickEmail(context, _MailApp.defaultApp);
                  },
                ),
                _MailAppOption(
                  icon: Icons.mail_outline_rounded,
                  title: 'Gmail',
                  subtitle: 'Open a Gmail compose window',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openQuickEmail(context, _MailApp.gmail);
                  },
                ),
                _MailAppOption(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Outlook',
                  subtitle: 'Open an Outlook compose window',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openQuickEmail(context, _MailApp.outlook);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
              title: "Let's talk.",
              description:
                  'Have an idea, opportunity, or just want to connect?',
              statusLabel: 'Open to opportunities',
              body: _EmailAddressAction(
                email: email.isEmpty
                    ? 'Email address available on request'
                    : _maskedEmail(email),
                onCopy: () => _copyValue(context, 'Email', email),
                onSend: () async {
                  Navigator.of(dialogContext).pop();
                  await _showMailAppPicker(context);
                },
              ),
              primaryLabel: 'Send email',
              showPrimaryAction: false,
              onPrimaryTap: () async {
                Navigator.of(dialogContext).pop();
                await _showMailAppPicker(context);
              },
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

enum _MailApp { defaultApp, gmail, outlook }

class _MailAppOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onTap;

  const _MailAppOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(icon, color: t.button),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.label.copyWith(color: t.text)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: t.label.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailAddressAction extends StatefulWidget {
  final String email;
  final Future<void> Function() onCopy;
  final Future<void> Function() onSend;
  const _EmailAddressAction(
      {required this.email, required this.onCopy, required this.onSend});

  @override
  State<_EmailAddressAction> createState() => _EmailAddressActionState();
}

class _EmailAddressActionState extends State<_EmailAddressAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: t.button.withValues(alpha: 0.42)),
        ),
        child: Row(
          children: [
            Icon(Icons.mail_outline_rounded, size: 18, color: t.button),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: InkWell(
                onTap: widget.onSend,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    _hovered ? 'Send email  →' : widget.email,
                    key: ValueKey(_hovered),
                    overflow: TextOverflow.ellipsis,
                    style: t.subheading.copyWith(
                      color: _hovered ? t.button : t.text,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onCopy,
              tooltip: 'Copy email',
              icon: Icon(Icons.content_copy_outlined,
                  size: 17, color: t.textMuted),
            ),
          ],
        ),
      ),
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
      triggerMode: TooltipTriggerMode.manual,
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
  final String description;
  final String? statusLabel;
  final Widget? body;
  final String primaryLabel;
  final bool showPrimaryAction;
  final Future<void> Function() onPrimaryTap;

  const _ContactActionDialog({
    required this.title,
    required this.description,
    this.statusLabel,
    required this.primaryLabel,
    this.showPrimaryAction = true,
    required this.onPrimaryTap,
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
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
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (statusLabel != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(statusLabel!,
                          style: t.label
                              .copyWith(color: t.textMuted, fontSize: 11)),
                    ],
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      constraints:
                          const BoxConstraints.tightFor(width: 32, height: 32),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.close_rounded, color: t.textMuted),
                    ),
                  ],
                ),
                Text(title,
                    style: t.subheading.copyWith(
                      color: t.text,
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: AppSpacing.sm),
                Text(description,
                    style: t.body.copyWith(decoration: TextDecoration.none)),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  body!,
                ],
                if (showPrimaryAction) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: onPrimaryTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: t.button,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text('$primaryLabel  →'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                          child: Text('Click the address to copy',
                              style: t.label.copyWith(fontSize: 11))),
                    ],
                  ),
                ] else
                  const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
