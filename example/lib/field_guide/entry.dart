import 'package:flutter/widgets.dart';

/// Where an entry sits in the field guide.
enum GuideGroup {
  frames('Frames', 'The frame and the root it sits in'),
  docks('Bars', 'What claims an edge, and how'),
  tide('The keyboard', 'The keyboard, and how bars meet it'),
  content('Content', 'How content keeps clear of the bars, runs under them or ignores them'),
  talk('Talking to the frame', 'Content asking the bars for room'),
  floating('Floats, popovers and toasts', 'What floats in the room'),
  sheets('Sheets and dialogs', 'Pages that open over a page'),
  lighthouse('Keeping in sight', 'Bringing covered content back into view'),
  folds('Folds and hinges', 'Dual screens and foldables: what keeps off the crease'),
  platform('System edges and the inspector', 'Where insets come from, TV, and seeing it all');

  const GuideGroup(this.title, this.blurb);

  final String title;
  final String blurb;
}

/// One class in the field guide.
@immutable
class GuideEntry {
  const GuideEntry({
    required this.id,
    required this.className,
    required this.group,
    required this.realWorld,
    required this.art,
    required this.page,
  });

  /// A stable key for finding the entry: `dock-pier`.
  final String id;

  /// The class as you'd write it: `HarborBar.overlay`.
  final String className;
  final GuideGroup group;

  /// What the drawing shows, captioned as an illustration rather than the meaning, in a few
  /// words: "Like a pier on piles: the body runs under it".
  final String realWorld;

  /// A harbour drawing that illustrates the class, used on the index and the entry's plate.
  final WidgetBuilder art;

  /// The entry's page.
  final WidgetBuilder page;
}
