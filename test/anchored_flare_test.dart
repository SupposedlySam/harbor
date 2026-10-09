// HarborFlares.raise(anchor:) (#65): a flare by a HarborAnchorPoint, as a HarborBuoy.anchored sits
// by one. Before #65 a flare could only be raised at a slot or an alignment of the clear water.

import 'dart:async';
import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

final Finder _button = find.byKey(const ValueKey<String>('button'));

Widget _toast(final String key) =>
    SizedBox(key: ValueKey<String>(key), width: 200, height: 30, child: const ColoredBox(color: Color(0xFF000000)));

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

/// A page with a 100 x 40 button in the middle, anchored to [anchor] while [present] says so.
Widget _page({required final HarborAnchor anchor, required final ValueSetter<BuildContext> onContext, final ValueListenable<bool>? present}) =>
    Builder(
      builder: (final BuildContext context) {
        onContext(context);
        final Widget button = HarborAnchorPoint(
          anchor: anchor,
          child: const SizedBox(key: ValueKey<String>('button'), width: 100, height: 40),
        );
        return Center(
          child: present == null
              ? button
              : ValueListenableBuilder<bool>(
                  valueListenable: present,
                  builder: (final BuildContext context, final bool present, final Widget? _) => present ? button : const SizedBox(),
                ),
        );
      },
    );

Widget _app(final Widget home, {final GlobalKey<NavigatorState>? navigator}) => MaterialApp(
  navigatorKey: navigator,
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: Material(child: home),
);

void main() {
  late HarborAnchor anchor;

  setUp(() => anchor = HarborAnchor(debugLabel: 'button'));
  tearDown(() => anchor.dispose());

  testWidgets('sits below its anchor by default, 8 away and centred on it', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(_app(Harbor(body: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))));
    HarborFlares.raise(page, anchor: anchor, duration: null, builder: (final BuildContext _) => _toast('toast'));
    await tester.pumpAndSettle();
    final Rect button = tester.getRect(_button);
    expect(_rect(tester, 'toast').top, button.bottom + 8);
    expect(_rect(tester, 'toast').center.dx, button.center.dx);
  });

  testWidgets('takes its side, gap and cross alignment, as an anchored buoy does', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(_app(Harbor(body: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))));
    HarborFlares.raise(
      page,
      anchor: anchor,
      side: HarborBuoySide.above,
      gap: 12,
      crossAlignment: HarborBuoyCrossAlignment.start,
      duration: null,
      builder: (final BuildContext _) => _toast('toast'),
    );
    await tester.pumpAndSettle();
    final Rect button = tester.getRect(_button);
    expect(_rect(tester, 'toast').bottom, button.top - 12);
    expect(_rect(tester, 'toast').left, button.left);
  });

  testWidgets('keeps the live region and the dismiss action', (final tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    late BuildContext page;
    await tester.pumpSeaTrial(_app(Harbor(body: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))));
    final HarborFlareEntry entry = HarborFlares.raise(
      page,
      anchor: anchor,
      duration: null,
      builder: (final BuildContext _) => const Text('Copied'),
    );
    HarborFlareClosedReason? reason;
    unawaited(entry.closed.then((final HarborFlareClosedReason r) => reason = r));
    await tester.pumpAndSettle();
    expect(find.semantics.byFlag(SemanticsFlag.isLiveRegion).evaluate().single.label, 'Copied');
    tester.semantics.performAction(find.semantics.byFlag(SemanticsFlag.isLiveRegion), SemanticsAction.dismiss);
    await tester.pumpAndSettle();
    expect(reason, HarborFlareClosedReason.dismiss);
    semantics.dispose();
  });

  testWidgets('is given its anchor alone, without a slot or an alignment', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(_app(Harbor(body: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))));
    expect(
      () => HarborFlares.raise(page, anchor: anchor, slot: HarborFlareSlot.low, builder: (final BuildContext _) => _toast('toast')),
      throwsAssertionError,
    );
    expect(
      () => HarborFlares.raise(page, anchor: anchor, alignment: Alignment.center, builder: (final BuildContext _) => _toast('toast')),
      throwsAssertionError,
    );
  });

  group('take turns', () {
    testWidgets('per anchor and side, so two at one anchor and side are shown one at a time', (final tester) async {
      final HarborAnchor other = HarborAnchor(debugLabel: 'other');
      addTearDown(other.dispose);
      late BuildContext page;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _page(anchor: anchor, onContext: (final BuildContext c) => page = c),
                const SizedBox(height: 200),
                HarborAnchorPoint(anchor: other, child: const SizedBox(width: 100, height: 40)),
              ],
            ),
          ),
        ),
      );
      final HarborFlareEntry first = HarborFlares.raise(page, anchor: anchor, duration: null, builder: (final BuildContext _) => _toast('first'));
      HarborFlares.raise(page, anchor: anchor, duration: null, builder: (final BuildContext _) => _toast('second'));
      HarborFlares.raise(page, anchor: anchor, side: HarborBuoySide.above, duration: null, builder: (final BuildContext _) => _toast('above'));
      HarborFlares.raise(page, anchor: other, duration: null, builder: (final BuildContext _) => _toast('other'));
      HarborFlares.raise(page, duration: null, builder: (final BuildContext _) => _toast('slot'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('first')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('second')), findsNothing, reason: 'it waits behind the first at the same anchor and side');
      expect(find.byKey(const ValueKey<String>('above')), findsOneWidget, reason: 'another side is another place');
      expect(find.byKey(const ValueKey<String>('other')), findsOneWidget, reason: 'another anchor is another place');
      expect(find.byKey(const ValueKey<String>('slot')), findsOneWidget, reason: 'a flare at a slot is another place');

      first.lower();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('first')), findsNothing);
      expect(find.byKey(const ValueKey<String>('second')), findsOneWidget);
    });
  });

  testWidgets('while its anchor is out of the tree, is not shown and its time stops', (final tester) async {
    final ValueNotifier<bool> present = ValueNotifier<bool>(true);
    addTearDown(present.dispose);
    late BuildContext page;
    await tester.pumpSeaTrial(
      _app(Harbor(body: _page(anchor: anchor, present: present, onContext: (final BuildContext c) => page = c))),
    );
    final HarborFlareEntry entry = HarborFlares.raise(
      page,
      anchor: anchor,
      duration: const Duration(seconds: 1),
      builder: (final BuildContext _) => _toast('toast'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('toast')).hitTestable(), findsOneWidget, reason: 'positive control: it is up');

    present.value = false;
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('toast')).hitTestable(), findsNothing, reason: 'with no anchor it takes no taps');
    await tester.pump(const Duration(seconds: 3));
    expect(entry.showing.value, isTrue, reason: 'its time stopped while nobody could see it');

    present.value = true;
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('toast')).hitTestable(), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(entry.showing.value, isFalse, reason: 'its time ran once the anchor was back');
    await tester.pumpAndSettle();
  });

  testWidgets("if its page is popped, is lowered with remove rather than moving to the port on top", (final tester) async {
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpSeaTrial(_app(const Harbor(body: SizedBox.expand()), navigator: navigator));
    late BuildContext page;
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (final BuildContext _) => Material(child: Harbor(body: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))),
    )));
    await tester.pumpAndSettle();
    final HarborFlareEntry anchored = HarborFlares.raise(page, anchor: anchor, duration: null, builder: (final BuildContext _) => _toast('anchored'));
    final HarborFlareEntry slotted = HarborFlares.raise(page, duration: null, builder: (final BuildContext _) => _toast('slotted'));
    HarborFlareClosedReason? reason;
    unawaited(anchored.closed.then((final HarborFlareClosedReason r) => reason = r));
    await tester.pumpAndSettle();

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(reason, HarborFlareClosedReason.remove);
    expect(find.byKey(const ValueKey<String>('anchored')), findsNothing);
    expect(find.byKey(const ValueKey<String>('slotted')), findsOneWidget, reason: 'positive control: a flare at a slot moves to the port now on top');
    slotted.lower();
    await tester.pumpAndSettle();
  });

  testWidgets('is shown by the page that raised it, not a dialog over it', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(_app(Harbor(body: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))));
    unawaited(showHarborDialog<void>(page, builder: (final BuildContext _) => const Harbor(body: SizedBox.expand())));
    await tester.pumpAndSettle();
    final HarborFlareEntry anchored = HarborFlares.raise(page, anchor: anchor, duration: null, builder: (final BuildContext _) => _toast('anchored'));
    final HarborFlareEntry slotted = HarborFlares.raise(page, duration: null, builder: (final BuildContext _) => _toast('slotted'));
    await tester.pump();
    expect(anchored.owner, same(Harbor.of(page)));
    expect(slotted.owner, isNot(same(Harbor.of(page))), reason: 'positive control: a flare at a slot goes to the port on top');
    anchored.lower();
    slotted.lower();
    await tester.pumpAndSettle();
  });

  testWidgets('without a harbor, sits by its anchor in the nearest overlay', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(MaterialApp(home: Material(child: _page(anchor: anchor, onContext: (final BuildContext c) => page = c))));
    final HarborFlareEntry entry = HarborFlares.raise(page, anchor: anchor, duration: null, builder: (final BuildContext _) => _toast('toast'));
    await tester.pumpAndSettle();
    final Rect button = tester.getRect(_button);
    expect(_rect(tester, 'toast').top, button.bottom + 8);
    expect(_rect(tester, 'toast').center.dx, button.center.dx);
    entry.lower();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('toast')), findsNothing);
  });
}
