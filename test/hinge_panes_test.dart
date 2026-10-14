// HarborPanes (hinge API 3 of 4): two panes either side of a hinge, side by side when wide enough,
// one alone otherwise; each pane a screen of its own.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540, 720 high
final HarborTrialDevice _tall = _dual.copyWith(
  name: 'dual screen tall',
  size: const Size(720, 1114),
  displayFeatures: const <DisplayFeature>[
    DisplayFeature(
      bounds: Rect.fromLTRB(0, 540, 720, 574),
      type: DisplayFeatureType.hinge,
      state: DisplayFeatureState.postureFlat,
    ),
  ],
);
const HarborTrialDevice _tablet = HarborTrialDevice(
  name: 'tablet',
  size: Size(1024, 768),
  systemEdges: EdgeInsets.only(top: 24, bottom: 20),
  keyboardHeight: 300,
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

final Map<String, MediaQueryData> _seen = <String, MediaQueryData>{};
HarborPanesMode? _mode;

Widget _pane(final String key) => Builder(
  builder: (final BuildContext context) {
    _seen[key] = MediaQuery.of(context);
    _mode = HarborPanes.modeOf(context);
    return SizedBox.expand(key: ValueKey<String>(key));
  },
);

Future<void> _pump(
  final WidgetTester tester, {
  required final HarborTrialDevice device,
  final TextDirection direction = TextDirection.ltr,
  final HarborPanePriority priority = HarborPanePriority.start,
  final HarborHinge? hinge,
  final double minTallHeight = double.infinity,
}) {
  _seen.clear();
  return tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => Directionality(
        textDirection: direction,
        child: HarborRoot(child: child!),
      ),
      home: HarborPanes(
        start: _pane('list'),
        end: _pane('detail'),
        priority: priority,
        hinge: hinge,
        minTallHeight: minTallHeight,
      ),
    ),
    device: device,
  );
}

void main() {
  testWidgets('either side of a vertical hinge, start where reading starts', (final tester) async {
    await _pump(tester, device: _dual);
    expect(_rect(tester, 'list'), const Rect.fromLTRB(0, 0, 540, 720));
    expect(_rect(tester, 'detail'), const Rect.fromLTRB(574, 0, 1114, 720));
    expect(_mode, HarborPanesMode.wide);
  });

  testWidgets('right to left, start is the right-hand screen', (final tester) async {
    await _pump(tester, device: _dual, direction: TextDirection.rtl);
    expect(_rect(tester, 'list'), const Rect.fromLTRB(574, 0, 1114, 720));
    expect(_rect(tester, 'detail'), const Rect.fromLTRB(0, 0, 540, 720));
  });

  testWidgets('each pane is a screen of its own: its size, the coast on its outer edges, no hinge', (
    final tester,
  ) async {
    await _pump(tester, device: _dual);
    final MediaQueryData list = _seen['list']!;
    expect(list.size, const Size(540, 720));
    expect(list.padding, const EdgeInsets.only(top: 24, bottom: 24));
    expect(list.displayFeatures, isEmpty, reason: 'the hinge is beside it, not in it');
  });

  testWidgets('above and below a horizontal hinge, start on top', (final tester) async {
    await _pump(tester, device: _tall);
    expect(_rect(tester, 'list'), const Rect.fromLTRB(0, 0, 720, 540));
    expect(_rect(tester, 'detail'), const Rect.fromLTRB(0, 574, 720, 1114));
    expect(_mode, HarborPanesMode.tall);
    expect(_seen['list']!.padding.bottom, 0, reason: 'the bottom coast is the lower pane\'s');
    expect(_seen['detail']!.padding.top, 0);
  });

  testWidgets('a tablet with no hinge, wide enough: side by side, halved', (final tester) async {
    await _pump(tester, device: _tablet);
    expect(_rect(tester, 'list'), const Rect.fromLTRB(0, 0, 512, 768));
    expect(_rect(tester, 'detail'), const Rect.fromLTRB(512, 0, 1024, 768));
  });

  testWidgets('a phone: the priority pane alone', (final tester) async {
    await _pump(tester, device: HarborTrialDevice.iPhone17);
    expect(find.byKey(const ValueKey<String>('list')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('detail')), findsNothing);
    expect(_mode, HarborPanesMode.single);
    await _pump(tester, device: HarborTrialDevice.iPhone17, priority: HarborPanePriority.end);
    expect(find.byKey(const ValueKey<String>('detail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('list')), findsNothing);
  });

  testWidgets('with a policy that keeps off nothing, the hinge does not split it: the width does', (
    final tester,
  ) async {
    await _pump(tester, device: _dual, hinge: HarborHinge.never);
    expect(_rect(tester, 'list'), const Rect.fromLTRB(0, 0, 557, 720));
  });

  testWidgets('minTallHeight stacks the panes on a tall screen with no hinge', (final tester) async {
    await _pump(tester, device: HarborTrialDevice.iPhone17, minTallHeight: 600);
    expect(_rect(tester, 'list'), const Rect.fromLTRB(0, 0, 402, 437));
    expect(_rect(tester, 'detail'), const Rect.fromLTRB(0, 437, 402, 874));
  });

  testWidgets('a pane can be a harbor with docks of its own', (final tester) async {
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: const HarborPanes(
          start: HarborFrame(
            bottom: <HarborBar>[
              HarborBar.solid(
                child: SizedBox(key: ValueKey<String>('tabs'), height: 56, width: double.infinity),
              ),
            ],
            body: SizedBox.expand(),
          ),
          end: HarborFrame(body: SizedBox.expand()),
        ),
      ),
      device: _dual,
    );
    expect(_rect(tester, 'tabs'), const Rect.fromLTRB(0, 720 - 24 - 56, 540, 720 - 24));
  });
}
