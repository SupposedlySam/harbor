import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Dashes a straight line from [a] to [b].
void _dashed(
  final Canvas canvas,
  final Offset a,
  final Offset b,
  final Paint paint, {
  final double dash = 6,
  final double gap = 4,
}) {
  final double length = (b - a).distance;
  if (length <= 0) {
    return;
  }
  final Offset step = (b - a) / length;
  for (double d = 0; d < length; d += dash + gap) {
    canvas.drawLine(a + step * d, a + step * math.min(d + dash, length), paint);
  }
}

void _dashedRect(
  final Canvas canvas,
  final Rect rect,
  final Paint paint, {
  final double dash = 6,
  final double gap = 4,
}) {
  _dashed(canvas, rect.topLeft, rect.topRight, paint, dash: dash, gap: gap);
  _dashed(canvas, rect.topRight, rect.bottomRight, paint, dash: dash, gap: gap);
  _dashed(canvas, rect.bottomRight, rect.bottomLeft, paint, dash: dash, gap: gap);
  _dashed(canvas, rect.bottomLeft, rect.topLeft, paint, dash: dash, gap: gap);
}

void _text(
  final Canvas canvas,
  final String text,
  final Offset at, {
  final Color color = Palette.plankDark,
  final double size = 8,
  final bool bold = false,
  final bool center = false,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontFamily: 'Georgia',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center ? at - Offset(painter.width / 2, painter.height / 2) : at);
}

/// A small sailing ship side-on: hull, two masts and their sails.
void _sailingShip(
  final Canvas canvas,
  final Offset waterline,
  final double length, {
  final Color hull = Palette.plankDark,
}) {
  final double h = length * 0.22;
  final Path body = Path()
    ..moveTo(waterline.dx - length / 2, waterline.dy - h)
    ..lineTo(waterline.dx + length / 2, waterline.dy - h * 1.15)
    ..quadraticBezierTo(waterline.dx + length * 0.38, waterline.dy, waterline.dx + length * 0.28, waterline.dy)
    ..lineTo(waterline.dx - length * 0.36, waterline.dy)
    ..quadraticBezierTo(
      waterline.dx - length * 0.46,
      waterline.dy - h * 0.4,
      waterline.dx - length / 2,
      waterline.dy - h,
    )
    ..close();
  canvas
    ..drawPath(body, Paint()..color = hull)
    ..drawLine(
      Offset(waterline.dx - length / 2, waterline.dy - h * 0.8),
      Offset(waterline.dx + length / 2, waterline.dy - h * 0.95),
      Paint()
        ..color = Palette.brass
        ..strokeWidth = math.max(1, length * 0.015),
    );
  final Paint mast = Paint()
    ..color = Palette.plankDark
    ..strokeWidth = math.max(1, length * 0.02);
  for (final double at in <double>[-0.18, 0.14]) {
    final double x = waterline.dx + length * at;
    final double top = waterline.dy - h - length * 0.7;
    canvas.drawLine(Offset(x, waterline.dy - h), Offset(x, top), mast);
    for (int i = 0; i < 3; i++) {
      final double y0 = top + length * 0.06 + i * length * 0.2;
      final double w = length * (0.13 + i * 0.03);
      final Path sail = Path()
        ..moveTo(x - w, y0)
        ..lineTo(x + w, y0)
        ..quadraticBezierTo(x + w * 1.15, y0 + length * 0.09, x + w * 0.95, y0 + length * 0.17)
        ..lineTo(x - w * 0.95, y0 + length * 0.17)
        ..quadraticBezierTo(x - w * 0.8, y0 + length * 0.09, x - w, y0)
        ..close();
      canvas.drawPath(sail, Paint()..color = Palette.sail);
      canvas.drawPath(
        sail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = Palette.stone,
      );
    }
  }
  // Bowsprit and a pennant.
  canvas.drawLine(
    Offset(waterline.dx + length / 2, waterline.dy - h * 1.15),
    Offset(waterline.dx + length * 0.68, waterline.dy - h * 1.9),
    mast,
  );
  final double flagX = waterline.dx + length * 0.14;
  final double flagY = waterline.dy - h - length * 0.7;
  canvas.drawPath(
    Path()
      ..moveTo(flagX, flagY)
      ..lineTo(flagX + length * 0.12, flagY + length * 0.03)
      ..lineTo(flagX, flagY + length * 0.06)
      ..close(),
    Paint()..color = Palette.buoyRed,
  );
}

// ─── HarborCoast: cliffs and a beach ───────────────────────────────────────────

/// A rugged coastline: banded cliffs dropping into the sea, a sea stack, and
/// a sandy cove with surf. The land the sea can't use.
class CoastArt extends StatelessWidget {
  const CoastArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _CoastPainter(), child: SizedBox.expand());
}

class _CoastPainter extends CustomPainter {
  const _CoastPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.64;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);

    // The cove's beach, between the two headlands.
    final Path beach = Path()
      ..moveTo(w * 0.3, waterline + 2)
      ..quadraticBezierTo(w * 0.45, waterline - h * 0.07, w * 0.62, waterline - h * 0.02)
      ..lineTo(w * 0.66, waterline + h * 0.06)
      ..quadraticBezierTo(w * 0.47, waterline + h * 0.14, w * 0.28, waterline + h * 0.07)
      ..close();
    canvas.drawPath(beach, Paint()..color = const Color(0xFFE6D3A0));
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.29, waterline + h * 0.07)
        ..quadraticBezierTo(w * 0.47, waterline + h * 0.15, w * 0.66, waterline + h * 0.06),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    // Surf lines rolling in.
    final Paint surf = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 1; i <= 3; i++) {
      final double dy = i * h * 0.05;
      canvas.drawPath(
        Path()
          ..moveTo(w * (0.32 - i * 0.02), waterline + h * 0.08 + dy)
          ..quadraticBezierTo(w * 0.47, waterline + h * 0.16 + dy, w * (0.64 + i * 0.02), waterline + h * 0.07 + dy),
        surf,
      );
    }

    // The near headland: tall banded cliffs on the right.
    final Path cliff = Path()
      ..moveTo(w * 0.6, waterline + h * 0.08)
      ..lineTo(w * 0.62, waterline - h * 0.18)
      ..lineTo(w * 0.66, waterline - h * 0.3)
      ..lineTo(w * 0.7, waterline - h * 0.36)
      ..lineTo(w * 0.76, waterline - h * 0.42)
      ..lineTo(w * 0.86, waterline - h * 0.47)
      ..lineTo(w, waterline - h * 0.5)
      ..lineTo(w, waterline + h * 0.36)
      ..close();
    canvas.drawPath(cliff, Paint()..color = const Color(0xFF8C7660));
    canvas.save();
    canvas.clipPath(cliff);
    final Paint strata = Paint()
      ..strokeWidth = 1.2
      ..color = const Color(0xFF6B5846);
    for (double y = waterline - h * 0.46; y < waterline + h * 0.3; y += h * 0.045) {
      canvas.drawLine(Offset(w * 0.55, y + h * 0.02), Offset(w, y - h * 0.02), strata);
    }
    // Shadowed cracks down the face.
    final Paint crack = Paint()
      ..strokeWidth = 1.4
      ..color = const Color(0xFF4E3F32);
    for (final double x in <double>[0.68, 0.78, 0.9]) {
      canvas.drawLine(Offset(w * x, waterline - h * 0.4), Offset(w * (x - 0.03), waterline + h * 0.1), crack);
    }
    canvas.restore();
    // Grass along the cliff top.
    final Path grass = Path()
      ..moveTo(w * 0.66, waterline - h * 0.3)
      ..lineTo(w * 0.7, waterline - h * 0.36)
      ..lineTo(w * 0.76, waterline - h * 0.42)
      ..lineTo(w * 0.86, waterline - h * 0.47)
      ..lineTo(w, waterline - h * 0.5)
      ..lineTo(w, waterline - h * 0.46)
      ..lineTo(w * 0.86, waterline - h * 0.43)
      ..lineTo(w * 0.76, waterline - h * 0.38)
      ..lineTo(w * 0.7, waterline - h * 0.33)
      ..close();
    canvas.drawPath(grass, Paint()..color = const Color(0xFF5E8C4A));
    // A cottage on the clifftop.
    final Rect cottage = Rect.fromLTWH(w * 0.88, waterline - h * 0.58, w * 0.06, h * 0.1);
    canvas
      ..drawRect(cottage, Paint()..color = Palette.sail)
      ..drawPath(
        Path()
          ..moveTo(cottage.left - 2, cottage.top)
          ..lineTo(cottage.center.dx, cottage.top - h * 0.06)
          ..lineTo(cottage.right + 2, cottage.top)
          ..close(),
        Paint()..color = Palette.buoyRed,
      );

    // The far headland on the left, lower and hazier.
    final Path far = Path()
      ..moveTo(0, waterline + h * 0.04)
      ..lineTo(0, waterline - h * 0.3)
      ..lineTo(w * 0.12, waterline - h * 0.27)
      ..lineTo(w * 0.22, waterline - h * 0.16)
      ..lineTo(w * 0.3, waterline - h * 0.02)
      ..lineTo(w * 0.32, waterline + h * 0.05)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF9C8B78));
    canvas.drawPath(
      Path()
        ..moveTo(0, waterline - h * 0.3)
        ..lineTo(w * 0.12, waterline - h * 0.27)
        ..lineTo(w * 0.22, waterline - h * 0.16)
        ..lineTo(w * 0.22, waterline - h * 0.13)
        ..lineTo(w * 0.12, waterline - h * 0.24)
        ..lineTo(0, waterline - h * 0.27)
        ..close(),
      Paint()..color = const Color(0xFF6E9A5A),
    );

    // A sea stack off the near headland, with surf at its foot.
    final Path stack = Path()
      ..moveTo(w * 0.52, waterline + h * 0.2)
      ..lineTo(w * 0.53, waterline + h * 0.02)
      ..lineTo(w * 0.545, waterline - h * 0.06)
      ..lineTo(w * 0.57, waterline - h * 0.05)
      ..lineTo(w * 0.58, waterline + h * 0.2)
      ..close();
    canvas
      ..drawPath(stack, Paint()..color = const Color(0xFF7A6552))
      ..drawOval(
        Rect.fromCenter(center: Offset(w * 0.555, waterline + h * 0.2), width: w * 0.09, height: h * 0.035),
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      )
      ..drawOval(
        Rect.fromCenter(center: Offset(w * 0.62, waterline + h * 0.3), width: w * 0.08, height: h * 0.03),
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    Scenery.ripples(canvas, size, waterline + h * 0.2);
  }

  @override
  bool shouldRepaint(final _CoastPainter oldDelegate) => false;
}

// ─── HarborCoast.titleSafe: an old TV with the safe frame marked ──────────────

/// An old wooden CRT television with rabbit-ear antennas, a ship on its
/// rounded screen, and the broadcast title-safe and action-safe frames marked
/// over the picture.
class TitleSafeTvArt extends StatelessWidget {
  const TitleSafeTvArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _TvPainter(), child: SizedBox.expand());
}

class _TvPainter extends CustomPainter {
  const _TvPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    // A papered wall and a floor.
    canvas
      ..drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE9D9B8))
      ..drawRect(Rect.fromLTWH(0, h * 0.86, w, h * 0.14), Paint()..color = Palette.plank);
    for (double x = 0; x < w; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.86), Paint()..color = const Color(0xFFDCC9A3));
    }

    final double tvW = math.min(w * 0.62, h * 1.05);
    final double tvH = tvW * 0.68;
    final Rect cabinet = Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: tvW, height: tvH);
    // Legs.
    final Paint leg = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(cabinet.bottomLeft + Offset(tvW * 0.12, 0), Offset(cabinet.left + tvW * 0.06, h * 0.93), leg)
      ..drawLine(cabinet.bottomRight - Offset(tvW * 0.12, 0), Offset(cabinet.right - tvW * 0.06, h * 0.93), leg);
    // Rabbit ears.
    final Offset base = cabinet.topCenter + const Offset(0, -2);
    final Paint ear = Paint()
      ..color = const Color(0xFF9EA4A8)
      ..strokeWidth = 1.6;
    canvas
      ..drawLine(base, base + Offset(-tvW * 0.25, -h * 0.26), ear)
      ..drawLine(base, base + Offset(tvW * 0.18, -h * 0.3), ear)
      ..drawOval(
        Rect.fromCenter(center: base, width: tvW * 0.14, height: tvH * 0.1),
        Paint()..color = const Color(0xFF37474F),
      );
    // The cabinet: veneer with a highlight.
    final RRect wood = RRect.fromRectAndRadius(cabinet, Radius.circular(tvW * 0.05));
    canvas
      ..drawRRect(wood.shift(const Offset(0, 3)), Paint()..color = Colors.black26)
      ..drawRRect(
        wood,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Palette.plankLight, Palette.plank, Palette.plankDark],
          ).createShader(cabinet),
      );
    // The screen, its bulging glass, inside a dark mask.
    final Rect screenBox = Rect.fromLTWH(cabinet.left + tvW * 0.06, cabinet.top + tvH * 0.09, tvW * 0.68, tvH * 0.82);
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenBox.inflate(4), Radius.circular(tvW * 0.06)),
      Paint()..color = const Color(0xFF1C1C1C),
    );
    final RRect glass = RRect.fromRectAndRadius(screenBox, Radius.circular(tvW * 0.07));
    canvas
      ..save()
      ..clipRRect(glass)
      ..translate(screenBox.left, screenBox.top);
    final Size picture = screenBox.size;
    final double horizon = picture.height * 0.6;
    Scenery.sky(canvas, picture, horizon);
    Scenery.water(canvas, picture, horizon);
    _sailingShip(canvas, Offset(picture.width * 0.5, horizon + picture.height * 0.08), picture.width * 0.4);
    // Scan lines and the tube's glow.
    for (double y = 0; y < picture.height; y += 2.5) {
      canvas.drawLine(Offset(0, y), Offset(picture.width, y), Paint()..color = Colors.black.withValues(alpha: 0.06));
    }
    canvas.drawRect(
      Offset.zero & picture,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[Colors.white.withValues(alpha: 0.12), Colors.black.withValues(alpha: 0.35)],
          stops: const <double>[0.55, 1.0],
        ).createShader(Offset.zero & picture),
    );
    // Action-safe (5%) and title-safe (10%) frames.
    final Rect action = Rect.fromLTRB(
      picture.width * 0.05,
      picture.height * 0.05,
      picture.width * 0.95,
      picture.height * 0.95,
    );
    final Rect title = Rect.fromLTRB(
      picture.width * 0.1,
      picture.height * 0.1,
      picture.width * 0.9,
      picture.height * 0.9,
    );
    _dashedRect(
      canvas,
      action,
      Paint()
        ..color = Palette.brass
        ..strokeWidth = 1.2,
      dash: 4,
      gap: 3,
    );
    _dashedRect(
      canvas,
      title,
      Paint()
        ..color = Palette.buoyRed
        ..strokeWidth = 1.4,
      dash: 5,
      gap: 3,
    );
    final Paint cross = Paint()
      ..color = Palette.buoyRed.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    final Offset c = picture.center(Offset.zero);
    canvas
      ..drawLine(c - const Offset(6, 0), c + const Offset(6, 0), cross)
      ..drawLine(c - const Offset(0, 6), c + const Offset(0, 6), cross);
    _text(canvas, 'TITLE SAFE', title.topLeft + const Offset(3, 2), color: Palette.buoyRed, size: 7, bold: true);
    canvas.restore();
    // A glint on the glass.
    canvas.drawPath(
      Path()
        ..moveTo(screenBox.left + screenBox.width * 0.1, screenBox.top + screenBox.height * 0.2)
        ..quadraticBezierTo(
          screenBox.left + screenBox.width * 0.15,
          screenBox.top + screenBox.height * 0.08,
          screenBox.left + screenBox.width * 0.35,
          screenBox.top + screenBox.height * 0.07,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    // The control panel: two knobs and a speaker grille.
    final double panelX = screenBox.right + (cabinet.right - screenBox.right) / 2;
    for (int i = 0; i < 2; i++) {
      final Offset knob = Offset(panelX, cabinet.top + tvH * (0.22 + i * 0.22));
      canvas
        ..drawCircle(knob, tvW * 0.045, Paint()..color = const Color(0xFF3E2A18))
        ..drawCircle(knob, tvW * 0.03, Paint()..color = const Color(0xFFCFC7B8))
        ..drawLine(
          knob,
          knob + Offset(0, -tvW * 0.028),
          Paint()
            ..color = const Color(0xFF3E2A18)
            ..strokeWidth = 1.4,
        );
    }
    for (int i = 0; i < 5; i++) {
      final double y = cabinet.top + tvH * (0.62 + i * 0.055);
      canvas.drawLine(
        Offset(panelX - tvW * 0.05, y),
        Offset(panelX + tvW * 0.05, y),
        Paint()
          ..color = const Color(0xFF3E2A18)
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(final _TvPainter oldDelegate) => false;
}

// ─── HarborScaleModel: a ship in a bottle ───────────────────────────────────

/// A ship in a bottle: a full-rigged ship on a putty sea inside a glass
/// bottle lying on a wooden stand, corked.
class ShipInBottleArt extends StatelessWidget {
  const ShipInBottleArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _BottlePainter(), child: SizedBox.expand());
}

class _BottlePainter extends CustomPainter {
  const _BottlePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    // A study's wall and a shelf.
    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF2B3A4A), Color(0xFF1B2733)],
          ).createShader(Offset.zero & size),
      )
      ..drawRect(Rect.fromLTWH(0, h * 0.8, w, h * 0.2), Paint()..color = Palette.plankDark)
      ..drawRect(Rect.fromLTWH(0, h * 0.8, w, 3), Paint()..color = Palette.plankLight);

    final double cy = h * 0.5;
    final double bodyL = w * 0.14;
    final double bodyR = w * 0.7;
    final double r = h * 0.24;
    // The bottle's outline: a long body, a shoulder and a neck to the right.
    final Path bottle = Path()
      ..moveTo(bodyL + r * 0.5, cy - r)
      ..lineTo(bodyR, cy - r)
      ..cubicTo(bodyR + w * 0.08, cy - r, bodyR + w * 0.08, cy - r * 0.35, bodyR + w * 0.12, cy - r * 0.32)
      ..lineTo(w * 0.88, cy - r * 0.32)
      ..lineTo(w * 0.88, cy + r * 0.32)
      ..lineTo(bodyR + w * 0.12, cy + r * 0.32)
      ..cubicTo(bodyR + w * 0.08, cy + r * 0.35, bodyR + w * 0.08, cy + r, bodyR, cy + r)
      ..lineTo(bodyL + r * 0.5, cy + r)
      ..quadraticBezierTo(bodyL, cy + r, bodyL, cy)
      ..quadraticBezierTo(bodyL, cy - r, bodyL + r * 0.5, cy - r)
      ..close();

    // The stand: two cradles on a plank.
    final Paint stand = Paint()..color = Palette.plank;
    canvas.drawRect(Rect.fromLTRB(w * 0.18, h * 0.76, w * 0.72, h * 0.8), stand);
    for (final double x in <double>[0.26, 0.6]) {
      canvas.drawPath(
        Path()
          ..moveTo(w * x - w * 0.05, h * 0.76)
          ..lineTo(w * x - w * 0.05, cy + r * 0.6)
          ..quadraticBezierTo(w * x, cy + r * 1.25, w * x + w * 0.05, cy + r * 0.6)
          ..lineTo(w * x + w * 0.05, h * 0.76)
          ..close(),
        Paint()..color = Palette.plankLight,
      );
    }

    // Inside: the putty sea and the ship.
    canvas
      ..save()
      ..clipPath(bottle);
    canvas.drawRect(Rect.fromLTRB(0, cy - r, w, cy + r), Paint()..color = const Color(0x332A86B5));
    final Path sea = Path()..moveTo(bodyL, cy + r * 0.45);
    for (double x = bodyL; x <= bodyR + w * 0.04; x += 4) {
      sea.lineTo(x, cy + r * 0.45 + math.sin(x / 7) * 1.6);
    }
    sea
      ..lineTo(bodyR + w * 0.04, cy + r)
      ..lineTo(bodyL, cy + r)
      ..close();
    canvas.drawPath(sea, Paint()..color = Palette.shallows);
    _sailingShip(canvas, Offset((bodyL + bodyR) / 2, cy + r * 0.48), (bodyR - bodyL) * 0.5);
    canvas.restore();

    // The glass: tint, edge and highlights.
    canvas
      ..drawPath(bottle, Paint()..color = const Color(0x2280CBC4))
      ..drawPath(
        bottle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xAA9ADBD3),
      )
      ..drawLine(
        Offset(bodyL + r * 0.6, cy - r * 0.78),
        Offset(bodyR - w * 0.02, cy - r * 0.78),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.45),
      )
      ..drawLine(
        Offset(bodyL + r * 0.9, cy + r * 0.82),
        Offset(bodyL + r * 2.2, cy + r * 0.82),
        Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.25),
      );
    // The cork.
    final Rect cork = Rect.fromLTRB(w * 0.87, cy - r * 0.27, w * 0.94, cy + r * 0.27);
    canvas.drawRRect(RRect.fromRectAndRadius(cork, const Radius.circular(2)), Paint()..color = const Color(0xFFC49A6C));
    final math.Random random = math.Random(9);
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(cork.left + random.nextDouble() * cork.width, cork.top + random.nextDouble() * cork.height),
        0.8,
        Paint()..color = const Color(0xFF8D6E4A),
      );
    }
  }

  @override
  bool shouldRepaint(final _BottlePainter oldDelegate) => false;
}

// ─── HarborEdge: port and starboard lights ───────────────────────────────────

/// A ship seen from above at night: a red running light on her port side, a
/// green one to starboard, each shining its sector forward, a white
/// masthead light and stern light, and a compass rose for bearings.
class RunningLightsArt extends StatelessWidget {
  const RunningLightsArt({super.key});

  @override
  Widget build(final BuildContext context) =>
      const CustomPaint(painter: _RunningLightsPainter(), child: SizedBox.expand());
}

class _RunningLightsPainter extends CustomPainter {
  const _RunningLightsPainter();

  static const Color _red = Color(0xFFFF3B30);
  static const Color _green = Color(0xFF30D158);

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    // Night sea from above.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF123456), Color(0xFF061220)],
        ).createShader(Offset.zero & size),
    );
    final Paint swell = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.foam.withValues(alpha: 0.08);
    for (double y = 8; y < h; y += 14) {
      final Path p = Path()..moveTo(0, y);
      for (double x = 0; x <= w; x += 8) {
        p.lineTo(x, y + math.sin(x / 18 + y) * 2);
      }
      canvas.drawPath(p, swell);
    }

    final Offset c = Offset(w * 0.5, h * 0.55);
    final double len = h * 0.62;
    final double beam = len * 0.3;
    final Offset portLight = c + Offset(-beam / 2, -len * 0.08);
    final Offset starboardLight = c + Offset(beam / 2, -len * 0.08);
    // Light sectors: dead ahead to 112.5° on each side.
    void sector(final Offset at, final Color color, final double from, final double sweep) {
      final Rect arc = Rect.fromCircle(center: at, radius: len * 0.75);
      canvas.drawArc(
        arc,
        from,
        sweep,
        true,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
          ).createShader(arc),
      );
    }

    const double ahead = -math.pi / 2;
    const double sectorSweep = math.pi * 112.5 / 180;
    sector(portLight, _red, ahead - sectorSweep, sectorSweep);
    sector(starboardLight, _green, ahead, sectorSweep);

    // The hull from above: pointed bow up, square stern.
    final Path hull = Path()
      ..moveTo(c.dx, c.dy - len / 2)
      ..quadraticBezierTo(c.dx + beam * 0.55, c.dy - len * 0.25, c.dx + beam / 2, c.dy + len * 0.1)
      ..lineTo(c.dx + beam * 0.42, c.dy + len / 2)
      ..lineTo(c.dx - beam * 0.42, c.dy + len / 2)
      ..lineTo(c.dx - beam / 2, c.dy + len * 0.1)
      ..quadraticBezierTo(c.dx - beam * 0.55, c.dy - len * 0.25, c.dx, c.dy - len / 2)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = const Color(0xFF2B2F33))
      ..drawPath(
        hull,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF8A9096),
      )
      // Deck planking and a wheelhouse.
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c + Offset(0, len * 0.2), width: beam * 0.55, height: len * 0.2),
          const Radius.circular(2),
        ),
        Paint()..color = Palette.sail.withValues(alpha: 0.8),
      )
      ..drawCircle(c + Offset(0, -len * 0.05), 2.4, Paint()..color = Colors.white)
      ..drawCircle(c + Offset(0, -len * 0.05), 7, Paint()..color = Colors.white.withValues(alpha: 0.2))
      ..drawCircle(c + Offset(0, len * 0.49), 2.2, Paint()..color = Colors.white);
    // The running lights themselves.
    for (final (Offset, Color) light in <(Offset, Color)>[(portLight, _red), (starboardLight, _green)]) {
      canvas
        ..drawCircle(light.$1, 9, Paint()..color = light.$2.withValues(alpha: 0.3))
        ..drawCircle(light.$1, 3.4, Paint()..color = light.$2);
    }
    _text(canvas, 'PORT', portLight + Offset(-beam * 1.2, len * 0.12), color: _red, size: 9, bold: true, center: true);
    _text(
      canvas,
      'STARBOARD',
      starboardLight + Offset(beam * 1.5, len * 0.12),
      color: _green,
      size: 9,
      bold: true,
      center: true,
    );

    // A compass rose in the corner.
    final Offset rose = Offset(w * 0.12, h * 0.2);
    final double rr = math.min(w, h) * 0.12;
    canvas.drawCircle(
      rose,
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Palette.brass.withValues(alpha: 0.7),
    );
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4 - math.pi / 2;
      final double reach = i.isEven ? rr : rr * 0.55;
      final Offset tip = rose + Offset(math.cos(a), math.sin(a)) * reach;
      final Offset l = rose + Offset(math.cos(a - math.pi / 2), math.sin(a - math.pi / 2)) * rr * 0.12;
      final Offset rgt = rose + Offset(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2)) * rr * 0.12;
      canvas
        ..drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(l.dx, l.dy)
            ..lineTo(rose.dx, rose.dy)
            ..close(),
          Paint()..color = Palette.brass,
        )
        ..drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(rgt.dx, rgt.dy)
            ..lineTo(rose.dx, rose.dy)
            ..close(),
          Paint()..color = const Color(0xFF9C7A2A),
        );
    }
    _text(canvas, 'N', rose + Offset(0, -rr - 7), color: Palette.brass, size: 8, bold: true, center: true);
  }

  @override
  bool shouldRepaint(final _RunningLightsPainter oldDelegate) => false;
}

// ─── HarborChart: a nautical chart ───────────────────────────────────────────

/// A nautical chart: buff land and a harbor plan with its breakwater, pier and
/// anchorage, blue shallows inside the depth contours, scattered soundings, a
/// compass rose and rhumb lines.
class NauticalChartArt extends StatelessWidget {
  const NauticalChartArt({super.key});

  @override
  Widget build(final BuildContext context) =>
      const CustomPaint(painter: _NauticalChartPainter(), child: SizedBox.expand());
}

class _NauticalChartPainter extends CustomPainter {
  const _NauticalChartPainter();

  static const Color _ink = Color(0xFF3B4A5A);
  static const Color _paper = Color(0xFFF4EBD4);
  static const Color _land = Color(0xFFE3C88E);
  static const Color _shoal = Color(0xFFBFE0EA);

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);

    // The coastline across the top, with the harbor's bay cut into it.
    final Path land = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.28)
      ..quadraticBezierTo(w * 0.86, h * 0.36, w * 0.74, h * 0.3)
      ..quadraticBezierTo(w * 0.66, h * 0.5, w * 0.5, h * 0.52)
      ..quadraticBezierTo(w * 0.36, h * 0.5, w * 0.32, h * 0.32)
      ..quadraticBezierTo(w * 0.2, h * 0.4, w * 0.08, h * 0.3)
      ..lineTo(0, h * 0.34)
      ..close();
    // Shallows: the land's outline grown outward, twice.
    for (final (double, Color) band in <(double, Color)>[(h * 0.14, const Color(0xFFDDEFF4)), (h * 0.07, _shoal)]) {
      canvas
        ..save()
        ..translate(0, band.$1)
        ..drawPath(land, Paint()..color = band.$2)
        ..restore();
      canvas
        ..save()
        ..translate(0, band.$1)
        ..drawPath(
          land,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = _ink.withValues(alpha: 0.35),
        )
        ..restore();
    }
    canvas
      ..drawPath(land, Paint()..color = _land)
      ..drawPath(
        land,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _ink,
      );
    // Hachures inland.
    final Paint hatch = Paint()
      ..strokeWidth = 0.7
      ..color = _ink.withValues(alpha: 0.35);
    for (double x = 6; x < w; x += 9) {
      canvas.drawLine(Offset(x, h * 0.04), Offset(x + 4, h * 0.12), hatch);
    }
    // The town in the bay: a few blocks and a church.
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(w * (0.4 + i * 0.04), h * (0.32 + (i % 2) * 0.04), w * 0.025, h * 0.03),
        Paint()..color = _ink.withValues(alpha: 0.7),
      );
    }
    // The harbor plan: a breakwater from the east headland and a pier.
    final Paint wall = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    canvas
      ..drawLine(Offset(w * 0.74, h * 0.31), Offset(w * 0.66, h * 0.6), wall)
      ..drawLine(Offset(w * 0.66, h * 0.6), Offset(w * 0.56, h * 0.64), wall)
      ..drawLine(
        Offset(w * 0.42, h * 0.5),
        Offset(w * 0.42, h * 0.62),
        Paint()
          ..strokeWidth = 2
          ..color = Palette.plankDark,
      );
    // A light at the breakwater's head, with its characteristic.
    canvas
      ..drawCircle(Offset(w * 0.56, h * 0.64), 3.2, Paint()..color = Palette.buoyRed)
      ..drawCircle(Offset(w * 0.56, h * 0.64), 7, Paint()..color = const Color(0x55E9B949));
    _text(canvas, 'Fl.R.5s', Offset(w * 0.57, h * 0.66), color: Palette.buoyRed, size: 7);
    // An anchorage symbol.
    final Offset anchor = Offset(w * 0.5, h * 0.75);
    final Paint anchorInk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = _ink;
    canvas
      ..drawLine(anchor - const Offset(0, 7), anchor + const Offset(0, 6), anchorInk)
      ..drawCircle(anchor - const Offset(0, 9), 2, anchorInk)
      ..drawArc(Rect.fromCircle(center: anchor, radius: 6), 0.2, math.pi - 0.4, false, anchorInk)
      ..drawLine(anchor - const Offset(4, 4), anchor + const Offset(4, -4), anchorInk);
    // Soundings in fathoms, deeper offshore.
    final math.Random random = math.Random(21);
    for (int i = 0; i < 26; i++) {
      final double x = w * (0.05 + random.nextDouble() * 0.9);
      final double y = h * (0.55 + random.nextDouble() * 0.42);
      if ((Offset(x, y) - Offset(w * 0.82, h * 0.78)).distance < h * 0.22) {
        continue;
      }
      final int depth = 2 + ((y / h - 0.5) * 30).round() + random.nextInt(3);
      _text(canvas, '$depth', Offset(x, y), color: _ink, size: 7, center: true);
    }
    // A buoy symbol off the harbor mouth.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.36, h * 0.66)
        ..lineTo(w * 0.38, h * 0.6)
        ..lineTo(w * 0.4, h * 0.66)
        ..close(),
      Paint()..color = const Color(0xFF2E7D5B),
    );

    // The compass rose, with rhumb lines from its center.
    final Offset rose = Offset(w * 0.82, h * 0.78);
    final double r = math.min(w, h) * 0.19;
    final Paint rhumb = Paint()
      ..strokeWidth = 0.5
      ..color = _ink.withValues(alpha: 0.3);
    for (int i = 0; i < 16; i++) {
      final double a = i * math.pi / 8;
      canvas.drawLine(rose, rose + Offset(math.cos(a), math.sin(a)) * w, rhumb);
    }
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.buoyRed.withValues(alpha: 0.8);
    canvas
      ..drawCircle(rose, r, Paint()..color = _paper)
      ..drawCircle(rose, r, ring)
      ..drawCircle(rose, r * 0.86, ring);
    for (int i = 0; i < 72; i++) {
      final double a = i * math.pi / 36;
      final double inner = i % 9 == 0 ? r * 0.76 : r * 0.86;
      canvas.drawLine(
        rose + Offset(math.cos(a), math.sin(a)) * inner,
        rose + Offset(math.cos(a), math.sin(a)) * r,
        ring,
      );
    }
    for (int i = 0; i < 8; i++) {
      final double a = i * math.pi / 4 - math.pi / 2;
      final double reach = i.isEven ? r * 0.74 : r * 0.42;
      final Offset tip = rose + Offset(math.cos(a), math.sin(a)) * reach;
      final Offset l = rose + Offset(math.cos(a - math.pi / 2), math.sin(a - math.pi / 2)) * r * 0.1;
      final Offset rg = rose + Offset(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2)) * r * 0.1;
      canvas
        ..drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(l.dx, l.dy)
            ..lineTo(rose.dx, rose.dy)
            ..close(),
          Paint()..color = _ink,
        )
        ..drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(rg.dx, rg.dy)
            ..lineTo(rose.dx, rose.dy)
            ..close(),
          Paint()..color = Palette.buoyRed,
        );
    }
    // A fleur-de-lis stand-in for north.
    _text(canvas, 'N', rose + Offset(0, -r - 6), color: Palette.buoyRed, size: 9, bold: true, center: true);
    // The chart's border.
    canvas
      ..drawRect(
        (Offset.zero & size).deflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _ink,
      )
      ..drawRect(
        (Offset.zero & size).deflate(6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = _ink,
      );
  }

  @override
  bool shouldRepaint(final _NauticalChartPainter oldDelegate) => false;
}

// ─── Sea trials: a new ship with the trials flags and a tug ─────────────────

/// A new ship on her sea trials: fresh paint, a dressing line of signal flags
/// from bow to mast to stern, a bow wave, and a tug standing by alongside
/// with fenders over her side and smoke from her stack.
class SeaTrialsArt extends StatelessWidget {
  const SeaTrialsArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SeaTrialsPainter(), child: SizedBox.expand());
}

class _SeaTrialsPainter extends CustomPainter {
  const _SeaTrialsPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.7;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);

    // The new ship: a long grey hull with red boot-topping, bow to the right.
    final double sl = w * 0.6;
    final double sx = w * 0.08;
    final double hullTop = waterline - h * 0.17;
    final Path hull = Path()
      ..moveTo(sx, hullTop + h * 0.02)
      ..lineTo(sx + sl, hullTop - h * 0.02)
      ..quadraticBezierTo(sx + sl * 0.97, waterline, sx + sl * 0.9, waterline + h * 0.02)
      ..lineTo(sx + sl * 0.05, waterline + h * 0.02)
      ..lineTo(sx, hullTop + h * 0.02)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = const Color(0xFF5F6B75))
      ..save()
      ..clipPath(hull)
      ..drawRect(Rect.fromLTRB(0, waterline - h * 0.03, w, h), Paint()..color = const Color(0xFFB0352B))
      ..restore()
      ..drawLine(
        Offset(sx, hullTop + h * 0.02),
        Offset(sx + sl, hullTop - h * 0.02),
        Paint()
          ..color = Palette.sail
          ..strokeWidth = 1.2,
      );
    _text(
      canvas,
      'NB 2026',
      Offset(sx + sl * 0.8, hullTop + h * 0.04),
      color: Palette.sail,
      size: 6,
      bold: true,
      center: true,
    );
    // Superstructure aft, a funnel and a mast.
    final Rect bridge = Rect.fromLTRB(sx + sl * 0.12, hullTop - h * 0.14, sx + sl * 0.34, hullTop + h * 0.01);
    canvas
      ..drawRect(bridge, Paint()..color = Palette.sail)
      ..drawRect(
        Rect.fromLTRB(bridge.left + sl * 0.03, bridge.top - h * 0.06, bridge.right - sl * 0.02, bridge.top),
        Paint()..color = Palette.sail,
      );
    for (double x = bridge.left + sl * 0.04; x < bridge.right - sl * 0.03; x += sl * 0.035) {
      canvas.drawRect(
        Rect.fromLTWH(x, bridge.top - h * 0.045, sl * 0.02, h * 0.02),
        Paint()..color = const Color(0xFF263238),
      );
    }
    final Rect funnel = Rect.fromLTRB(sx + sl * 0.2, bridge.top - h * 0.16, sx + sl * 0.27, bridge.top - h * 0.06);
    canvas
      ..drawRect(funnel, Paint()..color = Palette.buoyRed)
      ..drawRect(
        Rect.fromLTWH(funnel.left, funnel.top, funnel.width, h * 0.025),
        Paint()..color = const Color(0xFF263238),
      );
    final Offset mastTop = Offset(sx + sl * 0.55, h * 0.12);
    final Offset mastFoot = Offset(sx + sl * 0.55, hullTop);
    canvas.drawLine(
      mastFoot,
      mastTop,
      Paint()
        ..color = const Color(0xFF37474F)
        ..strokeWidth = 2,
    );
    // Dressed overall: a line of code flags bow to masthead to stern.
    final Offset bow = Offset(sx + sl, hullTop - h * 0.03);
    final Offset stern = Offset(sx, hullTop + h * 0.01);
    final Paint line = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 0.8;
    canvas
      ..drawLine(bow, mastTop, line)
      ..drawLine(mastTop, stern, line);
    const List<List<Color>> flags = <List<Color>>[
      <Color>[Color(0xFFE2463A), Colors.white],
      <Color>[Color(0xFF1E4FA3), Colors.white],
      <Color>[Color(0xFFF2C14E), Color(0xFF1E4FA3)],
      <Color>[Colors.white, Color(0xFFE2463A)],
      <Color>[Color(0xFFF2C14E), Colors.black],
      <Color>[Color(0xFF1E4FA3), Color(0xFFE2463A)],
    ];
    int f = 0;
    void dress(final Offset a, final Offset b, final int count) {
      for (int i = 1; i <= count; i++) {
        final Offset at = Offset.lerp(a, b, i / (count + 1))!;
        final List<Color> c = flags[f++ % flags.length];
        final double fs = h * 0.055;
        final Rect flag = Rect.fromLTWH(at.dx - fs / 2, at.dy, fs, fs * 0.8);
        canvas
          ..drawRect(flag, Paint()..color = c[0])
          ..drawRect(
            Rect.fromLTWH(flag.left, flag.top + flag.height * 0.33, flag.width, flag.height * 0.34),
            Paint()..color = c[1],
          );
      }
    }

    dress(bow, mastTop, 5);
    dress(mastTop, stern, 6);
    // A bow wave and a short wake.
    final Paint foam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas
      ..drawPath(
        Path()
          ..moveTo(sx + sl * 0.88, waterline + h * 0.02)
          ..quadraticBezierTo(sx + sl * 1.02, waterline - h * 0.01, sx + sl * 1.08, waterline + h * 0.04),
        foam,
      )
      ..drawLine(Offset(sx - w * 0.06, waterline + h * 0.04), Offset(sx + sl * 0.05, waterline + h * 0.025), foam);

    // The tug alongside, nearer the viewer and lower in the frame.
    final double tx = w * 0.6;
    final double tl = w * 0.3;
    final double tw = waterline + h * 0.17;
    final Path tug = Path()
      ..moveTo(tx, tw - h * 0.08)
      ..lineTo(tx + tl, tw - h * 0.11)
      ..quadraticBezierTo(tx + tl * 0.95, tw, tx + tl * 0.85, tw)
      ..lineTo(tx + tl * 0.08, tw)
      ..quadraticBezierTo(tx, tw - h * 0.02, tx, tw - h * 0.08)
      ..close();
    canvas
      ..drawPath(tug, Paint()..color = const Color(0xFF1F3A5F))
      ..drawLine(
        Offset(tx, tw - h * 0.08),
        Offset(tx + tl, tw - h * 0.11),
        Paint()
          ..color = Palette.buoyRed
          ..strokeWidth = 3,
      );
    // Wheelhouse and stack.
    final Rect house = Rect.fromLTRB(tx + tl * 0.3, tw - h * 0.2, tx + tl * 0.62, tw - h * 0.09);
    canvas
      ..drawRect(house, Paint()..color = Palette.sail)
      ..drawRect(
        Rect.fromLTWH(house.left + tl * 0.04, house.top + h * 0.02, house.width - tl * 0.08, h * 0.03),
        Paint()..color = const Color(0xFF263238),
      )
      ..drawRect(
        Rect.fromLTRB(tx + tl * 0.18, tw - h * 0.24, tx + tl * 0.26, tw - h * 0.09),
        Paint()..color = Palette.brass,
      );
    // Smoke.
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(tx + tl * 0.2 - i * w * 0.03, tw - h * 0.27 - i * h * 0.05),
        h * (0.025 + i * 0.012),
        Paint()..color = const Color(0xFF90A4AE).withValues(alpha: 0.6 - i * 0.12),
      );
    }
    // Tyre fenders over her side.
    for (double x = tx + tl * 0.1; x < tx + tl * 0.9; x += tl * 0.16) {
      canvas.drawCircle(Offset(x, tw - h * 0.05), h * 0.022, Paint()..color = const Color(0xFF1B1B1B));
    }
    // A towline up to the ship's bow.
    canvas.drawPath(
      Path()
        ..moveTo(tx + tl * 0.9, tw - h * 0.1)
        ..quadraticBezierTo(tx + tl * 0.7, waterline - h * 0.02, bow.dx - sl * 0.04, bow.dy + h * 0.03),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.rope,
    );
    Scenery.ripples(canvas, size, tw + h * 0.02);
  }

  @override
  bool shouldRepaint(final _SeaTrialsPainter oldDelegate) => false;
}

// ─── HarborWakePainter: a boat's V-shaped wake ───────────────────────────────

/// A motorboat seen from above, its V-shaped wake spreading behind it: the
/// two diverging arms at the Kelvin angle, the transverse waves between them
/// and the churned foam right astern, all fading with distance.
class WakeArt extends StatelessWidget {
  const WakeArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _WakePainter(), child: SizedBox.expand());
}

class _WakePainter extends CustomPainter {
  const _WakePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[Palette.shallows, Palette.sea],
        ).createShader(Offset.zero & size),
    );
    // Sun glitter on the water.
    final math.Random random = math.Random(4);
    for (int i = 0; i < 40; i++) {
      final Offset at = Offset(random.nextDouble() * w, random.nextDouble() * h);
      canvas.drawLine(
        at,
        at + const Offset(6, 0),
        Paint()
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.18),
      );
    }

    // The boat heads up and to the right; the wake trails down and left.
    final Offset bow = Offset(w * 0.74, h * 0.18);
    const double heading = -math.pi / 4.2;
    final Offset forward = Offset(math.cos(heading), math.sin(heading));
    final Offset across = Offset(-forward.dy, forward.dx);
    final double boatLen = h * 0.24;
    final Offset stern = bow - forward * boatLen;
    final double reach = math.sqrt(w * w + h * h);
    const double kelvin = 19.47 * math.pi / 180;

    // The two diverging arms, as cusps of short crests that fade astern.
    for (final double side in <double>[-1, 1]) {
      final Offset arm = -forward * math.cos(kelvin) + across * side * math.sin(kelvin);
      for (double d = 6; d < reach * 0.8; d += 7) {
        final double fade = (1 - d / (reach * 0.8)).clamp(0.0, 1.0);
        final Offset at = stern + arm * d;
        final Offset crest = forward * 0.35 + across * side;
        final double len = 4 + d * 0.06;
        canvas.drawLine(
          at,
          at + crest / crest.distance * len,
          Paint()
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: 0.75 * fade),
        );
      }
    }
    // Transverse waves: arcs across the V, wider astern.
    for (double d = 18; d < reach * 0.6; d += 16) {
      final double fade = (1 - d / (reach * 0.6)).clamp(0.0, 1.0);
      final Offset mid = stern - forward * d;
      final double half = d * math.tan(kelvin) * 0.9;
      final Offset a = mid + across * half;
      final Offset b = mid - across * half;
      final Offset ctrl = mid + forward * (half * 0.25);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.35 * fade),
      );
    }
    // Churned prop wash right astern.
    for (int i = 0; i < 18; i++) {
      final double d = random.nextDouble() * boatLen * 1.4;
      final Offset at = stern - forward * d + across * (random.nextDouble() - 0.5) * (6 + d * 0.25);
      canvas.drawCircle(
        at,
        1.5 + random.nextDouble() * 2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.7 - d / (boatLen * 2.4)),
      );
    }

    // The boat: a white hull from above, a blue deck and a windscreen.
    final double beam = boatLen * 0.34;
    final Path hull = Path()
      ..moveTo(bow.dx, bow.dy)
      ..quadraticBezierTo(
        (bow - forward * boatLen * 0.35 + across * beam * 0.62).dx,
        (bow - forward * boatLen * 0.35 + across * beam * 0.62).dy,
        (stern + across * beam / 2).dx,
        (stern + across * beam / 2).dy,
      )
      ..lineTo((stern - across * beam / 2).dx, (stern - across * beam / 2).dy)
      ..quadraticBezierTo(
        (bow - forward * boatLen * 0.35 - across * beam * 0.62).dx,
        (bow - forward * boatLen * 0.35 - across * beam * 0.62).dy,
        bow.dx,
        bow.dy,
      )
      ..close();
    canvas
      ..drawPath(hull.shift(const Offset(2, 3)), Paint()..color = Colors.black26)
      ..drawPath(hull, Paint()..color = Colors.white)
      ..drawPath(
        hull,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF90A4AE),
      );
    final Offset cockpit = stern + forward * boatLen * 0.32;
    canvas
      ..drawCircle(cockpit, beam * 0.26, Paint()..color = const Color(0xFF3D5A98))
      ..drawLine(
        cockpit + forward * beam * 0.45 + across * beam * 0.3,
        cockpit + forward * beam * 0.45 - across * beam * 0.3,
        Paint()
          ..strokeWidth = 2.4
          ..color = const Color(0xFF263238),
      )
      // A bow wave either side.
      ..drawArc(
        Rect.fromCircle(center: bow - forward * 4, radius: beam * 0.55),
        heading + math.pi * 0.55,
        math.pi * 0.9,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: 0.8),
      );
  }

  @override
  bool shouldRepaint(final _WakePainter oldDelegate) => false;
}
