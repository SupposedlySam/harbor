import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// Brushes shared by the Afloat plates.
abstract final class _Afloat {
  /// A distant low headland on the horizon, so open water reads as open water.
  static void farShore(final Canvas canvas, final Size size, final double horizon) {
    final Path land = Path()
      ..moveTo(size.width * 0.55, horizon)
      ..quadraticBezierTo(size.width * 0.7, horizon - size.height * 0.05, size.width * 0.82, horizon - size.height * 0.03)
      ..quadraticBezierTo(size.width * 0.92, horizon - size.height * 0.06, size.width, horizon - size.height * 0.02)
      ..lineTo(size.width, horizon)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF6F8FA0));
  }

  /// A gull in flight: two arcs.
  static void gull(final Canvas canvas, final Offset at, final double span) {
    final Paint ink = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final Path wings = Path()
      ..moveTo(at.dx - span / 2, at.dy)
      ..quadraticBezierTo(at.dx - span / 4, at.dy - span * 0.35, at.dx, at.dy)
      ..quadraticBezierTo(at.dx + span / 4, at.dy - span * 0.35, at.dx + span / 2, at.dy);
    canvas.drawPath(wings, ink);
  }

  /// A wobbly reflection under something floating at [x], [width] wide.
  static void reflection(final Canvas canvas, final double x, final double waterline, final double width, final Color color) {
    final Paint paint = Paint()..color = color.withValues(alpha: 0.35);
    for (int i = 0; i < 4; i++) {
      final double y = waterline + 4 + i * 5.0;
      final double half = width / 2 * (1 - i * 0.18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x - half + (i.isEven ? 2 : -2), y, x + half, y + 2.4), const Radius.circular(1.2)),
        paint,
      );
    }
  }
}

/// A red can buoy floating free in open water: a cylinder with a flat top, its
/// number painted on, nothing near it but water.
class HarborBuoyArt extends StatelessWidget {
  const HarborBuoyArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _CanBuoyPainter(), child: SizedBox.expand());
}

class _CanBuoyPainter extends CustomPainter {
  const _CanBuoyPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.42;
    Scenery.sky(canvas, size, horizon);
    _Afloat.farShore(canvas, size, horizon);
    Scenery.water(canvas, size, horizon);
    _Afloat.gull(canvas, Offset(w * 0.2, h * 0.16), 18);
    _Afloat.gull(canvas, Offset(w * 0.3, h * 0.24), 12);

    // The buoy sits a little left of center, riding the swell slightly tilted.
    final double waterline = h * 0.74;
    final double cx = w * 0.42;
    final double bw = h * 0.26;
    final double bh = h * 0.36;
    _Afloat.reflection(canvas, cx, waterline, bw * 1.3, Palette.buoyRed);
    canvas
      ..save()
      ..translate(cx, waterline)
      ..rotate(-0.06);
    final Rect body = Rect.fromLTRB(-bw / 2, -bh, bw / 2, 0);
    // The can: a red cylinder, lit from the left.
    canvas.drawRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFFF7A6B), Palette.buoyRed, Color(0xFF9E2A20)],
          stops: <double>[0.0, 0.45, 1.0],
        ).createShader(body),
    );
    // Its flat top, an ellipse.
    final Rect top = Rect.fromCenter(center: Offset(0, -bh), width: bw, height: bw * 0.28);
    canvas
      ..drawOval(top, Paint()..color = const Color(0xFFB8352B))
      ..drawOval(
        top,
        Paint()
          ..color = const Color(0xFF7A1F18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    // A reflective band and the number.
    canvas.drawRect(Rect.fromLTRB(-bw / 2, -bh * 0.82, bw / 2, -bh * 0.74), Paint()..color = const Color(0xFFF4F4F4));
    final TextPainter number = TextPainter(
      text: TextSpan(
        text: '2',
        style: TextStyle(color: Colors.white, fontSize: bh * 0.34, fontWeight: FontWeight.w800, fontFamily: 'Helvetica'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    number.paint(canvas, Offset(-number.width / 2, -bh * 0.62));
    // A lifting eye on top.
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, -bh - 2), width: bw * 0.3, height: bw * 0.3),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF424242)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
    // Water lapping round its foot.
    final Paint foam = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas
      ..drawArc(Rect.fromCenter(center: Offset(cx, waterline), width: bw * 1.5, height: 8), 0.1, math.pi - 0.2, false, foam)
      ..drawArc(Rect.fromCenter(center: Offset(cx, waterline + 4), width: bw * 2.1, height: 10), 0.3, math.pi - 0.6, false, foam);
    Scenery.ripples(canvas, size, waterline + 10);
  }

  @override
  bool shouldRepaint(final _CanBuoyPainter oldDelegate) => false;
}

/// A mooring buoy, cut away below the surface: the buoy afloat, its chain
/// hanging down to an anchor dug into the seabed.
class MooringBuoyArt extends StatelessWidget {
  const MooringBuoyArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _MooringPainter(), child: SizedBox.expand());
}

class _MooringPainter extends CustomPainter {
  const _MooringPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.3;
    Scenery.sky(canvas, size, waterline);
    // Deeper water: darker toward the bottom.
    final Rect sea = Rect.fromLTWH(0, waterline, w, h - waterline);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Palette.sea, Palette.deepSea],
        ).createShader(sea),
    );
    // Sun shafts in the water.
    for (int i = 0; i < 3; i++) {
      final double x = w * (0.15 + i * 0.25);
      final Path shaft = Path()
        ..moveTo(x, waterline)
        ..lineTo(x + w * 0.06, waterline)
        ..lineTo(x + w * 0.16, h)
        ..lineTo(x + w * 0.04, h)
        ..close();
      canvas.drawPath(shaft, Paint()..color = Colors.white.withValues(alpha: 0.05));
    }
    // The seabed: sand, a rock or two, weed.
    final double bed = h * 0.86;
    final Path sand = Path()..moveTo(0, bed + 4);
    for (double x = 0; x <= w; x += 10) {
      sand.lineTo(x, bed + math.sin(x / 30) * 3);
    }
    sand
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(sand, Paint()..color = const Color(0xFFC9B27C));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.12, bed), width: 30, height: 14), Paint()..color = Palette.stoneDark);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.86, bed + 2), width: 22, height: 10), Paint()..color = Palette.stone);
    final Paint weed = Paint()
      ..color = const Color(0xFF3E7D4F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final double x in <double>[w * 0.2, w * 0.23, w * 0.78, w * 0.92]) {
      final Path frond = Path()
        ..moveTo(x, bed)
        ..quadraticBezierTo(x - 6, bed - 14, x + 2, bed - 26)
        ..quadraticBezierTo(x + 6, bed - 34, x, bed - 40);
      canvas.drawPath(frond, weed);
    }

    // The buoy: a white sphere with a red band, half in the water.
    final Offset buoy = Offset(w * 0.36, waterline);
    final double r = h * 0.09;
    final Rect ball = Rect.fromCircle(center: buoy, radius: r);
    canvas
      ..drawCircle(
        buoy,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            colors: <Color>[Colors.white, Color(0xFFCFD8DC)],
          ).createShader(ball),
      )
      ..save()
      ..clipPath(Path()..addOval(ball))
      ..drawRect(Rect.fromLTRB(ball.left, buoy.dy - r * 0.35, ball.right, buoy.dy + r * 0.05), Paint()..color = Palette.buoyRed)
      ..restore();
    // The water surface over the bottom half (seen through the surface).
    canvas.drawRect(Rect.fromLTRB(ball.left - 2, waterline, ball.right + 2, ball.bottom + 1), Paint()..color = Palette.shallows.withValues(alpha: 0.45));
    canvas.drawLine(Offset(0, waterline), Offset(w, waterline), Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.2);
    Scenery.ripples(canvas, size, waterline);

    // The anchor, dug in, off to the right.
    final Offset anchor = Offset(w * 0.68, bed - 6);
    _anchor(canvas, anchor, h * 0.22);

    // The chain: a catenary from the buoy's bottom to the anchor's shackle, links drawn along it.
    final Offset from = Offset(buoy.dx, buoy.dy + r);
    final Offset to = anchor - Offset(0, h * 0.2);
    final Path chain = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx + 4, from.dy + h * 0.3, to.dx - w * 0.2, bed + 2, to.dx - w * 0.05, bed - 2)
      ..quadraticBezierTo(to.dx, bed - 4, to.dx, to.dy);
    for (final PathMetric metric in chain.computeMetrics()) {
      int i = 0;
      for (double d = 0; d < metric.length; d += 6, i++) {
        final Tangent? t = metric.getTangentForOffset(d);
        if (t == null) {
          continue;
        }
        canvas
          ..save()
          ..translate(t.position.dx, t.position.dy)
          ..rotate(-t.angle);
        final Paint link = Paint()
          ..color = const Color(0xFF90A4AE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        if (i.isEven) {
          canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2.5, 8, 5), const Radius.circular(2.5)), link);
        } else {
          canvas.drawLine(const Offset(-4, 0), const Offset(4, 0), link..strokeWidth = 2);
        }
        canvas.restore();
      }
    }
  }

  /// A stockless anchor: shank, crown and two flukes, drawn upright with its
  /// ring at the top, [height] tall from the crown at [crown].
  void _anchor(final Canvas canvas, final Offset crown, final double height) {
    final Paint iron = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.08
      ..strokeCap = StrokeCap.round;
    final Offset top = crown - Offset(0, height * 0.9);
    canvas
      ..drawLine(crown, top, iron)
      ..drawCircle(top - Offset(0, height * 0.06), height * 0.07, iron..strokeWidth = height * 0.05)
      ..drawLine(top + Offset(-height * 0.2, height * 0.12), top + Offset(height * 0.2, height * 0.12), iron..strokeWidth = height * 0.07);
    final Path arms = Path()
      ..moveTo(crown.dx - height * 0.38, crown.dy - height * 0.3)
      ..quadraticBezierTo(crown.dx - height * 0.3, crown.dy + height * 0.05, crown.dx, crown.dy)
      ..quadraticBezierTo(crown.dx + height * 0.3, crown.dy + height * 0.05, crown.dx + height * 0.38, crown.dy - height * 0.3);
    canvas.drawPath(arms, iron..strokeWidth = height * 0.08);
    final Paint fluke = Paint()..color = const Color(0xFF37474F);
    for (final double s in <double>[-1, 1]) {
      final Offset tip = Offset(crown.dx + s * height * 0.38, crown.dy - height * 0.3);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy - height * 0.08)
          ..lineTo(tip.dx + s * height * 0.08, tip.dy + height * 0.08)
          ..lineTo(tip.dx - s * height * 0.1, tip.dy + height * 0.06)
          ..close(),
        fluke,
      );
    }
    // Half buried: sand over the crown.
    canvas.drawOval(Rect.fromCenter(center: crown + Offset(0, height * 0.06), width: height * 0.9, height: height * 0.16), Paint()..color = const Color(0xFFC9B27C));
  }

  @override
  bool shouldRepaint(final _MooringPainter oldDelegate) => false;
}

/// The harbor master's launch coming through, its blue light flashing, the
/// other boats moving aside out of its way.
class HarborLaunchArt extends StatelessWidget {
  const HarborLaunchArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _LaunchPainter(), child: SizedBox.expand());
}

class _LaunchPainter extends CustomPainter {
  const _LaunchPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double horizon = h * 0.34;
    Scenery.sky(canvas, size, horizon);
    Scenery.shore(canvas, size, horizon, fromLeft: false, width: w * 0.2);
    Scenery.water(canvas, size, horizon);

    // The launch's V wake spreading behind it.
    final double waterline = h * 0.72;
    final Offset bow = Offset(w * 0.66, waterline);
    final Paint wake = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 3; i++) {
      final double spread = 10.0 + i * 10;
      canvas
        ..drawLine(Offset(bow.dx - w * 0.3, waterline + 2), Offset(bow.dx - w * 0.3 - w * 0.25, waterline - spread * 0.4 - 6), wake)
        ..drawLine(Offset(bow.dx - w * 0.3, waterline + 4), Offset(bow.dx - w * 0.3 - w * 0.25, waterline + spread), wake);
      wake.color = wake.color.withValues(alpha: 0.5 - i * 0.12);
    }

    // Two boats being moved aside, rocking in the wash, with arrows showing them clear the way.
    Scenery.rowboat(canvas, Offset(w * 0.86, h * 0.5), w * 0.1, Palette.hulls[2]);
    Scenery.rowboat(canvas, Offset(w * 0.84, h * 0.93), w * 0.12, Palette.hulls[1]);
    final Paint arrow = Paint()
      ..color = Palette.buoyRed.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    void moveAside(final Offset from, final Offset to) {
      canvas.drawLine(from, to, arrow);
      final double angle = (to - from).direction;
      for (final double s in <double>[-0.5, 0.5]) {
        canvas.drawLine(to, to - Offset.fromDirection(angle + s, 6), arrow);
      }
    }

    moveAside(Offset(w * 0.86, h * 0.56), Offset(w * 0.86, h * 0.44));
    moveAside(Offset(w * 0.84, h * 0.86), Offset(w * 0.84, h * 0.98));

    // The launch: a white hull with a blue sheer stripe, a wheelhouse, a blue light.
    final double len = w * 0.36;
    final double stern = bow.dx - len;
    final Path hull = Path()
      ..moveTo(stern, waterline - h * 0.1)
      ..lineTo(bow.dx - len * 0.12, waterline - h * 0.1)
      ..quadraticBezierTo(bow.dx, waterline - h * 0.12, bow.dx + len * 0.06, waterline - h * 0.13)
      ..quadraticBezierTo(bow.dx - len * 0.02, waterline, bow.dx - len * 0.18, waterline + 3)
      ..lineTo(stern + 4, waterline + 3)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = const Color(0xFFF5F5F5))
      ..drawPath(
        Path()
          ..moveTo(stern, waterline - h * 0.06)
          ..lineTo(bow.dx - len * 0.04, waterline - h * 0.07)
          ..lineTo(bow.dx - len * 0.07, waterline - h * 0.04)
          ..lineTo(stern + 1, waterline - h * 0.03)
          ..close(),
        Paint()..color = const Color(0xFF1E4E9C),
      );
    // Wheelhouse.
    final Rect house = Rect.fromLTRB(stern + len * 0.3, waterline - h * 0.24, stern + len * 0.68, waterline - h * 0.1);
    canvas.drawRRect(RRect.fromRectAndCorners(house, topLeft: const Radius.circular(3), topRight: const Radius.circular(8)), Paint()..color = Colors.white);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(house.left + 4 + i * (house.width - 8) / 3, house.top + 4, (house.width - 8) / 3 - 3, house.height * 0.38),
        Paint()..color = const Color(0xFF263238),
      );
    }
    final TextPainter label = TextPainter(
      text: TextSpan(text: 'HARBOR MASTER', style: TextStyle(color: const Color(0xFF1E4E9C), fontSize: h * 0.045, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(stern + len * 0.12, waterline - h * 0.1 + 1));
    // The blue light on its mast, flashing.
    final Offset mast = Offset(house.center.dx, house.top);
    canvas
      ..drawLine(mast, mast - Offset(0, h * 0.08), Paint()
        ..color = const Color(0xFF455A64)
        ..strokeWidth = 2)
      ..drawCircle(mast - Offset(0, h * 0.09), h * 0.07, Paint()..color = const Color(0x553D8BFF))
      ..drawCircle(mast - Offset(0, h * 0.09), h * 0.025, Paint()..color = const Color(0xFF3D8BFF));
    _Afloat.reflection(canvas, bow.dx - len / 2, waterline + 2, len * 0.8, const Color(0xFF1E4E9C));
    // Bow wave.
    canvas.drawArc(Rect.fromCenter(center: Offset(bow.dx - len * 0.1, waterline + 2), width: len * 0.3, height: 10), 3.4, 2.4, false, wake..color = Colors.white);
  }

  @override
  bool shouldRepaint(final _LaunchPainter oldDelegate) => false;
}

/// International maritime signal flags run up a halyard from a ship's
/// foredeck to its masthead.
class SignalFlagsArt extends StatelessWidget {
  const SignalFlagsArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _SignalFlagsPainter(), child: SizedBox.expand());
}

/// One flag of the international code: how to paint it in its rectangle.
typedef _FlagPainter = void Function(Canvas canvas, Rect r);

const Color _codeRed = Color(0xFFD32F2F);
const Color _codeBlue = Color(0xFF1A3D8F);
const Color _codeYellow = Color(0xFFFFD02A);
const Color _codeWhite = Color(0xFFFAFAFA);

class _SignalFlagsPainter extends CustomPainter {
  const _SignalFlagsPainter();

  static final Map<String, _FlagPainter> _flags = <String, _FlagPainter>{
    // Alpha: white and blue, swallowtailed (drawn as a rectangle with a notch).
    'A': (final Canvas c, final Rect r) {
      c
        ..drawRect(Rect.fromLTRB(r.left, r.top, r.center.dx, r.bottom), Paint()..color = _codeWhite)
        ..drawPath(
          Path()
            ..moveTo(r.center.dx, r.top)
            ..lineTo(r.right, r.top)
            ..lineTo(r.right - r.width * 0.25, r.center.dy)
            ..lineTo(r.right, r.bottom)
            ..lineTo(r.center.dx, r.bottom)
            ..close(),
          Paint()..color = _codeBlue,
        );
    },
    // Charlie: blue, white, red, white, blue bands.
    'C': (final Canvas c, final Rect r) {
      const List<Color> bands = <Color>[_codeBlue, _codeWhite, _codeRed, _codeWhite, _codeBlue];
      for (int i = 0; i < 5; i++) {
        c.drawRect(Rect.fromLTWH(r.left, r.top + r.height * i / 5, r.width, r.height / 5), Paint()..color = bands[i]);
      }
    },
    // Delta: yellow, blue, yellow.
    'D': (final Canvas c, final Rect r) {
      c
        ..drawRect(r, Paint()..color = _codeYellow)
        ..drawRect(Rect.fromLTWH(r.left, r.top + r.height / 4, r.width, r.height / 2), Paint()..color = _codeBlue);
    },
    // Echo: blue over red.
    'E': (final Canvas c, final Rect r) {
      c
        ..drawRect(Rect.fromLTRB(r.left, r.top, r.right, r.center.dy), Paint()..color = _codeBlue)
        ..drawRect(Rect.fromLTRB(r.left, r.center.dy, r.right, r.bottom), Paint()..color = _codeRed);
    },
    // Foxtrot: white with a red diamond.
    'F': (final Canvas c, final Rect r) {
      c
        ..drawRect(r, Paint()..color = _codeWhite)
        ..drawPath(
          Path()
            ..moveTo(r.center.dx, r.top)
            ..lineTo(r.right, r.center.dy)
            ..lineTo(r.center.dx, r.bottom)
            ..lineTo(r.left, r.center.dy)
            ..close(),
          Paint()..color = _codeRed,
        );
    },
    // Kilo: yellow and blue, halves.
    'K': (final Canvas c, final Rect r) {
      c
        ..drawRect(Rect.fromLTRB(r.left, r.top, r.center.dx, r.bottom), Paint()..color = _codeYellow)
        ..drawRect(Rect.fromLTRB(r.center.dx, r.top, r.right, r.bottom), Paint()..color = _codeBlue);
    },
    // Uniform: red and white quarters.
    'U': (final Canvas c, final Rect r) {
      final Paint red = Paint()..color = _codeRed;
      final Paint white = Paint()..color = _codeWhite;
      c
        ..drawRect(Rect.fromLTRB(r.left, r.top, r.center.dx, r.center.dy), red)
        ..drawRect(Rect.fromLTRB(r.center.dx, r.top, r.right, r.center.dy), white)
        ..drawRect(Rect.fromLTRB(r.left, r.center.dy, r.center.dx, r.bottom), white)
        ..drawRect(Rect.fromLTRB(r.center.dx, r.center.dy, r.right, r.bottom), red);
    },
    // November: blue and white checks.
    'N': (final Canvas c, final Rect r) {
      for (int x = 0; x < 4; x++) {
        for (int y = 0; y < 4; y++) {
          c.drawRect(
            Rect.fromLTWH(r.left + r.width * x / 4, r.top + r.height * y / 4, r.width / 4, r.height / 4),
            Paint()..color = (x + y).isEven ? _codeBlue : _codeWhite,
          );
        }
      }
    },
  };

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.82;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);

    // The ship's bow and foredeck along the bottom.
    final Path hull = Path()
      ..moveTo(0, waterline - h * 0.1)
      ..lineTo(w * 0.86, waterline - h * 0.12)
      ..quadraticBezierTo(w * 0.94, waterline - h * 0.13, w * 0.98, waterline - h * 0.16)
      ..lineTo(w * 0.9, waterline + 4)
      ..lineTo(0, waterline + 4)
      ..close();
    canvas
      ..drawPath(hull, Paint()..color = const Color(0xFF263238))
      ..drawRect(Rect.fromLTRB(0, waterline - h * 0.03, w * 0.9, waterline + 4), Paint()..color = const Color(0xFF8E2A22));
    // The mast at the left, and the stem at the right.
    final Offset masthead = Offset(w * 0.12, h * 0.06);
    final Offset deck = Offset(w * 0.12, waterline - h * 0.1);
    canvas.drawLine(deck, masthead, Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 4);
    final Offset stem = Offset(w * 0.95, waterline - h * 0.15);

    // The halyard runs from the masthead down to the stem, sagging a little.
    final Path halyard = Path()
      ..moveTo(masthead.dx, masthead.dy)
      ..quadraticBezierTo(w * 0.55, h * 0.32, stem.dx, stem.dy);
    canvas.drawPath(halyard, Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // Flags clipped along it, each hanging from the line, stirred by the wind.
    const List<String> hoist = <String>['K', 'C', 'A', 'E', 'D', 'U', 'F', 'N'];
    final PathMetric metric = halyard.computeMetrics().first;
    final double flagW = h * 0.13;
    final double flagH = h * 0.11;
    for (int i = 0; i < hoist.length; i++) {
      final double d = metric.length * (0.08 + i * 0.112);
      final Tangent? t = metric.getTangentForOffset(d);
      if (t == null) {
        continue;
      }
      canvas
        ..save()
        ..translate(t.position.dx, t.position.dy)
        ..rotate(-t.angle)
        ..rotate(math.sin(i * 1.7) * 0.05);
      final Rect flag = Rect.fromLTWH(0, 1, flagW, flagH);
      _flags[hoist[i]]!(canvas, flag);
      canvas
        ..drawRect(flag, Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6)
        ..restore();
    }
    Scenery.ripples(canvas, size, waterline + 4);
  }

  @override
  bool shouldRepaint(final _SignalFlagsPainter oldDelegate) => false;
}

/// A tiny red can buoy, for marking a buoy on the stage.
class CanBuoyIcon extends StatelessWidget {
  const CanBuoyIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(final BuildContext context) => SizedBox(width: size * 0.7, height: size, child: const CustomPaint(painter: _CanIconPainter()));
}

class _CanIconPainter extends CustomPainter {
  const _CanIconPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect body = Rect.fromLTRB(0, size.height * 0.15, size.width, size.height * 0.85);
    canvas
      ..drawRect(body, Paint()..color = Palette.buoyRed)
      ..drawOval(Rect.fromLTRB(0, 0, size.width, size.height * 0.3), Paint()..color = const Color(0xFFB8352B))
      ..drawRect(Rect.fromLTRB(0, size.height * 0.35, size.width, size.height * 0.45), Paint()..color = Colors.white)
      ..drawLine(Offset(-2, size.height * 0.88), Offset(size.width + 2, size.height * 0.88), Paint()
        ..color = Palette.foam
        ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(final _CanIconPainter oldDelegate) => false;
}

/// One international code flag, painted to fill its box: for the signals on the stage.
class CodeFlag extends StatelessWidget {
  const CodeFlag({super.key, required this.letter, this.width = 22, this.height = 16});

  /// A, C, D, E, F, K, N or U.
  final String letter;
  final double width;
  final double height;

  @override
  Widget build(final BuildContext context) => SizedBox(width: width, height: height, child: CustomPaint(painter: _CodeFlagPainter(letter)));
}

class _CodeFlagPainter extends CustomPainter {
  _CodeFlagPainter(this.letter);

  final String letter;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect r = Offset.zero & size;
    (_SignalFlagsPainter._flags[letter] ?? _SignalFlagsPainter._flags['K']!)(canvas, r);
    canvas.drawRect(r, Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(final _CodeFlagPainter oldDelegate) => oldDelegate.letter != letter;
}
