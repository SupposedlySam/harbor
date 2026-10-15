import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bar.dart';
import 'controller.dart';
import 'dock_slot.dart';
import 'edge.dart';
import 'edge_effect.dart';
import 'keyboard.dart';
import 'room.dart';

/// How a frame sizes itself: it [fill]s the space it is given, as a page does, or it [HarborSizing.hug]s
/// its body, as a content-sized sheet does.
///
/// A class rather than an enum since 0.9.1, so the share a hugging frame may take travels with it.
/// The enum's `values`, `name` and `index` are kept, deprecated, for code that read them.
@immutable
class HarborSizing with Diagnosticable {
  const HarborSizing._fill() : hugs = false, maxFraction = null, _isHugBody = false;

  // A constant of its own, apart from hug() by _isHugBody alone, so use_named_constants never offers
  // the deprecated hugBody for hug(). Equal to hug() all the same.
  const HarborSizing._hugBody() : hugs = true, maxFraction = null, _isHugBody = true;

  /// As tall as its body and solid bars, as a content-sized sheet is, up to [maxFraction] of the
  /// space above the keyboard (of the whole height when the frame's body runs under the keyboard).
  /// Null, the default, caps it at all of that space. It hugs the height only: a frame always fills
  /// its width.
  const HarborSizing.hug({this.maxFraction}) : hugs = true, _isHugBody = false;

  /// It fills the space it is given, as a page does. The default.
  static const HarborSizing fill = HarborSizing._fill();

  /// The old spelling of [HarborSizing.hug] with no cap.
  @Deprecated(
    'Use HarborSizing.hug(). `dart fix` applies it in a file that imports package:harbor/harbor.dart. Deprecated after 0.9.1.',
  )
  static const HarborSizing hugBody = HarborSizing._hugBody();

  /// The enum's values, [fill] and [hugBody].
  @Deprecated('HarborSizing is a class: list the sizings you offer. Deprecated after 0.9.1.')
  static const List<HarborSizing> values = <HarborSizing>[fill, HarborSizing._hugBody()];

  /// Whether the frame is as tall as its body rather than the space it is given.
  final bool hugs;

  /// For a frame that [hugs]: the most of the space above the keyboard it may take, or null for all
  /// of it.
  final double? maxFraction;

  final bool _isHugBody;

  /// The enum's name: `fill` or `hugBody`.
  @Deprecated('HarborSizing is a class: read hugs. Deprecated after 0.9.1.')
  String get name => hugs ? 'hugBody' : 'fill';

  /// The enum's index: 0 for [fill], 1 for a frame that hugs.
  @Deprecated('HarborSizing is a class: read hugs. Deprecated after 0.9.1.')
  int get index => hugs ? 1 : 0;

  @override
  bool operator ==(final Object other) =>
      other is HarborSizing && other.hugs == hugs && other.maxFraction == maxFraction;

  @override
  int get hashCode => Object.hash(hugs, maxFraction);

  @override
  String toStringShort() =>
      '${objectRuntimeType(this, 'HarborSizing')}.${_isHugBody
          ? 'hugBody'
          : hugs
          ? 'hug'
          : 'fill'}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      PercentProperty(
        'maxFraction',
        maxFraction,
        level: maxFraction == null ? DiagnosticLevel.fine : DiagnosticLevel.info,
      ),
    );
  }
}

/// What a frame hands its body during layout: the `MediaQuery` values and
/// the room for the body's area, computed after the bars were measured.
@immutable
class HarborBodyPayload {
  const HarborBodyPayload({
    required this.padding,
    required this.viewPadding,
    required this.viewInsetsBottom,
    required this.room,
    required this.ownFadeBands,
  });

  final EdgeInsets padding;
  final EdgeInsets viewPadding;
  final double viewInsetsBottom;
  final HarborRoomData room;

  /// The edge effects this frame's own bars draw, for its edge effect painter.
  final Map<HarborEdge, HarborFadeBand> ownFadeBands;

  @override
  bool operator ==(final Object other) =>
      other is HarborBodyPayload &&
      other.padding == padding &&
      other.viewPadding == viewPadding &&
      other.viewInsetsBottom == viewInsetsBottom &&
      other.room == room &&
      other.ownFadeBands.length == ownFadeBands.length &&
      other.ownFadeBands.entries.every(
        (final MapEntry<HarborEdge, HarborFadeBand> e) => ownFadeBands[e.key] == e.value,
      );

  @override
  int get hashCode => Object.hash(padding, viewPadding, viewInsetsBottom, room, ownFadeBands.length);
}

/// The body's constraints, carrying the [HarborBodyPayload] the way a
/// `Scaffold`'s body constraints carry its bars. Equality includes the
/// payload, so a bar that changed size reaches the body in the same pass.
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
  bool operator ==(final Object other) => super == other && other is HarborBodyConstraints && other.payload == payload;

  @override
  int get hashCode => Object.hash(super.hashCode, payload);
}

/// The float layer's constraints: the whole frame, and the room nothing covers.
class HarborFloatConstraints extends BoxConstraints {
  HarborFloatConstraints({required final Size frame, required this.room, final Rect? roomWithSystemEdges})
    : roomWithSystemEdges = roomWithSystemEdges ?? room,
      super.tight(frame);

  /// The rectangle, in the frame's coordinates, that no bar, system edge or keyboard covers.
  final Rect room;

  /// The rectangle no bar or keyboard covers, system edges included: where a toast that reaches
  /// the system edges may go.
  final Rect roomWithSystemEdges;

  @override
  bool operator ==(final Object other) =>
      super == other &&
      other is HarborFloatConstraints &&
      other.room == room &&
      other.roomWithSystemEdges == roomWithSystemEdges;

  @override
  int get hashCode => Object.hash(super.hashCode, room, roomWithSystemEdges);
}

enum HarborSlotKind { body, bar, statusBar, floats }

class HarborParentData extends ContainerBoxParentData<RenderBox> {
  HarborSlotKind kind = HarborSlotKind.body;
  HarborEdge edge = HarborEdge.top;

  /// Position counted from the edge inward.
  int fromEdge = 0;
  HarborBar? bar;
  HarborBarState state = HarborBarState.open;

  @override
  String toString() => '${super.toString()}; $kind $edge #$fromEdge';
}

/// Marks a child of [RenderHarborFrame] with its slot.
class HarborSlot extends ParentDataWidget<HarborParentData> {
  const HarborSlot.body({super.key, required super.child})
    : kind = HarborSlotKind.body,
      edge = HarborEdge.top,
      fromEdge = 0,
      bar = null,
      state = HarborBarState.open;

  /// The status bar's band at the top of the frame, over the bars and under the floats, as
  /// `Scaffold` has it: what a status bar tap is hit-tested against.
  const HarborSlot.statusBar({super.key, required super.child})
    : kind = HarborSlotKind.statusBar,
      edge = HarborEdge.top,
      fromEdge = 0,
      bar = null,
      state = HarborBarState.open;

  const HarborSlot.floats({super.key, required super.child})
    : kind = HarborSlotKind.floats,
      edge = HarborEdge.top,
      fromEdge = 0,
      bar = null,
      state = HarborBarState.open;

  const HarborSlot.bar({
    super.key,
    required this.edge,
    required this.fromEdge,
    required HarborBar this.bar,
    required this.state,
    required super.child,
  }) : kind = HarborSlotKind.bar;

  final HarborSlotKind kind;
  final HarborEdge edge;
  final int fromEdge;
  final HarborBar? bar;
  final HarborBarState state;

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
    if (!identical(data.bar, bar)) {
      data.bar = bar;
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

/// The geometry a frame's build hands its layout.
@immutable
class HarborGeometry {
  const HarborGeometry({
    required this.textDirection,
    required this.systemEdges,
    required this.systemEdgesSteady,
    required this.systemEdgesOnly,
    required this.systemEdgesOnlySteady,
    required this.inheritedBars,
    required this.inheritedFadeBands,
    required this.keyboard,
    required this.bodyClearsKeyboard,
    required this.minimum,
    required this.margin,
    required this.sizing,
    required this.viewHeight,
    required this.maxExtentFraction,
    this.frameSize,
    this.roomFloor = EdgeInsetsDirectional.zero,
    this.hinges = const <Rect>[],
    this.screenSize = Size.zero,
  });

  /// The hinges and folds this frame's policy keeps bars off, in the screen's coordinates.
  /// Read only by a frame as big as the screen, whose coordinates are the screen's.
  final List<Rect> hinges;

  /// The screen's size, to tell whether this frame fills it.
  final Size screenSize;

  /// System edges handled above this frame that still cover it: kept out of the room, though the
  /// bars and the body read zero there.
  final EdgeInsetsDirectional roomFloor;

  /// The frame size to report, for a component frame: its page's, which the
  /// keyboard never shrinks. Null reports this frame's own size.
  final Size? frameSize;

  final TextDirection textDirection;

  /// What the bars on each edge absorb, and the least the body keeps clear of:
  /// the system edges plus whatever bars of an outer frame reach in.
  final EdgeInsetsDirectional systemEdges;

  /// [systemEdges] as it is with the keyboard down.
  final EdgeInsetsDirectional systemEdgesSteady;

  /// The platform's share of [systemEdges], for the room.
  final EdgeInsetsDirectional systemEdgesOnly;

  /// [systemEdgesOnly] as it is with the keyboard down.
  final EdgeInsetsDirectional systemEdgesOnlySteady;

  /// How far an outer frame's bars reach into this one.
  final EdgeInsetsDirectional inheritedBars;
  final Map<HarborEdge, HarborFadeBand> inheritedFadeBands;

  /// How far the keyboard reaches into this frame.
  final double keyboard;
  final bool bodyClearsKeyboard;

  /// A floor under what the body keeps clear of on each edge.
  final EdgeInsetsDirectional minimum;
  final EdgeInsetsDirectional margin;
  final HarborSizing sizing;

  /// The height of the screen, to place page covers measured from its bottom.
  final double viewHeight;

  /// For a frame that hugs: the most of the space above the keyboard the
  /// frame may take, or null for all of it.
  final double? maxExtentFraction;

  @override
  bool operator ==(final Object other) =>
      other is HarborGeometry &&
      other.textDirection == textDirection &&
      other.systemEdges == systemEdges &&
      other.systemEdgesSteady == systemEdgesSteady &&
      other.systemEdgesOnly == systemEdgesOnly &&
      other.systemEdgesOnlySteady == systemEdgesOnlySteady &&
      other.inheritedBars == inheritedBars &&
      other.inheritedFadeBands.length == inheritedFadeBands.length &&
      other.inheritedFadeBands.entries.every(
        (final MapEntry<HarborEdge, HarborFadeBand> e) => inheritedFadeBands[e.key] == e.value,
      ) &&
      other.keyboard == keyboard &&
      other.bodyClearsKeyboard == bodyClearsKeyboard &&
      other.minimum == minimum &&
      other.margin == margin &&
      other.sizing == sizing &&
      other.viewHeight == viewHeight &&
      other.maxExtentFraction == maxExtentFraction &&
      other.frameSize == frameSize &&
      other.roomFloor == roomFloor &&
      listEquals(other.hinges, hinges) &&
      other.screenSize == screenSize;

  @override
  int get hashCode => Object.hash(
    textDirection,
    systemEdges,
    systemEdgesSteady,
    systemEdgesOnly,
    systemEdgesOnlySteady,
    inheritedBars,
    keyboard,
    bodyClearsKeyboard,
    minimum,
    margin,
    sizing,
    viewHeight,
    maxExtentFraction,
    roomFloor,
    Object.hashAll(hinges),
    screenSize,
  );
}

/// Lays a frame out: bars first, then the body with what the bars took,
/// then the floats in the room that is left, all in one layout pass.
class HarborLayout extends MultiChildRenderObjectWidget {
  const HarborLayout({super.key, required this.geometry, required this.controller, required super.children});

  final HarborGeometry geometry;
  final HarborController controller;

  @override
  RenderHarborFrame createRenderObject(final BuildContext context) =>
      RenderHarborFrame(geometry: geometry, controller: controller);

  @override
  void updateRenderObject(final BuildContext context, final RenderHarborFrame renderObject) {
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

class RenderHarborFrame extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, HarborParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, HarborParentData> {
  RenderHarborFrame({required this._geometry, required this._controller}) {
    _controller.layoutBox = this;
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
      _controller.pageCoverChanges.removeListener(_pageCoverMoved);
      value.pageCoverChanges.addListener(_pageCoverMoved);
    }
    _controller = value;
    value.layoutBox = this;
    markNeedsLayout();
  }

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _controller.pageCoverChanges.addListener(_pageCoverMoved);
  }

  void _pageCoverMoved() {
    // Told between drawn frames, so the last one's transforms can be read now and
    // the new cover reaches the very next layout.
    if (attached && hasSize && SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _edgeCoverage = _edgeCoverageNow();
      _edgeCoverageHeight = size.height;
    }
    markNeedsLayout();
    markNeedsPaint();
  }

  double _edgeCoverageNow() {
    double covered = 0.0;
    for (final double top in _controller.pageCoverTopsInGlobal) {
      final double local = globalToLocal(Offset(0.0, top)).dy;
      covered = math.max(covered, (size.height - local).clamp(0.0, size.height));
    }
    return covered;
  }

  @override
  void detach() {
    _controller.pageCoverChanges.removeListener(_pageCoverMoved);
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

  /// How far this frame's bottom sits above the screen's, measured when it
  /// last painted (ancestors can't be asked during layout).
  double _gapBelow = 0.0;

  /// How far page covers that report a top edge cover this frame, measured
  /// when it last painted.
  double _edgeCoverage = 0.0;

  /// The height [_edgeCoverage] was measured against.
  double _edgeCoverageHeight = 0.0;

  /// The cover to lay out against at [height]. The cover is only known after it paints, so after
  /// a turn or a fold the last measurement belongs to the old shape: used as pixels, a sheet over
  /// 365 of portrait's 874 covered nearly all of landscape's 402 for a drawn frame, and the page under
  /// it overflowed. Scaled by the change in height instead, it starts close to where the sheet
  /// will settle, and the next paint measures it exactly.
  double _pageCoverInFrame(final double height) {
    final double coverage = _controller.pageCoverage;
    final double fromBottom = coverage <= 0 ? 0.0 : math.max(0.0, coverage - _gapBelow);
    double edge = _edgeCoverage;
    if (edge > 0 && _edgeCoverageHeight > 0 && height.isFinite && (height - _edgeCoverageHeight).abs() > 0.5) {
      edge = edge * height / _edgeCoverageHeight;
    }
    return math.max(fromBottom, edge);
  }

  void _measureEdgeCoverage() {
    // The frame itself may have moved under a still cover.
    final double covered = _edgeCoverageNow();
    _edgeCoverageHeight = size.height;
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
      if (_controller.pageCoverage > 0) {
        SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
          if (attached) {
            markNeedsLayout();
          }
        });
      }
    }
  }

  bool _debugCheckHasBoundedConstraints({required final bool hug}) {
    assert(() {
      if (constraints.hasBoundedWidth && (hug || constraints.hasBoundedHeight)) {
        return true;
      }
      final String axis = constraints.hasBoundedWidth ? 'height' : 'width';
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('${_debugName()} was given unbounded $axis.'),
        ErrorDescription(
          'A HarborFrame fills the space it is given, as a Scaffold does, so it needs bounded constraints. '
          'This usually happens when a HarborFrame is placed in a scroll view, a Column or a Row.',
        ),
        DiagnosticsProperty<BoxConstraints>(
          'The constraints were',
          constraints,
          style: DiagnosticsTreeStyle.errorProperty,
        ),
        ErrorHint(
          constraints.hasBoundedWidth
              ? 'Give the HarborFrame a height (a SizedBox, or Expanded in a Column), or use '
                    'HarborFrame(sizing: HarborSizing.hug()) to make it as tall as its body.'
              : 'Give the HarborFrame a width, for example with a SizedBox, or Expanded in a Row. '
                    'HarborSizing.hug() hugs the height only; a HarborFrame always fills its width.',
        ),
      ]);
    }());
    return true;
  }

  bool _debugCheckSolidOutsideOverlays(final HarborEdge edge, {required final bool seenOverlay}) {
    assert(() {
      if (!seenOverlay) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('${_debugName()} lists a solid bar inside an overlay bar on its ${edge.name} edge.'),
        ErrorDescription(
          'The body stops at a solid bar and runs under an overlay bar, so the bars on an edge are '
          'its solid bars first, nearest the edge, then its overlay bars.',
        ),
        ErrorHint(
          'List every solid bar nearer the ${edge.name} edge than the overlay bars: '
          '${edge == HarborEdge.bottom || edge == HarborEdge.end ? 'after' : 'before'} them in HarborFrame.${edge.name}.',
        ),
      ]);
    }());
    return true;
  }

  String _debugName() =>
      _controller.debugLabel == null ? 'A HarborFrame' : 'The HarborFrame "${_controller.debugLabel}"';

  @override
  void performLayout() {
    final HarborGeometry g = _geometry;
    final bool hug = g.sizing.hugs;
    assert(_debugCheckHasBoundedConstraints(hug: hug));
    final double width = constraints.maxWidth;
    final double maxHeight = constraints.hasBoundedHeight ? constraints.maxHeight : double.infinity;
    final double barMaxHeight = maxHeight.isFinite ? maxHeight : 100000.0;

    RenderBox? body;
    RenderBox? statusBar;
    RenderBox? floats;
    final Map<HarborEdge, List<_Placed>> byEdge = <HarborEdge, List<_Placed>>{
      for (final HarborEdge e in HarborEdge.values) e: <_Placed>[],
    };

    // 1. Measure the bars: the side bars first, since they own the corners. A rail runs the
    // frame's full height and a header or a tab bar runs between the rails, as a tablet's
    // navigation rail sits beside its app bar. A header used to run the full width, under the
    // rail, and its title had no way to know the rail was there.
    final List<RenderBox> verticalBars = <RenderBox>[];
    void measure(final RenderBox child, final BoxConstraints barConstraints) {
      final HarborParentData data = child.parentData! as HarborParentData;
      child.layout(barConstraints, parentUsesSize: true);
      double extent = data.edge.isVertical ? child.size.height : child.size.width;
      double resting = extent;
      if (child is RenderHarborBarFrame) {
        extent = child.extent;
        resting = child.restingExtent;
      }
      final double visual = data.edge.isVertical ? child.size.height : child.size.width;
      byEdge[data.edge]!.add(_Placed(child, data, extent, resting, visual));
    }

    // A hinge or fold the page's policy keeps bars off, as Microsoft and Google both ask: a bar is
    // not laid across it, but moved to one side. Only a frame that fills the screen reads them,
    // since the display features are in the screen's coordinates.
    final bool fillsScreen =
        maxHeight.isFinite && (width - g.screenSize.width).abs() < 0.5 && (maxHeight - g.screenSize.height).abs() < 0.5;
    Rect? verticalHinge;
    Rect? horizontalHinge;
    if (fillsScreen) {
      for (final Rect hinge in g.hinges) {
        if (hinge.top <= 0.5 && hinge.bottom >= maxHeight - 0.5 && hinge.left > 0.5 && hinge.right < width - 0.5) {
          verticalHinge ??= hinge;
        } else if (hinge.left <= 0.5 &&
            hinge.right >= width - 0.5 &&
            hinge.top > 0.5 &&
            hinge.bottom < maxHeight - 0.5) {
          horizontalHinge ??= hinge;
        }
      }
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final HarborParentData data = child.parentData! as HarborParentData;
      switch (data.kind) {
        case HarborSlotKind.body:
          body = child;
        case HarborSlotKind.statusBar:
          statusBar = child;
        case HarborSlotKind.floats:
          floats = child;
        case HarborSlotKind.bar:
          // Unbounded along the edge's depth, as a Row or Column leaves its children. Bounding it
          // at the frame let any widget that fills what it is given (a NavigationRail, an AppBar,
          // an empty Container) take the whole frame and leave the body nothing, with no error.
          // Unbounded, those size as they do in a Row or Column, and one that truly wants to fill
          // (a ListView) fails loudly, which is the failure Flutter developers already know.
          if (data.edge.isVertical) {
            verticalBars.add(child);
          } else {
            final double sideHeight = horizontalHinge == null ? barMaxHeight : horizontalHinge.top;
            measure(child, BoxConstraints(minHeight: sideHeight, maxHeight: sideHeight));
          }
      }
      child = data.nextSibling;
    }
    // The space the side bars hold at rest: a rail that widens over the page while it has focus
    // does not squeeze the header, and one that withdraws gives its corners back as it goes.
    double sideAtRest(final HarborEdge edge) =>
        byEdge[edge]!.fold(0.0, (final double sum, final _Placed p) => sum + p.resting);
    final double cornerStart = math.min(sideAtRest(HarborEdge.start), width);
    final double cornerEnd = math.min(sideAtRest(HarborEdge.end), width - cornerStart);
    final bool ltr = g.textDirection == TextDirection.ltr;
    // Between the side bars, in physical coordinates; and kept to the screen where reading starts
    // when a vertical hinge falls between them.
    double runLeft = ltr ? cornerStart : cornerEnd;
    double runRight = width - (ltr ? cornerEnd : cornerStart);
    if (verticalHinge != null && verticalHinge.left > runLeft && verticalHinge.right < runRight) {
      if (ltr) {
        runRight = verticalHinge.left;
      } else {
        runLeft = verticalHinge.right;
      }
    }
    final double between = math.max(0.0, runRight - runLeft);
    for (final RenderBox bar in verticalBars) {
      measure(bar, BoxConstraints(minWidth: between, maxWidth: between));
    }
    for (final List<_Placed> bars in byEdge.values) {
      bars.sort((final _Placed a, final _Placed b) => a.data.fromEdge.compareTo(b.data.fromEdge));
    }

    // 2. Stack each edge from the edge inward. Bars that ride the keyboard rise with it.
    final double keyboard = g.keyboard;
    final Map<HarborEdge, double> far = <HarborEdge, double>{};
    final Map<HarborEdge, double> farResting = <HarborEdge, double>{};
    final Map<HarborEdge, double> farSteady = <HarborEdge, double>{};
    final Map<HarborEdge, double> solidEnd = <HarborEdge, double>{};
    final Map<HarborEdge, double> solidEndSteady = <HarborEdge, double>{};
    final Map<HarborEdge, HarborEdgeEffect> innerEdgeEffect = <HarborEdge, HarborEdgeEffect>{};
    final Map<HarborEdge, HarborBarKind> innerKind = <HarborEdge, HarborBarKind>{};
    for (final HarborEdge edge in HarborEdge.values) {
      double offset = 0.0;
      double restingOffset = 0.0;
      double steadyOffset = 0.0;
      bool seenOverlay = false;
      double solidExtent = 0.0;
      double solidExtentSteady = 0.0;
      for (final _Placed bar in byEdge[edge]!) {
        final HarborBar config = bar.data.bar!;
        final bool floats = edge == HarborEdge.bottom && config.keyboard == HarborKeyboardStance.rides;
        bar.start = floats ? math.max(offset, keyboard) : offset;
        bar.restingStart = restingOffset;
        bar.steadyStart = steadyOffset;
        offset = bar.start + bar.extent;
        restingOffset += bar.resting;
        steadyOffset += bar.extent;
        if (config.kind == HarborBarKind.solid) {
          assert(_debugCheckSolidOutsideOverlays(edge, seenOverlay: seenOverlay));
          solidExtent = offset;
          solidExtentSteady = steadyOffset;
        } else {
          seenOverlay = true;
        }
        if (bar.extent > 0) {
          innerEdgeEffect[edge] = config.edgeEffect;
          innerKind[edge] = config.kind;
        }
      }
      far[edge] = offset;
      farResting[edge] = restingOffset;
      farSteady[edge] = steadyOffset;
      solidEnd[edge] = solidExtent;
      solidEndSteady[edge] = solidExtentSteady;
    }

    // 3. The body's box: inside the solid bars, and above the keyboard when it clears it.
    final double bodyInsetBottom = g.bodyClearsKeyboard
        ? math.max(solidEnd[HarborEdge.bottom]!, keyboard)
        : solidEnd[HarborEdge.bottom]!;
    final EdgeInsetsDirectional bodyInset = EdgeInsetsDirectional.fromSTEB(
      solidEnd[HarborEdge.start]!,
      solidEnd[HarborEdge.top]!,
      solidEnd[HarborEdge.end]!,
      bodyInsetBottom,
    );

    // 4. What is in the way on each edge, from the frame's edge.
    final double coversPage = _pageCoverInFrame(maxHeight);
    double fadeClearance(final HarborEdge edge) => far[edge]! > 0 ? (innerEdgeEffect[edge]?.clearance ?? 0.0) : 0.0;
    double systemEdgeOf(final EdgeInsetsDirectional systemEdges, final HarborEdge edge) =>
        math.max(HarborEdges.of(systemEdges, edge), HarborEdges.of(g.minimum, edge));
    final EdgeInsetsDirectional barsLive = HarborEdges.build((final HarborEdge e) {
      double v = far[e]! > 0 ? far[e]! + fadeClearance(e) : 0.0;
      if (e == HarborEdge.bottom) {
        v = math.max(v, coversPage);
      }
      return v;
    });
    final EdgeInsetsDirectional barsResting = HarborEdges.build(
      (final HarborEdge e) => farResting[e]! > 0 ? farResting[e]! + fadeClearance(e) : 0.0,
    );
    // `MediaQuery.padding` never carries the keyboard: that stays in
    // `viewInsets`, as Flutter has it. The room does include it.
    final EdgeInsetsDirectional obstruction = HarborEdges.build(
      (final HarborEdge e) => math.max(systemEdgeOf(g.systemEdges, e), HarborEdges.of(barsLive, e)),
    );
    final EdgeInsetsDirectional obstructionWithKeyboard = HarborEdges.build(
      (final HarborEdge e) =>
          e == HarborEdge.bottom ? math.max(HarborEdges.of(obstruction, e), keyboard) : HarborEdges.of(obstruction, e),
    );
    final EdgeInsetsDirectional steady = HarborEdges.build((final HarborEdge e) {
      final double bars = farSteady[e]! > 0 ? farSteady[e]! + fadeClearance(e) : 0.0;
      return math.max(systemEdgeOf(g.systemEdgesSteady, e), bars);
    });
    double past(final EdgeInsetsDirectional value, final HarborEdge e) =>
        math.max(0.0, HarborEdges.of(value, e) - HarborEdges.of(bodyInset, e));

    final Map<HarborEdge, HarborFadeBand> ownFadeBands = <HarborEdge, HarborFadeBand>{};
    for (final HarborEdge e in HarborEdge.values) {
      final HarborEdgeEffect? edgeEffect = innerEdgeEffect[e];
      if (edgeEffect == null || edgeEffect.kind != HarborEdgeEffectKind.fade || far[e]! <= 0) {
        continue;
      }
      final double barFace = math.max(0.0, far[e]! - HarborEdges.of(bodyInset, e));
      ownFadeBands[e] = HarborFadeBand(
        barFace: barFace,
        fadeEnd: barFace + edgeEffect.length,
        // A fade at its defaults leaves them to the painter, as before they were options.
        faceOpacity: edgeEffect.faceOpacity == 0.25 ? null : edgeEffect.faceOpacity,
        curve: edgeEffect.curve == Curves.linear ? null : edgeEffect.curve,
      );
    }
    final Map<HarborEdge, HarborFadeBand> fadeBands = <HarborEdge, HarborFadeBand>{
      for (final MapEntry<HarborEdge, HarborFadeBand> inherited in g.inheritedFadeBands.entries)
        if (!ownFadeBands.containsKey(inherited.key) &&
            HarborEdges.of(bodyInset, inherited.key) < inherited.value.fadeEnd)
          inherited.key: inherited.value.measuredFrom(HarborEdges.of(bodyInset, inherited.key)),
      ...ownFadeBands,
    };

    final EdgeInsetsDirectional padding = HarborEdges.build((final HarborEdge e) => past(obstruction, e));
    final EdgeInsetsDirectional viewPadding = HarborEdges.build((final HarborEdge e) => past(steady, e));
    final EdgeInsetsDirectional systemEdgesPast = HarborEdges.build(
      (final HarborEdge e) => past(HarborEdges.build((final HarborEdge x) => systemEdgeOf(g.systemEdgesOnly, x)), e),
    );
    // Past the solid bars only: the keyboard's space is what the steady system edges hold through.
    final EdgeInsetsDirectional systemEdgesSteadyPast = HarborEdges.build(
      (final HarborEdge e) => math.max(0.0, systemEdgeOf(g.systemEdgesOnlySteady, e) - solidEnd[e]!),
    );
    final EdgeInsetsDirectional barsPast = HarborEdges.build(
      (final HarborEdge e) => past(HarborEdges.max(barsLive, g.inheritedBars), e),
    );
    final EdgeInsetsDirectional restingPast = HarborEdges.build(
      (final HarborEdge e) => past(HarborEdges.max(barsResting, g.inheritedBars), e),
    );

    // 5. Size the frame and lay the body out.
    final double insetH = bodyInset.start + bodyInset.end;
    final double insetV = bodyInset.top + bodyInset.bottom;
    double height;
    Size bodySize;
    HarborBodyPayload payload(final Size frame) => HarborBodyPayload(
      padding: padding.resolve(g.textDirection),
      viewPadding: viewPadding.resolve(g.textDirection),
      viewInsetsBottom: g.bodyClearsKeyboard ? 0.0 : math.max(0.0, keyboard - bodyInset.bottom),
      room: HarborRoomData(
        systemEdges: systemEdgesPast,
        systemEdgesSteady: systemEdgesSteadyPast,
        bars: barsPast,
        barsResting: restingPast,
        fadeBands: fadeBands,
        margin: g.margin,
        frameSize: g.frameSize ?? frame,
        hasBars: <HarborEdge>{
          for (final HarborEdge e in HarborEdge.values)
            if (byEdge[e]!.isNotEmpty) e,
        },
      ),
      ownFadeBands: ownFadeBands,
    );
    if (hug) {
      double cap = maxHeight.isFinite ? maxHeight : double.infinity;
      final double? fraction = g.maxExtentFraction;
      if (fraction != null && cap.isFinite) {
        // A share of the space above the keyboard, plus the keyboard's space, which a body that
        // clears the keyboard takes inside the frame. A body that does not leaves the keyboard outside
        // the frame's height, so the share is of the whole: adding the keyboard back let a 0.9
        // sheet whose body ran under the keyboard grow past 0.9 of the screen.
        cap = g.bodyClearsKeyboard ? (cap - keyboard) * fraction + keyboard : cap * fraction;
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

    // 6. Place the bars.
    final List<HarborBarRecord> records = <HarborBarRecord>[];
    for (final HarborEdge edge in HarborEdge.values) {
      for (final _Placed bar in byEdge[edge]!) {
        final Size s = bar.box.size;
        final Offset offset = switch (edge) {
          HarborEdge.top => Offset(runLeft, bar.start),
          HarborEdge.bottom => Offset(runLeft, height - bar.start - s.height),
          HarborEdge.start => Offset(ltr ? bar.start : width - bar.start - s.width, 0.0),
          HarborEdge.end => Offset(ltr ? width - bar.start - s.width : bar.start, 0.0),
        };
        bar.data.offset = offset;
        records.add(
          HarborBarRecord(
            edge: edge,
            kind: bar.data.bar!.kind,
            rect: offset & s,
            extent: bar.extent,
            restingExtent: bar.resting,
            state: bar.data.state,
            keyboard: bar.data.bar!.keyboard,
            label: bar.data.bar!.debugLabel,
          ),
        );
      }
    }

    // 7. The room nothing covers, and the floats in it.
    final EdgeInsets physicalObstruction = HarborEdges.max(
      obstructionWithKeyboard,
      g.roomFloor,
    ).resolve(g.textDirection);
    final Rect room = Rect.fromLTRB(
      math.min(physicalObstruction.left, width),
      math.min(physicalObstruction.top, height),
      math.max(physicalObstruction.left, width - physicalObstruction.right),
      math.max(physicalObstruction.top, height - physicalObstruction.bottom),
    );
    if (statusBar != null) {
      statusBar.layout(BoxConstraints(minWidth: width, maxWidth: width, maxHeight: height));
      (statusBar.parentData! as HarborParentData).offset = Offset.zero;
    }
    if (floats != null) {
      // The same room with the system edges left in: only the bars and the keyboard keep out of it.
      final EdgeInsets physicalBars = HarborEdges.build(
        (final HarborEdge e) =>
            e == HarborEdge.bottom ? math.max(HarborEdges.of(barsLive, e), keyboard) : HarborEdges.of(barsLive, e),
      ).resolve(g.textDirection);
      final Rect roomWithSystemEdges = Rect.fromLTRB(
        math.min(physicalBars.left, width),
        math.min(physicalBars.top, height),
        math.max(physicalBars.left, width - physicalBars.right),
        math.max(physicalBars.top, height - physicalBars.bottom),
      );
      floats.layout(HarborFloatConstraints(frame: size, room: room, roomWithSystemEdges: roomWithSystemEdges));
      (floats.parentData! as HarborParentData).offset = Offset.zero;
    }

    _controller.recordLayout(
      HarborLayoutRecord(
        frame: Offset.zero & size,
        body: Offset(bodyInsetPhysical.left, bodyInsetPhysical.top) & bodySize,
        room: room,
        bars: records,
        obstruction: obstructionWithKeyboard,
        keyboard: keyboard,
      ),
    );
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
