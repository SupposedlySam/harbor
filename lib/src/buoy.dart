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

/// Which side of its anchor an anchored buoy sits on.
enum HarborBuoySide { above, below, before, after }

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
  /// Where the buoy sits in the clear water. An [AlignmentDirectional] follows the reading
  /// direction, as a Material floating action button does.
  final AlignmentGeometry alignment;

  /// How far in from the clear water's edges; an [EdgeInsetsDirectional] follows the reading direction.
  final EdgeInsetsGeometry margin;
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
  RenderObject createRenderObject(final BuildContext context) => _RenderBuoyLayer(buoys, Directionality.of(context));

  @override
  void updateRenderObject(final BuildContext context, final _RenderBuoyLayer renderObject) {
    renderObject
      ..buoys = buoys
      ..textDirection = Directionality.of(context);
  }
}

class _BuoyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBuoyLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _BuoyParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _BuoyParentData> {
  _RenderBuoyLayer(this._buoys, this._textDirection);

  List<HarborBuoy> _buoys;

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
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
      final Rect water = buoy.margin.resolve(_textDirection).deflateRect(bounded);
      child.layout(BoxConstraints.loose(Size(math.max(0.0, water.width), math.max(0.0, water.height))), parentUsesSize: true);
      // Anchored buoys are placed when they paint, once their anchors have a size.
      data.offset = buoy.anchor == null ? buoy.alignment.resolve(_textDirection).inscribe(child.size, water).topLeft : data.offset;
      child = data.nextSibling;
      i++;
    }
  }

  Offset _anchoredOffset(final HarborBuoy buoy, final RenderBox anchorBox, final Size s) {
    final Rect water = buoy.margin.resolve(_textDirection).deflateRect(_clear);
    final Rect at = MatrixUtils.transformRect(anchorBox.getTransformTo(this), Offset.zero & anchorBox.size);
    double left = at.center.dx - s.width / 2;
    double top = at.center.dy - s.height / 2;
    switch (buoy.side) {
      case HarborBuoySide.above:
        top = math.max(at.top - buoy.gap - s.height + buoy.overlap, water.top);
      case HarborBuoySide.below:
        top = math.min(at.bottom + buoy.gap - buoy.overlap, water.bottom - s.height);
      case HarborBuoySide.before:
        left = at.left - buoy.gap - s.width + buoy.overlap;
      case HarborBuoySide.after:
        left = at.right + buoy.gap - buoy.overlap;
    }
    if (buoy.side == HarborBuoySide.above || buoy.side == HarborBuoySide.below) {
      left = left.clamp(water.left, math.max(water.left, water.right - s.width));
    } else {
      top = top.clamp(water.top, math.max(water.top, water.bottom - s.height));
    }
    return Offset(left, top);
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
        data.offset = _anchoredOffset(buoy, anchorBox, child.size);
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
    // A signal is built in its harbor's buoy layer, not where it was raised, so it takes the
    // themes and text style of the place that raised it, as a sheet does. Without this a page
    // that wraps itself in its own Theme raised a toast in the app's theme.
    final CapturedThemes themes = InheritedTheme.capture(from: context, to: null);
    final HarborSignalEntry entry = HarborSignalEntry(
      // A Builder, so the builder's own context sees the captured themes, not only what it returns.
      builder: (final BuildContext _) => themes.wrap(Builder(builder: builder)),
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
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220);
    if (_controller.isDismissed && widget.entry.showing.value) {
      _controller.forward();
    }
  }

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
  // A live region, so a screen reader announces the signal when it appears, as it does a SnackBar.
  Widget build(final BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: FadeTransition(
      opacity: _controller,
      child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1.0).animate(_controller), child: widget.entry.builder(context)),
    ),
  );
}
