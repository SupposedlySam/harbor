import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'palette.dart';

/// The weather over open water: a bank of fog rolling over the swell and, on a
/// clear night, a moon hung [moonTop] below the top of the sky. Fills its box
/// and paints over whatever is under it, so put it in a `Sea`'s child.
class SkyOverlay extends StatelessWidget {
  const SkyOverlay({super.key, this.fog = 0.0, this.moon = false, this.moonTop = 24.0});

  /// How thick the fog is, from 0 (clear) to 1 (pea soup).
  final double fog;

  /// Whether the moon is out.
  final bool moon;

  /// How far below the top of the sky the moon hangs: keep it clear of the coast.
  final double moonTop;

  @override
  Widget build(final BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _SkyPainter(fog, moon, moonTop), child: const SizedBox.expand()),
  );
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter(this.fog, this.moon, this.moonTop);

  final double fog;
  final bool moon;
  final double moonTop;

  @override
  void paint(final Canvas canvas, final Size size) {
    if (moon) {
      final Offset center = Offset(size.width * 0.78, moonTop + 26);
      canvas
        ..drawCircle(center, 42, Paint()..color = Palette.sail.withValues(alpha: 0.08))
        ..drawCircle(center, 22, Paint()..color = Palette.sail.withValues(alpha: 0.9))
        ..drawCircle(center + const Offset(-6, -4), 4, Paint()..color = Palette.rope.withValues(alpha: 0.35))
        ..drawCircle(center + const Offset(7, 6), 3, Paint()..color = Palette.rope.withValues(alpha: 0.3));
      // The moon's path on the water.
      final math.Random random = math.Random(5);
      for (int i = 0; i < 18; i++) {
        final double y = center.dy + 60 + i * 22.0;
        if (y > size.height) {
          break;
        }
        final double half = 6 + random.nextDouble() * 18 + i * 1.2;
        canvas.drawLine(
          Offset(center.dx - half, y),
          Offset(center.dx + half, y),
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = Palette.sail.withValues(alpha: 0.22 - i * 0.01),
        );
      }
    }
    if (fog > 0) {
      final Rect rect = Offset.zero & size;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Palette.foam.withValues(alpha: 0.5 * fog),
              Palette.foam.withValues(alpha: 0.15 * fog),
              Palette.foam.withValues(alpha: 0.4 * fog),
            ],
          ).createShader(rect),
      );
      // Wisps.
      final math.Random random = math.Random(9);
      for (int i = 0; i < 9; i++) {
        final Rect wisp = Rect.fromCenter(
          center: Offset(random.nextDouble() * size.width, size.height * (0.15 + random.nextDouble() * 0.8)),
          width: 120 + random.nextDouble() * 160,
          height: 18 + random.nextDouble() * 20,
        );
        canvas.drawOval(wisp, Paint()..color = Palette.foam.withValues(alpha: 0.18 * fog));
      }
    }
  }

  @override
  bool shouldRepaint(final _SkyPainter oldDelegate) =>
      oldDelegate.fog != fog || oldDelegate.moon != moon || oldDelegate.moonTop != moonTop;
}

/// A navigator's chart of one voyage: a dotted course from the home port to
/// the destination, with a compass rose in the corner. [seed] bends the course.
class VoyageChartArt extends StatelessWidget {
  const VoyageChartArt({super.key, this.seed = 0});

  final int seed;

  @override
  Widget build(final BuildContext context) =>
      CustomPaint(painter: _ChartPainter(seed), child: const SizedBox.expand());
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.seed);

  final int seed;

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final math.Random random = math.Random(seed);

    // Grid lines, as on a sea chart.
    final Paint grid = Paint()
      ..color = Palette.foam.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (double y = 0; y < h; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // The course: a bendy dotted line between two ports.
    final Offset from = Offset(w * 0.1, h * (0.7 + random.nextDouble() * 0.15));
    final Offset to = Offset(w * 0.9, h * (0.15 + random.nextDouble() * 0.2));
    final Offset bend = Offset(w * (0.3 + random.nextDouble() * 0.4), h * random.nextDouble());
    final Path course = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(bend.dx, bend.dy, to.dx, to.dy);
    final Paint dot = Paint()..color = Palette.rope.withValues(alpha: 0.7);
    for (final ui.PathMetric metric in course.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        final ui.Tangent? at = metric.getTangentForOffset(d);
        if (at != null) {
          canvas.drawCircle(at.position, 1.6, dot);
        }
      }
    }
    canvas
      ..drawCircle(from, 5, Paint()..color = Palette.brass)
      ..drawCircle(to, 7, Paint()..color = Palette.buoyRed.withValues(alpha: 0.9))
      ..drawCircle(to, 3, Paint()..color = Palette.sail);

    // A compass rose.
    final Offset rose = Offset(w - 26, h - 26);
    final Paint needle = Paint()..color = Palette.foam.withValues(alpha: 0.35);
    for (int i = 0; i < 4; i++) {
      final double a = i * math.pi / 2;
      canvas.drawPath(
        Path()
          ..moveTo(rose.dx + math.cos(a) * 16, rose.dy + math.sin(a) * 16)
          ..lineTo(rose.dx + math.cos(a + math.pi / 2) * 4, rose.dy + math.sin(a + math.pi / 2) * 4)
          ..lineTo(rose.dx + math.cos(a - math.pi / 2) * 4, rose.dy + math.sin(a - math.pi / 2) * 4)
          ..close(),
        i == 3 ? (Paint()..color = Palette.buoyRed.withValues(alpha: 0.8)) : needle,
      );
    }
  }

  @override
  bool shouldRepaint(final _ChartPainter oldDelegate) => oldDelegate.seed != seed;
}
