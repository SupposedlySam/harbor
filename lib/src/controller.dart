import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'dock.dart';
import 'edge.dart';
import 'tide.dart';

/// How a dock makes way when content asks it to.
enum HarborYield {
  /// Lights out: the dock disappears but keeps its ground.
  dark,

  /// The dock withdraws and gives its ground back.
  withdraw,
}

/// A request that a dock make way, returned by [HarborController.makeWay].
/// Release it when the content no longer needs the edge.
class HarborClaim {
  HarborClaim._(this._controller, this.edge, this.mode);

  HarborController? _controller;
  final HarborEdge edge;
  final HarborYield mode;

  bool get isActive => _controller != null;

  void release() {
    final HarborController? controller = _controller;
    _controller = null;
    controller?._releaseClaim(this);
  }
}

/// A breakwater: a sheet (or any overlay) reporting how far it covers the
/// bottom of the harbor that opened it, so that harbor's content keeps clear
/// of it while it is up.
class HarborBreakwater {
  HarborBreakwater._(this._controller, this._coverage, {this.measuresTop = false});

  HarborController? _controller;
  final ValueListenable<double> _coverage;

  /// Whether the listenable holds the cover's top edge in global coordinates
  /// rather than how far it reaches up from the bottom of the screen.
  final bool measuresTop;

  double get coverage => _controller == null || measuresTop ? 0.0 : _coverage.value;

  /// The cover's top edge in global coordinates, for a breakwater that measures it.
  double? get topInGlobal => _controller == null || !measuresTop ? null : _coverage.value;

  void remove() {
    final HarborController? controller = _controller;
    _controller = null;
    controller?._removeBreakwater(this);
  }
}

/// Builds a signal's entrance and exit around [child] from [animation], which
/// runs from 0 to 1 as the signal is raised and back as it is lowered.
typedef HarborSignalTransitionBuilder = Widget Function(BuildContext context, Animation<double> animation, Widget child);

/// A transient buoy raised by `HarborSignals.raise`, which returns it.
class HarborSignalEntry {
  /// Signals are raised with `HarborSignals.raise`.
  @internal
  HarborSignalEntry({
    required this.builder,
    required this.alignment,
    required this.duration,
    final Rect? avoidInGlobal,
    this.raisedIn,
    this.animationStyle,
    this.transitionBuilder,
    this.liveRegion = true,
  }) : _avoidAtRaise = avoidInGlobal;

  static const Duration _defaultTransition = Duration(milliseconds: 220);
  static const Duration _minimumLinger = Duration(milliseconds: 300);

  final WidgetBuilder builder;
  final Alignment alignment;
  final Duration? duration;

  /// The duration and curve of the entrance and exit, 220 ms each way by
  /// default; [AnimationStyle.noAnimation] shows and removes the signal as it is.
  final AnimationStyle? animationStyle;

  /// Builds the entrance and exit; a fade and a slight scale when null.
  final HarborSignalTransitionBuilder? transitionBuilder;

  /// Whether harbor makes the signal a live region with a dismiss action, as
  /// a `SnackBar` makes itself. False leaves the semantics to [builder]'s widget.
  final bool liveRegion;

  /// How long the entrance takes.
  Duration get transitionDuration => animationStyle?.duration ?? _defaultTransition;

  /// How long the exit takes.
  Duration get reverseTransitionDuration => animationStyle?.reverseDuration ?? transitionDuration;

  /// How long a lowered signal stays in the tree: its exit, and never less
  /// than 300 ms, so a child that runs an exit of its own has time to.
  Duration get lingers => reverseTransitionDuration > _minimumLinger ? reverseTransitionDuration : _minimumLinger;

  /// The harbor the signal was raised from, whose clear water it also keeps inside.
  final HarborController? raisedIn;

  final Rect? _avoidAtRaise;

  /// The clear water of the harbor the signal was raised from, in global
  /// coordinates: the signal stays inside it too, so it clears that harbor's
  /// docks (a tab's own header) as well as its target's.
  ///
  /// Read from that harbor's latest layout, not kept from the moment it was raised: a stored
  /// rectangle boxed the signal into a foldable's cover screen after the device opened. The
  /// rectangle from the raise is the fallback once that harbor has gone.
  Rect? get avoidInGlobal => raisedIn?.clearWaterInGlobal() ?? _avoidAtRaise;

  /// Whether the signal is still up: false from the moment it is lowered.
  ValueListenable<bool> get showing => _showing;
  final ValueNotifier<bool> _showing = ValueNotifier<bool>(true);

  /// The harbor showing the signal.
  HarborController? get owner => _owner;
  HarborController? _owner;

  /// Lowers the signal.
  void lower() => _showing.value = false;
}

/// The dock positions and clearances a harbor laid out last, in its own coordinates.
@immutable
class HarborLayoutRecord {
  const HarborLayoutRecord({
    required this.frame,
    required this.body,
    required this.clearWater,
    required this.docks,
    required this.obstruction,
    required this.tide,
  });

  final Rect frame;
  final Rect body;
  final Rect clearWater;
  final List<HarborDockRecord> docks;
  final EdgeInsetsDirectional obstruction;
  final double tide;
}

/// One dock as it was last laid out.
@immutable
class HarborDockRecord {
  const HarborDockRecord({
    required this.edge,
    required this.kind,
    required this.rect,
    required this.extent,
    required this.restingExtent,
    required this.state,
    required this.tide,
    this.label,
  });

  final HarborEdge edge;
  final HarborDockKind kind;
  final Rect rect;
  final double extent;
  final double restingExtent;
  final HarborDockState state;
  final String? label;
  final HarborTideStance tide;
}

/// Everything harbors in one view know about each other: which is on top
/// (where a signal goes) and the list a chart reads.
class HarborFleet {
  final List<HarborController> _harbors = <HarborController>[];

  /// Every harbor mounted in this view, outermost first.
  List<HarborController> get harbors => List<HarborController>.unmodifiable(_harbors);

  void _join(final HarborController controller) => _harbors.add(controller);

  void _leave(final HarborController controller) {
    _harbors.remove(controller);
    // Signals on a harbor that is leaving move to the one now on top. With no
    // harbor left to show them, they are lowered, which stops their timers.
    final List<HarborSignalEntry> orphans = controller._releaseSignals();
    final HarborController? top = topmost;
    for (final HarborSignalEntry signal in orphans) {
      if (top != null) {
        top._raiseSignal(signal);
      } else {
        signal.lower();
      }
    }
  }

  /// The port on top: the frame a signal goes to. Only the first harbor of
  /// each route (and of each sheet over the sea) counts, so a frame embedded in
  /// a page never takes a page's signals; among those, the most recently opened
  /// whose route is showing.
  HarborController? get topmost {
    HarborController? fallback;
    for (int i = _harbors.length - 1; i >= 0; i--) {
      final HarborController candidate = _harbors[i];
      if (!candidate.isRouteLevel) {
        continue;
      }
      final ModalRoute<Object?>? route = candidate.route;
      if (route == null || route.isCurrent) {
        return candidate;
      }
      if (route.isActive) {
        fallback ??= candidate;
      }
    }
    return fallback ?? (_harbors.isEmpty ? null : _harbors.first);
  }

  /// The outermost harbor, where signals go when asked to stay put.
  HarborController? get sea => _harbors.isEmpty ? null : _harbors.first;
}

/// A harbor's handle on itself, for its docks, its content and its neighbors.
///
/// Get it with `Harbor.of`, as a `Scaffold`'s is got with `Scaffold.of`. The
/// harbor makes it; claims, pontoons and breakwaters registered here change
/// what the harbor builds, and are applied on the next frame when they arrive
/// during one.
class HarborController {
  /// Made by the harbor it belongs to.
  @internal
  HarborController({required this.parent, required this.fleet, required this.isPort, this._debugLabel});

  /// The harbor this one sits in, if any.
  final HarborController? parent;

  final HarborFleet fleet;

  /// Whether this harbor is a port (the sea, a route or a sheet) rather than a
  /// component inside one. Reserved and not yet read: signals find their port
  /// with [isRouteLevel] instead.
  final bool isPort;

  /// This harbor's name on a chart.
  String? get debugLabel => _debugLabel;
  @internal
  set debugLabel(final String? value) => _debugLabel = value;
  String? _debugLabel;

  /// Called when something registered here changes what the harbor builds.
  @internal
  VoidCallback? onChanged;

  /// The edges this harbor has docks on.
  Set<HarborEdge> get dockedEdges => Set<HarborEdge>.unmodifiable(_dockedEdges);
  @internal
  set dockedEdges(final Set<HarborEdge> value) => _dockedEdges = value;
  Set<HarborEdge> _dockedEdges = <HarborEdge>{};

  /// The route this harbor is in, if any.
  ModalRoute<Object?>? get route => _route;
  @internal
  set route(final ModalRoute<Object?>? value) => _route = value;
  ModalRoute<Object?>? _route;

  /// Whether this is the first harbor of its route, or sits right on the sea:
  /// a port signals can go to.
  bool get isRouteLevel {
    final HarborController? parent = this.parent;
    return parent == null || parent.parent == null || !identical(route, parent.route);
  }

  /// The last layout, in this harbor's coordinates.
  @Deprecated(
    'Read HarborChart.nearest(context), which has the same rectangles in global coordinates, or listen to '
    'clearWater. This getter goes in a later release.',
  )
  HarborLayoutRecord? get lastLayout => _layoutRecord;

  /// The render object of the harbor.
  @Deprecated(
    'Read HarborChart.nearest(context) for the harbor\'s rectangles in global coordinates, or clearWaterInGlobal(). '
    'This getter goes in a later release.',
  )
  RenderBox? get renderBox => layoutBox;

  /// The last layout, for charts and for overlays that need the clear water.
  @internal
  HarborLayoutRecord? get layoutRecord => _layoutRecord;
  HarborLayoutRecord? _layoutRecord;

  /// The render object of the harbor, to map the last layout into global coordinates.
  @internal
  RenderBox? layoutBox;

  final List<HarborClaim> _claims = <HarborClaim>[];
  final List<HarborPontoonHandle> _pontoons = <HarborPontoonHandle>[];
  final List<HarborBreakwater> _breakwaters = <HarborBreakwater>[];
  final List<HarborSignalEntry> _signals = <HarborSignalEntry>[];
  final Map<HarborSignalEntry, VoidCallback> _signalListeners = <HarborSignalEntry, VoidCallback>{};
  final Map<HarborSignalEntry, Timer> _signalRemovals = <HarborSignalEntry, Timer>{};
  final _BreakwaterNotifier _breakwaterChanges = _BreakwaterNotifier();

  /// The nearest harbor above [context].
  static HarborController? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborScope>()?.controller;

  static HarborController of(final BuildContext context) {
    final HarborController? controller = maybeOf(context);
    assert(controller != null, 'No Harbor above this context.');
    return controller!;
  }

  /// The nearest harbor, from this one outward, that has a dock on [edge].
  HarborController? withDockOn(final HarborEdge edge) {
    HarborController? candidate = this;
    while (candidate != null) {
      if (candidate._dockedEdges.contains(edge)) {
        return candidate;
      }
      candidate = candidate.parent;
    }
    return null;
  }

  // Claims.

  /// Asks the docks on [edge] to make way: go [HarborYield.dark] or
  /// [HarborYield.withdraw]. Claims are counted, so the dock comes back only
  /// when every claim is released. The claim goes to the nearest harbor, from
  /// this one outward, that has a dock on [edge].
  HarborClaim makeWay(final HarborEdge edge, {final HarborYield mode = HarborYield.withdraw}) {
    final HarborController target = withDockOn(edge) ?? this;
    final HarborClaim claim = HarborClaim._(target, edge, mode);
    target._claims.add(claim);
    target._changed();
    return claim;
  }

  void _releaseClaim(final HarborClaim claim) {
    if (_claims.remove(claim)) {
      _changed();
    }
  }

  /// The state claims impose on [edge], or null when nothing has asked.
  HarborDockState? claimedStateOf(final HarborEdge edge) {
    bool dark = false;
    for (final HarborClaim claim in _claims) {
      if (claim.edge != edge) {
        continue;
      }
      if (claim.mode == HarborYield.withdraw) {
        return HarborDockState.withdrawn;
      }
      dark = true;
    }
    return dark ? HarborDockState.dark : null;
  }

  // Pontoons.

  /// Moors [dock] on [edge] of this harbor, as a [HarborPontoon] does, until
  /// the returned handle is given to [removePontoon].
  HarborPontoonHandle addPontoon(final HarborEdge edge, final HarborDock dock) {
    final HarborPontoonHandle pontoon = HarborPontoonHandle._(edge, dock);
    _pontoons.add(pontoon);
    _changed();
    return pontoon;
  }

  /// Moves the pontoon [handle] stands for to [edge] and rebuilds it as [dock].
  void updatePontoon(final HarborPontoonHandle handle, final HarborEdge edge, final HarborDock dock) {
    if (handle._edge == edge && identical(handle._dock, dock)) {
      return;
    }
    handle
      .._edge = edge
      .._dock = dock;
    _changed();
  }

  /// Takes the pontoon [handle] stands for out of this harbor.
  void removePontoon(final HarborPontoonHandle handle) {
    if (_pontoons.remove(handle)) {
      _changed();
    }
  }

  /// Docks moored here from deeper in the tree, by edge, in arrival order.
  List<HarborDock> pontoonsOn(final HarborEdge edge) => <HarborDock>[
    for (final HarborPontoonHandle p in _pontoons)
      if (p._edge == edge) p._dock,
  ];

  // Breakwaters.

  /// Reports that something now covers [coverage] of this harbor's bottom edge
  /// (measured from the bottom of the screen). Content keeps clear of it until
  /// the breakwater is removed.
  HarborBreakwater addBreakwater(final ValueListenable<double> coverage) {
    final HarborBreakwater breakwater = HarborBreakwater._(this, coverage);
    _breakwaters.add(breakwater);
    coverage.addListener(_breakwaterChanges.ping);
    _breakwaterChanges.ping();
    return breakwater;
  }

  void _removeBreakwater(final HarborBreakwater breakwater) {
    if (_breakwaters.remove(breakwater)) {
      breakwater._coverage.removeListener(_breakwaterChanges.ping);
      _breakwaterChanges.ping();
    }
  }

  /// Reports that something covers this harbor's bottom up to [topInGlobal], a
  /// top edge in global coordinates. Unlike [addBreakwater] it holds under any
  /// scale between the cover and the screen (a preview, a scale model).
  HarborBreakwater addBreakwaterEdge(final ValueListenable<double> topInGlobal) {
    final HarborBreakwater breakwater = HarborBreakwater._(this, topInGlobal, measuresTop: true);
    _breakwaters.add(breakwater);
    topInGlobal.addListener(_breakwaterChanges.ping);
    _breakwaterChanges.ping();
    return breakwater;
  }

  /// The top edges, in global coordinates, of breakwaters that measure one.
  Iterable<double> get breakwaterTopsInGlobal sync* {
    for (final HarborBreakwater breakwater in _breakwaters) {
      final double? top = breakwater.topInGlobal;
      if (top != null && top.isFinite) {
        yield top;
      }
    }
  }

  /// How far breakwaters cover the bottom of the screen, the largest of them.
  double get breakwaterCoverage {
    double largest = 0.0;
    for (final HarborBreakwater breakwater in _breakwaters) {
      if (breakwater.coverage > largest) {
        largest = breakwater.coverage;
      }
    }
    return largest;
  }

  /// Fires when a breakwater moves, so the harbor can lay out again without rebuilding.
  Listenable get breakwaterChanges => _breakwaterChanges;

  // Signals.

  List<HarborSignalEntry> get signals => List<HarborSignalEntry>.unmodifiable(_signals);

  void _raiseSignal(final HarborSignalEntry signal) {
    signal._owner = this;
    _signals.add(signal);
    void lowered() {
      if (!signal.showing.value) {
        // Leave time for the signal's own exit animation.
        _signalRemovals[signal] ??= Timer(signal.lingers, () {
          _signalRemovals.remove(signal);
          _forgetSignal(signal);
          _changed();
        });
      }
    }

    _signalListeners[signal] = lowered;
    signal.showing.addListener(lowered);
    _changed();
  }

  void _forgetSignal(final HarborSignalEntry signal) {
    _signals.remove(signal);
    final VoidCallback? listener = _signalListeners.remove(signal);
    if (listener != null) {
      signal.showing.removeListener(listener);
    }
  }

  /// Lets go of every signal, cancelling pending removals, and returns those
  /// still showing.
  List<HarborSignalEntry> _releaseSignals() {
    final List<HarborSignalEntry> showing = _signals.where((final HarborSignalEntry s) => s.showing.value).toList();
    for (final Timer removal in _signalRemovals.values) {
      removal.cancel();
    }
    _signalRemovals.clear();
    for (final HarborSignalEntry signal in List<HarborSignalEntry>.of(_signals)) {
      _forgetSignal(signal);
    }
    return showing;
  }

  /// Raises [signal] on this harbor.
  @internal
  void raiseSignal(final HarborSignalEntry signal) => _raiseSignal(signal);

  // Lifecycle.

  /// Called by the harbor as it mounts.
  @internal
  void join() => fleet._join(this);

  final List<VoidCallback> _leaveListeners = <VoidCallback>[];

  /// Calls [listener] once when this harbor leaves the tree.
  void addLeaveListener(final VoidCallback listener) => _leaveListeners.add(listener);

  void removeLeaveListener(final VoidCallback listener) => _leaveListeners.remove(listener);

  /// Called by the harbor as it leaves the tree.
  @internal
  void leave() {
    for (final VoidCallback listener in List<VoidCallback>.of(_leaveListeners)) {
      listener();
    }
    _leaveListeners.clear();
    for (final HarborClaim claim in List<HarborClaim>.of(_claims)) {
      claim._controller = null;
    }
    _claims.clear();
    for (final HarborBreakwater breakwater in List<HarborBreakwater>.of(_breakwaters)) {
      breakwater._coverage.removeListener(_breakwaterChanges.ping);
      breakwater._controller = null;
    }
    _breakwaters.clear();
    fleet._leave(this);
    onChanged = null;
  }

  void _changed() {
    final VoidCallback? callback = onChanged;
    if (callback == null) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) => onChanged?.call());
      SchedulerBinding.instance.ensureVisualUpdate();
    } else {
      callback();
    }
  }

  final ValueNotifier<Rect> _clearWater = ValueNotifier<Rect>(Rect.zero);
  bool _clearWaterPending = false;

  /// The water nothing covers, in this harbor's coordinates, a frame after
  /// each layout. For content that follows the docks by transform rather than
  /// relayout (a card that slides as a drawer rises).
  ValueListenable<Rect> get clearWater => _clearWater;

  /// Called by the harbor's layout.
  @internal
  void recordLayout(final HarborLayoutRecord record) {
    _layoutRecord = record;
    if (_clearWater.value == record.clearWater || _clearWaterPending) {
      return;
    }
    _clearWaterPending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _clearWaterPending = false;
      final HarborLayoutRecord? latest = _layoutRecord;
      if (latest != null) {
        _clearWater.value = latest.clearWater;
      }
    });
  }

  /// The water nothing covers, in global coordinates, from the last layout.
  Rect? clearWaterInGlobal() {
    final RenderBox? box = layoutBox;
    final HarborLayoutRecord? layout = _layoutRecord;
    if (box == null || layout == null || !box.attached || !box.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(box.getTransformTo(null), layout.clearWater);
  }
}

/// A dock moored on a harbor by [HarborController.addPontoon]; give it to
/// [HarborController.updatePontoon] and [HarborController.removePontoon].
class HarborPontoonHandle {
  HarborPontoonHandle._(this._edge, this._dock);

  HarborEdge _edge;
  HarborDock _dock;

  /// The edge the pontoon is moored on.
  HarborEdge get edge => _edge;

  /// The dock it is moored as.
  HarborDock get dock => _dock;
}

class _BreakwaterNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Carries a [HarborController] down to the harbor's docks and content.
class HarborScope extends InheritedWidget {
  const HarborScope({super.key, required this.controller, required super.child});

  final HarborController controller;

  @override
  bool updateShouldNotify(final HarborScope oldWidget) => controller != oldWidget.controller;
}

/// Carries the [HarborFleet] down from the outermost harbor.
class HarborFleetScope extends InheritedWidget {
  const HarborFleetScope({super.key, required this.fleet, required super.child});

  final HarborFleet fleet;

  static HarborFleet? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborFleetScope>()?.fleet;

  @override
  bool updateShouldNotify(final HarborFleetScope oldWidget) => fleet != oldWidget.fleet;
}
