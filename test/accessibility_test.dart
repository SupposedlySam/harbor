// Flutter's conventions for custom widgets, held: what harbor hides is hidden from keyboard
// focus and screen readers too, what it builds elsewhere keeps the inherited theme, it honours
// reduced motion, and it follows the reading direction.
//
// Every test here failed on the code before this file existed; each comment says how.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _app(final Widget home, {final bool disableAnimations = false, final TextDirection direction = TextDirection.ltr}) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
      child: HarborSea(child: child!),
    ),
  ),
  home: home,
);

Widget _page(final HarborDockState state) => Harbor(
  top: <HarborDock>[
    HarborDock.pier(state: state, child: SizedBox(height: 50, child: TextButton(onPressed: () {}, child: const Text('Header action')))),
  ],
  body: Center(child: TextButton(onPressed: () {}, child: const Text('Body action'))),
);

/// The labels of the buttons Tab reaches, in order, over [presses] presses.
Future<List<String>> _tabOrder(final WidgetTester tester, {final int presses = 4}) async {
  final List<String> order = <String>[];
  for (int i = 0; i < presses; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final TextButton? button = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>();
    order.add(button == null ? '-' : (button.child! as Text).data!);
  }
  return order;
}

void main() {
  group('A hidden dock is out of reach', () {
    testWidgets('an open dock is focusable and read out (positive control)', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpSeaTrial(_app(_page(HarborDockState.open)));
      expect(find.bySemanticsLabel('Header action'), findsOneWidget);
      expect(await _tabOrder(tester), contains('Header action'));
      semantics.dispose();
    });

    // Failed before: Tab reached the invisible header button.
    testWidgets('a dark dock is skipped by Tab and by screen readers', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpSeaTrial(_app(_page(HarborDockState.dark)));
      expect(find.bySemanticsLabel('Header action'), findsNothing);
      final List<String> order = await _tabOrder(tester);
      expect(order, contains('Body action'), reason: 'positive control: Tab works');
      expect(order, isNot(contains('Header action')));
      semantics.dispose();
    });

    // Failed before: a withdrawn header was still read out and still took focus.
    testWidgets('a withdrawn dock is skipped by Tab and by screen readers', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpSeaTrial(_app(_page(HarborDockState.withdrawn)));
      expect(find.bySemanticsLabel('Header action'), findsNothing);
      final List<String> order = await _tabOrder(tester);
      expect(order, contains('Body action'), reason: 'positive control: Tab works');
      expect(order, isNot(contains('Header action')));
      semantics.dispose();
    });
  });

  group('A signal', () {
    Future<BuildContext> pumpPage(final WidgetTester tester, {final bool disableAnimations = false, final Color? pagePrimary}) async {
      late BuildContext page;
      final Widget probe = Builder(
        builder: (final BuildContext context) {
          page = context;
          return const SizedBox.expand();
        },
      );
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: pagePrimary == null ? probe : Theme(data: ThemeData(colorScheme: ColorScheme.light(primary: pagePrimary)), child: probe),
          ),
          disableAnimations: disableAnimations,
        ),
      );
      return page;
    }

    // Failed before: no live region, so a screen reader never announced it.
    testWidgets('is announced by screen readers as it appears', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await pumpPage(tester);
      HarborSignals.raise(page, builder: (final BuildContext _) => const Text('Saved'), duration: null);
      await tester.pumpAndSettle();
      SemanticsNode? node = tester.getSemantics(find.text('Saved'));
      bool live = false;
      while (node != null) {
        live = live || node.flagsCollection.isLiveRegion;
        node = node.parent;
      }
      expect(live, isTrue);
      semantics.dispose();
    });

    // Failed before: the toast saw the app's theme, not the page's.
    testWidgets('keeps the theme of the page that raised it', (final tester) async {
      const Color red = Color(0xFFFF0000);
      final BuildContext page = await pumpPage(tester, pagePrimary: red);
      Color? seen;
      HarborSignals.raise(
        page,
        builder: (final BuildContext context) {
          seen = Theme.of(context).colorScheme.primary;
          return const Text('Saved');
        },
        duration: null,
      );
      await tester.pumpAndSettle();
      expect(seen, red);
    });

    // Failed before: it faded and scaled in over 220 ms whatever the platform asked.
    testWidgets('appears at once when the platform asks for reduced motion', (final tester) async {
      final BuildContext page = await pumpPage(tester, disableAnimations: true);
      HarborSignals.raise(page, builder: (final BuildContext _) => const Text('Saved'), duration: null);
      await tester.pump();
      await tester.pump();
      final FadeTransition fade = tester.widget(find.ancestor(of: find.text('Saved'), matching: find.byType(FadeTransition)).first);
      expect(fade.opacity.value, 1.0);
    });

    // The live region and the message are the same node, not two that each exist.
    testWidgets('is one live region, labelled by its message', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await pumpPage(tester);
      HarborSignals.raise(page, builder: (final BuildContext _) => const Text('Saved'), duration: null);
      await tester.pumpAndSettle();
      expect(find.semantics.byFlag(SemanticsFlag.isLiveRegion).evaluate().single.label, 'Saved');
      semantics.dispose();
    });

    // Failed before: no dismiss action, so a screen reader could not take a signal away, as it can a SnackBar.
    testWidgets('is lowered by the screen reader’s dismiss action', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await pumpPage(tester);
      final HarborSignalEntry entry = HarborSignals.raise(page, builder: (final BuildContext _) => const Text('Saved'), duration: null);
      HarborSignalClosedReason? reason;
      unawaited(entry.closed.then((final HarborSignalClosedReason r) => reason = r));
      await tester.pumpAndSettle();
      tester.semantics.performAction(find.semantics.byFlag(SemanticsFlag.isLiveRegion), SemanticsAction.dismiss);
      expect(entry.showing.value, isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
      expect(reason, HarborSignalClosedReason.dismiss);
      semantics.dispose();
    });

    // Failed before: harbor wrapped it in a second live region with no label, around the widget's own.
    testWidgets('with liveRegion: false, leaves the semantics to a widget that is its own live region', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await pumpPage(tester);
      HarborSignals.raise(
        page,
        liveRegion: false,
        builder: (final BuildContext _) => Semantics(
          container: true,
          liveRegion: true,
          label: 'Saved',
          child: const SizedBox(width: 200, height: 40),
        ),
        duration: null,
      );
      await tester.pumpAndSettle();
      expect(find.semantics.byFlag(SemanticsFlag.isLiveRegion).evaluate().single.label, 'Saved');
      semantics.dispose();
    });
  });

  group("A signal's entrance", () {
    Future<BuildContext> pumpPage(final WidgetTester tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      return page;
    }

    // The transitions harbor puts between [entry]'s buoy and its text; the page's own route
    // transition sits above the buoy and is not counted.
    Finder harborTransitions(final HarborSignalEntry entry, final Type type) => find.ancestor(
      of: find.text('Saved'),
      matching: find.descendant(of: find.byKey(ObjectKey(entry)), matching: find.byType(type)),
    );

    // Failed before: every signal faded and scaled in, so a widget with its own entrance played two.
    testWidgets('with AnimationStyle.noAnimation, shows the child as it is and keeps it for its own exit', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final HarborSignalEntry entry = HarborSignals.raise(
        page,
        animationStyle: AnimationStyle.noAnimation,
        builder: (final BuildContext _) => const Text('Saved'),
        duration: null,
      );
      await tester.pump();
      expect(find.text('Saved'), findsOneWidget);
      expect(harborTransitions(entry, FadeTransition), findsNothing);
      expect(harborTransitions(entry, ScaleTransition), findsNothing);

      entry.lower();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Saved'), findsOneWidget, reason: 'it lingers for its own exit');
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    // Failed before: a caller could not bring its own entrance; harbor's fade and scale always ran.
    testWidgets("a transitionBuilder replaces the fade and scale and runs on harbor's animation", (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final List<double> seen = <double>[];
      final HarborSignalEntry entry = HarborSignals.raise(
        page,
        animationStyle: const AnimationStyle(duration: Duration(milliseconds: 200)),
        transitionBuilder: (final BuildContext context, final Animation<double> animation, final Widget child) {
          return AnimatedBuilder(
            animation: animation,
            builder: (final BuildContext context, final Widget? child) {
              seen.add(animation.value);
              return child!;
            },
            child: child,
          );
        },
        builder: (final BuildContext _) => const Text('Saved'),
        duration: null,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(seen.last, closeTo(0.5, 0.01));
      expect(harborTransitions(entry, FadeTransition), findsNothing);
      expect(harborTransitions(entry, ScaleTransition), findsNothing);
      await tester.pumpAndSettle();
      expect(seen.last, 1.0);

      entry.lower();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(seen.last, closeTo(0.5, 0.01), reason: 'it runs back out when lowered');
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    // Failed before: a lowered signal was removed after 300 ms whatever its exit took.
    testWidgets('stays up for the whole of a longer exit', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final HarborSignalEntry entry = HarborSignals.raise(
        page,
        animationStyle: const AnimationStyle(reverseDuration: Duration(milliseconds: 600)),
        builder: (final BuildContext _) => const Text('Saved'),
        duration: null,
      );
      await tester.pumpAndSettle();
      entry.lower();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.text('Saved'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });
  });

  // Failed before, though sheets already captured the page's themes: the builder was called
  // outside the captured themes, so `Theme.of(context)` in it read the navigator's theme.
  testWidgets("a sheet's builder sees the theme of the page that opened it", (final tester) async {
    const Color red = Color(0xFFFF0000);
    late BuildContext page;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Theme(
            data: ThemeData(colorScheme: const ColorScheme.light(primary: red)),
            child: Builder(
              builder: (final BuildContext context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    Color? seen;
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) {
        seen = Theme.of(context).colorScheme.primary;
        return const HarborSheet(body: SizedBox(height: 100));
      },
    ));
    await tester.pumpAndSettle();
    expect(seen, red);
  });

  group('A dialog', () {
    Future<BuildContext> pumpPage(final WidgetTester tester, {final bool disableAnimations = false, final Color? pagePrimary}) async {
      late BuildContext page;
      final Widget probe = Builder(
        builder: (final BuildContext context) {
          page = context;
          return const SizedBox.expand();
        },
      );
      await tester.pumpSeaTrial(
        _app(
          Harbor(body: pagePrimary == null ? probe : Theme(data: ThemeData(colorScheme: ColorScheme.light(primary: pagePrimary)), child: probe)),
          disableAnimations: disableAnimations,
        ),
      );
      return page;
    }

    // Failed before: like sheets and signals, the builder ran outside the captured themes.
    testWidgets("'s builder sees the theme of the page that opened it", (final tester) async {
      const Color red = Color(0xFFFF0000);
      final BuildContext page = await pumpPage(tester, pagePrimary: red);
      Color? seen;
      unawaited(showHarborDialog<void>(
        page,
        builder: (final BuildContext context) {
          seen = Theme.of(context).colorScheme.primary;
          return const SizedBox(width: 100, height: 100);
        },
      ));
      await tester.pumpAndSettle();
      expect(seen, red);
    });

    // Failed before: it faded in over 180 ms whatever the platform asked.
    testWidgets('appears at once when the platform asks for reduced motion', (final tester) async {
      final BuildContext page = await pumpPage(tester, disableAnimations: true);
      unawaited(showHarborDialog<void>(page, builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('dialog'), width: 100, height: 100)));
      await tester.pump();
      await tester.pump();
      final FadeTransition fade = tester.widget(find.ancestor(of: find.byKey(const ValueKey<String>('dialog')), matching: find.byType(FadeTransition)).first);
      expect(fade.opacity.value, 1.0);
    });
  });

  group('Reduced motion', () {
    /// Frames a dock takes to withdraw. One measurement per test, on a fresh tree: measuring
    /// twice in one test reused the first tree's dock state and measured nothing.
    Future<int> framesToWithdraw(final WidgetTester tester, {required final bool disableAnimations}) async {
      final ValueNotifier<HarborDockState> state = ValueNotifier<HarborDockState>(HarborDockState.open);
      addTearDown(state.dispose);
      await tester.pumpSeaTrial(
        _app(
          ValueListenableBuilder<HarborDockState>(
            valueListenable: state,
            builder: (final BuildContext context, final HarborDockState s, final Widget? _) => _page(s),
          ),
          disableAnimations: disableAnimations,
        ),
      );
      await tester.pumpAndSettle();
      state.value = HarborDockState.withdrawn;
      await tester.pump();
      int frames = 0;
      while (tester.binding.hasScheduledFrame && frames < 200) {
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
      }
      return frames;
    }

    testWidgets('a dock withdraws over several frames normally (positive control)', (final tester) async {
      expect(await framesToWithdraw(tester, disableAnimations: false), greaterThan(5));
    });

    // Failed before: the dock took the same 16 frames to leave either way.
    testWidgets('a dock withdraws at once', (final tester) async {
      expect(await framesToWithdraw(tester, disableAnimations: true), lessThanOrEqualTo(2));
    });

    // Failed before: the sheet slid up over 280 ms.
    testWidgets('a sheet is there on its first frame', (final tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
          disableAnimations: true,
        ),
      );
      unawaited(showHarborSheet<void>(page, builder: (final BuildContext _) => const HarborSheet(body: SizedBox(key: ValueKey<String>('content'), height: 200))));
      await tester.pump();
      await tester.pump();
      final double firstFrame = tester.getRect(find.byKey(const ValueKey<String>('content'))).top;
      await tester.pumpAndSettle();
      expect(firstFrame, tester.getRect(find.byKey(const ValueKey<String>('content'))).top);
    });
  });

  group('A buoy follows the reading direction', () {
    Future<Rect> place(final WidgetTester tester, final TextDirection direction) async {
      await tester.pumpSeaTrial(
        _app(
          const Harbor(
            buoys: <HarborBuoy>[
              HarborBuoy(
                alignment: AlignmentDirectional.bottomEnd,
                margin: EdgeInsetsDirectional.only(end: 40, bottom: 16),
                child: SizedBox(key: ValueKey<String>('fab'), width: 56, height: 56),
              ),
            ],
            body: SizedBox.expand(),
          ),
          direction: direction,
        ),
        textDirection: direction,
      );
      return tester.getRect(find.byKey(const ValueKey<String>('fab')));
    }

    // Failed before: alignment and margin only took physical Alignment and EdgeInsets, so this
    // did not compile; a buoy could not follow a right-to-left reading direction.
    testWidgets('bottomEnd is bottom right left to right, bottom left right to left', (final tester) async {
      final Rect ltr = await place(tester, TextDirection.ltr);
      final Rect rtl = await place(tester, TextDirection.rtl);
      const double width = 402; // iPhone 17
      expect(ltr.right, width - 40);
      expect(rtl.left, 40);
    });
  });

  // Reported by the controllers-and-notifications audit. Failed before: only Scaffold handles the
  // status bar tap, and a page built from a harbor has none, so the list stayed at 800.
  group('A status bar tap on iOS scrolls the page to the top', () {
    for (final bool scaffold in <bool>[false, true]) {
      testWidgets(scaffold ? 'with a Scaffold too (positive control)' : 'with no Scaffold', (final tester) async {
        final Widget harbor = Harbor(
          top: const <HarborDock>[HarborDock.pier(child: SizedBox(height: 50))],
          body: HarborFairway(
            slivers: <Widget>[
              SliverList.builder(itemCount: 80, itemBuilder: (final BuildContext c, final int i) => SizedBox(height: 40, child: Text('row $i'))),
            ],
          ),
        );
        await tester.pumpSeaTrial(_app(scaffold ? Scaffold(resizeToAvoidBottomInset: false, body: harbor) : harbor));
        final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        position.jumpTo(800);
        await tester.pump();
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/status_bar',
          SystemChannels.statusBar.codec.encodeMethodCall(const MethodCall('handleScrollToTop')),
          (final ByteData? _) {},
        );
        await tester.pumpAndSettle();
        expect(position.pixels, 0.0);
      }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
    }
  });
}
