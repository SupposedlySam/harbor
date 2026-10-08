import 'narration.g.dart';

/// One spoken line of the showcase, placed on its timeline by `tool/narrate.py`.
class NarrationLine {
  const NarrationLine({required this.chapter, required this.text, required this.start, required this.duration, required this.words});

  final String chapter;
  final String text;

  /// Seconds into the showcase when the line starts, and how long it runs.
  final double start;
  final double duration;

  /// Each word as written in the script, timed from what Whisper heard.
  final List<NarrationWord> words;

  double get end => start + duration;
}

/// A word of a line and when it is spoken.
class NarrationWord {
  const NarrationWord(this.word, this.start, this.end);

  final String word;
  final double start;
  final double end;
}

/// The narration's timings, read by the timeline.
abstract final class Narration {
  static List<NarrationLine> get lines => narrationLines;

  static double get end => narrationEnd;

  static List<NarrationLine> of(final String chapter) =>
      narrationLines.where((final NarrationLine line) => line.chapter == chapter).toList();

  /// When [word] is first spoken in [chapter], or null if it never is.
  static double? when(final String chapter, final String word) {
    for (final NarrationLine line in of(chapter)) {
      for (final NarrationWord spoken in line.words) {
        if (spoken.word == word) {
          return spoken.start;
        }
      }
    }
    return null;
  }
}
