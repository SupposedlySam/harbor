import 'package:flutter/widgets.dart';

import '../art/palette.dart';
import '../field_guide/entry.dart';
import '../field_guide/field_guide.dart';
import 'narration.dart';
import 'timeline.dart';

/// The left half of the showcase for the chapters the panorama does not cover: the field
/// guide's drawing that illustrates the class, with the class and the drawing's caption beneath
/// it.
///
/// The drawings and their labels are the field guide's own, so the video and the app's guide
/// cannot disagree about what a class is called or what illustrates it.
class ShowcasePlate extends StatelessWidget {
  const ShowcasePlate({
    super.key,
    required this.chapter,
    required this.time,
    this.script = Narration.script,
    this.entries = ShowcasePlate.phone,
  });

  final ShowcaseChapter chapter;
  final double time;

  /// The narration the chapter's lines come from: the phone tour's unless given.
  final NarrationScript script;

  /// The field guide entries each chapter shows, one per line of its narration; the last stays
  /// up for any further lines.
  final Map<String, List<String>> entries;

  /// The phone tour's plates.
  static const Map<String, List<String>> phone = <String, List<String>>{
    'root': <String>['frame-sea'],
    'systemedges': <String>['coast'],
    'edgeeffect': <String>['wake-painter'],
    'clear': <String>['content-moored'],
    'rowinsets': <String>['content-mooring-line'],
    'scrollview': <String>['content-fairway'],
    'sliverbar': <String>['content-sliver-dock'],
    'sticky': <String>['content-sticky'],
    'room': <String>['content-open-water'],
    'reserves': <String>['tide-dry-dock'],
    'hidebar': <String>['talk-make-way'],
    'attachedbar': <String>['talk-pontoon'],
    'float': <String>['buoy', 'buoy-modal'],
    'popover': <String>['buoy-portal'],
    'toast': <String>['signals'],
    'sheet': <String>['sheet'],
    'coverspage': <String>['sheet-breakwater'],
    'dialog': <String>['dialog'],
    'keepvisible': <String>['lighthouse-reveal'],
    'inspector': <String>['chart'],
    'trials': <String>['sea-trial'],
  };

  /// Whether [chapter] is told with a plate rather than the panorama.
  static bool shows(final ShowcaseChapter chapter) => phone.containsKey(chapter.key);

  static GuideEntry _entry(final String id) => fieldGuideEntries.firstWhere(
    (final GuideEntry e) => e.id == id,
    orElse: () => throw StateError('the field guide has no entry "$id"'),
  );

  /// Which of the chapter's entries is up at [t], and when it came up.
  (int, double) _at(final ShowcaseChapter chapter, final double t) {
    final List<NarrationLine> lines = script.of(chapter.key);
    final int last = entries[chapter.key]!.length - 1;
    int index = 0;
    double since = chapter.start;
    for (int i = 1; i < lines.length && i <= last; i++) {
      if (lines[i].start <= t) {
        index = i;
        since = lines[i].start;
      }
    }
    return (index, since);
  }

  @override
  Widget build(final BuildContext context) {
    final List<String> ids = entries[chapter.key]!;
    final (int index, double since) = _at(chapter, time);
    // A slow push in across the chapter, so the drawing is never quite still.
    final double zoom = 1.0 + 0.06 * chapter.progress(time);
    final double fade = ShowcaseTimeline.ease(time, since, since + 0.4);
    return ColoredBox(
      color: Palette.night,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 660,
              height: 440,
              decoration: BoxDecoration(
                color: Palette.sail,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Palette.brass.withValues(alpha: 0.7), width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Transform.scale(
                scale: zoom,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (index > 0 && fade < 1) _entry(ids[index - 1]).art(context),
                    Opacity(opacity: index > 0 ? fade : 1, child: _entry(ids[index]).art(context)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _Label(entry: _entry(ids[index])),
          ],
        ),
      ),
    );
  }
}

/// The entry's class, as you would write it, and its drawing captioned as an illustration.
class _Label extends StatelessWidget {
  const _Label({required this.entry});

  final GuideEntry entry;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: 660,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          entry.className,
          key: const ValueKey<String>('plate class'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Menlo', fontSize: 24, fontWeight: FontWeight.w700, color: Palette.brass),
        ),
        const SizedBox(height: 6),
        Text(
          entry.realWorld,
          maxLines: 2,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 19,
            fontStyle: FontStyle.italic,
            color: Palette.foam.withValues(alpha: 0.85),
          ),
        ),
      ],
    ),
  );
}
