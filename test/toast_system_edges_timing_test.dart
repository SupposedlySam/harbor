// HarborFlares.raise(reachesCoast:) (#100), a toast's countdown: countsEntrance and a settable
// duration (#101), and what a toast's transition can know of where it hangs (#103).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<void> _step(final WidgetTester tester, [final int times = 5]) async {
  for (int i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<BuildContext> _page(
  final WidgetTester tester, {
  final List<HarborBar> bottom = const <HarborBar>[],
  final bool root = true,
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
}) async {
  late BuildContext page;
  final Widget body = Builder(
    builder: (final c) {
      page = c;
      return const SizedBox.expand();
    },
  );
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: root ? (final c, final child) => HarborRoot(child: child!) : null,
      home: root ? HarborFrame(bottom: bottom, body: body) : body,
    ),
    device: device,
  );
  return page;
}

void main() {
  group('#100 a toast that reaches the system edges', () {
    late EdgeInsets padding;
    Widget bar(final BuildContext c) {
      padding = MediaQuery.paddingOf(c);
      return const SizedBox(key: ValueKey<String>('bar'), height: 40, width: double.infinity);
    }

    testWidgets('positive control: by default a low bar stops at the home indicator', (final tester) async {
      final BuildContext page = await _page(tester);
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
        builder: bar,
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'bar'), const Rect.fromLTRB(0, 874 - 34 - 40, 402, 874 - 34));
    });

    testWidgets('a low bar runs down over the home indicator and is handed it as padding', (final tester) async {
      final BuildContext page = await _page(tester);
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
        reachesSystemEdges: true,
        builder: bar,
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'bar'), const Rect.fromLTRB(0, 874 - 40, 402, 874));
      expect(padding, const EdgeInsets.only(bottom: 34));
    });

    testWidgets('it still keeps off the bars: above a tab bar that took the home indicator, with no padding', (
      final tester,
    ) async {
      final BuildContext page = await _page(
        tester,
        bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(key: ValueKey<String>('tabs'), height: 56))],
      );
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
        reachesSystemEdges: true,
        builder: bar,
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'bar').bottom, _rect(tester, 'tabs').top - 0);
      expect(padding.bottom, 0);
    });

    testWidgets('on a phone on its side it runs over the side insets too', (final tester) async {
      final BuildContext page = await _page(tester, device: HarborTrialDevice.iPhone17Landscape);
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
        reachesSystemEdges: true,
        builder: bar,
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'bar'), const Rect.fromLTRB(0, 402 - 40, 874, 402));
      expect(padding, const EdgeInsets.fromLTRB(62, 0, 62, 21));
    });

    testWidgets('at the top it runs under the status bar, and only the top is handed over', (final tester) async {
      final BuildContext page = await _page(tester);
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.top.alignment, margin: EdgeInsets.zero),
        reachesSystemEdges: true,
        builder: bar,
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'bar').top, 0);
      expect(padding, const EdgeInsets.only(top: 62));
    });

    testWidgets('with no frame, in an overlay, the same', (final tester) async {
      final BuildContext page = await _page(tester, root: false);
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
        reachesSystemEdges: true,
        builder: bar,
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'bar'), const Rect.fromLTRB(0, 874 - 40, 402, 874));
      expect(padding, const EdgeInsets.only(bottom: 34));
    });
  });

  group('#101 a toast\'s countdown', () {
    Future<HarborToastEntry> show(final WidgetTester tester, {final bool countsEntrance = false}) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        builder: (final c) => const Text('toast'),
        timing: HarborToastTiming(duration: const Duration(seconds: 1), countsEntrance: countsEntrance),
      );
      await tester.pump();
      return entry;
    }

    testWidgets('positive control: by default the second starts after the 220 ms entrance', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 850));
      expect(entry.showing.value, isTrue, reason: '1150 ms after the raise, 930 into its second');
    });

    testWidgets('countsEntrance: the second includes the entrance', (final tester) async {
      final HarborToastEntry entry = await show(tester, countsEntrance: true);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 750));
      expect(entry.showing.value, isFalse, reason: 'gone 1050 ms after the raise');
    });

    testWidgets('setting the duration starts the time over with it', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 800));
      entry.duration = const Duration(seconds: 3);
      await tester.pump(const Duration(milliseconds: 2900));
      expect(entry.showing.value, isTrue, reason: 'its three seconds started over at the change');
      await tester.pump(const Duration(milliseconds: 200));
      expect(entry.showing.value, isFalse);
    });

    testWidgets('setting it to null stops it timing out', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      await tester.pump(const Duration(milliseconds: 300));
      entry.duration = null;
      await tester.pump(const Duration(seconds: 10));
      expect(entry.showing.value, isTrue);
    });
  });

  group('#103 a toast\'s transition and its anchor', () {
    testWidgets('the builder and the transition find their own entry; outside a toast there is none', (
      final tester,
    ) async {
      final BuildContext page = await _page(tester);
      HarborToastEntry? fromBuilder;
      HarborToastEntry? fromTransition;
      final HarborToastEntry entry = HarborToasts.show(
        page,
        transitionBuilder: (final c, final animation, final child) {
          fromTransition = HarborToastEntry.maybeOf(c);
          return child;
        },
        builder: (final c) {
          fromBuilder = HarborToastEntry.maybeOf(c);
          return const Text('toast');
        },
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(fromBuilder, same(entry));
      expect(fromTransition, same(entry));
      expect(HarborToastEntry.maybeOf(page), isNull);
    });

    testWidgets('a hold taken from inside the builder holds the toast', (final tester) async {
      final BuildContext page = await _page(tester);
      late BuildContext inside;
      final HarborToastEntry entry = HarborToasts.show(
        page,
        builder: (final c) {
          inside = c;
          return const Text('toast');
        },
        timing: const HarborToastTiming(duration: Duration(seconds: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      HarborToastEntry.maybeOf(inside)!.hold();
      await tester.pump(const Duration(seconds: 3));
      expect(entry.showing.value, isTrue);
    });

    for (final (HarborAnchorSide side, String label) in const <(HarborAnchorSide, String)>[
      (HarborAnchorSide.below, 'below'),
      (HarborAnchorSide.above, 'above'),
    ]) {
      testWidgets('HarborAnchorClip clips at the anchor\'s $label edge', (final tester) async {
        final HarborAnchor anchor = HarborAnchor(debugLabel: 'field');
        late BuildContext page;
        await tester.pumpHarborTrial(
          MaterialApp(
            builder: (final c, final child) => HarborRoot(child: child!),
            home: HarborFrame(
              body: Builder(
                builder: (final c) {
                  page = c;
                  return Center(
                    child: HarborAnchorPoint(
                      anchor: anchor,
                      child: const SizedBox(key: ValueKey<String>('field'), width: 200, height: 40),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        HarborToasts.show(
          page,
          placement: HarborAnchored(anchor, side: side),
          transitionBuilder: (final c, final animation, final child) {
            final HarborToastEntry entry = HarborToastEntry.maybeOf(c)!;
            return HarborAnchorClip(
              key: const ValueKey<String>('clip'),
              anchor: entry.anchor!,
              side: entry.side,
              child: child,
            );
          },
          builder: (final c) => const SizedBox(width: 120, height: 30),
          timing: HarborToastTiming.untilHidden,
        );
        await _step(tester);
        final Rect field = _rect(tester, 'field');
        final Offset clipOrigin = tester.getTopLeft(find.byKey(const ValueKey<String>('clip')));
        final Rect expected = side == HarborAnchorSide.below
            ? Rect.fromLTRB(-1e6, field.bottom - clipOrigin.dy, 1e6, 1e6)
            : Rect.fromLTRB(-1e6, -1e6, 1e6, field.top - clipOrigin.dy);
        expect(find.byKey(const ValueKey<String>('clip')), paints..clipRect(rect: expected));
      });
    }
  });

  testWidgets('#102 a popover shown in initState is up and takes taps in its first frame', (
    final tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (final c, final child) => HarborRoot(child: child!),
        home: HarborFrame(
          body: Center(child: _ShownFromTheStart(onTap: () => taps++)),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey<String>('menu'))));
    expect(taps, 1);
  });
}

class _ShownFromTheStart extends StatefulWidget {
  const _ShownFromTheStart({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ShownFromTheStart> createState() => _ShownFromTheStartState();
}

class _ShownFromTheStartState extends State<_ShownFromTheStart> {
  final OverlayPortalController _menu = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _menu.show();
  }

  @override
  Widget build(final BuildContext context) => HarborPopover(
    controller: _menu,
    popoverBuilder: (final BuildContext _) => GestureDetector(
      onTap: widget.onTap,
      child: const ColoredBox(
        key: ValueKey<String>('menu'),
        color: Color(0xFF000000),
        child: SizedBox(width: 50, height: 50),
      ),
    ),
    child: const SizedBox(width: 40, height: 40),
  );
}
