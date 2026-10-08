import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../art/palette.dart';
import '../field_guide/art/scenery.dart';
import 'timeline.dart';

/// The illustrated harbor: a side view of one long waterfront, panned and zoomed by a camera.
///
/// Drawn side-on so the tide rises from the bottom of the picture, as the keyboard rises from the
/// bottom of the phone. Everything is a function of [time], through [ShowcaseTimeline].
class HarborScene extends StatelessWidget {
  const HarborScene({super.key, required this.time});

  final double time;

  @override
  Widget build(final BuildContext context) => CustomPaint(painter: _ScenePainter(time), child: const SizedBox.expand());
}

/// World coordinates: x along the waterfront, y down. Low water stands at [_lowWater].
abstract final class _World {
  static const double width = 2800;
  static const double lowWater = 400;
  static const double tideRange = 100;
  static const double seabed = 600;

  // The pier.
  static const double pierStart = 200;
  static const double pierEnd = 980;
  static const double pierDeck = 292;

  // The quay.
  static const double quayStart = 1420;
  static const double quayTop = 350;

  // The tide stations.
  static const double pilingsStart = 1920;
  static const double pilingsEnd = 2150;
  static const double pilingsDeck = 372;
  static const double floatStart = 2260;
  static const double floatEnd = 2540;
}

class _Camera {
  const _Camera(this.x, this.zoom);

  final double x;
  final double zoom;

  static _Camera lerp(final _Camera a, final _Camera b, final double t) =>
      _Camera(lerpDouble(a.x, b.x, t)!, lerpDouble(a.zoom, b.zoom, t)!);

  static const _Camera wide = _Camera(1440, 0.265);
  static const _Camera pier = _Camera(600, 0.95);
  static const _Camera quay = _Camera(1380, 0.95);
  static const _Camera tide = _Camera(2230, 0.9);

  /// Glides between stations at the start of each chapter.
  static _Camera at(final double t) {
    const double glide = 1.6;
    final List<(double, _Camera)> stops = <(double, _Camera)>[
      (ShowcaseTimeline.intro.start + 2.2, wide),
      (ShowcaseTimeline.pier.start, pier),
      (ShowcaseTimeline.quay.start, quay),
      (ShowcaseTimeline.tide.start, tide),
      (ShowcaseTimeline.outro.start, wide),
    ];
    _Camera camera = wide;
    for (final (double start, _Camera target) in stops) {
      camera = lerp(camera, target, ShowcaseTimeline.ease(t, start, start + glide));
    }
    return camera;
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.t);

  final double t;

  @override
  void paint(final Canvas canvas, final Size size) {
    final _Camera camera = _Camera.at(t);
    final double waterline = _World.lowWater - _World.tideRange * ShowcaseTimeline.water(t);
    // Low water sits a little below the middle of the picture at every zoom.
    final double anchor = size.height * 0.6;
    Offset toScreen(final Offset world) =>
        Offset(size.width / 2 + (world.dx - camera.x) * camera.zoom, anchor + (world.dy - _World.lowWater) * camera.zoom);

    _sky(canvas, size, toScreen(Offset(0, waterline)).dy);

    canvas
      ..save()
      ..translate(size.width / 2 - camera.x * camera.zoom, anchor - _World.lowWater * camera.zoom)
      ..scale(camera.zoom);
    _seabed(canvas);
    _farShore(canvas);
    _pier(canvas);
    _quay(canvas);
    _pilings(canvas);
    _water(canvas, waterline);
    _float(canvas, waterline);
    _boats(canvas, waterline);
    _gauge(canvas, waterline);
    _labels(canvas, waterline, camera.zoom);
    canvas.restore();
  }

  // --- Backdrop -------------------------------------------------------------------------------

  void _sky(final Canvas canvas, final Size size, final double horizon) {
    final Rect sky = Offset.zero & size;
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF7FBFE8), Color(0xFFE8F4FA)],
          stops: <double>[0.1, 0.7],
        ).createShader(sky),
    );
    // Below the waterline the picture is sea, however far the camera has pulled back.
    final Rect sea = Rect.fromLTRB(0, horizon, size.width, size.height);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Palette.deepSea],
        ).createShader(sea),
    );
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.12), 24, Paint()..color = const Color(0xFFFFE08A));
    Scenery.cloud(canvas, Offset(size.width * 0.32 + t * 3, size.height * 0.1), 16);
    Scenery.cloud(canvas, Offset(size.width * 0.62 + t * 2, size.height * 0.08), 11);
  }

  void _seabed(final Canvas canvas) {
    final Path bed = Path()..moveTo(-400, _World.seabed);
    for (double x = -400; x <= _World.width + 400; x += 40) {
      bed.lineTo(x, _World.seabed + math.sin(x / 90) * 6);
    }
    bed
      ..lineTo(_World.width + 400, _World.seabed + 3000)
      ..lineTo(-400, _World.seabed + 3000)
      ..close();
    canvas.drawPath(bed, Paint()..color = const Color(0xFFCDB585));
    // Rocks and weed, so a wide shot's seabed is not an empty band.
    final math.Random random = math.Random(11);
    for (double x = -300; x < _World.width + 300; x += 90 + random.nextDouble() * 120) {
      final double y = _World.seabed + math.sin(x / 90) * 6;
      if (random.nextBool()) {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 4), width: 30 + random.nextDouble() * 30, height: 18), Paint()..color = Palette.stone);
      } else {
        final Paint weed = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF3E7B4F);
        for (int b = -1; b <= 1; b++) {
          final double sway = math.sin(t * 1.5 + x) * 8;
          canvas.drawPath(
            Path()
              ..moveTo(x + b * 8, y)
              ..quadraticBezierTo(x + b * 10 + sway, y - 30, x + b * 6 + sway * 1.5, y - 55 - b.abs() * 10),
            weed,
          );
        }
      }
    }
  }

  void _farShore(final Canvas canvas) {
    final Paint grass = Paint()..color = const Color(0xFF5E8C4A);
    final Paint sand = Paint()..color = const Color(0xFFE3CF9A);
    // The headland the pier is built out from.
    canvas
      ..drawPath(
        Path()
          ..moveTo(-400, _World.seabed)
          ..lineTo(-400, 230)
          ..quadraticBezierTo(60, 200, _World.pierStart + 40, 300)
          ..lineTo(_World.pierStart + 60, _World.seabed)
          ..close(),
        grass,
      )
      ..drawRect(const Rect.fromLTRB(-400, 300, _World.pierStart + 50, 316), sand);
    // A cottage on the headland.
    _house(canvas, const Offset(40, 262), 70, Palette.buoyRed);
    // The land behind the quay, and on to the tide stations.
    canvas
      ..drawPath(
        Path()
          ..moveTo(_World.quayStart, _World.quayTop)
          ..lineTo(_World.pilingsStart - 150, _World.quayTop)
          ..quadraticBezierTo(_World.pilingsStart - 60, _World.quayTop + 10, _World.pilingsStart - 20, _World.lowWater + 30)
          ..lineTo(_World.pilingsStart + 60, _World.seabed + 10)
          ..lineTo(_World.quayStart, _World.seabed + 10)
          ..close(),
        Paint()..color = const Color(0xFF8A6E4B),
      )
      ..drawRect(const Rect.fromLTRB(_World.quayStart, _World.quayTop, _World.pilingsStart - 150, _World.quayTop + 10), grass);
    _house(canvas, const Offset(1560, _World.quayTop), 110, const Color(0xFF3D5A98));
    _house(canvas, const Offset(1700, _World.quayTop), 80, Palette.brass);
    // The far bank past the floating dock.
    canvas.drawPath(
      Path()
        ..moveTo(_World.floatEnd + 120, _World.seabed)
        ..lineTo(_World.floatEnd + 120, 300)
        ..quadraticBezierTo(_World.width, 250, _World.width + 400, 260)
        ..lineTo(_World.width + 400, _World.seabed)
        ..close(),
      grass,
    );
  }

  void _house(final Canvas canvas, final Offset base, final double width, final Color roof) {
    final double h = width * 0.7;
    final Rect wall = Rect.fromLTWH(base.dx, base.dy - h, width, h);
    canvas
      ..drawRect(wall, Paint()..color = Palette.sail)
      ..drawPath(
        Path()
          ..moveTo(wall.left - 8, wall.top)
          ..lineTo(wall.center.dx, wall.top - h * 0.6)
          ..lineTo(wall.right + 8, wall.top)
          ..close(),
        Paint()..color = roof,
      )
      ..drawRect(Rect.fromLTWH(wall.left + width * 0.18, wall.top + h * 0.3, width * 0.2, h * 0.25), Paint()..color = Palette.shallows)
      ..drawRect(Rect.fromLTWH(wall.right - width * 0.36, wall.top + h * 0.45, width * 0.2, h * 0.55), Paint()..color = Palette.plankDark);
  }

  // --- The pier: built out over the water on piles --------------------------------------------

  void _pier(final Canvas canvas) {
    const double deckBottom = _World.pierDeck + 20;
    for (double x = _World.pierStart + 40; x <= _World.pierEnd - 10; x += 78) {
      Scenery.pile(canvas, Offset(x, deckBottom), _World.seabed + 4, width: 14);
    }
    final Rect deck = const Rect.fromLTRB(_World.pierStart, _World.pierDeck, _World.pierEnd, deckBottom);
    canvas.drawRect(deck, Paint()..color = Palette.plank);
    for (double x = deck.left; x < deck.right; x += 10) {
      canvas.drawLine(Offset(x, deck.top), Offset(x, deck.bottom), Paint()..color = Palette.plankDark.withValues(alpha: 0.45));
    }
    canvas.drawRect(Rect.fromLTRB(deck.left, deck.top, deck.right, deck.top + 4), Paint()..color = Palette.plankLight);
    final Paint rail = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 3;
    canvas.drawLine(Offset(deck.left, deck.top - 26), Offset(deck.right, deck.top - 26), rail);
    for (double x = deck.left; x <= deck.right; x += 39) {
      canvas.drawLine(Offset(x, deck.top), Offset(x, deck.top - 26), rail);
    }
    Scenery.lamp(canvas, Offset(deck.right - 20, deck.top), 70, lit: false);
  }

  // --- The quay: a stone wall on the shore ----------------------------------------------------

  void _quay(final Canvas canvas) {
    Scenery.quayWall(canvas, const Rect.fromLTRB(_World.quayStart, _World.quayTop, _World.quayStart + 140, _World.seabed + 10));
    Scenery.bollard(canvas, const Offset(_World.quayStart + 24, _World.quayTop), 22);
    Scenery.bollard(canvas, const Offset(_World.quayStart + 110, _World.quayTop), 22);
    // Crates waiting on the quay.
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(_World.quayStart + 140 + i * 30.0, _World.quayTop - 26 - (i == 1 ? 26 : 0), 26, 26),
        Paint()..color = i.isEven ? Palette.plank : Palette.plankLight,
      );
    }
  }

  // --- A jetty on pilings: stays where it is, and the tide covers it -------------------------

  void _pilings(final Canvas canvas) {
    const double deckBottom = _World.pilingsDeck + 12;
    for (double x = _World.pilingsStart + 16; x <= _World.pilingsEnd; x += 54) {
      Scenery.pile(canvas, Offset(x, deckBottom), _World.seabed + 4, width: 12);
    }
    canvas
      ..drawRect(const Rect.fromLTRB(_World.pilingsStart, _World.pilingsDeck, _World.pilingsEnd, deckBottom), Paint()..color = Palette.plank)
      ..drawRect(
        const Rect.fromLTRB(_World.pilingsStart, _World.pilingsDeck, _World.pilingsEnd, _World.pilingsDeck + 3),
        Paint()..color = Palette.plankLight,
      );
  }

  // --- Water: translucent, so what the tide covers can still be seen beneath it --------------

  void _water(final Canvas canvas, final double waterline) {
    final Rect sea = Rect.fromLTRB(-400, waterline, _World.width + 400, _World.seabed + 3000);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows.withValues(alpha: 0.62), Palette.sea.withValues(alpha: 0.85)],
        ).createShader(sea),
    );
    final Paint foam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.foam.withValues(alpha: 0.8);
    final Path surface = Path()..moveTo(-400, waterline);
    for (double x = -400; x <= _World.width + 400; x += 12) {
      surface.lineTo(x, waterline + math.sin(x / 26 + t * 2.4) * 2.2);
    }
    canvas.drawPath(surface, foam);
  }

  // --- A floating pontoon: rides up and down with the tide -----------------------------------

  void _float(final Canvas canvas, final double waterline) {
    final double bob = ShowcaseTimeline.bob(t, phase: 1);
    // Guide piles hold it in place; it slides up and down them.
    for (final double x in <double>[_World.floatStart + 20, _World.floatEnd - 20]) {
      Scenery.pile(canvas, Offset(x, 220), _World.seabed + 4, width: 14);
      canvas.drawCircle(Offset(x, 220), 8, Paint()..color = Palette.plankDark);
    }
    final double top = waterline - 16 + bob;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(_World.floatStart, top, _World.floatEnd, top + 26), const Radius.circular(4)),
        Paint()..color = Palette.stone,
      )
      ..drawRect(Rect.fromLTRB(_World.floatStart, top, _World.floatEnd, top + 8), Paint()..color = Palette.plank)
      ..drawRect(Rect.fromLTRB(_World.floatStart, top, _World.floatEnd, top + 2), Paint()..color = Palette.plankLight);
    // A sailboat moored alongside rises with it.
    _sailboat(canvas, Offset(_World.floatStart + 140, waterline + 2 + bob), 150, Palette.hulls[4]);
  }

  // --- Boats under way ---------------------------------------------------------------------

  void _boats(final Canvas canvas, final double waterline) {
    // Two rowboats pass under the pier, the way rows scroll under a header.
    const ShowcaseChapter pier = ShowcaseTimeline.pier;
    for (int i = 0; i < 2; i++) {
      final double p = ShowcaseTimeline.boat(t, pier.start + 0.6 + i * 1.6, pier.end - 0.4 + i * 0.6);
      final double x = lerpDouble(_World.pierEnd + 160, _World.pierStart - 40, Curves.easeInOut.transform(p))!;
      Scenery.rowboat(canvas, Offset(x, waterline + 4 + ShowcaseTimeline.bob(t, phase: i * 2.0)), 70, Palette.hulls[i == 0 ? 0 : 2]);
    }
    // A tug comes in and stops at the quay wall, the way a list stops at a tab bar.
    const ShowcaseChapter quay = ShowcaseTimeline.quay;
    final double p = Curves.easeOutCubic.transform(ShowcaseTimeline.boat(t, quay.start + 0.4, quay.end - 1.6));
    final double bow = lerpDouble(_World.pierEnd + 60, _World.quayStart - 4, p)!;
    _tug(canvas, Offset(bow - 75, waterline + 4 + ShowcaseTimeline.bob(t, phase: 3)), 150, Palette.hulls[1]);
  }

  void _tug(final Canvas canvas, final Offset center, final double length, final Color hull) {
    final double h = length * 0.3;
    final Path body = Path()
      ..moveTo(center.dx - length / 2, center.dy - h * 0.5)
      ..lineTo(center.dx + length / 2, center.dy - h * 0.5)
      ..quadraticBezierTo(center.dx + length * 0.42, center.dy + h * 0.5, center.dx + length * 0.3, center.dy + h * 0.5)
      ..lineTo(center.dx - length * 0.36, center.dy + h * 0.5)
      ..quadraticBezierTo(center.dx - length * 0.48, center.dy + h * 0.3, center.dx - length / 2, center.dy - h * 0.5)
      ..close();
    canvas
      ..drawPath(body, Paint()..color = hull)
      ..drawRect(Rect.fromLTWH(center.dx - length / 2, center.dy - h * 0.5, length, 5), Paint()..color = Palette.sail)
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(center.dx - length * 0.2, center.dy - h * 1.35, length * 0.36, h * 0.85), const Radius.circular(4)),
        Paint()..color = Palette.sail,
      )
      ..drawRect(Rect.fromLTWH(center.dx + length * 0.02, center.dy - h * 1.9, length * 0.09, h * 0.6), Paint()..color = Palette.buoyRed)
      ..drawRect(Rect.fromLTWH(center.dx + length * 0.02, center.dy - h * 1.9, length * 0.09, 5), Paint()..color = Colors.black87);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(center.dx - length * 0.13 + i * length * 0.1, center.dy - h * 0.95), 4, Paint()..color = Palette.shallows);
    }
  }

  void _sailboat(final Canvas canvas, final Offset waterlinePoint, final double length, final Color hull) {
    final double h = length * 0.22;
    final Offset c = waterlinePoint;
    canvas
      ..drawPath(
        Path()
          ..moveTo(c.dx - length / 2, c.dy - h)
          ..lineTo(c.dx + length / 2, c.dy - h)
          ..quadraticBezierTo(c.dx + length * 0.4, c.dy + h * 0.3, c.dx + length * 0.22, c.dy + h * 0.3)
          ..lineTo(c.dx - length * 0.3, c.dy + h * 0.3)
          ..close(),
        Paint()..color = hull,
      )
      ..drawRect(Rect.fromLTWH(c.dx - 3, c.dy - h - length * 0.95, 6, length * 0.95), Paint()..color = Palette.plankDark)
      ..drawPath(
        Path()
          ..moveTo(c.dx - 6, c.dy - h - length * 0.9)
          ..lineTo(c.dx - 6, c.dy - h - 8)
          ..lineTo(c.dx - length * 0.42, c.dy - h - 8)
          ..close(),
        Paint()..color = Palette.sail,
      )
      ..drawPath(
        Path()
          ..moveTo(c.dx + 6, c.dy - h - length * 0.8)
          ..lineTo(c.dx + 6, c.dy - h - 8)
          ..lineTo(c.dx + length * 0.34, c.dy - h - 8)
          ..close(),
        Paint()..color = Palette.sail.withValues(alpha: 0.88),
      );
  }

  // --- A tide gauge: the height of the water, as the keyboard's height ------------------------

  void _gauge(final Canvas canvas, final double waterline) {
    const double x = _World.floatEnd + 70;
    const double top = _World.lowWater - _World.tideRange - 40;
    canvas.drawRect(const Rect.fromLTRB(x - 7, top, x + 7, _World.seabed), Paint()..color = Colors.white);
    for (double y = top; y < _World.seabed; y += 20) {
      canvas.drawRect(Rect.fromLTRB(x - 7, y, x + (y % 40 == 0 ? 7 : 0), y + 3), Paint()..color = Palette.deepSea);
    }
    canvas.drawRect(Rect.fromLTRB(x - 11, waterline - 2, x + 11, waterline + 2), Paint()..color = Palette.buoyRed);
  }

  // --- Labels: the harbor word, lit while its chapter plays -----------------------------------

  void _labels(final Canvas canvas, final double waterline, final double zoom) {
    // Scaled up as the camera pulls back, so a wide shot can still be read.
    final double grow = math.max(1.0, 0.6 / zoom);
    void tag(final String text, final Offset at, final ShowcaseChapter chapter, {final double size = 30}) {
      final bool lit = chapter.contains(t);
      final double fade = lit ? 1 : 0.55;
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: size * grow,
            fontWeight: FontWeight.w700,
            color: (lit ? Palette.night : Palette.deepSea).withValues(alpha: fade),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final Rect box = Rect.fromCenter(center: at, width: painter.width + 28 * grow, height: painter.height + 14 * grow);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(10 * grow)),
        Paint()..color = (lit ? Palette.brass : Colors.white).withValues(alpha: lit ? 1 : 0.7),
      );
      painter.paint(canvas, box.center - Offset(painter.width / 2, painter.height / 2));
    }

    tag('PIER', const Offset((_World.pierStart + _World.pierEnd) / 2, _World.pierDeck - 70), ShowcaseTimeline.pier);
    tag('QUAY', const Offset(_World.quayStart + 70, _World.quayTop - 80), ShowcaseTimeline.quay);
    tag('ON PILINGS', const Offset((_World.pilingsStart + _World.pilingsEnd) / 2, 250), ShowcaseTimeline.tide, size: 24);
    tag('AFLOAT', Offset(_World.floatStart + 330, waterline - 120), ShowcaseTimeline.tide, size: 24);
    tag('TIDE', Offset(_World.floatEnd + 70, waterline + 50), ShowcaseTimeline.tide, size: 24);
  }

  @override
  bool shouldRepaint(final _ScenePainter oldDelegate) => oldDelegate.t != t;
}
