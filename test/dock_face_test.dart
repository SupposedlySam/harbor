// HarborWaters.dockFaceOf: where the docks on an edge end, with or without a wake (#61).
//
// On an iPhone 17: status bar 62, home indicator 34, a keyboard of 336.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _statusBar = 62;

Widget _bar(final String label, final double height) =>
    SizedBox(key: ValueKey<String>(label), height: height, width: double.infinity, child: Text(label));

Widget _app(final Widget home) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: Material(child: home),
);

/// Records the top dock face each time it is built.
class _FaceReader extends StatelessWidget {
  const _FaceReader(this.seen, {this.edge = HarborEdge.top});

  final List<double> seen;
  final HarborEdge edge;

  @override
  Widget build(final BuildContext context) {
    seen.add(HarborWaters.dockFaceOf(context, edge));
    return const SizedBox.expand();
  }
}

void main() {
  Future<double> faceUnder(final WidgetTester tester, final HarborWake wake) async {
    final List<double> seen = <double>[];
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(wake: wake, child: _bar('header', 50))],
          body: _FaceReader(seen),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(const ValueKey<String>('header'))).bottom, _statusBar + 50, reason: 'positive control');
    return seen.last;
  }

  // Breaks if: the face is read from the docks where a fade wake rests past them.
  testWidgets("is the header's inner face under a fade wake that the content rests past", (final tester) async {
    expect(await faceUnder(tester, const HarborWake.fade(length: 12)), _statusBar + 50);
  });

  // Breaks if: the face is read from the wake band alone, which only a fade wake has.
  testWidgets("is the header's inner face with no wake, a hairline, or a fade that rests at the dock", (final tester) async {
    expect(await faceUnder(tester, HarborWake.none), _statusBar + 50);
    expect(await faceUnder(tester, const HarborWake.hairline()), _statusBar + 50);
    expect(await faceUnder(tester, const HarborWake.fade(length: 12, restsAt: HarborRest.dockEdge)), _statusBar + 50);
  });

  testWidgets('is zero where nothing is docked, the coast left out', (final tester) async {
    final List<double> seen = <double>[];
    await tester.pumpSeaTrial(_app(Harbor(body: _FaceReader(seen, edge: HarborEdge.bottom))));
    expect(seen.last, 0);
  });

  // Breaks if: dockFaceOf reads the waters beyond the docks aspect. On a phone with a home
  // indicator the steady coast's clamp follows the keyboard for such a reader.
  testWidgets('its reader holds still while the keyboard rises', (final tester) async {
    final List<double> seen = <double>[];
    final List<double> keyboard = <double>[];
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          body: Column(
            children: <Widget>[
              SizedBox(height: 10, child: _FaceReader(seen)),
              SizedBox(
                height: 10,
                child: Builder(
                  builder: (final BuildContext context) {
                    keyboard.add(HarborTide.of(context).height);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    seen.clear();
    keyboard.clear();
    await trial.raiseTide();
    expect(keyboard.length, greaterThan(1), reason: 'positive control: the keyboard moved over several frames');
    // At most once, for the home indicator leaving the padding, which the docks' clamp reads.
    expect(seen.length, lessThanOrEqualTo(1));
    expect(seen, everyElement(_statusBar + 50));
  });

  // A reader of the waters as a whole would rebuild when any part of them changes; this one
  // depends on the docks alone. The margin changes and the docks do not.
  // Breaks if: dockFaceOf reads the waters beyond the docks aspect.
  testWidgets('its reader holds still when another part of the waters changes', (final tester) async {
    final List<double> faces = <double>[];
    final List<double> margins = <double>[];
    // Built once, so only what they depend on rebuilds them.
    final Widget body = Column(
      children: <Widget>[
        SizedBox(height: 10, child: _FaceReader(faces)),
        SizedBox(
          height: 10,
          child: Builder(
            builder: (final BuildContext context) {
              margins.add(HarborWaters.of(context, aspect: HarborWatersAspect.margin).margin.start);
              return const SizedBox.expand();
            },
          ),
        ),
      ],
    );
    late StateSetter setState;
    double margin = 0;
    await tester.pumpSeaTrial(
      _app(
        StatefulBuilder(
          builder: (final BuildContext context, final StateSetter set) {
            setState = set;
            return Harbor(
              margin: EdgeInsetsDirectional.symmetric(horizontal: margin),
              top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
              body: body,
            );
          },
        ),
      ),
    );
    faces.clear();
    margins.clear();
    setState(() => margin = 24);
    await tester.pumpAndSettle();
    expect(margins, <double>[24], reason: 'positive control: the margin changed under the reader');
    expect(faces, isEmpty);
  });
}
