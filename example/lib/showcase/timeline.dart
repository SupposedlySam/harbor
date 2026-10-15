import 'dart:math' as math;

import 'package:flutter/animation.dart';

import 'narration.dart';

/// One chapter of the showcase: what it is about, by its name in code, and when it plays.
class ShowcaseChapter {
  const ShowcaseChapter({
    required this.key,
    required this.term,
    required this.start,
    required this.end,
    this.code = true,
  });

  /// The chapter's name in narration.tsv.
  final String key;

  /// What the caption names the chapter: the API it shows, or a plain title.
  final String term;

  /// Whether [term] is code, set in code type, rather than a plain title.
  final bool code;
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

  /// Each chapter's name on screen, in the order narration.tsv plays them: the API it shows, as
  /// you would write it. The narration says what it does; the harbour is illustration at most.
  static const Map<String, String> _terms = <String, String>{
    'intro': 'harbor',
    'root': 'HarborRoot',
    'systemedges': 'HarborSystemEdges',
    'overlay': 'HarborBar.overlay',
    'solid': 'HarborBar.solid',
    'edgeeffect': 'HarborEdgeEffect.fade',
    'clear': 'HarborClear',
    'rowinsets': 'HarborClear.rowInsets',
    'scrollview': 'HarborScrollView',
    'sliverbar': 'HarborSliverBar',
    'sticky': 'HarborSticky',
    'room': 'HarborRoom.of(context)',
    'stances': 'HarborKeyboardStance',
    'reserves': 'HarborKeyboardStance.reserves',
    'hidebar': 'HarborHideBar',
    'attachedbar': 'HarborAttachedBar',
    'float': 'HarborFloat',
    'popover': 'HarborPopover',
    'toast': 'HarborToasts.show',
    'sheet': 'showHarborSheet',
    'coverspage': 'showHarborSheet(coversPage: true)',
    'dialog': 'showHarborDialog(inheritRoom: true)',
    'keepvisible': 'HarborKeepVisible',
    'inspector': 'HarborInspector',
    'trials': 'pumpHarborTrial',
    'outro': 'flutter pub add harbor',
  };

  /// Every chapter, in the order the narration plays them; each runs until the next one's
  /// camera starts to move.
  static final List<ShowcaseChapter> chapters = () {
    final List<String> keys = <String>[];
    for (final NarrationLine line in Narration.lines) {
      if (!keys.contains(line.chapter)) {
        keys.add(line.chapter);
      }
    }
    return <ShowcaseChapter>[
      for (int i = 0; i < keys.length; i++)
        ShowcaseChapter(
          key: keys[i],
          term: _terms[keys[i]] ?? keys[i],
          code: keys[i] != 'intro',
          start: i == 0 ? 0.0 : _startOf(keys[i]),
          end: i == keys.length - 1 ? Narration.end : _startOf(keys[i + 1]),
        ),
    ];
  }();

  /// The chapter named [key] in narration.tsv.
  static ShowcaseChapter of(final String key) => chapters.firstWhere(
    (final ShowcaseChapter c) => c.key == key,
    orElse: () => throw StateError('narration.tsv has no chapter "$key"'),
  );

  static final ShowcaseChapter intro = of('intro');
  static final ShowcaseChapter overlay = of('overlay');
  static final ShowcaseChapter solid = of('solid');
  static final ShowcaseChapter stances = of('stances');
  static final ShowcaseChapter outro = of('outro');

  /// The line of the narration on screen at [t]: the latest line of the current chapter that has
  /// started, or, in the moment before a chapter's first line, that first line. The caption shows
  /// exactly what the narrator says, so the video reads the same with the sound off.
  static String lineAt(final double t) {
    final List<NarrationLine> lines = Narration.of(chapterAt(t).key);
    if (lines.isEmpty) {
      return '';
    }
    NarrationLine shown = lines.first;
    for (final NarrationLine line in lines) {
      if (line.start <= t) {
        shown = line;
      }
    }
    return shown.text;
  }

  static double get duration => outro.end;

  static ShowcaseChapter chapterAt(final double t) =>
      chapters.firstWhere((final ShowcaseChapter c) => c.contains(t), orElse: () => outro);

  /// When [word] is spoken in [chapter], or [fallback] if the narration never says it.
  static double cue(final String chapter, final String word, final double fallback) =>
      Narration.when(chapter, word) ?? fallback;

  /// 0 to 1 across [a, b] seconds, eased.
  static double ease(final double t, final double a, final double b) =>
      Curves.easeInOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  /// The keyboard's height on the phone, in its logical pixels.
  static const double keyboardHeight = 336;

  /// The keyboard comes in as the stances' "comes in" is said and stays for the bar that reserves,
  /// which shows it going out and coming back; it rises again for the chapters that need it up.
  static double keyboard(final double t) {
    double up(final double at, [final double over = 0.7]) => ease(t, at, at + over);
    final ShowcaseChapter reserves = of('reserves');
    double level =
        up(cue('stances', 'comes', stances.start + 1.5), 1.5) -
        up(cue('reserves', 'out', reserves.start + 3)) +
        up(cue('reserves', 'comes', reserves.start + 4.5)) -
        up(reserves.end - 0.9);
    for (final (String chapter, String word) in const <(String, String)>[
      ('clear', 'form'),
      ('keepvisible', 'focused'),
      ('inspector', 'shows'),
      ('trials', 'phones'),
    ]) {
      final ShowcaseChapter c = of(chapter);
      final double rises = cue(chapter, word, c.start + 2);
      level += up(rises - 0.4, 1.0) - up(c.end - 0.9);
    }
    return keyboardHeight * level.clamp(0.0, 1.0);
  }

  /// How high the tide stands in the drawing, 0 (low water) to 1 (high water).
  static double water(final double t) => keyboard(t) / keyboardHeight;

  /// Whether the composer is out: it comes in for the stances, to show a bar that rides, and for
  /// the inspector, so the inspector has a bar that rides to draw.
  static bool composerOut(final double t) => t >= stances.start + 0.5 && t < stances.end || of('inspector').contains(t);

  /// How far down the list is scrolled, as a fraction of how far it can go: rows slide under the
  /// header as "beneath" is said, and come to rest at the tab bar on "rest".
  static double scroll(final double t) {
    final double under = cue('overlay', 'beneath', overlay.start + 1.5);
    final double underHeader = ease(t, under, under + 2.5) * 0.45;
    final double sets = cue('solid', 'tug', solid.start + 1.0);
    final double rests = cue('solid', 'rest', solid.end - 1.5);
    final double toTabBar = ease(t, sets, math.max(sets + 0.5, rests)) * 0.55;
    // The edge effect: the rows come back up under the header as it is described, and slide on
    // past it.
    final ShowcaseChapter effect = of('edgeeffect');
    final double backUp = ease(t, effect.start + 0.4, cue('edgeeffect', 'ripples', effect.start + 2.5)) * 0.35;
    final double onDown =
        ease(t, cue('edgeeffect', 'rows', effect.start + 5), cue('edgeeffect', 'rest', effect.end - 1)) * 0.35;
    final double back = ease(t, outro.start + 0.5, outro.end - 0.5);
    return (underHeader + toTabBar - backUp + onDown) * (1 - back);
  }

  /// The tug's passage to the quay wall in the drawing: it sets off on "tug" and is alongside by
  /// "wall".
  static (double, double) get tugPassage {
    final double sets = cue('solid', 'tug', solid.start + 0.4);
    return (sets, math.max(sets + 0.8, cue('solid', 'wall', solid.end - 1.6)));
  }

  /// Boats crossing the drawing, by time: 0 to 1 along their course.
  static double boat(final double t, final double a, final double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  /// A gentle bob for anything afloat, the same on every recording.
  static double bob(final double t, {final double phase = 0}) => math.sin(t * 2.2 + phase) * 2.0;
}
