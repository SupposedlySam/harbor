import 'package:flutter/widgets.dart';

/// Where an entry sits in the field guide.
enum GuideGroup {
  frames('Frames', 'The harbor and the sea it sits in'),
  docks('Docks', 'What claims an edge, and how'),
  tide('The tide', 'The keyboard, and how docks meet it'),
  content('Content', 'How content keeps clear, sails under or ignores the docks'),
  talk('Talking to the harbor', 'Content asking the docks for room'),
  floating('Afloat', 'Buoys and flares in the clear water'),
  sheets('Sheets and dialogs', 'New ports that open over a page'),
  lighthouse('The lighthouse', 'Keeping things in sight'),
  platform('Coast and charts', 'Where insets come from, TV, and seeing it all');

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

  /// The class as you'd write it: `HarborDock.pier`.
  final String className;
  final GuideGroup group;

  /// The real-world thing, in a few words: "A wooden pier on piles".
  final String realWorld;

  /// A drawing of the real thing, used on the index and the entry's plate.
  final WidgetBuilder art;

  /// The entry's page.
  final WidgetBuilder page;
}
