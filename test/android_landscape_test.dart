// An Android phone on its side with three-button navigation: the status bar stays on top and the
// navigation bar moves to the right, so the right is a side coast with nothing on the left. A pier
// clears the status bar and the side coast, and so does what is moored in the body, in either
// reading direction: the bar is on the physical right whichever side the end is.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _device = HarborTrialDevice.androidThreeButtonLandscape;

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Widget _page({final TextDirection direction = TextDirection.ltr}) => MaterialApp(
  builder: (final c, final child) => Directionality(
    textDirection: direction,
    child: HarborRoot(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  ),
  home: const HarborFrame(
    top: <HarborBar>[
      HarborBar.overlay(
        child: HarborClear.rowInsets(
          child: SizedBox(key: ValueKey<String>('title'), height: 40, width: double.infinity),
        ),
      ),
    ],
    body: HarborClear(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(key: ValueKey<String>('row'), height: 40, width: double.infinity),
      ),
    ),
  ),
);

void main() {
  testWidgets('positive control: the device puts its navigation bar on the right', (final tester) async {
    await tester.pumpHarborTrial(_page(), device: _device);
    expect(MediaQueryData.fromView(tester.view).padding, const EdgeInsets.only(top: 24, right: 48));
  });

  testWidgets('a pier clears the status bar and the navigation bar on the side', (final tester) async {
    await tester.pumpHarborTrial(_page(), device: _device);
    expect(_rect(tester, 'title').top, 24, reason: 'below the status bar');
    expect(_rect(tester, 'title').left, 16, reason: 'no coast on the left: the margin alone');
    expect(_rect(tester, 'title').right, 915 - 48 - 16, reason: 'clear of the navigation bar, then the margin');
  });

  testWidgets('what is moored in the body clears the pier and the side coast', (final tester) async {
    await tester.pumpHarborTrial(_page(), device: _device);
    expect(_rect(tester, 'row').top, greaterThanOrEqualTo(_rect(tester, 'title').bottom));
    // Moored keeps off the coast; the margin is a mooring line's, so none is added here.
    expect(_rect(tester, 'row').left, 0);
    expect(_rect(tester, 'row').right, 915 - 48);
  });

  testWidgets('right to left, the navigation bar is still on the right, now the start side', (final tester) async {
    await tester.pumpHarborTrial(_page(direction: TextDirection.rtl), device: _device);
    expect(_rect(tester, 'title').right, 915 - 48 - 16);
    expect(_rect(tester, 'title').left, 16);
    expect(_rect(tester, 'row').right, 915 - 48);
    expect(_rect(tester, 'row').left, 0);
  });
}
