import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'moored.dart';
import 'wake.dart';
import 'waters.dart';

/// What a scroll view's end on [edge] keeps clear of: everything in the way there, or without
/// [bars] the system edges alone; and at the bottom, while [keyboard], the keyboard.
///
/// Each part is read through its own aspect, so a scroll view that clears the system edges alone,
/// or leaves the keyboard, does not rebuild as the keyboard moves.
double _endClearance(
  final BuildContext context,
  final HarborEdge edge, {
  required final bool bars,
  required final bool keyboard,
}) {
  if (bars) {
    return HarborRoom.clearanceOf(context, edge, keyboard: keyboard);
  }
  final double systemEdges = HarborEdges.of(
    HarborRoom.of(context, aspect: HarborRoomAspect.systemEdges).systemEdges,
    edge,
  );
  if (keyboard && edge == HarborEdge.bottom) {
    return math.max(systemEdges, MediaQuery.viewInsetsOf(context).bottom);
  }
  return systemEdges;
}

/// A `StatelessWidget`, not a `ScrollView` subclass: a scroll view whose viewport runs to the
/// frame's edges, under the bars, while its content comes to rest clear of them at both ends.
///
/// Vertical, it keeps clear of the top and bottom (the keyboard included) and
/// leaves the sides to its rows ([HarborClear.rowInsets]) and to any horizontal
/// scroll view inside it, so a carousel can still run to the frame's edge.
/// Horizontal, it keeps clear of the start and end plus the row insets, at
/// both ends, and leaves the top and bottom alone.
///
/// [padding] is your own spacing and is added to the clearance, never in place
/// of it. A focused field, `Scrollable.ensureVisible` and focus traversal all
/// reveal a row clear of the bars: the scroll view widens each reveal by what
/// covers its trailing edge.
///
/// The tree is the same whatever the insets are, so the keyboard coming and
/// going changes numbers, never structure, and scroll position survives.
///
/// It takes the rest of a `CustomScrollView`'s parameters, with the same
/// defaults, and hands them to its scroll view.
///
/// See also:
///
///  * [ListView], which pads its ends by `MediaQuery.padding` when given no padding but not by the
///    keyboard, and [CustomScrollView], which pads nothing.
class HarborScrollView extends StatelessWidget {
  const HarborScrollView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.scrollBehavior,
    this.shrinkWrap = false,
    this.center,
    this.anchor = 0.0,
    this.padding = EdgeInsetsDirectional.zero,
    this.minimum = EdgeInsetsDirectional.zero,
    final bool rowInsets = true,
    @Deprecated('Renamed rowInsets. `dart fix` applies it.') final bool? mooringLine,
    this.bars = true,
    final bool keyboard = true,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final bool? tide,
    this.revealMargin = 0.0,
    final bool edgeEffects = true,
    @Deprecated('Renamed edgeEffects. `dart fix` applies it.') final bool? wake,
    final bool startsUnderBars = false,
    @Deprecated('Renamed startsUnderBars. `dart fix` applies it.') final bool? startsInOpenWater,
    this.scrollCacheExtent,
    this.paintOrder = SliverPaintOrder.firstIsTop,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    required this.slivers,
  }) : rowInsets = mooringLine ?? rowInsets,
       keyboard = tide ?? keyboard,
       edgeEffects = wake ?? edgeEffects,
       startsUnderBars = startsInOpenWater ?? startsUnderBars,
       assert(!shrinkWrap || center == null),
       assert(anchor >= 0.0 && anchor <= 1.0),
       _hugsChild = false;

  /// A scroll view with a single box [child].
  ///
  /// Where the cross axis is unbounded, as a horizontal scroll view's height is in
  /// a `Column`, it is as thick as [child] (a row of chips as tall as the
  /// chips), the way a `SingleChildScrollView` is. [child] then needs an
  /// intrinsic size on that axis, as it would under `IntrinsicHeight`. Given a
  /// bounded cross axis it fills it, like any scroll view. [shrinkWrap] is the
  /// main axis.
  HarborScrollView.box({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.scrollBehavior,
    this.shrinkWrap = false,
    this.padding = EdgeInsetsDirectional.zero,
    this.minimum = EdgeInsetsDirectional.zero,
    final bool rowInsets = true,
    @Deprecated('Renamed rowInsets. `dart fix` applies it.') final bool? mooringLine,
    this.bars = true,
    final bool keyboard = true,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final bool? tide,
    this.revealMargin = 0.0,
    final bool edgeEffects = true,
    @Deprecated('Renamed edgeEffects. `dart fix` applies it.') final bool? wake,
    final bool startsUnderBars = false,
    @Deprecated('Renamed startsUnderBars. `dart fix` applies it.') final bool? startsInOpenWater,
    this.scrollCacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    required final Widget child,
  }) : rowInsets = mooringLine ?? rowInsets,
       keyboard = tide ?? keyboard,
       edgeEffects = wake ?? edgeEffects,
       startsUnderBars = startsInOpenWater ?? startsUnderBars,
       center = null,
       anchor = 0.0,
       paintOrder = SliverPaintOrder.firstIsTop,
       semanticChildCount = null,
       _hugsChild = true,
       slivers = <Widget>[SliverToBoxAdapter(child: _HarborHugTarget(child: child))];

  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final ScrollBehavior? scrollBehavior;
  final bool shrinkWrap;

  /// The key of the sliver at the zero scroll offset, as on a
  /// `CustomScrollView`: the slivers before it grow away from it, toward the
  /// leading end. Each end of the scroll still rests clear of the bars there,
  /// and at rest the center sliver starts clear of the leading bars.
  ///
  /// [HarborSliverBar]s after the center pin at the bars' face. Those before it
  /// grow the other way, so they pin at the trailing end of the viewport, as
  /// they would in a `CustomScrollView`, without keeping clear of the bars.
  final Key? center;

  /// Where the zero scroll offset sits, as a fraction of the room between the
  /// bars rather than of the whole viewport, which runs under them: 0 rests
  /// it clear of the leading bars, 1 at the face of the trailing bars (and
  /// the keyboard). Otherwise it is a `CustomScrollView`'s anchor.
  final double anchor;

  /// Your own spacing at each end and side, added to the clearance.
  final EdgeInsetsGeometry padding;

  /// A floor on each end's clearance, as `SafeArea.minimum` is: whatever is in
  /// the way there or this, whichever is larger, before [padding] is added.
  /// The bottom of a phone with a home button, where nothing covers the end.
  final EdgeInsetsGeometry minimum;

  /// For a horizontal scroll view: whether the ends add the frame's margin, so
  /// the first item at rest lines up with the rest of the page.
  final bool rowInsets;

  /// The old name of [rowInsets].
  @Deprecated('Renamed rowInsets. `dart fix` applies it.')
  bool get mooringLine => rowInsets;

  /// Whether the ends keep clear of the bars (headers, tab bars, rails) as
  /// well as the system edges. True, the default, is the system edges, the
  /// bars and the keyboard.
  ///
  /// False is the system edges (the status bar, the home indicator, a cutout)
  /// alone, for a list that rests clear of the status bar and the home
  /// indicator but under a translucent header or tab bar: the ends mark the
  /// system edges alone handled, as `HarborHandled(bars: false)` does, so
  /// its rows still read the bars, measured from the scroll view's edge.
  /// Pinned [HarborSliverBar]s still pin at the bars' face, and reveals still
  /// keep clear of everything over the viewport.
  ///
  /// The bottom end keeps clear of the keyboard either way, unless [keyboard] is
  /// false, as a reveal needs that room to bring a row above it. (This is
  /// where a scroll view differs from [HarborClear.bars], whose false leaves the
  /// keyboard out whatever its `keyboard`.)
  final bool bars;

  /// Whether a vertical scroll view keeps clear of the keyboard, as on
  /// [HarborClear.keyboard]. False leaves it to something else: a list in a host
  /// whose body already ends at the keyboard, or one that stays put while a
  /// keyboard opens over it. The bottom end and reveals then leave the keyboard
  /// out, and it is not handled, so content inside can still keep clear of it.
  final bool keyboard;

  /// The old name of [keyboard].
  @Deprecated('Renamed keyboard. `dart fix` applies it.')
  bool get tide => keyboard;

  /// Extra space kept around a revealed row, beyond what covers the edge: a TV
  /// row that keeps the focused card a step in from the rail.
  final double revealMargin;

  /// Whether content fades out as it scrolls under a bar with a fade edge effect.
  final bool edgeEffects;

  /// The old name of [edgeEffects].
  @Deprecated('Renamed edgeEffects. `dart fix` applies it.')
  bool get wake => edgeEffects;

  /// Whether the first sliver starts at the frame's edge, under the bars, as
  /// a hero image that runs under a translucent header does. Pinned
  /// [HarborSliverBar]s still pin at the bars' face, and reveals still keep clear of them.
  ///
  /// The first sliver is handed back the leading end alone, so it can keep its
  /// title clear of the status bar: the trailing end, the keyboard and the
  /// trailing row insets stay handled.
  final bool startsUnderBars;

  /// The old name of [startsUnderBars].
  @Deprecated('Renamed startsUnderBars. `dart fix` applies it.')
  bool get startsInOpenWater => startsUnderBars;

  final ScrollCacheExtent? scrollCacheExtent;
  final SliverPaintOrder paintOrder;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;

  /// How a drag dismisses the keyboard. Left null, it is the [scrollBehavior]'s,
  /// or else the inherited `ScrollConfiguration`'s, as on a `ScrollView`.
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final HitTestBehavior hitTestBehavior;
  final List<Widget> slivers;

  /// Whether this is the box form, which can take its cross axis from its child.
  final bool _hugsChild;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // The fields a scroll view has read as `ScrollView` shows them, scrollDirection even at its default.
    properties.add(EnumProperty<Axis>('scrollDirection', scrollDirection));
    properties.add(FlagProperty('reverse', value: reverse, ifTrue: 'reversed', showName: true));
    properties.add(
      DiagnosticsProperty<ScrollController>('controller', controller, showName: false, defaultValue: null),
    );
    properties.add(FlagProperty('primary', value: primary, ifTrue: 'using primary controller', showName: true));
    properties.add(DiagnosticsProperty<ScrollPhysics>('physics', physics, showName: false, defaultValue: null));
    properties.add(FlagProperty('shrinkWrap', value: shrinkWrap, ifTrue: 'shrink-wrapping', showName: true));
    properties.add(DiagnosticsProperty<ScrollCacheExtent>('scrollCacheExtent', scrollCacheExtent, defaultValue: null));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('minimum', minimum, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(FlagProperty('rowInsets', value: rowInsets, ifFalse: 'no row insets'));
    properties.add(FlagProperty('bars', value: bars, ifFalse: 'bars not cleared'));
    properties.add(FlagProperty('keyboard', value: keyboard, ifFalse: 'keyboard ignored'));
    properties.add(DoubleProperty('revealMargin', revealMargin, defaultValue: 0.0));
    properties.add(FlagProperty('edgeEffects', value: edgeEffects, ifFalse: 'no edge effects'));
    properties.add(FlagProperty('startsUnderBars', value: startsUnderBars, ifTrue: 'starts under bars'));
    properties.add(
      EnumProperty<ScrollViewKeyboardDismissBehavior>(
        'keyboardDismissBehavior',
        keyboardDismissBehavior,
        defaultValue: null,
      ),
    );
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior, defaultValue: Clip.hardEdge));
    properties.add(IntProperty('semanticChildCount', semanticChildCount, defaultValue: null));
  }

  /// The scroll padding a third-party list should use to keep clear as this
  /// scroll view does: clearance at both ends along [axis], at least [minimum], plus
  /// [extra]. Mark the same edges handled beneath it with [HarborHandled]
  /// (`bars: false` where [bars] is false, and `keyboard: true` unless [keyboard] is
  /// false).
  static EdgeInsets paddingOf(
    final BuildContext context, {
    final Axis axis = Axis.vertical,
    final EdgeInsetsGeometry extra = EdgeInsetsDirectional.zero,
    final EdgeInsetsGeometry minimum = EdgeInsetsDirectional.zero,
    final bool rowInsets = true,
    @Deprecated('Renamed rowInsets. `dart fix` applies it.') final bool? mooringLine,
    final bool bars = true,
    final bool keyboard = true,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final bool? tide,
  }) {
    final bool insetsRows = mooringLine ?? rowInsets;
    final bool clearsKeyboard = tide ?? keyboard;
    final TextDirection direction = Directionality.of(context);
    final EdgeInsetsDirectional extraHere = HarborEdges.resolve(extra, direction);
    final EdgeInsetsDirectional minimumHere = HarborEdges.resolve(minimum, direction);
    double end(final HarborEdge edge) {
      double value = _endClearance(context, edge, bars: bars, keyboard: clearsKeyboard);
      if (!edge.isVertical && insetsRows) {
        value += HarborEdges.of(HarborRoom.of(context, aspect: HarborRoomAspect.margin).margin, edge);
      }
      return math.max(value, HarborEdges.of(minimumHere, edge)) + HarborEdges.of(extraHere, edge);
    }

    final EdgeInsetsDirectional padding = axis == Axis.vertical
        ? EdgeInsetsDirectional.only(
            top: end(HarborEdge.top),
            bottom: end(HarborEdge.bottom),
            start: extraHere.start,
            end: extraHere.end,
          )
        : EdgeInsetsDirectional.only(
            start: end(HarborEdge.start),
            end: end(HarborEdge.end),
            top: extraHere.top,
            bottom: extraHere.bottom,
          );
    return padding.resolve(direction);
  }

  @override
  Widget build(final BuildContext context) {
    assert(
      center == null || slivers.where((final Widget s) => s.key == center).length == 1,
      'A HarborScrollView center must be the key of exactly one of its slivers.',
    );
    final TextDirection direction = Directionality.of(context);
    final EdgeInsetsDirectional padding = HarborEdges.resolve(this.padding, direction);
    final EdgeInsetsDirectional minimum = HarborEdges.resolve(this.minimum, direction);
    // The bars carry the edge effects; the system edges and the margin are read only where
    // they are used, so a carousel does not rebuild as the keyboard moves.
    final HarborRoomData waters = HarborRoom.of(context, aspect: HarborRoomAspect.bars);
    EdgeInsetsDirectional systemEdges() => HarborRoom.of(context, aspect: HarborRoomAspect.systemEdges).systemEdges;
    final bool vertical = scrollDirection == Axis.vertical;
    final HarborEdge leadingEdge = vertical
        ? (reverse ? HarborEdge.bottom : HarborEdge.top)
        : (reverse ? HarborEdge.end : HarborEdge.start);
    double clearance(final HarborEdge edge, final bool bars) {
      double value = _endClearance(context, edge, bars: bars, keyboard: keyboard);
      if (!vertical && rowInsets) {
        value += HarborEdges.of(HarborRoom.of(context, aspect: HarborRoomAspect.margin).margin, edge);
      }
      return math.max(value, HarborEdges.of(minimum, edge)) + HarborEdges.of(padding, edge);
    }

    // Where each end rests, and (`All`) what is over the viewport there, which the cover and
    // reveals keep clear of whatever the ends clear.
    final double clearLeading = clearance(leadingEdge, bars);
    final double clearLeadingAll = bars ? clearLeading : clearance(leadingEdge, true);
    double leading = clearLeading;
    double leadingAll = clearLeadingAll;
    final double trailing = clearance(leadingEdge.opposite, bars);
    final double trailingAll = bars ? trailing : clearance(leadingEdge.opposite, true);

    // A sliver bar first in the scroll view takes the system edge on the leading edge
    // itself, so its surface runs under the status bar.
    final bool leadsWithDock = slivers.isNotEmpty && slivers.first is HarborSliverBar && leadingEdge == HarborEdge.top;
    double absorbed = 0.0;
    if (leadsWithDock && HarborEdges.of(waters.bars, HarborEdge.top) <= 0) {
      absorbed = math.min(leading, HarborEdges.of(systemEdges(), HarborEdge.top));
      leading -= absorbed;
      leadingAll -= absorbed;
    }

    // How far pinned slivers stay from the leading edge: the bars' face,
    // not the end of their fade.
    final HarborFadeBand? band = waters.edgeEffects[leadingEdge];
    double cover = band == null
        ? leadingAll
        : math.max(
            HarborRoom.clearanceOf(context, leadingEdge, keyboard: keyboard) - band.length,
            HarborEdges.of(systemEdges(), leadingEdge),
          );
    cover = math.max(0.0, math.min(cover, leadingAll + absorbed) - absorbed);

    final Set<HarborEdge> handled = vertical ? HarborEdge.vertical : HarborEdge.horizontal;
    final EdgeInsetsDirectional crossPadding = vertical
        ? EdgeInsetsDirectional.only(start: padding.start, end: padding.end)
        : EdgeInsetsDirectional.only(top: padding.top, bottom: padding.bottom);

    // A pinned sliver bar takes over the leading edge, so the scroll view's edge effect
    // there would only fade the bar.
    final bool hasSliverDock = slivers.any((final Widget s) => s is HarborSliverBar);
    final Map<HarborEdge, HarborFadeBand> bands = !edgeEffects
        ? const <HarborEdge, HarborFadeBand>{}
        : <HarborEdge, HarborFadeBand>{
            for (final HarborEdge e in handled)
              if (waters.edgeEffects.containsKey(e) &&
                  !waters.edgeEffectsPainted.contains(e) &&
                  !(hasSliverDock && e == leadingEdge))
                e: waters.edgeEffects[e]!,
          };
    final Widget fairway = HarborFadeMask(
      edgeEffects: bands,
      child: _fairway(
        context,
        leadingEdge,
        vertical,
        // Starting under the bars skips only the clearance at the leading end: the caller's own padding and
        // minimum there still apply (#74).
        startsUnderBars ? HarborEdges.of(minimum, leadingEdge) + HarborEdges.of(padding, leadingEdge) : leading,
        clearLeading,
        cover,
        trailing,
        (
          leading: revealMargin + math.max(0.0, leadingAll - cover),
          reverseLeading: revealMargin + clearLeadingAll,
          trailing: revealMargin + trailingAll,
        ),
        absorbed,
        leadsWithDock,
        crossPadding,
        direction,
      ),
    );
    if (!_hugsChild) {
      return fairway;
    }
    return _HarborCrossAxisHug(
      scrollDirection: scrollDirection,
      crossPadding: vertical ? crossPadding.horizontal : crossPadding.vertical,
      child: fairway,
    );
  }

  Widget _fairway(
    final BuildContext context,
    final HarborEdge leadingEdge,
    final bool vertical,
    final double leading,
    final double clearLeading,
    final double cover,
    final double trailing,
    final ({double leading, double reverseLeading, double trailing}) reveals,
    final double absorbed,
    final bool leadsWithDock,
    final EdgeInsetsDirectional crossPadding,
    final TextDirection direction,
  ) {
    final AxisDirection axis = vertical
        ? (reverse ? AxisDirection.up : AxisDirection.down)
        : textDirectionToAxisDirection(direction) == AxisDirection.right
        ? (reverse ? AxisDirection.left : AxisDirection.right)
        : (reverse ? AxisDirection.right : AxisDirection.left);
    // Every reveal (a focused field, focus traversal, ensureVisible) is widened
    // by what covers the trailing edge, and by the fade past the leading
    // bars' face, so the row comes to rest in the room.
    final double trailExtra = reveals.trailing;
    EdgeInsets reveal(final double leadExtra) => switch (axis) {
      AxisDirection.down => EdgeInsets.only(top: leadExtra, bottom: trailExtra),
      AxisDirection.up => EdgeInsets.only(top: trailExtra, bottom: leadExtra),
      AxisDirection.right => EdgeInsets.only(left: leadExtra, right: trailExtra),
      AxisDirection.left => EdgeInsets.only(left: trailExtra, right: leadExtra),
    };
    Widget first(final Widget sliver) {
      final Widget result = leadsWithDock ? _SliverDockAbsorb(systemEdges: absorbed, child: sliver) : sliver;
      // Content that starts under the bars keeps the system edges and bars it starts under, on the
      // leading end alone: the trailing end and the keyboard are still handled.
      return startsUnderBars ? _HarborOpenWaterSliver(sliver: result) : result;
    }

    // With a center, the cover leads the slivers that grow forward from it,
    // and anchor 0 rests the center where the first sliver would rest.
    final Widget coverSliver = _HarborCoverSliver(
      key: _coverKey,
      extent: cover,
      fromViewportEdge: !shrinkWrap && (center != null || anchor != 0.0),
    );
    final bool centersFirst = center != null && slivers.first.key == center;
    // The trailing end is handled first and the leading end beneath it, so the first sliver of a
    // scroll view that starts under the bars can be handed the view between the two.
    final bool margin = !vertical && rowInsets;
    return HarborHandled(
      edges: <HarborEdge>{leadingEdge.opposite},
      keyboard: vertical && keyboard,
      margin: margin,
      bars: bars,
      child: _HarborOpenWaterView(
        enabled: startsUnderBars,
        child: HarborHandled(
          edges: <HarborEdge>{leadingEdge},
          margin: margin,
          bars: bars,
          child: _HarborScrollView(
            reveal: reveal(reveals.leading),
            reverseReveal: reveal(reveals.reverseLeading),
            anchorLeading: center == null ? 0.0 : (centersFirst ? leading : clearLeading),
            anchorTrailing: center == null ? leading + trailing : trailing,
            scrollDirection: scrollDirection,
            reverse: reverse,
            controller: controller,
            primary: primary,
            physics: physics,
            scrollBehavior: scrollBehavior,
            shrinkWrap: shrinkWrap,
            center: center == null ? null : _coverKey,
            anchor: anchor,
            scrollCacheExtent: scrollCacheExtent,
            paintOrder: paintOrder,
            semanticChildCount: semanticChildCount,
            dragStartBehavior: dragStartBehavior,
            keyboardDismissBehavior: keyboardDismissBehavior,
            restorationId: restorationId,
            clipBehavior: clipBehavior,
            hitTestBehavior: hitTestBehavior,
            slivers: <Widget>[
              if (center == null) coverSliver,
              SliverToBoxAdapter(
                child: SizedBox(width: vertical ? null : leading, height: vertical ? leading : null),
              ),
              for (int i = 0; i < slivers.length; i++) ...<Widget>[
                if (center != null && slivers[i].key == center) coverSliver,
                SliverPadding(
                  key: switch (slivers[i].key) {
                    final Key key => _HarborSliverKey(key),
                    null => null,
                  },
                  padding: crossPadding.resolve(direction),
                  sliver: i == 0 ? first(slivers[i]) : slivers[i],
                ),
              ],
              SliverToBoxAdapter(
                child: SizedBox(width: vertical ? null : trailing, height: vertical ? trailing : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Publishes, to the first sliver of a scroll view that starts under the bars, the view between
/// the scroll view's two [HarborHandled]s: its leading end still there, its trailing end, the
/// keyboard and the trailing row insets already handled.
///
/// It is in the tree either way, so turning [enabled] on or off keeps the scroll view's state;
/// only while it is on does it depend on what it publishes.
class _HarborOpenWaterView extends StatelessWidget {
  const _HarborOpenWaterView({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(final BuildContext context) => _HarborOpenWaterScope(
    media: enabled ? MediaQuery.of(context) : null,
    waters: enabled ? HarborRoom.maybeRawOf(context) : null,
    child: child,
  );
}

class _HarborOpenWaterScope extends InheritedWidget {
  const _HarborOpenWaterScope({required this.media, required this.waters, required super.child});

  final MediaQueryData? media;
  final HarborRoomData? waters;

  @override
  bool updateShouldNotify(final _HarborOpenWaterScope oldWidget) =>
      media != oldWidget.media || waters != oldWidget.waters;
}

/// The first sliver of a scroll view that starts under the bars, in the view [_HarborOpenWaterView]
/// publishes.
class _HarborOpenWaterSliver extends StatelessWidget {
  const _HarborOpenWaterSliver({required this.sliver});

  final Widget sliver;

  @override
  Widget build(final BuildContext context) {
    final _HarborOpenWaterScope? scope = context.dependOnInheritedWidgetOfExactType<_HarborOpenWaterScope>();
    final MediaQueryData? media = scope?.media;
    if (media == null) {
      return sliver;
    }
    final HarborRoomData? waters = scope!.waters;
    return MediaQuery(
      data: media,
      child: waters == null ? sliver : HarborRoom(data: waters, child: sliver),
    );
  }
}

const Key _coverKey = _HarborCoverKey();

class _HarborCoverKey extends LocalKey {
  const _HarborCoverKey();
}

/// The key of the sliver a scroll view wraps around one of yours that has a key,
/// so a center names it and keyed slivers keep their state as they move.
class _HarborSliverKey extends LocalKey {
  const _HarborSliverKey(this.key);

  final Key key;

  @override
  bool operator ==(final Object other) => other is _HarborSliverKey && other.key == key;

  @override
  int get hashCode => Object.hash(_HarborSliverKey, key);
}

/// A `CustomScrollView` whose viewport widens every reveal by [reveal].
class _HarborScrollView extends CustomScrollView {
  const _HarborScrollView({
    required this.reveal,
    required this.reverseReveal,
    required this.anchorLeading,
    required this.anchorTrailing,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    super.shrinkWrap,
    super.center,
    super.anchor,
    super.scrollCacheExtent,
    super.paintOrder,
    super.slivers,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
  });

  final EdgeInsets reveal;

  /// [reveal] for the slivers before the center, which the cover does not reach.
  final EdgeInsets reverseReveal;

  /// How far from the leading and trailing edges an anchor of 0 and of 1 put
  /// the zero scroll offset.
  final double anchorLeading;
  final double anchorTrailing;

  @override
  Widget buildViewport(
    final BuildContext context,
    final ViewportOffset offset,
    final AxisDirection axisDirection,
    final List<Widget> slivers,
  ) {
    if (shrinkWrap) {
      return _HarborShrinkWrappingViewport(
        reveal: reveal,
        axisDirection: axisDirection,
        offset: offset,
        slivers: slivers,
        paintOrder: paintOrder,
        clipBehavior: clipBehavior,
        scrollCacheExtent: scrollCacheExtent,
      );
    }
    return _HarborViewport(
      reveal: reveal,
      reverseReveal: reverseReveal,
      anchorLeading: anchorLeading,
      anchorTrailing: anchorTrailing,
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      paintOrder: paintOrder,
      clipBehavior: clipBehavior,
      scrollCacheExtent: scrollCacheExtent,
      center: center,
      anchor: anchor,
    );
  }
}

class _HarborViewport extends Viewport {
  _HarborViewport({
    required this.reveal,
    required this.reverseReveal,
    required this.anchorLeading,
    required this.anchorTrailing,
    required super.axisDirection,
    required super.offset,
    super.slivers,
    super.paintOrder,
    super.clipBehavior,
    super.scrollCacheExtent,
    super.center,
    super.anchor,
  });

  final EdgeInsets reveal;
  final EdgeInsets reverseReveal;
  final double anchorLeading;
  final double anchorTrailing;

  @override
  RenderViewport createRenderObject(final BuildContext context) => _RenderHarborViewport(
    reveal: reveal,
    reverseReveal: reverseReveal,
    anchorLeading: anchorLeading,
    anchorTrailing: anchorTrailing,
    axisDirection: axisDirection,
    crossAxisDirection: crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
    anchor: anchor,
    offset: offset,
    scrollCacheExtent: scrollCacheExtent,
    paintOrder: paintOrder,
    clipBehavior: clipBehavior,
  );

  @override
  void updateRenderObject(final BuildContext context, final RenderViewport renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderHarborViewport)
      ..reveal = reveal
      ..reverseReveal = reverseReveal
      ..anchorLeading = anchorLeading
      ..anchorTrailing = anchorTrailing;
  }
}

class _RenderHarborViewport extends RenderViewport {
  _RenderHarborViewport({
    required this.reveal,
    required this.reverseReveal,
    required this._anchorLeading,
    required this._anchorTrailing,
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor,
    super.scrollCacheExtent,
    super.paintOrder,
    super.clipBehavior,
  });

  EdgeInsets reveal;
  EdgeInsets reverseReveal;

  double _anchorLeading;
  set anchorLeading(final double value) {
    if (_anchorLeading != value) {
      _anchorLeading = value;
      markNeedsLayout();
    }
  }

  double _anchorTrailing;
  set anchorTrailing(final double value) {
    if (_anchorTrailing != value) {
      _anchorTrailing = value;
      markNeedsLayout();
    }
  }

  // The viewport runs under the bars, so the anchor it lays out by is the
  // scroll view's anchor taken across the room between them.
  @override
  double get anchor {
    final double extent = hasSize ? (axis == Axis.vertical ? size.height : size.width) : 0.0;
    if (extent <= 0.0) {
      return super.anchor;
    }
    final double water = math.max(0.0, extent - _anchorLeading - _anchorTrailing);
    return ((_anchorLeading + super.anchor * water) / extent).clamp(0.0, 1.0);
  }

  @override
  RevealedOffset getOffsetToReveal(
    final RenderObject target,
    final double alignment, {
    final Rect? rect,
    final Axis? axis,
  }) {
    RenderObject? sliver = target;
    while (sliver != null && sliver.parent != this) {
      sliver = sliver.parent;
    }
    final bool beforeCenter = sliver is RenderSliver && sliver.constraints.growthDirection == GrowthDirection.reverse;
    final Rect widened = _widen(rect ?? target.paintBounds, beforeCenter ? reverseReveal : reveal);
    final RevealedOffset revealed = super.getOffsetToReveal(target, alignment, rect: widened, axis: axis);
    // RenderViewport reveals as if the zero scroll offset were at its leading
    // edge, wherever the anchor puts it.
    final double zero = anchor * (this.axis == Axis.vertical ? size.height : size.width);
    if (zero == 0.0 || !revealed.offset.isFinite) {
      return revealed;
    }
    final Offset shift = switch (axisDirection) {
      AxisDirection.down => Offset(0.0, -zero),
      AxisDirection.up => Offset(0.0, zero),
      AxisDirection.right => Offset(-zero, 0.0),
      AxisDirection.left => Offset(zero, 0.0),
    };
    return RevealedOffset(offset: revealed.offset + zero, rect: revealed.rect.shift(shift));
  }
}

class _HarborShrinkWrappingViewport extends ShrinkWrappingViewport {
  const _HarborShrinkWrappingViewport({
    required this.reveal,
    required super.axisDirection,
    required super.offset,
    super.slivers,
    super.paintOrder,
    super.clipBehavior,
    super.scrollCacheExtent,
  });

  final EdgeInsets reveal;

  @override
  RenderShrinkWrappingViewport createRenderObject(final BuildContext context) => _RenderHarborShrinkWrappingViewport(
    reveal: reveal,
    axisDirection: axisDirection,
    crossAxisDirection: crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
    offset: offset,
    paintOrder: paintOrder,
    clipBehavior: clipBehavior,
    scrollCacheExtent: scrollCacheExtent,
  );

  @override
  void updateRenderObject(final BuildContext context, final RenderShrinkWrappingViewport renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderHarborShrinkWrappingViewport).reveal = reveal;
  }
}

class _RenderHarborShrinkWrappingViewport extends RenderShrinkWrappingViewport {
  _RenderHarborShrinkWrappingViewport({
    required this.reveal,
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.paintOrder,
    super.clipBehavior,
    super.scrollCacheExtent,
  });

  EdgeInsets reveal;

  @override
  RevealedOffset getOffsetToReveal(
    final RenderObject target,
    final double alignment, {
    final Rect? rect,
    final Axis? axis,
  }) => super.getOffsetToReveal(target, alignment, rect: _widen(rect ?? target.paintBounds, reveal), axis: axis);

  // A shrink-wrapped viewport is as long as its slivers' paint. The cover only
  // paints to hand its overlap to the slivers after it, and the spacer behind
  // it already holds that ground, so it adds no length of its own.
  @override
  void updateOutOfBandData(final GrowthDirection growthDirection, final SliverGeometry childLayoutGeometry) {
    final RenderSliver? cover = firstChild;
    if (cover is _RenderHarborCoverSliver && identical(childLayoutGeometry, cover.geometry)) {
      super.updateOutOfBandData(
        growthDirection,
        SliverGeometry(hasVisualOverflow: childLayoutGeometry.hasVisualOverflow),
      );
      return;
    }
    super.updateOutOfBandData(growthDirection, childLayoutGeometry);
  }
}

Rect _widen(final Rect rect, final EdgeInsets by) =>
    Rect.fromLTRB(rect.left - by.left, rect.top - by.top, rect.right + by.right, rect.bottom + by.bottom);

/// Gives a box scroll view its cross-axis size from its child when its parent
/// leaves that axis unbounded. A viewport cannot be measured by what it holds,
/// so this asks the child, through [_HarborHugTarget], for its intrinsic size.
class _HarborCrossAxisHug extends SingleChildRenderObjectWidget {
  const _HarborCrossAxisHug({required this.scrollDirection, required this.crossPadding, required super.child});

  final Axis scrollDirection;

  /// The scroll view's own padding across the scroll, added to the child's size.
  final double crossPadding;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderHarborCrossAxisHug(scrollDirection, crossPadding);

  @override
  void updateRenderObject(final BuildContext context, final _RenderHarborCrossAxisHug renderObject) {
    renderObject
      ..scrollDirection = scrollDirection
      ..crossPadding = crossPadding;
  }
}

class _RenderHarborCrossAxisHug extends RenderProxyBox {
  _RenderHarborCrossAxisHug(this._scrollDirection, this._crossPadding);

  Axis _scrollDirection;
  set scrollDirection(final Axis value) {
    if (_scrollDirection != value) {
      _scrollDirection = value;
      markNeedsLayout();
    }
  }

  double _crossPadding;
  set crossPadding(final double value) {
    if (_crossPadding != value) {
      _crossPadding = value;
      markNeedsLayout();
    }
  }

  _RenderHarborHugTarget? target;
  bool _layingOut = false;

  // The viewport between this and the target is a relayout boundary, so a
  // target that changes size cannot reach this through its parents.
  void targetChanged() {
    if (!_layingOut) {
      markNeedsLayout();
    }
  }

  double? _crossExtent() {
    final RenderBox? target = this.target;
    if (target == null) {
      return null;
    }
    final double content = _scrollDirection == Axis.horizontal
        ? target.getMaxIntrinsicHeight(double.infinity)
        : target.getMaxIntrinsicWidth(double.infinity);
    return content + _crossPadding;
  }

  @override
  double computeMinIntrinsicHeight(final double width) =>
      _scrollDirection == Axis.horizontal ? (_crossExtent() ?? 0.0) : super.computeMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(final double width) =>
      _scrollDirection == Axis.horizontal ? (_crossExtent() ?? 0.0) : super.computeMaxIntrinsicHeight(width);

  @override
  double computeMinIntrinsicWidth(final double height) =>
      _scrollDirection == Axis.vertical ? (_crossExtent() ?? 0.0) : super.computeMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(final double height) =>
      _scrollDirection == Axis.vertical ? (_crossExtent() ?? 0.0) : super.computeMaxIntrinsicWidth(height);

  @override
  void performLayout() {
    final RenderBox child = this.child!;
    final bool horizontal = _scrollDirection == Axis.horizontal;
    final bool bounded = horizontal ? constraints.hasBoundedHeight : constraints.hasBoundedWidth;
    _layingOut = true;
    try {
      final double? cross = bounded ? null : _crossExtent();
      final BoxConstraints given = cross == null
          ? constraints
          : horizontal
          ? constraints.tighten(height: constraints.constrainHeight(cross))
          : constraints.tighten(width: constraints.constrainWidth(cross));
      child.layout(given, parentUsesSize: true);
      size = child.size;
    } finally {
      _layingOut = false;
    }
  }
}

/// Marks the box a [_HarborCrossAxisHug] measures, and tells it when that box
/// needs laying out again.
class _HarborHugTarget extends SingleChildRenderObjectWidget {
  const _HarborHugTarget({required super.child});

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderHarborHugTarget()..hug = context.findAncestorRenderObjectOfType<_RenderHarborCrossAxisHug>();

  @override
  void updateRenderObject(final BuildContext context, final _RenderHarborHugTarget renderObject) {
    renderObject.hug = context.findAncestorRenderObjectOfType<_RenderHarborCrossAxisHug>();
  }
}

class _RenderHarborHugTarget extends RenderProxyBox {
  _RenderHarborCrossAxisHug? _hug;
  set hug(final _RenderHarborCrossAxisHug? value) {
    if (identical(_hug, value)) {
      return;
    }
    if (identical(_hug?.target, this)) {
      _hug!.target = null;
    }
    _hug = value?..target = this;
  }

  @override
  void markNeedsLayout() {
    super.markNeedsLayout();
    _hug?.targetChanged();
  }

  @override
  void dispose() {
    hug = null;
    super.dispose();
  }
}

/// The old name of [HarborScrollView], whose constructors keep their names.
///
/// A subclass rather than a typedef: `dart fix` renames the arguments of `box(tide:, ...)`, and a
/// typedef cannot carry a fix on a named constructor's call.
@Deprecated('Renamed HarborScrollView. `dart fix` applies it.')
class HarborFairway extends HarborScrollView {
  /// The old name of [HarborScrollView.new].
  @Deprecated('Renamed HarborScrollView. `dart fix` applies it.')
  const HarborFairway({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    super.shrinkWrap,
    super.center,
    super.anchor,
    super.padding,
    super.minimum,
    super.rowInsets,
    @Deprecated('Renamed rowInsets. `dart fix` applies it.') super.mooringLine,
    super.bars,
    super.keyboard,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') super.tide,
    super.revealMargin,
    super.edgeEffects,
    @Deprecated('Renamed edgeEffects. `dart fix` applies it.') super.wake,
    super.startsUnderBars,
    @Deprecated('Renamed startsUnderBars. `dart fix` applies it.') super.startsInOpenWater,
    super.scrollCacheExtent,
    super.paintOrder,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    required super.slivers,
  });

  /// The old name of [HarborScrollView.box].
  @Deprecated('Renamed HarborScrollView.box. `dart fix` applies it.')
  HarborFairway.box({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    super.shrinkWrap,
    super.padding,
    super.minimum,
    super.rowInsets,
    @Deprecated('Renamed rowInsets. `dart fix` applies it.') super.mooringLine,
    super.bars,
    super.keyboard,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') super.tide,
    super.revealMargin,
    super.edgeEffects,
    @Deprecated('Renamed edgeEffects. `dart fix` applies it.') super.wake,
    super.startsUnderBars,
    @Deprecated('Renamed startsUnderBars. `dart fix` applies it.') super.startsInOpenWater,
    super.scrollCacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    required super.child,
  }) : super.box();

  /// The old name of [HarborScrollView.paddingOf].
  @Deprecated('Renamed HarborScrollView.paddingOf. `dart fix` applies it.')
  static EdgeInsets paddingOf(
    final BuildContext context, {
    final Axis axis = Axis.vertical,
    final EdgeInsetsGeometry extra = EdgeInsetsDirectional.zero,
    final EdgeInsetsGeometry minimum = EdgeInsetsDirectional.zero,
    final bool rowInsets = true,
    @Deprecated('Renamed rowInsets. `dart fix` applies it.') final bool? mooringLine,
    final bool bars = true,
    final bool keyboard = true,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final bool? tide,
  }) => HarborScrollView.paddingOf(
    context,
    axis: axis,
    extra: extra,
    minimum: minimum,
    rowInsets: mooringLine ?? rowInsets,
    bars: bars,
    keyboard: tide ?? keyboard,
  );
}

/// One sliver of a scroll view you build yourself, kept clear at the ends you
/// choose. Use it on the sliver at each end of a `CustomScrollView`; a whole
/// scroll view is better as a [HarborScrollView].
///
/// It marks the ends it cleared handled, as `SliverSafeArea` removes the padding it
/// applied, so a `SafeArea` or a `MediaQuery.padding` reader in [sliver] does
/// not clear them a second time. An end it does not clear is left as it is.
///
/// See also:
///
///  * [SliverSafeArea], the closest Flutter widget, which keeps clear of `MediaQuery.padding` alone.
class HarborSliverClear extends StatelessWidget {
  const HarborSliverClear({
    super.key,
    this.clearLeading = true,
    this.clearTrailing = true,
    this.bars = true,
    final bool keyboard = true,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final bool? tide,
    this.padding = EdgeInsetsDirectional.zero,
    this.minimum = EdgeInsetsDirectional.zero,
    required this.sliver,
  }) : keyboard = tide ?? keyboard;

  final bool clearLeading;
  final bool clearTrailing;

  /// Whether the ends it clears keep clear of the bars as well as the system edges, as
  /// on [HarborScrollView.bars]: false handles the system edges alone, keeps the
  /// keyboard while [keyboard], and reveals still keep clear of everything over the
  /// viewport.
  final bool bars;

  /// Whether a bottom end it clears keeps clear of the keyboard, and marks it
  /// handled, as on [HarborScrollView.keyboard].
  final bool keyboard;

  /// The old name of [keyboard].
  @Deprecated('Renamed keyboard. `dart fix` applies it.')
  bool get tide => keyboard;
  final EdgeInsetsGeometry padding;

  /// A floor on the clearance at each end it clears, as on [HarborScrollView.minimum].
  final EdgeInsetsGeometry minimum;
  final Widget sliver;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('clearLeading', value: clearLeading, ifFalse: 'leading end not cleared'));
    properties.add(FlagProperty('clearTrailing', value: clearTrailing, ifFalse: 'trailing end not cleared'));
    properties.add(FlagProperty('bars', value: bars, ifFalse: 'bars not cleared'));
    properties.add(FlagProperty('keyboard', value: keyboard, ifFalse: 'keyboard ignored'));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('minimum', minimum, defaultValue: EdgeInsetsDirectional.zero),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final AxisDirection axis = Scrollable.maybeOf(context)?.axisDirection ?? AxisDirection.down;
    final TextDirection direction = Directionality.of(context);
    final (HarborEdge leadingEdge, HarborEdge trailingEdge) = switch (axis) {
      AxisDirection.down => (HarborEdge.top, HarborEdge.bottom),
      AxisDirection.up => (HarborEdge.bottom, HarborEdge.top),
      AxisDirection.right =>
        direction == TextDirection.ltr ? (HarborEdge.start, HarborEdge.end) : (HarborEdge.end, HarborEdge.start),
      AxisDirection.left =>
        direction == TextDirection.ltr ? (HarborEdge.end, HarborEdge.start) : (HarborEdge.start, HarborEdge.end),
    };
    final EdgeInsetsDirectional padding = HarborEdges.resolve(this.padding, direction);
    final EdgeInsetsDirectional minimum = HarborEdges.resolve(this.minimum, direction);
    double clearance(final HarborEdge edge, final bool bars) =>
        math.max(_endClearance(context, edge, bars: bars, keyboard: keyboard), HarborEdges.of(minimum, edge));
    final double leading = clearLeading ? clearance(leadingEdge, bars) : 0.0;
    final double trailing = clearTrailing ? clearance(trailingEdge, bars) : 0.0;
    // Reveals keep clear of everything over the viewport, whatever the ends clear.
    final double revealLeading = bars || !clearLeading ? leading : clearance(leadingEdge, true);
    final double revealTrailing = bars || !clearTrailing ? trailing : clearance(trailingEdge, true);
    final EdgeInsetsDirectional insets = HarborEdges.build((final HarborEdge e) {
      final double own = HarborEdges.of(padding, e);
      if (e == leadingEdge) {
        return leading + own;
      }
      if (e == trailingEdge) {
        return trailing + own;
      }
      return own;
    });
    // As `SliverSafeArea` pads and then removes that padding, the ends it cleared are handled, so a
    // reader in the sliver does not clear them again. An end it leaves is left to its content.
    final Set<HarborEdge> cleared = <HarborEdge>{if (clearLeading) leadingEdge, if (clearTrailing) trailingEdge};
    return _HarborRevealSliver(
      leading: revealLeading,
      trailing: revealTrailing,
      textDirection: direction,
      sliver: SliverPadding(
        padding: insets.resolve(direction),
        sliver: HarborHandled(
          edges: cleared,
          keyboard: keyboard && cleared.contains(HarborEdge.bottom),
          margin: false,
          bars: bars,
          child: sliver,
        ),
      ),
    );
  }
}

/// A bar that lives in a [HarborScrollView]: a header that scrolls with the content and
/// then pins, clear of the bars above it, and becomes a bar for everything
/// after it. The first one in a scroll view with no bar above takes the status
/// bar itself, so its [backdrop] runs under it. Several stack.
///
/// It pins and stacks, but it is not a `SliverAppBar`: it has no `expandedHeight` and no
/// `flexibleSpace`.
///
/// See also:
///
///  * [PinnedHeaderSliver], which this pins with, and `SliverAppBar(pinned: true)`.
class HarborSliverBar extends StatelessWidget {
  const HarborSliverBar({super.key, required this.child, this.backdrop, this.hitTestBehavior = HitTestBehavior.opaque});

  final Widget child;
  final Widget? backdrop;
  final HitTestBehavior hitTestBehavior;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Widget>.has('backdrop', backdrop));
    properties.add(
      EnumProperty<HitTestBehavior>('hitTestBehavior', hitTestBehavior, defaultValue: HitTestBehavior.opaque),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final double systemEdges = _SliverDockAbsorb.coastOf(context);
    return PinnedHeaderSliver(
      child: Listener(
        behavior: hitTestBehavior,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: backdrop ?? const SizedBox.shrink()),
            Padding(
              padding: EdgeInsets.only(top: systemEdges),
              child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverDockAbsorb extends InheritedWidget {
  const _SliverDockAbsorb({required this.systemEdges, required super.child});

  final double systemEdges;

  static double coastOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SliverDockAbsorb>()?.systemEdges ?? 0.0;

  @override
  bool updateShouldNotify(final _SliverDockAbsorb oldWidget) => systemEdges != oldWidget.systemEdges;
}

/// Widens every reveal that passes through it by what covers the scroll
/// view's edges, so the viewport brings the row clear of the bars rather
/// than merely onto the screen.
class _HarborRevealSliver extends SingleChildRenderObjectWidget {
  const _HarborRevealSliver({
    required this.leading,
    required this.trailing,
    required this.textDirection,
    required Widget sliver,
  }) : super(child: sliver);

  final double leading;
  final double trailing;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderHarborRevealSliver(leading, trailing);

  @override
  void updateRenderObject(final BuildContext context, final _RenderHarborRevealSliver renderObject) {
    renderObject
      ..leading = leading
      ..trailing = trailing;
  }
}

class _RenderHarborRevealSliver extends RenderProxySliver {
  _RenderHarborRevealSliver(this.leading, this.trailing);

  double leading;
  double trailing;

  @override
  void showOnScreen({
    final RenderObject? descendant,
    final Rect? rect,
    final Duration duration = Duration.zero,
    final Curve curve = Curves.ease,
  }) {
    if (descendant == null || (leading <= 0 && trailing <= 0)) {
      super.showOnScreen(descendant: descendant, rect: rect, duration: duration, curve: curve);
      return;
    }
    // Widened in the descendant's own coordinates, which run the way the
    // screen does, and handed on with the descendant so the viewport measures
    // it from where the descendant really is.
    final Rect local = rect ?? descendant.paintBounds;
    final Rect widened = switch (applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    )) {
      AxisDirection.down => Rect.fromLTRB(local.left, local.top - leading, local.right, local.bottom + trailing),
      AxisDirection.up => Rect.fromLTRB(local.left, local.top - trailing, local.right, local.bottom + leading),
      AxisDirection.right => Rect.fromLTRB(local.left - leading, local.top, local.right + trailing, local.bottom),
      AxisDirection.left => Rect.fromLTRB(local.left - trailing, local.top, local.right + leading, local.bottom),
    };
    super.showOnScreen(descendant: descendant, rect: widened, duration: duration, curve: curve);
  }
}

/// Covers the leading edge of a scroll view without taking any scroll space: it
/// tells the slivers after it how far the bars reach, so pinned headers pin
/// at the bars' face and reveals keep clear of them.
class _HarborCoverSliver extends LeafRenderObjectWidget {
  const _HarborCoverSliver({super.key, required this.extent, required this.fromViewportEdge});

  final double extent;

  /// Whether the cover may start inside the viewport, as it does at a center
  /// or an anchor, and must reach only as far as the bars do from its edge.
  final bool fromViewportEdge;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderHarborCoverSliver(extent, fromViewportEdge);

  @override
  void updateRenderObject(final BuildContext context, final _RenderHarborCoverSliver renderObject) {
    renderObject
      ..extent = extent
      ..fromViewportEdge = fromViewportEdge;
  }
}

class _RenderHarborCoverSliver extends RenderSliver {
  _RenderHarborCoverSliver(this._extent, this._fromViewportEdge);

  double _extent;
  set extent(final double value) {
    if (_extent != value) {
      _extent = value;
      markNeedsLayout();
    }
  }

  bool _fromViewportEdge;
  set fromViewportEdge(final bool value) {
    if (_fromViewportEdge != value) {
      _fromViewportEdge = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    // First in its run of slivers, it starts where the viewport has that much
    // paint extent left, as the viewport measures overlap.
    final double start = _fromViewportEdge
        ? constraints.viewportMainAxisExtent - constraints.remainingPaintExtent
        : 0.0;
    final double paint = (_extent - start).clamp(0.0, constraints.remainingPaintExtent);
    geometry = SliverGeometry(
      paintExtent: paint,
      layoutExtent: 0.0,
      cacheExtent: 0.0,
      maxPaintExtent: _extent,
      maxScrollObstructionExtent: _extent,
    );
  }

  @override
  bool hitTest(
    final SliverHitTestResult result, {
    required final double mainAxisPosition,
    required final double crossAxisPosition,
  }) => false;
}
