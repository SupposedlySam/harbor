import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'wake.dart';
import 'waters.dart';

/// A fairway: a scroll view whose viewport runs to the frame's edges, under
/// the docks, while its content comes to rest clear of them at both ends.
///
/// Vertical, it keeps clear of the top and bottom (the keyboard included) and
/// leaves the sides to its rows ([HarborMooringLine]) and to any horizontal
/// fairway inside it, so a carousel can still run to the frame's edge.
/// Horizontal, it keeps clear of the start and end plus the mooring line, at
/// both ends, and leaves the top and bottom alone.
///
/// [padding] is your own spacing and is added to the clearance, never in place
/// of it. A focused field, `Scrollable.ensureVisible` and focus traversal all
/// reveal a row clear of the docks: the fairway widens each reveal by what
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
class HarborFairway extends StatelessWidget {
  const HarborFairway({
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
    this.mooringLine = true,
    this.revealMargin = 0.0,
    this.wake = true,
    this.startsInOpenWater = false,
    this.scrollCacheExtent,
    this.paintOrder = SliverPaintOrder.firstIsTop,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    required this.slivers,
  }) : assert(!shrinkWrap || center == null),
       assert(anchor >= 0.0 && anchor <= 1.0),
       _hugsChild = false;

  /// A fairway with a single box [child].
  ///
  /// Where the cross axis is unbounded, as a horizontal fairway's height is in
  /// a `Column`, it is as thick as [child] (a row of chips as tall as the
  /// chips), the way a `SingleChildScrollView` is. [child] then needs an
  /// intrinsic size on that axis, as it would under `IntrinsicHeight`. Given a
  /// bounded cross axis it fills it, like any scroll view. [shrinkWrap] is the
  /// main axis.
  HarborFairway.box({
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
    this.mooringLine = true,
    this.revealMargin = 0.0,
    this.wake = true,
    this.startsInOpenWater = false,
    this.scrollCacheExtent,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.hitTestBehavior = HitTestBehavior.opaque,
    required final Widget child,
  }) : center = null,
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
  /// leading end. Each end of the scroll still rests clear of the docks there,
  /// and at rest the center sliver starts clear of the leading docks.
  ///
  /// Sliver docks after the center pin at the docks' face. Those before it
  /// grow the other way, so they pin at the trailing end of the viewport, as
  /// they would in a `CustomScrollView`, without keeping clear of the docks.
  final Key? center;

  /// Where the zero scroll offset sits, as a fraction of the water between the
  /// docks rather than of the whole viewport, which runs under them: 0 rests
  /// it clear of the leading docks, 1 at the face of the trailing docks (and
  /// the keyboard). Otherwise it is a `CustomScrollView`'s anchor.
  final double anchor;

  /// Your own spacing at each end and side, added to the clearance.
  final EdgeInsetsGeometry padding;

  /// A floor on each end's clearance, as `SafeArea.minimum` is: whatever is in
  /// the way there or this, whichever is larger, before [padding] is added.
  /// The bottom of a phone with a home button, where nothing covers the end.
  final EdgeInsetsGeometry minimum;

  /// For a horizontal fairway: whether the ends add the harbor's margin, so
  /// the first item at rest lines up with the rest of the page.
  final bool mooringLine;

  /// Extra room kept around a revealed row, beyond what covers the edge: a TV
  /// row that keeps the focused card a step in from the rail.
  final double revealMargin;

  /// Whether content fades out as it sails under a dock with a fade wake.
  final bool wake;

  /// Whether the first sliver starts at the frame's edge, under the docks, as
  /// a hero image that runs under a translucent header does. Pinned sliver
  /// docks still pin at the docks' face, and reveals still keep clear of them.
  final bool startsInOpenWater;

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
    properties.add(FlagProperty('mooringLine', value: mooringLine, ifFalse: 'no mooring line'));
    properties.add(DoubleProperty('revealMargin', revealMargin, defaultValue: 0.0));
    properties.add(FlagProperty('wake', value: wake, ifFalse: 'no wake'));
    properties.add(FlagProperty('startsInOpenWater', value: startsInOpenWater, ifTrue: 'starts in open water'));
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

  /// The scroll padding a third-party list should use to sail this fairway's
  /// way: clearance at both ends along [axis], at least [minimum], plus
  /// [extra]. Cast off the same edges beneath it with [HarborCastOff].
  static EdgeInsets paddingOf(
    final BuildContext context, {
    final Axis axis = Axis.vertical,
    final EdgeInsetsGeometry extra = EdgeInsetsDirectional.zero,
    final EdgeInsetsGeometry minimum = EdgeInsetsDirectional.zero,
    final bool mooringLine = true,
  }) {
    final TextDirection direction = Directionality.of(context);
    final EdgeInsetsDirectional extraHere = HarborEdges.resolve(extra, direction);
    final EdgeInsetsDirectional minimumHere = HarborEdges.resolve(minimum, direction);
    double end(final HarborEdge edge) {
      double value = HarborWaters.clearanceOf(context, edge);
      if (!edge.isVertical && mooringLine) {
        value += HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.margin).margin, edge);
      }
      return math.max(value, HarborEdges.of(minimumHere, edge)) + HarborEdges.of(extraHere, edge);
    }

    final EdgeInsetsDirectional padding = axis == Axis.vertical
        ? EdgeInsetsDirectional.only(top: end(HarborEdge.top), bottom: end(HarborEdge.bottom), start: extraHere.start, end: extraHere.end)
        : EdgeInsetsDirectional.only(start: end(HarborEdge.start), end: end(HarborEdge.end), top: extraHere.top, bottom: extraHere.bottom);
    return padding.resolve(direction);
  }

  @override
  Widget build(final BuildContext context) {
    assert(
      center == null || slivers.where((final Widget s) => s.key == center).length == 1,
      'A fairway center must be the key of exactly one of its slivers.',
    );
    final TextDirection direction = Directionality.of(context);
    final EdgeInsetsDirectional padding = HarborEdges.resolve(this.padding, direction);
    final EdgeInsetsDirectional minimum = HarborEdges.resolve(this.minimum, direction);
    // The docks carry the wakes; the coast and the margin are read only where
    // they are used, so a carousel does not rebuild as the keyboard moves.
    final HarborWatersData waters = HarborWaters.of(context, aspect: HarborWatersAspect.docks);
    EdgeInsetsDirectional coast() => HarborWaters.of(context, aspect: HarborWatersAspect.coast).coast;
    final bool vertical = scrollDirection == Axis.vertical;
    final HarborEdge leadingEdge = vertical
        ? (reverse ? HarborEdge.bottom : HarborEdge.top)
        : (reverse ? HarborEdge.end : HarborEdge.start);
    double clearance(final HarborEdge edge) {
      double value = HarborWaters.clearanceOf(context, edge);
      if (!vertical && mooringLine) {
        value += HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.margin).margin, edge);
      }
      return math.max(value, HarborEdges.of(minimum, edge)) + HarborEdges.of(padding, edge);
    }

    final double clearLeading = clearance(leadingEdge);
    double leading = clearLeading;
    final double trailing = clearance(leadingEdge.opposite);

    // A sliver dock first in the fairway takes the coast on the leading edge
    // itself, so its surface runs under the status bar.
    final bool leadsWithDock = slivers.isNotEmpty && slivers.first is HarborSliverDock && leadingEdge == HarborEdge.top;
    double absorbed = 0.0;
    if (leadsWithDock && HarborEdges.of(waters.docks, HarborEdge.top) <= 0) {
      absorbed = math.min(leading, HarborEdges.of(coast(), HarborEdge.top));
      leading -= absorbed;
    }

    // How far pinned slivers stay from the leading edge: the docks' face,
    // not the end of their wake.
    final HarborWakeBand? band = waters.wakes[leadingEdge];
    double cover = band == null
        ? leading
        : math.max(HarborWaters.clearanceOf(context, leadingEdge) - band.length, HarborEdges.of(coast(), leadingEdge));
    cover = math.max(0.0, math.min(cover, leading + absorbed) - absorbed);

    final Set<HarborEdge> castOff = vertical ? HarborEdge.vertical : HarborEdge.horizontal;
    final EdgeInsetsDirectional crossPadding = vertical
        ? EdgeInsetsDirectional.only(start: padding.start, end: padding.end)
        : EdgeInsetsDirectional.only(top: padding.top, bottom: padding.bottom);

    // A pinned sliver dock takes over the leading edge, so the fairway's wake
    // there would only fade the dock.
    final bool hasSliverDock = slivers.any((final Widget s) => s is HarborSliverDock);
    final Map<HarborEdge, HarborWakeBand> wakes = !wake
        ? const <HarborEdge, HarborWakeBand>{}
        : <HarborEdge, HarborWakeBand>{
            for (final HarborEdge e in castOff)
              if (waters.wakes.containsKey(e) && !waters.wakesPainted.contains(e) && !(hasSliverDock && e == leadingEdge))
                e: waters.wakes[e]!,
          };
    final Widget fairway = HarborWakeMask(
      wakes: wakes,
      child: _fairway(
        context,
        castOff,
        vertical,
        startsInOpenWater ? 0.0 : leading,
        clearLeading,
        cover,
        trailing,
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
    final Set<HarborEdge> castOff,
    final bool vertical,
    final double leading,
    final double clearLeading,
    final double cover,
    final double trailing,
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
    // by what covers the trailing edge, and by the wake past the leading
    // docks' face, so the row comes to rest in clear water.
    final double trailExtra = revealMargin + trailing;
    EdgeInsets reveal(final double leadExtra) => switch (axis) {
      AxisDirection.down => EdgeInsets.only(top: leadExtra, bottom: trailExtra),
      AxisDirection.up => EdgeInsets.only(top: trailExtra, bottom: leadExtra),
      AxisDirection.right => EdgeInsets.only(left: leadExtra, right: trailExtra),
      AxisDirection.left => EdgeInsets.only(left: trailExtra, right: leadExtra),
    };
    Widget first(final Widget sliver) {
      Widget result = leadsWithDock ? _SliverDockAbsorb(coast: absorbed, child: sliver) : sliver;
      if (startsInOpenWater) {
        // Content that starts in open water keeps the coast and docks it starts under.
        final HarborWatersData? openWaterWaters = HarborWaters.maybeRawOf(context);
        result = MediaQuery(
          data: MediaQuery.of(context),
          child: openWaterWaters == null ? result : HarborWaters(data: openWaterWaters, child: result),
        );
      }
      return result;
    }

    // With a center, the cover leads the slivers that grow forward from it,
    // and anchor 0 rests the center where the first sliver would rest.
    final Widget coverSliver = _HarborCoverSliver(
      key: _coverKey,
      extent: cover,
      fromViewportEdge: !shrinkWrap && (center != null || anchor != 0.0),
    );
    final bool centersFirst = center != null && slivers.first.key == center;
    return HarborCastOff(
      edges: castOff,
      tide: vertical,
      margin: !vertical && mooringLine,
      child: _HarborScrollView(
        reveal: reveal(revealMargin + math.max(0.0, leading - cover)),
        reverseReveal: reveal(revealMargin + clearLeading),
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
    );
  }
}

const Key _coverKey = _HarborCoverKey();

class _HarborCoverKey extends LocalKey {
  const _HarborCoverKey();
}

/// The key of the sliver a fairway wraps around one of yours that has a key,
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

  // The viewport runs under the docks, so the anchor it lays out by is the
  // fairway's anchor taken across the water between them.
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
  RevealedOffset getOffsetToReveal(final RenderObject target, final double alignment, {final Rect? rect, final Axis? axis}) {
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
  RevealedOffset getOffsetToReveal(final RenderObject target, final double alignment, {final Rect? rect, final Axis? axis}) =>
      super.getOffsetToReveal(target, alignment, rect: _widen(rect ?? target.paintBounds, reveal), axis: axis);

  // A shrink-wrapped viewport is as long as its slivers' paint. The cover only
  // paints to hand its overlap to the slivers after it, and the spacer behind
  // it already holds that ground, so it adds no length of its own.
  @override
  void updateOutOfBandData(final GrowthDirection growthDirection, final SliverGeometry childLayoutGeometry) {
    final RenderSliver? cover = firstChild;
    if (cover is _RenderHarborCoverSliver && identical(childLayoutGeometry, cover.geometry)) {
      super.updateOutOfBandData(growthDirection, SliverGeometry(hasVisualOverflow: childLayoutGeometry.hasVisualOverflow));
      return;
    }
    super.updateOutOfBandData(growthDirection, childLayoutGeometry);
  }
}

Rect _widen(final Rect rect, final EdgeInsets by) =>
    Rect.fromLTRB(rect.left - by.left, rect.top - by.top, rect.right + by.right, rect.bottom + by.bottom);

/// Gives a box fairway its cross-axis size from its child when its parent
/// leaves that axis unbounded. A viewport cannot be measured by what it holds,
/// so this asks the child, through [_HarborHugTarget], for its intrinsic size.
class _HarborCrossAxisHug extends SingleChildRenderObjectWidget {
  const _HarborCrossAxisHug({required this.scrollDirection, required this.crossPadding, required super.child});

  final Axis scrollDirection;

  /// The fairway's own padding across the scroll, added to the child's size.
  final double crossPadding;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderHarborCrossAxisHug(scrollDirection, crossPadding);

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

/// One sliver of a scroll view you build yourself, kept clear at the ends you
/// choose. Use it on the sliver at each end of a `CustomScrollView`; a whole
/// scroll view is better as a [HarborFairway].
///
/// It casts off the ends it cleared, as `SliverSafeArea` removes the padding it
/// applied, so a `SafeArea` or a `MediaQuery.padding` reader in [sliver] does
/// not clear them a second time. An end it does not clear is left as it is.
///
/// See also:
///
///  * [SliverSafeArea], the closest Flutter widget, which keeps clear of `MediaQuery.padding` alone.
class HarborFairwaySliver extends StatelessWidget {
  const HarborFairwaySliver({
    super.key,
    this.clearLeading = true,
    this.clearTrailing = true,
    this.padding = EdgeInsetsDirectional.zero,
    this.minimum = EdgeInsetsDirectional.zero,
    required this.sliver,
  });

  final bool clearLeading;
  final bool clearTrailing;
  final EdgeInsetsGeometry padding;

  /// A floor on the clearance at each end it clears, as on [HarborFairway.minimum].
  final EdgeInsetsGeometry minimum;
  final Widget sliver;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('clearLeading', value: clearLeading, ifFalse: 'leading end not cleared'));
    properties.add(FlagProperty('clearTrailing', value: clearTrailing, ifFalse: 'trailing end not cleared'));
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
      AxisDirection.right => direction == TextDirection.ltr ? (HarborEdge.start, HarborEdge.end) : (HarborEdge.end, HarborEdge.start),
      AxisDirection.left => direction == TextDirection.ltr ? (HarborEdge.end, HarborEdge.start) : (HarborEdge.start, HarborEdge.end),
    };
    final EdgeInsetsDirectional padding = HarborEdges.resolve(this.padding, direction);
    final EdgeInsetsDirectional minimum = HarborEdges.resolve(this.minimum, direction);
    double clearance(final HarborEdge edge) => math.max(HarborWaters.clearanceOf(context, edge), HarborEdges.of(minimum, edge));
    final double leading = clearLeading ? clearance(leadingEdge) : 0.0;
    final double trailing = clearTrailing ? clearance(trailingEdge) : 0.0;
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
    // As `SliverSafeArea` pads and then removes that padding, the ends it cleared are cast off, so a
    // reader in the sliver does not clear them again. An end it leaves is left to its content.
    final Set<HarborEdge> cleared = <HarborEdge>{if (clearLeading) leadingEdge, if (clearTrailing) trailingEdge};
    return _HarborRevealSliver(
      leading: leading,
      trailing: trailing,
      textDirection: direction,
      sliver: SliverPadding(
        padding: insets.resolve(direction),
        sliver: HarborCastOff(
          edges: cleared,
          tide: cleared.contains(HarborEdge.bottom),
          margin: false,
          child: sliver,
        ),
      ),
    );
  }
}

/// A dock that lives in a fairway: a header that scrolls with the content and
/// then pins, clear of the docks above it, and becomes a dock for everything
/// after it. The first one in a fairway with no dock above takes the status
/// bar itself, so its [backdrop] runs under it. Several stack.
///
/// See also:
///
///  * [PinnedHeaderSliver], which this pins with, and `SliverAppBar(pinned: true)`.
class HarborSliverDock extends StatelessWidget {
  const HarborSliverDock({super.key, required this.child, this.backdrop, this.hitTestBehavior = HitTestBehavior.opaque});

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
    final double coast = _SliverDockAbsorb.coastOf(context);
    return PinnedHeaderSliver(
      child: Listener(
        behavior: hitTestBehavior,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: backdrop ?? const SizedBox.shrink()),
            Padding(
              padding: EdgeInsets.only(top: coast),
              child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverDockAbsorb extends InheritedWidget {
  const _SliverDockAbsorb({required this.coast, required super.child});

  final double coast;

  static double coastOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SliverDockAbsorb>()?.coast ?? 0.0;

  @override
  bool updateShouldNotify(final _SliverDockAbsorb oldWidget) => coast != oldWidget.coast;
}

/// Widens every reveal that passes through it by what covers the scroll
/// view's edges, so the viewport brings the row clear of the docks rather
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
    final Rect widened = switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
      AxisDirection.down => Rect.fromLTRB(local.left, local.top - leading, local.right, local.bottom + trailing),
      AxisDirection.up => Rect.fromLTRB(local.left, local.top - trailing, local.right, local.bottom + leading),
      AxisDirection.right => Rect.fromLTRB(local.left - leading, local.top, local.right + trailing, local.bottom),
      AxisDirection.left => Rect.fromLTRB(local.left - trailing, local.top, local.right + leading, local.bottom),
    };
    super.showOnScreen(descendant: descendant, rect: widened, duration: duration, curve: curve);
  }
}

/// Covers the leading edge of a fairway without taking any scroll space: it
/// tells the slivers after it how far the docks reach, so pinned headers pin
/// at the docks' face and reveals keep clear of them.
class _HarborCoverSliver extends LeafRenderObjectWidget {
  const _HarborCoverSliver({super.key, required this.extent, required this.fromViewportEdge});

  final double extent;

  /// Whether the cover may start inside the viewport, as it does at a center
  /// or an anchor, and must reach only as far as the docks do from its edge.
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
    final double start = _fromViewportEdge ? constraints.viewportMainAxisExtent - constraints.remainingPaintExtent : 0.0;
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
  bool hitTest(final SliverHitTestResult result, {required final double mainAxisPosition, required final double crossAxisPosition}) =>
      false;
}
