import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Brushes for drawings seen from above: boats, roofs and breakwaters on a chart.
abstract final class TopDown {
  static const Color land = Color(0xFF6F9A52);
  static const Color landDark = Color(0xFF557C3E);
  static const Color sand = Color(0xFFE3CF9A);
  static const List<Color> roofs = <Color>[Color(0xFFC0583A), Color(0xFFA9452E), Color(0xFF7A8A96), Color(0xFFD9774F)];

  /// A boat seen from above, its bow pointing along [angle] (radians, 0 = right).
  static void boat(final Canvas canvas, final Offset center, final double length, final double angle, final Color hull) {
    final double beam = length * 0.36;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle);
    final Path body = Path()
      ..moveTo(length / 2, 0)
      ..quadraticBezierTo(length * 0.2, -beam / 2, -length * 0.3, -beam / 2)
      ..lineTo(-length / 2, -beam * 0.38)
      ..lineTo(-length / 2, beam * 0.38)
      ..lineTo(-length * 0.3, beam / 2)
      ..quadraticBezierTo(length * 0.2, beam / 2, length / 2, 0)
      ..close();
    canvas
      ..drawPath(body.shift(const Offset(1.2, 1.6)), Paint()..color = Colors.black.withValues(alpha: 0.22))
      ..drawPath(body, Paint()..color = hull)
      ..drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.black.withValues(alpha: 0.35),
      )
      // The deck, and a cabin roof.
      ..drawPath(
        Path()
          ..moveTo(length * 0.38, 0)
          ..quadraticBezierTo(length * 0.15, -beam * 0.36, -length * 0.4, -beam * 0.32)
          ..lineTo(-length * 0.4, beam * 0.32)
          ..quadraticBezierTo(length * 0.15, beam * 0.36, length * 0.38, 0)
          ..close(),
        Paint()..color = Palette.plankLight,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-length * 0.22, -beam * 0.24, length * 0.3, beam * 0.48), Radius.circular(beam * 0.1)),
        Paint()..color = Palette.sail,
      )
      ..restore();
  }

  /// A house seen from above: a roof with its ridge.
  static void roof(final Canvas canvas, final Rect rect, final Color color) {
    canvas
      ..drawRect(rect.shift(const Offset(1.5, 1.5)), Paint()..color = Colors.black.withValues(alpha: 0.25))
      ..drawRect(rect, Paint()..color = color);
    final bool wide = rect.width >= rect.height;
    final Rect shade = wide
        ? Rect.fromLTRB(rect.left, rect.center.dy, rect.right, rect.bottom)
        : Rect.fromLTRB(rect.center.dx, rect.top, rect.right, rect.bottom);
    canvas
      ..drawRect(shade, Paint()..color = Colors.black.withValues(alpha: 0.16))
      ..drawLine(
        wide ? Offset(rect.left, rect.center.dy) : Offset(rect.center.dx, rect.top),
        wide ? Offset(rect.right, rect.center.dy) : Offset(rect.center.dx, rect.bottom),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..strokeWidth = 0.8,
      );
  }

  /// A rubble breakwater along [path]: dark stone with lighter blocks on top.
  static void breakwater(final Canvas canvas, final Path path, final double width) {
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 5
          ..strokeCap = StrokeCap.round
          ..color = Palette.foam.withValues(alpha: 0.55),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = Palette.stoneDark,
      );
    final math.Random random = math.Random(11);
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (double d = 2; d < metric.length - 2; d += width * 0.55) {
        final ui.Tangent? t = metric.getTangentForOffset(d);
        if (t == null) {
          continue;
        }
        final Offset jitter = Offset(t.vector.dy, -t.vector.dx) * ((random.nextDouble() - 0.5) * width * 0.4);
        canvas.drawCircle(
          t.position + jitter,
          width * (0.18 + random.nextDouble() * 0.12),
          Paint()..color = Color.lerp(Palette.stone, const Color(0xFFB0B7BD), random.nextDouble())!,
        );
      }
    }
  }

  /// A harbor light at a breakwater's head: a white tower and its colored lamp.
  static void light(final Canvas canvas, final Offset at, final double r, final Color lamp) {
    canvas
      ..drawCircle(at, r * 2.4, Paint()..color = lamp.withValues(alpha: 0.25))
      ..drawCircle(at, r, Paint()..color = Colors.white)
      ..drawCircle(at, r * 0.55, Paint()..color = lamp);
  }

  /// Wave marks on open water.
  static void waves(final Canvas canvas, final Rect area, {final int count = 18, final int seed = 2}) {
    final math.Random random = math.Random(seed);
    final Paint wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.foam.withValues(alpha: 0.4);
    for (int i = 0; i < count; i++) {
      final Offset at = Offset(area.left + random.nextDouble() * area.width, area.top + random.nextDouble() * area.height);
      canvas.drawArc(Rect.fromCenter(center: at, width: 10, height: 4), math.pi * 1.1, math.pi * 0.8, false, wave);
    }
  }
}

/// A harbor from above: a bay sheltered by two breakwater arms, with a town on
/// the shore and boats on the calm water inside.
class HarborArt extends StatelessWidget {
  const HarborArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _HarborPainter(), child: SizedBox.expand());
}

class _HarborPainter extends CustomPainter {
  const _HarborPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    // The open sea, deeper toward the bottom.
    final Rect all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Palette.sea],
        ).createShader(all),
    );
    TopDown.waves(canvas, Rect.fromLTWH(0, h * 0.75, w, h * 0.25), count: 26);
    TopDown.waves(canvas, Rect.fromLTWH(0, h * 0.3, w * 0.07, h * 0.6), count: 6, seed: 4);
    TopDown.waves(canvas, Rect.fromLTWH(w * 0.93, h * 0.3, w * 0.07, h * 0.6), count: 6, seed: 5);

    // The calm water inside the arms.
    final Path bay = Path()
      ..moveTo(w * 0.08, h * 0.3)
      ..quadraticBezierTo(w * 0.1, h * 0.86, w * 0.42, h * 0.86)
      ..lineTo(w * 0.58, h * 0.86)
      ..quadraticBezierTo(w * 0.9, h * 0.86, w * 0.92, h * 0.3)
      ..close();
    canvas.drawPath(bay, Paint()..color = const Color(0xFF3B9AC4));

    // The shore and the town on it.
    final Path shoreline = Path()
      ..moveTo(0, h * 0.3)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w, h * 0.3);
    final Path land = Path.from(shoreline)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas
      ..drawPath(land, Paint()..color = TopDown.land)
      ..drawPath(
        shoreline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Palette.stoneDark,
      )
      ..drawPath(
        shoreline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFB0B7BD),
      );
    // A road along the quay, and streets up the hill.
    final Paint road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = TopDown.sand;
    canvas.drawPath(shoreline.shift(Offset(0, -h * 0.05)), road);
    for (final double x in <double>[0.3, 0.5, 0.7]) {
      canvas.drawLine(Offset(w * x, h * (0.36 - (x - 0.5).abs() * 0.3)), Offset(w * x, 0), road);
    }
    final math.Random random = math.Random(7);
    for (double y = h * 0.03; y < h * 0.3; y += h * 0.07) {
      for (double x = w * 0.02; x < w * 0.98; x += w * 0.055) {
        final double shoreY = h * 0.3 + h * 0.2 * (1 - math.pow((x / w - 0.5) * 2, 2)) * 0.97 - h * 0.08;
        if (y > shoreY || random.nextDouble() < 0.18 || <double>[0.3, 0.5, 0.7].any((final double r) => (x / w + 0.02 - r).abs() < 0.025)) {
          continue;
        }
        final bool wide = random.nextBool();
        TopDown.roof(
          canvas,
          Rect.fromLTWH(x, y, wide ? w * 0.04 : w * 0.026, wide ? h * 0.035 : h * 0.05),
          TopDown.roofs[random.nextInt(TopDown.roofs.length)],
        );
      }
    }
    // A church with a tower on the hill.
    canvas
      ..drawRect(Rect.fromLTWH(w * 0.46, h * 0.02, w * 0.08, h * 0.05), Paint()..color = const Color(0xFFE8E2D4))
      ..drawCircle(Offset(w * 0.5, h * 0.045), h * 0.022, Paint()..color = Palette.stoneDark);

    // The two breakwater arms, with a light at each head.
    final Path west = Path()
      ..moveTo(w * 0.07, h * 0.3)
      ..quadraticBezierTo(w * 0.09, h * 0.88, w * 0.42, h * 0.87);
    final Path east = Path()
      ..moveTo(w * 0.93, h * 0.3)
      ..quadraticBezierTo(w * 0.91, h * 0.88, w * 0.58, h * 0.87);
    TopDown.breakwater(canvas, west, h * 0.05);
    TopDown.breakwater(canvas, east, h * 0.05);
    TopDown.light(canvas, Offset(w * 0.42, h * 0.87), h * 0.022, Palette.buoyRed);
    TopDown.light(canvas, Offset(w * 0.58, h * 0.87), h * 0.022, const Color(0xFF2E9D5B));

    // Boats moored along the quay, and one coming in through the mouth.
    for (int i = 0; i < 6; i++) {
      final double x = w * (0.24 + i * 0.1);
      final double shoreY = h * 0.3 + h * 0.2 * (1 - math.pow((x / w - 0.5) * 2, 2)) * 0.97;
      TopDown.boat(canvas, Offset(x, shoreY + h * 0.07), h * 0.12, math.pi / 2, Palette.hulls[i % Palette.hulls.length]);
    }
    TopDown.boat(canvas, Offset(w * 0.3, h * 0.66), h * 0.13, -0.3, Palette.sail);
    // The incoming boat leaves a V of wake behind it.
    final Offset bow = Offset(w * 0.5, h * 0.8);
    final Paint wake = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.7);
    canvas
      ..drawLine(bow + Offset(0, h * 0.05), bow + Offset(-w * 0.05, h * 0.2), wake)
      ..drawLine(bow + Offset(0, h * 0.05), bow + Offset(w * 0.05, h * 0.2), wake);
    TopDown.boat(canvas, bow, h * 0.13, -math.pi / 2, Palette.buoyRed);
  }

  @override
  bool shouldRepaint(final _HarborPainter oldDelegate) => false;
}

/// The open sea, out to the horizon: the water every harbor sits on.
class HarborSeaArt extends StatelessWidget {
  const HarborSeaArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SeaPainter(), child: SizedBox.expand());
}

class _SeaPainter extends CustomPainter {
  const _SeaPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.42;
    // An evening sky, warm at the horizon.
    final Rect sky = Rect.fromLTWH(0, 0, w, horizon);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF7FB6E0), Color(0xFFF6D7A8)],
        ).createShader(sky),
    );
    final Offset sun = Offset(w * 0.68, horizon - h * 0.06);
    canvas
      ..drawCircle(sun, h * 0.16, Paint()..color = const Color(0x33FFE08A))
      ..drawCircle(sun, h * 0.075, Paint()..color = const Color(0xFFFFD36E));
    Scenery.cloud(canvas, Offset(w * 0.2, h * 0.12), h * 0.04);
    Scenery.cloud(canvas, Offset(w * 0.45, h * 0.2), h * 0.025);

    // The sea, darkest at the horizon and nearest the viewer.
    final Rect sea = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1D5F8C), Palette.shallows, Palette.sea],
          stops: <double>[0, 0.35, 1],
        ).createShader(sea),
    );
    // The sun's glitter path down the water.
    final math.Random random = math.Random(9);
    for (int i = 0; i < 70; i++) {
      final double t = random.nextDouble();
      final double y = horizon + 2 + t * t * (h - horizon);
      final double spread = w * (0.02 + t * 0.14);
      final double x = sun.dx + (random.nextDouble() - 0.5) * spread * 2;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 3 + t * 10, height: 1 + t * 1.5),
        Paint()..color = const Color(0xFFFFE9B0).withValues(alpha: 0.9 - t * 0.5),
      );
    }
    // Swells, closer together toward the horizon.
    final Paint swell = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.35);
    for (int row = 1; row < 9; row++) {
      final double t = row / 9;
      final double y = horizon + (h - horizon) * t * t;
      swell.strokeWidth = 0.6 + t * 1.6;
      final Path path = Path()..moveTo(0, y);
      final double wave = 10 + t * 50;
      for (double x = 0; x <= w; x += 4) {
        path.lineTo(x, y + math.sin(x / wave + row * 1.7) * (0.6 + t * 3));
      }
      canvas.drawPath(path, swell);
    }
    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..color = const Color(0xFF15486C)
        ..strokeWidth = 1.2,
    );
    // A ship hull-down on the horizon, and a gull.
    final Paint ship = Paint()..color = const Color(0xFF2B3440);
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.16, horizon - 3)
          ..lineTo(w * 0.29, horizon - 3)
          ..lineTo(w * 0.28, horizon)
          ..lineTo(w * 0.17, horizon)
          ..close(),
        ship,
      )
      ..drawRect(Rect.fromLTWH(w * 0.24, horizon - 8, w * 0.03, 5), ship)
      ..drawRect(Rect.fromLTWH(w * 0.255, horizon - 12, 2, 4), ship);
    final Paint gull = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF37474F);
    for (final Offset at in <Offset>[Offset(w * 0.4, h * 0.3), Offset(w * 0.47, h * 0.26)]) {
      canvas.drawPath(
        Path()
          ..moveTo(at.dx - 7, at.dy)
          ..quadraticBezierTo(at.dx - 3, at.dy - 4, at.dx, at.dy)
          ..quadraticBezierTo(at.dx + 3, at.dy - 4, at.dx + 7, at.dy),
        gull,
      );
    }
  }

  @override
  bool shouldRepaint(final _SeaPainter oldDelegate) => false;
}

/// A chart of a coast with two harbor towns: one close by, and a new port
/// further up the coast with its own quays and breakwater.
class NewPortArt extends StatelessWidget {
  const NewPortArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _NewPortPainter(), child: SizedBox.expand());
}

class _NewPortPainter extends CustomPainter {
  const _NewPortPainter();

  double _coastX(final double y, final Size size) =>
      size.width * (0.36 + 0.16 * (y / size.height)) + math.sin(y / size.height * math.pi * 3) * size.width * 0.03;

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(colors: <Color>[Palette.shallows, Palette.sea]).createShader(all),
    );
    TopDown.waves(canvas, Rect.fromLTWH(w * 0.6, 0, w * 0.4, h), count: 30, seed: 8);

    // The land, on the left, with a shoal line off the coast.
    final Path land = Path()..moveTo(0, 0);
    for (double y = 0; y <= h; y += 4) {
      land.lineTo(_coastX(y, size), y);
    }
    land
      ..lineTo(0, h)
      ..close();
    canvas
      ..drawPath(
        land,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = const Color(0xFF55A9CF),
      )
      ..drawPath(land, Paint()..color = TopDown.land)
      ..drawPath(
        land,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = TopDown.sand,
      );
    // Hills inland.
    for (final Offset c in <Offset>[Offset(w * 0.1, h * 0.5), Offset(w * 0.17, h * 0.15), Offset(w * 0.08, h * 0.9)]) {
      for (int ring = 3; ring > 0; ring--) {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: w * 0.06 * ring, height: h * 0.1 * ring),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = TopDown.landDark,
        );
      }
    }
    // The coast road between the two towns.
    final Path road = Path()..moveTo(_coastX(h * 0.74, size) - w * 0.1, h * 0.74);
    road.quadraticBezierTo(w * 0.22, h * 0.48, _coastX(h * 0.24, size) - w * 0.08, h * 0.24);
    _dashed(
      canvas,
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = TopDown.sand,
    );

    _port(canvas, size, Offset(_coastX(h * 0.74, size), h * 0.74), h * 0.13, 1);
    _port(canvas, size, Offset(_coastX(h * 0.24, size), h * 0.24), h * 0.1, 2);

    // A course from one port to the next.
    final Path course = Path()
      ..moveTo(_coastX(h * 0.74, size) + h * 0.16, h * 0.74)
      ..quadraticBezierTo(w * 0.78, h * 0.5, _coastX(h * 0.24, size) + h * 0.14, h * 0.26);
    _dashed(
      canvas,
      course,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    TopDown.boat(canvas, Offset(w * 0.72, h * 0.52), h * 0.1, -math.pi / 2 - 0.4, Palette.sail);

    // A small compass rose.
    final Offset rose = Offset(w * 0.9, h * 0.82);
    final double r = h * 0.1;
    canvas.drawCircle(
      rose,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.6),
    );
    for (int i = 0; i < 4; i++) {
      final double a = i * math.pi / 2;
      canvas.drawPath(
        Path()
          ..moveTo(rose.dx + math.cos(a - math.pi / 2) * r, rose.dy + math.sin(a - math.pi / 2) * r)
          ..lineTo(rose.dx + math.cos(a) * r * 0.2, rose.dy + math.sin(a) * r * 0.2)
          ..lineTo(rose.dx + math.cos(a + math.pi) * r * 0.2, rose.dy + math.sin(a + math.pi) * r * 0.2)
          ..close(),
        Paint()..color = i == 0 ? Palette.buoyRed : Palette.sail,
      );
    }
  }

  /// A harbor town in a cove at [mouth]: its own quays, breakwater, roofs and boats.
  void _port(final Canvas canvas, final Size size, final Offset mouth, final double r, final int seed) {
    final Offset center = mouth - Offset(r * 0.4, 0);
    // The cove, cut into the land.
    canvas.drawCircle(center, r * 0.75, Paint()..color = const Color(0xFF3B9AC4));
    // Its quay walls around the inside.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.75),
      math.pi * 0.55,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Palette.stoneDark,
    );
    // A breakwater arm sheltering the cove.
    final Path arm = Path()
      ..moveTo(center.dx + r * 0.2, center.dy - r * 0.75)
      ..quadraticBezierTo(center.dx + r * 1.1, center.dy - r * 0.5, center.dx + r * 0.95, center.dy + r * 0.4);
    TopDown.breakwater(canvas, arm, r * 0.16);
    TopDown.light(canvas, Offset(center.dx + r * 0.95, center.dy + r * 0.4), r * 0.08, Palette.buoyRed);
    // Roofs in a ring behind the quays.
    final math.Random random = math.Random(seed);
    for (int ring = 0; ring < 2; ring++) {
      final double rr = r * (1.0 + ring * 0.32);
      for (double a = math.pi * 0.6; a < math.pi * 1.45; a += 0.24 + ring * 0.02) {
        if (random.nextDouble() < 0.15) {
          continue;
        }
        final Offset at = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
        final double s = r * (0.16 + random.nextDouble() * 0.06);
        TopDown.roof(canvas, Rect.fromCenter(center: at, width: s, height: s * 0.75), TopDown.roofs[random.nextInt(TopDown.roofs.length)]);
      }
    }
    // Boats tied up inside.
    for (int i = 0; i < 3; i++) {
      final double a = math.pi * (0.75 + i * 0.25);
      TopDown.boat(
        canvas,
        center + Offset(math.cos(a) * r * 0.48, math.sin(a) * r * 0.48),
        r * 0.32,
        a + math.pi,
        Palette.hulls[(i + seed * 2) % Palette.hulls.length],
      );
    }
  }

  void _dashed(final Canvas canvas, final Path path, final Paint paint) {
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 5, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(final _NewPortPainter oldDelegate) => false;
}

/// A skiff hoisted on a quayside davit, the winch wound in just as high as
/// the boat needs and no higher.
class HugBodyArt extends StatelessWidget {
  const HugBodyArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _HugBodyPainter(), child: SizedBox.expand());
}

class _HugBodyPainter extends CustomPainter {
  const _HugBodyPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.74;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);

    // The quay the davit stands on.
    final double quayTop = h * 0.6;
    final Rect wall = Rect.fromLTRB(0, quayTop, w * 0.3, h);
    Scenery.quayWall(canvas, wall);
    Scenery.bollard(canvas, Offset(w * 0.06, quayTop), h * 0.05);

    // The davit: a steel post, a jib out over the water, and a brace.
    final Paint steel = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final Offset foot = Offset(w * 0.22, quayTop);
    final Offset head = Offset(w * 0.22, h * 0.1);
    final Offset tip = Offset(w * 0.62, h * 0.12);
    canvas
      ..drawLine(foot, head, steel)
      ..drawLine(head, tip, steel..strokeWidth = 4)
      ..drawLine(Offset(w * 0.22, h * 0.32), Offset(w * 0.38, h * 0.115), steel..strokeWidth = 2.5)
      ..drawRect(Rect.fromLTWH(foot.dx - 9, foot.dy - 4, 18, 4), Paint()..color = const Color(0xFF263238));
    // The winch drum on the post, with a crank.
    final Offset drum = Offset(w * 0.22, h * 0.44);
    canvas
      ..drawCircle(drum, h * 0.045, Paint()..color = Palette.buoyRed)
      ..drawCircle(drum, h * 0.02, Paint()..color = Palette.rope)
      ..drawLine(
        drum,
        drum + Offset(h * 0.07, -h * 0.03),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 2,
      );
    // The fall: from the drum up the post, along the jib, and down to the block.
    final Paint cable = Paint()
      ..color = Palette.rope
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final double block = h * 0.32;
    canvas
      ..drawPath(
        Path()
          ..moveTo(drum.dx + 3, drum.dy)
          ..lineTo(head.dx + 3, head.dy + 2)
          ..lineTo(tip.dx, tip.dy + 2)
          ..lineTo(tip.dx, block),
        cable,
      )
      ..drawCircle(Offset(tip.dx, tip.dy + 3), 4, Paint()..color = const Color(0xFF263238))
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(tip.dx, block + 4), width: 8, height: 10), const Radius.circular(2)),
        Paint()..color = const Color(0xFF263238),
      );
    // The spreader bar and slings, down to the skiff.
    final double bar = block + h * 0.08;
    final double half = w * 0.13;
    final double keel = bar + h * 0.22;
    canvas
      ..drawLine(Offset(tip.dx, block + 8), Offset(tip.dx - half * 0.6, bar), cable)
      ..drawLine(Offset(tip.dx, block + 8), Offset(tip.dx + half * 0.6, bar), cable)
      ..drawLine(
        Offset(tip.dx - half * 0.7, bar),
        Offset(tip.dx + half * 0.7, bar),
        Paint()
          ..color = Palette.plankDark
          ..strokeWidth = 3,
      )
      ..drawLine(Offset(tip.dx - half * 0.65, bar), Offset(tip.dx - half * 0.75, keel - h * 0.06), cable)
      ..drawLine(Offset(tip.dx + half * 0.65, bar), Offset(tip.dx + half * 0.75, keel - h * 0.06), cable);
    // The skiff, hanging just clear of the water.
    final Path hull = Path()
      ..moveTo(tip.dx - half, keel - h * 0.1)
      ..lineTo(tip.dx + half * 1.05, keel - h * 0.11)
      ..quadraticBezierTo(tip.dx + half * 0.85, keel, tip.dx + half * 0.4, keel)
      ..lineTo(tip.dx - half * 0.55, keel)
      ..quadraticBezierTo(tip.dx - half * 0.95, keel - h * 0.02, tip.dx - half, keel - h * 0.1)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = const Color(0xFF2E7D5B))
      ..drawRect(Rect.fromLTWH(tip.dx - half, keel - h * 0.105, half * 2.05, h * 0.02), Paint()..color = Palette.sail);
    // Drips falling from the keel, and their rings on the water.
    final Paint drip = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final double dx in <double>[-0.3, 0.1, 0.35]) {
      canvas.drawCircle(Offset(tip.dx + half * dx, keel + h * 0.03 + dx.abs() * h * 0.05), 1.4, drip);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(tip.dx + half * dx, waterline + 2), width: 10, height: 3),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.6),
      );
    }
    // A dimension line: the hoist is as tall as the boat it carries.
    final double x = tip.dx + half * 1.45;
    final Paint dim = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 1.2;
    canvas
      ..drawLine(Offset(x, bar), Offset(x, keel), dim)
      ..drawLine(Offset(x - 4, bar), Offset(x + 4, bar), dim)
      ..drawLine(Offset(x - 4, keel), Offset(x + 4, keel), dim);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _HugBodyPainter oldDelegate) => false;
}
