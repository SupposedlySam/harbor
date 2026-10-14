import 'package:flutter/widgets.dart';

import '../art/palette.dart';
import '../field_guide/entry.dart';
import '../field_guide/field_guide.dart';
import 'narration.dart';
import 'timeline.dart';

/// The left half of the showcase for the chapters the panorama does not cover: the field
/// guide's drawing of the real thing, with the class it names beneath it.
///
/// The drawings are the field guide's own, so the video and the app's guide cannot disagree
/// about what a dock or a buoy looks like.
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
    'sea': <String>['frame-sea'],
    'coast': <String>['coast'],
    'wake': <String>['wake-painter'],
    'moored': <String>['content-moored'],
    'mooring': <String>['content-mooring-line'],
    'fairway': <String>['content-fairway'],
    'sliverdock': <String>['content-sliver-dock'],
    'sticky': <String>['content-sticky'],
    'openwater': <String>['content-open-water'],
    'drydock': <String>['tide-dry-dock'],
    'makeway': <String>['talk-make-way'],
    'pontoon': <String>['talk-pontoon'],
    'buoy': <String>['buoy', 'buoy-modal'],
    'portal': <String>['buoy-portal'],
    'signal': <String>['signals'],
    'sheet': <String>['sheet'],
    'breakwater': <String>['sheet-breakwater'],
    'dialog': <String>['dialog'],
    'lighthouse': <String>['lighthouse-reveal'],
    'chart': <String>['chart'],
    'trials': <String>['sea-trial'],
  };

  /// Whether [chapter] is told with a plate rather than the panorama.
  static bool shows(final ShowcaseChapter chapter) => phone.containsKey(chapter.key);

  /// What each plate says under its drawing, as the videos recorded it: the 0.8 class and the
  /// thing it was named after. The field guide's own entries took the 0.9 names, but the videos
  /// keep their words until they are re-voiced (#120, naming.md Q5), so the plates do too.
  static const Map<String, (String, String)> labels = <String, (String, String)>{
    'frame-harbor': ('Harbor', 'A bay sheltered by two breakwater arms, with a town on the shore'),
    'frame-sea': ('HarborSea', 'The open ocean, out to the horizon'),
    'frame-new-port': ('Harbor(newPort: true)', 'A second harbor town further up the coast, with its own quays'),
    'tide-dry-dock': (
      'HarborTideStance.dryDock',
      'A graving dry dock: a ship on keel blocks, the gate holding the sea out',
    ),
    'content-moored': ('HarborMoored', 'A boat moored alongside a quay, held off the wall by fenders'),
    'content-mooring-line': ('HarborMooringLine', 'Boats lined up along a quay, all tied to one mooring line'),
    'content-fairway': ('HarborFairway', 'A buoyed channel leading boats in from the sea'),
    'content-sliver-dock': ('HarborSliverDock', 'A landing stage on a gangway pinned to the quay'),
    'content-sticky': ('HarborSticky', 'Barnacles clinging to a hull'),
    'content-open-water': ('HarborOpenWater', 'A depth chart with its soundings'),
    'talk-make-way': ('HarborMakeWay', 'A small sailboat giving way to a ship in the channel'),
    'talk-pontoon': ('HarborPontoon', 'A floating pontoon tied to the quay'),
    'buoy': ('HarborBuoy', 'A red can buoy floating free in open water'),
    'buoy-modal': ('HarborBuoy(modal: true)', 'The harbor master’s launch, clearing other boats out of its way'),
    'buoy-portal': ('HarborPortalBuoy', 'A dan buoy thrown over the side, wherever the boat happens to be'),
    'signals': ('HarborFlares.raise', 'International signal flags run up a halyard'),
    'sheet': ('HarborSheet', 'A sail, trimmed by its sheet'),
    'sheet-breakwater': ('showHarborSheet(breakwater: true)', 'A rock breakwater sheltering the harbor from the swell'),
    'dialog': (
      'showHarborDialog(inheritClearWater:)',
      'The harbor master’s office window, where the radio call is taken',
    ),
    'lighthouse-reveal': ('HarborBeacon(keepInSight:)', 'A lighthouse sweeping its beam onto a boat'),
    'coast': ('HarborCoast', 'A rugged coastline of cliffs and a beach'),
    'coast-title-safe': ('HarborCoast.titleSafe', 'An old TV set with the broadcast title-safe frame marked'),
    'scale-model': ('HarborScaleModel', 'A ship in a bottle'),
    'edge': ('HarborEdge', 'A ship’s port and starboard running lights'),
    'chart': ('HarborChart', 'A nautical chart with a compass rose and soundings'),
    'sea-trial': ('pumpSeaTrial', 'A new ship on her sea trials, a tug alongside'),
    'wake-painter': ('HarborWakePainter', 'The V-shaped wake spreading behind a boat'),
  };

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
            _Label(id: ids[index]),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.id});

  final String id;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: 660,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ShowcasePlate.labels[id]!.$1,
          key: const ValueKey<String>('plate class'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Menlo', fontSize: 24, fontWeight: FontWeight.w700, color: Palette.brass),
        ),
        const SizedBox(height: 6),
        Text(
          ShowcasePlate.labels[id]!.$2,
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
