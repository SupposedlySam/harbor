// HarborBarrier: one value for what a sheet, a dialog and a float put over the page, in place of
// five loose sheet parameters that disagreed (`barrier: HarborSheetBarrier.dismissible` meant dimmed,
// `isDismissible` applied to clear too, `barrierColor` only to dimmed), three on a dialog and three on
// a float, each spelled differently. Each test checks what a host does with a barrier; the
// deprecated spellings are checked to still do what they did, through the value.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const Color _tint = Color(0x66000000);

Future<BuildContext> _page(final WidgetTester tester, {final List<String>? taps}) async {
  late BuildContext pageContext;
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: Material(
        child: HarborFrame(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return Align(
                alignment: Alignment.topLeft,
                child: TextButton(onPressed: () => taps?.add('page'), child: const Text('Page action')),
              );
            },
          ),
        ),
      ),
    ),
  );
  return pageContext;
}

Widget _sheet(final BuildContext _) => const HarborSheet(body: SizedBox(height: 200, child: Text('sheet')));

ModalRoute<Object?> _routeOf(final WidgetTester tester, final String text) =>
    ModalRoute.of(tester.element(find.text(text)))!;

class _Floats extends StatefulWidget {
  const _Floats({required this.float});

  final HarborFloat Function(VoidCallback onDismiss) float;

  @override
  State<_Floats> createState() => _FloatsState();
}

class _FloatsState extends State<_Floats> {
  bool up = true;
  int dismissed = 0;
  final List<String> taps = <String>[];

  @override
  Widget build(final BuildContext context) => HarborFrame(
    floats: <HarborFloat>[
      if (up)
        widget.float(
          () => setState(() {
            up = false;
            dismissed++;
          }),
        ),
    ],
    body: Align(
      alignment: Alignment.topLeft,
      child: TextButton(onPressed: () => taps.add('page'), child: const Text('Page action')),
    ),
  );
}

Future<_FloatsState> _pumpFloat(final WidgetTester tester, final HarborFloat Function(VoidCallback) float) async {
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: const HarborFrame(body: Center(child: Text('home'))),
    ),
  );
  unawaited(
    Navigator.of(
      tester.element(find.text('home')),
    ).push(MaterialPageRoute<void>(builder: (final BuildContext _) => _Floats(float: float))),
  );
  await tester.pumpAndSettle();
  return tester.state<_FloatsState>(find.byType(_Floats));
}

HarborFloat _menu(final VoidCallback onDismiss, {required final HarborBarrier barrier}) => HarborFloat(
  placement: const HarborAligned(alignment: Alignment.center),
  barrier: barrier,
  onDismiss: onDismiss,
  child: const SizedBox(width: 160, height: 120, child: Text('menu')),
);

ModalBarrier _floatBarrier(final WidgetTester tester) => tester.widget<ModalBarrier>(
  find.descendant(of: find.byType(HarborFrame).last, matching: find.byType(ModalBarrier)),
);

void main() {
  group('the value', () {
    test('a dimmed barrier is half-black and dismissible by default, and equal by value', () {
      const HarborBarrier dimmed = HarborBarrier.dimmed();
      expect(dimmed.color, HarborBarrier.defaultColor);
      expect(HarborBarrier.defaultColor, const Color(0x80000000));
      expect(dimmed.isDismissible, isTrue);
      expect(dimmed.label, isNull);
      expect(dimmed.onTapHint, isNull);
      expect(dimmed.blocks, isTrue);
      expect(dimmed, const HarborBarrier.dimmed(color: Color(0x80000000), dismissible: true));
      expect(dimmed.hashCode, const HarborBarrier.dimmed(color: Color(0x80000000)).hashCode);
      expect(dimmed, isNot(const HarborBarrier.dimmed(dismissible: false)));
      expect(dimmed, isNot(const HarborBarrier.clear()));
    });

    test('a clear barrier is transparent and blocks; none does not', () {
      const HarborBarrier clear = HarborBarrier.clear(dismissible: false, label: 'Fermer', onTapHint: 'fermer');
      expect(clear.color, const Color(0x00000000));
      expect(clear.isDismissible, isFalse);
      expect(clear.label, 'Fermer');
      expect(clear.onTapHint, 'fermer');
      expect(clear.blocks, isTrue);
      expect(clear, const HarborBarrier.clear(dismissible: false, label: 'Fermer', onTapHint: 'fermer'));

      expect(HarborBarrier.none.blocks, isFalse);
      expect(HarborBarrier.none.isDismissible, isFalse);
      expect(HarborBarrier.none.color, const Color(0x00000000));
    });

    test('it describes itself, leaving out its defaults', () {
      expect(const HarborBarrier.dimmed().toString(), 'HarborBarrier.dimmed');
      expect(
        const HarborBarrier.dimmed(color: _tint, dismissible: false, label: 'Fermer').toString(),
        'HarborBarrier.dimmed(color: ${const Color(0x66000000)}, not dismissible, label: "Fermer")',
      );
      expect(const HarborBarrier.clear(onTapHint: 'close').toString(), 'HarborBarrier.clear(onTapHint: "close")');
      expect(HarborBarrier.none.toString(), 'HarborBarrier.none');
    });

    test('the deprecated HarborSheetBarrier values are the barriers they stand for', () {
      // ignore: deprecated_member_use_from_same_package
      const List<HarborBarrier> old = HarborSheetBarrier.values;
      expect(<bool>[for (final HarborBarrier b in old) b.blocks], <bool>[true, true, false]);
      expect(
        <Color>[for (final HarborBarrier b in old) b.color],
        <Color>[HarborBarrier.defaultColor, const Color(0x00000000), const Color(0x00000000)],
      );
      // ignore: deprecated_member_use_from_same_package
      expect(HarborSheetBarrier.none.toString(), 'HarborSheetBarrier.none');
      // ignore: deprecated_member_use_from_same_package
      expect(HarborSheetBarrier.clear.name, 'clear');
    });
  });

  group('a sheet', () {
    testWidgets('is dimmed by default, and a tap on the barrier closes it', (final tester) async {
      final BuildContext page = await _page(tester);
      unawaited(showHarborSheet<void>(page, builder: _sheet));
      await tester.pumpAndSettle();
      final ModalRoute<Object?> route = _routeOf(tester, 'sheet');
      expect(route.barrierColor, const Color(0x80000000));
      expect(route.barrierDismissible, isTrue);
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
    });

    testWidgets('a clear barrier that is not dismissible keeps the sheet up and the page out of reach', (
      final tester,
    ) async {
      final List<String> taps = <String>[];
      final BuildContext page = await _page(tester, taps: taps);
      unawaited(showHarborSheet<void>(page, barrier: const HarborBarrier.clear(dismissible: false), builder: _sheet));
      await tester.pumpAndSettle();
      expect(_routeOf(tester, 'sheet').barrierColor, const Color(0x00000000));
      await tester.tap(find.text('Page action'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget, reason: 'the barrier did nothing with the tap');
      expect(taps, isEmpty, reason: 'and the page did not get it');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing, reason: 'back still closes it');
    });

    testWidgets('a dimmed barrier takes its colour, label and tap hint', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await _page(tester);
      unawaited(
        showHarborSheet<void>(
          page,
          barrier: const HarborBarrier.dimmed(color: _tint, label: 'Fermer', onTapHint: 'Close the reply'),
          builder: _sheet,
        ),
      );
      await tester.pumpAndSettle();
      final ModalRoute<Object?> route = _routeOf(tester, 'sheet');
      expect(route.barrierColor, _tint);
      expect(route.barrierLabel, 'Fermer');
      final SemanticsNode barrier = find.semantics.byLabel('Fermer').evaluate().single;
      expect(barrier, isSemantics(label: 'Fermer', hasTapAction: true, onTapHint: 'Close the reply'));
      semantics.dispose();
    });

    testWidgets('with HarborBarrier.none it is not a route, and the page stays live', (final tester) async {
      final List<String> taps = <String>[];
      final BuildContext page = await _page(tester, taps: taps);
      unawaited(showHarborSheet<void>(page, barrier: HarborBarrier.none, builder: _sheet));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget);
      expect(ModalRoute.of(tester.element(find.text('sheet'))), ModalRoute.of(page), reason: 'no route of its own');
      await tester.tap(find.text('Page action'));
      expect(taps, <String>['page']);
    });

    group('the deprecated spellings', () {
      testWidgets('isDismissible: false still keeps the sheet up, on a clear barrier too', (final tester) async {
        final BuildContext page = await _page(tester);
        unawaited(
          showHarborSheet<void>(
            page,
            // ignore: deprecated_member_use_from_same_package
            barrier: HarborSheetBarrier.clear,
            // ignore: deprecated_member_use_from_same_package
            isDismissible: false,
            builder: _sheet,
          ),
        );
        await tester.pumpAndSettle();
        final ModalRoute<Object?> route = _routeOf(tester, 'sheet');
        expect(route.barrierDismissible, isFalse);
        expect(route.barrierColor, const Color(0x00000000));
      });

      testWidgets('barrierColor tints a dimmed barrier and leaves a clear one clear, as it always did', (
        final tester,
      ) async {
        final BuildContext page = await _page(tester);
        // ignore: deprecated_member_use_from_same_package
        unawaited(showHarborSheet<void>(page, barrierColor: _tint, barrierLabel: 'Fermer', builder: _sheet));
        await tester.pumpAndSettle();
        expect(_routeOf(tester, 'sheet').barrierColor, _tint);
        expect(_routeOf(tester, 'sheet').barrierLabel, 'Fermer');
        Navigator.of(tester.element(find.text('sheet'))).pop();
        await tester.pumpAndSettle();

        unawaited(
          showHarborSheet<void>(
            page,
            barrier: const HarborBarrier.clear(),
            // ignore: deprecated_member_use_from_same_package
            barrierColor: _tint,
            builder: _sheet,
          ),
        );
        await tester.pumpAndSettle();
        expect(_routeOf(tester, 'sheet').barrierColor, const Color(0x00000000));
      });

      testWidgets('HarborSheetBarrier.none is still a sheet with no barrier', (final tester) async {
        final BuildContext page = await _page(tester);
        // ignore: deprecated_member_use_from_same_package
        unawaited(showHarborSheet<void>(page, barrier: HarborSheetBarrier.none, builder: _sheet));
        await tester.pumpAndSettle();
        expect(ModalRoute.of(tester.element(find.text('sheet'))), ModalRoute.of(page));
      });

      // As on 0.9.1: with no barrier they do nothing, and are ignored rather than asserted, while
      // they exist. Whether the barrier is none can depend on a variable dart fix leaves alone.
      for (final HarborBarrier none in <HarborBarrier>[
        HarborBarrier.none,
        // ignore: deprecated_member_use_from_same_package
        HarborSheetBarrier.none,
      ]) {
        testWidgets('with no barrier ($none) they are ignored, as they were', (final tester) async {
          final BuildContext page = await _page(tester);
          unawaited(
            showHarborSheet<void>(
              page,
              barrier: none,
              // ignore: deprecated_member_use_from_same_package
              isDismissible: false,
              // ignore: deprecated_member_use_from_same_package
              barrierLabel: 'x',
              // ignore: deprecated_member_use_from_same_package
              barrierColor: _tint,
              // ignore: deprecated_member_use_from_same_package
              barrierOnTapHint: 'close',
              builder: _sheet,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('sheet'), findsOneWidget);
          expect(ModalRoute.of(tester.element(find.text('sheet'))), ModalRoute.of(page), reason: 'still no route');
        });
      }
    });
  });

  group('a dialog', () {
    testWidgets('is dimmed by default; a clear barrier is transparent and takes its tap hint', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final BuildContext page = await _page(tester);
      unawaited(showHarborDialog<void>(page, builder: (_) => const Text('dialog')));
      await tester.pumpAndSettle();
      expect(_routeOf(tester, 'dialog').barrierColor, const Color(0x80000000));
      Navigator.of(tester.element(find.text('dialog'))).pop();
      await tester.pumpAndSettle();

      unawaited(
        showHarborDialog<void>(
          page,
          barrier: const HarborBarrier.clear(label: 'Fermer', onTapHint: 'close the dialog'),
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();
      final ModalRoute<Object?> route = _routeOf(tester, 'dialog');
      expect(route.barrierColor, const Color(0x00000000));
      expect(
        (route as HarborDialogRoute<Object?>).barrier,
        const HarborBarrier.clear(label: 'Fermer', onTapHint: 'close the dialog'),
      );
      final SemanticsNode barrier = find.semantics.byLabel('Fermer').evaluate().single;
      expect(barrier, isSemantics(label: 'Fermer', hasTapAction: true, onTapHint: 'close the dialog'));
      semantics.dispose();
    });

    testWidgets('a dimmed barrier with a tap hint still fades in', (final tester) async {
      final BuildContext page = await _page(tester);
      unawaited(
        showHarborDialog<void>(
          page,
          barrier: const HarborBarrier.dimmed(onTapHint: 'close the dialog'),
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AnimatedModalBarrier), matching: find.byType(ModalBarrier)),
        findsOneWidget,
      );
      expect(tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).semanticsOnTapHint, 'close the dialog');
    });

    testWidgets('a barrier that is not dismissible keeps it up', (final tester) async {
      final BuildContext page = await _page(tester);
      unawaited(
        showHarborDialog<void>(
          page,
          barrier: const HarborBarrier.dimmed(dismissible: false),
          builder: (_) => const Center(child: Text('dialog')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 300));
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);
    });

    testWidgets("a route's deprecated barrierColor: null is still a barrier with no colour", (final tester) async {
      final BuildContext page = await _page(tester);
      unawaited(
        Navigator.of(page).push(
          // ignore: deprecated_member_use_from_same_package
          HarborDialogRoute<void>(context: page, barrierColor: null, builder: (_) => const Text('dialog')),
        ),
      );
      await tester.pumpAndSettle();
      final HarborDialogRoute<Object?> route = _routeOf(tester, 'dialog') as HarborDialogRoute<Object?>;
      expect(route.barrierColor, const Color(0x00000000));
      expect(route.barrier, const HarborBarrier.clear());
      expect(route.barrierDismissible, isTrue);
    });

    testWidgets('cannot take HarborBarrier.none', (final tester) async {
      final BuildContext page = await _page(tester);
      expect(
        () => HarborDialogRoute<void>(context: page, barrier: HarborBarrier.none, builder: (_) => const SizedBox()),
        throwsAssertionError,
      );
    });

    testWidgets('the deprecated barrierColor, barrierDismissible and barrierLabel still apply', (final tester) async {
      final BuildContext page = await _page(tester);
      unawaited(
        showHarborDialog<void>(
          page,
          // ignore: deprecated_member_use_from_same_package
          barrierColor: _tint,
          // ignore: deprecated_member_use_from_same_package
          barrierDismissible: false,
          // ignore: deprecated_member_use_from_same_package
          barrierLabel: 'Fermer',
          builder: (_) => const Text('dialog'),
        ),
      );
      await tester.pumpAndSettle();
      final HarborDialogRoute<Object?> route = _routeOf(tester, 'dialog') as HarborDialogRoute<Object?>;
      expect(route.barrierColor, _tint);
      expect(route.barrierDismissible, isFalse);
      expect(route.barrierLabel, 'Fermer');
      expect(route.barrier, const HarborBarrier.dimmed(color: _tint, dismissible: false, label: 'Fermer'));
    });
  });

  group('a float', () {
    testWidgets('with no barrier is not modal', (final tester) async {
      final _FloatsState page = await _pumpFloat(
        tester,
        (final VoidCallback close) => const HarborFloat(child: Text('menu')),
      );
      expect(const HarborFloat(child: SizedBox()).modal, isFalse);
      expect(const HarborFloat(child: SizedBox()).barrier, HarborBarrier.none);
      await tester.tap(find.text('Page action'));
      expect(page.taps, <String>['page']);
    });

    testWidgets('with a clear barrier is modal: a tap on it dismisses the float, not the page', (final tester) async {
      final _FloatsState page = await _pumpFloat(
        tester,
        (final VoidCallback close) => _menu(close, barrier: const HarborBarrier.clear()),
      );
      expect(_floatBarrier(tester).color, const Color(0x00000000));
      await tester.tap(find.text('Page action'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(page.taps, isEmpty);
      expect(page.dismissed, 1);
    });

    testWidgets('a barrier that is not dismissible ignores a tap, and back still dismisses it', (final tester) async {
      final _FloatsState page = await _pumpFloat(
        tester,
        (final VoidCallback close) => _menu(close, barrier: const HarborBarrier.clear(dismissible: false)),
      );
      await tester.tap(find.text('Page action'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(page.taps, isEmpty, reason: 'the barrier still blocks the page');
      expect(page.dismissed, 0, reason: 'and the tap did not dismiss the float');
      expect(find.text('menu'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(page.dismissed, 1, reason: 'back always dismisses it');
    });

    testWidgets('a dimmed barrier takes its colour, label and tap hint', (final tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpFloat(
        tester,
        (final VoidCallback close) => _menu(
          close,
          barrier: const HarborBarrier.dimmed(color: _tint, label: 'Fermer', onTapHint: 'close the menu'),
        ),
      );
      expect(_floatBarrier(tester).color, _tint);
      final SemanticsNode barrier = find.semantics.byLabel('Fermer').evaluate().single;
      expect(barrier, isSemantics(label: 'Fermer', hasTapAction: true, onTapHint: 'close the menu'));
      semantics.dispose();
    });

    test('a barrier needs onDismiss', () {
      expect(() => HarborFloat(barrier: const HarborBarrier.clear(), child: const SizedBox()), throwsAssertionError);
    });

    group('the deprecated spellings', () {
      test('modal: true reads as a clear barrier, or a dimmed one with a barrierColor', () {
        void close() {}
        // ignore: deprecated_member_use_from_same_package
        final HarborFloat clear = HarborFloat(
          modal: true,
          barrierLabel: 'Fermer',
          onDismiss: close,
          child: const SizedBox(),
        );
        expect(clear.barrier, const HarborBarrier.clear(label: 'Fermer'));
        expect(clear.modal, isTrue);
        // ignore: deprecated_member_use_from_same_package
        expect(clear.barrierLabel, 'Fermer');
        // ignore: deprecated_member_use_from_same_package
        final HarborFloat dimmed = HarborFloat(
          modal: true,
          barrierColor: _tint,
          onDismiss: close,
          child: const SizedBox(),
        );
        expect(dimmed.barrier, const HarborBarrier.dimmed(color: _tint));
        // ignore: deprecated_member_use_from_same_package
        expect(dimmed.barrierColor, _tint);
        // ignore: deprecated_member_use_from_same_package
        expect(dimmed.barrierLabel, 'Dismiss');
        // ignore: deprecated_member_use_from_same_package
        expect(
          const HarborFloat(barrierColor: _tint, child: SizedBox()).modal,
          isFalse,
          reason: 'it did nothing alone',
        );
      });

      test('giving both is an assert', () {
        expect(
          () => HarborFloat(
            barrier: const HarborBarrier.clear(),
            // ignore: deprecated_member_use_from_same_package
            modal: true,
            onDismiss: () {},
            child: const SizedBox(),
          ),
          throwsAssertionError,
        );
        expect(
          () => HarborFloat(
            barrier: const HarborBarrier.clear(),
            // ignore: deprecated_member_use_from_same_package
            barrierLabel: 'Fermer',
            onDismiss: () {},
            child: const SizedBox(),
          ),
          throwsAssertionError,
        );
      });
    });
  });
}
