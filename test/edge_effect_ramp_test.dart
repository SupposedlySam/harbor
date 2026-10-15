// A fade's ramp (#70): how opaque content is at the bar's face, and the curve out to the
// fade's end. The defaults must draw exactly the ramp every fade had before they were options.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

const double _height = 200;

/// The mask's alpha down the middle column, one value per logical pixel row, from 0 to 1.
Future<List<double>> _alphaColumn(final WidgetTester tester, final Map<HarborEdge, HarborFadeBand> bands) async {
  final GlobalKey boundary = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 10,
            height: _height,
            child: HarborFadeMask(
              bands: bands,
              child: const ColoredBox(color: Color(0xFFFFFFFF)),
            ),
          ),
        ),
      ),
    ),
  );
  final RenderRepaintBoundary render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ByteData bytes = (await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await render.toImage();
    final ByteData? data = await image.toByteData();
    image.dispose();
    return data;
  }))!;
  return <double>[for (int y = 0; y < _height; y++) bytes.getUint8((y * 10 + 5) * 4 + 3) / 255];
}

/// The alpha a straight ramp gives at the centre of row [y]: clear at 0, [face] at [faceEdge],
/// opaque at [fadeEnd].
double _straight(final int y, final double faceEdge, final double fadeEnd, final double face) {
  final double at = y + 0.5;
  if (at <= faceEdge) {
    return face * at / faceEdge;
  }
  if (at >= fadeEnd) {
    return 1.0;
  }
  return face + (1 - face) * (at - faceEdge) / (fadeEnd - faceEdge);
}

void main() {
  // Passes on the code before #70 too: it pins the ramp the defaults must keep.
  testWidgets(
    'a band at its defaults draws the ramp fades always had: clear, a quarter at the bar, opaque at the end',
    (final tester) async {
      final List<double> alpha = await _alphaColumn(tester, <HarborEdge, HarborFadeBand>{
        HarborEdge.top: const HarborFadeBand(barFace: 40, fadeEnd: 80),
        HarborEdge.bottom: const HarborFadeBand(barFace: 20, fadeEnd: 60),
      });
      for (int y = 0; y < _height; y++) {
        final double expected = y < _height / 2
            ? _straight(y, 40, 80, 0.25)
            : _straight(_height.toInt() - 1 - y, 20, 60, 0.25);
        expect(alpha[y], moreOrLessEquals(expected, epsilon: 2 / 255), reason: 'row $y');
      }
    },
  );

  testWidgets("a band's faceOpacity is the opacity at the bar's face, on either edge", (final tester) async {
    final List<double> alpha = await _alphaColumn(tester, <HarborEdge, HarborFadeBand>{
      HarborEdge.top: const HarborFadeBand(barFace: 40, fadeEnd: 80, faceOpacity: 0.6),
      HarborEdge.bottom: const HarborFadeBand(barFace: 20, fadeEnd: 60, faceOpacity: 1.0),
    });
    for (int y = 0; y < _height; y++) {
      final double expected = y < _height / 2
          ? _straight(y, 40, 80, 0.6)
          : _straight(_height.toInt() - 1 - y, 20, 60, 1.0);
      expect(alpha[y], moreOrLessEquals(expected, epsilon: 2 / 255), reason: 'row $y');
    }
    // Opacity 1 at the bar: the band past the bar's face does not fade.
    expect(alpha.sublist(100, _height.toInt() - 20), everyElement(moreOrLessEquals(1.0, epsilon: 1 / 255)));
  });

  testWidgets("a band's curve shapes the ramp out to the fade's end", (final tester) async {
    final List<double> alpha = await _alphaColumn(tester, <HarborEdge, HarborFadeBand>{
      HarborEdge.top: const HarborFadeBand(barFace: 40, fadeEnd: 160, curve: Curves.easeIn),
      HarborEdge.bottom: const HarborFadeBand(barFace: 0, fadeEnd: 30, curve: Curves.easeOut),
    });
    double curved(final Curve curve, final double t) => 0.25 + 0.75 * curve.transform(t);
    // Halfway along the top ramp (row 100 of 40..160), an ease-in is well under a straight line.
    expect(alpha[99], moreOrLessEquals(curved(Curves.easeIn, 59.5 / 120), epsilon: 0.03));
    expect(alpha[99], lessThan(_straight(99, 40, 160, 0.25) - 0.1));
    // The ends are where they always were.
    expect(alpha[39], moreOrLessEquals(_straight(39, 40, 160, 0.25), epsilon: 0.03));
    expect(alpha[160], moreOrLessEquals(1.0, epsilon: 1 / 255));
    // Ten in from the bottom, an ease-out is already well past a straight line.
    expect(alpha[_height.toInt() - 11], greaterThan(_straight(10, 0, 30, 0.25) + 0.1));
  });

  testWidgets('HarborEdgeEffect.fade carries its ramp onto the band it measures, and leaves the defaults unset', (
    final tester,
  ) async {
    Future<HarborFadeBand> bandOf(final HarborEdgeEffect edgeEffect, {final bool nested = false}) async {
      final GlobalKey body = GlobalKey();
      final Widget content = SizedBox.expand(key: body);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: HarborFrame(
              top: <HarborBar>[HarborBar.overlay(edgeEffect: edgeEffect, child: const SizedBox(height: 50))],
              // A frame inside the body hands the band on, measured from its own edge.
              body: nested ? HarborFrame(body: content) : content,
            ),
          ),
        ),
      );
      return HarborRoom.of(body.currentContext!).fadeBands[HarborEdge.top]!;
    }

    expect(await bandOf(const HarborEdgeEffect.fade(length: 12)), const HarborFadeBand(barFace: 50, fadeEnd: 62));
    expect(
      await bandOf(const HarborEdgeEffect.fade(length: 12, faceOpacity: 0.6, curve: Curves.easeIn)),
      const HarborFadeBand(barFace: 50, fadeEnd: 62, faceOpacity: 0.6, curve: Curves.easeIn),
    );
    expect(
      await bandOf(const HarborEdgeEffect.fade(length: 12, faceOpacity: 0.6, curve: Curves.easeIn), nested: true),
      const HarborFadeBand(barFace: 50, fadeEnd: 62, faceOpacity: 0.6, curve: Curves.easeIn),
    );
  });

  test('a fade with a ramp of its own is a different edge effect, and says so', () {
    const HarborEdgeEffect plain = HarborEdgeEffect.fade();
    const HarborEdgeEffect ramped = HarborEdgeEffect.fade(faceOpacity: 0.5, curve: Curves.easeOut);
    expect(plain, const HarborEdgeEffect.fade(faceOpacity: 0.25, curve: Curves.linear));
    expect(ramped, isNot(plain));
    expect(const HarborEdgeEffect.fade(faceOpacity: 0.5), isNot(plain));
    expect(const HarborEdgeEffect.fade(curve: Curves.easeOut), isNot(plain));
    expect(ramped.hashCode, const HarborEdgeEffect.fade(faceOpacity: 0.5, curve: Curves.easeOut).hashCode);
    expect(plain.toString(), isNot(contains('dockOpacity')));
    expect(ramped.toString(), allOf(contains('faceOpacity: 0.5'), contains('curve:')));

    const HarborFadeBand band = HarborFadeBand(barFace: 1, fadeEnd: 2, faceOpacity: 0.5, curve: Curves.easeOut);
    expect(band, isNot(const HarborFadeBand(barFace: 1, fadeEnd: 2)));
    expect(band.hashCode, isNot(const HarborFadeBand(barFace: 1, fadeEnd: 2).hashCode));
    expect(band.toString(), contains('faceOpacity: 0.5'));
    expect(const HarborFadeBand(barFace: 1, fadeEnd: 2).toString(), 'HarborFadeBand(1.0 → 2.0)');
  });
}
