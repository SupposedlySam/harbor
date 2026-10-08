import 'dart:math' as math;

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
class HarborFairway extends StatelessWidget {
  const HarborFairway({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding = EdgeInsetsDirectional.zero,
    this.minimum = EdgeInsetsDirectional.zero,
    this.mooringLine = true,
    this.revealMargin = 0.0,
    this.wake = true,
    this.startsInOpenWater = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.scrollCacheExtent,
    this.semanticChildCount,
    required this.slivers,
  }) : _hugsChild = false;

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
    this.shrinkWrap = false,
    this.padding = EdgeInsetsDirectional.zero,
    this.minimum = EdgeInsetsDirectional.zero,
    this.mooringLine = true,
    this.revealMargin = 0.0,
    this.wake = true,
    this.startsInOpenWater = false,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.clipBehavior = Clip.hardEdge,
    this.scrollCacheExtent,
    required final Widget child,
  }) : semanticChildCount = null,
       _hugsChild = true,
       slivers = <Widget>[SliverToBoxAdapter(child: _HarborHugTarget(child: child))];

  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

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

  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Clip clipBehavior;
  final ScrollCacheExtent? scrollCacheExtent;
  final int? semanticChildCount;
  final List<Widget> slivers;

  /// Whether this is the box form, which can take its cross axis from its child.
  final bool _hugsChild;

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

    double leading = clearance(leadingEdge);
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
    final double leadExtra = revealMargin + math.max(0.0, leading - cover);
    final double trailExtra = revealMargin + trailing;
    final EdgeInsets reveal = switch (axis) {
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

    return HarborCastOff(
      edges: castOff,
      tide: vertical,
      margin: !vertical && mooringLine,
      child: _HarborScrollView(
        reveal: reveal,
        scrollDirection: scrollDirection,
        reverse: reverse,
        controller: controller,
        primary: primary,
        physics: physics,
        shrinkWrap: shrinkWrap,
        keyboardDismissBehavior: keyboardDismissBehavior,
        clipBehavior: clipBehavior,
        scrollCacheExtent: scrollCacheExtent,
        semanticChildCount: semanticChildCount,
        slivers: <Widget>[
          _HarborCoverSliver(extent: cover),
          SliverToBoxAdapter(
            child: SizedBox(width: vertical ? null : leading, height: vertical ? leading : null),
          ),
          for (int i = 0; i < slivers.length; i++)
            SliverPadding(
              padding: crossPadding.resolve(direction),
              sliver: i == 0 ? first(slivers[i]) : slivers[i],
            ),
          SliverToBoxAdapter(
            child: SizedBox(width: vertical ? null : trailing, height: vertical ? trailing : null),
          ),
        ],
      ),
    );
  }
}

/// A `CustomScrollView` whose viewport widens every reveal by [reveal].
class _HarborScrollView extends CustomScrollView {
  const _HarborScrollView({
    required this.reveal,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.keyboardDismissBehavior,
    super.clipBehavior,
    super.scrollCacheExtent,
    super.semanticChildCount,
    super.slivers,
  });

  final EdgeInsets reveal;

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
        clipBehavior: clipBehavior,
        scrollCacheExtent: scrollCacheExtent,
      );
    }
    return _HarborViewport(
      reveal: reveal,
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
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
    required super.axisDirection,
    required super.offset,
    super.slivers,
    super.clipBehavior,
    super.scrollCacheExtent,
    super.center,
    super.anchor,
  });

  final EdgeInsets reveal;

  @override
  RenderViewport createRenderObject(final BuildContext context) => _RenderHarborViewport(
    reveal: reveal,
    axisDirection: axisDirection,
    crossAxisDirection: crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
    anchor: anchor,
    offset: offset,
    scrollCacheExtent: scrollCacheExtent,
    clipBehavior: clipBehavior,
  );

  @override
  void updateRenderObject(final BuildContext context, final RenderViewport renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderHarborViewport).reveal = reveal;
  }
}

class _RenderHarborViewport extends RenderViewport {
  _RenderHarborViewport({
    required this.reveal,
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor,
    super.scrollCacheExtent,
    super.clipBehavior,
  });

  EdgeInsets reveal;

  @override
  RevealedOffset getOffsetToReveal(final RenderObject target, final double alignment, {final Rect? rect, final Axis? axis}) =>
      super.getOffsetToReveal(target, alignment, rect: _widen(rect ?? target.paintBounds, reveal), axis: axis);
}

class _HarborShrinkWrappingViewport extends ShrinkWrappingViewport {
  const _HarborShrinkWrappingViewport({
    required this.reveal,
    required super.axisDirection,
    required super.offset,
    super.slivers,
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
    return _HarborRevealSliver(
      leading: leading,
      trailing: trailing,
      textDirection: direction,
      sliver: SliverPadding(padding: insets.resolve(direction), sliver: sliver),
    );
  }
}

/// A dock that lives in a fairway: a header that scrolls with the content and
/// then pins, clear of the docks above it, and becomes a dock for everything
/// after it. The first one in a fairway with no dock above takes the status
/// bar itself, so its [backdrop] runs under it. Several stack.
class HarborSliverDock extends StatelessWidget {
  const HarborSliverDock({super.key, required this.child, this.backdrop, this.hitTestBehavior = HitTestBehavior.opaque});

  final Widget child;
  final Widget? backdrop;
  final HitTestBehavior hitTestBehavior;

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
  const _HarborCoverSliver({required this.extent});

  final double extent;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderHarborCoverSliver(extent);

  @override
  void updateRenderObject(final BuildContext context, final _RenderHarborCoverSliver renderObject) {
    renderObject.extent = extent;
  }
}

class _RenderHarborCoverSliver extends RenderSliver {
  _RenderHarborCoverSliver(this._extent);

  double _extent;
  set extent(final double value) {
    if (_extent != value) {
      _extent = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    final double paint = math.min(_extent, constraints.remainingPaintExtent);
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
