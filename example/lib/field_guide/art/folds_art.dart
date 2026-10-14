import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// A canal lock's mitre gates seen from downstream: two oak leaves hung on iron hinges in the
/// stone walls, meeting in the middle, with their balance beams out over the paving.
class LockGatesArt extends StatelessWidget {
  const LockGatesArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _LockGatesPainter(), child: SizedBox.expand());
}

class _LockGatesPainter extends CustomPainter {
  const _LockGatesPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.78;
    Scenery.sky(canvas, size, h * 0.4);
    Scenery.water(canvas, size, waterline);
    // The lock's walls either side, and the paving the beams swing over.
    final double wall = w * 0.16;
    Scenery.quayWall(canvas, Rect.fromLTRB(0, h * 0.34, wall, h));
    Scenery.quayWall(canvas, Rect.fromLTRB(w - wall, h * 0.34, w, h));
    // The two leaves, a little apart where they mitre, holding the higher water behind them.
    final double top = h * 0.38;
    final double mid = w / 2;
    final Paint oak = Paint()..color = Palette.plank;
    final Paint frame = Paint()
      ..color = Palette.plankDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final bool left in <bool>[true, false]) {
      final Rect leaf = left ? Rect.fromLTRB(wall, top, mid - 1.5, h * 0.96) : Rect.fromLTRB(mid + 1.5, top, w - wall, h * 0.96);
      canvas
        ..drawRect(leaf, oak)
        ..drawRect(leaf, frame);
      // Planks and a diagonal brace.
      for (int i = 1; i < 4; i++) {
        final double y = leaf.top + leaf.height * i / 4;
        canvas.drawLine(Offset(leaf.left, y), Offset(leaf.right, y), frame);
      }
      canvas.drawLine(left ? leaf.bottomLeft : leaf.bottomRight, left ? leaf.topRight : leaf.topLeft, frame);
      // The paddle gear on top, and the balance beam out over the wall.
      final double beamY = top - h * 0.04;
      canvas.drawRect(
        left ? Rect.fromLTRB(2, beamY, mid - 6, beamY + h * 0.05) : Rect.fromLTRB(mid + 6, beamY, w - 2, beamY + h * 0.05),
        Paint()..color = Palette.sail,
      );
      // The hinges: iron straps where each leaf hangs on its wall.
      final Paint iron = Paint()..color = const Color(0xFF263238);
      for (final double f in <double>[0.2, 0.75]) {
        final double y = leaf.top + leaf.height * f;
        canvas
          ..drawRect(left ? Rect.fromLTWH(wall - 4, y, w * 0.12, 5) : Rect.fromLTWH(w - wall - w * 0.12 + 4, y, w * 0.12, 5), iron)
          ..drawCircle(Offset(left ? wall - 2 : w - wall + 2, y + 2.5), 4.5, iron);
      }
    }
    // Water spurting through the mitre, as it does from a gate under load.
    canvas.drawLine(
      Offset(mid, top + 4),
      Offset(mid, h * 0.96),
      Paint()
        ..color = Palette.foam.withValues(alpha: 0.7)
        ..strokeWidth = 1.5,
    );
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _LockGatesPainter oldDelegate) => false;
}

/// A pair of locks side by side from above, a boat in each chamber and a stone wall between them:
/// two chambers, worked apart.
class TwinLocksArt extends StatelessWidget {
  const TwinLocksArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _TwinLocksPainter(), child: SizedBox.expand());
}

class _TwinLocksPainter extends CustomPainter {
  const _TwinLocksPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    // Grass and paving all round.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF6D8F4E));
    final Rect works = Rect.fromLTRB(w * 0.06, 0, w * 0.94, h);
    canvas.drawRect(works, Paint()..color = Palette.stone);
    // Two chambers either side of the middle wall, one fuller than the other.
    final double wall = w * 0.07;
    final Rect left = Rect.fromLTRB(works.left + w * 0.05, h * 0.08, w / 2 - wall / 2, h * 0.92);
    final Rect right = Rect.fromLTRB(w / 2 + wall / 2, h * 0.08, works.right - w * 0.05, h * 0.92);
    canvas
      ..drawRect(left, Paint()..color = Palette.shallows)
      ..drawRect(right, Paint()..color = Palette.sea)
      ..drawRect(Rect.fromLTRB(left.right, 0, right.left, h), Paint()..color = Palette.stoneDark);
    // Gates at each end of each chamber.
    final Paint gate = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 3;
    for (final Rect chamber in <Rect>[left, right]) {
      for (final double y in <double>[chamber.top, chamber.bottom]) {
        final double dy = y == chamber.top ? 6 : -6;
        canvas
          ..drawLine(Offset(chamber.left, y), Offset(chamber.center.dx, y + dy), gate)
          ..drawLine(Offset(chamber.right, y), Offset(chamber.center.dx, y + dy), gate);
      }
    }
    // A narrowboat in each, bows the same way.
    void boat(final Rect chamber, final Color hull) {
      final Rect body = Rect.fromCenter(center: chamber.center, width: chamber.width * 0.5, height: chamber.height * 0.62);
      canvas
        ..drawRRect(RRect.fromRectAndRadius(body, Radius.circular(body.width / 2)), Paint()..color = hull)
        ..drawRect(body.deflate(body.width * 0.18).translate(0, body.height * 0.06), Paint()..color = Palette.sail);
    }

    boat(left, Palette.hulls[1]);
    boat(right, Palette.hulls[0]);
  }

  @override
  bool shouldRepaint(final _TwinLocksPainter oldDelegate) => false;
}

/// A ship's logbook lying open on the chart table, its spine down the middle, and a pair of
/// dividers on the facing page: held like a book.
class LogbookArt extends StatelessWidget {
  const LogbookArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _LogbookPainter(), child: SizedBox.expand());
}

class _LogbookPainter extends CustomPainter {
  const _LogbookPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    // The chart table: a sea chart under the book.
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.plankDark);
    final Rect chart = Rect.fromLTRB(w * 0.04, h * 0.06, w * 0.96, h * 0.94);
    canvas.drawRect(chart, Paint()..color = const Color(0xFFE9DFC4));
    final Paint depth = Paint()
      ..color = Palette.shallows.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 1; i < 4; i++) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.8, h * 0.85), width: w * 0.25 * i, height: h * 0.25 * i), depth);
    }
    // The book: two pages rising to the spine, half open.
    final double spine = w / 2;
    final double top = h * 0.18;
    final double bottom = h * 0.84;
    final Paint page = Paint()..color = Palette.sail;
    final Paint shade = Paint()
      ..shader = const LinearGradient(colors: <Color>[Color(0x00000000), Color(0x55000000)]).createShader(Rect.fromLTRB(spine - w * 0.08, top, spine, bottom));
    for (final bool left in <bool>[true, false]) {
      final double outer = left ? w * 0.14 : w * 0.86;
      final Path leaf = Path()
        ..moveTo(spine, top + 4)
        ..quadraticBezierTo((spine + outer) / 2, top - h * 0.06, outer, top)
        ..lineTo(outer, bottom)
        ..quadraticBezierTo((spine + outer) / 2, bottom - h * 0.06, spine, bottom + 4)
        ..close();
      canvas.drawPath(leaf, page);
      // Ruled lines of the log.
      final Paint rule = Paint()
        ..color = Palette.shallows.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      for (int i = 1; i < 7; i++) {
        final double y = top + (bottom - top) * i / 7;
        canvas.drawLine(Offset(left ? outer + 6 : spine + 8, y), Offset(left ? spine - 8 : outer - 6, y), rule);
      }
    }
    canvas
      ..drawRect(Rect.fromLTRB(spine - w * 0.08, top, spine, bottom), shade)
      ..drawLine(
        Offset(spine, top + 4),
        Offset(spine, bottom + 4),
        Paint()
          ..color = Palette.plankDark
          ..strokeWidth = 1.5,
      );
    // Brass dividers on the right page.
    final Paint brass = Paint()
      ..color = Palette.brass
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final Offset hinge = Offset(w * 0.68, h * 0.3);
    canvas
      ..drawLine(hinge, Offset(w * 0.6, h * 0.72), brass)
      ..drawLine(hinge, Offset(w * 0.78, h * 0.7), brass)
      ..drawCircle(hinge, 3.5, Paint()..color = Palette.brass);
  }

  @override
  bool shouldRepaint(final _LogbookPainter oldDelegate) => false;
}

/// A berth on the quay marked out in yellow and signed RESERVED, with nobody tied up in it yet:
/// space held for a boat that is coming.
class ReservedBerthArt extends StatelessWidget {
  const ReservedBerthArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _ReservedBerthPainter(), child: SizedBox.expand());
}

class _ReservedBerthPainter extends CustomPainter {
  const _ReservedBerthPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.62;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    // The quay along the bottom, its face to the water.
    final double top = h * 0.7;
    Scenery.quayWall(canvas, Rect.fromLTRB(0, top, w, h));
    Scenery.bollard(canvas, Offset(w * 0.18, top), h * 0.07);
    Scenery.bollard(canvas, Offset(w * 0.82, top), h * 0.07);
    // The berth: a yellow box painted on the water's edge between the bollards, empty.
    final Rect berth = Rect.fromLTRB(w * 0.24, h * 0.38, w * 0.76, top);
    final Paint yellow = Paint()
      ..color = const Color(0xFFF2C14E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(berth, yellow);
    for (double x = berth.left; x < berth.right; x += 14) {
      canvas.drawLine(Offset(x, top - 3), Offset(x + 7, top - 3), yellow);
    }
    // The sign on a post.
    final Offset post = Offset(w * 0.5, h * 0.36);
    canvas.drawRect(Rect.fromLTWH(post.dx - 1.5, post.dy, 3, top - post.dy), Paint()..color = Palette.plankDark);
    final Rect sign = Rect.fromCenter(center: post.translate(0, -h * 0.08), width: w * 0.42, height: h * 0.16);
    canvas.drawRRect(RRect.fromRectAndRadius(sign, const Radius.circular(3)), Paint()..color = Palette.sail);
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: 'RESERVED',
        style: TextStyle(color: Palette.buoyRed, fontWeight: FontWeight.w900, fontSize: sign.height * 0.55, letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: sign.width);
    text.paint(canvas, sign.center - Offset(text.width / 2, text.height / 2));
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _ReservedBerthPainter oldDelegate) => false;
}
