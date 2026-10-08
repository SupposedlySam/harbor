import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureState;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'render_harbor.dart';

/// A point a buoy can be anchored to: give it to a [HarborAnchorPoint] around
/// the widget to anchor to (a button in a dock, a row in a list), and to the
/// [HarborBuoy.anchored] that should sit by it.
class HarborAnchor extends ChangeNotifier {
  HarborAnchor({this.debugLabel});

  final String? debugLabel;

  @override
  String toString() => debugLabel == null ? describeIdentity(this) : '${describeIdentity(this)}($debugLabel)';

  RenderBox? _box;
  bool _disposed = false;

  /// The anchored widget's box, while it is in the tree and laid out.
  RenderBox? get box => (_box != null && _box!.attached && _box!.hasSize) ? _box : null;

  void _attach(final RenderBox box) {
    assert(() {
      final RenderBox? previous = _box;
      if (previous != null && !identical(previous, box)) {
        (_debugPreviousBoxes ??= <RenderBox>{}).add(previous);
        _debugScheduleSharedCheck();
      }
      return true;
    }());
    _box = box;
    _moved();
  }

  void _detach(final RenderBox box) {
    if (identical(_box, box)) {
      _box = null;
      _moved();
    }
    assert(() {
      _debugPreviousBoxes?.remove(box);
      return true;
    }());
  }

  // The boxes a later attach replaced. As with a LayerLink's leaders, each one
  // must detach by the end of the frame, or two points share this anchor.
  Set<RenderBox>? _debugPreviousBoxes;
  bool _debugSharedCheckScheduled = false;

  void _debugScheduleSharedCheck() {
    if (_debugSharedCheckScheduled) {
      return;
    }
    _debugSharedCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _debugSharedCheckScheduled = false;
      final Set<RenderBox> stillAttached = <RenderBox>{
        for (final RenderBox previous in _debugPreviousBoxes ?? const <RenderBox>{})
          if (previous.attached && !identical(previous, _box)) previous,
      };
      _debugPreviousBoxes = null;
      if (stillAttached.isEmpty || _disposed) {
        return;
      }
      FlutterError.reportError(FlutterErrorDetails(
        exception: FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('More than one HarborAnchorPoint is using the same HarborAnchor${debugLabel == null ? '' : ' "$debugLabel"'}.'),
          ErrorDescription(
            'An anchor refers to one point. With several attached, a buoy anchored to it sits by whichever '
            'laid out last, and when that one leaves the anchor has no point while the others are still there.',
          ),
          ErrorHint(
            'Give each HarborAnchorPoint its own HarborAnchor, for example one per row of a list, '
            'or wrap only the row whose buoy is showing.',
          ),
          if (_box case final RenderBox current) current.describeForError('The point the anchor is using'),
          for (final RenderBox previous in stillAttached) previous.describeForError('Also attached'),
        ]),
        library: 'harbor',
      ));
    }, debugLabel: 'HarborAnchor.sharedCheck');
  }

  bool _pending = false;

  void _moved() {
    if (_pending || _disposed || !hasListeners) {
      return;
    }
    _pending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _pending = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Marks [child] as the point [anchor] refers to.
class HarborAnchorPoint extends SingleChildRenderObjectWidget {
  const HarborAnchorPoint({super.key, required this.anchor, super.child});

  final HarborAnchor anchor;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderAnchorPoint(anchor);

  @override
  void updateRenderObject(final BuildContext context, final RenderObject renderObject) {
    (renderObject as _RenderAnchorPoint).anchor = anchor;
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborAnchor>('anchor', anchor));
  }
}

class _RenderAnchorPoint extends RenderProxyBox {
  _RenderAnchorPoint(this._anchor);

  HarborAnchor _anchor;
  set anchor(final HarborAnchor value) {
    if (!identical(_anchor, value)) {
      _anchor._detach(this);
      _anchor = value;
      if (attached) {
        value._attach(this);
      }
    }
  }

  Offset? _lastGlobal;

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _anchor._attach(this);
  }

  @override
  void detach() {
    _anchor._detach(this);
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    _anchor._moved();
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    super.paint(context, offset);
    final Offset global = localToGlobal(Offset.zero);
    if (global != _lastGlobal) {
      _lastGlobal = global;
      _anchor._moved();
    }
  }
}

/// Which side of its anchor an anchored buoy sits on. [start] and [end] are in
/// reading order, as in `AlignmentDirectional.centerStart`: [start] is on the
/// right under right-to-left.
enum HarborBuoySide {
  above,
  below,
  start,
  end;

  @Deprecated('Use HarborBuoySide.start, the reading-order name Flutter uses.')
  static const HarborBuoySide before = start;

  @Deprecated('Use HarborBuoySide.end, the reading-order name Flutter uses.')
  static const HarborBuoySide after = end;

  HarborBuoySide get _opposite => switch (this) {
    above => below,
    below => above,
    start => end,
    end => start,
  };
}

/// How an anchored buoy lines up with its anchor across its side, as a `Row`'s or `Column`'s
/// `CrossAxisAlignment` lines up its children: above or below the anchor, [start] and [end] are in
/// reading order (a dropdown under its button's leading edge); at its start or end, they are its
/// top and bottom.
enum HarborBuoyCrossAlignment { start, center, end }

/// Where a buoy of [size] sits by the anchor at [at], inside [water], and the
/// side it landed on: on [side], [gap] away, overlapping it by [overlap], and
/// lined up with it across that side by [crossAlignment], moved [crossOffset]
/// in reading order. It is kept inside [water] across the side, and above or
/// below its anchor, never past the far edge. With [flips], it goes to the
/// opposite side when [side] has no room and that one has, and is never past
/// the far edge at the start or end of its anchor either.
({Offset offset, HarborBuoySide side}) _anchoredOffset({
  required final Rect water,
  required final Rect at,
  required final Size size,
  required final HarborBuoySide side,
  required final double gap,
  required final double overlap,
  required final TextDirection textDirection,
  final HarborBuoyCrossAlignment crossAlignment = HarborBuoyCrossAlignment.center,
  final double crossOffset = 0.0,
  final bool flips = false,
}) {
  final bool rtl = textDirection == TextDirection.rtl;
  final AxisDirection preferred = switch (side) {
    HarborBuoySide.above => AxisDirection.up,
    HarborBuoySide.below => AxisDirection.down,
    HarborBuoySide.start => rtl ? AxisDirection.right : AxisDirection.left,
    HarborBuoySide.end => rtl ? AxisDirection.left : AxisDirection.right,
  };
  double along(final AxisDirection d) => switch (d) {
    AxisDirection.up => at.top - gap - size.height + overlap,
    AxisDirection.down => at.bottom + gap - overlap,
    AxisDirection.left => at.left - gap - size.width + overlap,
    AxisDirection.right => at.right + gap - overlap,
  };
  bool fits(final AxisDirection d) => switch (d) {
    AxisDirection.up => along(d) >= water.top,
    AxisDirection.down => along(d) + size.height <= water.bottom,
    AxisDirection.left => along(d) >= water.left,
    AxisDirection.right => along(d) + size.width <= water.right,
  };
  final AxisDirection opposite = flipAxisDirection(preferred);
  final AxisDirection direction = flips && !fits(preferred) && fits(opposite) ? opposite : preferred;
  final bool vertical = axisDirectionToAxis(direction) == Axis.vertical;
  // Across a vertical side the start is the reading start; across a horizontal one, the top.
  final bool reversed = vertical && rtl;
  final (double low, double high, double extent) = vertical ? (at.left, at.right, size.width) : (at.top, at.bottom, size.height);
  final double cross = switch ((crossAlignment, reversed)) {
        (HarborBuoyCrossAlignment.center, _) => (low + high - extent) / 2,
        (HarborBuoyCrossAlignment.start, false) || (HarborBuoyCrossAlignment.end, true) => low,
        (HarborBuoyCrossAlignment.end, false) || (HarborBuoyCrossAlignment.start, true) => high - extent,
      } +
      (reversed ? -crossOffset : crossOffset);
  double left = vertical ? cross : 0.0;
  double top = vertical ? 0.0 : cross;
  switch (direction) {
    case AxisDirection.up:
      top = math.max(along(direction), water.top);
    case AxisDirection.down:
      top = math.min(along(direction), water.bottom - size.height);
    case AxisDirection.left:
      left = flips ? math.max(along(direction), water.left) : along(direction);
    case AxisDirection.right:
      left = flips ? math.min(along(direction), water.right - size.width) : along(direction);
  }
  if (vertical) {
    left = left.clamp(water.left, math.max(water.left, water.right - size.width));
  } else {
    top = top.clamp(water.top, math.max(water.top, water.bottom - size.height));
  }
  return (offset: Offset(left, top), side: direction == preferred ? side : side._opposite);
}

/// Something afloat in a harbor: placed in the water nothing covers, so it
/// clears the coast, every dock and the keyboard without knowing about them.
///
/// Give buoys to [Harbor.buoys]. A modal buoy hides the buoys listed before it
/// while it is up (a menu over a tooltip).
///
/// See also:
///
///  * `Scaffold.floatingActionButton`, the closest Flutter slot, and [ModalBarrier], which a modal
///    buoy's barrier is like.
@immutable
class HarborBuoy with Diagnosticable {
  /// A buoy at [alignment] within the clear water, [margin] in from its edges.
  const HarborBuoy({
    this.key,
    required this.child,
    this.alignment = Alignment.bottomCenter,
    this.margin = const EdgeInsets.all(16.0),
    this.modal = false,
    this.onDismiss,
    this.barrierColor = const Color(0x00000000),
    this.barrierLabel = 'Close',
    this.within,
  }) : assert(!modal || onDismiss != null, 'A modal buoy needs onDismiss: a tap outside it and back both call it.'),
       anchor = null,
       side = HarborBuoySide.above,
       gap = 0.0,
       overlap = 0.0,
       crossAlignment = HarborBuoyCrossAlignment.center,
       crossOffset = 0.0;

  /// A buoy moored to [anchor], on its [side], [gap] away, overlapping it by
  /// [overlap] (a speech bubble whose tail sits over the button), and lined up
  /// with it across that side by [crossAlignment]. Kept inside the clear water
  /// across that side, and never past its far edge.
  const HarborBuoy.anchored({
    this.key,
    required HarborAnchor this.anchor,
    required this.child,
    this.side = HarborBuoySide.above,
    this.gap = 8.0,
    this.overlap = 0.0,
    this.crossAlignment = HarborBuoyCrossAlignment.center,
    this.crossOffset = 0.0,
    this.margin = const EdgeInsets.all(8.0),
    this.modal = false,
    this.onDismiss,
    this.barrierColor = const Color(0x00000000),
    this.barrierLabel = 'Close',
  }) : assert(!modal || onDismiss != null, 'A modal buoy needs onDismiss: a tap outside it and back both call it.'),
       alignment = Alignment.center,
       within = null;

  final Key? key;
  final Widget child;
  /// Where the buoy sits in the clear water. An [AlignmentDirectional] follows the reading
  /// direction, as a Material floating action button does.
  final AlignmentGeometry alignment;

  /// How far in from the clear water's edges; an [EdgeInsetsDirectional] follows the reading direction.
  final EdgeInsetsGeometry margin;

  /// Whether this buoy is modal while it is up (quick actions, a menu): a barrier blocks taps to
  /// the page and its docks and tells screen readers to leave the page alone, a tap outside the
  /// buoy and back both call [onDismiss], and the buoys listed before it are hidden.
  ///
  /// Until 0.2.0 a modal buoy only hid the buoys before it, with taps and back reaching the page.
  /// NOT COVERED: keyboard focus is not trapped in the buoy, as a route's would be.
  final bool modal;

  /// Called when a modal buoy is dismissed by a tap outside it or by back. Required when [modal]:
  /// the buoy is yours, so you take it away.
  final VoidCallback? onDismiss;

  /// The colour of a modal buoy's barrier; clear by default, so the page shows as it is.
  final Color barrierColor;

  /// What a screen reader announces for a modal buoy's barrier, as [ModalBarrier.semanticsLabel].
  /// A Material app passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`.
  final String barrierLabel;
  final HarborAnchor? anchor;
  final HarborBuoySide side;
  final double gap;
  final double overlap;

  /// How an anchored buoy lines up with its anchor across its [side]; centred by default.
  final HarborBuoyCrossAlignment crossAlignment;

  /// How far an anchored buoy is moved across its [side] from where [crossAlignment] puts it:
  /// toward the reading end above or below its anchor, down beside it. The horizontal part of
  /// `MenuAnchor.alignmentOffset`; [gap] and [overlap] are the rest.
  final double crossOffset;

  /// Keeps the buoy inside this rectangle (in the harbor's own coordinates)
  /// as well as inside the clear water.
  final Rect? within;

  @override
  String toStringShort() =>
      anchor == null ? objectRuntimeType(this, 'HarborBuoy') : '${objectRuntimeType(this, 'HarborBuoy')}.anchored';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Key>('key', key, defaultValue: null));
    if (anchor == null) {
      properties.add(
        DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: Alignment.bottomCenter),
      );
      properties.add(
        DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: const EdgeInsets.all(16.0)),
      );
      properties.add(DiagnosticsProperty<Rect>('within', within, defaultValue: null));
    } else {
      properties.add(DiagnosticsProperty<HarborAnchor>('anchor', anchor));
      properties.add(EnumProperty<HarborBuoySide>('side', side, defaultValue: HarborBuoySide.above));
      properties.add(DoubleProperty('gap', gap, defaultValue: 8.0));
      properties.add(DoubleProperty('overlap', overlap, defaultValue: 0.0));
      properties.add(
        DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: const EdgeInsets.all(8.0)),
      );
    }
    properties.add(FlagProperty('modal', value: modal, ifTrue: 'modal'));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss));
    properties.add(ColorProperty('barrierColor', barrierColor, defaultValue: const Color(0x00000000)));
  }
}

/// The layer a harbor floats its buoys in.
class HarborBuoyLayer extends StatefulWidget {
  const HarborBuoyLayer({super.key, required this.buoys, required this.signals});

  final List<HarborBuoy> buoys;
  final List<HarborSignalEntry> signals;

  @override
  State<HarborBuoyLayer> createState() => _HarborBuoyLayerState();
}

class _HarborBuoyLayerState extends State<HarborBuoyLayer> {
  /// The page's history entry while a modal buoy is up, so back dismisses the buoy first (and the
  /// iOS back swipe stands aside), as it does a sheet with no barrier.
  LocalHistoryEntry? _history;
  bool _removingQuietly = false;

  HarborBuoy? get _modal {
    for (final HarborBuoy buoy in widget.buoys.reversed) {
      if (buoy.modal) {
        return buoy;
      }
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHistory();
  }

  @override
  void didUpdateWidget(final HarborBuoyLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncHistory();
  }

  // After the frame: a route's history cannot change while it builds.
  void _syncHistory() {
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (!mounted) {
        return;
      }
      final ModalRoute<Object?>? route = ModalRoute.of(context);
      if (_modal != null && _history == null && route != null) {
        _history = LocalHistoryEntry(
          onRemove: () {
            _history = null;
            if (!_removingQuietly) {
              _modal?.onDismiss?.call();
            }
          },
        );
        route.addLocalHistoryEntry(_history!);
      } else if (_modal == null && _history != null) {
        _leaveHistory(route);
      }
    });
  }

  void _leaveHistory(final ModalRoute<Object?>? route) {
    final LocalHistoryEntry? history = _history;
    _history = null;
    if (history != null && route != null && route.isActive) {
      _removingQuietly = true;
      route.removeLocalHistoryEntry(history);
      _removingQuietly = false;
    }
  }

  @override
  void deactivate() {
    _leaveHistory(ModalRoute.of(context));
    super.deactivate();
  }

  List<HarborBuoy> get buoys => widget.buoys;
  List<HarborSignalEntry> get signals => widget.signals;

  @override
  Widget build(final BuildContext context) {
    // A signal keeps inside the clear water of the harbor that raised it, so it is placed again
    // whenever that harbor's clear water moves (a turn, a foldable opening): read only at build,
    // it stayed boxed into the shape the screen had when the signal went up.
    final List<Listenable> raisers = <Listenable>[
      for (final HarborSignalEntry signal in signals)
        if (signal.raisedIn case final HarborController harbor) harbor.clearWater,
    ];
    final Widget layer = raisers.isEmpty
        ? _build(context)
        : ListenableBuilder(listenable: Listenable.merge(raisers), builder: (final BuildContext context, final Widget? _) => _build(context));
    final HarborBuoy? modal = _modal;
    if (modal == null) {
      return layer;
    }
    // Under every buoy and over the page and its docks: taps beside a modal buoy dismiss it
    // instead of reaching the page, and the barrier blocks the page's semantics.
    // PASSTHROUGH, so the layer still gets the harbor's own constraints, which carry the clear
    // water. StackFit.expand handed it plain tight ones, and a modal buoy was centred in the whole
    // frame instead of the clear water.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(child: ModalBarrier(color: modal.barrierColor, onDismiss: modal.onDismiss, semanticsLabel: modal.barrierLabel)),
        layer,
      ],
    );
  }

  Widget _build(final BuildContext context) {
    final int lastModal = buoys.lastIndexWhere((final HarborBuoy b) => b.modal);
    final List<HarborBuoy> all = <HarborBuoy>[
      ...buoys,
      for (final HarborSignalEntry signal in signalsInSight(signals))
        HarborBuoy(
          key: ObjectKey(signal),
          alignment: signal.alignment,
          within: _local(context, signal.avoidInGlobal),
          child: _Signal(entry: signal),
        ),
    ];
    return _BuoyLayout(
      buoys: all,
      children: <Widget>[
        for (int i = 0; i < all.length; i++)
          KeyedSubtree(
            key: all[i].key ?? ValueKey<int>(i),
            child: Visibility(
              visible: lastModal < 0 || i >= lastModal,
              maintainState: true,
              child: all[i].child,
            ),
          ),
      ],
    );
  }
}

Rect? _local(final BuildContext context, final Rect? global) {
  if (global == null) {
    return null;
  }
  final RenderObject? box = HarborController.maybeOf(context)?.renderBox;
  if (box is! RenderBox || !box.attached || !box.hasSize) {
    return null;
  }
  return Rect.fromPoints(box.globalToLocal(global.topLeft), box.globalToLocal(global.bottomRight));
}

class _BuoyLayout extends MultiChildRenderObjectWidget {
  const _BuoyLayout({required this.buoys, required super.children});

  final List<HarborBuoy> buoys;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderBuoyLayer(buoys, Directionality.maybeOf(context) ?? TextDirection.ltr).._avoid = _hinges(context);

  @override
  void updateRenderObject(final BuildContext context, final _RenderBuoyLayer renderObject) {
    renderObject
      ..buoys = buoys
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr
      ..avoid = _hinges(context);
  }

  /// The hinges and half-open folds a buoy keeps off, chosen as `DisplayFeatureSubScreen` chooses
  /// them: a flat fold has no width and content may span it. Read through `displayFeaturesOf`
  /// alone, so the layer is not rebuilt for every other change to `MediaQuery`.
  static List<Rect> _hinges(final BuildContext context) => <Rect>[
    for (final DisplayFeature feature in MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[])
      if (feature.bounds.shortestSide > 0 || feature.state == DisplayFeatureState.postureHalfOpened) feature.bounds,
  ];
}

class _BuoyParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether the last paint painted this buoy. An anchored buoy is not painted while its anchor
  /// has no box, and its offset is then stale, so it takes no taps and is not read out either.
  bool painted = false;
}

class _RenderBuoyLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _BuoyParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _BuoyParentData> {
  _RenderBuoyLayer(this._buoys, this._textDirection);

  List<HarborBuoy> _buoys;

  List<Rect> _avoid = const <Rect>[];
  set avoid(final List<Rect> value) {
    if (listEquals(value, _avoid)) {
      return;
    }
    _avoid = value;
    markNeedsLayout();
  }

  /// [water], or the one screen of it that holds [buoy]'s alignment point when a hinge splits it.
  /// A point on the hinge itself goes to the screen where reading starts, as a dialog does. Laid
  /// out in the layer's own coordinates, taken to be the screen's, as `DisplayFeatureSubScreen` does.
  Rect _screenFor(final HarborBuoy buoy, final Rect water) {
    if (_avoid.isEmpty) {
      return water;
    }
    final List<Rect> screens = DisplayFeatureSubScreen.subScreensInBounds(water, _avoid).toList();
    if (screens.length < 2) {
      return screens.isEmpty ? water : screens.single;
    }
    final Offset point = buoy.alignment.resolve(_textDirection).withinRect(water);
    for (final Rect screen in screens) {
      if (screen.contains(point)) {
        return screen;
      }
    }
    screens.sort((final Rect a, final Rect b) => a.left.compareTo(b.left));
    return _textDirection == TextDirection.rtl ? screens.last : screens.first;
  }

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  set buoys(final List<HarborBuoy> value) {
    _buoys = value;
    markNeedsLayout();
  }

  // Its own layer, since it is painted again every frame while it has an anchored buoy.
  @override
  bool get isRepaintBoundary => true;

  final _FollowEveryFrame _follow = _FollowEveryFrame();

  @override
  void detach() {
    _follow.cancel();
    super.detach();
  }

  @override
  void setupParentData(final RenderObject child) {
    if (child.parentData is! _BuoyParentData) {
      child.parentData = _BuoyParentData();
    }
  }

  @override
  Size computeDryLayout(final BoxConstraints constraints) => constraints.biggest;

  Rect _clear = Rect.zero;

  @override
  void performLayout() {
    size = constraints.biggest;
    _clear = constraints is HarborBuoyConstraints ? (constraints as HarborBuoyConstraints).clearWater : Offset.zero & size;
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      final HarborBuoy buoy = _buoys[i];
      final Rect? within = buoy.within;
      final Rect bounded = within == null || !within.overlaps(_clear) ? _clear : _clear.intersect(within);
      final Rect water = buoy.anchor == null
          ? _screenFor(buoy, buoy.margin.resolve(_textDirection).deflateRect(bounded))
          : buoy.margin.resolve(_textDirection).deflateRect(bounded);
      child.layout(BoxConstraints.loose(Size(math.max(0.0, water.width), math.max(0.0, water.height))), parentUsesSize: true);
      // Anchored buoys are placed when they paint, once their anchors have a size.
      data.offset = buoy.anchor == null ? buoy.alignment.resolve(_textDirection).inscribe(child.size, water).topLeft : data.offset;
      child = data.nextSibling;
      i++;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    if (_buoys.any((final HarborBuoy b) => b.anchor != null)) {
      _follow.next(markNeedsPaint);
    }
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      final HarborBuoy buoy = _buoys[i];
      final RenderBox? anchorBox = buoy.anchor?.box;
      final bool painted = buoy.anchor == null || anchorBox != null;
      if (painted != data.painted) {
        data.painted = painted;
        markNeedsSemanticsUpdate();
      }
      if (buoy.anchor != null) {
        if (anchorBox == null) {
          child = data.nextSibling;
          i++;
          continue;
        }
        data.offset = _anchoredOffset(
          water: buoy.margin.resolve(_textDirection).deflateRect(_clear),
          at: MatrixUtils.transformRect(anchorBox.getTransformTo(this), Offset.zero & anchorBox.size),
          size: child.size,
          side: buoy.side,
          gap: buoy.gap,
          overlap: buoy.overlap,
          crossAlignment: buoy.crossAlignment,
          crossOffset: buoy.crossOffset,
          textDirection: _textDirection,
        ).offset;
      }
      context.paintChild(child, data.offset + offset);
      child = data.nextSibling;
      i++;
    }
  }

  @override
  bool paintsChild(final RenderBox child) => (child.parentData! as _BuoyParentData).painted;

  @override
  void visitChildrenForSemantics(final RenderObjectVisitor visitor) {
    RenderBox? child = firstChild;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      if (data.painted) {
        visitor(child);
      }
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      final RenderBox shown = child;
      if (data.painted &&
          result.addWithPaintOffset(
            offset: data.offset,
            position: position,
            hitTest: (final BoxHitTestResult result, final Offset transformed) => shown.hitTest(result, position: transformed),
          )) {
        return true;
      }
      child = data.previousSibling;
    }
    return false;
  }
}

/// An anchored buoy opened from anywhere: a menu from a list row, a popover
/// from a button, declared where it is opened rather than in [Harbor.buoys].
///
/// It is an [OverlayPortal]: while [controller] shows it, [buoyBuilder]'s
/// buoy floats in the nearest [Overlay] and is placed as a
/// [HarborBuoy.anchored] is, in the clear water of the harbor around this
/// widget: by [anchor] (or by [child] when there is none), on its [side],
/// [gap] away, lined up by [crossAlignment], [margin] in from the water's
/// edges. When [side] has no room and the opposite side has, it [flips] there;
/// otherwise it is kept inside the clear water. [sideOf] tells the buoy which
/// side it landed on.
///
/// With [onDismiss], it closes as a `MenuAnchor` does: a tap outside both the
/// buoy and [child], Escape while focus is in either, and back all call it.
///
/// See also:
///
///  * [RawMenuAnchor] and `MenuAnchor`, which also open from an [OverlayPortal] and add menu
///    semantics and keyboard navigation, which this does not.
class HarborPortalBuoy extends StatefulWidget {
  const HarborPortalBuoy({
    super.key,
    required this.controller,
    required this.buoyBuilder,
    required this.child,
    this.anchor,
    this.side = HarborBuoySide.above,
    this.gap = 8.0,
    this.overlap = 0.0,
    this.crossAlignment = HarborBuoyCrossAlignment.center,
    this.crossOffset = 0.0,
    this.margin = const EdgeInsets.all(8.0),
    this.flips = true,
    this.onDismiss,
    this.consumeOutsideTaps = false,
  });

  /// Shows and hides the buoy.
  final OverlayPortalController controller;

  /// Builds the buoy. Its context is this widget's, so it reads the same
  /// themes and harbor.
  final WidgetBuilder buoyBuilder;

  /// Where this widget lives in the tree, and its anchor when [anchor] is null.
  final Widget child;

  /// What the buoy sits by. Null anchors it to [child].
  final HarborAnchor? anchor;

  final HarborBuoySide side;
  final double gap;
  final double overlap;

  /// How the buoy lines up with its anchor across its [side]; centred by default.
  final HarborBuoyCrossAlignment crossAlignment;

  /// How far the buoy is moved across its [side] from where [crossAlignment] puts it, as
  /// [HarborBuoy.crossOffset].
  final double crossOffset;
  final EdgeInsetsGeometry margin;

  /// Whether the buoy goes to the opposite side of its anchor when [side] has
  /// no room and that side has.
  final bool flips;

  /// Called while the buoy is shown when a tap lands outside both the buoy and [child] (a
  /// [TapRegion] group, as a `MenuAnchor`'s), when Escape is pressed with focus in either, and on
  /// back, before back reaches the page. Hide the buoy in it. Null leaves the buoy up until
  /// [controller] hides it.
  final VoidCallback? onDismiss;

  /// Whether a tap outside that calls [onDismiss] stops there, as
  /// [RawMenuAnchor.consumeOutsideTaps]: true for a menu whose closing tap must not also press
  /// what is under it. By default the tap goes on, as it does for a `MenuAnchor`.
  final bool consumeOutsideTaps;

  /// The side of its anchor the portal buoy around [context] landed on: its [side], or the
  /// opposite one after it flipped. A popover reads it to point its arrow at the anchor. It is
  /// placed when it paints, so after a flip this changes on the next frame.
  static HarborBuoySide sideOf(final BuildContext context) {
    final HarborBuoySide? side = maybeSideOf(context);
    assert(side != null, 'HarborPortalBuoy.sideOf was called from outside a portal buoy\'s buoyBuilder.');
    return side!;
  }

  /// [sideOf], or null outside a portal buoy.
  static HarborBuoySide? maybeSideOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PortalBuoySide>()?.side;

  @override
  State<HarborPortalBuoy> createState() => _HarborPortalBuoyState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<OverlayPortalController>('controller', controller));
    properties.add(DiagnosticsProperty<HarborAnchor>('anchor', anchor, defaultValue: null));
    properties.add(EnumProperty<HarborBuoySide>('side', side, defaultValue: HarborBuoySide.above));
    properties.add(DoubleProperty('gap', gap, defaultValue: 8.0));
    properties.add(DoubleProperty('overlap', overlap, defaultValue: 0.0));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: const EdgeInsets.all(8.0)));
    properties.add(FlagProperty('flips', value: flips, ifFalse: 'no flip'));
  }
}

class _HarborPortalBuoyState extends State<HarborPortalBuoy> {
  HarborAnchor? _own;
  late final ValueNotifier<HarborBuoySide> _landed = ValueNotifier<HarborBuoySide>(widget.side);
  late final _DismissPortalBuoyAction _dismissAction = _DismissPortalBuoyAction(this);
  bool _shown = false;

  HarborAnchor get _anchor => widget.anchor ?? (_own ??= HarborAnchor(debugLabel: 'HarborPortalBuoy'));

  void _dismiss() => widget.onDismiss?.call();

  // The controller is the caller's and tells no one when it shows or hides, so the buoy reports
  // it as it comes and goes. After the frame: it comes and goes while the overlay builds.
  void _buoyCameOrWent() => WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
    if (mounted && _shown != widget.controller.isShowing) {
      setState(() => _shown = widget.controller.isShowing);
    }
  });

  @override
  void dispose() {
    _own?.dispose();
    _landed.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool dismissible = widget.onDismiss != null;
    final Widget anchored = widget.anchor == null ? HarborAnchorPoint(anchor: _anchor, child: widget.child) : widget.child;
    final Widget portal = OverlayPortal(
      controller: widget.controller,
      overlayChildBuilder: (final BuildContext context) {
        Widget buoy = ValueListenableBuilder<HarborBuoySide>(
          valueListenable: _landed,
          builder: (final BuildContext context, final HarborBuoySide side, final Widget? child) => _PortalBuoySide(side: side, child: child!),
          // A Builder, so the builder's own context is below the side it reads.
          child: Builder(builder: widget.buoyBuilder),
        );
        buoy = _PortalBuoyDismissal(
          controller: widget.controller,
          groupId: this,
          consumeOutsideTaps: widget.consumeOutsideTaps,
          onDismiss: dismissible ? _dismiss : null,
          onCameOrWent: _buoyCameOrWent,
          child: buoy,
        );
        return _PortalBuoyLayout(
          harbor: HarborController.maybeOf(context),
          anchor: _anchor,
          side: widget.side,
          gap: widget.gap,
          overlap: widget.overlap,
          crossAlignment: widget.crossAlignment,
          crossOffset: widget.crossOffset,
          margin: widget.margin,
          flips: widget.flips,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          landed: _landed,
          child: buoy,
        );
      },
      // The anchor is in the buoy's tap region group, as a MenuAnchor's button is in its menu's, so
      // a tap on it is its own (a toggle) and never also an outside tap. This and the Actions below
      // stay in the tree without onDismiss, switched off, so setting it does not remount the child.
      child: TapRegion(groupId: this, enabled: dismissible, child: anchored),
    );
    // Above the portal, so Escape from focus in the buoy or in the child reaches it. Mapped only
    // while the buoy is shown: a disabled action would still stop Escape from reaching an enclosing
    // dialog or route. RawMenuAnchor maps its own the same way.
    return Actions(actions: <Type, Action<Intent>>{if (dismissible && _shown) DismissIntent: _dismissAction}, child: portal);
  }
}

/// Escape (a [DismissIntent]) dismisses the portal buoy while it is shown, as `RawMenuAnchor`'s
/// `DismissMenuAction` does.
class _DismissPortalBuoyAction extends DismissAction {
  _DismissPortalBuoyAction(this._buoy);

  final _HarborPortalBuoyState _buoy;

  @override
  bool isEnabled(final DismissIntent intent) => _buoy.widget.onDismiss != null && _buoy.widget.controller.isShowing;

  @override
  void invoke(final DismissIntent intent) => _buoy._dismiss();
}

class _PortalBuoySide extends InheritedWidget {
  const _PortalBuoySide({required this.side, required super.child});

  final HarborBuoySide side;

  @override
  bool updateShouldNotify(final _PortalBuoySide oldWidget) => side != oldWidget.side;
}

/// While a portal buoy is shown: its tap region, which calls [onDismiss] on a tap outside the
/// group, and the page's history entry, so back dismisses the buoy first, as it does a modal
/// [HarborBuoy]. Both are off without [onDismiss]; the region stays, so the buoy keeps its state.
class _PortalBuoyDismissal extends StatefulWidget {
  const _PortalBuoyDismissal({
    required this.controller,
    required this.groupId,
    required this.consumeOutsideTaps,
    required this.onDismiss,
    required this.onCameOrWent,
    required this.child,
  });

  final OverlayPortalController controller;
  final Object groupId;
  final bool consumeOutsideTaps;
  final VoidCallback? onDismiss;
  final VoidCallback onCameOrWent;
  final Widget child;

  @override
  State<_PortalBuoyDismissal> createState() => _PortalBuoyDismissalState();
}

class _PortalBuoyDismissalState extends State<_PortalBuoyDismissal> {
  ModalRoute<Object?>? _route;
  ModalRoute<Object?>? _historyRoute;
  LocalHistoryEntry? _history;
  bool _removingQuietly = false;

  @override
  void initState() {
    super.initState();
    widget.onCameOrWent();
    _takeHistoryAfterFrame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void didUpdateWidget(final _PortalBuoyDismissal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onDismiss == null) {
      _giveHistoryBack();
    } else if (oldWidget.onDismiss == null) {
      _takeHistoryAfterFrame();
    }
  }

  // After the frame: a route's history cannot change while it builds.
  void _takeHistoryAfterFrame() => WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
    final ModalRoute<Object?>? route = _route;
    if (!mounted || widget.onDismiss == null || _history != null || route == null) {
      return;
    }
    _history = LocalHistoryEntry(
      onRemove: () {
        _history = null;
        _historyRoute = null;
        if (!_removingQuietly) {
          widget.onDismiss?.call();
        }
      },
    );
    _historyRoute = route;
    route.addLocalHistoryEntry(_history!);
  });

  void _giveHistoryBack() {
    final LocalHistoryEntry? history = _history;
    final ModalRoute<Object?>? route = _historyRoute;
    _history = null;
    _historyRoute = null;
    if (history != null && route != null && route.isActive) {
      _removingQuietly = true;
      route.removeLocalHistoryEntry(history);
      _removingQuietly = false;
    }
  }

  void _tappedOutside(final PointerDownEvent _) {
    widget.onDismiss?.call();
    // Hidden now, gone at the next build. Back is the page's at once, so a barrier under the tap
    // (a dialog's) closes what it closes, as it does with a MenuAnchor open in a dialog.
    if (!widget.controller.isShowing) {
      _giveHistoryBack();
    }
  }

  @override
  void deactivate() {
    _giveHistoryBack();
    widget.onCameOrWent();
    super.deactivate();
  }

  @override
  Widget build(final BuildContext context) => TapRegion(
    groupId: widget.groupId,
    enabled: widget.onDismiss != null,
    consumeOutsideTaps: widget.consumeOutsideTaps,
    onTapOutside: _tappedOutside,
    child: widget.child,
  );
}

class _PortalBuoyLayout extends SingleChildRenderObjectWidget {
  const _PortalBuoyLayout({
    required this.harbor,
    required this.anchor,
    required this.side,
    required this.gap,
    required this.overlap,
    required this.crossAlignment,
    required this.crossOffset,
    required this.margin,
    required this.flips,
    required this.textDirection,
    required this.landed,
    super.child,
  });

  final HarborController? harbor;
  final HarborAnchor anchor;
  final HarborBuoySide side;
  final double gap;
  final double overlap;
  final HarborBuoyCrossAlignment crossAlignment;
  final double crossOffset;
  final EdgeInsetsGeometry margin;
  final bool flips;
  final TextDirection textDirection;

  /// Told the side the buoy landed on, the frame after it changes.
  final ValueNotifier<HarborBuoySide> landed;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderPortalBuoy(this);

  @override
  void updateRenderObject(final BuildContext context, final _RenderPortalBuoy renderObject) {
    renderObject.config = this;
  }
}

/// Fills the overlay and places its buoy when it paints, once the harbor's
/// clear water and the anchor are laid out for this frame.
class _RenderPortalBuoy extends RenderShiftedBox {
  _RenderPortalBuoy(this._config) : super(null);

  _PortalBuoyLayout _config;
  set config(final _PortalBuoyLayout value) {
    final _PortalBuoyLayout old = _config;
    _config = value;
    if (attached) {
      _unlisten(old);
      _listen(value);
    }
    markNeedsLayout();
  }

  bool _placed = false;

  void _listen(final _PortalBuoyLayout c) {
    c.harbor?.clearWater.addListener(markNeedsLayout);
  }

  void _unlisten(final _PortalBuoyLayout c) {
    c.harbor?.clearWater.removeListener(markNeedsLayout);
  }

  // Its own layer, since it is painted again every frame.
  @override
  bool get isRepaintBoundary => true;

  final _FollowEveryFrame _follow = _FollowEveryFrame();

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _listen(_config);
  }

  @override
  void detach() {
    _follow.cancel();
    _unlisten(_config);
    super.detach();
  }

  /// The harbor's clear water in this box's coordinates, or the whole box
  /// when there is no harbor around the buoy.
  Rect _water() {
    final HarborController? harbor = _config.harbor;
    final RenderBox? box = harbor?.renderBox;
    final HarborLayoutRecord? layout = harbor?.lastLayout;
    final Rect clear = box == null || layout == null || !box.attached || !box.hasSize
        ? Offset.zero & size
        : MatrixUtils.transformRect(box.getTransformTo(this), layout.clearWater);
    return _config.margin.resolve(_config.textDirection).deflateRect(clear);
  }

  @override
  Size computeDryLayout(final BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final RenderBox? child = this.child;
    if (child != null) {
      // Only the water's size is known while laying out: the harbor's last
      // one. A change to it lays the buoy out again.
      final Rect? clear = _config.harbor?.lastLayout?.clearWater;
      final Rect water = _config.margin.resolve(_config.textDirection).deflateRect(clear ?? Offset.zero & size);
      child.layout(BoxConstraints.loose(Size(math.max(0.0, water.width), math.max(0.0, water.height))), parentUsesSize: true);
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    _follow.next(markNeedsPaint);
    final RenderBox? child = this.child;
    final RenderBox? anchorBox = _config.anchor.box;
    final bool placed = child != null && anchorBox != null;
    if (placed != _placed) {
      _placed = placed;
      markNeedsSemanticsUpdate();
    }
    if (!placed) {
      return;
    }
    final BoxParentData data = child.parentData! as BoxParentData;
    final Offset was = data.offset;
    final ({Offset offset, HarborBuoySide side}) landed = _anchoredOffset(
      water: _water(),
      at: MatrixUtils.transformRect(anchorBox.getTransformTo(this), Offset.zero & anchorBox.size),
      size: child.size,
      side: _config.side,
      gap: _config.gap,
      overlap: _config.overlap,
      crossAlignment: _config.crossAlignment,
      crossOffset: _config.crossOffset,
      textDirection: _config.textDirection,
      flips: _config.flips,
    );
    data.offset = landed.offset;
    _report(landed.side);
    // Layout refreshes semantics, but the buoy is placed here, after it, so a move refreshes them too.
    if (data.offset != was) {
      markNeedsSemanticsUpdate();
    }
    context.paintChild(child, data.offset + offset);
  }

  HarborBuoySide? _reporting;

  // The side is only known here, and nothing may be rebuilt while painting, so the buoy hears it
  // the frame after, as an anchor reports that it moved.
  void _report(final HarborBuoySide side) {
    final ValueNotifier<HarborBuoySide> landed = _config.landed;
    if (side == (_reporting ?? landed.value)) {
      return;
    }
    final bool scheduled = _reporting != null;
    _reporting = side;
    if (scheduled) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      final HarborBuoySide? reported = _reporting;
      _reporting = null;
      if (reported != null && attached) {
        _config.landed.value = reported;
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  bool paintsChild(final RenderBox child) => _placed;

  @override
  void visitChildrenForSemantics(final RenderObjectVisitor visitor) {
    if (_placed) {
      super.visitChildrenForSemantics(visitor);
    }
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) =>
      _placed && super.hitTestChildren(result, position: position);
}

/// Paints an anchored buoy again at the start of every frame that is drawn, as
/// `OverlayPortal.overlayChildLayoutBuilder` lays its child out again, so the
/// buoy is placed by where its anchor is in that frame. An anchor that scrolls
/// is moved without being laid out or painted (a list row is its own layer), so
/// it cannot say that it moved in time, or at all. Asks for no frame itself.
class _FollowEveryFrame {
  int? _id;

  void next(final VoidCallback repaint) {
    _id ??= SchedulerBinding.instance.scheduleFrameCallback((final Duration _) {
      _id = null;
      repaint();
    }, scheduleNewFrame: false);
  }

  void cancel() {
    if (_id case final int id) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(id);
      _id = null;
    }
  }
}

/// Where a signal is raised within the clear water of its harbor.
enum HarborSignalSlot {
  top(Alignment.topCenter),
  high(Alignment(0.0, -0.55)),
  middle(Alignment.center),
  low(Alignment.bottomCenter);

  const HarborSignalSlot(this.alignment);

  final Alignment alignment;
}

/// Which harbor a signal goes to.
enum HarborSignalTarget {
  /// The port on top right now (a sheet over a page over the sea), so a low
  /// signal clears that sheet's footer.
  topmost,

  /// The outermost harbor, so the signal clears only the coast.
  sea,
}

/// Transient buoys: messages raised in a harbor's clear water for a while.
///
/// See also:
///
///  * `SnackBar` and `ScaffoldMessenger.showSnackBar`, which queue their messages; signals are not
///    queued.
abstract final class HarborSignals {
  /// Raises [builder]'s signal in [target]'s clear water at [slot], lowered
  /// after [duration] (or when the returned entry is lowered). If its harbor
  /// leaves (the page is popped), the signal moves to the port now on top.
  ///
  /// Signals at the same slot or alignment take turns, as a
  /// `ScaffoldMessenger` shows its snack bars one at a time: each comes in once
  /// the one before it has left. To replace the signal that is up, lower it.
  /// [HarborSignalEntry.closed] completes once a signal has left, with why.
  ///
  /// [duration] (4 s, a `SnackBar`'s) counts only while the signal is in
  /// sight: from the end of its entrance, and not while another route covers
  /// its page. With [persist] the signal stays until it is lowered, as a
  /// `SnackBar` with `persist` does; give it to a signal with a button, so a
  /// screen-reader user has time to reach it.
  ///
  /// [alignment] places the signal at an exact point instead of a slot, as
  /// [HarborBuoy.alignment] places a buoy; give one or the other, or neither
  /// for [HarborSignalSlot.high]. An [AlignmentDirectional] is resolved in the
  /// reading direction of [context], the page that raised it, whose themes the
  /// signal also keeps.
  ///
  /// The signal fades and scales in and out over [animationStyle] (220 ms each
  /// way by default). [AnimationStyle.noAnimation] shows it as it is, for a
  /// widget that brings its own entrance; [transitionBuilder] builds your own
  /// entrance and exit from harbor's animation instead. Either way a lowered
  /// signal stays at least 300 ms, so the widget's own exit can run. With
  /// reduced motion it appears and leaves at once.
  ///
  /// The signal is a live region with a dismiss action, so a screen reader
  /// announces it and can lower it, as it does a `SnackBar`. Give
  /// [liveRegion] false when [builder]'s widget is its own live region: harbor
  /// then adds no semantics, and the widget's node is the only one announced.
  ///
  /// With no harbor above [context] (a bare `MaterialApp` in a widget test, a
  /// screen not yet built from a harbor), the signal goes to the nearest
  /// [Overlay], kept clear of `MediaQuery.padding` and `viewInsets`. With no
  /// overlay either, it is reported through [FlutterError.reportError] and
  /// returned already lowered.
  static HarborSignalEntry raise(
    final BuildContext context, {
    required final WidgetBuilder builder,
    final HarborSignalSlot? slot,
    final AlignmentGeometry? alignment,
    final Duration? duration = const Duration(seconds: 4),
    final bool persist = false,
    final HarborSignalTarget target = HarborSignalTarget.topmost,
    final AnimationStyle? animationStyle,
    final HarborSignalTransitionBuilder? transitionBuilder,
    final bool liveRegion = true,
  }) {
    assert(slot == null || alignment == null, 'Give a signal a slot or an alignment, not both.');
    final HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    // A signal is built in its harbor's buoy layer, not where it was raised, so it takes the
    // themes and text style of the place that raised it, as a sheet does. Without this a page
    // that wraps itself in its own Theme raised a toast in the app's theme.
    final CapturedThemes themes = InheritedTheme.capture(from: context, to: null);
    final HarborSignalEntry entry = HarborSignalEntry(
      // A Builder, so the builder's own context sees the captured themes, not only what it returns.
      builder: (final BuildContext _) => themes.wrap(Builder(builder: builder)),
      alignment: alignment?.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr) ?? (slot ?? HarborSignalSlot.high).alignment,
      duration: duration,
      persist: persist,
      // Sent to the sea, a signal clears only the coast.
      avoidInGlobal: target == HarborSignalTarget.topmost ? HarborController.maybeOf(context)?.clearWaterInGlobal() : null,
      raisedIn: target == HarborSignalTarget.topmost ? HarborController.maybeOf(context) : null,
      animationStyle: animationStyle,
      transitionBuilder: transitionBuilder,
      liveRegion: liveRegion,
    );
    final HarborController? controller = switch (target) {
      HarborSignalTarget.topmost => fleet?.topmost,
      HarborSignalTarget.sea => fleet?.sea,
    } ?? HarborController.maybeOf(context);
    if (controller != null) {
      controller.raiseSignal(entry);
    } else if (Overlay.maybeOf(context) case final OverlayState overlay) {
      (_overlayQueues[overlay] ??= _OverlayQueue(overlay)).raise(entry);
    } else {
      entry.lower(reason: HarborSignalClosedReason.remove);
      signalLeft(entry);
      FlutterError.reportError(FlutterErrorDetails(
        exception: FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('HarborSignals.raise found no Harbor, HarborSea or Overlay above the context, so the signal was not shown.'),
          ErrorHint('Mount a HarborSea in MaterialApp.builder, or raise the signal from a context inside a Navigator.'),
        ]),
        library: 'harbor',
      ));
      return entry;
    }
    return entry;
  }

  static final Expando<_OverlayQueue> _overlayQueues = Expando<_OverlayQueue>();
}

/// The signals raised into one overlay, which take turns at each alignment as
/// they do in a harbor.
class _OverlayQueue {
  _OverlayQueue(this.overlay);

  final OverlayState overlay;
  final List<HarborSignalEntry> _signals = <HarborSignalEntry>[];
  final Set<HarborSignalEntry> _inserted = <HarborSignalEntry>{};

  void raise(final HarborSignalEntry entry) {
    _signals.add(entry);
    void lowered() {
      if (!entry.showing.value && !_inserted.contains(entry)) {
        entry.showing.removeListener(lowered);
        _signals.remove(entry);
        signalLeft(entry);
      }
    }

    entry.showing.addListener(lowered);
    _insertInSight();
  }

  void _insertInSight() {
    for (final HarborSignalEntry entry in signalsInSight(_signals)) {
      if (_inserted.add(entry)) {
        late final OverlayEntry host;
        host = OverlayEntry(builder: (final BuildContext _) => _OverlaySignal(entry: entry, host: host, queue: this));
        overlay.insert(host);
      }
    }
  }

  /// [entry] has run its exit and left the overlay: the next at its place comes in.
  void left(final HarborSignalEntry entry) {
    _forget(entry);
    _insertInSight();
  }

  /// The overlay went away under [entry], so the signals waiting behind it have
  /// nothing left to show them either.
  void gone(final HarborSignalEntry entry) {
    _forget(entry);
    for (final HarborSignalEntry waiting in List<HarborSignalEntry>.of(_signals)) {
      if (!_inserted.contains(waiting)) {
        waiting.lower(reason: HarborSignalClosedReason.remove);
      }
    }
  }

  void _forget(final HarborSignalEntry entry) {
    _signals.remove(entry);
    _inserted.remove(entry);
    signalLeft(entry);
  }
}

/// A signal raised where there is no harbor: in an overlay, at its slot in the
/// water the overlay's padding and keyboard leave.
class _OverlaySignal extends StatefulWidget {
  const _OverlaySignal({required this.entry, required this.host, required this.queue});

  final HarborSignalEntry entry;
  final OverlayEntry host;
  final _OverlayQueue queue;

  @override
  State<_OverlaySignal> createState() => _OverlaySignalState();
}

class _OverlaySignalState extends State<_OverlaySignal> {
  static const EdgeInsets _margin = EdgeInsets.all(16.0);

  Timer? _removal;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    widget.entry.showing.addListener(_changed);
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      // Leave time for the signal's own exit animation.
      _removal ??= Timer(widget.entry.lingers, () {
        _removed = true;
        widget.host
          ..remove()
          ..dispose();
        widget.queue.left(widget.entry);
      });
    }
  }

  @override
  void dispose() {
    widget.entry.showing.removeListener(_changed);
    _removal?.cancel();
    if (!_removed) {
      // The overlay went away with the signal still up: nothing is left to show it.
      widget.entry.lower(reason: HarborSignalClosedReason.remove);
      widget.queue.gone(widget.entry);
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets keyboard = MediaQuery.viewInsetsOf(context);
    // Both are measured from the screen's edges, so the larger one on each edge is what is covered.
    final EdgeInsets covered = EdgeInsets.fromLTRB(
      math.max(padding.left, keyboard.left),
      math.max(padding.top, keyboard.top),
      math.max(padding.right, keyboard.right),
      math.max(padding.bottom, keyboard.bottom),
    );
    return Padding(
      padding: covered + _margin,
      child: Align(alignment: widget.entry.alignment, child: _Signal(entry: widget.entry)),
    );
  }
}

class _Signal extends StatefulWidget {
  const _Signal({required this.entry});

  final HarborSignalEntry entry;

  @override
  State<_Signal> createState() => _SignalState();
}

class _SignalState extends State<_Signal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.entry.animationStyle?.curve ?? Curves.linear,
    reverseCurve: widget.entry.animationStyle?.reverseCurve,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0).animate(_animation);

  Timer? _timeout;
  bool _inSight = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    _controller
      ..duration = reducedMotion ? Duration.zero : widget.entry.transitionDuration
      ..reverseDuration = reducedMotion ? Duration.zero : widget.entry.reverseTransitionDuration;
    // As a ScaffoldMessenger starts a snack bar's timer only while its route is current: a page
    // covered by another route, or kept offstage with its tickers stopped, shows nobody the signal.
    _inSight = (ModalRoute.isCurrentOf(context) ?? true) && TickerMode.valuesOf(context).enabled;
    if (_controller.isDismissed && widget.entry.showing.value) {
      _controller.forward();
    }
    _syncTimeout();
  }

  @override
  void initState() {
    super.initState();
    widget.entry.showing.addListener(_changed);
    _controller.addStatusListener(_statusChanged);
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      _controller.reverse();
    }
    _syncTimeout();
  }

  void _statusChanged(final AnimationStatus _) => _syncTimeout();

  /// Runs the signal's time while it is fully in and in sight, and starts it over when it comes back.
  void _syncTimeout() {
    final HarborSignalEntry entry = widget.entry;
    final Duration? duration = entry.duration;
    final bool running = duration != null && !entry.persist && entry.showing.value && _controller.isCompleted && _inSight;
    if (running && _timeout == null) {
      _timeout = Timer(duration, () => entry.lower(reason: HarborSignalClosedReason.timeout));
    } else if (!running) {
      _timeout?.cancel();
      _timeout = null;
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    widget.entry.showing.removeListener(_changed);
    _controller.removeStatusListener(_statusChanged);
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _still => widget.entry.transitionDuration == Duration.zero && widget.entry.reverseTransitionDuration == Duration.zero;

  @override
  Widget build(final BuildContext context) {
    final HarborSignalEntry entry = widget.entry;
    final Widget child = entry.builder(context);
    final Widget shown = switch (entry.transitionBuilder) {
      final HarborSignalTransitionBuilder transition => transition(context, _animation, child),
      // Shown as it is, so a widget with its own entrance doesn't play two.
      null when _still => child,
      null => FadeTransition(opacity: _animation, child: ScaleTransition(scale: _scale, child: child)),
    };
    if (!entry.liveRegion) {
      return shown;
    }
    // A live region, so a screen reader announces the signal when it appears, and a dismiss
    // action to lower it, as a SnackBar has.
    return Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () => entry.lower(reason: HarborSignalClosedReason.dismiss),
      child: shown,
    );
  }
}
