import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'dock.dart';
import 'dock_slot.dart';
import 'edge.dart';
import 'tide.dart';
import 'wake.dart';
import 'waters.dart';

/// How a harbor sizes itself.
enum HarborSizing {
  /// It fills the space it is given, as a page does.
  fill,

  /// It is as tall as its body and quays, as a content-sized sheet is.
  hugBody,
}

/// What a harbor hands its body during layout: the `MediaQuery` values and
/// the waters for the body's area, computed after the docks were measured.
@immutable
class HarborBodyPayload {
  const HarborBodyPayload({
    required this.padding,
    required this.viewPadding,
    required this.viewInsetsBottom,
    required this.waters,
    required this.ownWakes,
  });

  final EdgeInsets padding;
  final EdgeInsets viewPadding;
  final double viewInsetsBottom;
  final HarborWatersData waters;

  /// The wakes this harbor's own docks leave, for its wake painter.
  final Map<HarborEdge, HarborWakeBand> ownWakes;

  @override
  bool operator ==(final Object other) =>
      other is HarborBodyPayload &&
      other.padding == padding &&
      other.viewPadding == viewPadding &&
      other.viewInsetsBottom == viewInsetsBottom &&
      other.waters == waters &&
      other.ownWakes.length == ownWakes.length &&
      other.ownWakes.entries.every((final MapEntry<HarborEdge, HarborWakeBand> e) => ownWakes[e.key] == e.value);

  @override
  int get hashCode => Object.hash(padding, viewPadding, viewInsetsBottom, waters, ownWakes.length);
}

/// The body's constraints, carrying the [HarborBodyPayload] the way a
/// `Scaffold`'s body constraints carry its bars. Equality includes the
/// payload, so a dock that changed size reaches the body in the same pass.
class HarborBodyConstraints extends BoxConstraints {
  const HarborBodyConstraints({
    super.minWidth,
    super.maxWidth,
    super.minHeight,
    super.maxHeight,
    required this.payload,
  });

  final HarborBodyPayload payload;

  @override
  bool operator ==(final Object other) =>
      super == other && other is HarborBodyConstraints && other.payload == payload;

  @override
  int get hashCode => Object.hash(super.hashCode, payload);
}

/// The buoy layer's constraints: the whole frame, and the water nothing covers.
class HarborBuoyConstraints extends BoxConstraints {
  HarborBuoyConstraints({required final Size frame, required this.clearWater}) : super.tight(frame);

  /// The rectangle, in the frame's coordinates, that no dock, coast or tide covers.
  final Rect clearWater;

  @override
  bool operator ==(final Object other) =>
      super == other && other is HarborBuoyConstraints && other.clearWater == clearWater;

  @override
  int get hashCode => Object.hash(super.hashCode, clearWater);
}

enum HarborSlotKind { body, dock, buoys }

class HarborParentData extends ContainerBoxParentData<RenderBox> {
  HarborSlotKind kind = HarborSlotKind.body;
  HarborEdge edge = HarborEdge.top;

  /// Position counted from the edge inward.
  int fromEdge = 0;
  HarborDock? dock;
  HarborDockState state = HarborDockState.open;

  @override
  String toString() => '${super.toString()}; $kind $edge #$fromEdge';
}

/// Marks a child of [RenderHarbor] with its slot.
class HarborSlot extends ParentDataWidget<HarborParentData> {
  const HarborSlot.body({super.key, required super.child})
    : kind = HarborSlotKind.body,
      edge = HarborEdge.top,
      fromEdge = 0,
      dock = null,
      state = HarborDockState.open;

  const HarborSlot.buoys({super.key, required super.child})
    : kind = HarborSlotKind.buoys,
      edge = HarborEdge.top,
      fromEdge = 0,
      dock = null,
      state = HarborDockState.open;

  const HarborSlot.dock({
    super.key,
    required this.edge,
    required this.fromEdge,
    required HarborDock this.dock,
    required this.state,
    required super.child,
  }) : kind = HarborSlotKind.dock;

  final HarborSlotKind kind;
  final HarborEdge edge;
  final int fromEdge;
  final HarborDock? dock;
  final HarborDockState state;

  @override
  void applyParentData(final RenderObject renderObject) {
    final HarborParentData data = renderObject.parentData! as HarborParentData;
    bool changed = false;
    if (data.kind != kind) {
      data.kind = kind;
      changed = true;
    }
    if (data.edge != edge) {
      data.edge = edge;
      changed = true;
    }
    if (data.fromEdge != fromEdge) {
      data.fromEdge = fromEdge;
      changed = true;
    }
    if (!identical(data.dock, dock)) {
      data.dock = dock;
      changed = true;
    }
    if (data.state != state) {
      data.state = state;
      changed = true;
    }
    if (changed) {
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => HarborLayout;
}

/// The geometry a harbor's build hands its layout.
@immutable
class HarborGeometry {
  const HarborGeometry({
    required this.textDirection,
    required this.coast,
    required this.coastSteady,
    required this.coastOnly,
    required this.inheritedDocks,
    required this.inheritedWakes,
    required this.tide,
    required this.bodyClearsTide,
    required this.minimum,
    required this.margin,
    required this.sizing,
    required this.viewHeight,
    required this.maxExtentFraction,
    this.frameSize,
  });

  /// The frame size to report, for a component harbor: its port's, which the
  /// keyboard never shrinks. Null reports this harbor's own size.
  final Size? frameSize;

  final TextDirection textDirection;

  /// What the docks on each edge absorb, and the least the body keeps clear of:
  /// the coast plus whatever docks of an outer harbor reach in.
  final EdgeInsetsDirectional coast;

  /// [coast] as it is with the keyboard down.
  final EdgeInsetsDirectional coastSteady;

  /// The platform's share of [coast], for the waters.
  final EdgeInsetsDirectional coastOnly;

  /// How far an outer harbor's docks reach into this one.
  final EdgeInsetsDirectional inheritedDocks;
  final Map<HarborEdge, HarborWakeBand> inheritedWakes;

  /// How far the keyboard reaches into this harbor.
  final double tide;
  final bool bodyClearsTide;

  /// A floor under what the body keeps clear of on each edge.
  final EdgeInsetsDirectional minimum;
  final EdgeInsetsDirectional margin;
  final HarborSizing sizing;

  /// The height of the screen, to place breakwaters measured from its bottom.
  final double viewHeight;

  /// For [HarborSizing.hugBody]: the most of the space above the tide the
  /// harbor may take, or null for all of it.
  final double? maxExtentFraction;

  @override
  bool operator ==(final Object other) =>
      other is HarborGeometry &&
      other.textDirection == textDirection &&
      other.coast == coast &&
      other.coastSteady == coastSteady &&
      other.coastOnly == coastOnly &&
      other.inheritedDocks == inheritedDocks &&
      other.inheritedWakes.length == inheritedWakes.length &&
      other.inheritedWakes.entries.every((final MapEntry<HarborEdge, HarborWakeBand> e) => inheritedWakes[e.key] == e.value) &&
      other.tide == tide &&
      other.bodyClearsTide == bodyClearsTide &&
      other.minimum == minimum &&
      other.margin == margin &&
      other.sizing == sizing &&
      other.viewHeight == viewHeight &&
      other.maxExtentFraction == maxExtentFraction &&
      other.frameSize == frameSize;

  @override
  int get hashCode => Object.hash(
    textDirection,
    coast,
    coastSteady,
    coastOnly,
    inheritedDocks,
    tide,
    bodyClearsTide,
    minimum,
    margin,
    sizing,
    viewHeight,
    maxExtentFraction,
  );
}

/// Lays a harbor out: docks first, then the body with what the docks took,
/// then the buoys in the water that is left, all in one layout pass.
class HarborLayout extends MultiChildRenderObjectWidget {
  const HarborLayout({super.key, required this.geometry, required this.controller, required super.children});

  final HarborGeometry geometry;
  final HarborController controller;

  @override
  RenderHarbor createRenderObject(final BuildContext context) =>
      RenderHarbor(geometry: geometry, controller: controller);

  @override
  void updateRenderObject(final BuildContext context, final RenderHarbor renderObject) {
    renderObject
      ..geometry = geometry
      ..controller = controller;
  }
}

class _Placed {
  _Placed(this.box, this.data, this.extent, this.resting, this.visual);

  final RenderBox box;
  final HarborParentData data;
  final double extent;
  final double resting;
  final double visual;
  double start = 0.0;
  double restingStart = 0.0;
  double steadyStart = 0.0;
}

class RenderHarbor extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, HarborParentData>, RenderBoxContainerDefaultsMixin<RenderBox, HarborParentData> {
  RenderHarbor({required this._geometry, required this._controller}) {
    _controller.renderBox = this;
  }

  HarborGeometry _geometry;
  set geometry(final HarborGeometry value) {
    if (_geometry != value) {
      _geometry = value;
      markNeedsLayout();
    }
  }

  HarborController _controller;
  set controller(final HarborController value) {
    if (identical(_controller, value)) {
      return;
    }
    if (attached) {
      _controller.breakwaterChanges.removeListener(_breakwaterMoved);
      value.breakwaterChanges.addListener(_breakwaterMoved);
    }
    _controller = value;
    value.renderBox = this;
    markNeedsLayout();
  }

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _controller.breakwaterChanges.addListener(_breakwaterMoved);
  }

  void _breakwaterMoved() {
    // Told between frames, so the last frame's transforms can be read now and
    // the new cover reaches the very next layout.
    if (attached && hasSize && SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _edgeCoverage = _edgeCoverageNow();
    }
    markNeedsLayout();
    markNeedsPaint();
  }

  double _edgeCoverageNow() {
    double covered = 0.0;
    for (final double top in _controller.breakwaterTopsInGlobal) {
      final double local = globalToLocal(Offset(0.0, top)).dy;
      covered = math.max(covered, (size.height - local).clamp(0.0, size.height));
    }
    return covered;
  }

  @override
  void detach() {
    _controller.breakwaterChanges.removeListener(_breakwaterMoved);
    super.detach();
  }

  @override
  void setupParentData(final RenderObject child) {
    if (child.parentData is! HarborParentData) {
      child.parentData = HarborParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(final double height) => 0.0;

  @override
  double computeMaxIntrinsicWidth(final double height) => 0.0;

  @override
  double computeMinIntrinsicHeight(final double width) => 0.0;

  @override
  double computeMaxIntrinsicHeight(final double width) => 0.0;

  @override
  Size computeDryLayout(final BoxConstraints constraints) => constraints.biggest;

  /// How far this harbor's bottom sits above the screen's, measured when it
  /// last painted (ancestors can't be asked during layout).
  double _gapBelow = 0.0;

  /// How far breakwaters that report a top edge cover this frame, measured
  /// when it last painted.
  double _edgeCoverage = 0.0;

  double _breakwaterInFrame() {
    final double coverage = _controller.breakwaterCoverage;
    final double fromBottom = coverage <= 0 ? 0.0 : math.max(0.0, coverage - _gapBelow);
    return math.max(fromBottom, _edgeCoverage);
  }

  void _measureEdgeCoverage() {
    // The harbor itself may have moved under a still cover.
    final double covered = _edgeCoverageNow();
    if ((covered - _edgeCoverage).abs() > 0.5) {
      _edgeCoverage = covered;
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
        if (attached) {
          markNeedsLayout();
        }
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    }
  }

  void _measureGapBelow() {
    final double bottom = localToGlobal(Offset(0.0, size.height)).dy;
    final double gap = math.max(0.0, _geometry.viewHeight - bottom);
    if ((gap - _gapBelow).abs() > 0.5) {
      _gapBelow = gap;
      if (_controller.breakwaterCoverage > 0) {
        SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
          if (attached) {
            markNeedsLayout();
          }
        });
      }
    }
  }

  @override
  void performLayout() {
    final HarborGeometry g = _geometry;
    final bool hug = g.sizing == HarborSizing.hugBody;
    assert(
      constraints.hasBoundedWidth && (hug || constraints.hasBoundedHeight),
      'A Harbor needs bounded constraints to fill, as a Scaffold does. Give it a size, or use HarborSizing.hugBody.',
    );
    final double width = constraints.maxWidth;
    final double maxHeight = constraints.hasBoundedHeight ? constraints.maxHeight : double.infinity;
    final double dockMaxHeight = maxHeight.isFinite ? maxHeight : 100000.0;

    RenderBox? body;
    RenderBox? buoys;
    final Map<HarborEdge, List<_Placed>> byEdge = <HarborEdge, List<_Placed>>{
      for (final HarborEdge e in HarborEdge.values) e: <_Placed>[],
    };

    // 1. Measure the docks.
    RenderBox? child = firstChild;
    while (child != null) {
      final HarborParentData data = child.parentData! as HarborParentData;
      switch (data.kind) {
        case HarborSlotKind.body:
          body = child;
        case HarborSlotKind.buoys:
          buoys = child;
        case HarborSlotKind.dock:
          // Unbounded along the edge's depth, as a Row or Column leaves its children. Bounding it
          // at the frame let any widget that fills what it is given (a NavigationRail, an AppBar,
          // an empty Container) take the whole frame and leave the body nothing, with no error.
          // Unbounded, those size as they do in a Row or Column, and one that truly wants to fill
          // (a ListView) fails loudly, which is the failure Flutter developers already know.
          final BoxConstraints dockConstraints = data.edge.isVertical
              ? BoxConstraints(minWidth: width, maxWidth: width)
              : BoxConstraints(minHeight: dockMaxHeight, maxHeight: dockMaxHeight);
          child.layout(dockConstraints, parentUsesSize: true);
          double extent = data.edge.isVertical ? child.size.height : child.size.width;
          double resting = extent;
          if (child is RenderHarborDockFrame) {
            extent = child.extent;
            resting = child.restingExtent;
          }
          final double visual = data.edge.isVertical ? child.size.height : child.size.width;
          byEdge[data.edge]!.add(_Placed(child, data, extent, resting, visual));
      }
      child = data.nextSibling;
    }
    for (final List<_Placed> docks in byEdge.values) {
      docks.sort((final _Placed a, final _Placed b) => a.data.fromEdge.compareTo(b.data.fromEdge));
    }

    // 2. Stack each edge from the edge inward. Floating docks ride the tide.
    final double tide = g.tide;
    final Map<HarborEdge, double> far = <HarborEdge, double>{};
    final Map<HarborEdge, double> farResting = <HarborEdge, double>{};
    final Map<HarborEdge, double> farSteady = <HarborEdge, double>{};
    final Map<HarborEdge, double> quayEnd = <HarborEdge, double>{};
    final Map<HarborEdge, double> quayEndSteady = <HarborEdge, double>{};
    final Map<HarborEdge, HarborWake> innerWake = <HarborEdge, HarborWake>{};
    final Map<HarborEdge, HarborDockKind> innerKind = <HarborEdge, HarborDockKind>{};
    for (final HarborEdge edge in HarborEdge.values) {
      double offset = 0.0;
      double restingOffset = 0.0;
      double steadyOffset = 0.0;
      bool seenPier = false;
      double quays = 0.0;
      double quaysSteady = 0.0;
      for (final _Placed dock in byEdge[edge]!) {
        final HarborDock config = dock.data.dock!;
        final bool floats = edge == HarborEdge.bottom && config.tide == HarborTideStance.float;
        dock.start = floats ? math.max(offset, tide) : offset;
        dock.restingStart = restingOffset;
        dock.steadyStart = steadyOffset;
        offset = dock.start + dock.extent;
        restingOffset += dock.resting;
        steadyOffset += dock.extent;
        if (config.kind == HarborDockKind.quay) {
          assert(!seenPier, 'A quay on the ${edge.name} edge is listed inside a pier. Quays are built on the shore: list them nearer the edge than piers.');
          quays = offset;
          quaysSteady = steadyOffset;
        } else {
          seenPier = true;
        }
        if (dock.extent > 0) {
          innerWake[edge] = config.wake;
          innerKind[edge] = config.kind;
        }
      }
      far[edge] = offset;
      farResting[edge] = restingOffset;
      farSteady[edge] = steadyOffset;
      quayEnd[edge] = quays;
      quayEndSteady[edge] = quaysSteady;
    }

    // 3. The body's box: inside the quays, and above the tide when it clears it.
    final double bodyInsetBottom = g.bodyClearsTide ? math.max(quayEnd[HarborEdge.bottom]!, tide) : quayEnd[HarborEdge.bottom]!;
    final EdgeInsetsDirectional bodyInset = EdgeInsetsDirectional.fromSTEB(
      quayEnd[HarborEdge.start]!,
      quayEnd[HarborEdge.top]!,
      quayEnd[HarborEdge.end]!,
      bodyInsetBottom,
    );

    // 4. What is in the way on each edge, from the frame's edge.
    final double breakwater = _breakwaterInFrame();
    double wakeClearance(final HarborEdge edge) => far[edge]! > 0 ? (innerWake[edge]?.clearance ?? 0.0) : 0.0;
    double coastOf(final EdgeInsetsDirectional coast, final HarborEdge edge) =>
        math.max(HarborEdges.of(coast, edge), HarborEdges.of(g.minimum, edge));
    final EdgeInsetsDirectional docksLive = HarborEdges.build((final HarborEdge e) {
      double v = far[e]! > 0 ? far[e]! + wakeClearance(e) : 0.0;
      if (e == HarborEdge.bottom) {
        v = math.max(v, breakwater);
      }
      return v;
    });
    final EdgeInsetsDirectional docksResting = HarborEdges.build(
      (final HarborEdge e) => farResting[e]! > 0 ? farResting[e]! + wakeClearance(e) : 0.0,
    );
    // `MediaQuery.padding` never carries the keyboard: that stays in
    // `viewInsets`, as Flutter has it. The clear water does include it.
    final EdgeInsetsDirectional obstruction = HarborEdges.build(
      (final HarborEdge e) => math.max(coastOf(g.coast, e), HarborEdges.of(docksLive, e)),
    );
    final EdgeInsetsDirectional obstructionWithTide = HarborEdges.build(
      (final HarborEdge e) => e == HarborEdge.bottom ? math.max(HarborEdges.of(obstruction, e), tide) : HarborEdges.of(obstruction, e),
    );
    final EdgeInsetsDirectional steady = HarborEdges.build((final HarborEdge e) {
      final double docks = farSteady[e]! > 0 ? farSteady[e]! + wakeClearance(e) : 0.0;
      return math.max(coastOf(g.coastSteady, e), docks);
    });
    double past(final EdgeInsetsDirectional value, final HarborEdge e) =>
        math.max(0.0, HarborEdges.of(value, e) - HarborEdges.of(bodyInset, e));

    final Map<HarborEdge, HarborWakeBand> ownWakes = <HarborEdge, HarborWakeBand>{};
    for (final HarborEdge e in HarborEdge.values) {
      final HarborWake? wake = innerWake[e];
      if (wake == null || wake.kind != HarborWakeKind.fade || far[e]! <= 0) {
        continue;
      }
      final double dockEdge = math.max(0.0, far[e]! - HarborEdges.of(bodyInset, e));
      ownWakes[e] = HarborWakeBand(dockEdge: dockEdge, wakeEnd: dockEdge + wake.length);
    }
    final Map<HarborEdge, HarborWakeBand> wakes = <HarborEdge, HarborWakeBand>{
      for (final MapEntry<HarborEdge, HarborWakeBand> inherited in g.inheritedWakes.entries)
        if (!ownWakes.containsKey(inherited.key) && HarborEdges.of(bodyInset, inherited.key) < inherited.value.wakeEnd)
          inherited.key: HarborWakeBand(
            dockEdge: math.max(0.0, inherited.value.dockEdge - HarborEdges.of(bodyInset, inherited.key)),
            wakeEnd: inherited.value.wakeEnd - HarborEdges.of(bodyInset, inherited.key),
          ),
      ...ownWakes,
    };

    final EdgeInsetsDirectional padding = HarborEdges.build((final HarborEdge e) => past(obstruction, e));
    final EdgeInsetsDirectional viewPadding = HarborEdges.build((final HarborEdge e) => past(steady, e));
    final EdgeInsetsDirectional coastPast = HarborEdges.build(
      (final HarborEdge e) => past(HarborEdges.build((final HarborEdge x) => coastOf(g.coastOnly, x)), e),
    );
    final EdgeInsetsDirectional docksPast = HarborEdges.build(
      (final HarborEdge e) => past(HarborEdges.max(docksLive, g.inheritedDocks), e),
    );
    final EdgeInsetsDirectional restingPast = HarborEdges.build(
      (final HarborEdge e) => past(HarborEdges.max(docksResting, g.inheritedDocks), e),
    );

    // 5. Size the frame and lay the body out.
    final double insetH = bodyInset.start + bodyInset.end;
    final double insetV = bodyInset.top + bodyInset.bottom;
    double height;
    Size bodySize;
    HarborBodyPayload payload(final Size frame) => HarborBodyPayload(
      padding: padding.resolve(g.textDirection),
      viewPadding: viewPadding.resolve(g.textDirection),
      viewInsetsBottom: g.bodyClearsTide ? 0.0 : math.max(0.0, tide - bodyInset.bottom),
      waters: HarborWatersData(
        coast: coastPast,
        docks: docksPast,
        docksResting: restingPast,
        wakes: wakes,
        margin: g.margin,
        frameSize: g.frameSize ?? frame,
        hasDocks: <HarborEdge>{
          for (final HarborEdge e in HarborEdge.values)
            if (byEdge[e]!.isNotEmpty) e,
        },
      ),
      ownWakes: ownWakes,
    );
    if (hug) {
      double cap = maxHeight.isFinite ? maxHeight : double.infinity;
      final double? fraction = g.maxExtentFraction;
      if (fraction != null && cap.isFinite) {
        cap = (cap - tide) * fraction + tide;
      }
      final double bodyMax = math.max(0.0, cap - insetV);
      if (body != null) {
        body.layout(
          HarborBodyConstraints(
            minWidth: math.max(0.0, width - insetH),
            maxWidth: math.max(0.0, width - insetH),
            maxHeight: bodyMax,
            payload: payload(Size(width, cap.isFinite ? cap : 0.0)),
          ),
          parentUsesSize: true,
        );
        bodySize = body.size;
      } else {
        bodySize = Size.zero;
      }
      height = constraints.constrainHeight(bodySize.height + insetV);
    } else {
      height = maxHeight;
      bodySize = Size(math.max(0.0, width - insetH), math.max(0.0, height - insetV));
      body?.layout(
        HarborBodyConstraints(
          minWidth: bodySize.width,
          maxWidth: bodySize.width,
          minHeight: bodySize.height,
          maxHeight: bodySize.height,
          payload: payload(Size(width, height)),
        ),
        parentUsesSize: true,
      );
    }
    size = Size(width, height);
    final EdgeInsets bodyInsetPhysical = bodyInset.resolve(g.textDirection);
    if (body != null) {
      (body.parentData! as HarborParentData).offset = Offset(bodyInsetPhysical.left, bodyInsetPhysical.top);
    }

    // 6. Place the docks.
    final bool ltr = g.textDirection == TextDirection.ltr;
    final List<HarborDockRecord> records = <HarborDockRecord>[];
    for (final HarborEdge edge in HarborEdge.values) {
      for (final _Placed dock in byEdge[edge]!) {
        final Size s = dock.box.size;
        final Offset offset = switch (edge) {
          HarborEdge.top => Offset(0.0, dock.start),
          HarborEdge.bottom => Offset(0.0, height - dock.start - s.height),
          HarborEdge.start => Offset(ltr ? dock.start : width - dock.start - s.width, 0.0),
          HarborEdge.end => Offset(ltr ? width - dock.start - s.width : dock.start, 0.0),
        };
        dock.data.offset = offset;
        records.add(
          HarborDockRecord(
            edge: edge,
            kind: dock.data.dock!.kind,
            rect: offset & s,
            extent: dock.extent,
            restingExtent: dock.resting,
            state: dock.data.state,
            tide: dock.data.dock!.tide,
            label: dock.data.dock!.debugLabel,
          ),
        );
      }
    }

    // 7. The water nothing covers, and the buoys in it.
    final EdgeInsets physicalObstruction = obstructionWithTide.resolve(g.textDirection);
    final Rect clearWater = Rect.fromLTRB(
      math.min(physicalObstruction.left, width),
      math.min(physicalObstruction.top, height),
      math.max(physicalObstruction.left, width - physicalObstruction.right),
      math.max(physicalObstruction.top, height - physicalObstruction.bottom),
    );
    if (buoys != null) {
      buoys.layout(HarborBuoyConstraints(frame: size, clearWater: clearWater));
      (buoys.parentData! as HarborParentData).offset = Offset.zero;
    }

    _controller.recordLayout(HarborLayoutRecord(
      frame: Offset.zero & size,
      body: Offset(bodyInsetPhysical.left, bodyInsetPhysical.top) & bodySize,
      clearWater: clearWater,
      docks: records,
      obstruction: obstructionWithTide,
      tide: tide,
    ));
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    _measureGapBelow();
    _measureEdgeCoverage();
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
