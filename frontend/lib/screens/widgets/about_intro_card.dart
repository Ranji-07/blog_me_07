import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';

class AboutIntroCard extends StatefulWidget {
  final List<String> paragraphs;

  const AboutIntroCard({super.key, required this.paragraphs});

  @override
  State<AboutIntroCard> createState() => _AboutIntroCardState();
}

class _AboutIntroCardState extends State<AboutIntroCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final mobile = Responsive.isMobile(context);
    final bodyStyle = t.body.copyWith(
      fontSize: mobile ? 15 : 16,
      height: 1.72,
    );
    final linkStyle = t.label.copyWith(color: t.button, fontSize: 14);
    final summary = widget.paragraphs.isEmpty ? '' : widget.paragraphs.first;
    final hasMore = widget.paragraphs.length > 1;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedSize(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: _expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final paragraph in widget.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(paragraph, style: bodyStyle),
                  ),
                if (hasMore)
                  _InlineTextAction(
                    label: 'Read Less ↑',
                    style: linkStyle,
                    semanticLabel: 'Read less about me',
                    expanded: true,
                    onPressed: () => setState(() => _expanded = false),
                  ),
              ],
            )
          : hasMore
              ? LayoutBuilder(
                  builder: (context, constraints) => _CollapsedSummary(
                    summary: summary,
                    maxWidth: constraints.maxWidth,
                    maxLines: 4,
                    bodyStyle: bodyStyle,
                    linkStyle: linkStyle,
                    onPressed: () => setState(() => _expanded = true),
                  ),
                )
              : Text(summary, style: bodyStyle),
    );
  }
}

class _CollapsedSummary extends StatelessWidget {
  final String summary;
  final double maxWidth;
  final int maxLines;
  final TextStyle bodyStyle;
  final TextStyle linkStyle;
  final VoidCallback onPressed;

  const _CollapsedSummary({
    required this.summary,
    required this.maxWidth,
    required this.maxLines,
    required this.bodyStyle,
    required this.linkStyle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const label = 'Read More ↓';
    final visibleText = _truncateAtWordBoundary(
      context: context,
      source: summary,
      maxWidth: maxWidth,
      maxLines: maxLines,
      bodyStyle: bodyStyle,
      linkStyle: linkStyle,
      linkLabel: label,
    );

    return RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(text: '$visibleText '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _InlineTextAction(
              label: label,
              style: linkStyle,
              semanticLabel: 'Read more about me',
              expanded: false,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }

  String _truncateAtWordBoundary({
    required BuildContext context,
    required String source,
    required double maxWidth,
    required int maxLines,
    required TextStyle bodyStyle,
    required TextStyle linkStyle,
    required String linkLabel,
  }) {
    final words = source.trim().split(RegExp(r'\s+'));
    final linkWidth = _measure(context, linkLabel, linkStyle);
    final availableWidth =
        (maxWidth - linkWidth - AppSpacing.xs).clamp(1.0, maxWidth);
    for (var count = words.length; count > 0; count--) {
      final candidate = '${words.take(count).join(' ')}...';
      final painter = TextPainter(
        text: TextSpan(text: candidate, style: bodyStyle),
        maxLines: maxLines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: availableWidth);
      if (!painter.didExceedMaxLines) return candidate;
    }
    return '...';
  }

  double _measure(BuildContext context, String value, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }
}

class _InlineTextAction extends StatelessWidget {
  final String label;
  final TextStyle style;
  final String semanticLabel;
  final bool expanded;
  final VoidCallback onPressed;

  const _InlineTextAction({
    required this.label,
    required this.style,
    required this.semanticLabel,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        toggled: expanded,
        child: TextButton(
          onPressed: onPressed,
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(style.color),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 2),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
            overlayColor: WidgetStatePropertyAll(
              style.color?.withValues(alpha: .14),
            ),
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? BorderSide(color: style.color ?? Colors.transparent)
                  : BorderSide.none,
            ),
            shape: const WidgetStatePropertyAll(StadiumBorder()),
          ),
          child: Text(label, style: style),
        ),
      );
}
