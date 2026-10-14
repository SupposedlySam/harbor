// HarborPosture (hinge API 4 of 4): flat, tabletop or book, from the fold; and a tabletop page
// with its content above the fold and its controls below.

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

DisplayFeature _fold(final Rect bounds, final DisplayFeatureState state) =>
    DisplayFeature(bounds: bounds, type: DisplayFeatureType.fold, state: state);

// A foldable half open on a table: 750 by 832, the fold across it at 416.
final HarborTrialDevice _tabletop = HarborTrialDevice.foldableOpen.copyWith(
  name: 'foldable tabletop',
  displayFeatures: <DisplayFeature>[
    _fold(const Rect.fromLTRB(0, 416, 750, 416), DisplayFeatureState.postureHalfOpened),
  ],
);

void main() {
  group('the posture each fold describes', () {
    test('half open across the screen: tabletop', () {
      expect(
        HarborPosture.from(<DisplayFeature>[
          _fold(const Rect.fromLTRB(0, 416, 750, 416), DisplayFeatureState.postureHalfOpened),
        ]),
        HarborPosture.tabletop,
      );
    });
    test('half open down the middle: book', () {
      expect(
        HarborPosture.from(<DisplayFeature>[
          _fold(const Rect.fromLTRB(375, 0, 375, 832), DisplayFeatureState.postureHalfOpened),
        ]),
        HarborPosture.book,
      );
    });
    test('flat, or a dual-screen hinge lying flat, or no fold: flat', () {
      expect(
        HarborPosture.from(<DisplayFeature>[
          _fold(const Rect.fromLTRB(375, 0, 375, 832), DisplayFeatureState.postureFlat),
        ]),
        HarborPosture.flat,
      );
      expect(HarborPosture.from(HarborTrialDevice.dualScreenOpen.displayFeatures), HarborPosture.flat);
      expect(HarborPosture.from(const <DisplayFeature>[]), HarborPosture.flat);
    });
  });

  testWidgets('a tabletop page: content above the fold, controls below, each its own screen', (final tester) async {
    late HarborPosture posture;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: Builder(
          builder: (final BuildContext context) {
            posture = HarborPosture.of(context);
            return const HarborPanes(
              start: SizedBox.expand(key: ValueKey<String>('video')),
              end: HarborFrame(
                bottom: <HarborBar>[
                  HarborBar.solid(
                    child: SizedBox(key: ValueKey<String>('controls'), height: 64, width: double.infinity),
                  ),
                ],
                body: SizedBox.expand(),
              ),
            );
          },
        ),
      ),
      device: _tabletop,
    );
    expect(posture, HarborPosture.tabletop);
    expect(tester.getRect(find.byKey(const ValueKey<String>('video'))), const Rect.fromLTRB(0, 0, 750, 416));
    expect(tester.getRect(find.byKey(const ValueKey<String>('controls'))).top, greaterThanOrEqualTo(416));
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('controls'))).bottom,
      832 - 24,
      reason: 'over the bottom coast of the lower screen',
    );
  });
}
