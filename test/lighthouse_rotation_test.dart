// Found by the rotation audit: a beacon kept in sight was left under the keyboard when the device
// turned. It re-revealed only when the bottom clearance grew in raw pixels, and turning to
// landscape shrinks that number (336 to 200) while the water above it drops from 538 to 202.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// Puts the view in [device]'s shape, with its keyboard up or down, as a turn would.
void _turnTo(final WidgetTester tester, final HarborTrialDevice device, {required final bool tideIn}) {
  final EdgeInsets coast = device.coastWhen(tideIn: tideIn);
  tester.view
    ..physicalSize = device.size
    ..padding = FakeViewPadding(left: coast.left, top: coast.top, right: coast.right, bottom: coast.bottom)
    ..viewPadding = FakeViewPadding(left: device.coast.left, top: device.coast.top, right: device.coast.right, bottom: device.coast.bottom)
    ..viewInsets = FakeViewPadding(bottom: tideIn ? device.tideHeight : 0.0);
}

void main() {
  for (final bool bodyClearsTide in <bool>[true, false]) {
    testWidgets('a beacon kept in sight is revealed again after a turn hides it (bodyClearsTide: $bodyClearsTide)', (final tester) async {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
          home: Harbor(
            bodyClearsTide: bodyClearsTide,
            body: const HarborFairway(
              slivers: <Widget>[
                SliverToBoxAdapter(child: SizedBox(height: 420)),
                SliverToBoxAdapter(child: HarborBeacon(keepInSight: true, child: SizedBox(key: ValueKey<String>('field'), height: 40))),
                SliverToBoxAdapter(child: SizedBox(height: 1500)),
              ],
            ),
          ),
        ),
      );
      await trial.raiseTide(settle: true);
      final Rect portrait = tester.getRect(find.byKey(const ValueKey<String>('field')));
      expect(portrait.bottom, lessThanOrEqualTo(trial.waterline), reason: 'positive control: in sight in portrait');

      const HarborTrialDevice landscape = HarborTrialDevice.iPhone17Landscape;
      _turnTo(tester, landscape, tideIn: true);
      await tester.pumpAndSettle();
      final double waterline = landscape.size.height - landscape.tideHeight;
      // Scrolled far enough out of sight, the list does not even build it.
      expect(find.byKey(const ValueKey<String>('field')), findsOneWidget, reason: 'it is near enough to the water to be built');
      expect(tester.getRect(find.byKey(const ValueKey<String>('field'))).bottom, lessThanOrEqualTo(waterline + 0.5));
    });
  }
}
