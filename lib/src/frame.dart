import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bar.dart';
import 'consumer.dart';
import 'controller.dart';
import 'defaults.dart';
import 'dock_slot.dart';
import 'edge.dart';
import 'edge_effect.dart';
import 'float.dart';
import 'hinge.dart';
import 'inspector.dart';
import 'keyboard.dart';
import 'render_frame.dart';
import 'room.dart';
import 'sheet.dart';
import 'system_edges.dart';

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
    this.floats = const <HarborFloat>[],
    this.systemEdges,
    this.isPage = false,
    this.bodyClearsKeyboard = true,
    this.margin,
    this.minimum = EdgeInsetsDirectional.zero,
    this.sizing = HarborSizing.fill,
    this.edgeEffectPainter,
    this.debugLabel,
    this.defaults,
  }) : _isRoot = false,
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
    this.edgeEffectPainter,
    this.debugLabel,
    this.defaults,
  }) : isPage = true,
       _isRoot = false,
       _observers = const <HarborFrameObserver>[];

  /// The outermost frame of a root: see [HarborRoot].
  const HarborFrame._root({
    this.systemEdges,
    this.margin,
    required this.body,
    required this._observers,
    required this.defaults,
  }) : top = const <HarborBar>[],
       bottom = const <HarborBar>[],
       start = const <HarborBar>[],
       end = const <HarborBar>[],
       floats = const <HarborFloat>[],
       isPage = true,
       bodyClearsKeyboard = false,
       minimum = EdgeInsetsDirectional.zero,
       sizing = HarborSizing.fill,
       edgeEffectPainter = null,
       debugLabel = 'sea',
       _isRoot = true;

  /// The choices this frame makes for its page and everything it opens, merged field by field
  /// over the defaults above it: which hinges its bars and overlays keep off, how its toasts
  /// queue, time and sit, what its barriers are announced as, how wide its sheets are. Null
  /// leaves them all to the frame, root or [HarborDefaultsScope] above. See [HarborDefaults].
  final HarborDefaults? defaults;

  /// Whether this is the outermost frame of a [HarborRoot].
  final bool _isRoot;

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

  /// Where this frame's system edges come from. Null inherits them.
  final HarborSystemEdges? systemEdges;

  /// Whether this frame starts a page (a route, a sheet, a dialog): the bars
  /// of the frame around it don't reach in, only the system edges do.
  final bool isPage;

  /// Whether the body ends at the keyboard's top when the keyboard is up. Off, the
  /// body runs under the keyboard and is told how far it reaches.
  final bool bodyClearsKeyboard;

  /// The margin content keeps from whatever is in its way, for the content
  /// that asks for it. Null inherits it. Resolved against the reading direction
  /// where this frame is built.
  final EdgeInsetsGeometry? margin;

  /// The least the body keeps clear of on each edge, system edge or not: the bottom
  /// of a phone with no home indicator.
  final EdgeInsetsGeometry minimum;

  /// Whether the frame fills the space it is given ([HarborSizing.fill], the default) or is as tall
  /// as its body and solid bars ([HarborSizing.hug]).
  final HarborSizing sizing;

  /// Paints an edge effect over the whole body. Null (the default) leaves the
  /// edge effect to the scroll views in it, which fade their content as it
  /// scrolls under the bars, while content outside one (a background, a hero)
  /// stays as it is.
  final HarborEdgeEffectPainter? edgeEffectPainter;

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
  State<HarborFrame> createState() => _HarborFrameState();

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
    properties.add(
      DiagnosticsProperty<HarborSizing>('sizing', sizing, defaultValue: HarborSizing.fill, description: '$sizing'),
    );
    properties.add(ObjectFlagProperty<HarborEdgeEffectPainter>.has('edgeEffectPainter', edgeEffectPainter));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<HarborDefaults>('defaults', defaults, defaultValue: null));
  }
}

class _HarborFrameState extends State<HarborFrame> with WidgetsBindingObserver {
  HarborController? _controller;
  HarborKeyboardGauge? _ownGauge;
  HarborFrameRegistry? _ownRegistry;
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
    if (widget._isRoot || !_statusBarHitAtOrigin()) {
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
    final bool isolated = widget._isRoot && outer != null;
    final HarborController? parent = isolated ? null : outer;
    HarborFrameRegistry? registry = isolated ? null : HarborFrameRegistryScope.maybeOf(context);
    if (registry == null) {
      if (_ownRegistry == null) {
        _ownRegistry = HarborFrameRegistry();
        HarborInspector.register(_ownRegistry!, isolated: isolated);
      }
      registry = _ownRegistry;
    }
    // Before the root joins, so its observers hear it join too.
    _observe(registry!);
    if (_controller == null || !identical(_controller!.parent, parent) || !identical(_controller!.registry, registry)) {
      _controller?.leave();
      _controller = HarborController(
        parent: parent,
        registry: registry,
        isPage: widget.isPage || parent == null,
        isRoot: widget._isRoot,
        debugLabel: widget.debugLabel,
      )..onChanged = _rebuild;
      _controller!.join();
    }
    _controller!.route = ModalRoute.of(context);
    if (isolated || HarborKeyboardScope.maybeGaugeOf(context, listen: false) == null) {
      _ownGauge ??= HarborKeyboardGauge();
    }
  }

  /// The registry this root's observers are registered with, and which.
  HarborFrameRegistry? _observedRegistry;
  List<HarborFrameObserver> _observing = const <HarborFrameObserver>[];

  void _observe(final HarborFrameRegistry registry) {
    if (identical(registry, _observedRegistry) && listEquals(_observing, widget._observers)) {
      return;
    }
    if (_observedRegistry case final HarborFrameRegistry old) {
      _observing.forEach(old.removeObserver);
    }
    _observedRegistry = registry;
    _observing = List<HarborFrameObserver>.of(widget._observers);
    _observing.forEach(registry.addObserver);
  }

  @override
  void didUpdateWidget(final HarborFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_observedRegistry case final HarborFrameRegistry registry) {
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
    if (_ownRegistry case final HarborFrameRegistry registry) {
      HarborInspector.unregister(registry);
    }
    // After the frame drawn, once the leaves in it (the root's own and its
    // pages', which go first) have been delivered to them.
    if (_observedRegistry case final HarborFrameRegistry registry when _observing.isNotEmpty) {
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
    // A root starts from harbor's own defaults, as it starts a world of its own; any other frame
    // from the defaults above it.
    final HarborDefaults? own = widget.defaults;
    final HarborDefaults resolved = (widget._isRoot ? HarborDefaults.fallback : HarborDefaults.of(context)).merge(own);
    final TextDirection direction = Directionality.of(context);
    final MediaQueryData ambient = (widget.systemEdges ?? HarborSystemEdges.ambient).apply(
      MediaQuery.of(context),
      direction,
    );
    // A frame nested in content keeps clear of what is in the way, so an edge handled for clearing
    // alone above it is not in the way.
    final HarborRoomData? outer = widget._isRoot ? null : HarborRoom.maybeRawOf(context)?.forClearing;

    final EdgeInsetsDirectional padding = HarborEdges.directional(ambient.padding, direction);
    final EdgeInsetsDirectional steadyPadding = HarborEdges.directional(ambient.viewPadding, direction);
    // The edges an overlay put the root's padding back on. Flutter gives an OverlayPortal's child
    // the MediaQuery padding of the overlay it paints in, while the outer room still comes from
    // where the portal is declared: under a frame whose bar took the home indicator, a root-overlay
    // child reads a bottom padding of 34 beside an outer room with no bottom system edge. The
    // signal takes both: the padding is exactly the root's (what the root hands its body, and so
    // the root overlay's), and neither the outer room's system edge nor its bars reach that far.
    // There the padding is all system edge. Padding the app raises with its own MediaQuery is not
    // the root's, and is split by the outer room as always. Padding that is the root's because
    // something covers the root too (a sheet that covers the page) is in the outer room's bars, so
    // it stays a bar.
    final EdgeInsetsDirectional? rootPadding = switch (widget._isRoot ? null : _HarborRootPadding.maybeOf(context)) {
      final EdgeInsets root => HarborEdges.directional(root, direction),
      null => null,
    };
    final Set<HarborEdge> rebased = <HarborEdge>{
      if ((outer, rootPadding) case (
        final HarborRoomData outer,
        final EdgeInsetsDirectional root,
      ) when widget.systemEdges == null)
        for (final HarborEdge e in HarborEdge.values)
          if (HarborEdges.of(padding, e) == HarborEdges.of(root, e) &&
              math.max(HarborEdges.of(outer.systemEdges, e), HarborEdges.of(outer.bars, e)) < HarborEdges.of(root, e))
            e,
    };
    EdgeInsetsDirectional unlessRebased(final EdgeInsetsDirectional value, final EdgeInsetsDirectional ambient) =>
        HarborEdges.build((final HarborEdge e) => HarborEdges.of(rebased.contains(e) ? ambient : value, e));
    final EdgeInsetsDirectional systemEdgesOnly = widget.systemEdges != null || outer == null
        ? padding
        : unlessRebased(HarborEdges.min(outer.systemEdges, padding), padding);
    final EdgeInsetsDirectional systemEdgesOnlySteady = widget.systemEdges != null || outer == null
        ? steadyPadding
        : unlessRebased(outer.systemEdgesSteady, steadyPadding);
    final EdgeInsetsDirectional inheritedBars = widget.isPage || outer == null || widget.systemEdges != null
        ? EdgeInsetsDirectional.zero
        : unlessRebased(HarborEdges.min(outer.bars, padding), EdgeInsetsDirectional.zero);
    final EdgeInsetsDirectional systemEdges = widget.isPage ? systemEdgesOnly : padding;
    // A page's steady system edges are the outer steady padding without the outer bars in it.
    final EdgeInsetsDirectional systemEdgesSteady = widget.isPage && outer != null && widget.systemEdges == null
        ? unlessRebased(
            HarborEdges.max(
              systemEdgesOnly,
              HarborEdges.build(
                (final HarborEdge e) =>
                    (HarborEdges.of(steadyPadding, e) - HarborEdges.of(outer.bars, e)).clamp(0.0, double.infinity),
              ),
            ),
            steadyPadding,
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
    HarborBarState stateOf(final HarborBar bar, final HarborEdge edge) {
      final HarborBarState? claimed = controller.claimedStateOf(edge);
      if (claimed == HarborBarState.withdrawn || (bar.withdrawsWithKeyboard && keyboard > 0)) {
        return HarborBarState.withdrawn;
      }
      if (claimed == HarborBarState.dark && bar.state == HarborBarState.open) {
        return HarborBarState.dark;
      }
      return bar.state;
    }

    final Set<HarborEdge> sidesHeld = <HarborEdge>{
      for (final HarborEdge side in HarborEdge.horizontal)
        if (bars[side]!.any((final HarborBar bar) => stateOf(bar, side) != HarborBarState.withdrawn)) side,
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
              child: _HarborRootPadding.wrap(
                widget._isRoot ? payload.padding : null,
                HarborRoom(
                  data: payload.room.copyWith(
                    fadeBandsPainted: <HarborEdge>{
                      if (widget.edgeEffectPainter != null) ...payload.ownFadeBands.keys,
                      if (outer != null)
                        for (final HarborEdge e in outer.fadeBandsPainted)
                          if (payload.room.fadeBands.containsKey(e) && !payload.ownFadeBands.containsKey(e)) e,
                    },
                  ),
                  child: widget.edgeEffectPainter?.call(context, payload.ownFadeBands, widget.body) ?? widget.body,
                ),
              ),
            );
          },
        ),
      ),
    );

    // What the bar against each edge took as its system edge, for the inspector: a frame nested in
    // another's body takes that frame's insets out of what its own body is handed.
    final Map<HarborEdge, double>? took = kReleaseMode ? null : <HarborEdge, double>{};
    for (final HarborEdge edge in HarborEdge.values) {
      final List<HarborBar> list = bars[edge]!;
      // Listed in reading order; counted from the edge inward.
      final bool reversed = edge == HarborEdge.bottom || edge == HarborEdge.end;
      final List<HarborBar> fromEdge = reversed ? list.reversed.toList() : list;
      int absorbing = -1;
      int innermost = -1;
      final List<HarborBarState> states = <HarborBarState>[];
      for (int i = 0; i < fromEdge.length; i++) {
        final HarborBar bar = fromEdge[i];
        final HarborBarState state = stateOf(bar, edge);
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
        final HarborBar bar = fromEdge[i];
        final double systemEdgeHere = i == absorbing
            ? _systemEdgeFor(bar, edge, systemEdges, systemEdgesSteady, keyboard, minimum)
            : 0.0;
        if (i == absorbing) {
          took?[edge] = systemEdgeHere;
        }
        children.add(
          HarborSlot.bar(
            key: bar.key != null ? ValueKey<Object>((edge, bar.key!)) : ValueKey<Object>((edge, i, bar.kind)),
            edge: edge,
            fromEdge: i,
            bar: bar,
            state: states[i],
            child: HarborDockSlot(
              dock: bar,
              edge: edge,
              state: states[i],
              coastPadding: HarborEdges.only(edge, systemEdgeHere),
              mediaQuery: _barMediaQuery(
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

    if (!widget._isRoot &&
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
        child: HarborFloatLayer(floats: widget.floats, toasts: controller.shownToasts),
      ),
    );

    Widget result = HarborLayout(
      controller: controller,
      geometry: HarborGeometry(
        textDirection: direction,
        systemEdges: systemEdges,
        systemEdgesSteady: systemEdgesSteady,
        systemEdgesOnly: systemEdgesOnly,
        systemEdgesOnlySteady: systemEdgesOnlySteady,
        inheritedBars: inheritedBars,
        inheritedFadeBands: widget.isPage || outer == null ? const <HarborEdge, HarborFadeBand>{} : outer.fadeBands,
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
        maxExtentFraction: widget.sizing.maxFraction,
        roomFloor: HarborRoomFloor.of(context),
        hinges: <Rect>[
          for (final DisplayFeature feature
              // own.barHinge ?? own.hinge ?? inherited.barHinge ?? inherited.hinge: merge puts it so.
              in (resolved.barHinge ?? resolved.hinge ?? HarborHinge.avoidSeparating).keptOff(
                MediaQuery.displayFeaturesOf(context),
              ))
            feature.bounds,
        ],
        screenSize: ambient.size,
      ),
      children: children,
    );
    result = HarborModalFloatActions(floats: widget.floats, child: result);
    result = HarborNonModalSheetActions(route: controller.route, child: result);
    result = HarborScope(controller: controller, child: result);
    // A wrapper that comes and goes between builds changes the type of what the body is built in,
    // and so unmounts the body and every State in it (#164). So a wrapper is conditional here only
    // on what stays the same for the frame's life: the registry and keyboard gauge a frame owns,
    // made once and kept, the route it is in, and whether it is nested. The systemEdges and the
    // defaults a frame is given can come and go, so the MediaQuery and the defaults are always
    // there, handing on what is above when the frame has none of its own.
    if (_ownRegistry != null) {
      result = HarborFrameRegistryScope(registry: _ownRegistry!, child: result);
    }
    if (_ownGauge != null) {
      result = HarborKeyboardScope(gauge: _ownGauge!, child: result);
    }
    result = MediaQuery(data: ambient, child: result);
    result = HarborDefaultsInherited(defaults: resolved, child: result);
    // The page's first frame draws the sheets with no barrier that the page opens, outermost, so
    // they see what this frame sees from above.
    if (controller.route case final ModalRoute<Object?> route when controller.isRouteLevel && !widget._isRoot) {
      result = HarborPageSheetHost(route: route, child: result);
    }
    // A frame nested in another frame's body; a route's page right under the root is not nested.
    if (took != null && !(controller.parent?.isRoot ?? true)) {
      result = HarborConsumerReport.wrap(
        type: 'HarborFrame',
        edges: took.keys,
        amounts: HarborEdges.build((final HarborEdge e) => took[e] ?? 0.0),
        label: widget.debugLabel,
        widgetKey: widget.key,
        child: result,
      );
    }
    return result;
  }

  double _systemEdgeFor(
    final HarborBar bar,
    final HarborEdge edge,
    final EdgeInsetsDirectional systemEdges,
    final EdgeInsetsDirectional systemEdgesSteady,
    final double keyboard,
    final EdgeInsetsDirectional minimum,
  ) {
    // What a reserving bar holds runs to the screen's edge: no system edge, no minimum.
    if (bar.effectiveSystemEdges == HarborSystemEdgeStance.none) {
      return 0.0;
    }
    final double value = switch (bar.effectiveSystemEdges) {
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
    final double floor = HarborEdges.of(minimum, edge) > bar.minimum ? HarborEdges.of(minimum, edge) : bar.minimum;
    return value > floor ? value : floor;
  }

  static MediaQueryData _barMediaQuery(
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
    this.systemEdges = HarborSystemEdges.ambient,
    this.margin,
    this.observers = const <HarborFrameObserver>[],
    this.defaults,
    required this.child,
  });

  final HarborSystemEdges systemEdges;

  /// The app's choices for everything beneath it, merged field by field over
  /// [HarborDefaults.fallback]: a root starts from harbor's own, not from a root it is mounted
  /// in. A frame's [HarborFrame.defaults] overrides them for a page, and an argument given to one
  /// call for that call. See [HarborDefaults].
  final HarborDefaults? defaults;

  /// Told of every frame that joins or leaves this root's registry, the root
  /// included, after the frame drawn that it happens in, as `Navigator.observers`
  /// are told of routes. See [HarborFrameObserver].
  final List<HarborFrameObserver> observers;

  /// The margin for the whole app, resolved against the reading direction
  /// where the root is mounted.
  final EdgeInsetsGeometry? margin;

  final Widget child;

  @override
  Widget build(final BuildContext context) => HarborFrame._root(
    systemEdges: systemEdges,
    margin: margin,
    observers: observers,
    // The root's own hinge is harbor's, so its bars' hinge follows it (merge sets barHinge from it)
    // and frames beneath inherit both, as they did while the root took a hinge of its own.
    defaults: const HarborDefaults(hinge: HarborHinge.avoidSeparating).merge(defaults),
    body: child,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<HarborSystemEdges>('systemEdges', systemEdges, defaultValue: HarborSystemEdges.ambient),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: null));
    properties.add(DiagnosticsProperty<HarborDefaults>('defaults', defaults, defaultValue: null));
    properties.add(
      IterableProperty<HarborFrameObserver>(
        'observers',
        observers,
        level: observers.isEmpty ? DiagnosticLevel.fine : DiagnosticLevel.info,
      ),
    );
  }
}

/// The padding the root hands its body, which is the root overlay's: a frame in an
/// `OverlayPortal`'s child compares its padding with it to see an overlay put the root's back.
class _HarborRootPadding extends InheritedWidget {
  const _HarborRootPadding({required this.padding, required super.child});

  final EdgeInsets padding;

  static Widget wrap(final EdgeInsets? padding, final Widget child) =>
      padding == null ? child : _HarborRootPadding(padding: padding, child: child);

  static EdgeInsets? maybeOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HarborRootPadding>()?.padding;

  @override
  bool updateShouldNotify(final _HarborRootPadding oldWidget) => padding != oldWidget.padding;
}
