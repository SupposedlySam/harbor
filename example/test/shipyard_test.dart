import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/scenes/shipyard.dart';

const HarborTrialDevice _device = HarborTrialDevice.iPhone17;

Widget _app() => MaterialApp(
  theme: Palette.theme(),
  builder: (final BuildContext context, final Widget? child) =>
      HarborRoot(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  home: const HarborPage(child: ShipyardPage()),
);

/// Reduce motion stills the sea and the boats, so `pumpAndSettle` (and the
/// trial's keyboard, which settles) can finish.
Future<HarborTrial> _pumpShipyard(final WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final HarborTrial trial = await tester.pumpHarborTrial(_app(), device: _device);
  await tester.pumpAndSettle();
  return trial;
}

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

const String _lowBoat = 'boat-3';

Future<void> _openPaintShop(final WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>(_lowBoat)));
  await tester.pumpAndSettle();
  expect(find.byType(PaintShop), findsOneWidget);
}

void main() {
  testWidgets('the tool strip stands on the home indicator', (final WidgetTester tester) async {
    await _pumpShipyard(tester);
    expect(_rect(tester, 'tool strip').bottom, _device.size.height - _device.systemEdges.bottom);
  });

  testWidgets('a change attaches the unsaved bar directly above the tool strip', (final WidgetTester tester) async {
    await _pumpShipyard(tester);
    expect(find.byKey(const ValueKey<String>('unsaved bar')), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('add crate')));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'unsaved bar').bottom, _rect(tester, 'tool strip').top);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('unsaved bar')), findsNothing);
    expect(find.text('Shipyard saved!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a low boat lifts 80 clear of the paint sheet and settles back', (final WidgetTester tester) async {
    await _pumpShipyard(tester);
    final Rect before = _rect(tester, _lowBoat);

    await _openPaintShop(tester);
    final Rect sheet = _rect(tester, 'paint panel');
    final Rect lifted = _rect(tester, _lowBoat);
    expect(before.bottom, greaterThan(sheet.top - 80), reason: 'the boat starts where the sheet would cover it');
    expect(lifted.bottom, lessThanOrEqualTo(sheet.top - 80 + 0.5));

    // Deselecting takes the boat off the stand: the sheet closes and the boat settles.
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PaintShop), findsNothing);
    expect(_rect(tester, _lowBoat).top, moreOrLessEquals(before.top, epsilon: 0.5));
  });

  testWidgets('the paint panel keeps one height across tabs and the keyboard', (final WidgetTester tester) async {
    final HarborTrial trial = await _pumpShipyard(tester);
    // Let the keyboard's height settle once, so the keyboard space stops estimating.
    await trial.showKeyboard();
    await trial.hideKeyboard();

    await _openPaintShop(tester);
    expect(find.byKey(const ValueKey<String>('estimate hint')), findsNothing);

    await trial.showKeyboard();
    final double nameTabHeight = _rect(tester, 'paint panel').height;
    // The keyboard covers exactly the keyboard space's ground.
    expect(_rect(tester, 'dry dock').top, moreOrLessEquals(trial.keyboardTop));
    expect(find.byKey(const ValueKey<String>('name field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('tab hull')));
    await trial.hideKeyboard();
    expect(_rect(tester, 'paint panel').height, nameTabHeight);
    expect(_rect(tester, 'dry dock').top, moreOrLessEquals(_device.size.height - _device.keyboardHeight));

    // Painting changes the hull.
    final Color red = Palette.hulls[3];
    await tester.tap(find.byKey(ValueKey<String>('hull ${red.toARGB32()}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('unsaved bar')), findsOneWidget);
  });

  testWidgets('with the keyboard shown, the tool strip is withdrawn', (final WidgetTester tester) async {
    final HarborTrial trial = await _pumpShipyard(tester);
    await trial.showKeyboard();
    final HarborBarRecord strip = trial
        .barsAround(find.byKey(const ValueKey<String>('tool strip')))
        .singleWhere((final HarborBarRecord d) => d.label == 'tool strip');
    expect(strip.state, HarborBarState.withdrawn);
    expect(strip.extent, 0);
    expect(strip.rect.height, 0);
  });

  testWidgets('the launch ceremony card overlaps the paint sheet by at most 12', (final WidgetTester tester) async {
    await _pumpShipyard(tester);
    await tester.tap(find.byKey(const ValueKey<String>('ceremony toggle')));
    await tester.pumpAndSettle();
    final Rect centered = _rect(tester, 'ceremony card');
    expect(centered.center.dy, moreOrLessEquals(_device.size.height / 2, epsilon: 0.5));

    await _openPaintShop(tester);
    final Rect sheet = _rect(tester, 'paint panel');
    expect(_rect(tester, 'ceremony card').bottom, lessThanOrEqualTo(sheet.top + 12 + 0.5));
  });
}
