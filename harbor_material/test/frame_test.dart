// HarborMaterialFrame lays a page out as a Scaffold does: the same page colour and text style, the
// app bar's body edge where a Scaffold's body starts, and ink with a Material to paint on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';
import 'package:harbor_test/harbor_test.dart';

const ValueKey<String> _body = ValueKey<String>('body');

late TextStyle _textStyle;

Widget _measuredBody() => Builder(
  builder: (final BuildContext context) {
    _textStyle = DefaultTextStyle.of(context).style;
    return const SizedBox.expand(key: _body);
  },
);

Widget _app(final Widget home, {final ThemeData? theme}) => MaterialApp(
  theme: theme,
  builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
  home: home,
);

void main() {
  for (final HarborTrialDevice device in HarborTrialDevice.phones) {
    testWidgets('the body starts where a Scaffold\'s does, on ${device.name}', (final WidgetTester tester) async {
      await tester.pumpHarborTrial(
        _app(
          Scaffold(
            appBar: AppBar(title: const Text('Inbox')),
            body: _measuredBody(),
          ),
        ),
        device: device,
      );
      final Rect scaffold = tester.getRect(find.byKey(_body));
      final TextStyle scaffoldText = _textStyle;

      await tester.pumpHarborTrial(
        _app(
          HarborMaterialFrame(
            appBar: AppBar(title: const Text('Inbox')),
            body: _measuredBody(),
          ),
        ),
        device: device,
      );
      expect(tester.getRect(find.byKey(_body)).top, scaffold.top);
      expect(_textStyle, scaffoldText);
    });
  }

  testWidgets('the page is the theme\'s scaffoldBackgroundColor, or its own', (final WidgetTester tester) async {
    final ThemeData theme = ThemeData(scaffoldBackgroundColor: Colors.lime);
    Material page() => tester.widget<Material>(
      find.descendant(of: find.byType(HarborMaterialFrame), matching: find.byType(Material)).first,
    );

    await tester.pumpHarborTrial(_app(HarborMaterialFrame(body: _measuredBody()), theme: theme));
    expect(page().color, Colors.lime);

    await tester.pumpHarborTrial(
      _app(
        HarborMaterialFrame(backgroundColor: Colors.cyan, body: _measuredBody()),
        theme: theme,
      ),
    );
    expect(page().color, Colors.cyan);
  });

  testWidgets('the app bar goes first in top, outermost, and takes the status bar', (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      _app(
        HarborMaterialFrame(
          appBar: AppBar(title: const Text('Inbox')),
          top: const <HarborBar>[
            HarborBar.solid(
              child: SizedBox(width: double.infinity, height: 40, key: ValueKey<String>('filters')),
            ),
          ],
          body: _measuredBody(),
        ),
      ),
    );
    final Rect appBar = tester.getRect(find.byType(AppBar));
    final Rect filters = tester.getRect(find.byKey(const ValueKey<String>('filters')));
    expect(appBar.top, HarborTrialDevice.iPhone17.systemEdges.top);
    expect(filters.top, appBar.bottom);
    expect(tester.getRect(find.byKey(_body)).top, filters.bottom);
  });

  testWidgets('frame arguments reach the frame', (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      _app(
        HarborMaterialFrame(
          bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(width: double.infinity, height: 56))],
          bodyClearsKeyboard: false,
          debugLabel: 'inbox',
          body: _measuredBody(),
        ),
      ),
    );
    final HarborFrame frame = tester.widget<HarborFrame>(find.byType(HarborFrame).last);
    expect(frame.bottom, hasLength(1));
    expect(frame.bodyClearsKeyboard, isFalse);
    expect(frame.debugLabel, 'inbox');
  });

  testWidgets('ink in the body has a Material to splash on', (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      _app(
        HarborMaterialFrame(
          body: Center(
            child: InkWell(onTap: () {}, child: const SizedBox(width: 100, height: 100)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an AppBar hears the body scroll under it, as in a Scaffold', (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      _app(
        HarborMaterialFrame(
          appBar: AppBar(title: const Text('Inbox')),
          body: HarborScrollView(
            slivers: <Widget>[
              SliverList.builder(
                itemCount: 60,
                itemBuilder: (final _, final int i) => SizedBox(height: 48, child: Text('$i')),
              ),
            ],
          ),
        ),
        theme: ThemeData(colorSchemeSeed: Colors.teal),
      ),
    );
    Material appBar() =>
        tester.widget<Material>(find.descendant(of: find.byType(AppBar), matching: find.byType(Material)).first);
    expect(appBar().elevation, 0.0);
    await tester.drag(find.byType(HarborScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(appBar().elevation, 3.0);
  });
}
