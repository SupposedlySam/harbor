import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'keyboard.dart';

/// Which part of the [HarborRoomData] a reader depends on, so it rebuilds only for that.
enum HarborRoomAspect { systemEdges, bars, margin, frame }

/// One edge's fade: the band where content passing under a bar fades out.
@immutable
class HarborFadeBand {
  const HarborFadeBand({required this.barFace, required this.fadeEnd, this.faceOpacity, this.curve});

  static const HarborFadeBand none = HarborFadeBand(barFace: 0.0, fadeEnd: 0.0);

  /// Distance from the body's edge to the inner face of the bars.
  final double barFace;

  /// Distance from the body's edge to where the fade has fully faded out.
  final double fadeEnd;

  /// How opaque content is at the bars' inner face: the edge effect's
  /// `HarborEdgeEffect.fade(faceOpacity:)`. Null for a fade at its default, so the
  /// painter's own (`HarborFadeMask.faceOpacity`) applies.
  final double? faceOpacity;

  /// The shape of the ramp from [barFace] to [fadeEnd]: the edge effect's
  /// `HarborEdgeEffect.fade(curve:)`. Null for a fade at its default, a straight line.
  final Curve? curve;

  double get length => fadeEnd - barFace;

  /// This band measured from [distance] further in, keeping its ramp.
  @internal
  HarborFadeBand measuredFrom(final double distance) => HarborFadeBand(
    barFace: math.max(0.0, barFace - distance),
    fadeEnd: fadeEnd - distance,
    faceOpacity: faceOpacity,
    curve: curve,
  );

  @override
  bool operator ==(final Object other) =>
      other is HarborFadeBand &&
      other.barFace == barFace &&
      other.fadeEnd == fadeEnd &&
      other.faceOpacity == faceOpacity &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(barFace, fadeEnd, faceOpacity, curve);

  @override
  String toString() => <String>[
    'HarborFadeBand($barFace → $fadeEnd',
    if (faceOpacity != null) ', faceOpacity: $faceOpacity',
    if (curve != null) ', curve: $curve',
    ')',
  ].join();
}

/// What bounds the room at a point in the tree: why `MediaQuery.padding` is what it is.
///
/// `MediaQuery` holds one truth, what is still in the way on each edge, and
/// that is what everything lays out against. This data holds the
/// explanation: how much of it is system edges (the platform), how much is bars
/// (your bars and headers, edge effect included), the margin (the page margin)
/// and the frame. Readers that need one part (a hero that clears the status
/// bar but sits under the header, a page that follows the rail at rest) read
/// it here. Every value is clamped to `MediaQuery`, so a layer outside the
/// frame that removes padding is honored here too.
@immutable
class HarborRoomData {
  const HarborRoomData({
    this.systemEdges = EdgeInsetsDirectional.zero,
    this.systemEdgesSteady = EdgeInsetsDirectional.zero,
    this.bars = EdgeInsetsDirectional.zero,
    this.barsResting = EdgeInsetsDirectional.zero,
    this.fadeBands = const <HarborEdge, HarborFadeBand>{},
    this.margin = EdgeInsetsDirectional.zero,
    this.frameSize = Size.zero,
    this.hasBars = const <HarborEdge>{},
    this.fadeBandsPainted = const <HarborEdge>{},
  });

  /// What the platform still takes on each edge: status bar, home indicator,
  /// cutouts, title-safe.
  final EdgeInsetsDirectional systemEdges;

  /// [systemEdges] as it is with the keyboard down, as `MediaQuery.viewPadding` is to
  /// `MediaQuery.padding`: the home indicator stays in it while the keyboard
  /// covers it. Read it with [HarborRoom.steadySystemEdgeOf].
  final EdgeInsetsDirectional systemEdgesSteady;

  /// How far the bars (and their edge effect, where content rests past it) reach
  /// into this area on each edge, as they are now.
  final EdgeInsetsDirectional bars;

  /// How far the bars reach at rest, for content that holds still while a
  /// bar expands over it (a rail that opens on focus).
  final EdgeInsetsDirectional barsResting;

  /// The fade band on each edge that has one, measured from this area's edge.
  final Map<HarborEdge, HarborFadeBand> fadeBands;

  /// The row insets: the margin content keeps from whatever is in its way.
  /// Applied only by the content that asks for it, so a carousel can run to the
  /// frame's edge while its first item lines up with everything else.
  final EdgeInsetsDirectional margin;

  /// The size of the frame, which neither the bars nor the keyboard shrink.
  final Size frameSize;

  /// The edges the nearest frame has bars on.
  final Set<HarborEdge> hasBars;

  /// The edges whose edge effect a frame's `edgeEffectPainter` already draws over its
  /// whole body, so scroll views inside leave them alone rather than fade twice.
  final Set<HarborEdge> fadeBandsPainted;

  /// The fade band on [edge], or [HarborFadeBand.none].
  HarborFadeBand fadeBandOf(final HarborEdge edge) => fadeBands[edge] ?? HarborFadeBand.none;

  /// What a web view in this area should keep clear of, as CSS custom
  /// properties for `env(safe-area-inset-*)`-style layouts: the larger of the
  /// system edges and the bars on each edge, in logical pixels.
  Map<String, String> toCssVariables(final TextDirection direction) {
    final EdgeInsets insets = HarborEdges.max(systemEdges, bars).resolve(direction);
    return <String, String>{
      '--harbor-inset-top': '${insets.top}px',
      '--harbor-inset-right': '${insets.right}px',
      '--harbor-inset-bottom': '${insets.bottom}px',
      '--harbor-inset-left': '${insets.left}px',
    };
  }

  HarborRoomData copyWith({
    final EdgeInsetsDirectional? systemEdges,
    final EdgeInsetsDirectional? systemEdgesSteady,
    final EdgeInsetsDirectional? bars,
    final EdgeInsetsDirectional? barsResting,
    final Map<HarborEdge, HarborFadeBand>? fadeBands,
    final EdgeInsetsDirectional? margin,
    final Size? frameSize,
    final Set<HarborEdge>? hasBars,
    final Set<HarborEdge>? fadeBandsPainted,
  }) {
    return HarborRoomData(
      systemEdges: systemEdges ?? this.systemEdges,
      systemEdgesSteady: systemEdgesSteady ?? this.systemEdgesSteady,
      bars: bars ?? this.bars,
      barsResting: barsResting ?? this.barsResting,
      fadeBands: fadeBands ?? this.fadeBands,
      margin: margin ?? this.margin,
      frameSize: frameSize ?? this.frameSize,
      hasBars: hasBars ?? this.hasBars,
      fadeBandsPainted: fadeBandsPainted ?? this.fadeBandsPainted,
    );
  }

  /// This room with [edges] handled: a layer has kept clear of them, so
  /// nothing beneath does it again.
  HarborRoomData handled(final Set<HarborEdge> edges, {final bool margin = true}) => copyWith(
    systemEdges: HarborEdges.without(systemEdges, edges),
    systemEdgesSteady: HarborEdges.without(systemEdgesSteady, edges),
    bars: HarborEdges.without(bars, edges),
    barsResting: HarborEdges.without(barsResting, edges),
    fadeBands: {
      for (final MapEntry<HarborEdge, HarborFadeBand> entry in fadeBands.entries)
        if (!edges.contains(entry.key)) entry.key: entry.value,
    },
    margin: margin ? HarborEdges.without(this.margin, edges) : this.margin,
  );

  // This room with the system edges on [edges] handled and the bars kept, beneath a layer that kept
  // clear of [cleared] there: the bars and their edge effects are measured from that layer's edge,
  // which is [cleared] in from this area's.
  HarborRoomData _handledSystemEdges(
    final Set<HarborEdge> edges, {
    required final EdgeInsetsDirectional cleared,
    required final bool margin,
  }) {
    EdgeInsetsDirectional past(final EdgeInsetsDirectional insets) => HarborEdges.build(
      (final HarborEdge e) => edges.contains(e)
          ? math.max(0.0, HarborEdges.of(insets, e) - HarborEdges.of(cleared, e))
          : HarborEdges.of(insets, e),
    );
    return copyWith(
      systemEdges: HarborEdges.without(systemEdges, edges),
      systemEdgesSteady: HarborEdges.without(systemEdgesSteady, edges),
      bars: past(bars),
      barsResting: past(barsResting),
      fadeBands: <HarborEdge, HarborFadeBand>{
        for (final MapEntry<HarborEdge, HarborFadeBand> entry in fadeBands.entries)
          if (!edges.contains(entry.key))
            entry.key: entry.value
          else if (entry.value.fadeEnd > HarborEdges.of(cleared, entry.key))
            entry.key: entry.value.measuredFrom(HarborEdges.of(cleared, entry.key)),
      },
      margin: margin ? HarborEdges.without(this.margin, edges) : this.margin,
    );
  }

  @override
  bool operator ==(final Object other) =>
      other is HarborRoomData &&
      other.systemEdges == systemEdges &&
      other.systemEdgesSteady == systemEdgesSteady &&
      other.bars == bars &&
      other.barsResting == barsResting &&
      _mapEquals(other.fadeBands, fadeBands) &&
      other.margin == margin &&
      other.frameSize == frameSize &&
      _setEquals(other.hasBars, hasBars) &&
      _setEquals(other.fadeBandsPainted, fadeBandsPainted);

  @override
  int get hashCode => Object.hash(
    systemEdges,
    systemEdgesSteady,
    bars,
    barsResting,
    Object.hashAllUnordered(
      fadeBands.entries.map((final MapEntry<HarborEdge, HarborFadeBand> e) => Object.hash(e.key, e.value)),
    ),
    margin,
    frameSize,
    Object.hashAllUnordered(hasBars),
    Object.hashAllUnordered(fadeBandsPainted),
  );

  static bool _mapEquals(final Map<HarborEdge, HarborFadeBand> a, final Map<HarborEdge, HarborFadeBand> b) =>
      a.length == b.length && a.entries.every((final MapEntry<HarborEdge, HarborFadeBand> e) => b[e.key] == e.value);

  static bool _setEquals(final Set<HarborEdge> a, final Set<HarborEdge> b) => a.length == b.length && a.containsAll(b);

  @override
  String toString() => 'HarborRoomData(systemEdges: $systemEdges, bars: $bars, margin: $margin, frame: $frameSize)';
}

/// Publishes [HarborRoomData] beneath a harbor layer.
class HarborRoom extends InheritedModel<HarborRoomAspect> {
  const HarborRoom({super.key, required this.data, required super.child});

  final HarborRoomData data;

  @override
  bool updateShouldNotify(final HarborRoom oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborRoomData>('data', data, showName: false));
  }

  @override
  bool updateShouldNotifyDependent(final HarborRoom oldWidget, final Set<HarborRoomAspect> dependencies) {
    final HarborRoomData a = data;
    final HarborRoomData b = oldWidget.data;
    return dependencies.any(
      (final HarborRoomAspect aspect) => switch (aspect) {
        HarborRoomAspect.systemEdges => a.systemEdges != b.systemEdges || a.systemEdgesSteady != b.systemEdgesSteady,
        HarborRoomAspect.bars =>
          a.bars != b.bars ||
              a.barsResting != b.barsResting ||
              !HarborRoomData._mapEquals(a.fadeBands, b.fadeBands) ||
              !HarborRoomData._setEquals(a.hasBars, b.hasBars) ||
              !HarborRoomData._setEquals(a.fadeBandsPainted, b.fadeBandsPainted),
        HarborRoomAspect.margin => a.margin != b.margin,
        HarborRoomAspect.frame => a.frameSize != b.frameSize,
      },
    );
  }

  /// The raw room data published above [context], unclamped; null outside any frame.
  static HarborRoomData? maybeRawOf(final BuildContext context, {final HarborRoomAspect? aspect}) =>
      InheritedModel.inheritFrom<HarborRoom>(context, aspect: aspect)?.data;

  /// The room data at [context], clamped to `MediaQuery` so a layer outside the
  /// frame that already kept clear of an edge is honored. Outside any
  /// frame the whole of `MediaQuery.padding` reads as system edges.
  ///
  /// With an [aspect], the caller rebuilds only when that part changes: a
  /// reader of the bars holds still while the keyboard moves.
  static HarborRoomData of(final BuildContext context, {final HarborRoomAspect? aspect}) {
    final HarborRoomData? raw = maybeRawOf(context, aspect: aspect);
    // Every field is filled in, but only the ones the aspect covers are
    // depended on: the rest are read without subscribing.
    final MediaQueryData mediaQuery =
        context.getInheritedWidgetOfExactType<MediaQuery>()?.data ?? MediaQuery.of(context);
    final bool readsPadding =
        aspect == null || aspect == HarborRoomAspect.systemEdges || aspect == HarborRoomAspect.bars;
    final EdgeInsetsDirectional padding = HarborEdges.directional(
      readsPadding ? MediaQuery.paddingOf(context) : mediaQuery.padding,
      Directionality.of(context),
    );
    if (raw == null) {
      final bool readsFrame = aspect == null || aspect == HarborRoomAspect.frame;
      return HarborRoomData(
        systemEdges: padding,
        systemEdgesSteady: HarborEdges.directional(
          readsPadding ? MediaQuery.viewPaddingOf(context) : mediaQuery.viewPadding,
          Directionality.of(context),
        ),
        frameSize: readsFrame ? MediaQuery.sizeOf(context) : mediaQuery.size,
      );
    }
    return raw.copyWith(
      systemEdges: HarborEdges.min(raw.systemEdges, padding),
      // The steady system edges' clamp reads the view padding and the keyboard, which a body that
      // clears the keyboard moves on every frame drawn. As `MediaQuery.paddingOf` does not subscribe
      // to `viewPadding`, only a reader of everything subscribes here; the rest get the right value,
      // read without subscribing, and hold still while the keyboard moves. `steadySystemEdgeOf` is
      // the reader that follows it.
      systemEdgesSteady: HarborEdges.build(
        (final HarborEdge edge) => _steadySystemEdge(context, raw, edge, listen: aspect == null),
      ),
      bars: HarborEdges.min(raw.bars, padding),
      barsResting: HarborEdges.min(raw.barsResting, padding),
    );
  }

  /// The system edge on [edge] at [context] as it is with the keyboard down: the home
  /// indicator's height at the bottom, held while the keyboard is up. For a
  /// footer that keeps the same size as the keyboard comes and goes, where
  /// `MediaQuery.viewPadding` would not: a frame whose body clears the keyboard
  /// takes the keyboard's ground out of both. Zero once a bar has absorbed
  /// the system edge or a layer has handled it; outside any frame,
  /// `MediaQuery.viewPadding`.
  ///
  /// It holds the home indicator even in a body that ends at the keyboard, so
  /// a footer there keeps its height as the keyboard comes and goes. A footer
  /// that sits on the keyboard instead, and gives the home indicator's room
  /// back while the keyboard covers it, reads `MediaQuery.viewPaddingOf`: in a
  /// body that clears the keyboard it is the home indicator with the keyboard
  /// down and 0 with it up, the share of the indicator the keyboard leaves
  /// uncovered on the way.
  static double steadySystemEdgeOf(final BuildContext context, final HarborEdge edge) {
    final HarborRoomData? raw = maybeRawOf(context, aspect: HarborRoomAspect.systemEdges);
    if (raw == null) {
      return HarborEdges.of(
        HarborEdges.directional(MediaQuery.viewPaddingOf(context), Directionality.of(context)),
        edge,
      );
    }
    return _steadySystemEdge(context, raw, edge);
  }

  // Clamped to `MediaQuery.viewPadding` like the rest of the room data, so a layer
  // outside the frame that removed the system edges is honored. At the bottom the
  // keyboard the frames above kept clear of is added back first: a body that
  // ends at the keyboard's top has no view padding left there, though the system
  // edge is still what it was.
  //
  // The keyboard's height is read without following it. Under a body that
  // clears the keyboard the view padding falls as the keyboard rises, so their sum
  // and the result hold still; following the gauge would rebuild a listening
  // reader on every frame drawn for a value that does not move. It still hears the
  // keyboard come and go.
  static double _steadySystemEdge(
    final BuildContext context,
    final HarborRoomData raw,
    final HarborEdge edge, {
    final bool listen = true,
  }) {
    final double value = HarborEdges.of(raw.systemEdgesSteady, edge);
    final MediaQueryData? quiet = listen ? null : context.getInheritedWidgetOfExactType<MediaQuery>()?.data;
    final EdgeInsets viewPadding = quiet?.viewPadding ?? MediaQuery.viewPaddingOf(context);
    double bound = HarborEdges.of(HarborEdges.directional(viewPadding, Directionality.of(context)), edge);
    if (bound < value && edge == HarborEdge.bottom) {
      if (listen) {
        HarborKeyboard.isShownOf(context);
      }
      final double remaining = quiet?.viewInsets.bottom ?? MediaQuery.viewInsetsOf(context).bottom;
      final double height = HarborKeyboardScope.maybeGaugeOf(context, listen: false)?.height ?? remaining;
      bound += math.max(height, remaining) - remaining;
    }
    return math.min(value, bound);
  }

  /// How far the bars on [edge] reach into [context]'s area, to their inner
  /// face: a header's bottom edge, where its edge effect (if it has one) begins. For
  /// artwork that lines up under a frosted header, with or without an edge effect.
  ///
  /// It is the fade band's [HarborFadeBand.barFace] where [edge] has a fade
  /// edge effect, and [HarborRoomData.bars] otherwise, which is the face itself when
  /// the edge effect adds no clearance (no edge effect, a hairline, or a fade that
  /// rests at the bar's edge). Zero where there is no bar, and beneath anything that
  /// handled the edge, a scroll view's ends included.
  ///
  /// It depends on the [HarborRoomAspect.bars] aspect alone, so its reader
  /// holds still while the keyboard moves.
  static double barFaceOf(final BuildContext context, final HarborEdge edge) {
    final HarborRoomData room = of(context, aspect: HarborRoomAspect.bars);
    final HarborFadeBand? band = room.fadeBands[edge];
    return band != null ? band.barFace : HarborEdges.of(room.bars, edge);
  }

  /// What is still in the way on [edge] at [context]: the one number content
  /// lays out against. The larger of `MediaQuery.padding` and, at the bottom,
  /// whatever of the keyboard still reaches here.
  static double clearanceOf(final BuildContext context, final HarborEdge edge, {final bool clearsKeyboard = true}) {
    final EdgeInsetsDirectional padding = HarborEdges.directional(
      MediaQuery.paddingOf(context),
      Directionality.of(context),
    );
    final double value = HarborEdges.of(padding, edge);
    if (clearsKeyboard && edge == HarborEdge.bottom) {
      return math.max(value, MediaQuery.viewInsetsOf(context).bottom);
    }
    return value;
  }
}

/// Marks [edges] handled for everything beneath: after a layer has kept clear of
/// them, the area below reads zero there and cannot clear them a second time.
///
/// For your own layer that pads by hand (or a third-party list given
/// `HarborScrollView.paddingOf`). harbor's own widgets mark them handled for you.
///
/// A layer that kept clear of the system edges alone (a page's safe-area margin, as
/// `HarborRoom.of(context).systemEdges` reads it) passes `clearsBars: false`: the system
/// edges are handled and the bars stay, so a scroll view beneath still rests clear of a
/// frosted header or tab bar. Beneath, the bars are measured from that
/// layer's edge, and `MediaQuery.padding` and `viewPadding` say the same.
///
/// See also:
///
///  * [MediaQuery.removePadding], which lowers `viewPadding` only by the padding it removes; this
///    zeroes `viewPadding`, removes the keyboard with [clearsKeyboard], and zeroes harbor's own room data.
class HarborHandled extends StatelessWidget {
  const HarborHandled({
    super.key,
    this.edges = HarborEdge.all,
    this.clearsKeyboard = false,
    this.margin = true,
    this.clearsBars = true,
    required this.child,
  });

  final Set<HarborEdge> edges;

  /// Whether the keyboard is handled too.
  final bool clearsKeyboard;

  /// Whether the margin on [edges] is handled too.
  final bool margin;

  /// Whether the bars on [edges] are handled with the system edges. False handles
  /// the system edges alone, for a layer that kept clear of them and leaves the
  /// bars (their edge effects, the bars at rest, which edges have them) to what is
  /// beneath it. Outside any frame all of `MediaQuery.padding` is system edges, so it
  /// is all handled either way.
  final bool clearsBars;

  final Widget child;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<HarborEdge>('edges', edges, defaultValue: HarborEdge.all));
    properties.add(FlagProperty('clearsKeyboard', value: clearsKeyboard, ifTrue: 'handles the keyboard'));
    properties.add(FlagProperty('margin', value: margin, ifFalse: 'keeps the margin'));
    properties.add(FlagProperty('clearsBars', value: clearsBars, ifFalse: 'keeps the bars'));
  }

  @override
  Widget build(final BuildContext context) {
    if (!clearsBars) {
      return _handledSystemEdges(context);
    }
    final TextDirection direction = Directionality.of(context);
    final ({bool left, bool top, bool right, bool bottom}) sides = HarborEdges.physical(edges, direction);
    MediaQueryData data = MediaQuery.of(
      context,
    ).removePadding(removeLeft: sides.left, removeTop: sides.top, removeRight: sides.right, removeBottom: sides.bottom);
    data = data.removeViewPadding(
      removeLeft: sides.left,
      removeTop: sides.top,
      removeRight: sides.right,
      removeBottom: sides.bottom,
    );
    if (clearsKeyboard) {
      data = data.removeViewInsets(removeBottom: true);
    }
    // Outside any frame, the room data a reader here would see: all of MediaQuery's padding as system
    // edges. Empty room data zeroed every edge beneath, not just these: a sheet with clearsSides opened
    // with no HarborRoot read a bottom inset of 0 instead of the home indicator (#98).
    final HarborRoomData room = (HarborRoom.maybeRawOf(context) ?? HarborRoom.of(context)).handled(
      edges,
      margin: margin,
    );
    return MediaQuery(
      data: data,
      child: HarborRoom(data: room, child: child),
    );
  }

  // The system edges alone: what is still in the way beneath is the bars past the system edges the
  // layer kept clear of, in `MediaQuery` and in the room data alike.
  Widget _handledSystemEdges(final BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final MediaQueryData ambient = MediaQuery.of(context);
    // The system edges as a reader here sees them, clamped to `MediaQuery`: outside a frame, all of it.
    final HarborRoomData here = HarborRoom.of(context);
    final EdgeInsetsDirectional cleared = HarborEdges.keep(here.systemEdges, edges);
    final EdgeInsetsDirectional clearedSteady = HarborEdges.keep(here.systemEdgesSteady, edges);
    final EdgeInsetsDirectional padding = HarborEdges.directional(ambient.padding, direction);
    final EdgeInsetsDirectional viewPadding = HarborEdges.directional(ambient.viewPadding, direction);
    final EdgeInsetsDirectional paddingBeneath = HarborEdges.build(
      (final HarborEdge e) => math.max(0.0, HarborEdges.of(padding, e) - HarborEdges.of(cleared, e)),
    );
    // The view padding is the bars past the steady system edges, never less than the padding, as
    // Flutter keeps it.
    final EdgeInsetsDirectional viewPaddingBeneath = HarborEdges.build(
      (final HarborEdge e) => edges.contains(e)
          ? math.max(
              HarborEdges.of(paddingBeneath, e),
              HarborEdges.of(viewPadding, e) - HarborEdges.of(clearedSteady, e),
            )
          : HarborEdges.of(viewPadding, e),
    );
    MediaQueryData data = ambient.copyWith(
      padding: paddingBeneath.resolve(direction),
      viewPadding: viewPaddingBeneath.resolve(direction),
    );
    if (clearsKeyboard) {
      data = data.removeViewInsets(removeBottom: true);
    }
    final HarborRoomData room = (HarborRoom.maybeRawOf(context) ?? HarborRoom.of(context))._handledSystemEdges(
      edges,
      cleared: cleared,
      margin: margin,
    );
    return MediaQuery(
      data: data,
      child: HarborRoom(data: room, child: child),
    );
  }
}

/// The system edges a layer handled above a frame that still covers the frame, which the
/// frame keeps out of its room though its content reads zero there. A sheet with
/// `clearsTopSystemEdge: false` handles the status bar for its header and body, yet the sheet still
/// reaches under it, so toasts, floats and the inspector must keep clear of it (#97).
@internal
class HarborRoomFloor extends InheritedWidget {
  const HarborRoomFloor({super.key, required this.floor, required super.child});

  final EdgeInsetsDirectional floor;

  static EdgeInsetsDirectional of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarborRoomFloor>()?.floor ?? EdgeInsetsDirectional.zero;

  @override
  bool updateShouldNotify(final HarborRoomFloor oldWidget) => floor != oldWidget.floor;
}
