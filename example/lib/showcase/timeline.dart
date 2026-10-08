import 'dart:math' as math;

import 'package:flutter/animation.dart';

import 'narration.dart';

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
///
/// THE TIMES COME FROM THE NARRATION. `tool/narrate.py` voices each line, times every word, and
/// writes `narration.g.dart`; each chapter runs as long as its lines, and the moments that matter
/// land on the words that name them (the keyboard rises as "comes in" is said). Reword a line,
/// re-run the tool, and the picture follows the voice.
abstract final class ShowcaseTimeline {
  /// Silence before a chapter's first line, during which the camera arrives.
  static const double _lead = 0.6;

  static double _startOf(final String chapter) {
    final List<NarrationLine> lines = Narration.of(chapter);
    return lines.isEmpty ? 0.0 : math.max(0.0, lines.first.start - _lead);
  }

  static ShowcaseChapter _chapter(final String key, final String next, {required final String term, required final String meaning}) =>
      ShowcaseChapter(term: term, meaning: meaning, start: key == 'intro' ? 0.0 : _startOf(key), end: next.isEmpty ? Narration.end : _startOf(next));

  static final ShowcaseChapter intro = _chapter(
    'intro',
    'pier',
    term: 'harbor',
    meaning: 'Every screen has something pushing in from its edges. harbor gives each one a place.',
  );
  static final ShowcaseChapter pier = _chapter('pier', 'quay', term: 'Pier', meaning: 'A header your content scrolls under.');
  static final ShowcaseChapter quay = _chapter('quay', 'tide', term: 'Quay', meaning: 'A tab bar your content stops at.');
  static final ShowcaseChapter tide = _chapter(
    'tide',
    'outro',
    term: 'Tide',
    meaning: 'The keyboard. A dock on pilings stays put and is covered; a floating one rides up.',
  );
  static final ShowcaseChapter outro = _chapter(
    'outro',
    '',
    term: 'flutter pub add harbor',
    meaning: 'Docks claim the edges. Everything else moors clear of them.',
  );

  static List<ShowcaseChapter> get chapters => <ShowcaseChapter>[intro, pier, quay, tide, outro];

  static double get duration => outro.end;

  static ShowcaseChapter chapterAt(final double t) =>
      chapters.firstWhere((final ShowcaseChapter c) => c.contains(t), orElse: () => outro);

  /// When [word] is spoken in [chapter], or [fallback] if the narration never says it.
  static double cue(final String chapter, final String word, final double fallback) => Narration.when(chapter, word) ?? fallback;

  /// 0 to 1 across [a, b] seconds, eased.
  static double ease(final double t, final double a, final double b) =>
      Curves.easeInOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  /// The keyboard's height on the phone, in its logical pixels.
  static const double keyboardHeight = 336;

  /// The keyboard comes in as "comes in" is said, and goes out before the outro.
  static double keyboard(final double t) {
    final double rises = cue('tide', 'comes', tide.start + 1.5);
    final double up = ease(t, rises, rises + 1.5);
    final double down = ease(t, tide.end - 1.6, tide.end - 0.2);
    return keyboardHeight * (up - down).clamp(0.0, 1.0);
  }

  /// How high the tide stands in the drawing, 0 (low water) to 1 (high water).
  static double water(final double t) => keyboard(t) / keyboardHeight;

  /// Whether the composer is out: it docks for the tide chapter, to show a dock that floats.
  static bool composerOut(final double t) => t >= tide.start + 0.5 && t < outro.start;

  /// How far down the list is scrolled, as a fraction of how far it can go: rows slide under the
  /// header as "beneath" is said, and come to rest at the tab bar on "rest".
  static double scroll(final double t) {
    final double under = cue('pier', 'beneath', pier.start + 1.5);
    final double underPier = ease(t, under, under + 2.5) * 0.45;
    final double sets = cue('quay', 'tug', quay.start + 1.0);
    final double rests = cue('quay', 'rest', quay.end - 1.5);
    final double toQuay = ease(t, sets, math.max(sets + 0.5, rests)) * 0.55;
    final double back = ease(t, outro.start + 0.5, outro.end - 0.5);
    return (underPier + toQuay) * (1 - back);
  }

  /// The tug's passage to the quay wall: it sets off on "tug" and is alongside by "wall".
  static (double, double) get tugPassage {
    final double sets = cue('quay', 'tug', quay.start + 0.4);
    return (sets, math.max(sets + 0.8, cue('quay', 'wall', quay.end - 1.6)));
  }

  /// Boats crossing the drawing, by time: 0 to 1 along their course.
  static double boat(final double t, final double a, final double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// A gentle bob for anything afloat, the same on every recording.
  static double bob(final double t, {final double phase = 0}) => math.sin(t * 2.2 + phase) * 2.0;
}
