// Docks keep off a separating hinge (hinge API 2 of 4): a bar is moved to one side rather than
// laid across it, as Microsoft's dual-screen guidance and Android's foldable guidance both ask.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540, 720 high
const HarborTrialDevice _flat = HarborTrialDevice.foldableOpen; // 750 wide, flat fold at 375
// A dual-screen device turned on its side: the screens one above the other.
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

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Widget _bar(final String key, final double height) =>
    SizedBox(key: ValueKey<String>(key), height: height, width: double.infinity);

Future<void> _page(
  final WidgetTester tester, {
  required final HarborTrialDevice device,
  final HarborHinge? hinge,
  final TextDirection direction = TextDirection.ltr,
  final List<HarborBar> start = const <HarborBar>[],
}) => tester.pumpHarborTrial(
  MaterialApp(
    builder: (final BuildContext context, final Widget? child) => Directionality(
      textDirection: direction,
      child: HarborRoot(child: child!),
    ),
    home: HarborFrame(
      hinge: hinge,
      top: <HarborBar>[HarborBar.overlay(child: _bar('header', 56))],
      bottom: <HarborBar>[HarborBar.solid(child: _bar('tabs', 56))],
      start: start,
      body: const SizedBox.expand(key: ValueKey<String>('body')),
    ),
  ),
  device: device,
);

void main() {
  testWidgets('positive control: on a phone the header and tab bar run the full width', (final tester) async {
    await _page(tester, device: HarborTrialDevice.iPhone17);
    expect(_rect(tester, 'tabs').width, 402);
  });

  testWidgets('across a hinge, the header and tab bar keep to the screen where reading starts', (final tester) async {
    await _page(tester, device: _dual);
    expect(_rect(tester, 'header').left, 0);
    expect(_rect(tester, 'header').right, 540);
    expect(_rect(tester, 'tabs').left, 0);
    expect(_rect(tester, 'tabs').right, 540);
    expect(_rect(tester, 'body').width, 1114, reason: 'the body still runs across: a page is one canvas');
  });

  testWidgets('right to left, that is the right-hand screen', (final tester) async {
    await _page(tester, device: _dual, direction: TextDirection.rtl);
    expect(_rect(tester, 'tabs').left, 574);
    expect(_rect(tester, 'tabs').right, 1114);
  });

  testWidgets('a page that keeps off nothing lays them across', (final tester) async {
    await _page(tester, device: _dual, hinge: HarborHinge.never);
    expect(_rect(tester, 'tabs').width, 1114);
  });

  testWidgets('a flat fold is run across by default, and kept off with always', (final tester) async {
    await _page(tester, device: _flat);
    expect(_rect(tester, 'tabs').width, 750);
    await _page(tester, device: _flat, hinge: HarborHinge.always);
    expect(_rect(tester, 'tabs').right, 375);
  });

  testWidgets('a horizontal hinge keeps a rail to the top screen, and leaves the bars alone', (final tester) async {
    await _page(
      tester,
      device: _tall,
      start: const <HarborBar>[
        HarborBar.solid(
          child: SizedBox(key: ValueKey<String>('rail'), width: 72, height: double.infinity),
        ),
      ],
    );
    expect(_rect(tester, 'rail').top, 0);
    expect(_rect(tester, 'rail').bottom, 540);
    expect(_rect(tester, 'tabs').width, 720 - 72, reason: 'beside the rail, as the corners say');
  });

  testWidgets('a harbor smaller than the screen does not read the hinge', (final tester) async {
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 800,
            height: 600,
            child: HarborFrame(
              bottom: <HarborBar>[HarborBar.solid(child: _bar('tabs', 56))],
              body: const SizedBox.expand(),
            ),
          ),
        ),
      ),
      device: _dual,
    );
    expect(_rect(tester, 'tabs').width, 800);
  });
}
