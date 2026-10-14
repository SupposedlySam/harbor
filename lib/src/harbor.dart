import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'buoy.dart';
import 'chart.dart';
import 'coast.dart';
import 'controller.dart';
import 'dock.dart';
import 'hinge.dart';
import 'dock_slot.dart';
import 'edge.dart';
import 'render_harbor.dart';
import 'sheet.dart';
import 'tide.dart';
import 'wake.dart';
import 'waters.dart';

/// A frame: a layer whose edges bars are built against, with the body in the
/// middle and floats over whatever room nothing covers.
///
/// The one rule: **a bar on the same layer takes space; a bar on a higher
/// layer becomes padding for everything beneath it.** Solid bars
/// ([HarborBar.solid]) take space, so the body ends where they do. Overlay bars
/// ([HarborBar.overlay]) lie over the body, so the body runs under them and
/// its `MediaQuery.padding` says how far they reach. Content inside keeps
/// clear of that ([HarborClear]), scrolls under it and rests clear
/// ([HarborScrollView]), or ignores it and reads the room itself
/// ([HarborRoom.of]).
///
/// Bars are measured in the same layout pass as the body, so a header that
/// grows with the text size is cleared at the size it grew to, and nothing
/// lags a drawn frame.
///
/// The keyboard comes in from the bottom. With [bodyClearsKeyboard] the body
/// ends at the keyboard's top, as a resizing `Scaffold`'s does; bars decide
/// for themselves whether they ride it, stay under it, or reserve its height
/// ([HarborBar.keyboard]).
///
/// A frame inside another sees the outer frame's bars as part of its system
/// edges, as a component inside a page does. A page ([isPage]) does not: a
/// route or a sheet starts fresh, with only the system edges.
///
/// See also:
///
///  * `Scaffold`, the closest Flutter widget, which has one app bar sized by its `preferredSize` and
///    one bottom bar.
class HarborFrame extends StatefulWidget {
  const HarborFrame({
    super.key,
    this.top = const <HarborBar>[],
    this.bottom = const <HarborBar>[],
    this.start = const <HarborBar>[],
    this.end = const <HarborBar>[],
    required this.body,
    final List<HarborFloat> floats = const <HarborFloat>[],
    @Deprecated('Renamed floats. `dart fix` applies it.') final List<HarborFloat>? buoys,
    final HarborSystemEdges? systemEdges,
    @Deprecated('Renamed systemEdges. `dart fix` applies it.') final HarborSystemEdges? coast,
    final bool isPage = false,
    @Deprecated('Renamed isPage. `dart fix` applies it.') final bool? newPort,
    final bool bodyClearsKeyboard = true,
    @Deprecated('Renamed bodyClearsKeyboard. `dart fix` applies it.') final bool? bodyClearsTide,
    this.margin,
    this.minimum = EdgeInsetsDirectional.zero,
    this.sizing = HarborSizing.fill,
    this.maxExtentFraction,
    final HarborEdgeEffectPainter? edgeEffectPainter,
    @Deprecated('Renamed edgeEffectPainter. `dart fix` applies it.') final HarborEdgeEffectPainter? wakePainter,
    this.debugLabel,
    this.hinge,
    final HarborHinge? barHinge,
    @Deprecated('Renamed barHinge. `dart fix` applies it.') final HarborHinge? dockHinge,
  }) : assert(
         buoys == null || identical(floats, const <HarborFloat>[]) || identical(buoys, floats),
         'floats and the deprecated buoys disagree. Give floats alone.',
       ),
       assert(coast == null || systemEdges == null, 'Give systemEdges or the deprecated coast, not both.'),
       assert(
         newPort == null || !isPage || newPort == isPage,
         'isPage and the deprecated newPort disagree. Give isPage alone.',
       ),
       assert(
         bodyClearsTide == null || bodyClearsKeyboard || bodyClearsTide == bodyClearsKeyboard,
         'bodyClearsKeyboard and the deprecated bodyClearsTide disagree. Give bodyClearsKeyboard alone.',
       ),
       assert(
         wakePainter == null || edgeEffectPainter == null,
         'Give edgeEffectPainter or the deprecated wakePainter, not both.',
       ),
       assert(dockHinge == null || barHinge == null, 'Give barHinge or the deprecated dockHinge, not both.'),
       floats = buoys ?? floats,
       systemEdges = systemEdges ?? coast,
       isPage = newPort ?? isPage,
       bodyClearsKeyboard = bodyClearsTide ?? bodyClearsKeyboard,
       edgeEffectPainter = edgeEffectPainter ?? wakePainter,
       barHinge = barHinge ?? dockHinge,
       _isSea = false,
       _observers = const <HarborFrameObserver>[];

  /// A frame that starts a page: a route, a sheet, a dialog. [isPage] is true, so the bars of the
  /// frame around it don't reach in, only the system edges do. As Navigator's `Page` is a route's
  /// content, this is the frame a route's content is built from.
  const HarborFrame.page({
    super.key,
    this.top = const <HarborBar>[],
    this.bottom = const <HarborBar>[],
    this.start = const <HarborBar>[],
    this.end = const <HarborBar>[],
    required this.body,
    this.floats = const <HarborFloat>[],
    this.systemEdges,
    this.bodyClearsKeyboard = true,
    this.margin,
    this.minimum = EdgeInsetsDirectional.zero,
    this.sizing = HarborSizing.fill,
    this.maxExtentFraction,
    this.edgeEffectPainter,
    this.debugLabel,
    this.hinge,
    this.barHinge,
  }) : isPage = true,
       _isSea = false,
       _observers = const <HarborFrameObserver>[];

  /// The outermost frame of a root: see [HarborRoot].
  const HarborFrame._sea({
    this.systemEdges,
    this.margin,
    required this.body,
    required this._observers,
    required this.hinge,
  }) : barHinge = null,
       top = const <HarborBar>[],
       bottom = const <HarborBar>[],
       start = const <HarborBar>[],
       end = const <HarborBar>[],
       floats = const <HarborFloat>[],
       isPage = true,
       bodyClearsKeyboard = false,
       minimum = EdgeInsetsDirectional.zero,
       sizing = HarborSizing.fill,
       maxExtentFraction = null,
       edgeEffectPainter = null,
       debugLabel = 'sea',
       _isSea = true;

  /// Which hinges and folds this frame's overlays keep off, for the page and what it opens; the
  /// root's, or [HarborHinge.avoidSeparating], when null. See [HarborHinge].
  final HarborHinge? hinge;

  /// Which hinges and folds this frame's own bars keep off, when they should differ from what
  /// its overlays keep off: `barHinge: HarborHinge.never` lays a tab bar across the hinge while
  /// sheets, dialogs, toasts and menus shown beneath still keep off it. Null takes [hinge], then
  /// the policy above. Read by the bars alone; the overlays never see it.
  final HarborHinge? barHinge;

  /// The old name of [barHinge].
  @Deprecated('Renamed barHinge. `dart fix` applies it.')
  HarborHinge? get dockHinge => barHinge;

  /// Whether this is the outermost frame of a [HarborRoot].
  final bool _isSea;

  /// A root's [HarborRoot.observers].
  final List<HarborFrameObserver> _observers;

  /// Bars against the top edge, listed top to bottom.
  final List<HarborBar> top;

  /// Bars against the bottom edge, listed top to bottom.
  final List<HarborBar> bottom;

  /// Bars against the start edge, listed in reading order.
  final List<HarborBar> start;

  /// Bars against the end edge, listed in reading order.
  final List<HarborBar> end;

  final Widget body;

  /// The floats over the room: menus, bubbles, messages.
  final List<HarborFloat> floats;

  /// The old name of [floats].
  @Deprecated('Renamed floats. `dart fix` applies it.')
  List<HarborFloat> get buoys => floats;

  /// Where this frame's system edges come from. Null inherits them.
  final HarborSystemEdges? systemEdges;

  /// The old name of [systemEdges].
  @Deprecated('Renamed systemEdges. `dart fix` applies it.')
  HarborSystemEdges? get coast => systemEdges;

  /// Whether this frame starts a page (a route, a sheet, a dialog): the bars
  /// of the frame around it don't reach in, only the system edges do.
  final bool isPage;

  /// The old name of [isPage].
  @Deprecated('Renamed isPage. `dart fix` applies it.')
  bool get newPort => isPage;

  /// Whether the body ends at the keyboard's top when the keyboard is up. Off, the
  /// body runs under the keyboard and is told how far it reaches.
  final bool bodyClearsKeyboard;

  /// The old name of [bodyClearsKeyboard].
  @Deprecated('Renamed bodyClearsKeyboard. `dart fix` applies it.')
  bool get bodyClearsTide => bodyClearsKeyboard;

  /// The margin content keeps from whatever is in its way, for the content
  /// that asks for it. Null inherits it. Resolved against the reading direction
  /// where this frame is built.
  final EdgeInsetsGeometry? margin;

  /// The least the body keeps clear of on each edge, system edge or not: the bottom
  /// of a phone with no home indicator.
  final EdgeInsetsGeometry minimum;

  final HarborSizing sizing;

  /// For [HarborSizing.hugBody]: the most of the space above the keyboard the
  /// frame may take.
  final double? maxExtentFraction;

  /// Paints an edge effect over the whole body. Null (the default) leaves the
  /// edge effect to the scroll views in it, which fade their content as it
  /// scrolls under the bars, while content outside one (a background, a hero)
  /// stays as it is.
  final HarborEdgeEffectPainter? edgeEffectPainter;

  /// The old name of [edgeEffectPainter].
  @Deprecated('Renamed edgeEffectPainter. `dart fix` applies it.')
  HarborEdgeEffectPainter? get wakePainter => edgeEffectPainter;

  /// This frame's name in the [HarborInspector].
  final String? debugLabel;

  /// The handle of the nearest frame above [context], as `Scaffold.of`
  /// returns the nearest `ScaffoldState`. Throws a [FlutterError], in release
  /// builds too, when there is none; [maybeOf] returns null instead.
  ///
  /// It does not make [context] depend on the frame: read it in a callback
  /// or a lifecycle method, not to decide what to build.
  static HarborController of(final BuildContext context) =>
      HarborController.maybeOf(context) ?? (throw harborNotFound(context, 'HarborFrame'));

  /// The handle of the nearest frame above [context], or null when there is none.
  static HarborController? maybeOf(final BuildContext context) => HarborController.maybeOf(context);

  @override
  State<HarborFrame> createState() => _HarborState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final (String name, List<HarborBar> bars) in <(String, List<HarborBar>)>[
      ('top', top),
      ('bottom', bottom),
      ('start', start),
      ('end', end),
    ]) {
      properties.add(
        IterableProperty<HarborBar>(name, bars, level: bars.isEmpty ? DiagnosticLevel.fine : DiagnosticLevel.info),
      );
    }
    properties.add(
      IterableProperty<HarborFloat>(
        'floats',
        floats,
        level: floats.isEmpty ? DiagnosticLevel.fine : DiagnosticLevel.info,
      ),
    );
    properties.add(DiagnosticsProperty<HarborSystemEdges>('systemEdges', systemEdges, defaultValue: null));
    properties.add(FlagProperty('isPage', value: isPage, ifTrue: 'page'));
    properties.add(
      FlagProperty('bodyClearsKeyboard', value: bodyClearsKeyboard, ifFalse: 'body runs under the keyboard'),
    );
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
    properties.add(ObjectFlagProperty<HarborEdgeEffectPainter>.has('edgeEffectPainter', edgeEffectPainter));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

class _HarborState extends State<HarborFrame> with WidgetsBindingObserver {
  HarborController? _controller;
  HarborTideGauge? _ownGauge;
  HarborFrameRegistry? _ownFleet;
  final GlobalKey _statusBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// On iOS a tap on the status bar scrolls the page's primary scroll view to the top. Flutter
  /// wires that up in `Scaffold` alone, and a page built from a frame needs no Scaffold, so the
  /// frame does it, with the Scaffold's own animation and the Scaffold's own test of which page
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
    // A root inside another frame is a world of its own: no parent, its own
    // registry and its own keyboard gauge (a phone drawn inside a page, say).
    final bool isolated = widget._isSea && outer != null;
    final HarborController? parent = isolated ? null : outer;
    HarborFrameRegistry? registry = isolated ? null : HarborFleetScope.maybeOf(context);
    if (registry == null) {
      if (_ownFleet == null) {
        _ownFleet = HarborFrameRegistry();
        HarborInspector.register(_ownFleet!, isolated: isolated);
      }
      registry = _ownFleet;
    }
    // Before the root joins, so its observers hear it join too.
    _observe(registry!);
    if (_controller == null || !identical(_controller!.parent, parent) || !identical(_controller!.registry, registry)) {
      _controller?.leave();
      _controller = HarborController(
        parent: parent,
        registry: registry,
        isPage: widget.isPage || parent == null,
        isRoot: widget._isSea,
        debugLabel: widget.debugLabel,
      )..onChanged = _rebuild;
      _controller!.join();
    }
    _controller!.route = ModalRoute.of(context);
    if (isolated || HarborTideScope.maybeGaugeOf(context, listen: false) == null) {
      _ownGauge ??= HarborTideGauge();
    }
  }

  /// The registry this root's observers are registered with, and which.
  HarborFrameRegistry? _observedFleet;
  List<HarborFrameObserver> _observing = const <HarborFrameObserver>[];

  void _observe(final HarborFrameRegistry registry) {
    if (identical(registry, _observedFleet) && listEquals(_observing, widget._observers)) {
      return;
    }
    if (_observedFleet case final HarborFrameRegistry old) {
      _observing.forEach(old.removeObserver);
    }
    _observedFleet = registry;
    _observing = List<HarborFrameObserver>.of(widget._observers);
    _observing.forEach(registry.addObserver);
  }

  @override
  void didUpdateWidget(final HarborFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_observedFleet case final HarborFrameRegistry registry) {
      _observe(registry);
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
    if (_ownFleet case final HarborFrameRegistry registry) {
      HarborInspector.unregister(registry);
    }
    // After the frame drawn, once the leaves in it (the root's own and its
    // pages', which go first) have been delivered to them.
    if (_observedFleet case final HarborFrameRegistry registry when _observing.isNotEmpty) {
      final List<HarborFrameObserver> observing = _observing;
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) => observing.forEach(registry.removeObserver));
    }
    _ownGauge?.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final HarborController controller = _controller!;
    controller.debugLabel = widget.debugLabel;
    final TextDirection direction = Directionality.of(context);
    final MediaQueryData ambient = (widget.systemEdges ?? HarborSystemEdges.ambient).apply(
      MediaQuery.of(context),
      direction,
    );
    final HarborRoomData? outer = widget._isSea ? null : HarborRoom.maybeRawOf(context);

    final EdgeInsetsDirectional padding = HarborEdges.directional(ambient.padding, direction);
    final EdgeInsetsDirectional steadyPadding = HarborEdges.directional(ambient.viewPadding, direction);
    final EdgeInsetsDirectional coastOnly = widget.systemEdges != null || outer == null
        ? padding
        : HarborEdges.min(outer.systemEdges, padding);
    final EdgeInsetsDirectional coastOnlySteady = widget.systemEdges != null || outer == null
        ? steadyPadding
        : outer.systemEdgesSteady;
    final EdgeInsetsDirectional inheritedDocks = widget.isPage || outer == null || widget.systemEdges != null
        ? EdgeInsetsDirectional.zero
        : HarborEdges.min(outer.bars, padding);
    final EdgeInsetsDirectional systemEdges = widget.isPage ? coastOnly : padding;
    // A page's steady system edges are the outer steady padding without the outer bars in it.
    final EdgeInsetsDirectional systemEdgesSteady = widget.isPage && outer != null && widget.systemEdges == null
        ? HarborEdges.max(
            coastOnly,
            HarborEdges.build(
              (final HarborEdge e) =>
                  (HarborEdges.of(steadyPadding, e) - HarborEdges.of(outer.bars, e)).clamp(0.0, double.infinity),
            ),
          )
        : steadyPadding;
    final double keyboard = ambient.viewInsets.bottom;
    final EdgeInsetsDirectional minimum = HarborEdges.resolve(widget.minimum, direction);
    _ownGauge?.observe(keyboard, ambient.size);

    // Bars, with the bars attached from deeper in the tree, by edge.
    final Map<HarborEdge, List<HarborBar>> bars = <HarborEdge, List<HarborBar>>{
      HarborEdge.top: <HarborBar>[...widget.top, ...controller.attachedBarsOn(HarborEdge.top)],
      HarborEdge.bottom: <HarborBar>[...controller.attachedBarsOn(HarborEdge.bottom), ...widget.bottom],
      HarborEdge.start: <HarborBar>[...widget.start, ...controller.attachedBarsOn(HarborEdge.start)],
      HarborEdge.end: <HarborBar>[...controller.attachedBarsOn(HarborEdge.end), ...widget.end],
    };
    controller.edgesWithBars = <HarborEdge>{
      for (final MapEntry<HarborEdge, List<HarborBar>> e in bars.entries)
        if (e.value.isNotEmpty) e.key,
    };

    // The sides a side bar holds. A top or bottom bar runs between the side bars, which take
    // the system edges on those sides, so it is not handed those system edges again.
    HarborBarState stateOf(final HarborBar dock, final HarborEdge edge) {
      final HarborBarState? claimed = controller.claimedStateOf(edge);
      if (claimed == HarborBarState.withdrawn || (dock.withdrawsAtHighTide && keyboard > 0)) {
        return HarborBarState.withdrawn;
      }
      if (claimed == HarborBarState.dark && dock.state == HarborBarState.open) {
        return HarborBarState.dark;
      }
      return dock.state;
    }

    final Set<HarborEdge> sidesHeld = <HarborEdge>{
      for (final HarborEdge side in HarborEdge.horizontal)
        if (bars[side]!.any((final HarborBar dock) => stateOf(dock, side) != HarborBarState.withdrawn)) side,
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
              child: HarborRoom(
                data: payload.waters.copyWith(
                  fadeBandsPainted: <HarborEdge>{
                    if (widget.edgeEffectPainter != null) ...payload.ownWakes.keys,
                    if (outer != null)
                      for (final HarborEdge e in outer.fadeBandsPainted)
                        if (payload.waters.fadeBands.containsKey(e) && !payload.ownWakes.containsKey(e)) e,
                  },
                ),
                child: widget.edgeEffectPainter?.call(context, payload.ownWakes, widget.body) ?? widget.body,
              ),
            );
          },
        ),
      ),
    );

    for (final HarborEdge edge in HarborEdge.values) {
      final List<HarborBar> list = bars[edge]!;
      // Listed in reading order; counted from the edge inward.
      final bool reversed = edge == HarborEdge.bottom || edge == HarborEdge.end;
      final List<HarborBar> fromEdge = reversed ? list.reversed.toList() : list;
      int absorbing = -1;
      int innermost = -1;
      final List<HarborBarState> states = <HarborBarState>[];
      for (int i = 0; i < fromEdge.length; i++) {
        final HarborBar dock = fromEdge[i];
        final HarborBarState state = stateOf(dock, edge);
        states.add(state);
        if (state != HarborBarState.withdrawn) {
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
        final HarborBar dock = fromEdge[i];
        final double coastHere = i == absorbing
            ? _coastFor(dock, edge, systemEdges, systemEdgesSteady, keyboard, minimum)
            : 0.0;
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
              mediaQuery: _dockMediaQuery(
                ambient,
                edge,
                direction,
                sidesHeld: edge.isVertical ? sidesHeld : const <HarborEdge>{},
              ),
              leavesWake: i == innermost,
              onSettled: _rebuild,
            ),
          ),
        );
      }
    }

    if (!widget._isSea &&
        (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)) {
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
      HarborSlot.floats(
        child: HarborBuoyLayer(floats: widget.floats, toasts: controller.shownToasts),
      ),
    );

    Widget result = HarborLayout(
      controller: controller,
      geometry: HarborGeometry(
        textDirection: direction,
        systemEdges: systemEdges,
        systemEdgesSteady: systemEdgesSteady,
        coastOnly: coastOnly,
        coastOnlySteady: coastOnlySteady,
        inheritedDocks: inheritedDocks,
        inheritedWakes: widget.isPage || outer == null ? const <HarborEdge, HarborFadeBand>{} : outer.fadeBands,
        keyboard: keyboard,
        bodyClearsKeyboard: widget.bodyClearsKeyboard,
        minimum: minimum,
        margin: switch (widget.margin) {
          final EdgeInsetsGeometry margin => HarborEdges.resolve(margin, direction),
          null => outer?.margin ?? EdgeInsetsDirectional.zero,
        },
        sizing: widget.sizing,
        viewHeight: ambient.size.height,
        frameSize: widget.isPage || outer == null || outer.frameSize.isEmpty ? null : outer.frameSize,
        maxExtentFraction: widget.maxExtentFraction,
        clearWaterFloor: HarborClearWaterFloor.of(context),
        hinges: <Rect>[
          for (final DisplayFeature feature in (widget.barHinge ?? widget.hinge ?? HarborHinge.of(context)).keptOff(
            MediaQuery.displayFeaturesOf(context),
          ))
            feature.bounds,
        ],
        screenSize: ambient.size,
      ),
      children: children,
    );
    result = HarborModalBuoyActions(floats: widget.floats, child: result);
    result = HarborNonModalSheetActions(route: controller.route, child: result);
    result = HarborScope(controller: controller, child: result);
    if (_ownFleet != null) {
      result = HarborFleetScope(registry: _ownFleet!, child: result);
    }
    if (_ownGauge != null) {
      result = HarborTideScope(gauge: _ownGauge!, child: result);
    }
    if (widget.systemEdges != null) {
      result = MediaQuery(data: ambient, child: result);
    }
    if (widget.hinge case final HarborHinge hinge) {
      result = HarborHingeScope(hinge: hinge, child: result);
    }
    // The page's first frame draws the sheets with no barrier that the page opens, outermost, so
    // they see what this frame sees from above.
    if (controller.route case final ModalRoute<Object?> route when controller.isRouteLevel && !widget._isSea) {
      result = HarborPageSheetHost(route: route, child: result);
    }
    return result;
  }

  double _coastFor(
    final HarborBar dock,
    final HarborEdge edge,
    final EdgeInsetsDirectional systemEdges,
    final EdgeInsetsDirectional systemEdgesSteady,
    final double keyboard,
    final EdgeInsetsDirectional minimum,
  ) {
    // What a reserving bar holds runs to the screen's edge: no system edge, no minimum.
    if (dock.effectiveSystemEdges == HarborSystemEdgeStance.none) {
      return 0.0;
    }
    final double value = switch (dock.effectiveSystemEdges) {
      // The platform drops the bottom system edge as soon as a keyboard is up; the
      // keyboard only covers it as it opens.
      HarborSystemEdgeStance.live when edge == HarborEdge.bottom => math.max(
        HarborEdges.of(systemEdges, edge),
        HarborEdges.of(systemEdgesSteady, edge) - keyboard,
      ),
      HarborSystemEdgeStance.live => HarborEdges.of(systemEdges, edge),
      HarborSystemEdgeStance.steady =>
        HarborEdges.of(systemEdgesSteady, edge) > HarborEdges.of(systemEdges, edge)
            ? HarborEdges.of(systemEdgesSteady, edge)
            : HarborEdges.of(systemEdges, edge),
      HarborSystemEdgeStance.none => 0.0,
    };
    final double floor = HarborEdges.of(minimum, edge) > dock.minimum ? HarborEdges.of(minimum, edge) : dock.minimum;
    return value > floor ? value : floor;
  }

  static MediaQueryData _dockMediaQuery(
    final MediaQueryData ambient,
    final HarborEdge edge,
    final TextDirection direction, {
    required final Set<HarborEdge> sidesHeld,
  }) {
    final Set<HarborEdge> absorbed = <HarborEdge>{edge, edge.opposite, ...sidesHeld};
    final ({bool left, bool top, bool right, bool bottom}) sides = HarborEdges.physical(absorbed, direction);
    return ambient
        .removePadding(
          removeLeft: sides.left,
          removeTop: sides.top,
          removeRight: sides.right,
          removeBottom: sides.bottom,
        )
        .removeViewPadding(
          removeLeft: sides.left,
          removeTop: sides.top,
          removeRight: sides.right,
          removeBottom: sides.bottom,
        )
        .removeViewInsets(removeBottom: true);
  }
}

/// The root every frame sits under. Mount it once, above the app's
/// `Navigator` (`MaterialApp.builder` is the place), so routes, dialogs and
/// sheets all share its system edges, its keyboard gauge and its toasts.
///
/// It never moves anything out of the keyboard's way itself: each route and
/// sheet is a [HarborFrame] that decides for its own bars.
///
/// A root mounted inside another frame is a world of its own, with its own
/// keyboard gauge, frame registry and toasts: a phone drawn inside a page, or
/// a preview.
///
/// See also:
///
///  * `MaterialApp.builder`, whose output `MaterialApp` wraps in its `ScaffoldMessenger`, above the [Navigator].
class HarborRoot extends StatelessWidget {
  const HarborRoot({
    super.key,
    final HarborSystemEdges systemEdges = HarborSystemEdges.ambient,
    @Deprecated('Renamed systemEdges. `dart fix` applies it.') final HarborSystemEdges? coast,
    this.margin,
    this.observers = const <HarborFrameObserver>[],
    this.hinge = HarborHinge.avoidSeparating,
    required this.child,
  }) : assert(
         coast == null || identical(systemEdges, HarborSystemEdges.ambient) || identical(coast, systemEdges),
         'systemEdges and the deprecated coast disagree. Give systemEdges alone.',
       ),
       systemEdges = coast ?? systemEdges;

  final HarborSystemEdges systemEdges;

  /// The old name of [systemEdges].
  @Deprecated('Renamed systemEdges. `dart fix` applies it.')
  HarborSystemEdges get coast => systemEdges;

  /// The app's default [HarborHinge]: which hinges and folds sheets, dialogs, toasts and floats
  /// keep off. A `HarborFrame(hinge:)` overrides it for a page, and an overlay's own `hinge:` for that
  /// overlay. [HarborHinge.never] treats a foldable's inner screen as one unbroken screen.
  final HarborHinge hinge;

  /// Told of every frame that joins or leaves this root's registry, the root
  /// included, after the frame drawn that it happens in, as `Navigator.observers`
  /// are told of routes. See [HarborFrameObserver].
  final List<HarborFrameObserver> observers;

  /// The margin for the whole app, resolved against the reading direction
  /// where the root is mounted.
  final EdgeInsetsGeometry? margin;

  final Widget child;

  @override
  Widget build(final BuildContext context) =>
      HarborFrame._sea(systemEdges: systemEdges, margin: margin, observers: observers, hinge: hinge, body: child);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<HarborSystemEdges>('systemEdges', systemEdges, defaultValue: HarborSystemEdges.ambient),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(EnumProperty<HarborHinge>('hinge', hinge, defaultValue: HarborHinge.avoidSeparating));
    properties.add(
      IterableProperty<HarborFrameObserver>(
        'observers',
        observers,
        level: observers.isEmpty ? DiagnosticLevel.fine : DiagnosticLevel.info,
      ),
    );
  }
}
