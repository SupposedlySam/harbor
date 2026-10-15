// The frame registry seen from outside a frame: observers that hear frames join and leave (#64), and
// the inspector's view of every live root that tooling reads with no context.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

/// Records each event with the scheduler phase it arrived in, and whether the frame had an inspector
/// entry (had laid out) by then.
class _Log extends HarborFrameObserver {
  final List<String> events = <String>[];
  final List<SchedulerPhase> phases = <SchedulerPhase>[];
  final List<bool> laidOut = <bool>[];

  @override
  void didJoin(final HarborController frame) {
    events.add('join ${frame.debugLabel}');
    phases.add(SchedulerBinding.instance.schedulerPhase);
    laidOut.add(
      HarborInspector.snapshotOf(frame.registry).any((final HarborInspectorEntry e) => e.label == frame.debugLabel),
    );
  }

  @override
  void didLeave(final HarborController frame) {
    events.add('leave ${frame.debugLabel}');
    phases.add(SchedulerBinding.instance.schedulerPhase);
  }
}

Widget _root({
  required final Widget child,
  final List<HarborFrameObserver> observers = const <HarborFrameObserver>[],
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(800, 600)),
    child: HarborRoot(observers: observers, child: child),
  ),
);

Widget _page(final String label, {final Widget? body}) => HarborFrame(
  debugLabel: label,
  top: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 40))],
  body: body ?? const SizedBox.expand(),
);

void main() {
  group('HarborFrameObserver', () {
    testWidgets('hears the root and its pages join, after the frame they were built in', (final tester) async {
      final _Log log = _Log();
      await tester.pumpWidget(_root(observers: <HarborFrameObserver>[log], child: _page('inbox')));

      expect(log.events, <String>['join sea', 'join inbox']);
      expect(log.phases, everyElement(SchedulerPhase.postFrameCallbacks));
      // Delivered once the frames have laid out, so an inspector can read them.
      expect(log.laidOut, <bool>[true, true]);
    });

    testWidgets('hears a page leave, and nothing more once the page has gone', (final tester) async {
      final _Log log = _Log();
      await tester.pumpWidget(_root(observers: <HarborFrameObserver>[log], child: _page('inbox')));
      log.events.clear();
      log.phases.clear();

      await tester.pumpWidget(_root(observers: <HarborFrameObserver>[log], child: const SizedBox.expand()));
      expect(log.events, <String>['leave inbox']);
      expect(log.phases, <SchedulerPhase>[SchedulerPhase.postFrameCallbacks]);

      await tester.pump();
      expect(log.events, <String>['leave inbox']);
    });

    testWidgets('hears the root itself leave when the app goes', (final tester) async {
      final _Log log = _Log();
      await tester.pumpWidget(_root(observers: <HarborFrameObserver>[log], child: _page('inbox')));
      log.events.clear();

      await tester.pumpWidget(const SizedBox.shrink());
      expect(log.events, unorderedEquals(<String>['leave inbox', 'leave sea']));
    });

    testWidgets('is added and removed on a frame registry reached through HarborFrame.of', (final tester) async {
      final _Log log = _Log();
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        _root(
          child: _page('inbox', body: SizedBox(key: anchor)),
        ),
      );
      final HarborFrameRegistry registry = HarborFrame.of(anchor.currentContext!).registry;

      registry.addObserver(log);
      await tester.pumpWidget(
        _root(
          child: _page(
            'inbox',
            body: SizedBox(key: anchor, child: _page('detail')),
          ),
        ),
      );
      expect(log.events, <String>['join detail']);

      registry.removeObserver(log);
      await tester.pumpWidget(
        _root(
          child: _page('inbox', body: SizedBox(key: anchor)),
        ),
      );
      expect(log.events, <String>['join detail']);
    });

    testWidgets('moves with the root when its list of observers changes', (final tester) async {
      final _Log first = _Log();
      final _Log second = _Log();
      await tester.pumpWidget(_root(observers: <HarborFrameObserver>[first], child: _page('inbox')));
      await tester.pumpWidget(_root(observers: <HarborFrameObserver>[second], child: const SizedBox.expand()));

      expect(first.events, <String>['join sea', 'join inbox']);
      expect(second.events, <String>['leave inbox']);
    });
  });

  group('HarborInspector.snapshotAll', () {
    testWidgets('reads every live root with no context, and forgets one once it is disposed', (final tester) async {
      expect(HarborInspector.snapshotAll(), isEmpty);
      await tester.pumpWidget(_root(child: _page('inbox')));

      final List<HarborInspectorEntry> entries = HarborInspector.snapshotAll();
      expect(entries.map((final HarborInspectorEntry e) => e.label), <String>['sea', 'inbox']);
      expect(entries.map((final HarborInspectorEntry e) => e.isolated), everyElement(isFalse));
      expect(entries.last.bars.single.rect, const Rect.fromLTWH(0, 0, 800, 40));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(HarborInspector.snapshotAll(), isEmpty);
    });

    testWidgets('lists a root inside a page after the app, labelled isolated', (final tester) async {
      await tester.pumpWidget(
        _root(
          child: _page(
            'field guide',
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 200, height: 300, child: HarborRoot(child: _page('phone'))),
            ),
          ),
        ),
      );

      final List<HarborInspectorEntry> entries = HarborInspector.snapshotAll();
      expect(
        <(String, bool, int)>[for (final HarborInspectorEntry e in entries) (e.label, e.isolated, e.depth)],
        <(String, bool, int)>[('sea', false, 0), ('field guide', false, 1), ('sea', true, 0), ('phone', true, 1)],
      );
      // In global coordinates, as every entry is: the phone sits below the page's 40 header.
      expect(entries.last.frame, const Rect.fromLTWH(0, 40, 200, 300));
      expect(entries.last.toJson()['isolated'], isTrue);
    });

    testWidgets('lists a root inspected by an overlay above it once', (final tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: HarborInspectorOverlay(enabled: false, child: HarborRoot(child: _page('inbox'))),
          ),
        ),
      );
      expect(HarborInspector.snapshotAll().map((final HarborInspectorEntry e) => e.label), <String>['sea', 'inbox']);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(HarborInspector.snapshotAll(), isEmpty);
    });
  });
}
