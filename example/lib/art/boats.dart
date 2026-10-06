import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';

enum BoatKind { sailboat, tug, ferry, rowboat, trawler, yacht }

/// A little boat, drawn to fit its box, bobbing gently when [bob] is set.
class BoatArt extends StatefulWidget {
  const BoatArt({super.key, required this.kind, required this.hull, this.bob = true, this.flag});

  final BoatKind kind;
  final Color hull;
  final bool bob;
  final Color? flag;

  @override
  State<BoatArt> createState() => _BoatArtState();
}

class _BoatArtState extends State<BoatArt> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    if (widget.bob) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AspectRatio(
    aspectRatio: 1.4,
    child: CustomPaint(painter: _BoatPainter(widget.kind, widget.hull, widget.flag, _bob)),
  );
}

class _BoatPainter extends CustomPainter {
  _BoatPainter(this.kind, this.hull, this.flag, this.bob) : super(repaint: bob);

  final BoatKind kind;
  final Color hull;
  final Color? flag;
  final Animation<double> bob;

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double phase = Curves.easeInOut.transform(bob.value);
    canvas
      ..save()
      ..translate(0, (phase - 0.5) * h * 0.05)
      ..translate(w / 2, h * 0.7)
      ..rotate((phase - 0.5) * 0.06)
      ..translate(-w / 2, -h * 0.7);

    final Paint hullPaint = Paint()..color = hull;
    final Paint dark = Paint()..color = Color.lerp(hull, Colors.black, 0.35)!;
    final Paint white = Paint()..color = Palette.sail;
    final double waterline = h * 0.72;

    // Hull.
    final Path body = Path()
      ..moveTo(w * 0.06, h * 0.52)
      ..lineTo(w * 0.94, h * 0.52)
      ..quadraticBezierTo(w * 0.88, waterline + h * 0.08, w * 0.74, waterline + h * 0.1)
      ..lineTo(w * 0.26, waterline + h * 0.1)
      ..quadraticBezierTo(w * 0.12, waterline + h * 0.06, w * 0.06, h * 0.52)
      ..close();
    canvas
      ..drawPath(body, hullPaint)
      ..drawRect(Rect.fromLTWH(w * 0.08, h * 0.52, w * 0.84, h * 0.035), dark);

    switch (kind) {
      case BoatKind.sailboat:
        canvas.drawRect(Rect.fromLTWH(w * 0.49, h * 0.06, w * 0.025, h * 0.47), Paint()..color = Palette.plankDark);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.47, h * 0.08)
            ..lineTo(w * 0.47, h * 0.48)
            ..lineTo(w * 0.16, h * 0.48)
            ..close(),
          white,
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.53, h * 0.12)
            ..lineTo(w * 0.53, h * 0.48)
            ..lineTo(w * 0.8, h * 0.48)
            ..close(),
          Paint()..color = Palette.sail.withValues(alpha: 0.85),
        );
      case BoatKind.tug:
        canvas
          ..drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, h * 0.3, w * 0.36, h * 0.23), const Radius.circular(4)), white)
          ..drawRect(Rect.fromLTWH(w * 0.52, h * 0.12, w * 0.09, h * 0.2), Paint()..color = Palette.buoyRed)
          ..drawRect(Rect.fromLTWH(w * 0.52, h * 0.12, w * 0.09, h * 0.04), Paint()..color = Colors.black87);
        _portholes(canvas, w * 0.36, h * 0.4, 3, w * 0.08, w);
      case BoatKind.ferry:
        canvas
          ..drawRect(Rect.fromLTWH(w * 0.16, h * 0.34, w * 0.68, h * 0.19), white)
          ..drawRect(Rect.fromLTWH(w * 0.26, h * 0.2, w * 0.48, h * 0.15), white)
          ..drawRect(Rect.fromLTWH(w * 0.44, h * 0.08, w * 0.08, h * 0.13), Paint()..color = Palette.brass);
        _portholes(canvas, w * 0.22, h * 0.43, 7, w * 0.085, w);
      case BoatKind.rowboat:
        canvas
          ..drawLine(Offset(w * 0.2, h * 0.36), Offset(w * 0.38, h * 0.62), Paint()
            ..color = Palette.plankLight
            ..strokeWidth = w * 0.02)
          ..drawLine(Offset(w * 0.8, h * 0.36), Offset(w * 0.62, h * 0.62), Paint()
            ..color = Palette.plankLight
            ..strokeWidth = w * 0.02);
      case BoatKind.trawler:
        canvas
          ..drawRect(Rect.fromLTWH(w * 0.56, h * 0.28, w * 0.24, h * 0.25), white)
          ..drawLine(Offset(w * 0.3, h * 0.52), Offset(w * 0.3, h * 0.1), Paint()
            ..color = Palette.plankDark
            ..strokeWidth = w * 0.02)
          ..drawLine(Offset(w * 0.3, h * 0.12), Offset(w * 0.12, h * 0.4), Paint()
            ..color = Palette.rope
            ..strokeWidth = w * 0.01);
        _portholes(canvas, w * 0.6, h * 0.38, 2, w * 0.08, w);
      case BoatKind.yacht:
        canvas
          ..drawPath(
            Path()
              ..moveTo(w * 0.22, h * 0.52)
              ..lineTo(w * 0.32, h * 0.34)
              ..lineTo(w * 0.78, h * 0.34)
              ..lineTo(w * 0.86, h * 0.52)
              ..close(),
            white,
          )
          ..drawRect(Rect.fromLTWH(w * 0.34, h * 0.38, w * 0.42, h * 0.05), Paint()..color = const Color(0xFF263238));
    }

    final Color? flag = this.flag;
    if (flag != null) {
      final double fx = kind == BoatKind.sailboat ? w * 0.51 : w * 0.7;
      final double fy = kind == BoatKind.sailboat ? h * 0.04 : h * 0.18;
      canvas
        ..drawLine(Offset(fx, fy), Offset(fx, fy + h * 0.16), Paint()
          ..color = Palette.plankDark
          ..strokeWidth = 1.5)
        ..drawPath(
          Path()
            ..moveTo(fx, fy)
            ..lineTo(fx + w * 0.12, fy + h * 0.035 + math.sin(bob.value * math.pi * 2) * 2)
            ..lineTo(fx, fy + h * 0.07)
            ..close(),
          Paint()..color = flag,
        );
    }
    canvas.restore();

    // Ripples at the waterline.
    final Paint ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Palette.foam.withValues(alpha: 0.55);
    canvas
      ..drawArc(Rect.fromLTWH(w * 0.12, waterline + h * 0.06, w * 0.3, h * 0.1), 0.2, 2.6, false, ripple)
      ..drawArc(Rect.fromLTWH(w * 0.58, waterline + h * 0.06, w * 0.3, h * 0.1), 0.2, 2.6, false, ripple);
  }

  void _portholes(final Canvas canvas, final double x, final double y, final int count, final double step, final double w) {
    final Paint glass = Paint()..color = const Color(0xFF90CAF9);
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(Offset(x + i * step, y), w * 0.018, glass);
    }
  }

  @override
  bool shouldRepaint(final _BoatPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.hull != hull || oldDelegate.flag != flag;
}
