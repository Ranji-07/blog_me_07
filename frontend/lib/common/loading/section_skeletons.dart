import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'shimmer_box.dart';

/// Owns one shared shimmer sweep for a whole section so every placeholder box
/// animates from a single controller and freezes for reduced-motion users.
class SectionSkeleton extends StatefulWidget {
  final Widget Function(BuildContext context, Animation<double> shimmer)
      builder;

  const SectionSkeleton({super.key, required this.builder});

  @override
  State<SectionSkeleton> createState() => _SectionSkeletonState();
}

class _SectionSkeletonState extends State<SectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _shimmer);
}

/// Mirrors the About section while its profile loads, matching the real
/// layout's viewport height, padding, and breakpoints so nothing shifts when
/// content replaces the skeleton.
class AboutSectionSkeleton extends StatelessWidget {
  const AboutSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionSkeleton(
      builder: (context, shimmer) {
        final narrow = MediaQuery.sizeOf(context).width < 600;
        final terminalHeight =
            (MediaQuery.sizeOf(context).height - 200).clamp(420.0, 720.0);
        return ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
          child: Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 16 : 32, narrow ? 96 : 112,
                narrow ? 16 : 32, narrow ? 24 : 48),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 5,
                        child: _AboutStorySkeleton(
                            shimmer: shimmer, mobile: false)),
                    const SizedBox(width: 40),
                    Expanded(
                        flex: 7,
                        child: _TerminalFrameSkeleton(
                            shimmer: shimmer, height: terminalHeight)),
                  ],
                );
              }
              final mobile = constraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutStorySkeleton(shimmer: shimmer, mobile: mobile),
                  SizedBox(height: mobile ? 16 : 28),
                  if (mobile) ...[
                    _HoneycombSkeleton(shimmer: shimmer),
                    const SizedBox(height: 20),
                    // Mirrors the skills summary line: one text strip with
                    // the plain arrow at its end.
                    Row(children: [
                      Expanded(
                          child: ShimmerBox(
                              width: double.infinity,
                              height: 15,
                              animation: shimmer)),
                      const SizedBox(width: 12),
                      ShimmerBox(width: 20, height: 15, animation: shimmer),
                    ]),
                  ] else
                    _TerminalFrameSkeleton(
                        shimmer: shimmer, height: terminalHeight),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

/// Mirrors the Work section: journey heading, the curved marker strip, then
/// the mobile deck stage or the paired desktop terminals.
class WorkSectionSkeleton extends StatelessWidget {
  const WorkSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionSkeleton(builder: (context, shimmer) {
      final mobile = Responsive.isMobile(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
              width: mobile ? 230 : 260,
              height: mobile ? 28 : 34,
              animation: shimmer),
          if (!mobile) ...[
            const SizedBox(height: AppSpacing.sm),
            ShimmerBox(width: 320, height: 15, animation: shimmer),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: mobile ? 162 : 154,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final count = (width / 148).floor().clamp(2, 6);
              return Stack(children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 71,
                  child: ShimmerBox(
                      width: double.infinity,
                      height: 2,
                      radius: 1,
                      animation: shimmer),
                ),
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: width * (i + .5) / count - 68,
                    top: 0,
                    width: 136,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerBox(width: 74, height: 12, animation: shimmer),
                        const SizedBox(height: 6),
                        ShimmerBox(width: 52, height: 11, animation: shimmer),
                        const SizedBox(height: 30),
                        ShimmerBox(
                            width: 18,
                            height: 18,
                            circle: true,
                            animation: shimmer),
                      ],
                    ),
                  ),
              ]);
            }),
          ),
          SizedBox(height: mobile ? AppSpacing.md : AppSpacing.xl),
          if (mobile) ...[
            SizedBox(
              height: 414,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final extent = width * .62;
                Widget card(double scale) => ShimmerBox(
                    width: 220 * scale,
                    height: 310 * scale,
                    radius: 18,
                    animation: shimmer);
                return Stack(children: [
                  Positioned(
                      left: width / 2 - extent - 93.5,
                      top: 72,
                      child: card(.85)),
                  Positioned(left: width / 2 - 110, top: 52, child: card(1)),
                  Positioned(
                      left: width / 2 + extent - 93.5,
                      top: 72,
                      child: card(.85)),
                ]);
              }),
            ),
            const SizedBox(height: 24),
          ] else
            LayoutBuilder(builder: (context, constraints) {
              // Terminal frames flex horizontally only when side-by-side;
              // the stacked variant lives in the page's unbounded scroll, so
              // Expanded children would be a layout error there.
              Widget stacked() => Column(children: [
                    _TerminalFrameSkeleton(shimmer: shimmer, height: 320),
                    const SizedBox(height: AppSpacing.md),
                    _TerminalFrameSkeleton(shimmer: shimmer, height: 320),
                  ]);
              if (constraints.maxWidth < 880) {
                return stacked();
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        flex: 12,
                        child: _TerminalFrameSkeleton(
                            shimmer: shimmer, height: 320)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                        flex: 9,
                        child: _TerminalFrameSkeleton(
                            shimmer: shimmer, height: 320)),
                  ],
                ),
              );
            }),
        ],
      );
    });
  }
}

/// Reserve the same contact columns and full-width illustration while loading.
class ContactSectionSkeleton extends StatelessWidget {
  const ContactSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionSkeleton(builder: (context, shimmer) {
      final isMobile = Responsive.isMobile(context);
      final padding = isMobile ? AppSpacing.md : AppSpacing.xxl;
      Widget intro = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
              width: isMobile ? 280 : 360,
              height: isMobile ? 38 : 52,
              animation: shimmer),
          const SizedBox(height: AppSpacing.md),
          ShimmerBox(
              width: 320, height: isMobile ? 13 : 15, animation: shimmer),
          const SizedBox(height: AppSpacing.xs),
          ShimmerBox(
              width: 300, height: isMobile ? 13 : 15, animation: shimmer),
        ],
      );
      Widget actions = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < 3; i++)
                ShimmerBox(
                    width: 132,
                    height: 48,
                    radius: AppRadius.full,
                    animation: shimmer),
            ],
          ),
        ],
      );
      Widget body = LayoutBuilder(builder: (context, constraints) {
        if (isMobile || constraints.maxWidth < 880) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              if (isMobile) ...[
                // Mirrors the robot between the paragraphs and the icons.
                const SizedBox(height: AppSpacing.lg),
                Center(
                    child: ShimmerBox(
                        width: 132,
                        height: 132,
                        radius: AppRadius.md,
                        animation: shimmer)),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (var i = 0; i < 3; i++)
                        ShimmerBox(
                            width: 48,
                            height: 48,
                            radius: AppRadius.full,
                            animation: shimmer),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                actions,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                flex: 12,
                child: Center(
                    child: ShimmerBox(
                        width: 420, height: 420, animation: shimmer))),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              flex: 10,
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    intro,
                    const Spacer(),
                    actions,
                  ],
                ),
              ),
            ),
          ],
        );
      });
      return SafeArea(
        top: false,
        left: false,
        right: false,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, isMobile ? 96 : 128, padding,
                isMobile ? 0 : AppSpacing.xxl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: body,
              ),
            ),
          ),
          LayoutBuilder(
              builder: (context, constraints) => AspectRatio(
                    aspectRatio: constraints.maxWidth < 600 ? 2 : 3,
                    child: ShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        radius: 0,
                        animation: shimmer),
                  )),
          if (!isMobile)
            Padding(
                padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding,
                    AppSpacing.xxl + MediaQuery.viewInsetsOf(context).bottom),
                child: Center(
                    child: ShimmerBox(
                        width: 280, height: 13, animation: shimmer))),
        ]),
      );
    });
  }
}

class _AboutStorySkeleton extends StatelessWidget {
  final Animation<double> shimmer;
  final bool mobile;
  const _AboutStorySkeleton({required this.shimmer, required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(width: mobile ? 190 : 230, height: 30, animation: shimmer),
        const SizedBox(height: 14),
        for (var i = 0; i < (mobile ? 2 : 5); i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerBox(
                width: i == (mobile ? 1 : 4) ? 220 : double.infinity,
                height: 15,
                animation: shimmer),
          ),
        ShimmerBox(
            width: 110, height: 32, radius: AppRadius.full, animation: shimmer),
        if (!mobile) ...[
          const SizedBox(height: 28),
          ShimmerBox(width: 90, height: 18, animation: shimmer),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 18,
            children: [
              for (var i = 0; i < 8; i++)
                SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerBox(width: 38, height: 38, animation: shimmer),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 48, height: 11, animation: shimmer),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HoneycombSkeleton extends StatelessWidget {
  final Animation<double> shimmer;
  const _HoneycombSkeleton({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    const centers = [
      Offset(.5, .5),
      Offset(.28, .62),
      Offset(.72, .62),
      Offset(.36, .3),
      Offset(.64, .3),
      Offset(.16, .46),
      Offset(.84, .46),
    ];
    return SizedBox(
      height: 328,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(children: [
          for (final center in centers)
            Positioned(
              left: center.dx * width - 24,
              top: center.dy * 328 - 24,
              child: ShimmerBox(
                  width: 48, height: 48, circle: true, animation: shimmer),
            ),
        ]);
      }),
    );
  }
}

class _TerminalFrameSkeleton extends StatelessWidget {
  final Animation<double> shimmer;
  final double height;
  const _TerminalFrameSkeleton({required this.shimmer, required this.height});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  ShimmerBox(
                      width: 9, height: 9, circle: true, animation: shimmer),
                ],
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ShimmerBox(
                      width: double.infinity, height: 14, animation: shimmer),
                ),
              ]),
            ),
          ),
          Divider(height: 1, color: t.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 6; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      ShimmerBox(width: 64, height: 12, animation: shimmer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShimmerBox(
                            width: double.infinity,
                            height: 12,
                            animation: shimmer),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
