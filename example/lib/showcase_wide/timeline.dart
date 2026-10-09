import '../showcase/narration.dart';
import '../showcase/timeline.dart';
import 'narration.g.dart' as wide;

/// The wide-format video as a pure function of time, as [ShowcaseTimeline] is for the phone tour:
/// chapters from its own narration, each running until the next one's camera starts to move.
abstract final class WideTimeline {
  static const NarrationScript script = NarrationScript(wide.narrationLines, wide.narrationEnd);

  /// Silence before a chapter's first line.
  static const double _lead = 0.6;

  static const Map<String, String> _terms = <String, String>{
    'intro': 'Wide screens',
    'rail': 'A start dock',
    'reading': 'Reading order',
    'landscape': 'Landscape',
    'hinge': 'The hinge',
    'tv': 'The coast on a TV',
    'outro': 'flutter pub add harbor',
  };

  static final List<ShowcaseChapter> chapters = () {
    final List<String> keys = script.chapters;
    double startOf(final String key) {
      final List<NarrationLine> lines = script.of(key);
      return lines.isEmpty ? 0.0 : (lines.first.start - _lead).clamp(0.0, double.infinity);
    }

    return <ShowcaseChapter>[
      for (int i = 0; i < keys.length; i++)
        ShowcaseChapter(
          key: keys[i],
          term: _terms[keys[i]] ?? keys[i],
          start: i == 0 ? 0.0 : startOf(keys[i]),
          end: i == keys.length - 1 ? script.end : startOf(keys[i + 1]),
        ),
    ];
  }();

  static ShowcaseChapter of(final String key) => chapters.firstWhere(
    (final ShowcaseChapter c) => c.key == key,
    orElse: () => throw StateError('the wide narration has no chapter "$key"'),
  );

  static double get duration => script.end;

  static ShowcaseChapter chapterAt(final double t) =>
      chapters.firstWhere((final ShowcaseChapter c) => c.contains(t), orElse: () => chapters.last);

  static String lineAt(final double t) => script.lineAt(chapterAt(t).key, t);

  /// When [word] is said in [chapter], or [after] seconds into it if it never is.
  static double cue(final String chapter, final String word, [final double after = 1.5]) =>
      script.when(chapter, word) ?? of(chapter).start + after;

  static double ease(final double t, final double a, final double b) => ShowcaseTimeline.ease(t, a, b);
}
