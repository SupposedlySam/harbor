// HarborMaterialBar.appBar paints the AppBar's own surface behind the status bar: the backdrop's
// Material is checked against the Material the AppBar builds for itself, in Material 2 and 3,
// light and dark, with the app bar's and the theme's colours, and scrolled under.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';
import 'package:harbor_test/harbor_test.dart';

Material _backdrop(final WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: find.byType(HarborMaterialAppBarSurface), matching: find.byType(Material)),
);

/// The Material the AppBar builds for its own surface: the outermost one inside it.
Material _appBarMaterial(final WidgetTester tester) =>
    tester.widget<Material>(find.descendant(of: find.byType(AppBar), matching: find.byType(Material)).first);

/// The color and elevation a Material paints with, where its shadow and tint come from.
void _expectSameSurface(final WidgetTester tester) {
  final Material backdrop = _backdrop(tester);
  final Material appBar = _appBarMaterial(tester);
  expect(backdrop.color, appBar.color, reason: 'color');
  expect(backdrop.elevation, appBar.elevation, reason: 'elevation');
  expect(backdrop.surfaceTintColor, appBar.surfaceTintColor, reason: 'surface tint');
  expect(backdrop.shape, appBar.shape, reason: 'shape');
  expect(backdrop.type, appBar.type, reason: 'type');
}

/// Pumps a frame with an app bar, and lets a theme change from the last pump finish animating.
Future<void> _pump(
  final WidgetTester tester, {
  required final ThemeData theme,
  final AppBar? appBar,
  final Widget body = const SizedBox.expand(),
}) async {
  await tester.pumpHarborTrial(
    MaterialApp(
      theme: theme,
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: HarborMaterialFrame(
        appBar: appBar ?? AppBar(title: const Text('Inbox')),
        body: body,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    'Material 3, light': ThemeData(colorSchemeSeed: Colors.teal),
    'Material 3, dark': ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
    'Material 2, light': ThemeData(useMaterial3: false, primarySwatch: Colors.indigo),
    'Material 2, dark': ThemeData(useMaterial3: false, brightness: Brightness.dark),
    'an AppBarTheme colour': ThemeData(appBarTheme: const AppBarThemeData(backgroundColor: Colors.amber)),
  };

  for (final MapEntry<String, ThemeData> theme in themes.entries) {
    testWidgets('the backdrop is the AppBar\'s own surface: ${theme.key}', (final WidgetTester tester) async {
      await _pump(tester, theme: theme.value);
      _expectSameSurface(tester);
    });
  }

  testWidgets('the expected colours, by Material\'s rules', (final WidgetTester tester) async {
    final ThemeData m2 = ThemeData(useMaterial3: false, primarySwatch: Colors.indigo);
    await _pump(tester, theme: m2);
    expect(_backdrop(tester).color, m2.colorScheme.primary);

    final ThemeData m2Dark = ThemeData(useMaterial3: false, brightness: Brightness.dark);
    await _pump(tester, theme: m2Dark);
    expect(_backdrop(tester).color, m2Dark.colorScheme.surface);

    final ThemeData m3 = ThemeData(colorSchemeSeed: Colors.teal);
    await _pump(tester, theme: m3);
    expect(_backdrop(tester).color, m3.colorScheme.surface);

    await _pump(
      tester,
      theme: m3,
      appBar: AppBar(backgroundColor: Colors.pink, title: const Text('Inbox')),
    );
    expect(_backdrop(tester).color, Colors.pink);
  });

  testWidgets('it runs from the screen\'s edge, behind the status bar, to the AppBar\'s bottom', (
    final WidgetTester tester,
  ) async {
    await _pump(tester, theme: ThemeData());
    final Rect backdrop = tester.getRect(find.byType(HarborMaterialAppBarSurface));
    final Rect appBar = tester.getRect(find.byType(AppBar));
    expect(backdrop.top, 0.0);
    expect(appBar.top, HarborTrialDevice.iPhone17.systemEdges.top);
    expect(backdrop.bottom, appBar.bottom);
  });

  testWidgets('scrolled under, in Material 3, it changes with the AppBar', (final WidgetTester tester) async {
    final ThemeData m3 = ThemeData(colorSchemeSeed: Colors.teal);
    await _pump(
      tester,
      theme: m3,
      body: HarborScrollView(
        slivers: <Widget>[
          SliverList.builder(
            itemCount: 60,
            itemBuilder: (final _, final int i) => SizedBox(height: 48, child: Text('$i')),
          ),
        ],
      ),
    );
    expect(_backdrop(tester).color, m3.colorScheme.surface);
    expect(_backdrop(tester).elevation, 0.0);

    await tester.drag(find.byType(HarborScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_backdrop(tester).color, m3.colorScheme.surfaceContainer);
    expect(_backdrop(tester).elevation, 3.0);
    _expectSameSurface(tester);

    await tester.drag(find.byType(HarborScrollView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(_backdrop(tester).color, m3.colorScheme.surface);
    _expectSameSurface(tester);
  });

  testWidgets('forceMaterialTransparency paints nothing', (final WidgetTester tester) async {
    await _pump(
      tester,
      theme: ThemeData(),
      appBar: AppBar(forceMaterialTransparency: true, title: const Text('Inbox')),
    );
    expect(_backdrop(tester).type, MaterialType.transparency);
  });

  testWidgets('it casts no shadow of its own', (final WidgetTester tester) async {
    await _pump(tester, theme: ThemeData(useMaterial3: false));
    expect(_backdrop(tester).shadowColor, Colors.transparent);
  });

  testWidgets('the AppBar\'s systemOverlayStyle sets the status bar, as under a Scaffold', (
    final WidgetTester tester,
  ) async {
    await _pump(
      tester,
      theme: ThemeData(),
      appBar: AppBar(systemOverlayStyle: SystemUiOverlayStyle.light, title: const Text('Inbox')),
    );
    final RenderView view = tester.binding.renderViews.first;
    final SystemUiOverlayStyle? style = view.debugLayer!.find<SystemUiOverlayStyle>(
      Offset(view.paintBounds.center.dx, tester.view.padding.top / 2.0),
    );
    expect(style, SystemUiOverlayStyle.light);
  });

  testWidgets('as an overlay bar, the body runs under it', (final WidgetTester tester) async {
    late EdgeInsets padding;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborMaterialFrame(
          top: <HarborBar>[HarborMaterialBar.appBar(AppBar(title: const Text('Inbox')), kind: HarborBarKind.overlay)],
          body: Builder(
            builder: (final BuildContext context) {
              padding = MediaQuery.paddingOf(context);
              return const SizedBox.expand(key: ValueKey<String>('body'));
            },
          ),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(const ValueKey<String>('body'))).top, 0.0);
    expect(padding.top, tester.getRect(find.byType(AppBar)).bottom);
  });
}
