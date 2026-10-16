// HarborMaterialSheet draws the sheet showModalBottomSheet would: Material's surface, its drag
// handle, and a drag down to close, on harbor's sheet.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';
import 'package:harbor_test/harbor_test.dart';

late BuildContext _page;

const ValueKey<String> _form = ValueKey<String>('form');

Future<void> _pump(final WidgetTester tester, {final ThemeData? theme}) async {
  // A fresh app each time: no sheet or toast left from the last pump, and no theme change to animate.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpHarborTrial(
    MaterialApp(
      theme: theme,
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: HarborMaterialFrame(
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

late Future<void> _closed;

/// Opens [sheet] from the page and lets it slide in; [_closed] completes when it has gone.
Future<void> _open(final WidgetTester tester, final Widget sheet) async {
  _closed = showHarborSheet<void>(_page, builder: (final _) => sheet);
  await tester.pumpAndSettle();
}

Material _surface(final WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(HarborMaterialSheetSurface), matching: find.byType(Material)),
);

void main() {
  testWidgets('Material 3\'s surface: surfaceContainerLow, a top rounded by 28, no shadow', (
    final WidgetTester tester,
  ) async {
    final ThemeData theme = ThemeData(colorSchemeSeed: Colors.teal);
    await _pump(tester, theme: theme);
    await _open(tester, const HarborMaterialSheet(body: SizedBox(key: _form, height: 200)));
    expect(_surface(tester).color, theme.colorScheme.surfaceContainerLow);
    expect(_surface(tester).elevation, 1.0);
    expect(_surface(tester).shadowColor, Colors.transparent);
    expect(
      _surface(tester).shape,
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    );
  });

  testWidgets('Material 2\'s, the theme\'s modal values, and the arguments over both', (
    final WidgetTester tester,
  ) async {
    final ThemeData m2 = ThemeData(useMaterial3: false);
    await _pump(tester, theme: m2);
    await _open(tester, const HarborMaterialSheet(body: SizedBox(height: 200)));
    expect(_surface(tester).color, m2.canvasColor);
    expect(_surface(tester).elevation, 0.0);
    expect(_surface(tester).shape, isNull);

    await _pump(
      tester,
      theme: ThemeData(
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.blue,
          modalBackgroundColor: Colors.green,
          elevation: 2,
          modalElevation: 8,
        ),
      ),
    );
    await _open(tester, const HarborMaterialSheet(body: SizedBox(height: 200)));
    expect(_surface(tester).color, Colors.green);
    expect(_surface(tester).elevation, 8.0);

    await _pump(tester);
    await _open(
      tester,
      const HarborMaterialSheet(
        backgroundColor: Colors.orange,
        elevation: 4,
        shape: RoundedRectangleBorder(),
        body: SizedBox(height: 200),
      ),
    );
    expect(_surface(tester).color, Colors.orange);
    expect(_surface(tester).elevation, 4.0);
    expect(_surface(tester).shape, const RoundedRectangleBorder());
  });

  testWidgets('the content is clipped to the shape, and the surface is not, so its shadow shows', (
    final WidgetTester tester,
  ) async {
    await _pump(tester);
    await _open(tester, const HarborMaterialSheet(body: SizedBox(key: _form, height: 200)));
    expect(tester.widget<HarborSheet>(find.byType(HarborSheet)).clip, isNull);
    expect(find.ancestor(of: find.byType(HarborMaterialSheetSurface), matching: find.byType(ClipPath)), findsNothing);
    expect(find.ancestor(of: find.byKey(_form), matching: find.byType(ClipPath)), findsOneWidget);
  });

  testWidgets('the drag handle: 32 by 4, centred in a 48 band above the body', (final WidgetTester tester) async {
    final ThemeData theme = ThemeData(colorSchemeSeed: Colors.teal);
    await _pump(tester, theme: theme);
    await _open(tester, const HarborMaterialSheet(showDragHandle: true, body: SizedBox(key: _form, height: 200)));
    final Finder bar = find.descendant(of: find.byType(HarborMaterialDragHandle), matching: find.byType(DecoratedBox));
    final Rect handle = tester.getRect(bar);
    final Rect band = tester.getRect(find.byType(HarborMaterialDragHandle));
    final Rect sheet = tester.getRect(find.byType(HarborSheet));
    expect(handle.size, const Size(32, 4));
    expect(band.height, 48.0);
    expect(band.top, sheet.top);
    expect(handle.center, band.center);
    expect(handle.center.dx, sheet.center.dx);
    final BoxDecoration decoration = tester.widget<DecoratedBox>(bar).decoration as BoxDecoration;
    expect(decoration.color, theme.colorScheme.onSurfaceVariant);
    expect(tester.getRect(find.byKey(_form)).top, greaterThanOrEqualTo(band.bottom), reason: 'the body rests below it');
  });

  testWidgets('the theme\'s handle, and a handle above a header', (final WidgetTester tester) async {
    await _pump(
      tester,
      theme: ThemeData(
        bottomSheetTheme: const BottomSheetThemeData(
          showDragHandle: true,
          dragHandleColor: Colors.red,
          dragHandleSize: Size(40, 6),
        ),
      ),
    );
    await _open(tester, const HarborMaterialSheet(header: Text('Reply'), body: SizedBox(height: 200)));
    final Finder bar = find.descendant(of: find.byType(HarborMaterialDragHandle), matching: find.byType(DecoratedBox));
    expect(tester.getSize(bar), const Size(40, 6));
    expect((tester.widget<DecoratedBox>(bar).decoration as BoxDecoration).color, Colors.red);
    expect(
      tester.getRect(find.text('Reply')).top,
      greaterThanOrEqualTo(tester.getRect(find.byType(HarborMaterialDragHandle)).bottom),
    );
  });

  testWidgets('the handle is a button that closes the sheet for a screen reader', (final WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(tester);
    await _open(tester, const HarborMaterialSheet(showDragHandle: true, body: SizedBox(height: 200)));
    final SemanticsNode node = tester.getSemantics(
      find.descendant(of: find.byType(HarborMaterialDragHandle), matching: find.byType(Semantics)).first,
    );
    expect(node.label, 'Dismiss');
    expect(node.flagsCollection.isButton, isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.byType(HarborSheet), findsNothing);
    await _closed;
    semantics.dispose();
  });

  testWidgets('a drag down closes it, unless enableDrag is off', (final WidgetTester tester) async {
    await _pump(tester);
    await _open(tester, const HarborMaterialSheet(body: SizedBox(key: _form, height: 300)));
    expect(tester.widget<HarborSheet>(find.byType(HarborSheet)).dragToClose, isTrue);
    await tester.fling(find.byKey(_form), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(HarborSheet), findsNothing);

    await _open(tester, const HarborMaterialSheet(enableDrag: false, body: SizedBox(key: _form, height: 300)));
    await tester.fling(find.byKey(_form), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(find.byType(HarborSheet), findsOneWidget);
  });

  testWidgets('text fields and ink work in it', (final WidgetTester tester) async {
    await _pump(tester);
    await _open(
      tester,
      HarborMaterialSheet(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TextField(),
            InkWell(onTap: () {}, child: const SizedBox(height: 48, width: 200)),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(InkWell));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('a draggable one, with a handle that drags it', (final WidgetTester tester) async {
    await _pump(tester);
    final DraggableScrollableController controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await _open(
      tester,
      HarborMaterialSheet.draggable(
        showDragHandle: true,
        controller: controller,
        builder: (final BuildContext context, final ScrollController scroll) => HarborScrollView(
          controller: scroll,
          slivers: <Widget>[
            SliverList.builder(
              itemCount: 40,
              itemBuilder: (final _, final int i) => SizedBox(height: 48, child: Text('$i')),
            ),
          ],
        ),
      ),
    );
    expect(find.byType(HarborMaterialDragHandle), findsOneWidget);
    expect(controller.size, moreOrLessEquals(0.5, epsilon: 0.01));
    await tester.drag(find.byType(HarborMaterialDragHandle), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
  });

  testWidgets('semanticLabelOf: Material\'s dialog label, but none on iOS and macOS', (
    final WidgetTester tester,
  ) async {
    await _pump(tester);
    expect(HarborMaterialSheet.semanticLabelOf(_page), 'Dialog');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(HarborMaterialSheet.semanticLabelOf(_page), isNull);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(HarborMaterialSheet.semanticLabelOf(_page), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
