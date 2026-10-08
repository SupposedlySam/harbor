// Misuse is reported the way Flutter reports it: a FlutterError that says what went wrong and
// what to do about it, not a bare assert. These tests check the error's type and its hint, not
// its full wording.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _app(final Widget home) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: home),
);

/// The errors reported while [body] runs. A layout that throws goes on to fail its paint and its
/// parents' layout too, so the first is the one that says what went wrong.
Future<List<FlutterErrorDetails>> _errorsWhile(final Future<void> Function() body) async {
  final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  testWidgets('HarborController.of with no harbor above says to use maybeOf', (final tester) async {
    late BuildContext bare;
    await tester.pumpWidget(
      Builder(
        builder: (final BuildContext c) {
          bare = c;
          return const SizedBox();
        },
      ),
    );
    expect(
      () => HarborController.of(bare),
      throwsA(
        isA<FlutterError>()
            .having((final FlutterError e) => e.toStringDeep(), 'message', contains('HarborController.maybeOf'))
            .having((final FlutterError e) => e.toStringDeep(), 'message', contains('The context used was')),
      ),
    );
  });

  testWidgets('a harbor given unbounded height names itself and says to hug its body', (final tester) async {
    final List<FlutterErrorDetails> errors = await _errorsWhile(
      () => tester.pumpSeaTrial(
        _app(
          const SingleChildScrollView(
            child: Harbor(debugLabel: 'settings', body: SizedBox(height: 100)),
          ),
        ),
      ),
    );
    final Object error = errors.first.exception;
    expect(error, isA<FlutterError>());
    expect('$error', contains('settings'));
    expect('$error', contains('HarborSizing.hugBody'));
  });

  testWidgets('a quay listed inside a pier says to list it nearer the edge', (final tester) async {
    final List<FlutterErrorDetails> errors = await _errorsWhile(
      () => tester.pumpSeaTrial(
        _app(
          const Harbor(
            debugLabel: 'inbox',
            top: <HarborDock>[
              HarborDock.quay(child: SizedBox(height: 20)),
              HarborDock.pier(child: SizedBox(height: 20)),
              HarborDock.quay(child: SizedBox(height: 20)),
            ],
            body: SizedBox.expand(),
          ),
        ),
      ),
    );
    final Object error = errors.first.exception;
    expect(error, isA<FlutterError>());
    expect('$error', contains('inbox'));
    expect('$error', contains('nearer the top edge'));
  });

  testWidgets('dragToClose outside showHarborSheet says to open the sheet with it', (final tester) async {
    await tester.pumpSeaTrial(_app(const HarborSheet(dragToClose: true, body: SizedBox(height: 100))));
    final Object? error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect('$error', contains('showHarborSheet'));
    expect('$error', contains('dragToClose: false'));
  });

  group('Two anchor points sharing one anchor', () {
    Widget rows(final HarborAnchor anchor, final List<int> anchored) => _app(
      Harbor(
        body: Column(
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              if (anchored.contains(i))
                HarborAnchorPoint(key: ValueKey<int>(i), anchor: anchor, child: const SizedBox(height: 40))
              else
                SizedBox(key: ValueKey<int>(i), height: 40),
          ],
        ),
      ),
    );

    testWidgets('are reported after the frame, with the fix', (final tester) async {
      final HarborAnchor anchor = HarborAnchor(debugLabel: 'row menu');
      addTearDown(anchor.dispose);
      await tester.pumpSeaTrial(rows(anchor, <int>[0, 2]));
      final Object? error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('row menu'));
      expect('$error', contains('its own HarborAnchor'));
    });

    testWidgets('are not reported when the anchor moves from one point to another', (final tester) async {
      final HarborAnchor anchor = HarborAnchor(debugLabel: 'row menu');
      addTearDown(anchor.dispose);
      await tester.pumpSeaTrial(rows(anchor, <int>[0]));
      await tester.pumpWidget(rows(anchor, <int>[2]));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(anchor.box, isNotNull, reason: 'positive control: the anchor holds the point it moved to');
    });
  });
}
