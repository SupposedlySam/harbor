import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'frames_art.dart';
import 'scenery.dart';

/// A fishing boat seen side-on, its waterline at [waterline], [length] long,
/// starting at [left].
void _sideBoat(final Canvas canvas, final double left, final double waterline, final double length, final Color hull) {
  final double h = length * 0.22;
  final Path body = Path()
    ..moveTo(left, waterline - h)
    ..lineTo(left + length, waterline - h * 1.25)
    ..quadraticBezierTo(left + length * 0.9, waterline + h * 0.4, left + length * 0.7, waterline + h * 0.4)
    ..lineTo(left + length * 0.12, waterline + h * 0.4)
    ..quadraticBezierTo(left + length * 0.02, waterline, left, waterline - h)
    ..close();
  canvas
    ..drawPath(body, Paint()..color = hull)
    ..drawLine(
      Offset(left + length * 0.02, waterline - h * 0.75),
      Offset(left + length * 0.98, waterline - h),
      Paint()
        ..color = Palette.sail
        ..strokeWidth = 2,
    );
  // The wheelhouse, its windows and a mast.
  final Rect house = Rect.fromLTWH(left + length * 0.28, waterline - h * 2.3, length * 0.26, h * 1.15);
  canvas
    ..drawRect(house, Paint()..color = Palette.sail)
    ..drawRect(Rect.fromLTWH(house.left + 3, house.top + 3, house.width - 6, house.height * 0.35), Paint()..color = const Color(0xFF37474F))
    ..drawLine(
      Offset(house.center.dx, house.top),
      Offset(house.center.dx, house.top - length * 0.3),
      Paint()
        ..color = const Color(0xFF37474F)
        ..strokeWidth = 1.6,
    );
}

/// A stone quay wall with bollards on top and a fishing boat moored alongside:
/// solid ground that the water starts beyond.
class QuayArt extends StatelessWidget {
  const QuayArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _QuayPainter(), child: SizedBox.expand());
}

class _QuayPainter extends CustomPainter {
  const _QuayPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.66;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // Warehouses behind the quay.
    for (int i = 0; i < 3; i++) {
      final Rect shed = Rect.fromLTWH(w * (0.02 + i * 0.15), h * 0.22 + i * 4, w * 0.14, h * 0.24 - i * 4);
      canvas
        ..drawRect(shed, Paint()..color = <Color>[const Color(0xFFB5654A), const Color(0xFFCFB58E), const Color(0xFF8C6D5A)][i])
        ..drawPath(
          Path()
            ..moveTo(shed.left - 2, shed.top)
            ..lineTo(shed.center.dx, shed.top - h * 0.06)
            ..lineTo(shed.right + 2, shed.top)
            ..close(),
          Paint()..color = Palette.stoneDark,
        )
        ..drawRect(Rect.fromLTWH(shed.center.dx - 6, shed.bottom - 16, 12, 16), Paint()..color = Palette.plankDark);
    }
    // The quay wall: dressed stone from the paving down into the water.
    final double top = h * 0.46;
    final double face = w * 0.5;
    Scenery.quayWall(canvas, Rect.fromLTRB(0, top, face, h));
    // Weed and a tide line on the wall's face.
    canvas.drawRect(Rect.fromLTRB(0, waterline - 6, face, waterline), Paint()..color = const Color(0x664E6B2E));
    // Bollards along the edge, and tire fenders hanging down the face.
    Scenery.bollard(canvas, Offset(face * 0.3, top), h * 0.06);
    Scenery.bollard(canvas, Offset(face * 0.85, top), h * 0.06);
    for (final double y in <double>[top + h * 0.06]) {
      canvas.drawCircle(
        Offset(face - 4, y + h * 0.06),
        h * 0.04,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.022
          ..color = const Color(0xFF212121),
      );
    }
    Scenery.lamp(canvas, Offset(face * 0.6, top), h * 0.24, lit: false);
    // A crate waiting on the quay.
    canvas
      ..drawRect(Rect.fromLTWH(face * 0.08, top - h * 0.07, h * 0.07, h * 0.07), Paint()..color = Palette.plankLight)
      ..drawRect(
        Rect.fromLTWH(face * 0.08, top - h * 0.07, h * 0.07, h * 0.07),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Palette.plankDark,
      );
    // The boat alongside, lying against the wall, lines to the bollards.
    final double boatLeft = face + 2;
    final double length = w * 0.44;
    _sideBoat(canvas, boatLeft, waterline + 2, length, const Color(0xFF3D5A98));
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Palette.rope;
    canvas
      ..drawPath(
        Path()
          ..moveTo(face * 0.85, top - h * 0.05)
          ..quadraticBezierTo(face * 0.95, top + h * 0.02, boatLeft + 6, waterline - length * 0.2),
        line,
      )
      ..drawPath(
        Path()
          ..moveTo(face * 0.3, top - h * 0.05)
          ..quadraticBezierTo(face * 0.8, top - h * 0.12, boatLeft + length * 0.95, waterline - length * 0.26),
        line,
      );
    Scenery.ripples(canvas, Size(w, h), waterline);
  }

  @override
  bool shouldRepaint(final _QuayPainter oldDelegate) => false;
}

/// Two boats rafted up from above: one tied to the quay, the other tied
/// outside it, fenders between them.
class RaftedArt extends StatelessWidget {
  const RaftedArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _RaftedPainter(), child: SizedBox.expand());
}

class _RaftedPainter extends CustomPainter {
  const _RaftedPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()..shader = const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: <Color>[Palette.shallows, Palette.sea]).createShader(all),
    );
    TopDown.waves(canvas, Rect.fromLTWH(0, 0, w, h * 0.3), count: 16, seed: 3);
    // The quay along the bottom: paving and its stone edge.
    final double edge = h * 0.82;
    canvas
      ..drawRect(Rect.fromLTRB(0, edge, w, h), Paint()..color = const Color(0xFFA7A9A3))
      ..drawRect(Rect.fromLTRB(0, edge, w, edge + 5), Paint()..color = Palette.stoneDark);
    for (double x = 0; x < w; x += 22) {
      canvas.drawLine(
        Offset(x, edge + 5),
        Offset(x, h),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..strokeWidth = 1,
      );
    }
    final List<Offset> bollards = <Offset>[Offset(w * 0.18, edge + h * 0.06), Offset(w * 0.82, edge + h * 0.06)];
    for (final Offset b in bollards) {
      canvas
        ..drawCircle(b, h * 0.03, Paint()..color = const Color(0xFF263238))
        ..drawCircle(b, h * 0.015, Paint()..color = const Color(0xFF455A64));
    }
    // The inner boat lies against the quay, the outer boat against the inner.
    final double length = w * 0.56;
    final Offset inner = Offset(w * 0.5, edge - h * 0.12);
    final Offset outer = Offset(w * 0.52, edge - h * 0.36);
    // Mooring lines: inner to the quay, outer to the inner, and the outer's long lines ashore.
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Palette.rope;
    canvas
      ..drawLine(inner + Offset(length * 0.42, 0), bollards[1], line)
      ..drawLine(inner - Offset(length * 0.45, 0), bollards[0], line)
      ..drawLine(outer + Offset(length * 0.3, h * 0.04), inner + Offset(length * 0.2, -h * 0.04), line)
      ..drawLine(outer - Offset(length * 0.3, -h * 0.04), inner - Offset(length * 0.2, h * 0.04), line);
    final Paint longLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.rope.withValues(alpha: 0.85);
    canvas
      ..drawPath(
        Path()
          ..moveTo(outer.dx + length * 0.47, outer.dy)
          ..quadraticBezierTo(w * 0.98, edge - h * 0.1, bollards[1].dx + 4, bollards[1].dy),
        longLine,
      )
      ..drawPath(
        Path()
          ..moveTo(outer.dx - length * 0.48, outer.dy)
          ..quadraticBezierTo(w * 0.02, edge - h * 0.1, bollards[0].dx - 4, bollards[0].dy),
        longLine,
      );
    TopDown.boat(canvas, inner, length, 0, Palette.hulls[3]);
    TopDown.boat(canvas, outer, length * 0.92, 0, Palette.hulls[1]);
    // Fenders between the hulls and between the inner boat and the wall.
    final Paint fender = Paint()..color = Colors.white;
    for (final double dx in <double>[-0.2, 0.05, 0.25]) {
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5 + length * dx, (inner.dy + outer.dy) / 2), width: 10, height: 6), const Radius.circular(3)),
          fender,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5 + length * dx, edge - 3), width: 10, height: 5), const Radius.circular(3)),
          fender,
        );
    }
  }

  @override
  bool shouldRepaint(final _RaftedPainter oldDelegate) => false;
}

/// Harbor lights at night along a quay: one lit, one out, and a drawbridge
/// raised with its red light showing.
class HarborLightsArt extends StatelessWidget {
  const HarborLightsArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _LightsPainter(), child: SizedBox.expand());
}

class _LightsPainter extends CustomPainter {
  const _LightsPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.7;
    Scenery.sky(canvas, size, waterline, night: true);
    final Rect sea = Rect.fromLTWH(0, waterline, w, h - waterline);
    canvas
      ..drawRect(sea, Paint()..color = const Color(0xFF0B2440))
      ..drawCircle(Offset(w * 0.12, h * 0.16), h * 0.05, Paint()..color = const Color(0xFFF2EBD0));
    // The quay, from the left to the bridge pier.
    final double top = h * 0.58;
    final double bridgeAt = w * 0.66;
    Scenery.quayWall(canvas, Rect.fromLTRB(0, top, bridgeAt, h));
    canvas.drawRect(Rect.fromLTRB(0, top, bridgeAt, h), Paint()..color = Colors.black.withValues(alpha: 0.45));

    // Lit: a lamp with its glow and a streak of light on the water.
    final Offset litBase = Offset(w * 0.14, top);
    final double lampHeight = h * 0.32;
    for (int i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(litBase.dx + lampHeight * 0.18 + (i.isEven ? 2 : -2), waterline + 6 + i * 7), width: 18 - i * 2.0, height: 2),
        Paint()..color = const Color(0xFFFFE08A).withValues(alpha: 0.7 - i * 0.1),
      );
    }
    canvas.drawCircle(litBase - Offset(-lampHeight * 0.18, lampHeight * 0.9), lampHeight * 0.5, Paint()..color = const Color(0x22FFE08A));
    Scenery.lamp(canvas, litBase, lampHeight, lit: true);
    // Out: the same lamp, dark.
    Scenery.lamp(canvas, Offset(w * 0.4, top), lampHeight, lit: false);

    // The bridge: its pier, the leaf raised high over the channel, and the stop light.
    final Rect pier = Rect.fromLTRB(bridgeAt, top - h * 0.04, bridgeAt + w * 0.08, h);
    canvas.drawRect(pier, Paint()..color = const Color(0xFF37474F));
    final Offset hinge = Offset(pier.right, top - h * 0.02);
    final double leaf = w * 0.32;
    const double angle = -math.pi * 0.38;
    final Offset leafTip = hinge + Offset(math.cos(angle), math.sin(angle)) * leaf;
    canvas
      ..drawLine(
        hinge,
        leafTip,
        Paint()
          ..color = const Color(0xFF546E7A)
          ..strokeWidth = h * 0.05
          ..strokeCap = StrokeCap.butt,
      )
      ..drawLine(
        hinge + const Offset(0, -6),
        leafTip + const Offset(-4, -4),
        Paint()
          ..color = const Color(0xFF90A4AE)
          ..strokeWidth = 1.5,
      )
      // The counterweight below the hinge.
      ..drawRect(Rect.fromCenter(center: hinge + Offset(-w * 0.03, h * 0.06), width: w * 0.06, height: h * 0.08), Paint()..color = const Color(0xFF263238));
    final Offset stop = Offset(pier.center.dx, pier.top - h * 0.1);
    canvas
      ..drawLine(
        Offset(stop.dx, pier.top),
        stop,
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 2,
      )
      ..drawCircle(stop, h * 0.07, Paint()..color = const Color(0x55E2463A))
      ..drawCircle(stop, h * 0.025, Paint()..color = Palette.buoyRed);
    // The open channel beyond, with the red light's reflection.
    canvas.drawRect(
      Rect.fromCenter(center: Offset(stop.dx, waterline + h * 0.08), width: 6, height: h * 0.1),
      Paint()..color = Palette.buoyRed.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(final _LightsPainter oldDelegate) => false;
}

/// A bascule drawbridge over a channel: one leaf resting down, the other
/// raised high so a sailboat can pass.
class BasculeArt extends StatelessWidget {
  const BasculeArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _BasculePainter(), child: SizedBox.expand());
}

class _BasculePainter extends CustomPainter {
  const _BasculePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.76;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    final double deck = h * 0.56;
    // The two abutments: stone piers on each bank.
    final Rect left = Rect.fromLTRB(0, deck, w * 0.22, h);
    final Rect right = Rect.fromLTRB(w * 0.78, deck, w, h);
    Scenery.quayWall(canvas, left);
    Scenery.quayWall(canvas, right);
    // Bridge houses on each pier.
    for (final Rect house in <Rect>[
      Rect.fromLTWH(w * 0.04, deck - h * 0.16, w * 0.12, h * 0.16),
      Rect.fromLTWH(w * 0.84, deck - h * 0.16, w * 0.12, h * 0.16),
    ]) {
      canvas
        ..drawRect(house, Paint()..color = const Color(0xFFE8E2D4))
        ..drawPath(
          Path()
            ..moveTo(house.left - 3, house.top)
            ..lineTo(house.center.dx, house.top - h * 0.07)
            ..lineTo(house.right + 3, house.top)
            ..close(),
          Paint()..color = const Color(0xFFA9452E),
        )
        ..drawRect(Rect.fromLTWH(house.center.dx - 4, house.top + 6, 8, 8), Paint()..color = const Color(0xFF37474F));
    }
    final double span = w * 0.28;
    final double thick = h * 0.045;
    final Paint leaf = Paint()..color = const Color(0xFF3D5A6C);
    final Paint truss = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 1.2;
    // Resting: the left leaf lies down across its half of the channel.
    final Rect down = Rect.fromLTWH(left.right, deck - thick, span, thick);
    canvas.drawRect(down, leaf);
    for (double x = down.left; x < down.right - 8; x += 12) {
      canvas
        ..drawLine(Offset(x, down.bottom), Offset(x + 6, down.top), truss)
        ..drawLine(Offset(x + 6, down.top), Offset(x + 12, down.bottom), truss);
    }
    // Raised: the right leaf turned up on its hinge.
    canvas
      ..save()
      ..translate(right.left, deck)
      ..rotate(math.pi * 0.4);
    final Rect up = Rect.fromLTWH(-span, -thick, span, thick);
    canvas.drawRect(up, leaf);
    for (double x = up.left; x < up.right - 8; x += 12) {
      canvas
        ..drawLine(Offset(x, up.bottom), Offset(x + 6, up.top), truss)
        ..drawLine(Offset(x + 6, up.top), Offset(x + 12, up.bottom), truss);
    }
    canvas
      ..drawCircle(Offset(up.left + 4, up.top - 3), 3, Paint()..color = Palette.buoyRed)
      ..restore()
      ..drawCircle(Offset(right.left, deck - thick / 2), 5, Paint()..color = const Color(0xFF263238));
    // A sailboat passing through the open half.
    final double boatX = w * 0.62;
    final Path hull = Path()
      ..moveTo(boatX - w * 0.08, waterline - 4)
      ..lineTo(boatX + w * 0.08, waterline - 4)
      ..lineTo(boatX + w * 0.05, waterline + 4)
      ..lineTo(boatX - w * 0.06, waterline + 4)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = Palette.sail)
      ..drawLine(
        Offset(boatX, waterline - 4),
        Offset(boatX, h * 0.18),
        Paint()
          ..color = Palette.plankDark
          ..strokeWidth = 1.6,
      )
      ..drawPath(
        Path()
          ..moveTo(boatX + 2, h * 0.2)
          ..lineTo(boatX + 2, waterline - 9)
          ..lineTo(boatX + w * 0.09, waterline - 9)
          ..close(),
        Paint()..color = Colors.white,
      )
      ..drawPath(
        Path()
          ..moveTo(boatX - 2, h * 0.26)
          ..lineTo(boatX - 2, waterline - 9)
          ..lineTo(boatX - w * 0.06, waterline - 9)
          ..close(),
        Paint()..color = const Color(0xFFEDE6D6),
      );
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _BasculePainter oldDelegate) => false;
}

/// A gangway down to a floating pontoon, with its gate at the top: one leaf
/// shut across the way, the other swung open.
class GangwayGateArt extends StatelessWidget {
  const GangwayGateArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _GangwayPainter(), child: SizedBox.expand());
}

class _GangwayPainter extends CustomPainter {
  const _GangwayPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.72;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // The high pier on the left, on its piles.
    final double pierTop = h * 0.4;
    final double pierEnd = w * 0.3;
    for (double x = w * 0.04; x < pierEnd; x += w * 0.08) {
      Scenery.pile(canvas, Offset(x, pierTop + 6), h * 0.92, width: w * 0.02);
    }
    canvas
      ..drawRect(Rect.fromLTRB(0, pierTop, pierEnd, pierTop + 7), Paint()..color = Palette.plank)
      ..drawRect(Rect.fromLTRB(0, pierTop, pierEnd, pierTop + 2), Paint()..color = Palette.plankLight);
    // The pontoon, floating low on the right, with a boat beside it.
    final double pontoonTop = waterline - h * 0.04;
    final Rect pontoon = Rect.fromLTRB(w * 0.62, pontoonTop, w, waterline + h * 0.03);
    canvas
      ..drawRect(pontoon, Paint()..color = const Color(0xFFCFD8DC))
      ..drawRect(Rect.fromLTRB(pontoon.left, pontoonTop, pontoon.right, pontoonTop + 3), Paint()..color = Palette.plankLight);
    Scenery.rowboat(canvas, Offset(w * 0.84, waterline + h * 0.08), w * 0.16, Palette.hulls[2]);
    // The gangway: a ramp with handrails, hinged at the pier and rolling on the pontoon.
    final Offset from = Offset(pierEnd, pierTop + 3);
    final Offset to = Offset(pontoon.left + w * 0.05, pontoonTop);
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..strokeWidth = 5,
    );
    final Paint rail = Paint()
      ..color = const Color(0xFF607D8B)
      ..strokeWidth = 1.6;
    final Offset up = Offset(0, -h * 0.1);
    canvas.drawLine(from + up, to + up, rail);
    for (double t = 0; t <= 1.0001; t += 0.2) {
      final Offset p = Offset.lerp(from, to, t)!;
      canvas.drawLine(p, p + up, rail);
    }
    // The gate at the top: two posts, one leaf closed, one swung open.
    final double postTop = pierTop - h * 0.2;
    final double gateLeft = pierEnd - w * 0.14;
    final Paint post = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 3;
    canvas
      ..drawLine(Offset(gateLeft, pierTop), Offset(gateLeft, postTop), post)
      ..drawLine(Offset(pierEnd, pierTop), Offset(pierEnd, postTop), post);
    final Paint bars = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 1.4;
    // Closed leaf: from the left post to the middle, bars upright.
    final double mid = (gateLeft + pierEnd) / 2;
    final double leafTop = postTop + h * 0.03;
    canvas
      ..drawLine(Offset(gateLeft, leafTop), Offset(mid, leafTop), bars)
      ..drawLine(Offset(gateLeft, pierTop - 2), Offset(mid, pierTop - 2), bars);
    for (double x = gateLeft; x <= mid; x += 5) {
      canvas.drawLine(Offset(x, leafTop), Offset(x, pierTop - 2), bars);
    }
    // Open leaf: swung out toward the viewer, drawn foreshortened.
    final Path open = Path()
      ..moveTo(pierEnd, leafTop)
      ..lineTo(pierEnd + w * 0.04, leafTop + h * 0.04)
      ..lineTo(pierEnd + w * 0.04, pierTop + h * 0.03)
      ..lineTo(pierEnd, pierTop - 2);
    canvas.drawPath(
      open,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF37474F)
        ..strokeWidth = 1.4,
    );
    for (double t = 0.25; t < 1; t += 0.25) {
      final double x = pierEnd + w * 0.04 * t;
      canvas.drawLine(Offset(x, leafTop + h * 0.04 * t), Offset(x, pierTop - 2 + h * 0.05 * t), bars);
    }
    // A sign on the closed leaf.
    canvas.drawRect(Rect.fromCenter(center: Offset((gateLeft + mid) / 2, (leafTop + pierTop) / 2), width: w * 0.05, height: h * 0.05), Paint()..color = Palette.buoyRed);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _GangwayPainter oldDelegate) => false;
}
