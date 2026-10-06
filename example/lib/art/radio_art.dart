import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'boats.dart';
import 'docks.dart';
import 'palette.dart';

/// The radio room's wallpaper: a still night sea with faint rings of signal
/// spreading from a mast in the corner. Painted once, never animated, so a
/// page built on it can settle.
class RadioWaves extends StatelessWidget {
  const RadioWaves({super.key, this.child});

  final Widget? child;

  @override
  Widget build(final BuildContext context) =>
      CustomPaint(painter: const _RadioWavesPainter(), child: child ?? const SizedBox.expand());
}

class _RadioWavesPainter extends CustomPainter {
  const _RadioWavesPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect all = Offset.zero & size;
    canvas.drawRect(
      all,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0E2E50), Palette.night],
        ).createShader(all),
    );
    final Offset mast = Offset(size.width * 0.92, size.height * 0.08);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 1; i <= 9; i++) {
      ring.color = Palette.shallows.withValues(alpha: 0.16 - i * 0.014);
      canvas.drawCircle(mast, i * 70.0, ring);
    }
    final Paint swell = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.foam.withValues(alpha: 0.04);
    for (double y = 40; y < size.height; y += 56) {
      final Path path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.lineTo(x, y + math.sin(x / 38 + y) * 3);
      }
      canvas.drawPath(path, swell);
    }
  }

  @override
  bool shouldRepaint(final _RadioWavesPainter oldDelegate) => false;
}

/// What a photo in the locker shows.
enum PhotoScene { sunset, lighthouse, boat, gulls, storm, moonlight }

/// A little painted photograph for the photo locker: a snapshot of harbor
/// life with a white deckle edge. Still, so a sheet full of them settles.
class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.scene, this.hull = Palette.buoyRed});

  final PhotoScene scene;
  final Color hull;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Palette.sail,
      borderRadius: BorderRadius.circular(4),
      boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 4, color: Colors.black38, offset: Offset(0, 2))],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(painter: _PhotoSkyPainter(scene)),
            switch (scene) {
              PhotoScene.lighthouse => const Align(
                alignment: Alignment(0.4, 0.7),
                child: FractionallySizedBox(heightFactor: 0.7, child: LighthouseArt(shining: false)),
              ),
              PhotoScene.boat || PhotoScene.storm => Align(
                alignment: const Alignment(0, 0.55),
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: BoatArt(
                    kind: scene == PhotoScene.storm ? BoatKind.trawler : BoatKind.sailboat,
                    hull: hull,
                    bob: false,
                  ),
                ),
              ),
              PhotoScene.gulls => const Align(alignment: Alignment(-0.3, -0.3), child: GullArt(size: 28)),
              PhotoScene.sunset || PhotoScene.moonlight => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    ),
  );
}

class _PhotoSkyPainter extends CustomPainter {
  const _PhotoSkyPainter(this.scene);

  final PhotoScene scene;

  @override
  void paint(final Canvas canvas, final Size size) {
    final (Color sky, Color sea) = switch (scene) {
      PhotoScene.sunset => (const Color(0xFFFFA36C), const Color(0xFF3D5A98)),
      PhotoScene.lighthouse => (const Color(0xFF9BD3F0), Palette.sea),
      PhotoScene.boat => (const Color(0xFFBDE6F7), Palette.shallows),
      PhotoScene.gulls => (const Color(0xFFDDEFF7), const Color(0xFF4F8FB0)),
      PhotoScene.storm => (const Color(0xFF5D6D7E), const Color(0xFF22313F)),
      PhotoScene.moonlight => (const Color(0xFF1B2A4A), Palette.night),
    };
    final double horizon = size.height * 0.62;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, horizon), Paint()..color = sky)
      ..drawRect(Rect.fromLTWH(0, horizon, size.width, size.height - horizon), Paint()..color = sea);
    if (scene == PhotoScene.sunset) {
      canvas.drawCircle(Offset(size.width * 0.5, horizon), size.width * 0.18, Paint()..color = const Color(0xFFFFE08A));
    }
    if (scene == PhotoScene.moonlight) {
      canvas
        ..drawCircle(Offset(size.width * 0.7, size.height * 0.25), size.width * 0.1, Paint()..color = Palette.sail)
        ..drawRect(
          Rect.fromLTWH(size.width * 0.62, horizon + 4, size.width * 0.16, 2),
          Paint()..color = Palette.sail.withValues(alpha: 0.6),
        );
    }
    final Paint ripple = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (double y = horizon + 6; y < size.height; y += 7) {
      canvas.drawLine(Offset(size.width * 0.15, y), Offset(size.width * 0.4, y), ripple);
      canvas.drawLine(Offset(size.width * 0.55, y + 3), Offset(size.width * 0.85, y + 3), ripple);
    }
  }

  @override
  bool shouldRepaint(final _PhotoSkyPainter oldDelegate) => oldDelegate.scene != scene;
}
