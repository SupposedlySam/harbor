import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Which hinges and folds across a foldable's screen harbor keeps things off: a sheet or dialog
/// opens on one side of them, and a flare or buoy keeps to the side that holds it. Modelled on
/// Material 3's `HingePolicy`.
///
/// Set the app's default on `HarborSea(hinge:)`, a page's on `Harbor(hinge:)`, and one overlay's
/// on `showHarborSheet(hinge:)`, `showHarborDialog(hinge:)`, `HarborFlares.raise(hinge:)` or
/// `HarborBuoy(hinge:)`. The nearest wins. It is a policy, not a change to the screen:
/// `MediaQuery.displayFeatures` is left as the platform reports it for everything else, so a
/// two-pane layout or a video player beneath still sees the hinge.
enum HarborHinge {
  /// Keeps off what separates the screen: a hinge with width (the gap between a dual-screen
  /// device's two screens), and a fold that is half open (a laptop or a book). A flat fold has no
  /// width and content runs across it. The default, and what Flutter's `DisplayFeatureSubScreen`
  /// and Android's `FoldingFeature.isSeparating` call separating.
  avoidSeparating,

  /// Keeps off only what hides content: a hinge with width. A half-open fold is still one
  /// screen to draw on, so content runs across it.
  avoidOccluding,

  /// Keeps off every hinge and fold, a flat fold too: the two halves of a foldable's inner
  /// screen are always treated as two screens.
  always,

  /// Keeps off nothing: the inner screen is one wide, unbroken screen, and sheets, dialogs,
  /// flares and buoys run across the crease. Use it for an extended canvas, a map or a drawing.
  never;

  /// The policy at [context]: the nearest `Harbor(hinge:)` or `HarborSea(hinge:)` above it, or
  /// [avoidSeparating] with neither.
  static HarborHinge of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarborHingeScope>()?.hinge ?? HarborHinge.avoidSeparating;

  /// The hinges and folds in [features] this policy keeps off, each reported so that
  /// `DisplayFeatureSubScreen` splits the screen at it: a flat fold kept off by [always] is
  /// reported half open, since that widget lets content run across a flat fold of no width.
  List<DisplayFeature> keptOff(final Iterable<DisplayFeature> features) => <DisplayFeature>[
    for (final DisplayFeature feature in features)
      if ((feature.type == DisplayFeatureType.hinge || feature.type == DisplayFeatureType.fold) && _keepsOff(feature))
        if (feature.bounds.shortestSide > 0 || feature.state == DisplayFeatureState.postureHalfOpened)
          feature
        else
          DisplayFeature(bounds: feature.bounds, type: feature.type, state: DisplayFeatureState.postureHalfOpened),
  ];

  bool _keepsOff(final DisplayFeature feature) => switch (this) {
    HarborHinge.avoidSeparating => feature.bounds.shortestSide > 0 || feature.state == DisplayFeatureState.postureHalfOpened,
    HarborHinge.avoidOccluding => feature.type == DisplayFeatureType.hinge && feature.bounds.shortestSide > 0,
    HarborHinge.always => true,
    HarborHinge.never => false,
  };

  /// [mediaQuery] with its display features cut down to the ones this policy keeps off, for a
  /// `DisplayFeatureSubScreen` to choose a side of the screen by.
  MediaQueryData splitting(final MediaQueryData mediaQuery) => mediaQuery.copyWith(displayFeatures: keptOff(mediaQuery.displayFeatures));
}

/// Hands a [HarborHinge] to everything beneath, read with [HarborHinge.of].
@internal
class HarborHingeScope extends InheritedWidget {
  const HarborHingeScope({super.key, required this.hinge, required super.child});

  final HarborHinge hinge;

  @override
  bool updateShouldNotify(final HarborHingeScope oldWidget) => hinge != oldWidget.hinge;
}
