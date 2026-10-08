import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'buoy.dart';
import 'chart.dart';
import 'coast.dart';
import 'controller.dart';
import 'dock.dart';
import 'dock_slot.dart';
import 'edge.dart';
import 'render_harbor.dart';
import 'sheet.dart';
import 'tide.dart';
import 'wake.dart';
import 'waters.dart';

/// A harbor: a frame whose edges docks are built against, with a body of
/// water in the middle and buoys afloat in whatever water nothing covers.
///
/// The one rule: **a dock on the same layer takes space; a dock on a higher
/// layer becomes padding for everything beneath it.** Quays
/// ([HarborDock.quay]) take space, so the body ends where they do. Piers
/// ([HarborDock.pier]) are built out over the water, so the body runs under
/// them and its `MediaQuery.padding` says how far they reach. Content inside
/// moors clear of that ([HarborMoored]), sails under it and rests clear
/// ([HarborFairway]), or ignores it ([HarborOpenWater]).
///
/// Docks are measured in the same layout pass as the body, so a header that
/// grows with the text size is cleared at the size it grew to, and nothing
/// lags a frame.
///
/// The tide (the keyboard) comes in from the bottom. With [bodyClearsTide] the
/// body ends at the waterline, as a resizing `Scaffold`'s does; docks decide
/// for themselves whether they float on it, stand on pilings under it, or keep
/// a dry dock at its height ([HarborDock.tide]).
///
/// A harbor inside another sees the outer harbor's docks as part of its
/// coast, as a component inside a page does. A [newPort] does not: a route or
/// a sheet starts fresh, with only the coast.
class Harbor extends StatefulWidget {
  const Harbor({
    super.key,
    this.top = const <HarborDock>[],
    this.bottom = const <HarborDock>[],
    this.start = const <HarborDock>[],
    this.end = const <HarborDock>[],
    required this.body,
    this.buoys = const <HarborBuoy>[],
    this.coast,
    this.newPort = false,
    this.bodyClearsTide = true,
    this.margin,
    this.minimum = EdgeInsetsDirectional.zero,
    this.sizing = HarborSizing.fill,
    this.maxExtentFraction,
    this.wakePainter,
    this.debugLabel,
  }) : _isSea = false;

  /// The outermost harbor of a sea: see [HarborSea].
  const Harbor._sea({
    this.coast,
    this.margin,
    required this.body,
  }) : top = const <HarborDock>[],
       bottom = const <HarborDock>[],
       start = const <HarborDock>[],
       end = const <HarborDock>[],
       buoys = const <HarborBuoy>[],
       newPort = true,
       bodyClearsTide = false,
       minimum = EdgeInsetsDirectional.zero,
       sizing = HarborSizing.fill,
       maxExtentFraction = null,
       wakePainter = null,
       debugLabel = 'sea',
       _isSea = true;

  /// Whether this is the outermost harbor of a [HarborSea].
  final bool _isSea;

  /// Docks against the top edge, listed top to bottom.
  final List<HarborDock> top;

  /// Docks against the bottom edge, listed top to bottom.
  final List<HarborDock> bottom;

  /// Docks against the start edge, listed in reading order.
  final List<HarborDock> start;

  /// Docks against the end edge, listed in reading order.
  final List<HarborDock> end;

  final Widget body;

  /// What floats in the clear water: menus, bubbles, messages.
  final List<HarborBuoy> buoys;

  /// Where this harbor's coast comes from. Null inherits it.
  final HarborCoast? coast;

  /// Whether this harbor is a new port (a route, a sheet, a dialog): the docks
  /// of the harbor around it don't reach in, only the coast does.
  final bool newPort;

  /// Whether the body ends at the waterline when the keyboard is up. Off, the
  /// body runs under the keyboard and is told how far it reaches.
  final bool bodyClearsTide;

  /// The mooring line: the margin content keeps from whatever is in its way,
  /// for the content that asks for it. Null inherits it. Resolved against the
  /// reading direction where this harbor is built.
  final EdgeInsetsGeometry? margin;

  /// The least the body keeps clear of on each edge, coast or not: the bottom
  /// of a phone with no home indicator.
  final EdgeInsetsGeometry minimum;

  final HarborSizing sizing;

  /// For [HarborSizing.hugBody]: the most of the space above the keyboard the
  /// harbor may take.
  final double? maxExtentFraction;

  /// Paints a wake over the whole body. Null (the default) leaves the wake to
  /// the fairways in it, which fade their content as it sails under the docks,
  /// while open water (a background, a hero) stays as it is.
  final HarborWakePainter? wakePainter;

  /// This harbor's name on a chart.
  final String? debugLabel;

  @override
  State<Harbor> createState() => _HarborState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final (String name, List<HarborDock> docks) in <(String, List<HarborDock>)>[
      ('top', top),
      ('bottom', bottom),
      ('start', start),
      ('end', end),
    ]) {
      properties.add(
        IterableProperty<HarborDock>(name, docks, level: docks.isEmpty ? DiagnosticLevel.fine : DiagnosticLevel.info),
      );
    }
    properties.add(
      IterableProperty<HarborBuoy>('buoys', buoys, level: buoys.isEmpty ? DiagnosticLevel.fine : DiagnosticLevel.info),
    );
    properties.add(DiagnosticsProperty<HarborCoast>('coast', coast, defaultValue: null));
    properties.add(FlagProperty('newPort', value: newPort, ifTrue: 'new port'));
    properties.add(FlagProperty('bodyClearsTide', value: bodyClearsTide, ifFalse: 'body runs under the tide'));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('minimum', minimum, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(EnumProperty<HarborSizing>('sizing', sizing, defaultValue: HarborSizing.fill));
    properties.add(
      PercentProperty(
        'maxExtentFraction',
        maxExtentFraction,
        level: maxExtentFraction == null ? DiagnosticLevel.fine : DiagnosticLevel.info,
      ),
    );
    properties.add(ObjectFlagProperty<HarborWakePainter>.has('wakePainter', wakePainter));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

class _HarborState extends State<Harbor> with WidgetsBindingObserver {
  HarborController? _controller;
  HarborTideGauge? _ownGauge;
  HarborFleet? _ownFleet;
  final GlobalKey _statusBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// On iOS a tap on the status bar scrolls the page's primary scroll view to the top. Flutter
  /// wires that up in `Scaffold` alone, and a page built from a harbor needs no Scaffold, so the
  /// harbor does it, with the Scaffold's own animation and the Scaffold's own test of which page
  /// was tapped: the one whose status bar band a tap at the screen's top left would hit. A page
  /// covered from outside its own navigator, by an overlay, or beside the one at the left is not.
  /// Every position is scrolled, not the controller, since a controller with two scroll views
  /// attached (tabs sharing the primary controller) cannot animate as one.
  @override
  void handleStatusBarTap() {
    super.handleStatusBarTap();
    if (widget._isSea || !_statusBarHitAtOrigin()) {
      return;
    }
    final ScrollController? primary = PrimaryScrollController.maybeOf(context);
    if (primary == null) {
      return;
    }
    final bool still = MediaQuery.disableAnimationsOf(context);
    for (final ScrollPosition position in List<ScrollPosition>.of(primary.positions)) {
      if (still) {
        position.jumpTo(0.0);
      } else {
        position.animateTo(0.0, duration: const Duration(milliseconds: 1000), curve: Curves.easeOutCirc);
      }
    }
  }

  bool _statusBarHitAtOrigin() {
    final RenderObject? band = _statusBarKey.currentContext?.findRenderObject();
    if (band == null) {
      return false;
    }
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, Offset.zero, View.of(context).viewId);
    return result.path.any((final HitTestEntry entry) => identical(entry.target, band));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final HarborController? outer = HarborController.maybeOf(context);
    // A sea inside another harbor is a world of its own: no parent, its own
    // fleet and its own tide gauge (a phone drawn inside a page, say).
    final bool isolated = widget._isSea && outer != null;
    final HarborController? parent = isolated ? null : outer;
    HarborFleet? fleet = isolated ? null : HarborFleetScope.maybeOf(context);
    if (fleet == null) {
      if (_ownFleet == null) {
        _ownFleet = HarborFleet();
        if (!isolated) {
          HarborChart.serve(_ownFleet!);
        }
      }
      fleet = _ownFleet;
    }
    if (_controller == null || !identical(_controller!.parent, parent) || !identical(_controller!.fleet, fleet)) {
      _controller?.leave();
      _controller = HarborController(
        parent: parent,
        fleet: fleet!,
        isPort: widget.newPort || parent == null,
        debugLabel: widget.debugLabel,
      )..onChanged = _rebuild;
      _controller!.join();
    }
    _controller!.route = ModalRoute.of(context);
    if (isolated || HarborTideScope.maybeGaugeOf(context, listen: false) == null) {
      _ownGauge ??= HarborTideGauge();
    }
  }

  void _rebuild() {
    if (!mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
        if (mounted) {
          setState(() {});
        }
      });
      SchedulerBinding.instance.ensureVisualUpdate();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.leave();
    _ownGauge?.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final HarborController controller = _controller!;
    controller.debugLabel = widget.debugLabel;
    final TextDirection direction = Directionality.of(context);
    final MediaQueryData ambient = (widget.coast ?? HarborCoast.ambient).apply(MediaQuery.of(context), direction);
    final HarborWatersData? outer = widget._isSea ? null : HarborWaters.maybeRawOf(context);

    final EdgeInsetsDirectional padding = HarborEdges.directional(ambient.padding, direction);
    final EdgeInsetsDirectional steadyPadding = HarborEdges.directional(ambient.viewPadding, direction);
    final EdgeInsetsDirectional coastOnly = widget.coast != null || outer == null
        ? padding
        : HarborEdges.min(outer.coast, padding);
    final EdgeInsetsDirectional coastOnlySteady = widget.coast != null || outer == null ? steadyPadding : outer.coastSteady;
    final EdgeInsetsDirectional inheritedDocks = widget.newPort || outer == null || widget.coast != null
        ? EdgeInsetsDirectional.zero
        : HarborEdges.min(outer.docks, padding);
    final EdgeInsetsDirectional coast = widget.newPort ? coastOnly : padding;
    // A new port's steady coast is the outer steady padding without the outer docks in it.
    final EdgeInsetsDirectional coastSteady = widget.newPort && outer != null && widget.coast == null
        ? HarborEdges.max(
            coastOnly,
            HarborEdges.build(
              (final HarborEdge e) => (HarborEdges.of(steadyPadding, e) - HarborEdges.of(outer.docks, e)).clamp(0.0, double.infinity),
            ),
          )
        : steadyPadding;
    final double tide = ambient.viewInsets.bottom;
    final EdgeInsetsDirectional minimum = HarborEdges.resolve(widget.minimum, direction);
    _ownGauge?.observe(tide, ambient.size);

    // Docks, with pontoons moored from deeper in the tree, by edge.
    final Map<HarborEdge, List<HarborDock>> docks = <HarborEdge, List<HarborDock>>{
      HarborEdge.top: <HarborDock>[...widget.top, ...controller.pontoonsOn(HarborEdge.top)],
      HarborEdge.bottom: <HarborDock>[...controller.pontoonsOn(HarborEdge.bottom), ...widget.bottom],
      HarborEdge.start: <HarborDock>[...widget.start, ...controller.pontoonsOn(HarborEdge.start)],
      HarborEdge.end: <HarborDock>[...controller.pontoonsOn(HarborEdge.end), ...widget.end],
    };
    controller.dockedEdges = <HarborEdge>{
      for (final MapEntry<HarborEdge, List<HarborDock>> e in docks.entries)
        if (e.value.isNotEmpty) e.key,
    };

    final List<Widget> children = <Widget>[];
    final MediaQueryData bodyBase = ambient;
    children.add(
      HarborSlot.body(
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) {
            final HarborBodyPayload payload = (constraints as HarborBodyConstraints).payload;
            return MediaQuery(
              data: bodyBase.copyWith(
                padding: payload.padding,
                viewPadding: payload.viewPadding,
                viewInsets: bodyBase.viewInsets.copyWith(bottom: payload.viewInsetsBottom),
              ),
              child: HarborWaters(
                data: payload.waters.copyWith(
                  wakesPainted: <HarborEdge>{
                    if (widget.wakePainter != null) ...payload.ownWakes.keys,
                    if (outer != null)
                      for (final HarborEdge e in outer.wakesPainted)
                        if (payload.waters.wakes.containsKey(e) && !payload.ownWakes.containsKey(e)) e,
                  },
                ),
                child: widget.wakePainter?.call(context, payload.ownWakes, widget.body) ?? widget.body,
              ),
            );
          },
        ),
      ),
    );

    for (final HarborEdge edge in HarborEdge.values) {
      final List<HarborDock> list = docks[edge]!;
      // Listed in reading order; counted from the edge inward.
      final bool reversed = edge == HarborEdge.bottom || edge == HarborEdge.end;
      final List<HarborDock> fromEdge = reversed ? list.reversed.toList() : list;
      final HarborDockState? claimed = controller.claimedStateOf(edge);
      int absorbing = -1;
      int innermost = -1;
      final List<HarborDockState> states = <HarborDockState>[];
      for (int i = 0; i < fromEdge.length; i++) {
        final HarborDock dock = fromEdge[i];
        HarborDockState state = dock.state;
        if (claimed == HarborDockState.withdrawn || (dock.withdrawsAtHighTide && tide > 0)) {
          state = HarborDockState.withdrawn;
        } else if (claimed == HarborDockState.dark && state == HarborDockState.open) {
          state = HarborDockState.dark;
        }
        states.add(state);
        if (state != HarborDockState.withdrawn) {
          if (absorbing < 0) {
            absorbing = i;
          }
          innermost = i;
        }
      }
      if (absorbing < 0 && fromEdge.isNotEmpty) {
        absorbing = 0;
        innermost = fromEdge.length - 1;
      }
      for (int i = 0; i < fromEdge.length; i++) {
        final HarborDock dock = fromEdge[i];
        final double coastHere = i == absorbing ? _coastFor(dock, edge, coast, coastSteady, tide, minimum) : 0.0;
        children.add(
          HarborSlot.dock(
            key: dock.key != null ? ValueKey<Object>((edge, dock.key!)) : ValueKey<Object>((edge, i, dock.kind)),
            edge: edge,
            fromEdge: i,
            dock: dock,
            state: states[i],
            child: HarborDockSlot(
              dock: dock,
              edge: edge,
              state: states[i],
              coastPadding: HarborEdges.only(edge, coastHere),
              mediaQuery: _dockMediaQuery(ambient, edge, direction),
              leavesWake: i == innermost,
              onSettled: _rebuild,
            ),
          ),
        );
      }
    }

    if (!widget._isSea && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
      children.add(
        HarborSlot.statusBar(
          child: SizedBox(
            height: ambient.padding.top,
            child: MetaData(key: _statusBarKey, behavior: HitTestBehavior.translucent, child: const SizedBox.expand()),
          ),
        ),
      );
    }

    children.add(
      HarborSlot.buoys(
        child: HarborBuoyLayer(buoys: widget.buoys, signals: controller.signals),
      ),
    );

    Widget result = HarborLayout(
      controller: controller,
      geometry: HarborGeometry(
        textDirection: direction,
        coast: coast,
        coastSteady: coastSteady,
        coastOnly: coastOnly,
        coastOnlySteady: coastOnlySteady,
        inheritedDocks: inheritedDocks,
        inheritedWakes: widget.newPort || outer == null ? const <HarborEdge, HarborWakeBand>{} : outer.wakes,
        tide: tide,
        bodyClearsTide: widget.bodyClearsTide,
        minimum: minimum,
        margin: switch (widget.margin) {
          final EdgeInsetsGeometry margin => HarborEdges.resolve(margin, direction),
          null => outer?.margin ?? EdgeInsetsDirectional.zero,
        },
        sizing: widget.sizing,
        viewHeight: ambient.size.height,
        frameSize: widget.newPort || outer == null || outer.frameSize.isEmpty ? null : outer.frameSize,
        maxExtentFraction: widget.maxExtentFraction,
      ),
      children: children,
    );
    result = HarborNonModalSheetActions(route: controller.route, child: result);
    result = HarborScope(controller: controller, child: result);
    if (_ownFleet != null) {
      result = HarborFleetScope(fleet: _ownFleet!, child: result);
    }
    if (_ownGauge != null) {
      result = HarborTideScope(gauge: _ownGauge!, child: result);
    }
    if (widget.coast != null) {
      result = MediaQuery(data: ambient, child: result);
    }
    return result;
  }

  double _coastFor(
    final HarborDock dock,
    final HarborEdge edge,
    final EdgeInsetsDirectional coast,
    final EdgeInsetsDirectional coastSteady,
    final double tide,
    final EdgeInsetsDirectional minimum,
  ) {
    // What a dry dock holds runs to the screen's edge: no coast, no minimum.
    if (dock.effectiveCoast == HarborCoastStance.none) {
      return 0.0;
    }
    final double value = switch (dock.effectiveCoast) {
      // The platform drops the bottom coast as soon as a keyboard is in; the
      // keyboard only covers it as it rises.
      HarborCoastStance.live when edge == HarborEdge.bottom => math.max(
        HarborEdges.of(coast, edge),
        HarborEdges.of(coastSteady, edge) - tide,
      ),
      HarborCoastStance.live => HarborEdges.of(coast, edge),
      HarborCoastStance.steady => HarborEdges.of(coastSteady, edge) > HarborEdges.of(coast, edge)
          ? HarborEdges.of(coastSteady, edge)
          : HarborEdges.of(coast, edge),
      HarborCoastStance.none => 0.0,
    };
    final double floor = HarborEdges.of(minimum, edge) > dock.minimum ? HarborEdges.of(minimum, edge) : dock.minimum;
    return value > floor ? value : floor;
  }

  static MediaQueryData _dockMediaQuery(final MediaQueryData ambient, final HarborEdge edge, final TextDirection direction) {
    final Set<HarborEdge> absorbed = <HarborEdge>{edge, edge.opposite};
    final ({bool left, bool top, bool right, bool bottom}) sides = HarborEdges.physical(absorbed, direction);
    return ambient
        .removePadding(removeLeft: sides.left, removeTop: sides.top, removeRight: sides.right, removeBottom: sides.bottom)
        .removeViewPadding(removeLeft: sides.left, removeTop: sides.top, removeRight: sides.right, removeBottom: sides.bottom)
        .removeViewInsets(removeBottom: true);
  }
}

/// The sea every harbor floats on. Mount it once, above the app's
/// `Navigator` (`MaterialApp.builder` is the place), so routes, dialogs and
/// sheets all share its coast, its tide gauge and its signals.
///
/// It never moves anything out of the keyboard's way itself: each route and
/// sheet is a [Harbor] that decides for its own docks.
///
/// A sea mounted inside another harbor is a world of its own, with its own
/// tide gauge, fleet and signals: a phone drawn inside a page, or a preview.
class HarborSea extends StatelessWidget {
  const HarborSea({super.key, this.coast = HarborCoast.ambient, this.margin, required this.child});

  final HarborCoast coast;

  /// The mooring line for the whole app, resolved against the reading
  /// direction where the sea is mounted.
  final EdgeInsetsGeometry? margin;

  final Widget child;

  @override
  Widget build(final BuildContext context) => Harbor._sea(coast: coast, margin: margin, body: child);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborCoast>('coast', coast, defaultValue: HarborCoast.ambient));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
  }

}
