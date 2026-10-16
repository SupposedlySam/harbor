// Found by the rotation audit: a widget kept in sight was left under the keyboard when the device
// turned. It re-revealed only when the bottom clearance grew in raw pixels, and turning to
// landscape shrinks that number (336 to 200) while the room above it drops from 538 to 202.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// Puts the view in [device]'s shape, with its keyboard up or down, as a turn would. The view takes
/// physical pixels, at the pixel ratio the trial put on it.
void _turnTo(final WidgetTester tester, final HarborTrialDevice device, {required final bool keyboardShown}) {
  final double ratio = tester.view.devicePixelRatio;
  final EdgeInsets systemEdges = device.systemEdgesWhen(keyboardShown: keyboardShown) * ratio;
  final EdgeInsets viewPadding = device.systemEdges * ratio;
  tester.view
    ..physicalSize = device.size * ratio
    ..padding = FakeViewPadding(
      left: systemEdges.left,
      top: systemEdges.top,
      right: systemEdges.right,
      bottom: systemEdges.bottom,
    )
    ..viewPadding = FakeViewPadding(
      left: viewPadding.left,
      top: viewPadding.top,
      right: viewPadding.right,
      bottom: viewPadding.bottom,
    )
    ..viewInsets = FakeViewPadding(bottom: (keyboardShown ? device.keyboardHeight : 0.0) * ratio);
}

void main() {
  for (final bool bodyClearsKeyboard in <bool>[true, false]) {
    testWidgets('kept in sight, a widget is revealed after a turn hides it (bodyClearsKeyboard: $bodyClearsKeyboard)', (
      final tester,
    ) async {
      final HarborTrial trial = await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            bodyClearsKeyboard: bodyClearsKeyboard,
            body: const HarborScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: SizedBox(height: 420)),
                SliverToBoxAdapter(
                  child: HarborKeepVisible(child: SizedBox(key: ValueKey<String>('field'), height: 40)),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 1500)),
              ],
            ),
          ),
        ),
      );
      await trial.showKeyboard(settle: true);
      final Rect portrait = tester.getRect(find.byKey(const ValueKey<String>('field')));
      expect(portrait.bottom, lessThanOrEqualTo(trial.keyboardTop), reason: 'positive control: in sight in portrait');

      const HarborTrialDevice landscape = HarborTrialDevice.iPhone17Landscape;
      _turnTo(tester, landscape, keyboardShown: true);
      await tester.pumpAndSettle();
      final double keyboardTop = landscape.size.height - landscape.keyboardHeight;
      // Scrolled far enough out of sight, the list does not even build it.
      expect(
        find.byKey(const ValueKey<String>('field')),
        findsOneWidget,
        reason: 'it is near enough to the water to be built',
      );
      expect(tester.getRect(find.byKey(const ValueKey<String>('field'))).bottom, lessThanOrEqualTo(keyboardTop + 0.5));
    });
  }
}
