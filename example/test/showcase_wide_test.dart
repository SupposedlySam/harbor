// The wide-format video's captions are claims about harbor too. These play it and measure the real
// harbor pages on its devices, so a caption that stops being true fails here first.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/showcase_wide/timeline.dart';
import 'package:harbor_example/showcase_wide/wide.dart';

void main() {
  Future<void> showAt(final WidgetTester tester, final double t) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = WideShowcase.frame;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WideShowcase(time: t)));
    await tester.pump();
  }

  Rect rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

  testWidgets('every chapter has a line, and each line is on screen while it is spoken', (final tester) async {
    expect(WideTimeline.chapters.map((final c) => c.key), containsAllInOrder(<String>['intro', 'rail', 'reading', 'landscape', 'hinge', 'tv', 'outro']));
    for (final line in WideTimeline.script.lines) {
      expect(WideTimeline.lineAt(line.start + 0.1), line.text);
    }
  });

  testWidgets('a rail docked at the start is on the left, and on the right once the page reads right to left', (final tester) async {
    await showAt(tester, WideTimeline.of('rail').start + 1);
    final Rect tablet = tester.getRect(find.byType(Harbor).first);
    final Rect left = rect(tester, 'rail');
    expect(left.left, closeTo(tablet.left, 1), reason: 'left to right, the start edge is the left');

    await showAt(tester, WideTimeline.cue('reading', 'right') + 0.5);
    final Rect right = rect(tester, 'rail');
    expect(right.right, closeTo(tester.getRect(find.byType(Harbor).first).right, 1), reason: 'right to left, the start edge is the right');
    expect(right.left, greaterThan(left.left + 100), reason: 'positive control: the rail moved');
  });

  testWidgets("the header's title keeps clear of the rail it sits beside", (final tester) async {
    await showAt(tester, WideTimeline.of('rail').start + 1);
    expect(tester.getRect(find.text('Harbor Master')).left, greaterThanOrEqualTo(rect(tester, 'rail').right));
  });
}
