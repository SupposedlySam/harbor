import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Drawings for the Content and Talking-to-the-harbor pages of the field guide.

const Color _chartPaper = Color(0xFFF1E6C8);
const Color _chartInk = Color(0xFF3E4A5A);
const Color _antifouling = Color(0xFF8E2B22);
const Color _channelGreen = Color(0xFF2E9E57);

Paint _stroke(final Color color, final double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round;

/// A rope from [a] to [b] that sags by [sag] in the middle, with a twist
/// pattern so it reads as laid line.
void _rope(final Canvas canvas, final Offset a, final Offset b, {final double sag = 6, final double width = 2.4}) {
  final Offset mid = Offset((a.dx + b.dx) / 2, math.max(a.dy, b.dy) + sag);
  final Path path = Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
  canvas
    ..drawPath(path, _stroke(Palette.plankDark, width + 1))
    ..drawPath(path, _stroke(Palette.rope, width));
  final Paint twist = _stroke(Palette.plankDark.withValues(alpha: 0.6), 0.8);
  for (final PathMetric metric in path.computeMetrics()) {
    for (double d = 3; d < metric.length; d += 4.5) {
      final Tangent? t = metric.getTangentForOffset(d);
      if (t == null) {
        continue;
      }
      final Offset n = Offset(-t.vector.dy, t.vector.dx) * (width / 2);
      canvas.drawLine(t.position - n + t.vector, t.position + n - t.vector, twist);
    }
  }
}

void _text(final Canvas canvas, final String text, final Offset center, {final double size = 9, final Color color = _chartInk, final FontWeight weight = FontWeight.w600, final bool italic = false}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontStyle: italic ? FontStyle.italic : FontStyle.normal),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
}

/// A lateral mark seen side-on: a red can or a green cone on a float.
void _lateralMark(final Canvas canvas, final Offset waterlineAt, final double height, {required final bool red}) {
  final double w = height * 0.42;
  final Color color = red ? Palette.buoyRed : _channelGreen;
  final Color dark = Color.lerp(color, Colors.black, 0.35)!;
  // The float, half under water.
  final Rect float = Rect.fromCenter(center: waterlineAt, width: w * 1.5, height: height * 0.28);
  canvas.drawOval(float, Paint()..color = dark);
  // The body.
  final Rect body = Rect.fromLTRB(waterlineAt.dx - w / 2, waterlineAt.dy - height * 0.7, waterlineAt.dx + w / 2, waterlineAt.dy - height * 0.06);
  canvas
    ..drawRect(body, Paint()..color = color)
    ..drawRect(Rect.fromLTWH(body.left, body.top, body.width * 0.28, body.height), Paint()..color = Colors.white.withValues(alpha: 0.22));
  // The topmark: a can for red, a cone for green.
  final double top = body.top - height * 0.08;
  if (red) {
    canvas.drawRect(Rect.fromLTRB(body.left + w * 0.1, top - height * 0.2, body.right - w * 0.1, top), Paint()..color = color);
  } else {
    final Path cone = Path()
      ..moveTo(waterlineAt.dx, top - height * 0.24)
      ..lineTo(body.right - w * 0.05, top)
      ..lineTo(body.left + w * 0.05, top)
      ..close();
    canvas.drawPath(cone, Paint()..color = color);
  }
  canvas.drawLine(Offset(waterlineAt.dx, body.top), Offset(waterlineAt.dx, top), _stroke(dark, 1.4));
}

/// A boat moored alongside a stone quay: bow and stern lines run to bollards
/// on the quay, and fenders hang between the hull and the wall.
class MooredArt extends StatelessWidget {
  const MooredArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _MooredPainter(), child: SizedBox.expand());
}

class _MooredPainter extends CustomPainter {
  const _MooredPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.66;
    final double quayTop = h * 0.36;
    Scenery.sky(canvas, size, quayTop);
    // The quay wall behind the boat, from its coping down into the water.
    Scenery.quayWall(canvas, Rect.fromLTRB(0, quayTop, w, waterline + 2));
    Scenery.water(canvas, size, waterline);
    // Bollards on the quay, fore and aft.
    final Offset sternBollard = Offset(w * 0.1, quayTop);
    final Offset bowBollard = Offset(w * 0.9, quayTop);
    Scenery.bollard(canvas, sternBollard, h * 0.06);
    Scenery.bollard(canvas, bowBollard, h * 0.06);

    // The hull, lying alongside, a little off the wall.
    final double left = w * 0.2;
    final double right = w * 0.8;
    final double deck = h * 0.5;
    final Path hull = Path()
      ..moveTo(left, deck)
      ..lineTo(right + w * 0.04, deck - h * 0.02)
      ..quadraticBezierTo(right, waterline + h * 0.04, right - w * 0.08, waterline + h * 0.08)
      ..lineTo(left + w * 0.04, waterline + h * 0.08)
      ..quadraticBezierTo(left - w * 0.01, waterline, left, deck)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = Palette.sail)
      ..save()
      ..clipPath(hull)
      ..drawRect(Rect.fromLTRB(0, waterline - h * 0.01, w, h), Paint()..color = _antifouling)
      ..drawRect(Rect.fromLTRB(0, deck, w, deck + h * 0.025), Paint()..color = const Color(0xFF1F4E79))
      ..restore();
    // Cabin, windows and mast.
    final RRect cabin = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.36, deck - h * 0.09, w * 0.6, deck), const Radius.circular(4));
    canvas.drawRRect(cabin, Paint()..color = const Color(0xFFE9E2D0));
    for (double x = w * 0.39; x < w * 0.57; x += w * 0.06) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, deck - h * 0.07, w * 0.035, h * 0.035), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2F4858),
      );
    }
    canvas.drawLine(Offset(w * 0.5, deck - h * 0.09), Offset(w * 0.5, h * 0.06), _stroke(const Color(0xFF9AA5AE), 2));
    // Fenders hang from the rail, between the hull and the wall.
    for (final double x in <double>[0.3, 0.47, 0.64]) {
      final Offset hang = Offset(w * x, deck + 1);
      canvas.drawLine(hang, hang + Offset(0, h * 0.04), _stroke(Palette.rope, 1.2));
      final RRect fender = RRect.fromRectAndRadius(Rect.fromCenter(center: hang + Offset(0, h * 0.09), width: w * 0.035, height: h * 0.1), Radius.circular(w * 0.02));
      canvas
        ..drawRRect(fender, Paint()..color = const Color(0xFF1E5AA8))
        ..drawRRect(fender.deflate(1.5).shift(const Offset(-1, 0)), Paint()..color = const Color(0xFF3B7DD8));
    }
    // Bow and stern lines to the bollards.
    _rope(canvas, Offset(left + 3, deck), sternBollard - Offset(0, h * 0.05), sag: h * 0.03);
    _rope(canvas, Offset(right + w * 0.03, deck - h * 0.02), bowBollard - Offset(0, h * 0.05), sag: h * 0.03);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _MooredPainter oldDelegate) => false;
}

/// Seen from above: boats lined up along a quay, each made fast to one long
/// mooring line, so their sterns all sit on the same line.
class MooringLineArt extends StatelessWidget {
  const MooringLineArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _MooringLinePainter(), child: SizedBox.expand());
}

class _MooringLinePainter extends CustomPainter {
  const _MooringLinePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect sea = Offset.zero & size;
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Palette.sea],
        ).createShader(sea),
    );
    // The quay, seen from above, along the top.
    final double quay = h * 0.24;
    Scenery.quayWall(canvas, Rect.fromLTWH(0, 0, w, quay));
    // The mooring line runs along the quay between two posts.
    final double lineY = quay + h * 0.12;
    final Offset a = Offset(w * 0.04, lineY);
    final Offset b = Offset(w * 0.96, lineY);
    canvas
      ..drawLine(Offset(a.dx, quay), a, _stroke(Palette.plankDark, 2))
      ..drawLine(Offset(b.dx, quay), b, _stroke(Palette.plankDark, 2));
    _rope(canvas, a, b, sag: 0, width: 2.6);
    // Boats, stern to the line, bows out to sea.
    for (int i = 0; i < 6; i++) {
      final double cx = w * (0.12 + i * 0.152);
      final Color hull = Palette.hulls[i % Palette.hulls.length];
      final double len = h * (0.42 + (i.isEven ? 0.06 : 0.0));
      final double beam = w * 0.075;
      final double stern = lineY + h * 0.05;
      final Path boat = Path()
        ..moveTo(cx - beam / 2, stern)
        ..lineTo(cx + beam / 2, stern)
        ..quadraticBezierTo(cx + beam * 0.6, stern + len * 0.6, cx, stern + len)
        ..quadraticBezierTo(cx - beam * 0.6, stern + len * 0.6, cx - beam / 2, stern)
        ..close();
      canvas
        ..drawPath(boat.shift(const Offset(2, 3)), Paint()..color = Colors.black.withValues(alpha: 0.2))
        ..drawPath(boat, Paint()..color = hull)
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx - beam * 0.32, stern + len * 0.12, beam * 0.64, len * 0.32), const Radius.circular(3)),
          Paint()..color = Palette.sail,
        );
      // Two short lines from the stern quarters to the mooring line.
      _rope(canvas, Offset(cx - beam * 0.4, stern), Offset(cx - beam * 0.7, lineY), sag: 0, width: 1.2);
      _rope(canvas, Offset(cx + beam * 0.4, stern), Offset(cx + beam * 0.7, lineY), sag: 0, width: 1.2);
    }
    // The line they all keep, dashed.
    final Paint dash = _stroke(Colors.white.withValues(alpha: 0.7), 1.2);
    for (double x = 0; x < w; x += 10) {
      canvas.drawLine(Offset(x, lineY + h * 0.05), Offset(x + 5, lineY + h * 0.05), dash);
    }
  }

  @override
  bool shouldRepaint(final _MooringLinePainter oldDelegate) => false;
}

/// A buoyed channel: red and green lateral marks lead in from the open sea to
/// the harbor mouth, and a boat steams up the middle.
class FairwayArt extends StatelessWidget {
  const FairwayArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _FairwayPainter(), child: SizedBox.expand());
}

class _FairwayPainter extends CustomPainter {
  const _FairwayPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.36;
    Scenery.sky(canvas, size, horizon);
    Scenery.water(canvas, size, horizon);
    // The harbor mouth on the horizon: two breakwater heads and a light.
    final Paint stone = Paint()..color = Palette.stoneDark;
    canvas
      ..drawRect(Rect.fromLTRB(w * 0.18, horizon - h * 0.03, w * 0.46, horizon + 2), stone)
      ..drawRect(Rect.fromLTRB(w * 0.54, horizon - h * 0.03, w * 0.82, horizon + 2), stone);
    canvas
      ..drawRect(Rect.fromLTRB(w * 0.445, horizon - h * 0.12, w * 0.46, horizon - h * 0.03), Paint()..color = Palette.buoyRed)
      ..drawRect(Rect.fromLTRB(w * 0.54, horizon - h * 0.12, w * 0.555, horizon - h * 0.03), Paint()..color = _channelGreen);
    // Pairs of marks, nearer and larger toward the viewer.
    final Offset vanish = Offset(w * 0.5, horizon);
    for (int i = 0; i < 5; i++) {
      final double t = 0.18 + i * 0.2; // 0 at horizon, 1 at the viewer
      final double y = horizon + (h - horizon) * t * 0.95;
      final double spread = w * 0.08 + w * 0.42 * t;
      final double size = h * (0.05 + 0.18 * t);
      _lateralMark(canvas, Offset(vanish.dx - spread, y), size, red: true);
      _lateralMark(canvas, Offset(vanish.dx + spread, y), size, red: false);
    }
    // The leading line up the middle, and a boat on it.
    final Paint lead = _stroke(Colors.white.withValues(alpha: 0.45), 1.2);
    for (double t = 0.1; t < 1; t += 0.06) {
      final double y0 = horizon + (h - horizon) * t;
      canvas.drawLine(Offset(w * 0.5, y0), Offset(w * 0.5, y0 + (h - horizon) * 0.025), lead);
    }
    final double by = horizon + (h - horizon) * 0.55;
    final Path boat = Path()
      ..moveTo(w * 0.5, by - h * 0.12)
      ..quadraticBezierTo(w * 0.54, by - h * 0.04, w * 0.535, by + h * 0.05)
      ..lineTo(w * 0.465, by + h * 0.05)
      ..quadraticBezierTo(w * 0.46, by - h * 0.04, w * 0.5, by - h * 0.12)
      ..close();
    canvas
      ..drawPath(boat, Paint()..color = Palette.sail)
      ..drawRect(Rect.fromLTRB(w * 0.485, by - h * 0.04, w * 0.515, by + h * 0.02), Paint()..color = const Color(0xFF1F4E79));
    // Its wake, spreading behind.
    final Paint wake = _stroke(Palette.foam.withValues(alpha: 0.7), 1.4);
    canvas
      ..drawLine(Offset(w * 0.47, by + h * 0.06), Offset(w * 0.4, h), wake)
      ..drawLine(Offset(w * 0.53, by + h * 0.06), Offset(w * 0.6, h), wake);
  }

  @override
  bool shouldRepaint(final _FairwayPainter oldDelegate) => false;
}

/// One channel marker: a red can buoy afloat, its chain running down to a
/// sinker on the seabed, seen in cross-section.
class FairwaySliverArt extends StatelessWidget {
  const FairwaySliverArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _FairwaySliverPainter(), child: SizedBox.expand());
}

class _FairwaySliverPainter extends CustomPainter {
  const _FairwaySliverPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.42;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // The seabed.
    final Path bed = Path()..moveTo(0, h * 0.88);
    for (double x = 0; x <= w; x += 12) {
      bed.lineTo(x, h * 0.88 + math.sin(x / 30) * 3);
    }
    bed
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(bed, Paint()..color = const Color(0xFFD9C38E));
    // The sinker and the chain hanging from the buoy to it.
    final Rect sinker = Rect.fromCenter(center: Offset(w * 0.68, h * 0.88), width: w * 0.08, height: h * 0.06);
    canvas.drawRect(sinker, Paint()..color = Palette.stone);
    final Offset from = Offset(w * 0.42, waterline + h * 0.07);
    final Offset to = sinker.topCenter;
    final Paint link = _stroke(const Color(0xFF3A3F44), 1.6);
    for (double t = 0; t < 1; t += 0.05) {
      final Offset p = Offset.lerp(from, to, t)! + Offset(-math.sin(t * math.pi) * w * 0.06, 0);
      canvas.drawOval(Rect.fromCenter(center: p, width: 5, height: 3.4), link);
    }
    // The buoy itself.
    _lateralMark(canvas, Offset(w * 0.42, waterline), h * 0.5, red: true);
    // Its number, as a real mark carries one.
    _text(canvas, '2', Offset(w * 0.42, waterline - h * 0.22), size: 12, color: Colors.white, weight: FontWeight.w800);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _FairwaySliverPainter oldDelegate) => false;
}

/// A landing stage: a gangway hinged at the quay runs down to a floating stage,
/// pinned at the top so it stays put while the stage rises and falls.
class SliverDockArt extends StatelessWidget {
  const SliverDockArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SliverDockPainter(), child: SizedBox.expand());
}

class _SliverDockPainter extends CustomPainter {
  const _SliverDockPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.66;
    final double quayTop = h * 0.34;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    Scenery.quayWall(canvas, Rect.fromLTRB(0, quayTop, w * 0.26, h));
    // The floating stage: a deck on a pontoon hull.
    final Rect stage = Rect.fromLTRB(w * 0.56, waterline - h * 0.07, w * 0.96, waterline + h * 0.05);
    canvas
      ..drawRect(Rect.fromLTRB(stage.left, waterline - h * 0.02, stage.right, stage.bottom), Paint()..color = const Color(0xFF37474F))
      ..drawRect(Rect.fromLTRB(stage.left, stage.top, stage.right, waterline - h * 0.02), Paint()..color = Palette.plank)
      ..drawRect(Rect.fromLTRB(stage.left, stage.top, stage.right, stage.top + 2.5), Paint()..color = Palette.plankLight);
    // Guide piles the stage slides up and down on.
    Scenery.pile(canvas, Offset(stage.left + w * 0.04, h * 0.3), h, width: w * 0.022);
    Scenery.pile(canvas, Offset(stage.right - w * 0.04, h * 0.3), h, width: w * 0.022);
    // The gangway from the hinge on the quay down to the stage.
    final Offset hinge = Offset(w * 0.25, quayTop);
    final Offset foot = Offset(stage.left + w * 0.08, stage.top);
    final Paint deck = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(hinge, foot, deck);
    final Offset up = Offset(0, -h * 0.08);
    final Paint rail = _stroke(const Color(0xFF546E7A), 1.6);
    canvas.drawLine(hinge + up, foot + up, rail);
    for (double t = 0; t <= 1.001; t += 0.2) {
      final Offset p = Offset.lerp(hinge, foot, t)!;
      canvas.drawLine(p, p + up, rail);
    }
    // The pin at the hinge: where it holds.
    canvas
      ..drawCircle(hinge, w * 0.018, Paint()..color = Palette.brass)
      ..drawCircle(hinge, w * 0.007, Paint()..color = Palette.plankDark);
    // A roller at the foot, so it rides the stage.
    canvas.drawCircle(foot + const Offset(0, 2), w * 0.012, Paint()..color = const Color(0xFF263238));
    Scenery.lamp(canvas, Offset(w * 0.08, quayTop), h * 0.2, lit: false);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _SliverDockPainter oldDelegate) => false;
}

/// Barnacles clinging to a hull below the waterline: they ride with the boat
/// wherever it goes.
class StickyArt extends StatelessWidget {
  const StickyArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _StickyPainter(), child: SizedBox.expand());
}

class _StickyPainter extends CustomPainter {
  const _StickyPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.22;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // A big hull curving across the frame: topsides above the waterline,
    // antifouling below.
    final Path hull = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.55)
      ..quadraticBezierTo(w * 0.55, h * 0.95, 0, h * 0.82)
      ..close();
    canvas
      ..save()
      ..clipPath(hull)
      ..drawRect(Rect.fromLTRB(0, 0, w, waterline), Paint()..color = const Color(0xFF1F4E79))
      ..drawRect(Rect.fromLTRB(0, waterline, w, h), Paint()..color = _antifouling)
      ..drawRect(Rect.fromLTRB(0, waterline - 3, w, waterline + 2), Paint()..color = Colors.white.withValues(alpha: 0.85));
    // Hull plating seams.
    final Paint seam = _stroke(Colors.black.withValues(alpha: 0.18), 1);
    for (double y = waterline + h * 0.12; y < h; y += h * 0.12) {
      canvas.drawLine(Offset(0, y), Offset(w, y - h * 0.04), seam);
    }
    canvas.restore();
    // Barnacles: little volcano shells, clustered low on the hull.
    final math.Random random = math.Random(11);
    for (int i = 0; i < 46; i++) {
      final double x = random.nextDouble() * w;
      final double edge = h * 0.55 + (h * 0.82 - h * 0.55) * (1 - x / w) - (x / w) * (1 - x / w) * h * 0.3;
      final double y = edge - random.nextDouble() * h * 0.32;
      if (y < waterline + 8) {
        continue;
      }
      final double r = 3 + random.nextDouble() * 6;
      final Rect shell = Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 1.7);
      canvas
        ..drawOval(shell, Paint()..color = const Color(0xFFE6E0D2))
        ..drawOval(shell.deflate(r * 0.25), Paint()..color = const Color(0xFFBDB5A3))
        ..drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 0.7, height: r * 0.5), Paint()..color = const Color(0xFF5D5446));
      for (int p = 0; p < 6; p++) {
        final double a = p * math.pi / 3;
        canvas.drawLine(Offset(x, y) + Offset(math.cos(a), math.sin(a) * 0.85) * r * 0.4,
            Offset(x, y) + Offset(math.cos(a), math.sin(a) * 0.85) * r, _stroke(const Color(0xFF9E9583), 0.7));
      }
    }
    // Bubbles drifting by.
    final Paint bubble = _stroke(Colors.white.withValues(alpha: 0.55), 1);
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(Offset(w * (0.1 + i * 0.11), h * (0.9 - (i % 3) * 0.04)), 2 + (i % 3).toDouble(), bubble);
    }
  }

  @override
  bool shouldRepaint(final _StickyPainter oldDelegate) => false;
}

/// A compass rose on a chart, with a ship held in the middle of the channel.
class CenterArt extends StatelessWidget {
  const CenterArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _CenterPainter(), child: SizedBox.expand());
}

class _CenterPainter extends CustomPainter {
  const _CenterPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _chartPaper);
    // The channel's banks, either side.
    final Paint bank = Paint()..color = const Color(0xFFDCC99A);
    canvas
      ..drawRect(Rect.fromLTRB(0, 0, w * 0.14, h), bank)
      ..drawRect(Rect.fromLTRB(w * 0.86, 0, w, h), bank)
      ..drawLine(Offset(w * 0.14, 0), Offset(w * 0.14, h), _stroke(_chartInk, 1))
      ..drawLine(Offset(w * 0.86, 0), Offset(w * 0.86, h), _stroke(_chartInk, 1));
    final Offset c = Offset(w / 2, h / 2);
    final double r = math.min(w, h) * 0.42;
    // Rings with degree ticks.
    canvas
      ..drawCircle(c, r, _stroke(_chartInk, 1.4))
      ..drawCircle(c, r * 0.9, _stroke(_chartInk, 0.8));
    for (int d = 0; d < 360; d += 5) {
      final double a = d * math.pi / 180;
      final double inner = d % 30 == 0 ? r * 0.84 : r * 0.9;
      canvas.drawLine(c + Offset(math.sin(a), -math.cos(a)) * inner, c + Offset(math.sin(a), -math.cos(a)) * r, _stroke(_chartInk, 0.7));
    }
    // The points: four long, four medium, eight short.
    void point(final double angle, final double length, final double width, final Color light, final Color dark) {
      final Offset tip = c + Offset(math.sin(angle), -math.cos(angle)) * length;
      final Offset side = Offset(math.cos(angle), math.sin(angle)) * width;
      canvas
        ..drawPath(Path()..addPolygon(<Offset>[c, tip, c + side], true), Paint()..color = light)
        ..drawPath(Path()..addPolygon(<Offset>[c, tip, c - side], true), Paint()..color = dark);
    }

    for (int i = 0; i < 16; i++) {
      if (i.isEven && i % 4 != 0) {
        point(i * math.pi / 8, r * 0.62, r * 0.07, const Color(0xFFB0A37E), _chartInk);
      } else if (i.isOdd) {
        point(i * math.pi / 8, r * 0.45, r * 0.05, const Color(0xFFCFC29D), const Color(0xFF7A6F55));
      }
    }
    for (int i = 0; i < 4; i++) {
      point(i * math.pi / 2, r * 0.82, r * 0.1, i == 0 ? Palette.buoyRed : const Color(0xFFE8DDBE), i == 0 ? const Color(0xFF9C2B22) : _chartInk);
    }
    _text(canvas, 'N', c + Offset(0, -r * 1.12 + 2), size: 11, weight: FontWeight.w800);
    // The ship, held in the middle.
    final Path ship = Path()
      ..moveTo(c.dx, c.dy - r * 0.2)
      ..quadraticBezierTo(c.dx + r * 0.08, c.dy - r * 0.05, c.dx + r * 0.07, c.dy + r * 0.18)
      ..lineTo(c.dx - r * 0.07, c.dy + r * 0.18)
      ..quadraticBezierTo(c.dx - r * 0.08, c.dy - r * 0.05, c.dx, c.dy - r * 0.2)
      ..close();
    canvas
      ..drawCircle(c, r * 0.24, Paint()..color = _chartPaper)
      ..drawPath(ship, Paint()..color = const Color(0xFF1F4E79))
      ..drawRect(Rect.fromCenter(center: c + Offset(0, r * 0.06), width: r * 0.08, height: r * 0.08), Paint()..color = Palette.sail);
  }

  @override
  bool shouldRepaint(final _CenterPainter oldDelegate) => false;
}

/// A nautical depth chart: the coast, depth contours shading from shallow to
/// deep, and soundings in fathoms scattered over the open water.
class OpenWaterArt extends StatelessWidget {
  const OpenWaterArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _OpenWaterPainter(), child: SizedBox.expand());
}

class _OpenWaterPainter extends CustomPainter {
  const _OpenWaterPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    // Depth bands: the shallows darkest blue, the deep water left white.
    Path contour(final double depth) {
      final Path p = Path()..moveTo(0, 0);
      for (double x = 0; x <= w; x += 8) {
        p.lineTo(x, h * (0.22 + depth) + math.sin(x / 40 + depth * 9) * h * 0.04 + math.sin(x / 13) * 1.5);
      }
      return p
        ..lineTo(w, 0)
        ..close();
    }

    const List<Color> bands = <Color>[Color(0xFFE3F1FB), Color(0xFFBFDDF3), Color(0xFF94C6EA)];
    for (int i = 0; i < bands.length; i++) {
      canvas.drawPath(contour(0.42 - i * 0.12), Paint()..color = bands[i]);
    }
    for (int i = 0; i < bands.length; i++) {
      canvas.drawPath(contour(0.42 - i * 0.12), _stroke(const Color(0xFF5B8DB8), 0.8));
    }
    // The land.
    final Path land = Path()..moveTo(0, 0);
    for (double x = 0; x <= w; x += 6) {
      land.lineTo(x, h * 0.16 + math.sin(x / 26) * h * 0.04 + math.sin(x / 9) * 1.2);
    }
    land
      ..lineTo(w, 0)
      ..close();
    canvas
      ..drawPath(land, Paint()..color = const Color(0xFFF2D98D))
      ..drawPath(land, _stroke(const Color(0xFF8C6D2C), 1.2));
    _text(canvas, 'HARBOR', Offset(w * 0.2, h * 0.07), size: 9, weight: FontWeight.w800, color: const Color(0xFF6B5320));
    // Soundings: the deeper, the further out.
    final math.Random random = math.Random(4);
    for (int i = 0; i < 34; i++) {
      final double x = w * 0.05 + random.nextDouble() * w * 0.9;
      final double y = h * 0.28 + random.nextDouble() * h * 0.66;
      final int depth = (2 + (y / h) * 30 + random.nextDouble() * 4).round();
      _text(canvas, '$depth', Offset(x, y), size: 8, color: const Color(0xFF2D3E50), italic: true);
    }
    // A small compass rose and the chart's border.
    final Offset c = Offset(w * 0.86, h * 0.8);
    final double r = h * 0.12;
    canvas
      ..drawCircle(c, r, _stroke(Palette.buoyRed.withValues(alpha: 0.8), 1))
      ..drawLine(c - Offset(0, r), c + Offset(0, r), _stroke(Palette.buoyRed, 1))
      ..drawLine(c - Offset(r, 0), c + Offset(r, 0), _stroke(Palette.buoyRed, 1));
    _text(canvas, 'N', c - Offset(0, r + 6), size: 7, color: Palette.buoyRed, weight: FontWeight.w800);
    canvas.drawRect((Offset.zero & size).deflate(4), _stroke(_chartInk, 1.2));
  }

  @override
  bool shouldRepaint(final _OpenWaterPainter oldDelegate) => false;
}

/// Casting off: the eye of a mooring line lifted clear of its bollard, and
/// the boat beginning to drift away from the quay.
class CastOffArt extends StatelessWidget {
  const CastOffArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _CastOffPainter(), child: SizedBox.expand());
}

class _CastOffPainter extends CustomPainter {
  const _CastOffPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double quayTop = h * 0.62;
    Scenery.sky(canvas, size, quayTop);
    // The quay in the foreground, from the left; water to the right.
    Scenery.water(canvas, Size(w, h), quayTop + h * 0.08);
    Scenery.quayWall(canvas, Rect.fromLTRB(0, quayTop, w * 0.5, h));
    // A big bollard, close up.
    final Offset base = Offset(w * 0.26, quayTop);
    final double bh = h * 0.22;
    final Paint iron = Paint()..color = const Color(0xFF263238);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - w * 0.04, base.dy - bh, base.dx + w * 0.04, base.dy), const Radius.circular(4)), iron)
      ..drawOval(Rect.fromCenter(center: base - Offset(0, bh), width: w * 0.13, height: h * 0.07), iron)
      ..drawOval(Rect.fromCenter(center: base - Offset(0, bh + 2), width: w * 0.1, height: h * 0.04), Paint()..color = const Color(0xFF455A64));
    // The eye, lifted clear above the bollard's head.
    final Rect eye = Rect.fromCenter(center: base - Offset(0, bh + h * 0.2), width: w * 0.16, height: h * 0.09);
    canvas
      ..drawOval(eye, _stroke(Palette.plankDark, 4.4))
      ..drawOval(eye, _stroke(Palette.rope, 3));
    // An arrow: up and off.
    final Paint arrow = _stroke(Colors.white, 2);
    final Offset a0 = base - Offset(w * 0.1, bh + h * 0.02);
    final Offset a1 = base - Offset(w * 0.1, bh + h * 0.28);
    canvas
      ..drawLine(a0, a1, arrow)
      ..drawLine(a1, a1 + Offset(-w * 0.02, h * 0.04), arrow)
      ..drawLine(a1, a1 + Offset(w * 0.02, h * 0.04), arrow);
    // The line runs from the eye out to the boat, slack now.
    final Offset bow = Offset(w * 0.74, quayTop + h * 0.02);
    _rope(canvas, eye.centerRight, bow, sag: h * 0.18);
    // The boat, bow in, moving off.
    final double y = quayTop + h * 0.08;
    final Path hull = Path()
      ..moveTo(w * 0.72, y - h * 0.08)
      ..lineTo(w * 1.02, y - h * 0.1)
      ..lineTo(w * 1.02, y + h * 0.08)
      ..lineTo(w * 0.78, y + h * 0.08)
      ..quadraticBezierTo(w * 0.72, y, w * 0.72, y - h * 0.08)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = Palette.hulls[2])
      ..drawRect(Rect.fromLTRB(w * 0.78, y - h * 0.08, w * 1.02, y - h * 0.065), Paint()..color = Palette.sail);
    // Water opening between the boat and the quay.
    final Paint gap = _stroke(Palette.foam.withValues(alpha: 0.7), 1.4);
    for (int i = 0; i < 3; i++) {
      final double x = w * (0.55 + i * 0.05);
      canvas.drawArc(Rect.fromLTWH(x, y + h * 0.1 + i * 3, w * 0.08, h * 0.05), math.pi * 1.1, math.pi * 0.8, false, gap);
    }
  }

  @override
  bool shouldRepaint(final _CastOffPainter oldDelegate) => false;
}

/// A small sailboat bearing away to give the channel to a big container ship
/// coming through.
class MakeWayArt extends StatelessWidget {
  const MakeWayArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _MakeWayPainter(), child: SizedBox.expand());
}

class _MakeWayPainter extends CustomPainter {
  const _MakeWayPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.42;
    Scenery.sky(canvas, size, horizon);
    Scenery.water(canvas, size, horizon);
    // The ship, side-on, steaming left through the channel.
    final double wl = h * 0.66;
    final Path hull = Path()
      ..moveTo(w * 0.08, wl - h * 0.12)
      ..lineTo(w * 0.86, wl - h * 0.12)
      ..lineTo(w * 0.84, wl + h * 0.05)
      ..lineTo(w * 0.14, wl + h * 0.05)
      ..quadraticBezierTo(w * 0.09, wl - h * 0.02, w * 0.08, wl - h * 0.12)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = const Color(0xFF263238))
      ..save()
      ..clipPath(hull)
      ..drawRect(Rect.fromLTRB(0, wl - h * 0.01, w, h), Paint()..color = _antifouling)
      ..restore();
    // Containers, stacked in colored rows.
    const List<Color> boxes = <Color>[Color(0xFFE2463A), Color(0xFF2F7CF6), Color(0xFFE9B949), Color(0xFF2E9E57), Color(0xFF8E24AA)];
    final math.Random random = math.Random(8);
    final double cw = w * 0.055;
    final double ch = h * 0.05;
    for (int col = 0; col < 10; col++) {
      final int stack = 2 + random.nextInt(2);
      for (int row = 0; row < stack; row++) {
        final Rect box = Rect.fromLTWH(w * 0.14 + col * cw, wl - h * 0.12 - (row + 1) * ch, cw - 1, ch - 1);
        canvas.drawRect(box, Paint()..color = boxes[random.nextInt(boxes.length)]);
      }
    }
    // The bridge aft.
    canvas
      ..drawRect(Rect.fromLTRB(w * 0.72, wl - h * 0.34, w * 0.82, wl - h * 0.12), Paint()..color = Palette.sail)
      ..drawRect(Rect.fromLTRB(w * 0.72, wl - h * 0.32, w * 0.82, wl - h * 0.29), Paint()..color = const Color(0xFF2F4858))
      ..drawRect(Rect.fromLTRB(w * 0.76, wl - h * 0.42, w * 0.79, wl - h * 0.34), Paint()..color = Palette.buoyRed);
    // The bow wave.
    canvas.drawArc(Rect.fromLTWH(w * 0.02, wl - h * 0.02, w * 0.14, h * 0.08), math.pi * 0.5, math.pi * 0.9, false, _stroke(Colors.white, 2));
    // The sailboat, small and heeling, in the foreground right, bearing off.
    final Offset s = Offset(w * 0.8, h * 0.88);
    final double sl = w * 0.12;
    canvas
      ..save()
      ..translate(s.dx, s.dy)
      ..rotate(0.18);
    final Path small = Path()
      ..moveTo(-sl / 2, -sl * 0.08)
      ..lineTo(sl / 2, -sl * 0.1)
      ..quadraticBezierTo(sl * 0.35, sl * 0.12, sl * 0.2, sl * 0.12)
      ..lineTo(-sl * 0.3, sl * 0.12)
      ..close();
    canvas
      ..drawPath(small, Paint()..color = Palette.sail)
      ..drawLine(Offset(0, -sl * 0.1), Offset(0, -sl * 0.95), _stroke(Palette.plankDark, 1.4))
      ..drawPath(
        Path()
          ..moveTo(sl * 0.02, -sl * 0.92)
          ..lineTo(sl * 0.4, -sl * 0.14)
          ..lineTo(sl * 0.02, -sl * 0.14)
          ..close(),
        Paint()..color = Colors.white,
      )
      ..drawPath(
        Path()
          ..moveTo(-sl * 0.02, -sl * 0.8)
          ..lineTo(-sl * 0.3, -sl * 0.14)
          ..lineTo(-sl * 0.02, -sl * 0.14)
          ..close(),
        Paint()..color = const Color(0xFFF2EEE3),
      )
      ..restore();
    // Its curving course, out of the ship's way.
    final Paint course = _stroke(Colors.white.withValues(alpha: 0.8), 1.4);
    final Path turn = Path()
      ..moveTo(w * 0.58, h * 0.8)
      ..quadraticBezierTo(w * 0.66, h * 0.98, w * 0.74, h * 0.92);
    canvas.drawPath(turn, course);
  }

  @override
  bool shouldRepaint(final _MakeWayPainter oldDelegate) => false;
}

/// A floating pontoon: a plank deck on cylindrical floats, held by guide piles
/// and tied to the quay.
class PontoonArt extends StatelessWidget {
  const PontoonArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _PontoonPainter(), child: SizedBox.expand());
}

class _PontoonPainter extends CustomPainter {
  const _PontoonPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.6;
    final double quayTop = h * 0.4;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, Size(w, h), waterline);
    Scenery.quayWall(canvas, Rect.fromLTRB(0, quayTop, w * 0.22, waterline + 2));
    // Cylindrical floats, seen end-on, half under water.
    final double deckTop = waterline - h * 0.1;
    final double deckBottom = waterline - h * 0.06;
    final double left = w * 0.3;
    final double right = w * 0.94;
    final double r = h * 0.07;
    for (double x = left + r * 1.3; x < right - r; x += r * 2.6) {
      final Offset c = Offset(x, waterline + r * 0.2);
      canvas
        ..drawCircle(c, r, Paint()..color = const Color(0xFFDADFE3))
        ..drawCircle(c, r * 0.72, _stroke(const Color(0xFFB0B7BD), 1.2))
        ..drawCircle(c, r * 0.2, Paint()..color = const Color(0xFF90A4AE));
    }
    // The water covers the lower part of the floats.
    canvas.drawRect(
      Rect.fromLTRB(left - 4, waterline + r * 0.35, right + 4, waterline + r * 1.4),
      Paint()..color = Palette.sea.withValues(alpha: 0.55),
    );
    // The frame and the plank deck on top.
    canvas
      ..drawRect(Rect.fromLTRB(left, deckBottom, right, waterline - r * 0.6), Paint()..color = const Color(0xFF546E7A))
      ..drawRect(Rect.fromLTRB(left, deckTop, right, deckBottom), Paint()..color = Palette.plank);
    for (double x = left; x < right; x += 8) {
      canvas.drawLine(Offset(x, deckTop), Offset(x, deckBottom), _stroke(Palette.plankDark.withValues(alpha: 0.5), 0.8));
    }
    canvas.drawRect(Rect.fromLTRB(left, deckTop, right, deckTop + 2), Paint()..color = Palette.plankLight);
    // Guide piles through hoops, so it rises and falls in place.
    for (final double x in <double>[left + w * 0.05, right - w * 0.05]) {
      Scenery.pile(canvas, Offset(x, h * 0.2), h, width: w * 0.024);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, deckTop + 2), width: w * 0.045, height: h * 0.035), _stroke(const Color(0xFF263238), 1.6));
    }
    // A cleat on the deck, tied to a bollard on the quay.
    final Offset cleat = Offset(left + w * 0.12, deckTop);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: cleat - const Offset(0, 2), width: w * 0.05, height: 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFF263238),
    );
    final Offset bollard = Offset(w * 0.14, quayTop);
    Scenery.bollard(canvas, bollard, h * 0.06);
    _rope(canvas, bollard - Offset(0, h * 0.05), cleat - const Offset(0, 3), sag: h * 0.05);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _PontoonPainter oldDelegate) => false;
}
