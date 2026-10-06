import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// A sailor's portrait for a crew card: a round face under a peaked cap in
/// the sailor's color, with a striped jersey below.
class SailorArt extends StatelessWidget {
  const SailorArt({super.key, required this.color, this.size = 64});

  /// The color of the sailor's cap and jersey stripes.
  final Color color;
  final double size;

  @override
  Widget build(final BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _SailorPainter(color)));
}

class _SailorPainter extends CustomPainter {
  const _SailorPainter(this.color);

  final Color color;

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);

    // A porthole frame around the portrait.
    canvas
      ..drawCircle(center, w / 2, Paint()..color = Palette.brass)
      ..drawCircle(center, w / 2 - 3, Paint()..color = Palette.shallows);
    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: w / 2 - 3)));

    // Jersey with stripes.
    final Rect jersey = Rect.fromLTWH(w * 0.14, h * 0.68, w * 0.72, h * 0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(jersey, Radius.circular(w * 0.2)), Paint()..color = Palette.sail);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(jersey.left, jersey.top + h * (0.06 + i * 0.09), jersey.width, h * 0.04),
        Paint()..color = color,
      );
    }

    // Face.
    final Offset face = Offset(w / 2, h * 0.5);
    canvas.drawCircle(face, w * 0.2, Paint()..color = const Color(0xFFF1C9A5));
    final Paint eye = Paint()..color = Palette.night;
    canvas
      ..drawCircle(face.translate(-w * 0.07, -h * 0.01), w * 0.022, eye)
      ..drawCircle(face.translate(w * 0.07, -h * 0.01), w * 0.022, eye)
      ..drawArc(
        Rect.fromCenter(center: face.translate(0, h * 0.05), width: w * 0.14, height: h * 0.08),
        0.2,
        math.pi - 0.4,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = Palette.plankDark,
      );

    // Peaked cap.
    final Path cap = Path()
      ..moveTo(w * 0.27, h * 0.38)
      ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.73, h * 0.38)
      ..close();
    canvas
      ..drawPath(cap, Paint()..color = color)
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, h * 0.36, w * 0.52, h * 0.05), const Radius.circular(2)),
        Paint()..color = Palette.night,
      )
      ..drawCircle(Offset(w / 2, h * 0.28), w * 0.03, Paint()..color = Palette.brass)
      ..restore();
  }

  @override
  bool shouldRepaint(final _SailorPainter oldDelegate) => oldDelegate.color != color;
}

/// A voyage on a sea chart: a dotted course from one port to another, with a
/// cross where it made landfall.
class VoyageChartArt extends StatelessWidget {
  const VoyageChartArt({super.key, required this.seed, this.ink = Palette.brass});

  /// Picks the course, so each voyage draws its own.
  final int seed;
  final Color ink;

  @override
  Widget build(final BuildContext context) => CustomPaint(painter: _VoyagePainter(seed, ink), child: const SizedBox.expand());
}

class _VoyagePainter extends CustomPainter {
  const _VoyagePainter(this.seed, this.ink);

  final int seed;
  final Color ink;

  @override
  void paint(final Canvas canvas, final Size size) {
    final math.Random random = math.Random(seed);
    final double w = size.width;
    final double h = size.height;

    // Chart paper and a faint grid of latitude lines.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      Paint()..color = const Color(0xFF1B4A6E),
    );
    final Paint grid = Paint()
      ..color = Palette.foam.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double y = h / 5; y < h; y += h / 5) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // The course, a dotted curve.
    final Offset from = Offset(w * (0.12 + random.nextDouble() * 0.1), h * (0.65 + random.nextDouble() * 0.2));
    final Offset to = Offset(w * (0.75 + random.nextDouble() * 0.12), h * (0.15 + random.nextDouble() * 0.25));
    final Offset bend = Offset(w * (0.3 + random.nextDouble() * 0.4), h * random.nextDouble());
    final Paint dot = Paint()..color = ink;
    for (double t = 0; t <= 1.0; t += 0.06) {
      final double u = 1 - t;
      final Offset p = from * (u * u) + bend * (2 * u * t) + to * (t * t);
      canvas.drawCircle(p, 1.6, dot);
    }

    // Home port and landfall.
    canvas.drawCircle(from, 4, Paint()..color = Palette.foam);
    final Paint cross = Paint()
      ..color = Palette.buoyRed
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(to.translate(-5, -5), to.translate(5, 5), cross)
      ..drawLine(to.translate(5, -5), to.translate(-5, 5), cross);
  }

  @override
  bool shouldRepaint(final _VoyagePainter oldDelegate) => oldDelegate.seed != seed || oldDelegate.ink != ink;
}
