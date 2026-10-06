import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Brushes shared by the lighthouse plates.
abstract final class _Light {
  static const Color glow = Color(0xFFFFE08A);

  /// A night sea from [waterline] down, with moonlit wave lines.
  static void nightWater(final Canvas canvas, final Size size, final double waterline) {
    final Rect sea = Rect.fromLTWH(0, waterline, size.width, size.height - waterline);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF16385E), Palette.night],
        ).createShader(sea),
    );
    final Paint wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.18);
    for (int row = 1; row < 5; row++) {
      final double y = waterline + (size.height - waterline) * row / 5;
      final Path path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 6) {
        path.lineTo(x, y + math.sin(x / 12 + row) * 1.2);
      }
      canvas.drawPath(path, wave);
    }
  }

  /// A red-and-white banded tower from [base] up [height], [width] at its foot;
  /// returns where its lantern is.
  static Offset tower(final Canvas canvas, final Offset base, final double height, final double width, {final bool lit = true}) {
    final double topWidth = width * 0.62;
    final Path body = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..lineTo(base.dx - topWidth / 2, base.dy - height)
      ..lineTo(base.dx + topWidth / 2, base.dy - height)
      ..lineTo(base.dx + width / 2, base.dy)
      ..close();
    canvas
      ..save()
      ..clipPath(body)
      ..drawRect(body.getBounds(), Paint()..color = const Color(0xFFF5F5F5));
    for (int i = 0; i < 4; i += 2) {
      canvas.drawRect(
        Rect.fromLTRB(base.dx - width, base.dy - height * (i + 1) / 4, base.dx + width, base.dy - height * i / 4),
        Paint()..color = Palette.buoyRed,
      );
    }
    canvas.restore();
    // Gallery, lantern room, cupola.
    final double galleryY = base.dy - height;
    final Rect gallery = Rect.fromCenter(center: Offset(base.dx, galleryY), width: topWidth * 1.5, height: height * 0.04);
    final Rect lantern = Rect.fromLTRB(base.dx - topWidth * 0.4, galleryY - height * 0.15, base.dx + topWidth * 0.4, galleryY - gallery.height / 2);
    canvas
      ..drawRect(gallery, Paint()..color = const Color(0xFF263238))
      ..drawRect(lantern, Paint()..color = lit ? glow : const Color(0xFF546E7A))
      ..drawPath(
        Path()
          ..moveTo(lantern.left - 3, lantern.top)
          ..lineTo(base.dx, lantern.top - height * 0.08)
          ..lineTo(lantern.right + 3, lantern.top)
          ..close(),
        Paint()..color = const Color(0xFF263238),
      );
    for (int i = 1; i < 3; i++) {
      final double x = lantern.left + lantern.width * i / 3;
      canvas.drawLine(Offset(x, lantern.top), Offset(x, lantern.bottom), Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1);
    }
    return lantern.center;
  }

  /// A beam of light from [from] toward [to], spreading to [spread] wide.
  static void beam(final Canvas canvas, final Offset from, final Offset to, final double spread, {final double strength = 0.55}) {
    final Offset along = to - from;
    final Offset normal = Offset(-along.dy, along.dx) / along.distance * (spread / 2);
    final Path cone = Path()
      ..moveTo(from.dx, from.dy - 2)
      ..lineTo(to.dx + normal.dx, to.dy + normal.dy)
      ..lineTo(to.dx - normal.dx, to.dy - normal.dy)
      ..lineTo(from.dx, from.dy + 2)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(from.dx < to.dx ? -1 : 1, 0),
          end: Alignment(from.dx < to.dx ? 1 : -1, 0),
          colors: <Color>[glow.withValues(alpha: strength), glow.withValues(alpha: 0.04)],
        ).createShader(cone.getBounds()),
    );
  }

  /// Dark rocks along [y], from [left] to [right].
  static void rocks(final Canvas canvas, final double left, final double right, final double y, final int seed) {
    final math.Random random = math.Random(seed);
    for (double x = left; x < right; x += 8 + random.nextDouble() * 8) {
      final double r = 8 + random.nextDouble() * 8;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y + random.nextDouble() * 4), width: r * 2.2, height: r * 1.4), Paint()..color = Color.lerp(const Color(0xFF263238), const Color(0xFF37474F), random.nextDouble())!);
    }
  }

  /// A small boat's silhouette with a lit cabin.
  static void boat(final Canvas canvas, final Offset center, final double length, final Color hull) {
    final double depth = length * 0.16;
    final Path body = Path()
      ..moveTo(center.dx - length / 2, center.dy - depth)
      ..lineTo(center.dx + length / 2, center.dy - depth * 1.3)
      ..quadraticBezierTo(center.dx + length * 0.4, center.dy + depth * 0.5, center.dx + length * 0.25, center.dy + depth * 0.5)
      ..lineTo(center.dx - length * 0.38, center.dy + depth * 0.5)
      ..close();
    final Rect cabin = Rect.fromLTRB(center.dx - length * 0.22, center.dy - depth * 2.6, center.dx + length * 0.12, center.dy - depth);
    canvas
      ..drawRect(cabin, Paint()..color = const Color(0xFFF5F5F5))
      ..drawRect(Rect.fromLTWH(cabin.left + 3, cabin.top + 3, cabin.width * 0.5, cabin.height * 0.4), Paint()..color = const Color(0xFF263238))
      ..drawPath(body, Paint()..color = hull)
      ..drawLine(Offset(center.dx - length / 2, center.dy - depth), Offset(center.dx + length / 2, center.dy - depth * 1.3), Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6)
      ..drawLine(Offset(cabin.center.dx, cabin.top), Offset(cabin.center.dx, cabin.top - depth * 2), Paint()
        ..color = const Color(0xFF455A64)
        ..strokeWidth = 1.4);
  }
}

/// A lighthouse on its rocks at night, sweeping its beam out over the water
/// onto a boat, lit up so it can be seen.
class LighthouseBeamArt extends StatelessWidget {
  const LighthouseBeamArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _BeamPainter(), child: SizedBox.expand());
}

class _BeamPainter extends CustomPainter {
  const _BeamPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.66;
    Scenery.sky(canvas, size, waterline, night: true);
    _Light.nightWater(canvas, size, waterline);
    // The headland it stands on.
    final Path land = Path()
      ..moveTo(0, waterline + 6)
      ..lineTo(0, h * 0.5)
      ..quadraticBezierTo(w * 0.12, h * 0.44, w * 0.26, h * 0.56)
      ..lineTo(w * 0.32, waterline + 6)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF1E2B26));
    _Light.rocks(canvas, w * 0.02, w * 0.34, waterline + 2, 4);
    final Offset lantern = _Light.tower(canvas, Offset(w * 0.14, h * 0.5), h * 0.38, w * 0.07);
    // The boat it falls on, and the beam reaching it, with a faint back beam.
    final Offset boat = Offset(w * 0.76, waterline + h * 0.1);
    _Light.beam(canvas, lantern, Offset(w * 0.06, lantern.dy - h * 0.06), h * 0.12, strength: 0.25);
    _Light.beam(canvas, lantern, Offset(w * 0.98, boat.dy - h * 0.02), h * 0.34);
    canvas.drawCircle(lantern, h * 0.08, Paint()..color = _Light.glow.withValues(alpha: 0.4));
    _Light.boat(canvas, boat, w * 0.18, Palette.hulls[0]);
    // The light it catches, on the water round it.
    canvas.drawOval(Rect.fromCenter(center: boat + Offset(0, h * 0.05), width: w * 0.3, height: h * 0.06), Paint()..color = _Light.glow.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(final _BeamPainter oldDelegate) => false;
}

/// A harbor light seen across the water, half hidden behind a headland that
/// runs in front of it.
class HeadlandBeaconArt extends StatelessWidget {
  const HeadlandBeaconArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _HeadlandPainter(), child: SizedBox.expand());
}

class _HeadlandPainter extends CustomPainter {
  const _HeadlandPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.7;
    Scenery.sky(canvas, size, waterline, night: true);
    // Dusk glow on the horizon.
    final Rect dusk = Rect.fromLTWH(0, waterline - h * 0.2, w, h * 0.2);
    canvas.drawRect(
      dusk,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[const Color(0x00FF8A65), const Color(0xFFFF8A65).withValues(alpha: 0.35)],
        ).createShader(dusk),
    );
    _Light.nightWater(canvas, size, waterline);
    // The beacon on its island, behind.
    _Light.rocks(canvas, w * 0.5, w * 0.72, waterline + 2, 9);
    final Offset lantern = _Light.tower(canvas, Offset(w * 0.6, waterline), h * 0.5, w * 0.08);
    canvas
      ..drawCircle(lantern, h * 0.16, Paint()..color = _Light.glow.withValues(alpha: 0.18))
      ..drawCircle(lantern, h * 0.07, Paint()..color = _Light.glow.withValues(alpha: 0.45));
    _Light.beam(canvas, lantern, Offset(w, lantern.dy + h * 0.1), h * 0.2, strength: 0.35);
    // The headland in front, cutting off the lower half of the tower.
    final Path headland = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.38)
      ..quadraticBezierTo(w * 0.24, h * 0.34, w * 0.42, h * 0.48)
      ..quadraticBezierTo(w * 0.56, h * 0.56, w * 0.7, h * 0.62)
      ..quadraticBezierTo(w * 0.78, h * 0.68, w * 0.8, h)
      ..close();
    canvas.drawPath(headland, Paint()..color = const Color(0xFF15211C));
    // Trees on its ridge.
    final Paint tree = Paint()..color = const Color(0xFF0D1612);
    for (final double x in <double>[0.06, 0.12, 0.2, 0.3, 0.36]) {
      final double base = h * (0.37 + x * 0.12);
      canvas.drawPath(
        Path()
          ..moveTo(w * x - 8, base + 4)
          ..lineTo(w * x, base - 20)
          ..lineTo(w * x + 8, base + 4)
          ..close(),
        tree,
      );
    }
    // How much is hidden: the bracket and fraction a sailor would note.
    final Paint mark = Paint()
      ..color = _Light.glow.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    final double towerTop = waterline - h * 0.5 - h * 0.1;
    final double hiddenTop = h * 0.585;
    canvas
      ..drawLine(Offset(w * 0.68, towerTop), Offset(w * 0.68, waterline), mark..color = Colors.white38)
      ..drawLine(Offset(w * 0.68, hiddenTop), Offset(w * 0.68, waterline), mark..color = _Light.glow);
    final TextPainter label = TextPainter(
      text: const TextSpan(text: 'half hidden', style: TextStyle(color: _Light.glow, fontSize: 10, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(w * 0.7, (hiddenTop + waterline) / 2 - 6));
  }

  @override
  bool shouldRepaint(final _HeadlandPainter oldDelegate) => false;
}

/// A boat lift at the yard: a travel-lift gantry straddling the slip, its
/// slings raising a boat clear of the water.
class BoatLiftArt extends StatelessWidget {
  const BoatLiftArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _LiftPainter(), child: SizedBox.expand());
}

class _LiftPainter extends CustomPainter {
  const _LiftPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.84;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // The two concrete piers of the slip.
    final Rect leftPier = Rect.fromLTRB(0, waterline - h * 0.06, w * 0.2, h);
    final Rect rightPier = Rect.fromLTRB(w * 0.8, waterline - h * 0.06, w, h);
    for (final Rect pier in <Rect>[leftPier, rightPier]) {
      canvas
        ..drawRect(pier, Paint()..color = const Color(0xFF9EA4A8))
        ..drawRect(Rect.fromLTWH(pier.left, pier.top, pier.width, 3), Paint()..color = const Color(0xFFC5CACD));
    }
    // The gantry: two legs on wheels, one on each pier, and a beam across the top.
    const Color steel = Color(0xFF1565C0);
    final Paint frame = Paint()
      ..color = steel
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.square;
    final double beamY = h * 0.12;
    final double legL = w * 0.12;
    final double legR = w * 0.88;
    final double deck = leftPier.top;
    canvas
      ..drawLine(Offset(legL, deck - 8), Offset(legL, beamY), frame)
      ..drawLine(Offset(legR, deck - 8), Offset(legR, beamY), frame)
      ..drawLine(Offset(legL - 6, beamY), Offset(legR + 6, beamY), frame..strokeWidth = 9)
      ..drawLine(Offset(legL, beamY + 30), Offset(legL + 18, beamY + 4), frame..strokeWidth = 3)
      ..drawLine(Offset(legR, beamY + 30), Offset(legR - 18, beamY + 4), frame);
    for (final double x in <double>[legL, legR]) {
      canvas
        ..drawCircle(Offset(x - 7, deck - 6), 6, Paint()..color = const Color(0xFF212121))
        ..drawCircle(Offset(x + 7, deck - 6), 6, Paint()..color = const Color(0xFF212121))
        ..drawRect(Rect.fromCenter(center: Offset(x, deck - 12), width: 26, height: 6), Paint()..color = const Color(0xFF0D47A1));
    }
    // The boat, raised clear of the water.
    final Offset hull = Offset(w * 0.5, h * 0.55);
    final double length = w * 0.5;
    final double depth = h * 0.14;
    final Path boat = Path()
      ..moveTo(hull.dx - length / 2, hull.dy - depth * 0.5)
      ..lineTo(hull.dx + length / 2, hull.dy - depth * 0.7)
      ..quadraticBezierTo(hull.dx + length * 0.42, hull.dy + depth * 0.4, hull.dx + length * 0.2, hull.dy + depth * 0.5)
      ..lineTo(hull.dx - length * 0.38, hull.dy + depth * 0.5)
      ..quadraticBezierTo(hull.dx - length * 0.48, hull.dy + depth * 0.2, hull.dx - length / 2, hull.dy - depth * 0.5)
      ..close();
    final Rect cabin = Rect.fromLTRB(hull.dx - length * 0.2, hull.dy - depth * 1.3, hull.dx + length * 0.14, hull.dy - depth * 0.6);
    canvas
      ..drawRect(cabin, Paint()..color = Colors.white)
      ..drawRect(Rect.fromLTWH(cabin.left + 4, cabin.top + 4, cabin.width * 0.6, cabin.height * 0.4), Paint()..color = const Color(0xFF263238))
      ..drawPath(boat, Paint()..color = Palette.hulls[3])
      ..drawPath(
        Path()
          ..moveTo(hull.dx - length * 0.42, hull.dy + depth * 0.25)
          ..lineTo(hull.dx + length * 0.36, hull.dy + depth * 0.15)
          ..lineTo(hull.dx + length * 0.24, hull.dy + depth * 0.5)
          ..lineTo(hull.dx - length * 0.38, hull.dy + depth * 0.5)
          ..close(),
        Paint()..color = const Color(0xFF8E2A22),
      );
    // The slings: from the beam's hoists down and under the hull.
    final Paint sling = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 1.6;
    final Paint strap = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final double t in <double>[-0.26, 0.24]) {
      final double x = hull.dx + length * t;
      canvas
        ..drawRect(Rect.fromCenter(center: Offset(x, beamY + 8), width: 12, height: 10), Paint()..color = const Color(0xFF424242))
        ..drawLine(Offset(x - 3, beamY + 12), Offset(x - length * 0.16, hull.dy - depth * 0.4), sling)
        ..drawLine(Offset(x + 3, beamY + 12), Offset(x + length * 0.16, hull.dy - depth * 0.4), sling)
        ..drawLine(Offset(x - length * 0.16, hull.dy - depth * 0.4), Offset(x - length * 0.1, hull.dy + depth * 0.55), strap)
        ..drawLine(Offset(x - length * 0.1, hull.dy + depth * 0.55), Offset(x + length * 0.1, hull.dy + depth * 0.55), strap)
        ..drawLine(Offset(x + length * 0.1, hull.dy + depth * 0.55), Offset(x + length * 0.16, hull.dy - depth * 0.4), strap);
    }
    // Water streaming off the keel, and the gap of air under it.
    final Paint drip = Paint()..color = Palette.foam.withValues(alpha: 0.85);
    final math.Random random = math.Random(2);
    for (int i = 0; i < 14; i++) {
      final double x = hull.dx - length * 0.3 + random.nextDouble() * length * 0.5;
      final double y = hull.dy + depth * 0.6 + random.nextDouble() * (waterline - hull.dy - depth * 0.6);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 2, height: 4), drip);
    }
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _LiftPainter oldDelegate) => false;
}
