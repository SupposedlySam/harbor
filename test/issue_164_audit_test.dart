// A widget harbor puts around content keeps the same shape from build to build, so what is beneath
// it keeps its state when an input changes: a bar coming or going, an edge, a flag (#164).
//
// The inspector's consumer report wrapped a nested frame only while a bar took a system edge, and
// the report is a widget of its own, so in debug a bar coming or going unmounted the frame's body.
// #165 fixed that (test/issue_164_test.dart); this file varies it and audits every other wrapper
// that could come and go the same way. The last test fails when a widget starts reporting itself
// to the inspector without a group here.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

int _inits = 0;

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _inits++;
  }

  @override
  Widget build(final BuildContext context) => const SizedBox(height: 100);
}

const HarborBar _header = HarborBar.overlay(child: SizedBox(height: 56));
const HarborBar _tabs = HarborBar.overlay(child: SizedBox(height: 40));

Widget _app(final Widget child, {final double keyboard = 0}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      padding: EdgeInsets.only(top: 47, bottom: keyboard > 0 ? 0 : 34),
      viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
      viewInsets: EdgeInsets.only(bottom: keyboard),
    ),
    child: HarborRoot(child: child),
  ),
);

/// Pumps each of [apps] in turn, then the first again, and expects the one [_Probe] in them to have
/// been mounted once and still be there: what each app changes kept the state beneath it.
Future<void> _expectKeepsState(final WidgetTester tester, final List<Widget> apps) async {
  _inits = 0;
  for (final Widget app in <Widget>[...apps, apps.first]) {
    await tester.pumpWidget(app);
    expect(find.byType(_Probe), findsOneWidget);
  }
  expect(_inits, 1, reason: 'the probe was mounted again');
}

void main() {
  group('HarborFrame', () {
    Widget nested({
      final List<HarborBar> top = const <HarborBar>[],
      final List<HarborBar> bottom = const <HarborBar>[],
      final double keyboard = 0,
    }) => _app(
      HarborFrame(
        top: const <HarborBar>[_header],
        body: HarborFrame(top: top, bottom: bottom, body: const _Probe()),
      ),
      keyboard: keyboard,
    );

    testWidgets('a nested frame keeps its body when a bottom bar comes and goes', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        nested(),
        nested(bottom: const <HarborBar>[_tabs]),
      ]);
    });

    testWidgets('a nested frame keeps its body when a top bar comes and goes', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        nested(),
        nested(top: const <HarborBar>[_header]),
      ]);
    });

    testWidgets('a nested frame with bars keeps its body when they all go', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        nested(top: const <HarborBar>[_header], bottom: const <HarborBar>[_tabs]),
        nested(),
        nested(bottom: const <HarborBar>[_tabs]),
      ]);
    });

    testWidgets('a nested frame keeps its body when a bar comes with the keyboard', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        nested(),
        nested(keyboard: 300, bottom: const <HarborBar>[_tabs]),
      ]);
    });

    testWidgets('a nested frame keeps its body when a bar withdraws with the keyboard', (final tester) async {
      const HarborBar withdraws = HarborBar.overlay(
        keyboard: HarborKeyboardStance.withdraws,
        child: SizedBox(height: 40),
      );
      await _expectKeepsState(tester, <Widget>[
        nested(bottom: const <HarborBar>[withdraws]),
        nested(keyboard: 300, bottom: const <HarborBar>[withdraws]),
      ]);
    });

    Widget page({final HarborSystemEdges? systemEdges, final HarborDefaults? defaults, final String? label}) => _app(
      HarborFrame(
        systemEdges: systemEdges,
        defaults: defaults,
        debugLabel: label,
        top: const <HarborBar>[_header],
        body: const _Probe(),
      ),
    );

    testWidgets('a frame keeps its body when its systemEdges are given or taken away', (final tester) async {
      await _expectKeepsState(tester, <Widget>[page(), page(systemEdges: HarborSystemEdges.none)]);
    });

    testWidgets('a frame keeps its body when its defaults are given or taken away', (final tester) async {
      await _expectKeepsState(tester, <Widget>[page(), page(defaults: const HarborDefaults(hinge: HarborHinge.never))]);
    });

    testWidgets('a frame keeps its body when its debugLabel changes', (final tester) async {
      await _expectKeepsState(tester, <Widget>[page(), page(label: 'page')]);
    });
  });

  group('HarborClear', () {
    Widget clear({
      final bool bar = true,
      final bool clearsBars = true,
      final bool clearsKeyboard = false,
      final Set<HarborEdge> edges = HarborEdge.all,
    }) => _app(
      HarborFrame(
        top: <HarborBar>[if (bar) _header],
        body: HarborClear(edges: edges, clearsBars: clearsBars, clearsKeyboard: clearsKeyboard, child: const _Probe()),
      ),
    );

    testWidgets('keeps its child when a bar comes and goes, and when its options change', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        clear(),
        clear(bar: false),
        clear(clearsBars: false),
        clear(clearsKeyboard: true),
        clear(edges: HarborEdge.vertical),
      ]);
    });

    testWidgets('HarborClear.rowInsets keeps its child when a bar comes and goes', (final tester) async {
      Widget rowInsets({required final bool bar}) => _app(
        HarborFrame(
          top: <HarborBar>[if (bar) _header],
          body: const HarborClear.rowInsets(child: _Probe()),
        ),
      );
      await _expectKeepsState(tester, <Widget>[rowInsets(bar: true), rowInsets(bar: false)]);
    });
  });

  group('HarborHandled', () {
    Widget handled({final bool bar = true, final bool clearsBars = true, final bool keepsGeometry = false}) => _app(
      HarborFrame(
        top: <HarborBar>[if (bar) _header],
        body: HarborHandled(clearsBars: clearsBars, keepsGeometry: keepsGeometry, child: const _Probe()),
      ),
    );

    testWidgets('keeps its child when a bar comes and goes, and when its options change', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        handled(),
        handled(bar: false),
        handled(clearsBars: false),
        handled(keepsGeometry: true),
      ]);
    });
  });

  group('HarborScrollView', () {
    Widget scrollView({
      final bool bar = true,
      final bool clearsBars = true,
      final bool startsUnderBars = false,
      final bool edgeEffects = true,
    }) => _app(
      HarborFrame(
        top: <HarborBar>[if (bar) _header],
        body: HarborScrollView(
          clearsBars: clearsBars,
          startsUnderBars: startsUnderBars,
          edgeEffects: edgeEffects,
          slivers: const <Widget>[SliverToBoxAdapter(child: _Probe())],
        ),
      ),
    );

    testWidgets('keeps its first sliver when a bar comes and goes, and when its options change', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        scrollView(),
        scrollView(bar: false),
        scrollView(clearsBars: false),
        scrollView(edgeEffects: false),
      ]);
    });

    testWidgets('keeps its first sliver when startsUnderBars is turned on and off', (final tester) async {
      await _expectKeepsState(tester, <Widget>[scrollView(), scrollView(startsUnderBars: true)]);
    });

    testWidgets('a keyed sliver keeps its state as it moves off the first place of one that starts under '
        'the bars', (final tester) async {
      Widget moved({required final bool first}) {
        const Widget probe = SliverToBoxAdapter(key: ValueKey<String>('probe'), child: _Probe());
        const Widget other = SliverToBoxAdapter(key: ValueKey<String>('other'), child: SizedBox(height: 10));
        return _app(
          HarborFrame(
            top: const <HarborBar>[_header],
            body: HarborScrollView(
              startsUnderBars: true,
              slivers: first ? const <Widget>[probe, other] : const <Widget>[other, probe],
            ),
          ),
        );
      }

      await _expectKeepsState(tester, <Widget>[moved(first: true), moved(first: false)]);
    });

    testWidgets('HarborScrollView.box keeps its child when a bar comes and goes', (final tester) async {
      Widget box({required final bool bar}) => _app(
        HarborFrame(
          top: <HarborBar>[if (bar) _header],
          body: HarborScrollView.box(child: const _Probe()),
        ),
      );
      await _expectKeepsState(tester, <Widget>[box(bar: true), box(bar: false)]);
    });
  });

  group('HarborSliverClear', () {
    Widget sliverClear({final bool bar = true, final bool clearLeading = true, final bool clearsBars = true}) => _app(
      HarborFrame(
        top: <HarborBar>[if (bar) _header],
        body: CustomScrollView(
          slivers: <Widget>[
            HarborSliverClear(
              clearLeading: clearLeading,
              clearsBars: clearsBars,
              sliver: const SliverToBoxAdapter(child: _Probe()),
            ),
          ],
        ),
      ),
    );

    testWidgets('keeps its sliver when a bar comes and goes, and when its options change', (final tester) async {
      await _expectKeepsState(tester, <Widget>[
        sliverClear(),
        sliverClear(bar: false),
        sliverClear(clearLeading: false),
        sliverClear(clearsBars: false),
      ]);
    });
  });

  group('HarborSliverBar', () {
    // First in a scroll view with no bar above, a sliver bar takes the status bar; under a header it
    // does not.
    Widget sliverBar({required final bool bar}) => _app(
      HarborFrame(
        top: <HarborBar>[if (bar) _header],
        body: const HarborScrollView(
          slivers: <Widget>[
            HarborSliverBar(child: _Probe()),
            SliverToBoxAdapter(child: SizedBox(height: 2000)),
          ],
        ),
      ),
    );

    testWidgets('keeps its child when the bar above comes and goes', (final tester) async {
      await _expectKeepsState(tester, <Widget>[sliverBar(bar: false), sliverBar(bar: true)]);
    });
  });

  test('every widget that reports itself to the inspector is covered here', () {
    // The consumer types named where `HarborConsumerReport.wrap` is called, read from the source.
    final Set<String> reported = <String>{};
    for (final File file in Directory('lib/src').listSync().whereType<File>()) {
      final List<String> lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (!lines[i].contains('HarborConsumerReport.wrap(')) {
          continue;
        }
        final String call = lines.skip(i).take(3).join('\n');
        reported.addAll(RegExp(r"'(Harbor[A-Za-z.]*)'").allMatches(call).map((final Match m) => m[1]!));
      }
    }
    expect(
      reported,
      <String>{
        'HarborFrame',
        'HarborClear',
        'HarborClear.rowInsets',
        'HarborHandled',
        'HarborScrollView',
        'HarborSliverClear',
        'HarborSliverBar',
      },
      reason:
          'A widget that reports itself must keep the same shape whatever its inputs: add a group above '
          'that changes them and expects what is beneath it to stay mounted.',
    );
  });
}
