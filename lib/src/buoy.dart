import 'dart:async';
import 'dart:math' as math;

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

  RenderBox? _box;
  bool _disposed = false;

  /// The anchored widget's box, while it is in the tree and laid out.
  RenderBox? get box => (_box != null && _box!.attached && _box!.hasSize) ? _box : null;

  void _attach(final RenderBox box) {
    _box = box;
    _moved();
  }

  void _detach(final RenderBox box) {
    if (identical(_box, box)) {
      _box = null;
      _moved();
    }
  }

  bool _pending = false;

  void _moved() {
    if (_pending || _disposed) {
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

/// Which side of its anchor an anchored buoy sits on. [before] and [after]
/// are in reading order: [before] is on the right under right-to-left.
enum HarborBuoySide { above, below, before, after }

/// Where a buoy of [size] sits by the anchor at [at], inside [water]: on
/// [side], [gap] away, overlapping it by [overlap], and centered on it across
/// that side. It is kept inside [water] across the side, and above or below
/// its anchor, never past the far edge. With [flips], it goes to the opposite
/// side when [side] has no room and that one has, and is never past the far
/// edge before or after its anchor either.
Offset _anchoredOffset({
  required final Rect water,
  required final Rect at,
  required final Size size,
  required final HarborBuoySide side,
  required final double gap,
  required final double overlap,
  required final TextDirection textDirection,
  final bool flips = false,
}) {
  final bool rtl = textDirection == TextDirection.rtl;
  final AxisDirection preferred = switch (side) {
    HarborBuoySide.above => AxisDirection.up,
    HarborBuoySide.below => AxisDirection.down,
    HarborBuoySide.before => rtl ? AxisDirection.right : AxisDirection.left,
    HarborBuoySide.after => rtl ? AxisDirection.left : AxisDirection.right,
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
  double left = at.center.dx - size.width / 2;
  double top = at.center.dy - size.height / 2;
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
  if (axisDirectionToAxis(direction) == Axis.vertical) {
    left = left.clamp(water.left, math.max(water.left, water.right - size.width));
  } else {
    top = top.clamp(water.top, math.max(water.top, water.bottom - size.height));
  }
  return Offset(left, top);
}

/// Something afloat in a harbor: placed in the water nothing covers, so it
/// clears the coast, every dock and the keyboard without knowing about them.
///
/// Give buoys to [Harbor.buoys]. A modal buoy hides the buoys listed before it
/// while it is up (a menu over a tooltip).
@immutable
class HarborBuoy {
  /// A buoy at [alignment] within the clear water, [margin] in from its edges.
  const HarborBuoy({
    this.key,
    required this.child,
    this.alignment = Alignment.bottomCenter,
    this.margin = const EdgeInsets.all(16.0),
    this.modal = false,
    this.within,
  }) : anchor = null,
       side = HarborBuoySide.above,
       gap = 0.0,
       overlap = 0.0;

  /// A buoy moored to [anchor], on its [side], [gap] away, overlapping it by
  /// [overlap] (a speech bubble whose tail sits over the button). Kept inside
  /// the clear water across that side, and never past its far edge.
  const HarborBuoy.anchored({
    this.key,
    required HarborAnchor this.anchor,
    required this.child,
    this.side = HarborBuoySide.above,
    this.gap = 8.0,
    this.overlap = 0.0,
    this.margin = const EdgeInsets.all(8.0),
    this.modal = false,
  }) : alignment = Alignment.center,
       within = null;

  final Key? key;
  final Widget child;
  final Alignment alignment;
  final EdgeInsets margin;
  final bool modal;
  final HarborAnchor? anchor;
  final HarborBuoySide side;
  final double gap;
  final double overlap;

  /// Keeps the buoy inside this rectangle (in the harbor's own coordinates)
  /// as well as inside the clear water.
  final Rect? within;
}

/// The layer a harbor floats its buoys in.
class HarborBuoyLayer extends StatelessWidget {
  const HarborBuoyLayer({super.key, required this.buoys, required this.signals});

  final List<HarborBuoy> buoys;
  final List<HarborSignalEntry> signals;

  @override
  Widget build(final BuildContext context) {
    final int lastModal = buoys.lastIndexWhere((final HarborBuoy b) => b.modal);
    final List<HarborBuoy> all = <HarborBuoy>[
      ...buoys,
      for (final HarborSignalEntry signal in signals)
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
      _RenderBuoyLayer(buoys, Directionality.maybeOf(context) ?? TextDirection.ltr);

  @override
  void updateRenderObject(final BuildContext context, final _RenderBuoyLayer renderObject) {
    renderObject
      ..buoys = buoys
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

class _BuoyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBuoyLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _BuoyParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _BuoyParentData> {
  _RenderBuoyLayer(this._buoys, this._textDirection);

  List<HarborBuoy> _buoys;
  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (value != _textDirection) {
      _textDirection = value;
      markNeedsPaint();
    }
  }

  final Set<HarborAnchor> _listening = <HarborAnchor>{};

  set buoys(final List<HarborBuoy> value) {
    _buoys = value;
    _syncAnchors();
    markNeedsLayout();
  }

  void _syncAnchors() {
    final Set<HarborAnchor> wanted = <HarborAnchor>{
      for (final HarborBuoy b in _buoys)
        if (b.anchor != null) b.anchor!,
    };
    for (final HarborAnchor a in _listening.difference(wanted)) {
      a.removeListener(markNeedsLayout);
    }
    if (attached) {
      for (final HarborAnchor a in wanted.difference(_listening)) {
        a.addListener(markNeedsLayout);
      }
    }
    _listening
      ..clear()
      ..addAll(attached ? wanted : <HarborAnchor>{});
  }

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _syncAnchors();
  }

  @override
  void detach() {
    for (final HarborAnchor a in _listening) {
      a.removeListener(markNeedsLayout);
    }
    _listening.clear();
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
      final Rect water = buoy.margin.deflateRect(bounded);
      child.layout(BoxConstraints.loose(Size(math.max(0.0, water.width), math.max(0.0, water.height))), parentUsesSize: true);
      // Anchored buoys are placed when they paint, once their anchors have a size.
      data.offset = buoy.anchor == null ? buoy.alignment.inscribe(child.size, water).topLeft : data.offset;
      child = data.nextSibling;
      i++;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      final HarborBuoy buoy = _buoys[i];
      final RenderBox? anchorBox = buoy.anchor?.box;
      if (buoy.anchor != null) {
        if (anchorBox == null) {
          child = data.nextSibling;
          i++;
          continue;
        }
        data.offset = _anchoredOffset(
          water: buoy.margin.deflateRect(_clear),
          at: MatrixUtils.transformRect(anchorBox.getTransformTo(this), Offset.zero & anchorBox.size),
          size: child.size,
          side: buoy.side,
          gap: buoy.gap,
          overlap: buoy.overlap,
          textDirection: _textDirection,
        );
      }
      context.paintChild(child, data.offset + offset);
      child = data.nextSibling;
      i++;
    }
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// An anchored buoy opened from anywhere: a menu from a list row, a popover
/// from a button, declared where it is opened rather than in [Harbor.buoys].
///
/// It is an [OverlayPortal]: while [controller] shows it, [buoyBuilder]'s
/// buoy floats in the nearest [Overlay] and is placed as a
/// [HarborBuoy.anchored] is, in the clear water of the harbor around this
/// widget: by [anchor] (or by [child] when there is none), on its [side],
/// [gap] away, [margin] in from the water's edges. When [side] has no room
/// and the opposite side has, it [flips] there; otherwise it is kept inside
/// the clear water.
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
    this.margin = const EdgeInsets.all(8.0),
    this.flips = true,
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
  final EdgeInsets margin;

  /// Whether the buoy goes to the opposite side of its anchor when [side] has
  /// no room and that side has.
  final bool flips;

  @override
  State<HarborPortalBuoy> createState() => _HarborPortalBuoyState();
}

class _HarborPortalBuoyState extends State<HarborPortalBuoy> {
  HarborAnchor? _own;

  HarborAnchor get _anchor => widget.anchor ?? (_own ??= HarborAnchor(debugLabel: 'HarborPortalBuoy'));

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => OverlayPortal(
    controller: widget.controller,
    overlayChildBuilder: (final BuildContext context) => _PortalBuoyLayout(
      harbor: HarborController.maybeOf(context),
      anchor: _anchor,
      side: widget.side,
      gap: widget.gap,
      overlap: widget.overlap,
      margin: widget.margin,
      flips: widget.flips,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: widget.buoyBuilder(context),
    ),
    child: widget.anchor == null ? HarborAnchorPoint(anchor: _anchor, child: widget.child) : widget.child,
  );
}

class _PortalBuoyLayout extends SingleChildRenderObjectWidget {
  const _PortalBuoyLayout({
    required this.harbor,
    required this.anchor,
    required this.side,
    required this.gap,
    required this.overlap,
    required this.margin,
    required this.flips,
    required this.textDirection,
    super.child,
  });

  final HarborController? harbor;
  final HarborAnchor anchor;
  final HarborBuoySide side;
  final double gap;
  final double overlap;
  final EdgeInsets margin;
  final bool flips;
  final TextDirection textDirection;

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
    c.anchor.addListener(markNeedsPaint);
    c.harbor?.clearWater.addListener(markNeedsLayout);
  }

  void _unlisten(final _PortalBuoyLayout c) {
    c.anchor.removeListener(markNeedsPaint);
    c.harbor?.clearWater.removeListener(markNeedsLayout);
  }

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _listen(_config);
  }

  @override
  void detach() {
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
    return _config.margin.deflateRect(clear);
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
      final Rect water = _config.margin.deflateRect(clear ?? Offset.zero & size);
      child.layout(BoxConstraints.loose(Size(math.max(0.0, water.width), math.max(0.0, water.height))), parentUsesSize: true);
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    final RenderBox? anchorBox = _config.anchor.box;
    _placed = child != null && anchorBox != null;
    if (!_placed) {
      return;
    }
    final BoxParentData data = child!.parentData! as BoxParentData;
    data.offset = _anchoredOffset(
      water: _water(),
      at: MatrixUtils.transformRect(anchorBox!.getTransformTo(this), Offset.zero & anchorBox.size),
      size: child.size,
      side: _config.side,
      gap: _config.gap,
      overlap: _config.overlap,
      textDirection: _config.textDirection,
      flips: _config.flips,
    );
    context.paintChild(child, data.offset + offset);
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) =>
      _placed && super.hitTestChildren(result, position: position);
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
abstract final class HarborSignals {
  /// Raises [builder]'s signal in [target]'s clear water at [slot], lowered
  /// after [duration] (or when the returned entry is lowered). If its harbor
  /// leaves (the page is popped), the signal moves to the port now on top.
  static HarborSignalEntry raise(
    final BuildContext context, {
    required final WidgetBuilder builder,
    final HarborSignalSlot slot = HarborSignalSlot.high,
    final Duration? duration = const Duration(seconds: 3),
    final HarborSignalTarget target = HarborSignalTarget.topmost,
  }) {
    final HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    final HarborSignalEntry entry = HarborSignalEntry(
      builder: builder,
      alignment: slot.alignment,
      duration: duration,
      // Sent to the sea, a signal clears only the coast.
      avoidInGlobal: target == HarborSignalTarget.topmost ? HarborController.maybeOf(context)?.clearWaterInGlobal() : null,
    );
    final HarborController? controller = switch (target) {
      HarborSignalTarget.topmost => fleet?.topmost,
      HarborSignalTarget.sea => fleet?.sea,
    } ?? HarborController.maybeOf(context);
    assert(controller != null, 'HarborSignals.raise needs a Harbor or HarborSea above the context.');
    controller?.raiseSignal(entry);
    if (duration != null) {
      Timer(duration, entry.lower);
    }
    return entry;
  }
}

class _Signal extends StatefulWidget {
  const _Signal({required this.entry});

  final HarborSignalEntry entry;

  @override
  State<_Signal> createState() => _SignalState();
}

class _SignalState extends State<_Signal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
    ..forward();

  @override
  void initState() {
    super.initState();
    widget.entry.showing.addListener(_changed);
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.entry.showing.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => FadeTransition(
    opacity: _controller,
    child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1.0).animate(_controller), child: widget.entry.builder(context)),
  );
}
