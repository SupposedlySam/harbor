// A fade wake's ramp (#70): how opaque content is at the dock's face, and the curve out to the
// wake's end. The defaults must draw exactly the ramp every fade had before they were options.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

const double _height = 200;

/// The mask's alpha down the middle column, one value per logical pixel row, from 0 to 1.
Future<List<double>> _alphaColumn(final WidgetTester tester, final Map<HarborEdge, HarborWakeBand> wakes) async {
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
            child: HarborWakeMask(wakes: wakes, child: const ColoredBox(color: Color(0xFFFFFFFF))),
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

/// The alpha a straight ramp gives at the centre of row [y]: clear at 0, [dock] at [dockEdge],
/// opaque at [wakeEnd].
double _straight(final int y, final double dockEdge, final double wakeEnd, final double dock) {
  final double at = y + 0.5;
  if (at <= dockEdge) {
    return dock * at / dockEdge;
  }
  if (at >= wakeEnd) {
    return 1.0;
  }
  return dock + (1 - dock) * (at - dockEdge) / (wakeEnd - dockEdge);
}

void main() {
  // Passes on the code before #70 too: it pins the ramp the defaults must keep.
  testWidgets('a band at its defaults draws the ramp fades always had: clear, a quarter at the dock, opaque at the end', (
    final tester,
  ) async {
    final List<double> alpha = await _alphaColumn(tester, <HarborEdge, HarborWakeBand>{
      HarborEdge.top: const HarborWakeBand(dockEdge: 40, wakeEnd: 80),
      HarborEdge.bottom: const HarborWakeBand(dockEdge: 20, wakeEnd: 60),
    });
    for (int y = 0; y < _height; y++) {
      final double expected = y < _height / 2
          ? _straight(y, 40, 80, 0.25)
          : _straight(_height.toInt() - 1 - y, 20, 60, 0.25);
      expect(alpha[y], moreOrLessEquals(expected, epsilon: 2 / 255), reason: 'row $y');
    }
  });

  testWidgets("a band's dockOpacity is the opacity at the dock's face, on either edge", (final tester) async {
    final List<double> alpha = await _alphaColumn(tester, <HarborEdge, HarborWakeBand>{
      HarborEdge.top: const HarborWakeBand(dockEdge: 40, wakeEnd: 80, dockOpacity: 0.6),
      HarborEdge.bottom: const HarborWakeBand(dockEdge: 20, wakeEnd: 60, dockOpacity: 1.0),
    });
    for (int y = 0; y < _height; y++) {
      final double expected = y < _height / 2
          ? _straight(y, 40, 80, 0.6)
          : _straight(_height.toInt() - 1 - y, 20, 60, 1.0);
      expect(alpha[y], moreOrLessEquals(expected, epsilon: 2 / 255), reason: 'row $y');
    }
    // Opacity 1 at the dock: the band past the dock's face does not fade.
    expect(alpha.sublist(100, _height.toInt() - 20), everyElement(moreOrLessEquals(1.0, epsilon: 1 / 255)));
  });

  testWidgets("a band's curve shapes the ramp out to the wake's end", (final tester) async {
    final List<double> alpha = await _alphaColumn(tester, <HarborEdge, HarborWakeBand>{
      HarborEdge.top: const HarborWakeBand(dockEdge: 40, wakeEnd: 160, curve: Curves.easeIn),
      HarborEdge.bottom: const HarborWakeBand(dockEdge: 0, wakeEnd: 30, curve: Curves.easeOut),
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

  testWidgets('HarborWake.fade carries its ramp onto the band it measures, and leaves the defaults unset', (
    final tester,
  ) async {
    Future<HarborWakeBand> bandOf(final HarborWake wake, {final bool nested = false}) async {
      final GlobalKey body = GlobalKey();
      final Widget content = SizedBox.expand(key: body);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: Harbor(
              top: <HarborDock>[HarborDock.pier(wake: wake, child: const SizedBox(height: 50))],
              // A harbor inside the body hands the band on, measured from its own edge.
              body: nested ? Harbor(body: content) : content,
            ),
          ),
        ),
      );
      return HarborWaters.of(body.currentContext!).wakes[HarborEdge.top]!;
    }

    expect(await bandOf(const HarborWake.fade(length: 12)), const HarborWakeBand(dockEdge: 50, wakeEnd: 62));
    expect(
      await bandOf(const HarborWake.fade(length: 12, dockOpacity: 0.6, curve: Curves.easeIn)),
      const HarborWakeBand(dockEdge: 50, wakeEnd: 62, dockOpacity: 0.6, curve: Curves.easeIn),
    );
    expect(
      await bandOf(const HarborWake.fade(length: 12, dockOpacity: 0.6, curve: Curves.easeIn), nested: true),
      const HarborWakeBand(dockEdge: 50, wakeEnd: 62, dockOpacity: 0.6, curve: Curves.easeIn),
    );
  });

  test('a fade with a ramp of its own is a different wake, and says so', () {
    const HarborWake plain = HarborWake.fade();
    const HarborWake ramped = HarborWake.fade(dockOpacity: 0.5, curve: Curves.easeOut);
    expect(plain, const HarborWake.fade(dockOpacity: 0.25, curve: Curves.linear));
    expect(ramped, isNot(plain));
    expect(const HarborWake.fade(dockOpacity: 0.5), isNot(plain));
    expect(const HarborWake.fade(curve: Curves.easeOut), isNot(plain));
    expect(ramped.hashCode, const HarborWake.fade(dockOpacity: 0.5, curve: Curves.easeOut).hashCode);
    expect(plain.toString(), isNot(contains('dockOpacity')));
    expect(ramped.toString(), allOf(contains('dockOpacity: 0.5'), contains('curve:')));

    const HarborWakeBand band = HarborWakeBand(dockEdge: 1, wakeEnd: 2, dockOpacity: 0.5, curve: Curves.easeOut);
    expect(band, isNot(const HarborWakeBand(dockEdge: 1, wakeEnd: 2)));
    expect(band.hashCode, isNot(const HarborWakeBand(dockEdge: 1, wakeEnd: 2).hashCode));
    expect(band.toString(), contains('dockOpacity: 0.5'));
    expect(const HarborWakeBand(dockEdge: 1, wakeEnd: 2).toString(), 'HarborWakeBand(1.0 → 2.0)');
  });
}
