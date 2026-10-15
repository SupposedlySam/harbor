// The audit's smaller steps (#120, DECISIONS.md): the new spellings, and the deprecated ones
// forwarding to them with the defaults they had.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _navHeight = 56;

Widget _app(final Widget home) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
  home: home,
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

HarborBar _tabs() => const HarborBar.solid(
  child: SizedBox(key: ValueKey<String>('nav'), height: _navHeight),
);

void main() {
  group('HarborYield merges into HarborBarState', () {
    Future<void> pumpHidden(final WidgetTester tester, final Widget Function(Widget child) hide) =>
        tester.pumpHarborTrial(
          _app(
            HarborFrame(
              bottom: <HarborBar>[_tabs()],
              body: hide(const HarborClear(child: SizedBox.expand(key: ValueKey<String>('body')))),
            ),
          ),
          device: HarborTrialDevice.iPhone17,
        );

    testWidgets('state: dark keeps the bar\'s space; withdrawn, the default, gives it back', (final tester) async {
      await pumpHidden(tester, (final Widget child) => HarborHideBar(edge: HarborEdge.bottom, child: child));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'body').bottom, 874 - 34);

      await pumpHidden(
        tester,
        (final Widget child) => HarborHideBar(edge: HarborEdge.bottom, state: HarborBarState.dark, child: child),
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'body').bottom, 874 - 34 - _navHeight);
    });

    testWidgets('the deprecated mode: forwards to state', (final tester) async {
      await pumpHidden(
        tester,
        (final Widget child) => HarborHideBar(edge: HarborEdge.bottom, mode: HarborYield.dark, child: child),
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'body').bottom, 874 - 34 - _navHeight);
      const HarborHideBar old = HarborHideBar(edge: HarborEdge.top, mode: HarborYield.dark, child: SizedBox());
      expect(old.state, HarborBarState.dark);
      expect(old.mode, HarborYield.dark);
    });

    testWidgets('hideBar takes a state, and a claim reports it', (final tester) async {
      late HarborController frame;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bottom: <HarborBar>[_tabs()],
            body: Builder(
              builder: (final BuildContext context) {
                frame = HarborFrame.of(context);
                return const HarborClear(child: SizedBox.expand(key: ValueKey<String>('body')));
              },
            ),
          ),
        ),
        device: HarborTrialDevice.iPhone17,
      );
      final HarborClaim dark = frame.hideBar(HarborEdge.bottom, state: HarborBarState.dark);
      await tester.pumpAndSettle();
      expect(dark.state, HarborBarState.dark);
      expect(_rect(tester, 'body').bottom, 874 - 34 - _navHeight);
      final HarborClaim withdrawn = frame.hideBar(HarborEdge.bottom);
      await tester.pumpAndSettle();
      expect(withdrawn.state, HarborBarState.withdrawn);
      expect(withdrawn.mode, HarborYield.withdraw);
      expect(_rect(tester, 'body').bottom, 874 - 34);
      withdrawn.release();
      dark.release();
      final HarborClaim old = frame.hideBar(HarborEdge.bottom, mode: HarborYield.dark);
      expect(old.state, HarborBarState.dark);
      old.release();
    });

    test('open is not a way to hide, and state and mode must agree', () {
      expect(
        () => HarborHideBar(edge: HarborEdge.bottom, state: HarborBarState.open, child: const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => HarborHideBar(
          edge: HarborEdge.bottom,
          state: HarborBarState.dark,
          mode: HarborYield.withdraw,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });
}
