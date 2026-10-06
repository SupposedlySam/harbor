import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor/testing.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/game/settings.dart';
import 'package:harbor_example/scenes/tv.dart';

/// The television (1920×1080) over the 1200×675 reference screen.
const double _scale = 1920 / 1200;

/// 5% title-safe on the reference screen's sides and top.
const double _titleSafeStart = 1200 * 0.05;
const double _titleSafeTop = 675 * 0.05;

Future<(HarborSeaTrial, HarborSettings)> _pumpTv(final WidgetTester tester) async {
  final HarborSettings settings = HarborSettings()..tv = true;
  addTearDown(settings.dispose);
  final HarborSeaTrial trial = await tester.pumpSeaTrial(
    HarborSettingsScope(
      settings: settings,
      child: MaterialApp(
        theme: Palette.theme(),
        builder: (final BuildContext context, final Widget? child) => HarborScaleModel(
          referenceSize: const Size(1200, 675),
          coast: const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),
          child: HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 32), child: child!),
        ),
        home: const TvHarborTown(),
      ),
    ),
    device: HarborTrialDevice.television,
  );
  await _settle(tester);
  return (trial, settings);
}

/// Steps time: the seas and lighthouses never settle.
Future<void> _settle(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A rect on the reference screen.
Rect _model(final WidgetTester tester, final Finder finder) {
  final Rect global = tester.getRect(finder);
  return Rect.fromLTRB(global.left / _scale, global.top / _scale, global.right / _scale, global.bottom / _scale);
}

Finder _key(final String key) => find.byKey(ValueKey<String>(key));

/// The fleet wall's heading text, inside its moored padding.
Finder get _heading => find.descendant(of: _key('fleet wall heading'), matching: find.byType(Column)).first;

/// Where the focused widget is, on the reference screen.
Rect _focusedRect() {
  final RenderBox box = FocusManager.instance.primaryFocus!.context!.findRenderObject()! as RenderBox;
  final Rect global = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
  return Rect.fromLTRB(global.left / _scale, global.top / _scale, global.right / _scale, global.bottom / _scale);
}

Future<void> _focusRail(final WidgetTester tester, final String item) async {
  Focus.of(tester.element(find.descendant(of: _key(item), matching: find.byType(Row)))).requestFocus();
  await _settle(tester);
}

void main() {
  testWidgets('the rail absorbs the title-safe coast and rests at 96', (final WidgetTester tester) async {
    await _pumpTv(tester);
    final Rect rail = _model(tester, _key('rail'));
    expect(rail.left, moreOrLessEquals(_titleSafeStart));
    expect(rail.right, moreOrLessEquals(96));
    // Its items keep clear of the title-safe band across it.
    expect(_model(tester, _key('rail fleetWall')).top, greaterThanOrEqualTo(_titleSafeTop));
  });

  testWidgets('the fleet wall follows the rail live as it opens on focus', (final WidgetTester tester) async {
    await _pumpTv(tester);
    final double before = _model(tester, _heading).left;
    expect(before, moreOrLessEquals(96 + 32));
    // The first card has focus; step left onto the rail.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(_model(tester, _key('rail')).right, moreOrLessEquals(240));
    expect(_model(tester, _heading).left, moreOrLessEquals(240 + 32));
    // And back off it: the rail closes and the wall follows.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(_model(tester, _key('rail')).right, moreOrLessEquals(96));
    expect(_model(tester, _heading).left, moreOrLessEquals(before));
  });

  testWidgets('focus along a row brings each card clear of the rail and the title-safe band', (
    final WidgetTester tester,
  ) async {
    await _pumpTv(tester);
    ScrollPosition row() => tester
        .state<ScrollableState>(find.descendant(of: _key('fleet row 0'), matching: find.byType(Scrollable)))
        .position;
    // Clear of the resting rail plus the mooring line, and of the end's
    // title-safe band plus the mooring line, with the 24 reveal margin.
    const double startClear = 96 + 32;
    const double endClear = 1200 - _titleSafeStart - 32;
    Future<void> step(final LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await _settle(tester);
      final Rect card = _focusedRect();
      // Undo the focused card's 1.06 lift.
      final Rect laid = card.deflate(card.width * (0.06 / 1.06) / 2);
      final ScrollPosition position = row();
      final String at = '$laid at ${position.pixels}';
      expect(laid.left, greaterThanOrEqualTo(startClear - 0.5), reason: at);
      expect(laid.right, lessThanOrEqualTo(endClear + 0.5), reason: at);
      if (position.pixels > position.minScrollExtent && position.pixels < position.maxScrollExtent) {
        expect(laid.left, greaterThanOrEqualTo(startClear + 24 - 0.5), reason: at);
        expect(laid.right, lessThanOrEqualTo(endClear - 24 + 0.5), reason: at);
      }
    }

    for (int i = 0; i < 7; i++) {
      await step(LogicalKeyboardKey.arrowRight);
    }
    expect(row().pixels, row().maxScrollExtent);
    for (int i = 0; i < 7; i++) {
      await step(LogicalKeyboardKey.arrowLeft);
    }
    expect(row().pixels, 0);
  });

  testWidgets('the open-sea card holds still while the rail opens over it', (final WidgetTester tester) async {
    await _pumpTv(tester);
    await tester.tap(_key('rail openSea'));
    await _settle(tester);
    final Rect before = _model(tester, _key('voyage card'));
    expect(before.left, moreOrLessEquals(96 + 32));
    await _focusRail(tester, 'rail openSea');
    expect(_model(tester, _key('rail')).right, moreOrLessEquals(240));
    expect(_model(tester, _key('voyage card')), before);
  });

  testWidgets('a long voyage darkens the rail, which keeps its ground', (final WidgetTester tester) async {
    final (HarborSeaTrial trial, _) = await _pumpTv(tester);
    await tester.tap(_key('rail longVoyage'));
    await _settle(tester);
    await tester.tap(_key('voyage toggle'));
    await _settle(tester);
    final HarborDockRecord rail = trial.docksAround(_key('rail')).single;
    expect(rail.state, HarborDockState.dark);
    expect(rail.extent, moreOrLessEquals(96));
    await tester.tap(_key('voyage toggle'));
    await _settle(tester);
    expect(trial.docksAround(_key('rail')).single.state, HarborDockState.open);
  });

  testWidgets('back to the phone turns TV mode off', (final WidgetTester tester) async {
    final (_, HarborSettings settings) = await _pumpTv(tester);
    await tester.tap(_key('rail phone'));
    await tester.pump();
    expect(settings.tv, isFalse);
  });
}
