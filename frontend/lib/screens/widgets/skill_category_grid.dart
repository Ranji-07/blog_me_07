import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/technology.dart';
import 'package:portfolio/screens/widgets/technology_word_cloud.dart';

class SkillCategoryGrid extends StatelessWidget {
  final Map<String, List<String>> categories;

  const SkillCategoryGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What I Work With', style: t.heading.copyWith(color: t.button)),
        const SizedBox(height: AppSpacing.md),
        if (Responsive.isMobile(context))
          _MobileTechnologyGrid(categories: categories)
        else
          DesktopTabletSkillsLayout(categories: categories),
      ],
    );
  }
}

/// A mobile-only, Apple Watch inspired technology browser. Dragging moves the
/// skill field in any direction; the bubble closest to the viewport centre is
/// deliberately the largest and clearest.
class _MobileTechnologyGrid extends StatefulWidget {
  final Map<String, List<String>> categories;

  const _MobileTechnologyGrid({required this.categories});

  @override
  State<_MobileTechnologyGrid> createState() => _MobileTechnologyGridState();
}

class _MobileTechnologyGridState extends State<_MobileTechnologyGrid> {
  Offset _panOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final technologies = widget.categories.values
        .expand((skills) => skills)
        .map(TechnologyCatalog.fromSkill)
        .where((technology) => seen.add(technology.canonicalName))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideMobile = constraints.maxWidth >= 390;
        final viewportSize = Size(
          constraints.maxWidth,
          wideMobile ? 390 : 350,
        );
        final columns = wideMobile ? 7 : 6;
        final bubbleSize = wideMobile ? 43.0 : 39.0;
        final xStep = bubbleSize * .98;
        final yStep = bubbleSize * .92;
        final rows = (technologies.length / columns).ceil();
        final gridWidth = (columns - 1) * xStep + bubbleSize;
        final gridHeight = (rows - 1) * yStep + bubbleSize;
        final origin = Offset(
          (viewportSize.width - gridWidth) / 2,
          (viewportSize.height - gridHeight) / 2,
        );
        final centre = Offset(viewportSize.width / 2, viewportSize.height / 2);
        final maxPan =
            Offset(viewportSize.width * .34, viewportSize.height * .32);

        return Semantics(
          label: 'Technology skills. Drag the skill cloud to explore.',
          child: SizedBox(
            height: viewportSize.height,
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                setState(() {
                  _panOffset = Offset(
                    (_panOffset.dx + details.delta.dx)
                        .clamp(-maxPan.dx, maxPan.dx)
                        .toDouble(),
                    (_panOffset.dy + details.delta.dy)
                        .clamp(-maxPan.dy, maxPan.dy)
                        .toDouble(),
                  );
                });
              },
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var index = 0; index < technologies.length; index++)
                    _SkillBubble(
                      technology: technologies[index],
                      centre: centre,
                      position: _bubblePosition(
                        index: index,
                        columns: columns,
                        origin: origin,
                        panOffset: _panOffset,
                        xStep: xStep,
                        yStep: yStep,
                        bubbleSize: bubbleSize,
                      ),
                      baseSize: bubbleSize,
                      viewport: viewportSize,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _bubblePosition({
    required int index,
    required int columns,
    required Offset origin,
    required Offset panOffset,
    required double xStep,
    required double yStep,
    required double bubbleSize,
  }) {
    final row = index ~/ columns;
    final column = index % columns;
    // Alternate each row by half a step for the honeycomb structure.
    final stagger = row.isOdd ? xStep / 2 : 0.0;
    return origin +
        panOffset +
        Offset(column * xStep + stagger, row * yStep) +
        Offset(bubbleSize / 2, bubbleSize / 2);
  }
}

class _SkillBubble extends StatelessWidget {
  final Technology technology;
  final Offset position;
  final Offset centre;
  final Size viewport;
  final double baseSize;

  const _SkillBubble({
    required this.technology,
    required this.position,
    required this.centre,
    required this.viewport,
    required this.baseSize,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final distance = (position - centre).distance;
    final maxDistance = math.sqrt(
          viewport.width * viewport.width + viewport.height * viewport.height,
        ) /
        2;
    final proximity = (1 - distance / maxDistance).clamp(0.0, 1.0).toDouble();
    final scale = .46 + (proximity * .66);
    final size = baseSize * scale;
    final focused = proximity > .82;

    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: Semantics(
        label: '${technology.name} technology',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: size,
          height: size,
          padding: EdgeInsets.all(math.max(4, size * .19)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: focused ? t.buttonSoft : t.surface.withValues(alpha: .88),
            border: Border.all(
              color: focused ? t.button.withValues(alpha: .8) : t.border,
              width: focused ? 1.2 : .7,
            ),
          ),
          child: technology.logoAsset == null
              ? Center(
                  child: Text(
                    _fallbackMark(technology.canonicalName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.label.copyWith(
                      color: focused ? t.button : t.textMuted,
                      fontSize: math.max(7, size * .24),
                    ),
                  ),
                )
              : ExcludeSemantics(
                  child: SvgPicture.asset(
                    technology.logoAsset!,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => const SizedBox.shrink(),
                  ),
                ),
        ),
      ),
    );
  }

  String _fallbackMark(String name) {
    final words = name.split(RegExp(r'\s+'));
    return words.length == 1
        ? name.substring(0, name.length.clamp(0, 3)).toUpperCase()
        : words.map((word) => word.characters.first).join().toUpperCase();
  }
}
