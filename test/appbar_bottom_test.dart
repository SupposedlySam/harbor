// A top or bottom bar bounds a PreferredSizeWidget child at its own height, as Scaffold bounds its
// appBar: an AppBar with a `bottom:` lays its toolbar out in a Column with a Flexible, which threw
// under the unbounded height a bar gives its child. The bound is the child's intrinsic height, so an
// AppBar sized by AppBarTheme.toolbarHeight keeps that height, and its preferredSize where the
// child cannot be asked.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const ValueKey<String> _bar = ValueKey<String>('bar');
const ValueKey<String> _body = ValueKey<String>('body');

const TabBar _tabs = TabBar(
  tabs: <Widget>[
    Tab(text: 'One'),
    Tab(text: 'Two'),
  ],
);

Map<String, PreferredSizeWidget> get _bottoms => <String, PreferredSizeWidget>{
  'a 4-high bottom': const PreferredSize(preferredSize: Size.fromHeight(4), child: SizedBox(height: 4)),
  'a TabBar': _tabs,
};

late EdgeInsets _bodyPadding;

Future<void> _pump(
  final WidgetTester tester,
  final HarborBar Function({required Widget child}) bar,
  final PreferredSizeWidget appBar,
  final HarborTrialDevice device, {
  final double? themeToolbarHeight,
}) async {
  await tester.pumpHarborTrial(
    MaterialApp(
      theme: ThemeData(appBarTheme: AppBarTheme(toolbarHeight: themeToolbarHeight)),
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: DefaultTabController(
        length: 2,
        child: HarborFrame(
          top: <HarborBar>[bar(child: appBar)],
          body: Builder(
            builder: (final BuildContext context) {
              _bodyPadding = MediaQuery.paddingOf(context);
              return const SizedBox.expand(key: _body);
            },
          ),
        ),
      ),
    ),
    device: device,
  );
}

HarborBar _solid({required final Widget child}) => HarborBar.solid(child: child);
HarborBar _overlay({required final Widget child}) => HarborBar.overlay(child: child);

/// How far the bar reaches into the frame: where a solid bar's body starts, or how far an overlay
/// bar's body is told to keep clear.
double _reach(final WidgetTester tester, final String kind) =>
    kind == 'solid' ? tester.getTopLeft(find.byKey(_body)).dy : _bodyPadding.top;

void main() {
  final Map<String, HarborBar Function({required Widget child})> kinds =
      <String, HarborBar Function({required Widget child})>{'solid': _solid, 'overlay': _overlay};
  for (final HarborTrialDevice device in <HarborTrialDevice>[HarborTrialDevice.iPhone17, HarborTrialDevice.iPhoneSE]) {
    final double statusBar = device.systemEdges.top;
    for (final MapEntry<String, HarborBar Function({required Widget child})> kind in kinds.entries) {
      group('${device.name}, a ${kind.key} top bar', () {
        for (final MapEntry<String, PreferredSizeWidget> bottom in _bottoms.entries) {
          testWidgets('an AppBar with ${bottom.key} is its toolbar and its bottom high', (final tester) async {
            await _pump(tester, kind.value, AppBar(key: _bar, title: const Text('x'), bottom: bottom.value), device);
            expect(tester.takeException(), isNull);
            final double expected = kToolbarHeight + bottom.value.preferredSize.height;
            expect(tester.getSize(find.byKey(_bar)).height, expected);
            expect(tester.getTopLeft(find.byKey(_bar)).dy, statusBar, reason: 'it sits below the status bar');
            expect(_reach(tester, kind.key), statusBar + expected);
          });
        }

        testWidgets('an AppBar with its own toolbarHeight and a bottom keeps both', (final tester) async {
          await _pump(
            tester,
            kind.value,
            AppBar(key: _bar, title: const Text('x'), toolbarHeight: 72, bottom: _tabs),
            device,
          );
          expect(tester.getSize(find.byKey(_bar)).height, 72 + _tabs.preferredSize.height);
          expect(_reach(tester, kind.key), statusBar + 72 + _tabs.preferredSize.height);
        });

        for (final MapEntry<String, PreferredSizeWidget?> bottom in <String, PreferredSizeWidget?>{
          'no bottom': null,
          ..._bottoms,
        }.entries) {
          testWidgets('an AppBar sized by AppBarTheme.toolbarHeight alone keeps it, with ${bottom.key}', (
            final tester,
          ) async {
            await _pump(
              tester,
              kind.value,
              AppBar(key: _bar, title: const Text('x'), bottom: bottom.value),
              device,
              themeToolbarHeight: 80,
            );
            final double expected = 80 + (bottom.value?.preferredSize.height ?? 0);
            expect(tester.getSize(find.byKey(_bar)).height, expected);
            expect(_reach(tester, kind.key), statusBar + expected);
          });
        }

        testWidgets('a plain AppBar keeps its toolbar height (positive control)', (final tester) async {
          await _pump(tester, kind.value, AppBar(key: _bar, title: const Text('x')), device);
          expect(tester.getSize(find.byKey(_bar)).height, kToolbarHeight);
          expect(_reach(tester, kind.key), statusBar + kToolbarHeight);
        });
      });
    }
  }

  testWidgets('a bottom bar holds a PreferredSizeWidget at its preferred height', (final tester) async {
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          bottom: <HarborBar>[
            HarborBar.solid(
              child: AppBar(key: _bar, title: const Text('x'), bottom: _bottoms['a 4-high bottom']),
            ),
          ],
          body: const SizedBox.expand(key: _body),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(_bar)).height, kToolbarHeight + 4);
    expect(
      tester.getBottomLeft(find.byKey(_body)).dy,
      874 - 34 - kToolbarHeight - 4,
      reason: 'the bar stands on the home indicator',
    );
  });

  testWidgets('a PreferredSizeWidget shorter than its preferredSize keeps its own height', (final tester) async {
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: const HarborFrame(
          top: <HarborBar>[
            HarborBar.solid(
              child: PreferredSize(
                preferredSize: Size.fromHeight(40),
                child: SizedBox(key: _bar, height: 30),
              ),
            ),
          ],
          body: SizedBox.expand(key: _body),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(_bar)).height, 30, reason: 'the bound is a most, as Scaffold gives');
    expect(tester.getTopLeft(find.byKey(_body)).dy, 62 + 30);
  });

  group('a child that cannot be asked for its intrinsic height', () {
    testWidgets('an AppBar whose flexibleSpace is a LayoutBuilder, with a bottom, is held to its preferredSize', (
      final tester,
    ) async {
      await _pump(
        tester,
        _solid,
        AppBar(
          key: _bar,
          title: const Text('x'),
          // A FlexibleSpaceBar is built in a LayoutBuilder too, but needs the settings a Scaffold gives.
          flexibleSpace: LayoutBuilder(
            builder: (final BuildContext context, final BoxConstraints constraints) => const SizedBox.expand(),
          ),
          bottom: _tabs,
        ),
        HarborTrialDevice.iPhone17,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_bar)).height, kToolbarHeight + _tabs.preferredSize.height);
      expect(_reach(tester, 'solid'), 62 + kToolbarHeight + _tabs.preferredSize.height);
    });

    testWidgets('a PreferredSize around a LayoutBuilder is held to its preferredSize', (final tester) async {
      await _pump(
        tester,
        _overlay,
        PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: LayoutBuilder(
            builder: (final BuildContext context, final BoxConstraints constraints) => Column(
              children: <Widget>[
                Expanded(
                  child: SizedBox(key: _bar, height: constraints.maxHeight),
                ),
              ],
            ),
          ),
        ),
        HarborTrialDevice.iPhoneSE,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_bar)).height, 50);
      expect(_reach(tester, 'overlay'), 20 + 50);
    });
  });

  testWidgets('a PreferredSize around a horizontal ListView (a viewport) is held to its preferredSize', (
    final tester,
  ) async {
    await _pump(
      tester,
      _solid,
      PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: ListView(key: _bar, scrollDirection: Axis.horizontal, children: const <Widget>[SizedBox(width: 100)]),
      ),
      HarborTrialDevice.iPhoneSE,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(_bar)).height, 50);
  });

  testWidgets('a child with no intrinsic height of its own fills its preferredSize, as under Scaffold', (
    final tester,
  ) async {
    await _pump(
      tester,
      _solid,
      PreferredSize(
        preferredSize: const Size.fromHeight(50),
        // A Container with no child fills what it is given, and asks nothing of its own.
        child: Container(key: _bar, color: const Color(0xFF0000FF)),
      ),
      HarborTrialDevice.iPhoneSE,
    );
    expect(tester.getSize(find.byKey(_bar)).height, 50);
    expect(_reach(tester, 'solid'), 20 + 50);
  });

  testWidgets('a scrolling TabBar (a SingleChildScrollView) is asked, so a themed toolbar keeps its height', (
    final tester,
  ) async {
    const TabBar scrolling = TabBar(
      isScrollable: true,
      tabs: <Widget>[
        Tab(text: 'One'),
        Tab(text: 'Two'),
      ],
    );
    await _pump(
      tester,
      _solid,
      AppBar(key: _bar, title: const Text('x'), bottom: scrolling),
      HarborTrialDevice.iPhone17,
      themeToolbarHeight: 80,
    );
    expect(tester.getSize(find.byKey(_bar)).height, 80 + scrolling.preferredSize.height);
  });
}
