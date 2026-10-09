// The fleet seen from outside a harbor: observers that hear harbors join and leave (#64), and the
// chart of every live sea that tooling reads with no context.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

/// Records each event with the scheduler phase it arrived in, and whether the harbor had a chart
/// entry (had laid out) by then.
class _Log extends HarborFleetObserver {
  final List<String> events = <String>[];
  final List<SchedulerPhase> phases = <SchedulerPhase>[];
  final List<bool> laidOut = <bool>[];

  @override
  void didJoin(final HarborController harbor) {
    events.add('join ${harbor.debugLabel}');
    phases.add(SchedulerBinding.instance.schedulerPhase);
    laidOut.add(HarborChart.snapshotOf(harbor.fleet).any((final HarborChartEntry e) => e.label == harbor.debugLabel));
  }

  @override
  void didLeave(final HarborController harbor) {
    events.add('leave ${harbor.debugLabel}');
    phases.add(SchedulerBinding.instance.schedulerPhase);
  }
}

Widget _sea({required final Widget child, final List<HarborFleetObserver> observers = const <HarborFleetObserver>[]}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: HarborSea(observers: observers, child: child),
      ),
    );

Widget _page(final String label, {final Widget? body}) => Harbor(
  debugLabel: label,
  top: const <HarborDock>[HarborDock.quay(child: SizedBox(height: 40))],
  body: body ?? const SizedBox.expand(),
);

void main() {
  group('HarborFleetObserver', () {
    testWidgets('hears the sea and its pages join, after the frame they were built in', (final tester) async {
      final _Log log = _Log();
      await tester.pumpWidget(_sea(observers: <HarborFleetObserver>[log], child: _page('inbox')));

      expect(log.events, <String>['join sea', 'join inbox']);
      expect(log.phases, everyElement(SchedulerPhase.postFrameCallbacks));
      // Delivered once the harbors have laid out, so a chart can read them.
      expect(log.laidOut, <bool>[true, true]);
    });

    testWidgets('hears a page leave, and nothing more once the page has gone', (final tester) async {
      final _Log log = _Log();
      await tester.pumpWidget(_sea(observers: <HarborFleetObserver>[log], child: _page('inbox')));
      log.events.clear();
      log.phases.clear();

      await tester.pumpWidget(_sea(observers: <HarborFleetObserver>[log], child: const SizedBox.expand()));
      expect(log.events, <String>['leave inbox']);
      expect(log.phases, <SchedulerPhase>[SchedulerPhase.postFrameCallbacks]);

      await tester.pump();
      expect(log.events, <String>['leave inbox']);
    });

    testWidgets('hears the sea itself leave when the app goes', (final tester) async {
      final _Log log = _Log();
      await tester.pumpWidget(_sea(observers: <HarborFleetObserver>[log], child: _page('inbox')));
      log.events.clear();

      await tester.pumpWidget(const SizedBox.shrink());
      expect(log.events, unorderedEquals(<String>['leave inbox', 'leave sea']));
    });

    testWidgets('is added and removed on a fleet reached through Harbor.of', (final tester) async {
      final _Log log = _Log();
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        _sea(
          child: _page('inbox', body: SizedBox(key: anchor)),
        ),
      );
      final HarborFleet fleet = Harbor.of(anchor.currentContext!).fleet;

      fleet.addObserver(log);
      await tester.pumpWidget(
        _sea(
          child: _page(
            'inbox',
            body: SizedBox(key: anchor, child: _page('detail')),
          ),
        ),
      );
      expect(log.events, <String>['join detail']);

      fleet.removeObserver(log);
      await tester.pumpWidget(
        _sea(
          child: _page('inbox', body: SizedBox(key: anchor)),
        ),
      );
      expect(log.events, <String>['join detail']);
    });

    testWidgets('moves with the sea when its list of observers changes', (final tester) async {
      final _Log first = _Log();
      final _Log second = _Log();
      await tester.pumpWidget(_sea(observers: <HarborFleetObserver>[first], child: _page('inbox')));
      await tester.pumpWidget(_sea(observers: <HarborFleetObserver>[second], child: const SizedBox.expand()));

      expect(first.events, <String>['join sea', 'join inbox']);
      expect(second.events, <String>['leave inbox']);
    });
  });

  group('HarborChart.snapshotAll', () {
    testWidgets('reads every live sea with no context, and forgets one once it is disposed', (final tester) async {
      expect(HarborChart.snapshotAll(), isEmpty);
      await tester.pumpWidget(_sea(child: _page('inbox')));

      final List<HarborChartEntry> chart = HarborChart.snapshotAll();
      expect(chart.map((final HarborChartEntry e) => e.label), <String>['sea', 'inbox']);
      expect(chart.map((final HarborChartEntry e) => e.isolated), everyElement(isFalse));
      expect(chart.last.docks.single.rect, const Rect.fromLTWH(0, 0, 800, 40));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(HarborChart.snapshotAll(), isEmpty);
    });

    testWidgets('lists a sea inside a page after the app, labelled isolated', (final tester) async {
      await tester.pumpWidget(
        _sea(
          child: _page(
            'field guide',
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 200, height: 300, child: HarborSea(child: _page('phone'))),
            ),
          ),
        ),
      );

      final List<HarborChartEntry> chart = HarborChart.snapshotAll();
      expect(
        <(String, bool, int)>[for (final HarborChartEntry e in chart) (e.label, e.isolated, e.depth)],
        <(String, bool, int)>[('sea', false, 0), ('field guide', false, 1), ('sea', true, 0), ('phone', true, 1)],
      );
      // In global coordinates, as every entry is: the phone sits below the page's 40 header.
      expect(chart.last.frame, const Rect.fromLTWH(0, 40, 200, 300));
      expect(chart.last.toJson()['isolated'], isTrue);
    });

    testWidgets('lists a sea charted by an overlay above it once', (final tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: HarborChartOverlay(enabled: false, child: HarborSea(child: _page('inbox'))),
          ),
        ),
      );
      expect(HarborChart.snapshotAll().map((final HarborChartEntry e) => e.label), <String>['sea', 'inbox']);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(HarborChart.snapshotAll(), isEmpty);
    });
  });
}
