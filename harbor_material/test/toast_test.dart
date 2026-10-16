// HarborSnackToast is a SnackBar's surface for a harbor toast, and context.showSnackToast shows one
// where a snack bar sits, clear of the page's bars, staying while it has an action.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';
import 'package:harbor_test/harbor_test.dart';

late BuildContext _page;

const ValueKey<String> _tabs = ValueKey<String>('tabs');

Future<void> _pump(final WidgetTester tester, {final ThemeData? theme}) async {
  // A fresh app each time: no sheet or toast left from the last pump, and no theme change to animate.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpHarborTrial(
    MaterialApp(
      theme: theme,
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: HarborMaterialFrame(
        bottom: const <HarborBar>[
          HarborBar.solid(
            child: SizedBox(key: _tabs, width: double.infinity, height: 80),
          ),
        ],
        body: Builder(
          builder: (final BuildContext context) {
            _page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Material _surface(final WidgetTester tester) =>
    tester.widget<Material>(find.descendant(of: find.byType(HarborSnackToast), matching: find.byType(Material)).first);

void main() {
  testWidgets('it sits low on the page, above the tab bar, the room\'s width less the margin', (
    final WidgetTester tester,
  ) async {
    await _pump(tester);
    _page.showSnackToast(const Text('Archived'));
    await tester.pumpAndSettle();
    final Rect toast = tester.getRect(find.byType(HarborSnackToast));
    final Rect tabs = tester.getRect(find.byKey(_tabs));
    expect(toast.bottom, lessThanOrEqualTo(tabs.top));
    expect(toast.width, HarborTrialDevice.iPhone17.size.width - 32);
  });

  testWidgets('Material 3\'s snack bar colours and shape', (final WidgetTester tester) async {
    final ThemeData theme = ThemeData(colorSchemeSeed: Colors.teal);
    await _pump(tester, theme: theme);
    _page.showSnackToast(const Text('Archived'), actionLabel: 'Undo', onAction: () {});
    await tester.pumpAndSettle();
    expect(_surface(tester).color, theme.colorScheme.inverseSurface);
    expect(_surface(tester).elevation, 6.0);
    expect(_surface(tester).shape, const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))));
    final RenderParagraph message = tester.renderObject<RenderParagraph>(find.text('Archived'));
    expect(message.text.style?.color, theme.colorScheme.onInverseSurface);
    final RenderParagraph action = tester.renderObject<RenderParagraph>(find.text('Undo'));
    expect(action.text.style?.color, theme.colorScheme.inversePrimary);
  });

  testWidgets('Material 2\'s, and the SnackBarTheme\'s over both', (final WidgetTester tester) async {
    final ThemeData m2 = ThemeData(useMaterial3: false);
    await _pump(tester, theme: m2);
    _page.showSnackToast(const Text('Archived'));
    await tester.pumpAndSettle();
    expect(
      _surface(tester).color,
      Color.alphaBlend(m2.colorScheme.onSurface.withValues(alpha: 0.8), m2.colorScheme.surface),
    );

    await _pump(
      tester,
      theme: ThemeData(snackBarTheme: const SnackBarThemeData(backgroundColor: Colors.deepPurple, elevation: 2)),
    );
    _page.showSnackToast(const Text('Saved'));
    await tester.pumpAndSettle();
    expect(_surface(tester).color, Colors.deepPurple);
    expect(_surface(tester).elevation, 2.0);
  });

  testWidgets('with no action it leaves after 4 s, as a SnackBar does', (final WidgetTester tester) async {
    await _pump(tester);
    final HarborToastEntry entry = _page.showSnackToast(const Text('Archived'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(HarborSnackToast), findsNothing);
    expect(await entry.closed, HarborToastClosedReason.timeout);
  });

  testWidgets('with an action it stays until the action is pressed, which hides it', (final WidgetTester tester) async {
    await _pump(tester);
    int undone = 0;
    final HarborToastEntry entry = _page.showSnackToast(
      const Text('Archived'),
      actionLabel: 'Undo',
      onAction: () => undone++,
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(find.byType(HarborSnackToast), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.byType(HarborSnackToast), findsNothing);
    expect(await entry.closed, HarborToastClosedReason.hide);
  });

  testWidgets('it is announced once, by harbor\'s live region', (final WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    _page.showSnackToast(const Text('Archived'));
    await tester.pumpAndSettle();
    expect(find.semantics.byPredicate((final SemanticsNode node) => node.flagsCollection.isLiveRegion), findsOne);
    semantics.dispose();
  });
}
