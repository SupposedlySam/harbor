import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'tide.dart';

/// Which part of the waters a reader depends on, so it rebuilds only for that.
enum HarborWatersAspect { coast, docks, margin, frame }

/// One edge's wake: the band where content passing under a dock fades out.
@immutable
class HarborWakeBand {
  const HarborWakeBand({required this.dockEdge, required this.wakeEnd});

  static const HarborWakeBand none = HarborWakeBand(dockEdge: 0.0, wakeEnd: 0.0);

  /// Distance from the body's edge to the inner face of the docks.
  final double dockEdge;

  /// Distance from the body's edge to where the wake has fully faded out.
  final double wakeEnd;

  double get length => wakeEnd - dockEdge;

  @override
  bool operator ==(final Object other) =>
      other is HarborWakeBand && other.dockEdge == dockEdge && other.wakeEnd == wakeEnd;

  @override
  int get hashCode => Object.hash(dockEdge, wakeEnd);

  @override
  String toString() => 'HarborWakeBand($dockEdge → $wakeEnd)';
}

/// The waters at a point in the tree: why `MediaQuery.padding` is what it is.
///
/// `MediaQuery` holds one truth, what is still in the way on each edge, and
/// that is what everything lays out against. These waters hold the
/// explanation: how much of it is coast (the platform), how much is docks
/// (your bars and headers, wake included), the mooring line (the page margin)
/// and the frame. Readers that need one part (a hero that clears the status
/// bar but sits under the header, a page that follows the rail at rest) read
/// it here. Every value is clamped to `MediaQuery`, so a layer outside the
/// harbor that removes padding is honored here too.
@immutable
class HarborWatersData {
  const HarborWatersData({
    this.coast = EdgeInsetsDirectional.zero,
    this.coastSteady = EdgeInsetsDirectional.zero,
    this.docks = EdgeInsetsDirectional.zero,
    this.docksResting = EdgeInsetsDirectional.zero,
    this.wakes = const <HarborEdge, HarborWakeBand>{},
    this.margin = EdgeInsetsDirectional.zero,
    this.frameSize = Size.zero,
    this.hasDocks = const <HarborEdge>{},
    this.wakesPainted = const <HarborEdge>{},
  });

  /// What the platform still takes on each edge: status bar, home indicator,
  /// cutouts, title-safe.
  final EdgeInsetsDirectional coast;

  /// [coast] as it is with the keyboard down, as `MediaQuery.viewPadding` is to
  /// `MediaQuery.padding`: the home indicator stays in it while the keyboard
  /// covers it. Read it with [HarborWaters.steadyCoastOf].
  final EdgeInsetsDirectional coastSteady;

  /// How far the docks (and their wake, where content rests past it) reach
  /// into this area on each edge, as they are now.
  final EdgeInsetsDirectional docks;

  /// How far the docks reach at rest, for content that holds still while a
  /// dock expands over it (a rail that opens on focus).
  final EdgeInsetsDirectional docksResting;

  /// The wake band on each edge that has one, measured from this area's edge.
  final Map<HarborEdge, HarborWakeBand> wakes;

  /// The mooring line: the margin content keeps from whatever is in its way.
  /// Applied only by the content that asks for it, so a carousel can run to the
  /// frame's edge while its first item lines up with everything else.
  final EdgeInsetsDirectional margin;

  /// The size of the harbor's frame, which neither the docks nor the keyboard shrink.
  final Size frameSize;

  /// The edges the nearest harbor has docks on.
  final Set<HarborEdge> hasDocks;

  /// The edges whose wake a harbor's `wakePainter` already draws over its
  /// whole body, so fairways inside leave them alone rather than fade twice.
  final Set<HarborEdge> wakesPainted;

  HarborWakeBand wakeOf(final HarborEdge edge) => wakes[edge] ?? HarborWakeBand.none;

  /// What a web view in this area should keep clear of, as CSS custom
  /// properties for `env(safe-area-inset-*)`-style layouts: the larger of the
  /// coast and the docks on each edge, in logical pixels.
  Map<String, String> toCssVariables(final TextDirection direction) {
    final EdgeInsets insets = HarborEdges.max(coast, docks).resolve(direction);
    return <String, String>{
      '--harbor-inset-top': '${insets.top}px',
      '--harbor-inset-right': '${insets.right}px',
      '--harbor-inset-bottom': '${insets.bottom}px',
      '--harbor-inset-left': '${insets.left}px',
    };
  }

  HarborWatersData copyWith({
    final EdgeInsetsDirectional? coast,
    final EdgeInsetsDirectional? coastSteady,
    final EdgeInsetsDirectional? docks,
    final EdgeInsetsDirectional? docksResting,
    final Map<HarborEdge, HarborWakeBand>? wakes,
    final EdgeInsetsDirectional? margin,
    final Size? frameSize,
    final Set<HarborEdge>? hasDocks,
    final Set<HarborEdge>? wakesPainted,
  }) => HarborWatersData(
    coast: coast ?? this.coast,
    coastSteady: coastSteady ?? this.coastSteady,
    docks: docks ?? this.docks,
    docksResting: docksResting ?? this.docksResting,
    wakes: wakes ?? this.wakes,
    margin: margin ?? this.margin,
    frameSize: frameSize ?? this.frameSize,
    hasDocks: hasDocks ?? this.hasDocks,
    wakesPainted: wakesPainted ?? this.wakesPainted,
  );

  /// These waters with [edges] cast off: a layer has kept clear of them, so
  /// nothing beneath does it again.
  HarborWatersData castOff(final Set<HarborEdge> edges, {final bool margin = true}) => copyWith(
    coast: HarborEdges.without(coast, edges),
    coastSteady: HarborEdges.without(coastSteady, edges),
    docks: HarborEdges.without(docks, edges),
    docksResting: HarborEdges.without(docksResting, edges),
    wakes: {
      for (final MapEntry<HarborEdge, HarborWakeBand> entry in wakes.entries)
        if (!edges.contains(entry.key)) entry.key: entry.value,
    },
    margin: margin ? HarborEdges.without(this.margin, edges) : this.margin,
  );

  @override
  bool operator ==(final Object other) =>
      other is HarborWatersData &&
      other.coast == coast &&
      other.coastSteady == coastSteady &&
      other.docks == docks &&
      other.docksResting == docksResting &&
      _mapEquals(other.wakes, wakes) &&
      other.margin == margin &&
      other.frameSize == frameSize &&
      _setEquals(other.hasDocks, hasDocks) &&
      _setEquals(other.wakesPainted, wakesPainted);

  @override
  int get hashCode => Object.hash(
    coast,
    coastSteady,
    docks,
    docksResting,
    Object.hashAllUnordered(wakes.entries.map((final MapEntry<HarborEdge, HarborWakeBand> e) => Object.hash(e.key, e.value))),
    margin,
    frameSize,
    Object.hashAllUnordered(hasDocks),
    Object.hashAllUnordered(wakesPainted),
  );

  static bool _mapEquals(final Map<HarborEdge, HarborWakeBand> a, final Map<HarborEdge, HarborWakeBand> b) =>
      a.length == b.length && a.entries.every((final MapEntry<HarborEdge, HarborWakeBand> e) => b[e.key] == e.value);

  static bool _setEquals(final Set<HarborEdge> a, final Set<HarborEdge> b) => a.length == b.length && a.containsAll(b);

  @override
  String toString() => 'HarborWatersData(coast: $coast, docks: $docks, margin: $margin, frame: $frameSize)';
}

/// Publishes [HarborWatersData] beneath a harbor layer.
class HarborWaters extends InheritedModel<HarborWatersAspect> {
  const HarborWaters({super.key, required this.data, required super.child});

  final HarborWatersData data;

  @override
  bool updateShouldNotify(final HarborWaters oldWidget) => data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(final HarborWaters oldWidget, final Set<HarborWatersAspect> dependencies) {
    final HarborWatersData a = data;
    final HarborWatersData b = oldWidget.data;
    return dependencies.any(
      (final HarborWatersAspect aspect) => switch (aspect) {
        HarborWatersAspect.coast => a.coast != b.coast || a.coastSteady != b.coastSteady,
        HarborWatersAspect.docks =>
          a.docks != b.docks ||
              a.docksResting != b.docksResting ||
              !HarborWatersData._mapEquals(a.wakes, b.wakes) ||
              !HarborWatersData._setEquals(a.hasDocks, b.hasDocks) ||
              !HarborWatersData._setEquals(a.wakesPainted, b.wakesPainted),
        HarborWatersAspect.margin => a.margin != b.margin,
        HarborWatersAspect.frame => a.frameSize != b.frameSize,
      },
    );
  }

  /// The raw waters published above [context], unclamped; null outside any harbor.
  static HarborWatersData? maybeRawOf(final BuildContext context, {final HarborWatersAspect? aspect}) =>
      InheritedModel.inheritFrom<HarborWaters>(context, aspect: aspect)?.data;

  /// The waters at [context], clamped to `MediaQuery` so a layer outside the
  /// harbor that already kept clear of an edge is honored. Outside any
  /// harbor the whole of `MediaQuery.padding` reads as coast.
  ///
  /// With an [aspect], the caller rebuilds only when that part changes: a
  /// reader of the docks holds still while the keyboard moves.
  static HarborWatersData of(final BuildContext context, {final HarborWatersAspect? aspect}) {
    final HarborWatersData? raw = maybeRawOf(context, aspect: aspect);
    // Every field is filled in, but only the ones the aspect covers are
    // depended on: the rest are read without subscribing.
    final MediaQueryData mediaQuery = context.getInheritedWidgetOfExactType<MediaQuery>()?.data ?? MediaQuery.of(context);
    final bool readsPadding = aspect == null || aspect == HarborWatersAspect.coast || aspect == HarborWatersAspect.docks;
    final EdgeInsetsDirectional padding = HarborEdges.directional(
      readsPadding ? MediaQuery.paddingOf(context) : mediaQuery.padding,
      Directionality.of(context),
    );
    if (raw == null) {
      final bool readsFrame = aspect == null || aspect == HarborWatersAspect.frame;
      return HarborWatersData(
        coast: padding,
        coastSteady: HarborEdges.directional(
          readsPadding ? MediaQuery.viewPaddingOf(context) : mediaQuery.viewPadding,
          Directionality.of(context),
        ),
        frameSize: readsFrame ? MediaQuery.sizeOf(context) : mediaQuery.size,
      );
    }
    return raw.copyWith(
      coast: HarborEdges.min(raw.coast, padding),
      // The steady coast's clamp reads the view padding and the keyboard, which a body that clears
      // the tide moves on every frame. As `MediaQuery.paddingOf` does not subscribe to
      // `viewPadding`, only a reader of everything subscribes here; the rest get the right value,
      // read without subscribing, and hold still while the keyboard moves. `steadyCoastOf` is the
      // reader that follows it.
      coastSteady: HarborEdges.build(
        (final HarborEdge edge) => _steadyCoast(context, raw, edge, listen: aspect == null),
      ),
      docks: HarborEdges.min(raw.docks, padding),
      docksResting: HarborEdges.min(raw.docksResting, padding),
    );
  }

  /// The coast on [edge] at [context] as it is with the keyboard down: the home
  /// indicator's height at the bottom, held while the keyboard is up. For a
  /// footer that keeps the same size as the keyboard comes and goes, where
  /// `MediaQuery.viewPadding` would not: a harbor whose body clears the tide
  /// takes the keyboard's ground out of both. Zero once a dock has absorbed
  /// the coast or a layer has cast it off; outside any harbor,
  /// `MediaQuery.viewPadding`.
  static double steadyCoastOf(final BuildContext context, final HarborEdge edge) {
    final HarborWatersData? raw = maybeRawOf(context, aspect: HarborWatersAspect.coast);
    if (raw == null) {
      return HarborEdges.of(HarborEdges.directional(MediaQuery.viewPaddingOf(context), Directionality.of(context)), edge);
    }
    return _steadyCoast(context, raw, edge);
  }

  // Clamped to `MediaQuery.viewPadding` like the rest of the waters, so a layer
  // outside the harbor that removed the coast is honored. At the bottom the
  // keyboard the harbors above kept clear of is added back first: a body that
  // ends at the waterline has no view padding left there, though the coast is
  // still what it was.
  //
  // The keyboard's height is read without following it. Under a body that
  // clears the tide the view padding falls as the keyboard rises, so their sum
  // and the result hold still; following the gauge would rebuild a listening
  // reader on every frame for a value that does not move. It still hears the
  // keyboard come and go.
  static double _steadyCoast(final BuildContext context, final HarborWatersData raw, final HarborEdge edge, {final bool listen = true}) {
    final double value = HarborEdges.of(raw.coastSteady, edge);
    final MediaQueryData? quiet = listen ? null : context.getInheritedWidgetOfExactType<MediaQuery>()?.data;
    final EdgeInsets viewPadding = quiet?.viewPadding ?? MediaQuery.viewPaddingOf(context);
    double bound = HarborEdges.of(HarborEdges.directional(viewPadding, Directionality.of(context)), edge);
    if (bound < value && edge == HarborEdge.bottom) {
      if (listen) {
        HarborTide.isInOf(context);
      }
      final double remaining = quiet?.viewInsets.bottom ?? MediaQuery.viewInsetsOf(context).bottom;
      final double height = HarborTideScope.maybeGaugeOf(context, listen: false)?.height ?? remaining;
      bound += math.max(height, remaining) - remaining;
    }
    return math.min(value, bound);
  }

  /// What is still in the way on [edge] at [context]: the one number content
  /// lays out against. The larger of `MediaQuery.padding` and, at the bottom,
  /// whatever of the keyboard still reaches here.
  static double clearanceOf(final BuildContext context, final HarborEdge edge, {final bool tide = true}) {
    final EdgeInsetsDirectional padding = HarborEdges.directional(
      MediaQuery.paddingOf(context),
      Directionality.of(context),
    );
    final double value = HarborEdges.of(padding, edge);
    if (tide && edge == HarborEdge.bottom) {
      return math.max(value, MediaQuery.viewInsetsOf(context).bottom);
    }
    return value;
  }
}

/// Casts off [edges] for everything beneath: after a layer has kept clear of
/// them, the area below reads zero there and cannot clear them a second time.
///
/// For your own layer that pads by hand (or a third-party list given
/// `HarborFairway.paddingOf`). The harbor's own widgets cast off for you.
class HarborCastOff extends StatelessWidget {
  const HarborCastOff({
    super.key,
    this.edges = HarborEdge.all,
    this.tide = false,
    this.margin = true,
    required this.child,
  });

  final Set<HarborEdge> edges;

  /// Whether the keyboard is cast off too.
  final bool tide;

  /// Whether the mooring line on [edges] is cast off too.
  final bool margin;

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final ({bool left, bool top, bool right, bool bottom}) sides = HarborEdges.physical(edges, direction);
    MediaQueryData data = MediaQuery.of(context).removePadding(
      removeLeft: sides.left,
      removeTop: sides.top,
      removeRight: sides.right,
      removeBottom: sides.bottom,
    );
    data = data.removeViewPadding(
      removeLeft: sides.left,
      removeTop: sides.top,
      removeRight: sides.right,
      removeBottom: sides.bottom,
    );
    if (tide) {
      data = data.removeViewInsets(removeBottom: true);
    }
    final HarborWatersData waters = (HarborWaters.maybeRawOf(context) ?? const HarborWatersData()).castOff(
      edges,
      margin: margin,
    );
    return MediaQuery(
      data: data,
      child: HarborWaters(data: waters, child: child),
    );
  }
}
