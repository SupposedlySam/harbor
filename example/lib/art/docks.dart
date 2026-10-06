import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// A pier's backdrop: weathered planks on posts, the boardwalk a header or a
/// bar is built on. The posts run toward [postsToward], into the water.
class PierPlanks extends StatelessWidget {
  const PierPlanks({super.key, this.postsToward = AxisDirection.down, this.opacity = 0.92});

  final AxisDirection postsToward;
  final double opacity;

  @override
  Widget build(final BuildContext context) =>
      CustomPaint(painter: _PlankPainter(postsToward, opacity), child: const SizedBox.expand());
}

class _PlankPainter extends CustomPainter {
  _PlankPainter(this.postsToward, this.opacity);

  final AxisDirection postsToward;
  final double opacity;

  @override
  void paint(final Canvas canvas, final Size size) {
    final bool vertical = postsToward == AxisDirection.down || postsToward == AxisDirection.up;
    final double along = vertical ? size.width : size.height;
    final double across = vertical ? size.height : size.width;
    canvas.save();
    if (!vertical) {
      canvas
        ..translate(size.width / 2, size.height / 2)
        ..rotate(postsToward == AxisDirection.right ? -math.pi / 2 : math.pi / 2)
        ..translate(-size.height / 2, -size.width / 2);
    } else if (postsToward == AxisDirection.up) {
      canvas
        ..translate(0, size.height)
        ..scale(1, -1);
    }
    final math.Random random = math.Random(3);
    const double plank = 22.0;
    for (double x = 0; x < along; x += plank) {
      final Color shade = Color.lerp(Palette.plank, Palette.plankLight, random.nextDouble() * 0.6)!;
      canvas.drawRect(Rect.fromLTWH(x, 0, plank - 2, across), Paint()..color = shade.withValues(alpha: opacity));
      // Grain.
      for (int g = 0; g < 3; g++) {
        final double gx = x + 4 + random.nextDouble() * (plank - 8);
        canvas.drawLine(
          Offset(gx, 0),
          Offset(gx + random.nextDouble() * 2 - 1, across),
          Paint()
            ..color = Palette.plankDark.withValues(alpha: 0.25 * opacity)
            ..strokeWidth = 0.8,
        );
      }
      // Nails.
      canvas
        ..drawCircle(Offset(x + plank / 2 - 1, 5), 1.2, Paint()..color = Colors.black.withValues(alpha: 0.35 * opacity))
        ..drawCircle(Offset(x + plank / 2 - 1, across - 5), 1.2, Paint()..color = Colors.black.withValues(alpha: 0.35 * opacity));
    }
    // A rope along the water side.
    final Path rope = Path()..moveTo(0, across - 2);
    for (double x = 0; x <= along; x += 40) {
      rope.quadraticBezierTo(x + 20, across + 3, x + 40, across - 2);
    }
    canvas.drawPath(
      rope,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Palette.rope.withValues(alpha: opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(final _PlankPainter oldDelegate) => oldDelegate.postsToward != postsToward || oldDelegate.opacity != opacity;
}

/// A quay's backdrop: a stone wall, solid ground the body starts beyond.
class QuayStones extends StatelessWidget {
  const QuayStones({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _StonePainter(), child: SizedBox.expand());
}

class _StonePainter extends CustomPainter {
  const _StonePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.stoneDark);
    final math.Random random = math.Random(11);
    const double rowHeight = 14.0;
    int row = 0;
    for (double y = 0; y < size.height; y += rowHeight, row++) {
      double x = row.isEven ? 0 : -18;
      while (x < size.width) {
        final double w = 30 + random.nextDouble() * 22;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 1, y + 1, w - 2, rowHeight - 2), const Radius.circular(3)),
          Paint()..color = Color.lerp(Palette.stone, Palette.stoneDark, random.nextDouble() * 0.5)!,
        );
        x += w;
      }
    }
    // A brass edge where the quay meets the water.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 2), Paint()..color = Palette.brass.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(final _StonePainter oldDelegate) => false;
}

/// A red-and-white buoy with a light on top.
class BuoyArt extends StatelessWidget {
  const BuoyArt({super.key, this.size = 28});

  final double size;

  @override
  Widget build(final BuildContext context) => SizedBox.square(dimension: size, child: const CustomPaint(painter: _BuoyPainter()));
}

class _BuoyPainter extends CustomPainter {
  const _BuoyPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path body = Path()
      ..moveTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.7, h * 0.2)
      ..lineTo(w * 0.85, h * 0.85)
      ..lineTo(w * 0.15, h * 0.85)
      ..close();
    canvas
      ..drawPath(body, Paint()..color = Palette.buoyRed)
      ..save()
      ..clipPath(body)
      ..drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.16), Paint()..color = Palette.sail)
      ..restore()
      ..drawCircle(Offset(w / 2, h * 0.14), w * 0.1, Paint()..color = Palette.brass)
      ..drawOval(Rect.fromLTWH(0, h * 0.8, w, h * 0.18), Paint()..color = Palette.foam.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(final _BuoyPainter oldDelegate) => false;
}

/// A striped lighthouse, its beam sweeping when [shining].
class LighthouseArt extends StatefulWidget {
  const LighthouseArt({super.key, this.shining = true});

  final bool shining;

  @override
  State<LighthouseArt> createState() => _LighthouseArtState();
}

class _LighthouseArtState extends State<LighthouseArt> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    if (widget.shining) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      AspectRatio(aspectRatio: 0.7, child: CustomPaint(painter: _LighthousePainter(_sweep, widget.shining)));
}

class _LighthousePainter extends CustomPainter {
  _LighthousePainter(this.sweep, this.shining) : super(repaint: sweep);

  final Animation<double> sweep;
  final bool shining;

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    if (shining) {
      final double angle = sweep.value * math.pi * 2;
      final Offset lamp = Offset(w / 2, h * 0.2);
      final Path beam = Path()
        ..moveTo(lamp.dx, lamp.dy)
        ..lineTo(lamp.dx + math.cos(angle - 0.18) * w * 3, lamp.dy + math.sin(angle - 0.18) * w * 0.6)
        ..lineTo(lamp.dx + math.cos(angle + 0.18) * w * 3, lamp.dy + math.sin(angle + 0.18) * w * 0.6)
        ..close();
      canvas.drawPath(beam, Paint()..color = Palette.brass.withValues(alpha: 0.18));
    }
    final Path tower = Path()
      ..moveTo(w * 0.36, h * 0.26)
      ..lineTo(w * 0.64, h * 0.26)
      ..lineTo(w * 0.74, h * 0.92)
      ..lineTo(w * 0.26, h * 0.92)
      ..close();
    canvas
      ..drawPath(tower, Paint()..color = Palette.sail)
      ..save()
      ..clipPath(tower);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(0, h * (0.36 + i * 0.2), w, h * 0.09), Paint()..color = Palette.buoyRed);
    }
    canvas
      ..restore()
      ..drawRect(Rect.fromLTWH(w * 0.38, h * 0.13, w * 0.24, h * 0.13), Paint()..color = Palette.brass)
      ..drawPath(
        Path()
          ..moveTo(w * 0.32, h * 0.13)
          ..lineTo(w * 0.5, h * 0.03)
          ..lineTo(w * 0.68, h * 0.13)
          ..close(),
        Paint()..color = Palette.buoyRed,
      )
      ..drawRect(Rect.fromLTWH(w * 0.18, h * 0.92, w * 0.64, h * 0.06), Paint()..color = Palette.stone);
  }

  @override
  bool shouldRepaint(final _LighthousePainter oldDelegate) => oldDelegate.shining != shining;
}

/// A gull, mid-flap.
class GullArt extends StatelessWidget {
  const GullArt({super.key, this.size = 24});

  final double size;

  @override
  Widget build(final BuildContext context) =>
      SizedBox(width: size, height: size / 2, child: const CustomPaint(painter: _GullPainter()));
}

class _GullPainter extends CustomPainter {
  const _GullPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final Path path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.75, 0, size.width, size.height * 0.6);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Palette.foam,
    );
  }

  @override
  bool shouldRepaint(final _GullPainter oldDelegate) => false;
}

/// A wooden crate of cargo.
class CrateArt extends StatelessWidget {
  const CrateArt({super.key, this.size = 36, this.color = Palette.plankLight});

  final double size;
  final Color color;

  @override
  Widget build(final BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: Palette.plankDark, width: 3),
      borderRadius: BorderRadius.circular(3),
    ),
    child: CustomPaint(painter: _CrossPainter(), size: Size.square(size)),
  );
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint p = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 2.5;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), p)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(final _CrossPainter oldDelegate) => false;
}
