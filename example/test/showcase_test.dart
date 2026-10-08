// The showcase's captions are claims about harbor. These tests play the showcase and measure the
// real harbor page on its phone, so a caption that stops being true fails here before it ships
// in a README video.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/field_guide/stage.dart';
import 'package:harbor_example/showcase/narration.dart';
import 'package:harbor_example/showcase/showcase.dart';
import 'package:harbor_example/showcase/timeline.dart';

void main() {
  late ValueNotifier<double> time;
  double now = 0;

  Future<void> start(final WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = HarborShowcase.frame;
    addTearDown(tester.view.reset);
    time = ValueNotifier<double>(0);
    addTearDown(time.dispose);
    now = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<double>(
          valueListenable: time,
          builder: (final BuildContext context, final double t, final Widget? _) => HarborShowcase(time: t),
        ),
      ),
    );
  }

  /// Plays forward to [t] a frame at a time, so harbor's own animations keep pace.
  Future<void> seek(final WidgetTester tester, final double t) async {
    while (now < t) {
      final double from = now;
      now = (now + 1 / 30).clamp(0, t);
      // Two pumps, never at one time: harbor's tide gauge takes a keyboard that holds still for a
      // frame as settled (see render_showcase_test.dart).
      time.value = (from + now) / 2;
      await tester.pump(const Duration(microseconds: 16667));
      time.value = now;
      await tester.pump(const Duration(microseconds: 16667));
    }
  }

  Rect header(final WidgetTester tester) => tester.getRect(find.byKey(const ValueKey<String>('showcase header')));
  Rect tabBar(final WidgetTester tester) => tester.getRect(find.byKey(const ValueKey<String>('showcase tab bar')));
  Rect composer(final WidgetTester tester) => tester.getRect(find.byKey(const ValueKey<String>('showcase composer')));
  Iterable<Rect> rows(final WidgetTester tester) => find.byType(HarborMooringLine).evaluate().map((final Element e) {
    // Transformed whole: the phone is drawn scaled, so a global origin plus a local size is wrong.
    final RenderBox box = e.renderObject! as RenderBox;
    return MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
  });

  testWidgets('Pier: rows scroll under the header, which stays put', (final tester) async {
    await start(tester);
    await seek(tester, ShowcaseTimeline.pier.start);
    final Rect before = header(tester);
    await seek(tester, ShowcaseTimeline.pier.end - 1);
    expect(header(tester), before);
    // The list's viewport runs up under a pier; under a quay it would start below it. Rows
    // overlapping the header prove nothing alone: the list lays out a cache above the screen.
    final Rect viewport = tester.getRect(find.byType(Scrollable).first);
    expect(viewport.top, lessThan(before.top), reason: 'the list runs under the header');
    expect(
      rows(tester).any((final Rect r) => r.top < before.bottom && r.bottom > before.top && r.bottom > viewport.top),
      isTrue,
      reason: 'and a row is under it',
    );
  });

  testWidgets('Quay: the list stops at the tab bar', (final tester) async {
    await start(tester);
    await seek(tester, ShowcaseTimeline.quay.end - 0.5);
    final Rect bar = tabBar(tester);
    // Rows starting past the tab bar's top are the list's cache: laid out, never painted.
    final double lowest = rows(tester)
        .where((final Rect r) => r.top < bar.top)
        .map((final Rect r) => r.bottom)
        .reduce((final double a, final double b) => a > b ? a : b);
    // The difference between a quay and a pier: the list's viewport ends at a quay, and runs on
    // under a pier. Where the last row comes to rest is the same for both, since a fairway rests
    // clear of a pier too, so that alone cannot tell them apart.
    expect(tester.getRect(find.byType(Scrollable).first).bottom, lessThanOrEqualTo(bar.top + 0.5), reason: 'nothing runs under the tab bar');
    expect(lowest, lessThanOrEqualTo(bar.top + 0.5));
    expect(lowest, greaterThan(bar.top - 20), reason: 'positive control: the last row has come to rest at it');
  });

  testWidgets('Tide: the tab bar on pilings stays put and is covered; the composer rides up', (final tester) async {
    await start(tester);
    await seek(tester, ShowcaseTimeline.tide.start + 1.2);
    final Rect dry = tabBar(tester);
    expect(ShowcaseTimeline.keyboard(now), 0, reason: 'positive control: the keyboard is still down');
    expect(composer(tester).bottom, lessThanOrEqualTo(dry.top + 0.5), reason: 'the composer rests on the tab bar');

    await seek(tester, ShowcaseTimeline.tide.start + 5);
    final Rect keyboard = tester.getRect(find.byType(KeyboardArt));
    expect(keyboard.height, greaterThan(100), reason: 'positive control: the keyboard is up');
    expect(tabBar(tester), dry, reason: 'on pilings: it does not move');
    expect(keyboard.overlaps(tabBar(tester)), isTrue, reason: 'and the keyboard covers it');
    expect(composer(tester).bottom, moreOrLessEquals(keyboard.top, epsilon: 0.5), reason: 'afloat: it sits on the keyboard');
  });

  // The caption is the narration, word for word, so the video reads the same with the sound off.
  // Breaks if: a caption drifts from what is said. (Whether a line FITS is checked by the recorder,
  // test/render_showcase_test.dart, which draws in the real fonts; this suite's test font is wider.)
  testWidgets('the caption shows each line as it is spoken', (final tester) async {
    await start(tester);
    expect(Narration.lines, isNotEmpty, reason: 'positive control: there is narration to check');
    for (final NarrationLine line in Narration.lines) {
      await seek(tester, line.start + 0.1);
      final Finder caption = find.byKey(const ValueKey<String>('caption line'));
      expect(tester.widget<Text>(caption).data, line.text);
    }
  });
}
