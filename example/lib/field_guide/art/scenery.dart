import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../art/palette.dart';

/// Shared brushes for the field guide's drawings, so every plate shares one
/// sky, one sea and one shoreline.
abstract final class Scenery {
  /// A daytime sky down to [horizon], with a sun and two clouds.
  static void sky(final Canvas canvas, final Size size, final double horizon, {final bool night = false}) {
    final Rect sky = Rect.fromLTWH(0, 0, size.width, horizon);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const <Color>[Color(0xFF0A1630), Color(0xFF1F3A66)] : const <Color>[Color(0xFF8CC8EE), Color(0xFFE8F4FA)],
        ).createShader(sky),
    );
    if (night) {
      final math.Random random = math.Random(5);
      for (int i = 0; i < 24; i++) {
        canvas.drawCircle(
          Offset(random.nextDouble() * size.width, random.nextDouble() * horizon * 0.8),
          0.9,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
      }
      return;
    }
    canvas.drawCircle(Offset(size.width * 0.82, horizon * 0.28), size.height * 0.07, Paint()..color = const Color(0xFFFFE08A));
    cloud(canvas, Offset(size.width * 0.28, horizon * 0.25), size.height * 0.05);
    cloud(canvas, Offset(size.width * 0.6, horizon * 0.15), size.height * 0.035);
  }

  static void cloud(final Canvas canvas, final Offset at, final double r) {
    final Paint white = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas
      ..drawCircle(at, r, white)
      ..drawCircle(at + Offset(r * 0.9, r * 0.2), r * 0.8, white)
      ..drawCircle(at + Offset(-r * 0.9, r * 0.25), r * 0.7, white)
      ..drawRect(Rect.fromLTRB(at.dx - r * 1.5, at.dy, at.dx + r * 1.6, at.dy + r * 0.85), white);
  }

  /// The sea from [waterline] down, with a few wave lines.
  static void water(final Canvas canvas, final Size size, final double waterline) {
    final Rect sea = Rect.fromLTWH(0, waterline, size.width, size.height - waterline);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Palette.shallows, Palette.sea],
        ).createShader(sea),
    );
    final Paint wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Palette.foam.withValues(alpha: 0.35);
    for (int row = 1; row < 4; row++) {
      final double y = waterline + (size.height - waterline) * row / 4;
      final Path path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 6) {
        path.lineTo(x, y + math.sin(x / 14 + row) * 1.5);
      }
      canvas.drawPath(path, wave);
    }
  }

  /// Small ripples along [waterline].
  static void ripples(final Canvas canvas, final Size size, final double waterline) {
    final Paint ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.6);
    for (double x = 8; x < size.width; x += 26) {
      canvas.drawArc(Rect.fromLTWH(x, waterline - 1, 14, 4), 0.2, 2.7, false, ripple);
    }
  }

  /// A grassy shore with a sandy edge, on the left or right.
  static void shore(final Canvas canvas, final Size size, final double waterline, {required final bool fromLeft, required final double width}) {
    final double x0 = fromLeft ? 0 : size.width - width;
    final double x1 = fromLeft ? width : size.width;
    final Path land = Path()
      ..moveTo(x0, waterline + 4)
      ..lineTo(x0, waterline - size.height * 0.22)
      ..quadraticBezierTo((x0 + x1) / 2, waterline - size.height * 0.3, x1, waterline - size.height * 0.08)
      ..lineTo(x1 + (fromLeft ? 8 : -8), waterline + 4)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF5E8C4A));
    canvas.drawRect(Rect.fromLTRB(x0, waterline - 3, x1 + (fromLeft ? 6 : -6), waterline + 3), Paint()..color = const Color(0xFFE3CF9A));
  }

  /// A round timber pile from [top] down to [bottom].
  static void pile(final Canvas canvas, final Offset top, final double bottom, {required final double width}) {
    final Rect pile = Rect.fromLTRB(top.dx - width / 2, top.dy, top.dx + width / 2, bottom);
    canvas
      ..drawRect(pile, Paint()..color = Palette.plankDark)
      ..drawRect(Rect.fromLTRB(pile.left, pile.top, pile.left + width * 0.3, pile.bottom), Paint()..color = Palette.plank);
  }

  /// A dockside lamp post standing on [base], [height] tall.
  static void lamp(final Canvas canvas, final Offset base, final double height, {required final bool lit}) {
    final Paint iron = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 2;
    final Offset head = base - Offset(0, height);
    canvas
      ..drawLine(base, head, iron)
      ..drawLine(head, head + Offset(height * 0.18, 0), iron);
    final Offset lantern = head + Offset(height * 0.18, height * 0.1);
    if (lit) {
      canvas.drawCircle(lantern, height * 0.22, Paint()..color = const Color(0x55FFE08A));
    }
    canvas.drawCircle(lantern, height * 0.07, Paint()..color = lit ? const Color(0xFFFFE08A) : const Color(0xFF546E7A));
  }

  /// A black iron bollard: the post lines are tied to.
  static void bollard(final Canvas canvas, final Offset base, final double height) {
    final Paint iron = Paint()..color = const Color(0xFF263238);
    final double r = height * 0.55;
    canvas
      ..drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(base.dx - r * 0.6, base.dy - height, base.dx + r * 0.6, base.dy), Radius.circular(r * 0.3)), iron)
      ..drawOval(Rect.fromCenter(center: base - Offset(0, height), width: r * 2, height: r * 0.8), iron);
  }

  /// A little rowboat at [center], [length] long.
  static void rowboat(final Canvas canvas, final Offset center, final double length, final Color hull) {
    final double h = length * 0.28;
    final Path body = Path()
      ..moveTo(center.dx - length / 2, center.dy - h / 2)
      ..lineTo(center.dx + length / 2, center.dy - h / 2)
      ..quadraticBezierTo(center.dx + length * 0.4, center.dy + h / 2, center.dx + length * 0.25, center.dy + h / 2)
      ..lineTo(center.dx - length * 0.25, center.dy + h / 2)
      ..quadraticBezierTo(center.dx - length * 0.4, center.dy + h / 2, center.dx - length / 2, center.dy - h / 2)
      ..close();
    canvas
      ..drawPath(body, Paint()..color = hull)
      ..drawRect(Rect.fromLTWH(center.dx - length / 2, center.dy - h / 2, length, h * 0.18), Paint()..color = Palette.sail);
  }

  /// A stone quay wall, from [top] down into the water at [waterline].
  static void quayWall(final Canvas canvas, final Rect wall) {
    canvas.drawRect(wall, Paint()..color = Palette.stoneDark);
    final math.Random random = math.Random(3);
    const double row = 9;
    int r = 0;
    for (double y = wall.top; y < wall.bottom; y += row, r++) {
      double x = wall.left + (r.isEven ? 0 : -9);
      while (x < wall.right) {
        final double bw = 16 + random.nextDouble() * 10;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(math.max(x, wall.left) + 1, y + 1, math.min(bw - 2, wall.right - math.max(x, wall.left) - 1), row - 2),
            const Radius.circular(2),
          ),
          Paint()..color = Color.lerp(Palette.stone, Palette.stoneDark, random.nextDouble() * 0.6)!,
        );
        x += bw;
      }
    }
    canvas.drawRect(Rect.fromLTWH(wall.left, wall.top, wall.width, 3), Paint()..color = const Color(0xFFB0B7BD));
  }
}
