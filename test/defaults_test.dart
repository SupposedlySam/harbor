// HarborDefaults (doc/design/defaults.md, DECISIONS.md Q19-Q22): choices set once on a root, a frame or
// a HarborDefaultsScope, merged field by field with the nearest winning, read by every sheet, dialog,
// float and toast beneath, and carried across the route into what a page opens.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// Pumps a root with [root] defaults and a page frame with [page] defaults, and returns a context
/// inside the page's body.
Future<BuildContext> _page(
  final WidgetTester tester, {
  final HarborDefaults? root,
  final HarborDefaults? page,
  final List<HarborFloat> floats = const <HarborFloat>[],
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
  final Widget Function(Widget body)? wrap,
}) async {
  late BuildContext inside;
  final Widget body = Builder(
    builder: (final BuildContext context) {
      inside = context;
      return const SizedBox.expand();
    },
  );
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(defaults: root, child: child!),
      home: HarborFrame(defaults: page, floats: floats, body: wrap?.call(body) ?? body),
    ),
    device: device,
  );
  return inside;
}

Future<void> _step(final WidgetTester tester, [final int times = 5]) async {
  for (int i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _toast(final BuildContext _) => const SizedBox(key: ValueKey<String>('toast'), width: 2000, height: 40);

void main() {
  group('the value', () {
    test('merges field by field: what the nearer sets wins, what it leaves out is kept', () {
      const HarborDefaults app = HarborDefaults(barrierLabel: 'Fermer', toastQueue: HarborToastQueue.wait);
      const HarborDefaults page = HarborDefaults(toastQueue: HarborToastQueue.replace, hinge: HarborHinge.never);
      expect(
        app.merge(page),
        const HarborDefaults(
          barrierLabel: 'Fermer',
          toastQueue: HarborToastQueue.replace,
          hinge: HarborHinge.never,
          // A nearer hinge replaces an inherited barHinge, so it is written out.
          barHinge: HarborHinge.never,
        ),
      );
      expect(
        const HarborDefaults(
          barHinge: HarborHinge.never,
        ).merge(const HarborDefaults(hinge: HarborHinge.always)).barHinge,
        HarborHinge.always,
        reason: 'the nearer hinge, not the inherited barHinge',
      );
      expect(
        const HarborDefaults(
          barHinge: HarborHinge.never,
        ).merge(const HarborDefaults(toastQueue: HarborToastQueue.replace)).barHinge,
        HarborHinge.never,
        reason: 'a nearer scope that says nothing of the hinge keeps it',
      );
      expect(app.merge(null), app);
      expect(app.merge(const HarborDefaults()), app);
    });

    test('the fallback is harbor’s own choices, written once', () {
      const HarborDefaults f = HarborDefaults.fallback;
      expect(f.hinge, HarborHinge.avoidSeparating);
      expect(f.barHinge, isNull, reason: 'it follows hinge');
      expect(f.barrierLabel, 'Dismiss');
      expect(f.sheetBarrierOnTapHint, isNull);
      expect(f.sheetMaxWidth, isNull);
      expect(f.toastQueue, HarborToastQueue.wait);
      expect(f.toastTiming, const HarborToastTiming());
      expect(f.toastTiming!.duration, const Duration(seconds: 4));
      expect(f.toastAnimationStyle, isNull);
      expect(f.toastMargin, HarborAligned.defaultMargin);
    });

    test('is equal by value and describes only what it sets', () {
      expect(
        const HarborDefaults(sheetMaxWidth: 640, toastMargin: EdgeInsets.all(8)),
        const HarborDefaults(sheetMaxWidth: 640, toastMargin: EdgeInsets.all(8)),
      );
      expect(const HarborDefaults(sheetMaxWidth: 640).hashCode, const HarborDefaults(sheetMaxWidth: 640).hashCode);
      expect(const HarborDefaults(sheetMaxWidth: 640), isNot(const HarborDefaults(sheetMaxWidth: 600)));
      expect(
        const HarborDefaults(toastQueue: HarborToastQueue.replace, barrierLabel: 'Fermer').toString(),
        'HarborDefaults(barrierLabel: "Fermer", toastQueue: replace)',
      );
    });
  });

  group('where it is read', () {
    testWidgets('with no scope, of and read are the fallback', (final tester) async {
      late BuildContext bare;
      await tester.pumpWidget(
        Builder(
          builder: (final BuildContext context) {
            bare = context;
            return const SizedBox();
          },
        ),
      );
      expect(HarborDefaults.of(bare), HarborDefaults.fallback);
      expect(HarborDefaults.read(bare), HarborDefaults.fallback);
      expect(HarborHinge.of(bare), HarborHinge.avoidSeparating);
    });

    testWidgets('a page merges over the root, and a scope over the page, field by field', (final tester) async {
      final BuildContext inside = await _page(
        tester,
        root: const HarborDefaults(barrierLabel: 'Fermer', sheetMaxWidth: 640),
        page: const HarborDefaults(sheetMaxWidth: 500, toastQueue: HarborToastQueue.replace),
        wrap: (final Widget body) => HarborDefaultsScope(
          defaults: const HarborDefaults(hinge: HarborHinge.never),
          child: body,
        ),
      );
      final HarborDefaults d = HarborDefaults.of(inside);
      expect(d.barrierLabel, 'Fermer', reason: 'the root’s, which the page leaves out');
      expect(d.sheetMaxWidth, 500, reason: 'the page’s, nearer than the root’s');
      expect(d.toastQueue, HarborToastQueue.replace);
      expect(d.hinge, HarborHinge.never, reason: 'the scope’s');
      expect(HarborHinge.of(inside), HarborHinge.never);
      expect(d.toastTiming, const HarborToastTiming(), reason: 'what nobody sets is the fallback');
    });

    testWidgets('a root inside a frame starts from harbor’s own, as it starts a world of its own', (
      final tester,
    ) async {
      late BuildContext inner;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(
            defaults: const HarborDefaults(barrierLabel: 'Fermer'),
            child: child!,
          ),
          home: HarborFrame(
            body: HarborRoot(
              child: Builder(
                builder: (final BuildContext context) {
                  inner = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      expect(HarborDefaults.of(inner).barrierLabel, 'Dismiss');
    });

    testWidgets('of rebuilds its reader when a scope above changes; read does not', (final tester) async {
      int builds = 0;
      Widget app(final HarborToastQueue queue) => HarborDefaultsScope(
        defaults: HarborDefaults(toastQueue: queue),
        child: Builder(
          builder: (final BuildContext context) {
            builds++;
            return Text(HarborDefaults.of(context).toastQueue!.name, textDirection: TextDirection.ltr);
          },
        ),
      );
      await tester.pumpWidget(app(HarborToastQueue.wait));
      expect(find.text('wait'), findsOneWidget);
      await tester.pumpWidget(app(HarborToastQueue.replace));
      expect(find.text('replace'), findsOneWidget);
      expect(builds, 2);
    });
  });

  group('barriers', () {
    testWidgets('a sheet, a dialog and a modal float are announced with the root’s label', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await _page(
        tester,
        root: const HarborDefaults(barrierLabel: 'Fermer', sheetBarrierOnTapHint: 'Fermer la feuille'),
      );
      unawaited(showHarborSheet<void>(page, builder: (final BuildContext _) => const HarborSheet(body: Text('sheet'))));
      await tester.pumpAndSettle();
      final ModalRoute<Object?> sheet = ModalRoute.of(tester.element(find.text('sheet')))!;
      expect(sheet.barrierLabel, 'Fermer');
      expect(
        find.semantics.byLabel('Fermer').evaluate().single,
        isSemantics(label: 'Fermer', hasTapAction: true, onTapHint: 'Fermer la feuille'),
      );
      Navigator.of(page).pop();
      await tester.pumpAndSettle();

      unawaited(showHarborDialog<void>(page, builder: (final BuildContext _) => const Text('dialog')));
      await tester.pumpAndSettle();
      expect(ModalRoute.of(tester.element(find.text('dialog')))!.barrierLabel, 'Fermer');
      expect(find.semantics.byLabel('Fermer'), findsOne);
      semantics.dispose();
    });

    testWidgets('a modal float takes the page’s label', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _page(
        tester,
        root: const HarborDefaults(barrierLabel: 'Fermer'),
        page: const HarborDefaults(barrierLabel: 'Schließen'),
        floats: <HarborFloat>[
          HarborFloat(barrier: const HarborBarrier.clear(), onDismiss: () {}, child: const Text('menu')),
        ],
      );
      expect(find.semantics.byLabel('Schließen'), findsOne);
      expect(find.semantics.byLabel('Fermer'), findsNothing);
      semantics.dispose();
    });

    testWidgets('the call’s own label and tap hint win', (final tester) async {
      final BuildContext page = await _page(tester, root: const HarborDefaults(barrierLabel: 'Fermer'));
      unawaited(
        showHarborSheet<void>(
          page,
          barrier: const HarborBarrier.dimmed(label: 'Close the reply'),
          builder: (final BuildContext _) => const HarborSheet(body: Text('sheet')),
        ),
      );
      await tester.pumpAndSettle();
      expect(ModalRoute.of(tester.element(find.text('sheet')))!.barrierLabel, 'Close the reply');
    });

    testWidgets('positive control: with no defaults it is Dismiss, as before', (final tester) async {
      final BuildContext page = await _page(tester);
      unawaited(showHarborSheet<void>(page, builder: (final BuildContext _) => const HarborSheet(body: Text('sheet'))));
      await tester.pumpAndSettle();
      expect(ModalRoute.of(tester.element(find.text('sheet')))!.barrierLabel, 'Dismiss');
    });
  });

  group('sheets', () {
    Future<double> sheetWidth(final WidgetTester tester, final BuildContext page, {final double? maxWidth}) async {
      unawaited(
        showHarborSheet<void>(
          page,
          maxWidth: maxWidth,
          builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 200, child: Text('sheet'))),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(HarborSheet)).width;
    }

    testWidgets('sheetMaxWidth caps a sheet opened without a maxWidth', (final tester) async {
      final BuildContext page = await _page(tester, root: const HarborDefaults(sheetMaxWidth: 300));
      expect(await sheetWidth(tester, page), 300);
    });

    testWidgets('the call’s maxWidth wins', (final tester) async {
      final BuildContext page = await _page(tester, root: const HarborDefaults(sheetMaxWidth: 300));
      expect(await sheetWidth(tester, page, maxWidth: 350), 350);
    });

    testWidgets('positive control: with none, the sheet spans the 402 screen', (final tester) async {
      final BuildContext page = await _page(tester);
      expect(await sheetWidth(tester, page), 402);
    });
  });

  group('toasts', () {
    testWidgets('toastMargin keeps a toast at a slot, or at none, that far in', (final tester) async {
      final BuildContext inside = await _page(tester, root: const HarborDefaults(toastMargin: EdgeInsets.all(40)));
      HarborToasts.show(inside, slot: HarborToastSlot.low, builder: _toast);
      await _step(tester);
      expect(tester.getRect(find.byKey(const ValueKey<String>('toast'))).left, 40);
      expect(tester.getRect(find.byKey(const ValueKey<String>('toast'))).right, 402 - 40);
    });

    testWidgets('a toast given a placement keeps the placement’s margin', (final tester) async {
      final BuildContext inside = await _page(tester, root: const HarborDefaults(toastMargin: EdgeInsets.all(40)));
      HarborToasts.show(inside, placement: const HarborAligned(), builder: _toast);
      await _step(tester);
      expect(tester.getRect(find.byKey(const ValueKey<String>('toast'))).left, 16);
    });

    testWidgets('positive control: with no defaults a toast at a slot keeps 16 in', (final tester) async {
      final BuildContext inside = await _page(tester);
      HarborToasts.show(inside, slot: HarborToastSlot.low, builder: _toast);
      await _step(tester);
      expect(tester.getRect(find.byKey(const ValueKey<String>('toast'))).left, 16);
    });

    testWidgets('toastTiming is how long a toast shown without a timing stays', (final tester) async {
      final BuildContext inside = await _page(
        tester,
        page: const HarborDefaults(toastTiming: HarborToastTiming(duration: Duration(seconds: 1))),
      );
      final HarborToastEntry short = HarborToasts.show(inside, slot: HarborToastSlot.low, builder: _toast);
      final HarborToastEntry own = HarborToasts.show(
        inside,
        slot: HarborToastSlot.top,
        timing: const HarborToastTiming(duration: Duration(seconds: 3)),
        builder: _toast,
      );
      expect(short.duration, const Duration(seconds: 1));
      expect(own.duration, const Duration(seconds: 3), reason: 'the call’s own timing wins');
      await _step(tester, 20); // 2 s
      expect(short.phase, HarborToastPhase.closed);
      expect(own.phase, HarborToastPhase.shown);
      own.hide();
      await _step(tester);
    });

    testWidgets('toastAnimationStyle is how a toast shown without one comes in', (final tester) async {
      final BuildContext inside = await _page(
        tester,
        root: const HarborDefaults(toastAnimationStyle: AnimationStyle(duration: Duration(milliseconds: 600))),
      );
      final HarborToastEntry entry = HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        timing: HarborToastTiming.untilHidden,
        builder: _toast,
      );
      // ignore: deprecated_member_use_from_same_package
      expect(entry.animationStyle, const AnimationStyle(duration: Duration(milliseconds: 600)));
      final HarborToastEntry own = HarborToasts.show(
        inside,
        slot: HarborToastSlot.top,
        animationStyle: AnimationStyle.noAnimation,
        timing: HarborToastTiming.untilHidden,
        builder: _toast,
      );
      // ignore: deprecated_member_use_from_same_package
      expect(own.animationStyle, AnimationStyle.noAnimation);
      entry.hide();
      own.hide();
      await _step(tester, 10);
    });

    testWidgets('toastQueue from a HarborDefaultsScope: the newer replaces the one up', (final tester) async {
      final BuildContext inside = await _page(
        tester,
        wrap: (final Widget body) => HarborDefaultsScope(
          defaults: const HarborDefaults(toastQueue: HarborToastQueue.replace),
          child: body,
        ),
      );
      final HarborToastEntry first = HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        timing: HarborToastTiming.untilHidden,
        builder: (final BuildContext _) => const Text('saved'),
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        timing: HarborToastTiming.untilHidden,
        builder: (final BuildContext _) => const Text('undo'),
      );
      await _step(tester);
      expect(find.text('undo'), findsOneWidget);
      expect(find.text('saved'), findsNothing);
      expect(await first.closed, HarborToastClosedReason.replaced);
    });
  });

  group('across the route', () {
    testWidgets('a sheet opened from a page takes the page’s defaults, and so does a toast shown in it', (
      final tester,
    ) async {
      final BuildContext page = await _page(
        tester,
        page: const HarborDefaults(hinge: HarborHinge.never, toastQueue: HarborToastQueue.replace),
      );
      late BuildContext inSheet;
      unawaited(
        showHarborSheet<void>(
          page,
          builder: (final BuildContext _) => HarborSheet(
            body: Builder(
              builder: (final BuildContext context) {
                inSheet = context;
                return const SizedBox(height: 200);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(HarborHinge.of(inSheet), HarborHinge.never, reason: 'the page’s, not the root’s');
      expect(HarborDefaults.read(inSheet).toastQueue, HarborToastQueue.replace);

      final HarborToastEntry first = HarborToasts.show(
        inSheet,
        timing: HarborToastTiming.untilHidden,
        builder: (final BuildContext _) => const Text('saved'),
      );
      await _step(tester);
      HarborToasts.show(
        inSheet,
        timing: HarborToastTiming.untilHidden,
        builder: (final BuildContext _) => const Text('undo'),
      );
      await _step(tester);
      expect(await first.closed, HarborToastClosedReason.replaced);
    });

    testWidgets('a dialog opened from a page takes the page’s label', (final tester) async {
      final BuildContext page = await _page(tester, page: const HarborDefaults(barrierLabel: 'Fermer'));
      late BuildContext inDialog;
      unawaited(
        showHarborDialog<void>(
          page,
          builder: (final BuildContext context) {
            inDialog = context;
            return const Text('dialog');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(ModalRoute.of(tester.element(find.text('dialog')))!.barrierLabel, 'Fermer');
      expect(HarborDefaults.of(inDialog).barrierLabel, 'Fermer');
    });
  });

  group('the hinge', () {
    const HarborTrialDevice dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540

    Future<void> nested(final WidgetTester tester, {final HarborDefaults? outer}) => tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          defaults: outer,
          body: const HarborFrame(
            bottom: <HarborBar>[
              HarborBar.solid(
                child: SizedBox(key: ValueKey<String>('tabs'), height: 56, width: double.infinity),
              ),
            ],
            body: SizedBox.expand(),
          ),
        ),
      ),
      device: dual,
    );

    testWidgets('barHinge reaches a frame nested in the page: its bars cross the hinge too', (final tester) async {
      await nested(tester, outer: const HarborDefaults(barHinge: HarborHinge.never));
      expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).right, 1114);
    });

    testWidgets('positive control: without it the nested frame’s bars keep to the left screen', (final tester) async {
      await nested(tester);
      expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).right, 540);
    });

    // Owner review: a frame's own hinge beats a barHinge inherited from the frame around it. The
    // order per frame is its own barHinge, its own hinge, then the inherited barHinge and hinge, as
    // on main, where the inner frame's tabs ended at 540.
    Future<void> ownHinge(
      final WidgetTester tester, {
      required final bool deprecated,
      final bool deeper = false,
      final bool innerHinge = true,
    }) {
      // Deeper, the inner frame holds no bars, so the frame in its body is still as big as the
      // screen: only a frame that size reads the hinge.
      final Widget body = deeper
          ? const HarborFrame(
              bottom: <HarborBar>[
                HarborBar.solid(
                  child: SizedBox(key: ValueKey<String>('deeper tabs'), height: 40, width: double.infinity),
                ),
              ],
              body: SizedBox.expand(),
            )
          : const SizedBox.expand();
      final List<HarborBar> bottom = deeper
          ? const <HarborBar>[]
          : const <HarborBar>[
              HarborBar.solid(
                child: SizedBox(key: ValueKey<String>('tabs'), height: 56, width: double.infinity),
              ),
            ];
      final HarborHinge? own = innerHinge ? HarborHinge.avoidSeparating : null;
      return tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: deprecated
              ? HarborFrame(
                  // ignore: deprecated_member_use_from_same_package
                  barHinge: HarborHinge.never,
                  // ignore: deprecated_member_use_from_same_package
                  body: HarborFrame(hinge: own, bottom: bottom, body: body),
                )
              : HarborFrame(
                  defaults: const HarborDefaults(barHinge: HarborHinge.never),
                  body: HarborFrame(
                    defaults: HarborDefaults(hinge: own),
                    bottom: bottom,
                    body: body,
                  ),
                ),
        ),
        device: dual,
      );
    }

    for (final bool deprecated in <bool>[true, false]) {
      final String how = deprecated ? 'hinge:/barHinge:' : 'defaults:';
      testWidgets('a nested frame’s own hinge beats an inherited barHinge ($how)', (final tester) async {
        await ownHinge(tester, deprecated: deprecated);
        expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).right, 540);
      });

      testWidgets('and a frame beneath that one follows the nearer hinge too ($how)', (final tester) async {
        await ownHinge(tester, deprecated: deprecated, deeper: true);
        expect(tester.getRect(find.byKey(const ValueKey<String>('deeper tabs'))).right, 540);
      });

      testWidgets('positive control: without the inner hinge, the outer barHinge reaches it ($how)', (
        final tester,
      ) async {
        await ownHinge(tester, deprecated: deprecated, deeper: true, innerHinge: false);
        expect(tester.getRect(find.byKey(const ValueKey<String>('deeper tabs'))).right, 1114);
      });
    }

    testWidgets('a frame’s own barHinge still beats its own hinge', (final tester) async {
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: const HarborFrame(
            defaults: HarborDefaults(hinge: HarborHinge.avoidSeparating, barHinge: HarborHinge.never),
            bottom: <HarborBar>[
              HarborBar.solid(
                child: SizedBox(key: ValueKey<String>('tabs'), height: 56, width: double.infinity),
              ),
            ],
            body: SizedBox.expand(),
          ),
        ),
        device: dual,
      );
      expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).right, 1114);
    });
  });

  group('the deprecated spellings still work', () {
    testWidgets('HarborFrame(hinge:) and HarborRoot(hinge:) set the hinge; defaults wins over them', (
      final tester,
    ) async {
      late BuildContext inside;
      late BuildContext both;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) =>
              // ignore: deprecated_member_use_from_same_package
              HarborRoot(hinge: HarborHinge.always, child: child!),
          home: Column(
            children: <Widget>[
              Expanded(
                child: Builder(
                  builder: (final BuildContext context) {
                    inside = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
              Expanded(
                child: HarborFrame(
                  defaults: const HarborDefaults(hinge: HarborHinge.avoidOccluding),
                  // ignore: deprecated_member_use_from_same_package
                  hinge: HarborHinge.never,
                  body: Builder(
                    builder: (final BuildContext context) {
                      both = context;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      expect(HarborHinge.of(inside), HarborHinge.always);
      expect(HarborHinge.of(both), HarborHinge.avoidOccluding);
    });

    testWidgets('HarborFlarePolicy builds a HarborDefaultsScope, and queueOf reads it', (final tester) async {
      late BuildContext inside;
      await tester.pumpWidget(
        // ignore: deprecated_member_use_from_same_package
        HarborFlarePolicy(
          queue: HarborToastQueue.replace,
          child: Builder(
            builder: (final BuildContext context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(find.byType(HarborDefaultsScope), findsOneWidget);
      // ignore: deprecated_member_use_from_same_package
      expect(HarborFlarePolicy.queueOf(inside), HarborToastQueue.replace);
      expect(HarborDefaults.read(inside).toastQueue, HarborToastQueue.replace);
    });
  });
}
