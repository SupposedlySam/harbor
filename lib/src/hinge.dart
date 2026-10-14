import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Which hinges and folds across a foldable's screen harbor keeps things off: a sheet or dialog
/// opens on one side of them, and a toast or float keeps to the side that holds it. Modelled on
/// Material 3's `HingePolicy`.
///
/// Set the app's default on `HarborRoot(hinge:)`, a page's on `HarborFrame(hinge:)`, and one overlay's
/// on `showHarborSheet(hinge:)`, `showHarborDialog(hinge:)`, `HarborToasts.show(hinge:)` or
/// `HarborFloat(hinge:)`. The nearest wins. It is a policy, not a change to the screen:
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
  /// toasts and floats run across the crease. Use it for an extended canvas, a map or a drawing.
  never;

  /// The policy at [context]: the nearest `HarborFrame(hinge:)` or `HarborRoot(hinge:)` above it, or
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
    HarborHinge.avoidSeparating =>
      feature.bounds.shortestSide > 0 || feature.state == DisplayFeatureState.postureHalfOpened,
    HarborHinge.avoidOccluding => feature.type == DisplayFeatureType.hinge && feature.bounds.shortestSide > 0,
    HarborHinge.always => true,
    HarborHinge.never => false,
  };

  /// [mediaQuery] with its display features cut down to the ones this policy keeps off, for a
  /// `DisplayFeatureSubScreen` to choose a side of the screen by.
  MediaQueryData splitting(final MediaQueryData mediaQuery) =>
      mediaQuery.copyWith(displayFeatures: keptOff(mediaQuery.displayFeatures));
}

/// How a foldable is held, from its fold: open flat, half open on a table, or half open like a
/// book. Android's tabletop and book postures, read from `MediaQuery.displayFeatures`.
enum HarborPosture {
  /// Open flat, or with no fold: one screen to lay out, the hinge policy aside.
  flat,

  /// Half open with the fold across the screen, the lower half on a table: content above the
  /// fold, controls below it, as Android's guidance has a video above its playback controls.
  /// A [HarborPanes] puts its start pane above the fold and its end pane below.
  tabletop,

  /// Half open with the fold down the middle, held like a book: two pages, one either side.
  book;

  /// The posture at [context], from the half-open fold or hinge in its `MediaQuery`, if any.
  static HarborPosture of(final BuildContext context) => from(MediaQuery.displayFeaturesOf(context));

  /// The posture [features] describe.
  static HarborPosture from(final Iterable<DisplayFeature> features) {
    for (final DisplayFeature feature in features) {
      if ((feature.type == DisplayFeatureType.fold || feature.type == DisplayFeatureType.hinge) &&
          feature.state == DisplayFeatureState.postureHalfOpened) {
        // A fold has no width, so its long side says which way it runs.
        return feature.bounds.width >= feature.bounds.height ? HarborPosture.tabletop : HarborPosture.book;
      }
    }
    return HarborPosture.flat;
  }
}

/// Hands a [HarborHinge] to everything beneath, read with [HarborHinge.of].
@internal
class HarborHingeScope extends InheritedWidget {
  const HarborHingeScope({super.key, required this.hinge, required super.child});

  final HarborHinge hinge;

  @override
  bool updateShouldNotify(final HarborHingeScope oldWidget) => hinge != oldWidget.hinge;
}
