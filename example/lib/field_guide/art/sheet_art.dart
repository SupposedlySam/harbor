import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Brushes shared by the sheets plates.
abstract final class _Rigging {
  static final Paint wire = Paint()
    ..color = const Color(0xFF455A64)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1;

  static void label(final Canvas canvas, final String text, final Offset at, {final Color color = Palette.plankDark, final double size = 10}) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  /// A sail as a curved triangle with seams, from [head] to [tack] to [clew].
  static void sail(final Canvas canvas, final Offset head, final Offset tack, final Offset clew, {final double belly = 0.12}) {
    final Offset mid = Offset.lerp(head, clew, 0.5)!;
    final Offset out = Offset(mid.dx + (clew.dx - tack.dx) * belly, mid.dy - (clew.dy - head.dy) * belly * 0.3);
    final Path path = Path()
      ..moveTo(head.dx, head.dy)
      ..lineTo(tack.dx, tack.dy)
      ..quadraticBezierTo((tack.dx + clew.dx) / 2, (tack.dy + clew.dy) / 2 + 4, clew.dx, clew.dy)
      ..quadraticBezierTo(out.dx, out.dy, head.dx, head.dy)
      ..close();
    final Rect bounds = path.getBounds();
    canvas
      ..drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(colors: <Color>[Color(0xFFFFFFFF), Color(0xFFE3DCCB)]).createShader(bounds),
      )
      ..drawPath(path, Paint()
        ..color = const Color(0xFFB9AE93)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    // Seams across the sail, from the luff to the leech.
    final Paint seam = Paint()
      ..color = const Color(0xFFCFC5AE)
      ..strokeWidth = 0.8;
    for (int i = 1; i < 6; i++) {
      final double t = i / 6;
      final Offset luff = Offset.lerp(head, tack, t)!;
      final Offset leech = Offset.lerp(head, clew, t)!;
      canvas.drawLine(luff, leech, seam);
    }
  }

  /// A sailboat hull at [waterline], [length] long, its bow to the right.
  static void hull(final Canvas canvas, final double x, final double waterline, final double length, final Color color) {
    final double depth = length * 0.13;
    final Path path = Path()
      ..moveTo(x, waterline - depth)
      ..lineTo(x + length, waterline - depth * 1.3)
      ..quadraticBezierTo(x + length * 0.88, waterline + depth * 0.2, x + length * 0.7, waterline + depth * 0.3)
      ..lineTo(x + length * 0.12, waterline + depth * 0.3)
      ..quadraticBezierTo(x + 2, waterline, x, waterline - depth)
      ..close();
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawLine(Offset(x, waterline - depth), Offset(x + length, waterline - depth * 1.3), Paint()
        ..color = Colors.white
        ..strokeWidth = 2);
  }
}

/// A sailboat with its sail set and the sheet, the line that trims it, run
/// from the sail's clew back to a winch in the cockpit.
class SailSheetArt extends StatelessWidget {
  const SailSheetArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SailSheetPainter(), child: SizedBox.expand());
}

class _SailSheetPainter extends CustomPainter {
  const _SailSheetPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.8;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);

    final double x = w * 0.18;
    final double length = w * 0.62;
    final Offset mastFoot = Offset(x + length * 0.42, waterline - length * 0.13);
    final Offset masthead = Offset(mastFoot.dx, h * 0.06);
    // Shrouds and forestay.
    canvas
      ..drawLine(masthead, Offset(x + length * 0.98, waterline - length * 0.17), _Rigging.wire)
      ..drawLine(masthead, Offset(x + 6, waterline - length * 0.13), _Rigging.wire);
    // The mainsail on the boom, and the jib on the forestay.
    final Offset boomEnd = Offset(x + length * 0.02, mastFoot.dy - h * 0.08);
    _Rigging.sail(canvas, masthead + const Offset(-2, 4), mastFoot - Offset(2, h * 0.08), boomEnd, belly: -0.1);
    _Rigging.sail(canvas, masthead + const Offset(4, 12), Offset(x + length * 0.96, waterline - length * 0.18), Offset(x + length * 0.6, waterline - length * 0.16 - 4), belly: 0.08);
    canvas
      ..drawLine(mastFoot - Offset(0, h * 0.08), boomEnd, Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round)
      ..drawLine(mastFoot, masthead, Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 3.6);
    _Rigging.hull(canvas, x, waterline, length, Palette.hulls[3]);

    // The jib sheet: from the jib's clew back to a winch on the cabin top, then its tail coiled.
    final Offset clew = Offset(x + length * 0.6, waterline - length * 0.16 - 4);
    final Offset winch = Offset(x + length * 0.3, waterline - length * 0.15);
    final Paint sheet = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(clew.dx, clew.dy)
          ..quadraticBezierTo((clew.dx + winch.dx) / 2, clew.dy + 8, winch.dx, winch.dy),
        sheet,
      )
      ..drawRect(Rect.fromCenter(center: winch - const Offset(0, 3), width: 9, height: 8), Paint()..color = const Color(0xFF9E9E9E))
      ..drawOval(Rect.fromCenter(center: winch + const Offset(-14, 2), width: 14, height: 5), sheet..strokeWidth = 1.6)
      ..drawOval(Rect.fromCenter(center: winch + const Offset(-14, 1), width: 10, height: 3.6), sheet);
    // The main sheet from the boom end down to the transom.
    canvas.drawLine(boomEnd, Offset(boomEnd.dx + 4, waterline - length * 0.13), sheet..strokeWidth = 1.8);
    _Rigging.label(canvas, 'sheet', Offset((clew.dx + winch.dx) / 2 - 8, clew.dy + 8), color: const Color(0xFFBF360C));
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _SailSheetPainter oldDelegate) => false;
}

/// Two masts side by side: on the left a sail hauled up its halyard only to
/// a reef, on the right hoisted full, with the heights marked.
class HalyardArt extends StatelessWidget {
  const HalyardArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _HalyardPainter(), child: SizedBox.expand());
}

class _HalyardPainter extends CustomPainter {
  const _HalyardPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.88;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    final double boom = h * 0.78;
    final double top = h * 0.07;
    // Height marks across the frame: max, rest, min.
    final Paint dash = Paint()
      ..color = Palette.plankDark.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final Map<String, double> marks = <String, double>{'max': top + 6, 'rest': h * 0.4, 'min': h * 0.62};
    for (final MapEntry<String, double> mark in marks.entries) {
      for (double x = w * 0.04; x < w * 0.96; x += 9) {
        canvas.drawLine(Offset(x, mark.value), Offset(x + 5, mark.value), dash);
      }
      _Rigging.label(canvas, mark.key, Offset(w * 0.9, mark.value - 12));
    }

    void rig(final double mastX, final double headY, {required final bool reefed}) {
      final Offset foot = Offset(mastX, boom);
      final Offset sheave = Offset(mastX, top);
      final Offset boomEnd = Offset(mastX + w * 0.24, boom);
      // Sail below the reef: bundled on the boom with reef points.
      if (reefed) {
        final Rect bundle = Rect.fromLTRB(mastX + 2, boom - 9, boomEnd.dx - 4, boom);
        canvas.drawRRect(RRect.fromRectAndRadius(bundle, const Radius.circular(4)), Paint()..color = const Color(0xFFE3DCCB));
        for (double x = bundle.left + 8; x < bundle.right - 4; x += 10) {
          canvas.drawLine(Offset(x, bundle.top - 3), Offset(x, bundle.bottom), Paint()
            ..color = Palette.plankDark
            ..strokeWidth = 1);
        }
      }
      final double sailFoot = reefed ? boom - 9 : boom;
      _Rigging.sail(canvas, Offset(mastX + 2, headY), Offset(mastX + 2, sailFoot), Offset(boomEnd.dx - (reefed ? 6 : 0), sailFoot), belly: 0.14);
      // Mast, boom, and the halyard: over the sheave at the masthead and down the mast to a cleat.
      canvas
        ..drawLine(Offset(mastX, waterline - 6), sheave, Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 4)
        ..drawLine(foot, boomEnd, Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round)
        ..drawCircle(sheave, 3.2, Paint()..color = const Color(0xFF9E9E9E));
      final Paint halyard = Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas
        ..drawLine(sheave + const Offset(2, 0), Offset(mastX + 2, headY), halyard)
        ..drawLine(sheave - const Offset(2, 0), Offset(mastX - 4, boom + 10), halyard)
        ..drawRect(Rect.fromCenter(center: Offset(mastX - 4, boom + 12), width: 8, height: 3), Paint()..color = const Color(0xFF9E9E9E));
      _Rigging.hull(canvas, mastX - w * 0.08, waterline, w * 0.38, reefed ? Palette.hulls[1] : Palette.hulls[0]);
    }

    rig(w * 0.16, marks['rest']!, reefed: true);
    rig(w * 0.58, marks['max']!, reefed: false);
    _Rigging.label(canvas, 'halyard', Offset(w * 0.58 + 6, h * 0.24), color: const Color(0xFFBF360C));
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _HalyardPainter oldDelegate) => false;
}

/// A rock breakwater across the harbor mouth: the swell breaks white on its
/// seaward side, and the water behind it lies calm round the moored boats.
class BreakwaterArt extends StatelessWidget {
  const BreakwaterArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _BreakwaterPainter(), child: SizedBox.expand());
}

class _BreakwaterPainter extends CustomPainter {
  const _BreakwaterPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.22;
    Scenery.sky(canvas, size, horizon);
    // Seen from above the harbor: the rough sea beyond, the breakwater, the calm harbor in front.
    final double wall = h * 0.5;
    final Rect open = Rect.fromLTRB(0, horizon, w, wall);
    canvas.drawRect(
      open,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1C5C86), Color(0xFF0F3E61)],
        ).createShader(open),
    );
    // The swell rolling in.
    final Paint swell = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    for (int row = 0; row < 3; row++) {
      final double y = horizon + 10 + row * (wall - horizon - 20) / 3;
      final Path path = Path()..moveTo(0, y);
      for (double x = 0; x <= w; x += 4) {
        path.lineTo(x, y - math.max(0.0, math.sin(x / 22 + row * 2)) * 6);
      }
      canvas.drawPath(path, swell);
    }
    // The calm harbor.
    final Rect calm = Rect.fromLTRB(0, wall, w, h);
    canvas.drawRect(
      calm,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Color(0xFF3B9CC8)],
        ).createShader(calm),
    );
    // A quay along the bottom.
    Scenery.quayWall(canvas, Rect.fromLTRB(0, h * 0.9, w, h));
    // The breakwater: a long mound of boulders running in from the left, leaving a mouth on the right.
    final math.Random random = math.Random(11);
    final double end = w * 0.78;
    for (int layer = 0; layer < 2; layer++) {
      for (double x = -6; x < end; x += 9 + random.nextDouble() * 6) {
        final double r = 7 + random.nextDouble() * 6 - layer * 2;
        final Offset c = Offset(x, wall - 4 + layer * 6 + random.nextDouble() * 4);
        canvas
          ..drawOval(Rect.fromCenter(center: c, width: r * 2.2, height: r * 1.5), Paint()..color = Color.lerp(Palette.stone, Palette.stoneDark, random.nextDouble())!)
          ..drawOval(Rect.fromCenter(center: c - Offset(r * 0.3, r * 0.3), width: r * 0.9, height: r * 0.5), Paint()..color = Colors.white.withValues(alpha: 0.18));
      }
    }
    // The light at its end.
    final Offset head = Offset(end + 6, wall - 6);
    canvas
      ..drawRect(Rect.fromLTRB(head.dx - 4, head.dy - 24, head.dx + 4, head.dy), Paint()..color = Palette.buoyRed)
      ..drawRect(Rect.fromLTRB(head.dx - 5, head.dy - 28, head.dx + 5, head.dy - 24), Paint()..color = const Color(0xFF263238))
      ..drawCircle(head - const Offset(0, 30), 3, Paint()..color = const Color(0xFFFFE08A));
    // Spray where the swell breaks on the seaward face.
    final Paint spray = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (int i = 0; i < 40; i++) {
      final double x = random.nextDouble() * end;
      final double y = wall - 10 - random.nextDouble() * 14;
      canvas.drawCircle(Offset(x, y), 1 + random.nextDouble() * 2.4, spray);
    }
    // Boats lying quietly in the shelter, with their reflections.
    Scenery.rowboat(canvas, Offset(w * 0.25, h * 0.7), w * 0.12, Palette.hulls[0]);
    Scenery.rowboat(canvas, Offset(w * 0.5, h * 0.76), w * 0.14, Palette.hulls[2]);
    Scenery.rowboat(canvas, Offset(w * 0.7, h * 0.66), w * 0.1, Palette.hulls[4]);
    final Paint still = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final Offset at in <Offset>[Offset(w * 0.25, h * 0.74), Offset(w * 0.5, h * 0.81), Offset(w * 0.7, h * 0.7)]) {
      canvas.drawLine(at - const Offset(14, 0), at + const Offset(14, 0), still);
    }
  }

  @override
  bool shouldRepaint(final _BreakwaterPainter oldDelegate) => false;
}

/// The harbor master's office on the quay: a hip roof above, a counter sill
/// below, and its window between them, where the radio call is taken.
class HarborOfficeArt extends StatelessWidget {
  const HarborOfficeArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _OfficePainter(), child: SizedBox.expand());
}

class _OfficePainter extends CustomPainter {
  const _OfficePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double ground = h * 0.86;
    Scenery.sky(canvas, size, ground);
    Scenery.water(canvas, size, ground);
    Scenery.quayWall(canvas, Rect.fromLTRB(0, ground - 6, w, h));

    // The office: white clapboard walls.
    final Rect walls = Rect.fromLTRB(w * 0.22, h * 0.3, w * 0.78, ground - 6);
    canvas.drawRect(walls, Paint()..color = const Color(0xFFF2EEE4));
    for (double y = walls.top + 6; y < walls.bottom; y += 7) {
      canvas.drawLine(Offset(walls.left, y), Offset(walls.right, y), Paint()
        ..color = const Color(0xFFD6D0C2)
        ..strokeWidth = 1);
    }
    // The roof (the header) with its eaves, and a radio mast with a wind sock.
    final Path roof = Path()
      ..moveTo(walls.left - 14, walls.top)
      ..lineTo(walls.left + 20, h * 0.12)
      ..lineTo(walls.right - 20, h * 0.12)
      ..lineTo(walls.right + 14, walls.top)
      ..close();
    canvas
      ..drawPath(roof, Paint()..color = const Color(0xFF2E5E4E))
      ..drawRect(Rect.fromLTRB(walls.left - 14, walls.top - 3, walls.right + 14, walls.top + 2), Paint()..color = const Color(0xFF1F4236));
    final Offset mastFoot = Offset(walls.right - 30, h * 0.12);
    canvas.drawLine(mastFoot, mastFoot - Offset(0, h * 0.11), Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.6);
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(Rect.fromCircle(center: mastFoot - Offset(0, h * 0.11), radius: 4.0 + i * 4), -2.4, 1.6, false, Paint()
        ..color = Palette.buoyRed.withValues(alpha: 0.7 - i * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }
    final TextPainter sign = TextPainter(
      text: TextSpan(text: 'HARBOR MASTER', style: TextStyle(color: Palette.brass, fontSize: h * 0.05, fontWeight: FontWeight.w800, letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    sign.paint(canvas, Offset(walls.center.dx - sign.width / 2, h * 0.16));

    // The window: frame, the room inside, the harbor master at the radio.
    final Rect window = Rect.fromLTRB(walls.left + w * 0.06, walls.top + h * 0.08, walls.right - w * 0.06, walls.bottom - h * 0.16);
    canvas
      ..drawRect(window.inflate(4), Paint()..color = const Color(0xFF2E5E4E))
      ..drawRect(window, Paint()..color = const Color(0xFF263D4F));
    // Inside: a radio set on the desk with its dial lit, and a figure in a cap.
    final Rect radio = Rect.fromLTWH(window.left + window.width * 0.56, window.bottom - window.height * 0.36, window.width * 0.32, window.height * 0.3);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(radio, const Radius.circular(3)), Paint()..color = const Color(0xFF5D4037))
      ..drawCircle(radio.center + Offset(-radio.width * 0.2, 0), radio.height * 0.22, Paint()..color = const Color(0xFFFFE08A))
      ..drawRect(Rect.fromLTWH(radio.center.dx + 2, radio.top + 5, radio.width * 0.3, radio.height * 0.18), Paint()..color = const Color(0xFF9CCC65));
    final Offset head = Offset(window.left + window.width * 0.3, window.top + window.height * 0.42);
    canvas
      ..drawPath(
        Path()
          ..moveTo(head.dx - window.width * 0.14, window.bottom)
          ..quadraticBezierTo(head.dx - window.width * 0.13, head.dy + 12, head.dx, head.dy + 10)
          ..quadraticBezierTo(head.dx + window.width * 0.13, head.dy + 12, head.dx + window.width * 0.14, window.bottom)
          ..close(),
        Paint()..color = const Color(0xFF1A2A6C),
      )
      ..drawCircle(head, window.height * 0.13, Paint()..color = const Color(0xFFE0B48A))
      ..drawRect(Rect.fromCenter(center: head - Offset(0, window.height * 0.1), width: window.height * 0.3, height: window.height * 0.07), Paint()..color = const Color(0xFF1A2A6C));
    // Mullions over the glass and a glint.
    final Paint mullion = Paint()
      ..color = const Color(0xFF2E5E4E)
      ..strokeWidth = 3;
    canvas
      ..drawLine(Offset(window.center.dx, window.top), Offset(window.center.dx, window.bottom), mullion)
      ..drawLine(Offset(window.left, window.center.dy - window.height * 0.2), Offset(window.right, window.center.dy - window.height * 0.2), mullion)
      ..drawLine(window.topLeft + const Offset(8, 22), window.topLeft + const Offset(22, 8), Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 3);
    // The sill (the footer) under it, and a door and a life ring.
    canvas
      ..drawRect(Rect.fromLTRB(window.left - 10, window.bottom + 4, window.right + 10, window.bottom + 11), Paint()..color = const Color(0xFF8A5A33))
      ..drawCircle(Offset(walls.left + 14, walls.center.dy + 6), 8, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4);
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(Rect.fromCircle(center: Offset(walls.left + 14, walls.center.dy + 6), radius: 8), i * math.pi / 2, math.pi / 4, false, Paint()
        ..color = Palette.buoyRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4);
    }
    Scenery.bollard(canvas, Offset(w * 0.88, ground - 6), h * 0.06);
    Scenery.lamp(canvas, Offset(w * 0.1, ground - 6), h * 0.3, lit: false);
  }

  @override
  bool shouldRepaint(final _OfficePainter oldDelegate) => false;
}
