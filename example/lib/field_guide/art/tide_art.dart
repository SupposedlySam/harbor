import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Brushes only the tide plates use.
abstract final class _Tide {
  static const Color weed = Color(0xFF4E6B3A);
  static const Color barnacle = Color(0xFF3B3F36);
  static const Color steel = Color(0xFF37474F);
  static const Color steelLight = Color(0xFF546E7A);
  static const Color earth = Color(0xFF7A6248);

  /// A tide staff: a board with black and white bands and a number every
  /// other band, standing from [top] to [bottom] at [x].
  static void staff(
    final Canvas canvas,
    final double x,
    final double top,
    final double bottom, {
    required final double width,
  }) {
    final Rect board = Rect.fromLTRB(x - width / 2, top, x + width / 2, bottom);
    canvas.drawRect(board.inflate(1.2), Paint()..color = Colors.black87);
    canvas.drawRect(board, Paint()..color = Colors.white);
    final double band = (bottom - top) / 12;
    for (int i = 0; i < 12; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(board.left, top + i * band, width * 0.55, band), Paint()..color = Colors.black87);
      }
      if (i.isOdd) {
        final TextPainter mark = TextPainter(
          text: TextSpan(
            text: '${(12 - i) ~/ 2}',
            style: TextStyle(color: Palette.buoyRed, fontSize: band * 0.95, fontWeight: FontWeight.w800),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        mark.paint(canvas, Offset(board.left + width * 0.6, top + i * band - band * 0.1));
      }
    }
  }

  /// A short straight arrow from [from] to [to], with a head at [to].
  static void arrow(
    final Canvas canvas,
    final Offset from,
    final Offset to,
    final Color color, {
    final bool both = false,
  }) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
    void head(final Offset tip, final Offset tail) {
      final Offset d = (tip - tail) / (tip - tail).distance;
      final Offset n = Offset(-d.dy, d.dx);
      final Path path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - d.dx * 6 + n.dx * 4, tip.dy - d.dy * 6 + n.dy * 4)
        ..lineTo(tip.dx - d.dx * 6 - n.dx * 4, tip.dy - d.dy * 6 - n.dy * 4)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    head(to, from);
    if (both) {
      head(from, to);
    }
  }

  /// A dashed horizontal line from [x0] to [x1] at [y].
  static void dashed(final Canvas canvas, final double x0, final double x1, final double y, final Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    for (double x = x0; x < x1; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4.5, x1), y), paint);
    }
  }

  static void label(
    final Canvas canvas,
    final String text,
    final Offset at, {
    final Color color = Colors.white,
    final double size = 8,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w800, letterSpacing: 0.6),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  /// A plank deck from [left] to [right] between [top] and [bottom].
  static void deck(final Canvas canvas, final double left, final double right, final double top, final double bottom) {
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), Paint()..color = Palette.plank);
    final Paint seam = Paint()..color = Palette.plankDark.withValues(alpha: 0.5);
    for (double x = left; x < right; x += 7) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), seam);
    }
    canvas.drawRect(Rect.fromLTRB(left, top, right, top + 2.5), Paint()..color = Palette.plankLight);
  }

  /// A side-on ship's hull from [left] to [right], keel at [keel], deck at [deckY].
  static void ship(final Canvas canvas, final double left, final double right, final double deckY, final double keel) {
    final double length = right - left;
    final double depth = keel - deckY;
    final Path hull = Path()
      ..moveTo(left, deckY)
      ..lineTo(right, deckY - depth * 0.12)
      ..quadraticBezierTo(right - length * 0.04, keel - depth * 0.2, right - length * 0.14, keel)
      ..lineTo(left + length * 0.12, keel)
      ..quadraticBezierTo(left + length * 0.02, keel - depth * 0.1, left, deckY)
      ..close();
    canvas
      ..save()
      ..clipPath(hull)
      ..drawRect(Rect.fromLTRB(left, deckY - depth, right, keel), Paint()..color = const Color(0xFF1F2A33))
      // Antifouling red below the boot-top.
      ..drawRect(Rect.fromLTRB(left, deckY + depth * 0.45, right, keel), Paint()..color = const Color(0xFFB23A2E))
      ..drawRect(Rect.fromLTRB(left, deckY + depth * 0.4, right, deckY + depth * 0.47), Paint()..color = Colors.white70)
      ..restore();
    // Superstructure, funnel and mast.
    canvas
      ..drawRect(
        Rect.fromLTRB(left + length * 0.55, deckY - depth * 0.55, left + length * 0.8, deckY),
        Paint()..color = Palette.sail,
      )
      ..drawRect(
        Rect.fromLTRB(left + length * 0.58, deckY - depth * 0.45, left + length * 0.77, deckY - depth * 0.35),
        Paint()..color = const Color(0xFF263238),
      )
      ..drawRect(
        Rect.fromLTRB(left + length * 0.62, deckY - depth * 0.95, left + length * 0.7, deckY - depth * 0.55),
        Paint()..color = Palette.buoyRed,
      )
      ..drawLine(
        Offset(left + length * 0.25, deckY),
        Offset(left + length * 0.25, deckY - depth * 1.1),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 2,
      );
  }
}

/// A harbor tide clock on a post at the quay's edge, and a tide staff
/// standing in the water beside it.
class HarborTideArt extends StatelessWidget {
  const HarborTideArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _TideClockPainter(), child: SizedBox.expand());
}

class _TideClockPainter extends CustomPainter {
  const _TideClockPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.66;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // The quay the clock stands on.
    final double quayTop = h * 0.56;
    Scenery.quayWall(canvas, Rect.fromLTRB(0, quayTop, w * 0.46, h));
    // The post and the clock on it.
    final Offset center = Offset(w * 0.22, h * 0.28);
    final double r = h * 0.19;
    canvas
      ..drawRect(
        Rect.fromLTRB(center.dx - 3.5, center.dy, center.dx + 3.5, quayTop),
        Paint()..color = const Color(0xFF2E4B3A),
      )
      ..drawRect(
        Rect.fromLTRB(center.dx - 7, quayTop - 6, center.dx + 7, quayTop),
        Paint()..color = const Color(0xFF2E4B3A),
      )
      ..drawCircle(center, r + 4, Paint()..color = const Color(0xFF2E4B3A))
      ..drawCircle(center, r + 1.5, Paint()..color = Palette.brass)
      ..drawCircle(center, r, Paint()..color = Palette.sail);
    // Hour ticks: high water at the top, low water at the bottom.
    for (int i = 0; i < 12; i++) {
      final double a = i * math.pi / 6;
      final Offset d = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        center + d * (r * 0.82),
        center + d * (r * 0.95),
        Paint()
          ..color = Palette.plankDark
          ..strokeWidth = i % 3 == 0 ? 2 : 1,
      );
    }
    _Tide.label(canvas, 'HIGH', center - Offset(0, r * 0.55), color: Palette.sea, size: r * 0.24);
    _Tide.label(canvas, 'LOW', center + Offset(0, r * 0.55), color: Palette.sea, size: r * 0.24);
    _Tide.label(canvas, 'TIDE', center + Offset(r * 0.42, 0), color: Palette.buoyRed, size: r * 0.16);
    // The hand: two hours after high water, falling.
    const double handAngle = math.pi / 3;
    final Offset tip = center + Offset(math.sin(handAngle), -math.cos(handAngle)) * (r * 0.78);
    canvas
      ..drawLine(
        center,
        tip,
        Paint()
          ..color = Palette.night
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(center, 3, Paint()..color = Palette.buoyRed);
    // The tide staff on its pile, half under water.
    final double staffX = w * 0.68;
    Scenery.pile(canvas, Offset(staffX + w * 0.035, h * 0.18), h, width: w * 0.024);
    _Tide.staff(canvas, staffX, h * 0.2, h * 0.96, width: w * 0.05);
    canvas.drawRect(
      Rect.fromLTRB(staffX - w * 0.04, waterline, staffX + w * 0.06, h),
      Paint()..color = Palette.shallows.withValues(alpha: 0.6),
    );
    // A gull's eye view: the height the water stands at.
    _Tide.arrow(canvas, Offset(w * 0.86, waterline + h * 0.2), Offset(w * 0.86, waterline + 3), Palette.foam);
    _Tide.label(canvas, 'height', Offset(w * 0.86, waterline + h * 0.26), color: Palette.foam, size: 9);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _TideClockPainter oldDelegate) => false;
}

/// A floating dock: a pontoon on air drums, held to two tall guide piles by
/// hoops so it slides up and down them with the tide, a hinged gangway to the
/// shore.
class FloatingDockArt extends StatelessWidget {
  const FloatingDockArt({super.key});

  @override
  Widget build(final BuildContext context) =>
      const CustomPaint(painter: _FloatingDockPainter(), child: SizedBox.expand());
}

class _FloatingDockPainter extends CustomPainter {
  const _FloatingDockPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.6;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    Scenery.shore(canvas, size, waterline, fromLeft: true, width: w * 0.24);
    final double pileWidth = w * 0.026;
    final List<double> piles = <double>[w * 0.5, w * 0.82];
    // The guide piles, behind the pontoon.
    for (final double x in piles) {
      Scenery.pile(canvas, Offset(x, h * 0.12), h, width: pileWidth);
      canvas.drawCircle(Offset(x, h * 0.12), pileWidth * 0.6, Paint()..color = Palette.plankDark);
    }
    // The pontoon, floating: drums half under, deck just above the water.
    final double left = w * 0.38;
    final double right = w * 0.93;
    final double deckTop = waterline - h * 0.06;
    final double deckBottom = waterline - h * 0.015;
    for (double x = left + 8; x < right - 8; x += w * 0.09) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, deckBottom, w * 0.07, h * 0.05), const Radius.circular(4)),
        Paint()..color = const Color(0xFF263238),
      );
    }
    _Tide.deck(canvas, left, right, deckTop, deckBottom);
    // Hoops around each pile, so the pontoon slides on them.
    for (final double x in piles) {
      canvas.drawRect(
        Rect.fromLTRB(x - pileWidth, deckTop - 4, x + pileWidth, deckBottom + 2),
        Paint()
          ..color = const Color(0xFF263238)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      Scenery.pile(canvas, Offset(x, h * 0.12), deckTop - 4, width: pileWidth);
    }
    // The gangway, hinged on the shore, resting on the pontoon.
    final Offset hinge = Offset(w * 0.2, waterline - h * 0.14);
    final Offset foot = Offset(left + w * 0.04, deckTop);
    canvas
      ..drawLine(
        hinge,
        foot,
        Paint()
          ..color = Palette.plankDark
          ..strokeWidth = 4,
      )
      ..drawLine(
        hinge - const Offset(0, 9),
        foot - const Offset(0, 9),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 1.4,
      );
    // It rides the tide.
    _Tide.arrow(
      canvas,
      Offset(w * 0.66, deckTop - h * 0.3),
      Offset(w * 0.66, deckTop - h * 0.06),
      Palette.night,
      both: true,
    );
    Scenery.bollard(canvas, Offset(w * 0.88, deckTop), h * 0.05);
    Scenery.rowboat(canvas, Offset(w * 0.7, waterline + h * 0.12), w * 0.16, Palette.buoyRed);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _FloatingDockPainter oldDelegate) => false;
}

/// A fixed pier high on tall pilings: the water stands partway up the piles,
/// with weed and barnacles marking where high water reaches.
class PilingsArt extends StatelessWidget {
  const PilingsArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _PilingsPainter(), child: SizedBox.expand());
}

class _PilingsPainter extends CustomPainter {
  const _PilingsPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.7;
    final double highWater = h * 0.5;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    Scenery.shore(canvas, size, waterline, fromLeft: true, width: w * 0.16);
    final double deckTop = h * 0.26;
    final double deckBottom = h * 0.33;
    final double pileWidth = w * 0.024;
    final List<double> piles = <double>[for (double x = w * 0.2; x <= w * 0.92; x += w * 0.12) x];
    for (final double x in piles) {
      Scenery.pile(canvas, Offset(x, deckBottom), h, width: pileWidth);
      // Barnacles and weed between high and low water.
      canvas
        ..drawRect(
          Rect.fromLTRB(x - pileWidth / 2, highWater, x + pileWidth / 2, waterline),
          Paint()..color = _Tide.barnacle,
        )
        ..drawRect(
          Rect.fromLTRB(x - pileWidth / 2, highWater, x + pileWidth / 2, highWater + h * 0.04),
          Paint()..color = _Tide.weed,
        );
    }
    // Bracing high above the water.
    final Paint brace = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 1.6;
    for (int i = 0; i < piles.length - 1; i++) {
      canvas
        ..drawLine(Offset(piles[i], deckBottom + 2), Offset(piles[i + 1], highWater - 4), brace)
        ..drawLine(Offset(piles[i + 1], deckBottom + 2), Offset(piles[i], highWater - 4), brace);
    }
    _Tide.deck(canvas, w * 0.1, w * 0.96, deckTop, deckBottom);
    // Rails and a ladder down to the water.
    final Paint rail = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(w * 0.1, deckTop - h * 0.08), Offset(w * 0.96, deckTop - h * 0.08), rail);
    for (double x = w * 0.1; x <= w * 0.96; x += w * 0.08) {
      canvas.drawLine(Offset(x, deckTop), Offset(x, deckTop - h * 0.08), rail);
    }
    final double ladder = w * 0.62;
    final Paint iron = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 1.4;
    canvas
      ..drawLine(Offset(ladder - 5, deckBottom), Offset(ladder - 5, h), iron)
      ..drawLine(Offset(ladder + 5, deckBottom), Offset(ladder + 5, h), iron);
    for (double y = deckBottom + 6; y < h; y += 7) {
      canvas.drawLine(Offset(ladder - 5, y), Offset(ladder + 5, y), iron);
    }
    // The high-water mark, and the deck that stays put above it.
    _Tide.dashed(canvas, w * 0.14, w, highWater, Colors.white);
    _Tide.label(canvas, 'HW', Offset(w * 0.12, highWater), color: Colors.white, size: 9);
    Scenery.lamp(canvas, Offset(w * 0.92, deckTop), h * 0.2, lit: false);
    Scenery.rowboat(canvas, Offset(w * 0.4, waterline + h * 0.05), w * 0.15, Palette.hulls[1]);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _PilingsPainter oldDelegate) => false;
}

/// A floating pontoon moored beside a fixed pier: at high tide the pontoon
/// has ridden up the guide piles while the pier deck stays where it was
/// built. The dashed outline is where the pontoon sat at low water.
class FloatAndPilingsArt extends StatelessWidget {
  const FloatAndPilingsArt({super.key});

  @override
  Widget build(final BuildContext context) =>
      const CustomPaint(painter: _FloatAndPilingsPainter(), child: SizedBox.expand());
}

class _FloatAndPilingsPainter extends CustomPainter {
  const _FloatAndPilingsPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.5;
    final double lowWater = h * 0.82;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    final double pileWidth = w * 0.024;
    // The fixed pier: its deck is near the water now, the tide is in.
    final double pierTop = h * 0.4;
    final double pierBottom = h * 0.47;
    for (double x = w * 0.08; x <= w * 0.46; x += w * 0.095) {
      Scenery.pile(canvas, Offset(x, pierBottom), h, width: pileWidth);
    }
    _Tide.deck(canvas, w * 0.02, w * 0.5, pierTop, pierBottom);
    Scenery.lamp(canvas, Offset(w * 0.46, pierTop), h * 0.18, lit: true);
    // Where the pontoon floated at low water.
    final double left = w * 0.54;
    final double right = w * 0.96;
    final double lowTop = lowWater - h * 0.06;
    final Paint ghost = Paint()
      ..color = Palette.foam.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Path outline = Path()..addRect(Rect.fromLTRB(left, lowTop, right, lowWater));
    for (final metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 4.5, metric.length)), ghost);
      }
    }
    _Tide.dashed(canvas, w * 0.5, w, lowWater, Palette.foam.withValues(alpha: 0.7));
    _Tide.label(canvas, 'LW', Offset(w * 0.52, lowWater - 6), color: Palette.foam, size: 8);
    // The guide piles and the pontoon riding high on them.
    final List<double> piles = <double>[w * 0.62, w * 0.88];
    for (final double x in piles) {
      Scenery.pile(canvas, Offset(x, h * 0.1), h, width: pileWidth);
    }
    final double deckTop = waterline - h * 0.06;
    final double deckBottom = waterline - h * 0.015;
    _Tide.deck(canvas, left, right, deckTop, deckBottom);
    for (final double x in piles) {
      canvas.drawRect(
        Rect.fromLTRB(x - pileWidth, deckTop - 4, x + pileWidth, deckBottom + 2),
        Paint()
          ..color = const Color(0xFF263238)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      Scenery.pile(canvas, Offset(x, h * 0.1), deckTop - 4, width: pileWidth);
    }
    _Tide.arrow(canvas, Offset(w * 0.75, lowTop - 4), Offset(w * 0.75, deckBottom + 6), Palette.brass);
    Scenery.bollard(canvas, Offset(w * 0.92, deckTop), h * 0.05);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _FloatAndPilingsPainter oldDelegate) => false;
}

/// A graving dry dock in cross-section: a stone basin with stepped sides, a
/// ship sitting on keel blocks and propped with shores, and the caisson gate
/// holding the sea out.
class DryDockArt extends StatelessWidget {
  const DryDockArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _DryDockPainter(), child: SizedBox.expand());
}

class _DryDockPainter extends CustomPainter {
  const _DryDockPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double ground = h * 0.36;
    final double floor = h * 0.9;
    final double gateLeft = w * 0.74;
    final double gateRight = w * 0.79;
    final double sea = h * 0.48;
    Scenery.sky(canvas, size, ground);
    // The ground around the basin.
    canvas.drawRect(Rect.fromLTRB(0, ground, w, h), Paint()..color = _Tide.earth);
    // The sea beyond the gate, standing higher than the dock's floor.
    Scenery.water(canvas, Size(w, h), sea);
    canvas.drawRect(Rect.fromLTRB(0, sea - 1, gateRight, h), Paint()..color = _Tide.earth);
    // The basin: stepped stone sides (altars) down to the floor.
    final Path basin = Path()..moveTo(w * 0.04, ground);
    const int steps = 4;
    for (int i = 0; i < steps; i++) {
      final double y = ground + (floor - ground) * (i + 1) / steps;
      final double x = w * 0.04 + w * 0.025 * (i + 1);
      basin
        ..lineTo(x - w * 0.025, y)
        ..lineTo(x, y);
    }
    basin
      ..lineTo(gateLeft, floor)
      ..lineTo(gateLeft, ground)
      ..close();
    canvas
      ..save()
      ..clipPath(basin);
    Scenery.quayWall(canvas, Rect.fromLTRB(0, ground, gateLeft, h));
    canvas
      ..drawRect(Rect.fromLTRB(w * 0.14, ground, gateLeft, floor), Paint()..color = const Color(0xFFCFD3D6))
      ..restore()
      ..drawRect(Rect.fromLTRB(w * 0.04, floor, gateLeft, floor + 4), Paint()..color = Palette.stoneDark);
    // Keel blocks on the floor, and the ship on them.
    final double blockTop = floor - h * 0.06;
    for (double x = w * 0.22; x < w * 0.64; x += w * 0.06) {
      for (int layer = 0; layer < 3; layer++) {
        final double y = floor - (layer + 1) * h * 0.02;
        canvas.drawRect(
          Rect.fromLTWH(x, y, w * 0.035, h * 0.02 - 0.8),
          Paint()..color = layer == 2 ? Palette.plankLight : Palette.plank,
        );
      }
    }
    _Tide.ship(canvas, w * 0.16, w * 0.7, ground + h * 0.02, blockTop);
    // Shores: timber props from the altars to the hull.
    final Paint shore = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 2.2;
    canvas
      ..drawLine(Offset(w * 0.115, ground + (floor - ground) * 0.5), Offset(w * 0.2, blockTop - h * 0.12), shore)
      ..drawLine(Offset(w * 0.09, ground + (floor - ground) * 0.25), Offset(w * 0.18, ground + h * 0.12), shore);
    // The caisson gate: riveted steel holding the water out.
    final Rect gate = Rect.fromLTRB(gateLeft, ground - h * 0.03, gateRight, floor + 4);
    canvas.drawRect(gate, Paint()..color = _Tide.steel);
    canvas.drawRect(Rect.fromLTRB(gate.left, gate.top, gate.right, gate.top + 3), Paint()..color = _Tide.steelLight);
    for (double y = gate.top + 8; y < gate.bottom - 4; y += 9) {
      canvas
        ..drawCircle(Offset(gate.left + 3, y), 1, Paint()..color = _Tide.steelLight)
        ..drawCircle(Offset(gate.right - 3, y), 1, Paint()..color = _Tide.steelLight);
    }
    // Sea-side quay beyond the gate.
    canvas.drawRect(Rect.fromLTRB(gateRight, ground, w, sea), Paint()..color = Palette.stone);
    canvas.drawRect(Rect.fromLTRB(gateRight, ground, w, ground + 3), Paint()..color = const Color(0xFFB0B7BD));
    canvas.drawRect(
      Rect.fromLTRB(gateRight, sea, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Palette.sea],
        ).createShader(Rect.fromLTRB(gateRight, sea, w, h)),
    );
    _Tide.arrow(canvas, Offset(w * 0.93, sea + h * 0.2), Offset(gateRight + 4, sea + h * 0.2), Palette.foam);
    Scenery.ripples(canvas, Size(w, h), sea);
    // A crane on the quay.
    final Paint crane = Paint()
      ..color = Palette.brass
      ..strokeWidth = 2.2;
    canvas
      ..drawLine(Offset(w * 0.05, ground), Offset(w * 0.05, h * 0.08), crane)
      ..drawLine(Offset(w * 0.05, h * 0.08), Offset(w * 0.3, h * 0.08), crane)
      ..drawLine(Offset(w * 0.05, h * 0.18), Offset(w * 0.12, h * 0.08), crane)
      ..drawLine(
        Offset(w * 0.27, h * 0.08),
        Offset(w * 0.27, h * 0.17),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(final _DryDockPainter oldDelegate) => false;
}

/// A seawall: a promenade on top, a curved stone wave wall, high and low
/// water marked on its face, and the sea breaking against it.
class SeawallArt extends StatelessWidget {
  const SeawallArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SeawallPainter(), child: SizedBox.expand());
}

class _SeawallPainter extends CustomPainter {
  const _SeawallPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double top = h * 0.4;
    final double waterline = h * 0.62;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // The wall: flat promenade, then a recurved face down into the sea.
    final Path wall = Path()
      ..moveTo(0, top)
      ..lineTo(w * 0.56, top)
      ..quadraticBezierTo(w * 0.6, top + h * 0.02, w * 0.6, top + h * 0.08)
      ..quadraticBezierTo(w * 0.54, top + h * 0.2, w * 0.6, h)
      ..lineTo(0, h)
      ..close();
    canvas
      ..save()
      ..clipPath(wall);
    Scenery.quayWall(canvas, Rect.fromLTRB(0, top, w * 0.62, h));
    canvas
      ..drawRect(Rect.fromLTRB(0, top, w * 0.62, top + h * 0.035), Paint()..color = const Color(0xFFC9C1AE))
      ..restore();
    // High and low water on the wall's face.
    _Tide.dashed(canvas, w * 0.3, w * 0.58, h * 0.52, Colors.white);
    _Tide.label(canvas, 'HW', Offset(w * 0.26, h * 0.52), size: 8);
    _Tide.dashed(canvas, w * 0.3, w * 0.6, h * 0.8, Colors.white70);
    _Tide.label(canvas, 'LW', Offset(w * 0.26, h * 0.8), size: 8, color: Colors.white70);
    // Railings and a lamp on the promenade.
    final Paint rail = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(w * 0.04, top - h * 0.07), Offset(w * 0.56, top - h * 0.07), rail);
    for (double x = w * 0.04; x <= w * 0.56; x += w * 0.04) {
      canvas.drawLine(Offset(x, top), Offset(x, top - h * 0.07), rail);
    }
    Scenery.lamp(canvas, Offset(w * 0.18, top), h * 0.26, lit: false);
    Scenery.bollard(canvas, Offset(w * 0.45, top), h * 0.04);
    // A wave breaking against the wall.
    final Paint foam = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(
        Rect.fromCircle(center: Offset(w * 0.64, waterline - h * 0.04), radius: h * 0.08),
        math.pi * 0.9,
        math.pi * 0.8,
        false,
        foam,
      )
      ..drawArc(
        Rect.fromCircle(center: Offset(w * 0.66, waterline - h * 0.1), radius: h * 0.06),
        math.pi * 1.0,
        math.pi * 0.7,
        false,
        foam,
      );
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(w * 0.6 + i * 5.0, waterline - h * 0.17 - (i.isEven ? 4 : 0)),
        1.6,
        Paint()..color = Colors.white,
      );
    }
    for (double x = w * 0.7; x < w; x += w * 0.1) {
      canvas.drawArc(
        Rect.fromLTWH(x, waterline - 4, w * 0.07, 8),
        math.pi,
        math.pi * 0.9,
        false,
        foam..strokeWidth = 1.4,
      );
    }
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _SeawallPainter oldDelegate) => false;
}

/// A slipway: a ramp into the water with rails, a boat hauled out on its
/// cradle by the winch house's cable before the tide comes up the ramp.
class SlipwayArt extends StatelessWidget {
  const SlipwayArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SlipwayPainter(), child: SizedBox.expand());
}

class _SlipwayPainter extends CustomPainter {
  const _SlipwayPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.7;
    Scenery.sky(canvas, size, h * 0.55);
    // The shore slopes down into the sea.
    final Path land = Path()
      ..moveTo(0, h * 0.4)
      ..lineTo(w * 0.22, h * 0.42)
      ..lineTo(w, h * 0.96)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawRect(Rect.fromLTRB(0, h * 0.55, w, h), Paint()..color = Palette.sea);
    Scenery.water(canvas, size, waterline);
    canvas.drawPath(land, Paint()..color = const Color(0xFFD9C38E));
    // The ramp and its rails.
    final Offset rampTop = Offset(w * 0.18, h * 0.44);
    final Offset rampEnd = Offset(w * 0.98, h * 0.98);
    final Paint concrete = Paint()
      ..color = const Color(0xFFB8B4AA)
      ..strokeWidth = h * 0.06;
    canvas.drawLine(rampTop, rampEnd, concrete);
    final Paint rail = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.6;
    canvas
      ..drawLine(rampTop - Offset(0, h * 0.018), rampEnd - Offset(0, h * 0.018), rail)
      ..drawLine(rampTop + Offset(0, h * 0.012), rampEnd + Offset(0, h * 0.012), rail);
    // The sea covers the lower end of the ramp.
    canvas.drawRect(Rect.fromLTRB(w * 0.5, waterline, w, h), Paint()..color = Palette.shallows.withValues(alpha: 0.55));
    _Tide.dashed(canvas, w * 0.45, w, h * 0.6, Colors.white);
    _Tide.label(canvas, 'HW', Offset(w * 0.42, h * 0.6), size: 8);
    _Tide.arrow(canvas, Offset(w * 0.9, waterline - 2), Offset(w * 0.9, h * 0.62), Colors.white);
    // The winch house at the head of the slip.
    canvas
      ..drawRect(Rect.fromLTRB(w * 0.02, h * 0.24, w * 0.16, h * 0.41), Paint()..color = const Color(0xFF8D6E63))
      ..drawPath(
        Path()
          ..moveTo(w * 0.0, h * 0.25)
          ..lineTo(w * 0.09, h * 0.15)
          ..lineTo(w * 0.18, h * 0.25)
          ..close(),
        Paint()..color = Palette.buoyRed,
      )
      ..drawRect(Rect.fromLTRB(w * 0.07, h * 0.31, w * 0.11, h * 0.41), Paint()..color = Palette.plankDark);
    // The cradle on the ramp and the boat hauled out on it.
    final Offset cradle = Offset.lerp(rampTop, rampEnd, 0.3)!;
    final double angle = math.atan2(rampEnd.dy - rampTop.dy, rampEnd.dx - rampTop.dx);
    canvas.drawLine(
      Offset(w * 0.16, h * 0.38),
      cradle - Offset(w * 0.08, 0),
      Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1,
    );
    canvas
      ..save()
      ..translate(cradle.dx, cradle.dy)
      ..rotate(angle);
    canvas
      ..drawRect(Rect.fromLTRB(-w * 0.1, -h * 0.05, w * 0.1, -h * 0.02), Paint()..color = const Color(0xFF455A64))
      ..drawCircle(Offset(-w * 0.07, -h * 0.015), 2.5, Paint()..color = Colors.black87)
      ..drawCircle(Offset(w * 0.07, -h * 0.015), 2.5, Paint()..color = Colors.black87);
    final Path hull = Path()
      ..moveTo(-w * 0.15, -h * 0.2)
      ..lineTo(w * 0.15, -h * 0.2)
      ..quadraticBezierTo(w * 0.12, -h * 0.07, w * 0.05, -h * 0.05)
      ..lineTo(-w * 0.08, -h * 0.05)
      ..quadraticBezierTo(-w * 0.14, -h * 0.08, -w * 0.15, -h * 0.2)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = Palette.hulls[2])
      ..drawRect(Rect.fromLTRB(-w * 0.15, -h * 0.2, w * 0.15, -h * 0.18), Paint()..color = Palette.sail)
      ..drawLine(
        Offset(-w * 0.01, -h * 0.2),
        Offset(-w * 0.01, -h * 0.55),
        Paint()
          ..color = Palette.plankDark
          ..strokeWidth = 1.8,
      )
      ..restore();
    Scenery.rowboat(canvas, Offset(w * 0.08, h * 0.47), w * 0.11, Palette.hulls[0]);
    Scenery.ripples(canvas, Size(w, h), waterline);
  }

  @override
  bool shouldRepaint(final _SlipwayPainter oldDelegate) => false;
}

/// A canal lock seen from the side: the gate holds high water on one side
/// and low water on the other, with its balance beam up on the lock side
/// and a boat waiting below.
class LockGateArt extends StatelessWidget {
  const LockGateArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _LockGatePainter(), child: SizedBox.expand());
}

class _LockGatePainter extends CustomPainter {
  const _LockGatePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double copingTop = h * 0.34;
    final double high = h * 0.44;
    final double low = h * 0.7;
    final double gateX = w * 0.48;
    Scenery.sky(canvas, size, copingTop);
    // The lock walls behind the water.
    Scenery.quayWall(canvas, Rect.fromLTRB(0, copingTop, w, h));
    void sea(final double left, final double right, final double top) {
      final Rect r = Rect.fromLTRB(left, top, right, h);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Palette.shallows.withValues(alpha: 0.92), Palette.sea],
          ).createShader(r),
      );
      Scenery.ripples(canvas, Size(right, h), top);
    }

    sea(0, gateX, high);
    sea(gateX, w, low);
    // The gate: heavy timber, with the walkway on top.
    final Rect gate = Rect.fromLTRB(gateX - w * 0.03, copingTop - h * 0.06, gateX + w * 0.03, h);
    canvas.drawRect(gate, Paint()..color = Palette.plankDark);
    for (double y = gate.top + 10; y < gate.bottom; y += 12) {
      canvas.drawLine(Offset(gate.left, y), Offset(gate.right, y), Paint()..color = Palette.plank);
    }
    canvas.drawRect(Rect.fromLTRB(gate.left, gate.top, gate.right, gate.top + 3), Paint()..color = Palette.plankLight);
    // The balance beam reaching back over the bank.
    final Paint beam = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(gate.right, gate.top + 4), Offset(w * 0.12, gate.top - h * 0.02), beam)
      ..drawLine(
        Offset(w * 0.12, gate.top - h * 0.02),
        Offset(w * 0.2, gate.top - h * 0.02),
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 5,
      );
    // Paddle gear on the gate.
    canvas
      ..drawRect(
        Rect.fromLTRB(gateX - 3, gate.top - h * 0.1, gateX + 3, gate.top),
        Paint()..color = const Color(0xFF263238),
      )
      ..drawCircle(Offset(gateX, gate.top - h * 0.1), 4, Paint()..color = Palette.buoyRed);
    // The difference in level.
    _Tide.arrow(canvas, Offset(w * 0.6, high), Offset(w * 0.6, low - 3), Palette.brass, both: true);
    _Tide.dashed(canvas, gateX, w * 0.66, high, Palette.brass);
    // A narrowboat waiting on the low side.
    final double boatTop = low - h * 0.08;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.66, boatTop, w * 0.97, low + h * 0.04), const Radius.circular(4)),
        Paint()..color = const Color(0xFF2E5E3A),
      )
      ..drawRect(Rect.fromLTRB(w * 0.7, boatTop - h * 0.07, w * 0.92, boatTop), Paint()..color = Palette.buoyRed)
      ..drawRect(
        Rect.fromLTRB(w * 0.7, boatTop - h * 0.075, w * 0.92, boatTop - h * 0.06),
        Paint()..color = Palette.brass,
      );
    for (double x = w * 0.73; x < w * 0.9; x += w * 0.05) {
      canvas.drawRect(Rect.fromLTWH(x, boatTop - h * 0.05, w * 0.025, h * 0.025), Paint()..color = Palette.sail);
    }
  }

  @override
  bool shouldRepaint(final _LockGatePainter oldDelegate) => false;
}
