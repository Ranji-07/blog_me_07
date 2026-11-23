import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'project_deck_style.dart';

ImageProvider? projectImageProvider(String? source) {
  if (source == null || source.trim().isEmpty) return null;
  final uri = Uri.tryParse(source);
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
      ? NetworkImage(source)
      : AssetImage(source);
}

/// A single loading/failure treatment shared by the deck and its detail sheet.
class ProjectArtwork extends StatelessWidget {
  final String? screenshot;
  final String iconKey;
  final bool centred;
  final bool reducedMotion;
  const ProjectArtwork(
      {super.key,
      required this.screenshot,
      required this.iconKey,
      required this.centred,
      this.reducedMotion = false});

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
        color: ProjectDeckStyle.raised,
        child: Center(
            child: Semantics(
                image: true,
                label: '$iconKey project illustration',
                child: CustomPaint(
                    size: const Size.square(84),
                    painter: _ProjectIconPainter(
                        iconKey,
                        centred
                            ? ProjectDeckStyle.accent
                            : ProjectDeckStyle.muted)))));
    final provider = projectImageProvider(screenshot);
    if (provider == null) return fallback;
    return Image(
      image: provider,
      excludeFromSemantics: true,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => fallback,
      frameBuilder: (_, image, frame, synchronous) =>
          Stack(fit: StackFit.expand, children: [
        ExcludeSemantics(excluding: frame != null, child: fallback),
        AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: reducedMotion || synchronous
                ? Duration.zero
                : const Duration(milliseconds: 150),
            child: frame == null
                ? image
                : Semantics(
                    image: true, label: 'Project screenshot', child: image)),
      ]),
    );
  }
}

class _ProjectIconPainter extends CustomPainter {
  final String iconKey;
  final Color color;
  const _ProjectIconPainter(this.iconKey, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 84, size.height / 84);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(Offset a, Offset b) => canvas.drawLine(a, b, pen);
    void poly(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, pen);
    }

    final key = iconKey.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (key) {
      case 'chart' || 'data':
        poly(
            [const Offset(15, 16), const Offset(15, 68), const Offset(71, 68)]);
        for (final rect in [
          const Rect.fromLTWH(25, 46, 8, 15),
          const Rect.fromLTWH(41, 34, 8, 27),
          const Rect.fromLTWH(57, 20, 8, 41)
        ]) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(2)), pen);
        }
      case 'hexcluster' || 'hex' || 'cloud':
        for (final center in [
          const Offset(27, 28),
          const Offset(56, 28),
          const Offset(42, 54)
        ]) {
          final points = List.generate(
              7,
              (i) =>
                  center +
                  Offset(math.cos(math.pi / 6 + i * math.pi / 3) * 16,
                      math.sin(math.pi / 6 + i * math.pi / 3) * 16));
          poly(points);
        }
      case 'loop' || 'cicd':
        final path = Path()
          ..moveTo(42, 42)
          ..cubicTo(17, 8, 1, 27, 14, 47)
          ..cubicTo(25, 65, 37, 49, 42, 42)
          ..cubicTo(67, 8, 83, 27, 70, 47)
          ..cubicTo(59, 65, 47, 49, 42, 42);
        canvas.drawPath(path, pen);
        poly(
            [const Offset(13, 35), const Offset(14, 47), const Offset(26, 46)]);
        poly(
            [const Offset(58, 46), const Offset(70, 47), const Offset(71, 35)]);
      case 'pulse' || 'pulsemonitor' || 'observability':
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(10, 15, 64, 45), const Radius.circular(5)),
            pen);
        poly([
          const Offset(17, 39),
          const Offset(29, 39),
          const Offset(35, 28),
          const Offset(43, 48),
          const Offset(50, 35),
          const Offset(56, 39),
          const Offset(67, 39)
        ]);
        line(const Offset(42, 60), const Offset(42, 69));
        line(const Offset(28, 70), const Offset(56, 70));
      case 'chip' || 'embedded':
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(22, 22, 40, 40), const Radius.circular(5)),
            pen);
        canvas.drawRect(const Rect.fromLTWH(32, 32, 20, 20), pen);
        for (final p in [30.0, 42.0, 54.0]) {
          line(Offset(p, 13), Offset(p, 22));
          line(Offset(p, 62), Offset(p, 71));
          line(Offset(13, p), Offset(22, p));
          line(Offset(62, p), Offset(71, p));
        }
      default:
        const points = [
          Offset(42, 15),
          Offset(16, 35),
          Offset(68, 35),
          Offset(26, 67),
          Offset(59, 67)
        ];
        for (final pair in [
          [0, 1],
          [0, 2],
          [0, 3],
          [0, 4],
          [1, 2],
          [1, 3],
          [2, 4],
          [3, 4]
        ]) {
          final a = points[pair[0]],
              b = points[pair[1]],
              direction = (b - a) / (b - a).distance;
          line(a + direction * 6, b - direction * 6);
        }
        for (final point in points) {
          canvas.drawCircle(point, 5, pen);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProjectIconPainter old) =>
      old.iconKey != iconKey || old.color != color;
}
