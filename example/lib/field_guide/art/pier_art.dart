import 'package:flutter/material.dart';

import '../../art/palette.dart';
import 'scenery.dart';

/// A wooden pier on piles, built out over the water, with a rowboat moored
/// in its shade: water runs underneath it.
class PierArt extends StatelessWidget {
  const PierArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _PierPainter(), child: SizedBox.expand());
}

class _PierPainter extends CustomPainter {
  const _PierPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final double w = size.width;
    final double h = size.height;
    final double waterline = h * 0.62;
    Scenery.sky(canvas, size, waterline);
    Scenery.water(canvas, size, waterline);
    Scenery.shore(canvas, size, waterline, fromLeft: true, width: w * 0.22);

    // The deck runs from the shore out over the water.
    final double deckTop = h * 0.42;
    final double deckBottom = h * 0.5;
    final double deckEnd = w * 0.9;
    // Piles first, so the deck sits on them.
    for (double x = w * 0.2; x <= deckEnd - 6; x += w * 0.1) {
      Scenery.pile(canvas, Offset(x, deckBottom), waterline + h * 0.12, width: w * 0.022);
    }
    // Cross bracing between the piles.
    final Paint brace = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 1.6;
    for (double x = w * 0.2; x < deckEnd - w * 0.1; x += w * 0.1) {
      canvas
        ..drawLine(Offset(x, deckBottom + 2), Offset(x + w * 0.1, waterline - 2), brace)
        ..drawLine(Offset(x + w * 0.1, deckBottom + 2), Offset(x, waterline - 2), brace);
    }
    // The deck: planks end-on, and its edge.
    final Rect deck = Rect.fromLTRB(w * 0.12, deckTop, deckEnd, deckBottom);
    canvas.drawRect(deck, Paint()..color = Palette.plank);
    for (double x = deck.left; x < deck.right; x += 7) {
      canvas.drawLine(Offset(x, deckTop), Offset(x, deckBottom), Paint()..color = Palette.plankDark.withValues(alpha: 0.5));
    }
    canvas.drawRect(Rect.fromLTRB(deck.left, deckTop, deck.right, deckTop + 2.5), Paint()..color = Palette.plankLight);
    // Rails and a lamp at the end.
    final Paint rail = Paint()
      ..color = Palette.plankDark
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(deck.left, deckTop - h * 0.08), Offset(deck.right, deckTop - h * 0.08), rail);
    for (double x = deck.left; x <= deck.right; x += w * 0.1) {
      canvas.drawLine(Offset(x, deckTop), Offset(x, deckTop - h * 0.08), rail);
    }
    Scenery.lamp(canvas, Offset(deckEnd - w * 0.03, deckTop), h * 0.2, lit: true);
    Scenery.bollard(canvas, Offset(w * 0.55, deckTop), h * 0.05);

    // A rowboat in the pier's shade: the water runs under the pier.
    Scenery.rowboat(canvas, Offset(w * 0.5, waterline + h * 0.04), w * 0.16, Palette.buoyRed);
    Scenery.ripples(canvas, size, waterline);
  }

  @override
  bool shouldRepaint(final _PierPainter oldDelegate) => false;
}
