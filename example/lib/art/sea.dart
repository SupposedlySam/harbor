import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Open water: an animated sea that fills whatever it is given. The harbor's
/// background, drawn under every dock.
class Sea extends StatefulWidget {
  const Sea({super.key, this.mood = SeaMood.calm, this.child});

  final SeaMood mood;
  final Widget? child;

  @override
  State<Sea> createState() => _SeaState();
}

enum SeaMood {
  calm(Palette.shallows, Palette.sea, 0.6),
  choppy(Color(0xFF2B6E8F), Color(0xFF123A57), 1.2),
  stormy(Color(0xFF34495E), Color(0xFF0E1A26), 2.0),
  night(Color(0xFF15325A), Palette.night, 0.5);

  const SeaMood(this.top, this.bottom, this.swell);

  final Color top;
  final Color bottom;
  final double swell;
}

class _SeaState extends State<Sea> with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 12))
    ..repeat();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _SeaPainter(_time, widget.mood),
      child: widget.child ?? const SizedBox.expand(),
    ),
  );
}

class _SeaPainter extends CustomPainter {
  _SeaPainter(this.time, this.mood) : super(repaint: time);

  final Animation<double> time;
  final SeaMood mood;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[mood.top, mood.bottom],
        ).createShader(rect),
    );
    final double t = time.value * math.pi * 2;
    for (int layer = 0; layer < 7; layer++) {
      final double y0 = size.height * (0.12 + layer * 0.13);
      final double amp = (4.0 + layer * 1.6) * mood.swell;
      final double wavelength = 90.0 + layer * 26.0;
      final Path path = Path()..moveTo(0, y0);
      for (double x = 0; x <= size.width + 8; x += 8) {
        path.lineTo(x, y0 + math.sin(x / wavelength * math.pi * 2 + t * (layer.isEven ? 1 : -1) + layer) * amp);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Palette.foam.withValues(alpha: 0.06 + layer * 0.012),
      );
    }
    // Glints.
    final math.Random random = math.Random(7);
    for (int i = 0; i < 40; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double flicker = (math.sin(t * 2 + i) + 1) / 2;
      canvas.drawCircle(Offset(x, y), 1.2, Paint()..color = Palette.foam.withValues(alpha: 0.08 + 0.18 * flicker));
    }
  }

  @override
  bool shouldRepaint(final _SeaPainter oldDelegate) => oldDelegate.mood != mood;
}
