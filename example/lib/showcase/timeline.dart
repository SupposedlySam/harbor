import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// One chapter of the showcase: a harbor word, the plain word for it, and when it plays.
class ShowcaseChapter {
  const ShowcaseChapter({required this.term, required this.meaning, required this.start, required this.end});

  final String term;
  final String meaning;
  final double start;
  final double end;

  bool contains(final double t) => t >= start && t < end;

  /// How far through this chapter [t] is, 0 to 1.
  double progress(final double t) => ((t - start) / (end - start)).clamp(0.0, 1.0);
}

/// Everything the showcase shows, as a pure function of time in seconds.
///
/// Both halves read this and nothing else: the illustrated harbor on the left and the real
/// harbor on the phone on the right. So what the drawing does and what the app does cannot drift
/// apart, and a recording made frame by frame is the same every time it is made.
abstract final class ShowcaseTimeline {
  static const ShowcaseChapter intro = ShowcaseChapter(
    term: 'harbor',
    meaning: 'Every screen has something pushing in from its edges. harbor gives each one a place.',
    start: 0,
    end: 4,
  );
  static const ShowcaseChapter pier = ShowcaseChapter(
    term: 'Pier',
    meaning: 'A header your content scrolls under.',
    start: 4,
    end: 11,
  );
  static const ShowcaseChapter quay = ShowcaseChapter(
    term: 'Quay',
    meaning: 'A tab bar your content stops at.',
    start: 11,
    end: 17,
  );
  static const ShowcaseChapter tide = ShowcaseChapter(
    term: 'Tide',
    meaning: 'The keyboard. A dock on pilings stays put and is covered; a floating one rides up.',
    start: 17,
    end: 27,
  );
  static const ShowcaseChapter outro = ShowcaseChapter(
    term: 'flutter pub add harbor',
    meaning: 'Docks claim the edges. Everything else moors clear of them.',
    start: 27,
    end: 31,
  );

  static const List<ShowcaseChapter> chapters = <ShowcaseChapter>[intro, pier, quay, tide, outro];

  static double get duration => outro.end;

  static ShowcaseChapter chapterAt(final double t) =>
      chapters.firstWhere((final ShowcaseChapter c) => c.contains(t), orElse: () => outro);

  /// 0 to 1 across [a, b] seconds, eased.
  static double ease(final double t, final double a, final double b) =>
      Curves.easeInOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  /// The keyboard's height on the phone, in its logical pixels.
  static const double keyboardHeight = 336;

  static double keyboard(final double t) {
    final double up = ease(t, tide.start + 1.5, tide.start + 3.0);
    final double down = ease(t, tide.end - 2.0, tide.end - 0.5);
    return keyboardHeight * (up - down).clamp(0.0, 1.0);
  }

  /// How high the tide stands in the drawing, 0 (low water) to 1 (high water).
  static double water(final double t) => keyboard(t) / keyboardHeight;

  /// Whether the composer is out: it docks for the tide chapter, to show a dock that floats.
  static bool composerOut(final double t) => t >= tide.start + 0.5 && t < outro.start;

  /// How far down the list is scrolled, as a fraction of how far it can go.
  static double scroll(final double t) {
    final double underPier = ease(t, pier.start + 1.5, pier.end - 1.5) * 0.45;
    final double toQuay = ease(t, quay.start + 1.0, quay.end - 1.5) * 0.55;
    final double back = ease(t, outro.start + 0.5, outro.end - 0.5);
    return (underPier + toQuay) * (1 - back);
  }

  /// Boats crossing the drawing, by time: 0 to 1 along their course.
  static double boat(final double t, final double a, final double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// A gentle bob for anything afloat, the same on every recording.
  static double bob(final double t, {final double phase = 0}) => math.sin(t * 2.2 + phase) * 2.0;
}
