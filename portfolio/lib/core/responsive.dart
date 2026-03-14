import 'package:flutter/material.dart';

// ─────────────────────────── Breakpoints ─────────────────────────────────────
class Breakpoints {
  Breakpoints._();
  static const double mobile  = 0;
  static const double tablet  = 600;
  static const double desktop = 1024;
}

// ─────────────────────────── Responsive helper ────────────────────────────────
class Responsive {
  Responsive._();

  static double _w(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context)  => _w(context) < Breakpoints.tablet;
  static bool isTablet(BuildContext context)  => _w(context) >= Breakpoints.tablet && _w(context) < Breakpoints.desktop;
  static bool isDesktop(BuildContext context) => _w(context) >= Breakpoints.desktop;

  /// Returns one of three values depending on device class.
  /// Falls back gracefully: tablet → desktop value, mobile → tablet value.
  static T value<T>(BuildContext context, {required T mobile, T? tablet, required T desktop}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context))  return tablet ?? desktop;
    return mobile;
  }

  /// Responsive font size — scales between [min] and [max] based on screen width.
  static double fontSize(BuildContext context, {required double mobile, required double desktop, double? tablet}) {
    return value(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Responsive padding
  static EdgeInsets padding(BuildContext context, {
    EdgeInsets mobile  = const EdgeInsets.all(16),
    EdgeInsets? tablet,
    EdgeInsets desktop = const EdgeInsets.all(48),
  }) {
    return value(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }

  /// Responsive horizontal padding for page content
  static EdgeInsets pagePadding(BuildContext context) => padding(
    context,
    mobile:  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    tablet:  const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
    desktop: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
  );

  /// Column count for a grid
  static int gridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    return value(context, mobile: mobile, tablet: tablet, desktop: desktop);
  }
}

// ─────────────────────────── Responsive Widgets ──────────────────────────────

/// Renders different children based on screen size.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Responsive.isMobile(context),
      Responsive.isTablet(context),
      Responsive.isDesktop(context),
    );
  }
}

/// Wraps content with responsive horizontal padding.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  const ResponsiveContainer({super.key, required this.child, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Responsive.pagePadding(context),
      child: maxWidth != null
          ? Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth!), child: child))
          : child,
    );
  }
}

/// An adaptive grid that wraps children with correct column count.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.mobileColumns  = 1,
    this.tabletColumns  = 2,
    this.desktopColumns = 3,
    this.spacing    = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cols = Responsive.gridColumns(context,
      mobile: mobileColumns, tablet: tabletColumns, desktop: desktopColumns);
    final total = children.length;
    if (total == 0) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < total; i += cols) {
      final rowItems = children.sublist(i, (i + cols).clamp(0, total));
      rows.add(Row(
        children: [
          for (var j = 0; j < rowItems.length; j++) ...[
            if (j > 0) SizedBox(width: spacing),
            Expanded(child: rowItems[j]),
          ],
          // fill remaining columns with invisible spacers
          for (var k = rowItems.length; k < cols; k++) ...[
            SizedBox(width: spacing),
            const Expanded(child: SizedBox.shrink()),
          ],
        ],
      ));
      if (i + cols < total) SizedBox(height: runSpacing);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) SizedBox(height: runSpacing),
        rows[i],
      ]
    ]);
  }
}

/// Scales a non-nullable double between device classes.
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T desktop;
  final Widget Function(T value) builder;
  const ResponsiveValue({super.key, required this.mobile, this.tablet, required this.desktop, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(Responsive.value(context, mobile: mobile, tablet: tablet, desktop: desktop));
  }
}
