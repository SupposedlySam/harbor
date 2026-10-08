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
  RenderObject createRenderObject(final BuildContext context) => _RenderBuoyLayer(buoys);

  @override
  void updateRenderObject(final BuildContext context, final _RenderBuoyLayer renderObject) {
    renderObject.buoys = buoys;
  }
}

class _BuoyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBuoyLayer extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _BuoyParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _BuoyParentData> {
  _RenderBuoyLayer(this._buoys);

  List<HarborBuoy> _buoys;
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

  Offset _anchoredOffset(final HarborBuoy buoy, final RenderBox anchorBox, final Size s) {
    final Rect water = buoy.margin.deflateRect(_clear);
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
  ///
  /// With no harbor above [context] (a bare `MaterialApp` in a widget test, a
  /// screen not yet built from a harbor), the signal goes to the nearest
  /// [Overlay], kept clear of `MediaQuery.padding` and `viewInsets`. With no
  /// overlay either, it is reported through [FlutterError.reportError] and
  /// returned already lowered.
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
    if (controller != null) {
      controller.raiseSignal(entry);
    } else if (Overlay.maybeOf(context) case final OverlayState overlay) {
      late final OverlayEntry host;
      host = OverlayEntry(builder: (final BuildContext _) => _OverlaySignal(entry: entry, host: host));
      overlay.insert(host);
    } else {
      entry.lower();
      FlutterError.reportError(FlutterErrorDetails(
        exception: FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('HarborSignals.raise found no Harbor, HarborSea or Overlay above the context, so the signal was not shown.'),
          ErrorHint('Mount a HarborSea in MaterialApp.builder, or raise the signal from a context inside a Navigator.'),
        ]),
        library: 'harbor',
      ));
      return entry;
    }
    if (duration != null) {
      _lowerAfter(entry, duration);
    }
    return entry;
  }

  /// Lowers [entry] after [duration], and stops waiting as soon as it is
  /// lowered some other way (by hand, or because nothing is left to show it).
  static void _lowerAfter(final HarborSignalEntry entry, final Duration duration) {
    final Timer timer = Timer(duration, entry.lower);
    void lowered() {
      if (!entry.showing.value) {
        timer.cancel();
        entry.showing.removeListener(lowered);
      }
    }

    entry.showing.addListener(lowered);
  }
}

/// A signal raised where there is no harbor: in an overlay, at its slot in the
/// water the overlay's padding and keyboard leave.
class _OverlaySignal extends StatefulWidget {
  const _OverlaySignal({required this.entry, required this.host});

  final HarborSignalEntry entry;
  final OverlayEntry host;

  @override
  State<_OverlaySignal> createState() => _OverlaySignalState();
}

class _OverlaySignalState extends State<_OverlaySignal> {
  static const EdgeInsets _margin = EdgeInsets.all(16.0);

  Timer? _removal;

  @override
  void initState() {
    super.initState();
    widget.entry.showing.addListener(_changed);
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      // Leave time for the signal's own exit animation.
      _removal ??= Timer(const Duration(milliseconds: 300), () {
        widget.host
          ..remove()
          ..dispose();
      });
    }
  }

  @override
  void dispose() {
    widget.entry.showing.removeListener(_changed);
    _removal?.cancel();
    // The overlay went away with the signal still up: nothing is left to show it.
    widget.entry.lower();
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
