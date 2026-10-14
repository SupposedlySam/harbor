import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'barrier_label.dart';
import 'controller.dart';
import 'hinge.dart';
import 'placement.dart';
import 'render_harbor.dart';

/// A point a buoy can be anchored to: give it to a [HarborAnchorPoint] around
/// the widget to anchor to (a button in a dock, a row in a list), and to the
/// [HarborAnchored] placement that should sit by it.
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
  /// A buoy placed by [placement] in the clear water: at a point of it ([HarborAligned], bottom
  /// centre by default) or by an anchor ([HarborAnchored]).
  const HarborBuoy({
    this.key,
    required this.child,
    final HarborPlacement? placement,
    @Deprecated(
      'Use placement: HarborAligned(alignment: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final AlignmentGeometry? alignment,
    @Deprecated(
      'Use placement: HarborAligned(margin: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final EdgeInsetsGeometry? margin,
    this.modal = false,
    this.onDismiss,
    this.barrierColor = const Color(0x00000000),
    this.requestFocus = true,
    this.barrierLabel = harborBarrierDismissLabel,
    this.within,
    this.hinge,
  }) : assert(!modal || onDismiss != null, 'A modal buoy needs onDismiss: a tap outside it and back both call it.'),
       assert(
         placement == null || (alignment == null && margin == null),
         'Give a buoy a placement, or the deprecated alignment and margin, not both.',
       ),
       _placement = placement,
       _alignment = alignment,
       _margin = margin,
       _anchor = null,
       _side = HarborAnchorSide.above,
       _gap = HarborAnchored.defaultGap,
       _overlap = 0.0,
       _crossAlignment = HarborCrossAlignment.center,
       _crossOffset = 0.0;

  /// A buoy moored to [anchor], on its [side], [gap] away, overlapping it by
  /// [overlap] (a speech bubble whose tail sits over the button), and lined up
  /// with it across that side by [crossAlignment]. Kept inside the clear water
  /// across that side, and never past its far edge.
  @Deprecated(
    'Use HarborBuoy(placement: HarborAnchored(anchor, side: HarborAnchorSide.above)); its side is below '
    'by default. `dart fix` applies it to a call; a tear-off is yours to change. Deprecated after 0.6.3.',
  )
  const HarborBuoy.anchored({
    this.key,
    // Optional and deprecated in itself, though every call gives it: `dart fix` can move a call's
    // arguments only from a diagnostic on one of them, never from the one on the constructor's name,
    // and a tear-off (which has no arguments to move) must keep compiling. So it is asserted, not typed.
    // ignore: tighten_type_of_initializing_formals
    @Deprecated(
      'Use HarborBuoy(placement: HarborAnchored(anchor, side: HarborAnchorSide.above)). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    this._anchor,
    required this.child,
    this._side = HarborAnchorSide.above,
    this._gap = HarborAnchored.defaultGap,
    this._overlap = 0.0,
    this._crossAlignment = HarborCrossAlignment.center,
    this._crossOffset = 0.0,
    EdgeInsetsGeometry this._margin = HarborAnchored.defaultMargin,
    this.modal = false,
    this.onDismiss,
    this.barrierColor = const Color(0x00000000),
    this.requestFocus = true,
    this.barrierLabel = harborBarrierDismissLabel,
    this.hinge,
  }) : assert(!modal || onDismiss != null, 'A modal buoy needs onDismiss: a tap outside it and back both call it.'),
       assert(_anchor != null, 'HarborBuoy.anchored needs an anchor.'),
       _placement = null,
       _alignment = null,
       within = null;

  final Key? key;
  final Widget child;

  // The placement given, or null when the buoy was made with the deprecated parameters, which are
  // kept below so it can be built in a const constructor.
  final HarborPlacement? _placement;
  final AlignmentGeometry? _alignment;
  final EdgeInsetsGeometry? _margin;
  final HarborAnchor? _anchor;
  final HarborAnchorSide _side;
  final double _gap;
  final double _overlap;
  final HarborCrossAlignment _crossAlignment;
  final double _crossOffset;

  /// Where the buoy sits in the clear water: at a point of it, or by an anchor. An aligned buoy at
  /// bottom centre, 16 in from the water's edges, when none is given.
  ///
  /// An anchored buoy needs an anchor, and it keeps its side: [HarborAnchored.flips] null is false
  /// here. While its anchor is not in the tree it is not shown, takes no taps and is not read out.
  HarborPlacement get placement =>
      _placement ??
      switch (_anchor) {
        final HarborAnchor anchor => HarborAnchored(
          anchor,
          side: _side,
          gap: _gap,
          overlap: _overlap,
          crossAlignment: _crossAlignment,
          crossOffset: _crossOffset,
          margin: _margin ?? HarborAnchored.defaultMargin,
        ),
        null => HarborAligned(
          alignment: _alignment ?? HarborAligned.defaultAlignment,
          margin: _margin ?? HarborAligned.defaultMargin,
        ),
      };

  /// Which hinges and folds the buoy keeps to one side of: the screen that holds its alignment
  /// point, or for an anchored buoy the screen its anchor is on. Null takes its harbor's
  /// [HarborHinge.of].
  final HarborHinge? hinge;

  /// Where an aligned buoy sits in the clear water; [Alignment.center] for an anchored one.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  AlignmentGeometry get alignment => switch (placement) {
    HarborAligned(:final AlignmentGeometry alignment) => alignment,
    HarborAnchored() => Alignment.center,
  };

  /// How far in from the clear water's edges.
  @Deprecated('Read placement.margin. Deprecated after 0.6.3.')
  EdgeInsetsGeometry get margin => placement.margin;

  /// Whether this buoy is modal while it is up (quick actions, a menu): a barrier blocks taps to
  /// the page and its docks and tells screen readers to leave the page alone, a tap outside the
  /// buoy, back and Escape all call [onDismiss], and the buoys listed before it are hidden.
  ///
  /// It is modal for the keyboard as a dialog route is: the buoy is a [FocusScope] that takes
  /// focus when it opens (see [requestFocus]), keeps Tab in a closed loop and stops arrow keys at
  /// its edges, and gives focus back to what had it when it closes.
  ///
  /// Until 0.2.0 a modal buoy only hid the buoys before it, with taps and back reaching the page.
  final bool modal;

  /// Called when a modal buoy is dismissed by a tap outside it, by back or by Escape. Required
  /// when [modal]: the buoy is yours, so you take it away.
  final VoidCallback? onDismiss;

  /// Whether a modal buoy takes focus when it opens, as [Route.requestFocus]: its scope is
  /// focused, so a child with `autofocus: true` takes it from there. With false, focus stays where
  /// it was, and Escape from the page still dismisses the buoy, though not from a page of a
  /// [Navigator] nested in the harbor's body: that page's route answers Escape first. Ignored for a
  /// buoy that is not [modal].
  final bool requestFocus;

  /// The colour of a modal buoy's barrier; clear by default, so the page shows as it is.
  final Color barrierColor;

  /// What a screen reader announces for a modal buoy's barrier, as [ModalBarrier.semanticsLabel].
  /// A Material app passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`.
  final String barrierLabel;

  /// What an anchored buoy sits by; null for an aligned one.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  HarborAnchor? get anchor => switch (placement) {
    HarborAnchored(:final HarborAnchor? anchor) => anchor,
    HarborAligned() => null,
  };

  /// Which side of its anchor an anchored buoy sits on.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  HarborAnchorSide get side => switch (placement) {
    HarborAnchored(:final HarborAnchorSide side) => side,
    HarborAligned() => HarborAnchorSide.above,
  };

  /// How far an anchored buoy sits from its anchor.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  double get gap => switch (placement) {
    HarborAnchored(:final double gap) => gap,
    HarborAligned() => 0.0,
  };

  /// How far an anchored buoy reaches back over its anchor.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  double get overlap => switch (placement) {
    HarborAnchored(:final double overlap) => overlap,
    HarborAligned() => 0.0,
  };

  /// How an anchored buoy lines up with its anchor across its side; centred by default.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  HarborCrossAlignment get crossAlignment => switch (placement) {
    HarborAnchored(:final HarborCrossAlignment crossAlignment) => crossAlignment,
    HarborAligned() => HarborCrossAlignment.center,
  };

  /// How far an anchored buoy is moved across its side from where its cross alignment puts it.
  @Deprecated('Read placement. Deprecated after 0.6.3.')
  double get crossOffset => switch (placement) {
    HarborAnchored(:final double crossOffset) => crossOffset,
    HarborAligned() => 0.0,
  };

  /// Keeps the buoy inside this rectangle (in the harbor's own coordinates)
  /// as well as inside the clear water.
  final Rect? within;

  @override
  String toStringShort() => _placement == null && _anchor != null
      ? '${objectRuntimeType(this, 'HarborBuoy')}.anchored'
      : objectRuntimeType(this, 'HarborBuoy');

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Key>('key', key, defaultValue: null));
    if (_placement != null) {
      properties.add(DiagnosticsProperty<HarborPlacement>('placement', _placement, defaultValue: const HarborAligned()));
      properties.add(DiagnosticsProperty<Rect>('within', within, defaultValue: null));
    } else if (_anchor == null) {
      // Made with the deprecated parameters: described as it was then.
      properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', _alignment, defaultValue: null));
      properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', _margin, defaultValue: null));
      properties.add(DiagnosticsProperty<Rect>('within', within, defaultValue: null));
    } else {
      properties.add(DiagnosticsProperty<HarborAnchor>('anchor', _anchor));
      properties.add(EnumProperty<HarborAnchorSide>('side', _side, defaultValue: HarborAnchorSide.above));
      properties.add(DoubleProperty('gap', _gap, defaultValue: HarborAnchored.defaultGap));
      properties.add(DoubleProperty('overlap', _overlap, defaultValue: 0.0));
      properties.add(
        DiagnosticsProperty<EdgeInsetsGeometry>('margin', _margin, defaultValue: HarborAnchored.defaultMargin),
      );
    }
    properties.add(FlagProperty('modal', value: modal, ifTrue: 'modal'));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss));
    properties.add(FlagProperty('requestFocus', value: requestFocus, ifFalse: 'does not take focus', defaultValue: true));
    properties.add(ColorProperty('barrierColor', barrierColor, defaultValue: const Color(0x00000000)));
    properties.add(StringProperty('barrierLabel', barrierLabel, defaultValue: harborBarrierDismissLabel));
  }
}

/// The layer a harbor floats its buoys in.
class HarborBuoyLayer extends StatefulWidget {
  const HarborBuoyLayer({super.key, required this.buoys, required this.flares});

  final List<HarborBuoy> buoys;
  final List<HarborFlareEntry> flares;

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
  List<HarborFlareEntry> get flares => widget.flares;

  @override
  Widget build(final BuildContext context) {
    // A flare keeps inside the clear water of the harbor that raised it, so it is placed again
    // whenever that harbor's clear water moves (a turn, a foldable opening): read only at build,
    // it stayed boxed into the shape the screen had when the flare went up.
    final List<Listenable> raisers = <Listenable>[
      for (final HarborFlareEntry flare in flares)
        if (flare.raisedIn case final HarborController harbor) harbor.clearWater,
    ];
    final HarborBuoy? modal = _modal;
    // One shape whether or not a flare or a modal buoy is up, so neither coming or going
    // remounts the buoys. PASSTHROUGH, so the layer still gets the harbor's own constraints, which
    // carry the clear water. StackFit.expand handed it plain tight ones, and a modal buoy was
    // centred in the whole frame instead of the clear water.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        // Under every buoy and over the page and its docks: taps beside a modal buoy dismiss it
        // instead of reaching the page, and the barrier blocks the page's semantics.
        if (modal != null)
          Positioned.fill(child: ModalBarrier(color: modal.barrierColor, onDismiss: modal.onDismiss, semanticsLabel: modal.barrierLabel)),
        ListenableBuilder(listenable: Listenable.merge(raisers), builder: (final BuildContext context, final Widget? _) => _build(context)),
      ],
    );
  }

  Widget _build(final BuildContext context) {
    final int lastModal = buoys.lastIndexWhere((final HarborBuoy b) => b.modal);
    assert(
      buoys.every((final HarborBuoy b) => b.placement is! HarborAnchored || (b.placement as HarborAnchored).anchor != null),
      'A HarborBuoy placed by HarborAnchored needs an anchor; only a HarborPortalBuoy anchors to its child.',
    );
    final List<HarborBuoy> all = <HarborBuoy>[
      ...buoys,
      for (final HarborFlareEntry flare in flaresInSight(flares))
        HarborBuoy(
          key: ObjectKey(flare),
          placement: flare.placement,
          hinge: flare.hinge,
          // An anchored flare goes to the port of the page that holds its anchor, so only an aligned
          // one is kept inside the clear water of the harbor that raised it.
          within: flare.placement is HarborAligned ? _local(context, flare.avoidInGlobal) : null,
          child: _Flare(entry: flare),
        ),
    ];
    return _BuoyLayout(
      buoys: all,
      // An anchored flare sits by its anchor in the clear water, so it covers no coast to reach.
      reaching: <int>{
        for (int i = 0; i < all.length; i++)
          if (all[i].child case _Flare(entry: final HarborFlareEntry entry) when entry.reachesCoast && entry.placement is HarborAligned) i,
      },
      children: <Widget>[
        for (int i = 0; i < all.length; i++)
          KeyedSubtree(
            key: all[i].key ?? ValueKey<int>(i),
            child: Visibility(
              visible: lastModal < 0 || i >= lastModal,
              maintainState: true,
              child: _ModalBuoyFocus(modal: all[i].modal, requestFocus: all[i].requestFocus, child: all[i].child),
            ),
          ),
      ],
    );
  }
}

/// A modal buoy's focus scope, as a modal route's: its own node, so focus traversal ends at its
/// edges ([FocusScopeNode]'s defaults are a dialog's: Tab loops, arrows stop). On close, the scope
/// around it falls back to the child it focused before, as a page does when a dialog pops.
///
/// Every buoy has one, so a buoy that turns modal or back keeps its child: the scope comes and goes
/// around the child, which moves under a [GlobalKey] instead of being built again.
class _ModalBuoyFocus extends StatefulWidget {
  const _ModalBuoyFocus({required this.modal, required this.requestFocus, required this.child});

  final bool modal;
  final bool requestFocus;
  final Widget child;

  @override
  State<_ModalBuoyFocus> createState() => _ModalBuoyFocusState();
}

class _ModalBuoyFocusState extends State<_ModalBuoyFocus> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'HarborBuoy (modal)');
  final GlobalKey _child = GlobalKey(debugLabel: 'HarborBuoy child');
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened) {
      _open();
    }
    _opened = true;
  }

  @override
  void didUpdateWidget(final _ModalBuoyFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.modal) {
      _open();
    }
  }

  // As a modal route takes focus: first focus in the scope around it, so the buoy has focus now if
  // that scope does, and gets it when focus comes back to that scope otherwise.
  void _open() {
    if (widget.modal && widget.requestFocus) {
      FocusScope.of(context).setFirstFocus(_scope);
    }
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Widget child = KeyedSubtree(key: _child, child: widget.child);
    return widget.modal ? FocusScope.withExternalFocusNode(focusScopeNode: _scope, child: child) : child;
  }
}

/// Escape (a [DismissIntent]) from anywhere in a harbor calls its top modal buoy's
/// [HarborBuoy.onDismiss], from focus in the buoy or on the page behind it. With no modal buoy up
/// it is left to the widgets above, as `RawMenuAnchor` leaves it while its menu is closed: a page
/// route answers Escape with an action that is disabled, which would stop the search there. For
/// the same reason, a page of a navigator nested in the harbor's body keeps Escape from reaching
/// this.
class HarborModalBuoyActions extends StatelessWidget {
  const HarborModalBuoyActions({super.key, required this.buoys, required this.child});

  final List<HarborBuoy> buoys;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final int top = buoys.lastIndexWhere((final HarborBuoy b) => b.modal);
    return Actions(
      actions: <Type, Action<Intent>>{
        if (top >= 0) DismissIntent: _DismissModalBuoyAction(buoys[top].onDismiss!),
      },
      child: child,
    );
  }
}

class _DismissModalBuoyAction extends DismissAction {
  _DismissModalBuoyAction(this._onDismiss);

  final VoidCallback _onDismiss;

  @override
  void invoke(final DismissIntent intent) => _onDismiss();
}

Rect? _local(final BuildContext context, final Rect? global) {
  if (global == null) {
    return null;
  }
  final RenderObject? box = HarborController.maybeOf(context)?.layoutBox;
  if (box is! RenderBox || !box.attached || !box.hasSize) {
    return null;
  }
  return Rect.fromPoints(box.globalToLocal(global.topLeft), box.globalToLocal(global.bottomRight));
}

class _BuoyLayout extends MultiChildRenderObjectWidget {
  const _BuoyLayout({required this.buoys, this.reaching = const <int>{}, required super.children});

  final List<HarborBuoy> buoys;

  /// The buoys (flares) that may reach over the coast, by index.
  final Set<int> reaching;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderBuoyLayer(buoys, Directionality.maybeOf(context) ?? TextDirection.ltr)
        .._features = MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[]
        .._hinge = HarborHinge.of(context)
        .._reaching = reaching;

  @override
  void updateRenderObject(final BuildContext context, final _RenderBuoyLayer renderObject) {
    renderObject
      ..buoys = buoys
      ..reaching = reaching
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr
      // Read through displayFeaturesOf alone, so the layer is not rebuilt for every other change
      // to MediaQuery.
      ..features = MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[]
      ..hinge = HarborHinge.of(context);
  }
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

  Set<int> _reaching = const <int>{};
  set reaching(final Set<int> value) {
    if (setEquals(value, _reaching)) {
      return;
    }
    _reaching = value;
    markNeedsLayout();
  }

  /// The screen's hinges, folds and cutouts, as the platform reports them.
  List<DisplayFeature> _features = const <DisplayFeature>[];
  set features(final List<DisplayFeature> value) {
    if (listEquals(value, _features)) {
      return;
    }
    _features = value;
    markNeedsLayout();
  }

  /// The harbor's policy, for the buoys with none of their own.
  HarborHinge _hinge = HarborHinge.avoidSeparating;
  set hinge(final HarborHinge value) {
    if (value != _hinge) {
      _hinge = value;
      markNeedsLayout();
    }
  }

  /// The bounds of the hinges and folds [buoy] keeps off: its own policy's, or the harbor's.
  List<Rect> _hingesFor(final HarborBuoy buoy) => HarborPlacementEngine.hingeBounds(buoy.hinge ?? _hinge, _features);

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
    final Rect open = constraints is HarborBuoyConstraints ? (constraints as HarborBuoyConstraints).openWater : _clear;
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      final HarborBuoy buoy = _buoys[i];
      final HarborPlacement placement = buoy.placement;
      final bool reaches = _reaching.contains(i);
      // An anchored buoy is laid out in the largest screen of its water, since which screen holds
      // its anchor is only known when it paints.
      final HarborWater water = HarborPlacementEngine.water(
        clear: _clear,
        open: reaches ? open : null,
        within: buoy.within,
        placement: placement,
        textDirection: _textDirection,
        hinges: _hingesFor(buoy),
      );
      final Size room = Size(math.max(0.0, water.rect.width), math.max(0.0, water.rect.height));
      child.layout(reaches ? _CoastConstraints(room, water.coastCovered) : BoxConstraints.loose(room), parentUsesSize: true);
      // Anchored buoys are placed when they paint, once their anchors have a size.
      if (placement is HarborAligned) {
        data.offset = HarborPlacementEngine.place(
          placement: placement,
          water: water.rect,
          size: child.size,
          textDirection: _textDirection,
        ).offset;
      }
      child = data.nextSibling;
      i++;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    if (_buoys.any((final HarborBuoy b) => b.placement is HarborAnchored)) {
      _follow.next(markNeedsPaint);
    }
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _BuoyParentData data = child.parentData! as _BuoyParentData;
      final HarborBuoy buoy = _buoys[i];
      final HarborPlacement placement = buoy.placement;
      final RenderBox? anchorBox = placement is HarborAnchored ? placement.anchor?.box : null;
      final bool painted = placement is HarborAligned || anchorBox != null;
      if (painted != data.painted) {
        data.painted = painted;
        markNeedsSemanticsUpdate();
      }
      if (!painted) {
        child = data.nextSibling;
        i++;
        continue;
      }
      if (placement is HarborAnchored) {
        final Rect at = MatrixUtils.transformRect(anchorBox!.getTransformTo(this), Offset.zero & anchorBox.size);
        data.offset = HarborPlacementEngine.place(
          placement: placement,
          water: HarborPlacementEngine.water(
            clear: _clear,
            within: buoy.within,
            placement: placement,
            textDirection: _textDirection,
            hinges: _hingesFor(buoy),
            holding: at.center,
          ).rect,
          size: child.size,
          textDirection: _textDirection,
          anchorRect: at,
          // A flare never flips, so its transition knows its side (HarborFlareEntry.side).
          flips: buoy.child is! _Flare && (placement.flips ?? false),
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
/// buoy floats in the nearest [Overlay] and is placed by [placement], as an
/// anchored [HarborBuoy] is, in the clear water of the harbor around this
/// widget: by the placement's anchor (or by [child] when it has none), on its
/// side, its gap away, lined up by its cross alignment, its margin in from the
/// water's edges. When that side has no room and the opposite side has, it
/// flips there (unless [HarborAnchored.flips] is false); otherwise it is kept
/// inside the clear water. [sideOf] tells the buoy which side it landed on.
///
/// With [onDismiss], it closes as a `MenuAnchor` does: a tap outside both the
/// buoy and [child], Escape while focus is in either, and back all call it.
///
/// It leaves focus where it was when it opens, as a `MenuAnchor` does, unless
/// [requestFocus] is true.
///
/// To show it in the frame it is built, call `controller.show()` before then,
/// in `initState`: an [OverlayPortalController] keeps a `show()` made before
/// its portal is attached, and the portal shows as it attaches, with no
/// post-frame callback.
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
    final HarborAnchored? placement,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, side: HarborAnchorSide.above). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final HarborAnchor? anchor,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final HarborAnchorSide? side,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, gap: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final double? gap,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, overlap: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final double? overlap,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, crossAlignment: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final HarborCrossAlignment? crossAlignment,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, crossOffset: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final double? crossOffset,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, margin: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final EdgeInsetsGeometry? margin,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, flips: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final bool? flips,
    this.onDismiss,
    this.consumeOutsideTaps = false,
    this.requestFocus = false,
    this.hinge,
  }) : assert(
         !requestFocus || onDismiss != null,
         'A HarborPortalBuoy that takes focus needs an onDismiss, so Escape can close it and a keyboard user is not left in it.',
       ),
       assert(
         placement == null ||
             (anchor == null &&
                 side == null &&
                 gap == null &&
                 overlap == null &&
                 crossAlignment == null &&
                 crossOffset == null &&
                 margin == null &&
                 flips == null),
         'Give a portal buoy a placement, or the deprecated anchor, side, gap, overlap, crossAlignment, crossOffset, '
         'margin and flips, not both.',
       ),
       _placement = placement,
       _anchor = anchor,
       _side = side,
       _gap = gap,
       _overlap = overlap,
       _crossAlignment = crossAlignment,
       _crossOffset = crossOffset,
       _margin = margin,
       _flips = flips;

  /// Shows and hides the buoy.
  final OverlayPortalController controller;

  /// Builds the buoy. Its context is this widget's, so it reads the same
  /// themes and harbor.
  final WidgetBuilder buoyBuilder;

  /// Where this widget lives in the tree, and its anchor when [placement] has none.
  final Widget child;

  // The placement given, or null when the deprecated parameters were used (or none at all).
  final HarborAnchored? _placement;
  final HarborAnchor? _anchor;
  final HarborAnchorSide? _side;
  final double? _gap;
  final double? _overlap;
  final HarborCrossAlignment? _crossAlignment;
  final double? _crossOffset;
  final EdgeInsetsGeometry? _margin;
  final bool? _flips;

  /// Where the buoy sits by its anchor. A null [HarborAnchored.anchor] anchors it to [child], and a
  /// null [HarborAnchored.flips] flips it when its side has no room.
  ///
  /// Given no placement, it sits above [child], as it did before placements: a portal buoy's side
  /// was above by default, where a [HarborAnchored]'s is below.
  HarborAnchored get placement =>
      _placement ??
      HarborAnchored(
        _anchor,
        side: _side ?? HarborAnchorSide.above,
        gap: _gap ?? HarborAnchored.defaultGap,
        overlap: _overlap ?? 0.0,
        crossAlignment: _crossAlignment ?? HarborCrossAlignment.center,
        crossOffset: _crossOffset ?? 0.0,
        flips: _flips,
        margin: _margin ?? HarborAnchored.defaultMargin,
      );

  /// What the buoy sits by. Null anchors it to [child].
  @Deprecated('Read placement.anchor. Deprecated after 0.6.3.')
  HarborAnchor? get anchor => placement.anchor;

  /// Which side of its anchor the buoy sits on before any flip.
  @Deprecated('Read placement.side. Deprecated after 0.6.3.')
  HarborAnchorSide get side => placement.side;

  /// How far the buoy sits from its anchor.
  @Deprecated('Read placement.gap. Deprecated after 0.6.3.')
  double get gap => placement.gap;

  /// How far the buoy reaches back over its anchor.
  @Deprecated('Read placement.overlap. Deprecated after 0.6.3.')
  double get overlap => placement.overlap;

  /// How the buoy lines up with its anchor across its side; centred by default.
  @Deprecated('Read placement.crossAlignment. Deprecated after 0.6.3.')
  HarborCrossAlignment get crossAlignment => placement.crossAlignment;

  /// How far the buoy is moved across its side from where its cross alignment puts it.
  @Deprecated('Read placement.crossOffset. Deprecated after 0.6.3.')
  double get crossOffset => placement.crossOffset;

  /// How far in from the clear water's edges.
  @Deprecated('Read placement.margin. Deprecated after 0.6.3.')
  EdgeInsetsGeometry get margin => placement.margin;

  /// Whether the buoy goes to the opposite side of its anchor when its side has no room and that
  /// side has.
  @Deprecated('Read placement.flips. Deprecated after 0.6.3.')
  bool get flips => placement.flips ?? true;

  /// Called while the buoy is shown when a tap lands outside both the buoy and [child] (a
  /// [TapRegion] group, as a `MenuAnchor`'s), when Escape is pressed with focus in either, and on
  /// back, before back reaches the page. Hide the buoy in it. Null leaves the buoy up until
  /// [controller] hides it.
  final VoidCallback? onDismiss;

  /// Whether a tap outside that calls [onDismiss] stops there, as
  /// [RawMenuAnchor.consumeOutsideTaps]: true for a menu whose closing tap must not also press
  /// what is under it. By default the tap goes on, as it does for a `MenuAnchor`.
  final bool consumeOutsideTaps;

  /// Which hinges and folds the buoy keeps to one side of: the screen that holds its anchor, as
  /// a Material menu keeps to the screen of its button. Null takes the page's [HarborHinge.of].
  final HarborHinge? hinge;

  /// Whether the buoy takes keyboard focus when it opens, as a sheet with no barrier does with
  /// `requestFocus: true`. False by default, which leaves focus where it was, as a `MenuAnchor`
  /// does.
  ///
  /// With true, the buoy is a [FocusScope] of its own that becomes the first focus of the scope
  /// around [child] (the page's, or a modal buoy's or dialog's), so it has focus now if that scope
  /// does, and a control in it with `autofocus: true` takes it from there. A portal buoy is not
  /// modal, so Tab past its last control does what it does at a route's edge (the navigator's
  /// `routeTraversalEdgeBehavior`) rather than going round inside it. When it closes, focus goes
  /// back to what the scope around it had focused before, but only if focus is still in the buoy.
  /// Escape from focus in it still calls [onDismiss], which it requires.
  final bool requestFocus;

  /// The side of its anchor the portal buoy around [context] landed on: its placement's side, or the
  /// opposite one after it flipped. A popover reads it to point its arrow at the anchor. It is
  /// placed when it paints, so after a flip this changes on the next frame.
  static HarborAnchorSide sideOf(final BuildContext context) {
    final HarborAnchorSide? side = maybeSideOf(context);
    assert(side != null, 'HarborPortalBuoy.sideOf was called from outside a portal buoy\'s buoyBuilder.');
    return side!;
  }

  /// [sideOf], or null outside a portal buoy.
  static HarborAnchorSide? maybeSideOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PortalBuoySide>()?.side;

  @override
  State<HarborPortalBuoy> createState() => _HarborPortalBuoyState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<OverlayPortalController>('controller', controller));
    if (_placement case final HarborAnchored placement) {
      properties.add(DiagnosticsProperty<HarborAnchored>('placement', placement));
    } else {
      // Made with the deprecated parameters, or none: described as it was then.
      properties.add(DiagnosticsProperty<HarborAnchor>('anchor', _anchor, defaultValue: null));
      properties.add(EnumProperty<HarborAnchorSide>('side', _side, defaultValue: null));
      properties.add(DoubleProperty('gap', _gap, defaultValue: null));
      properties.add(DoubleProperty('overlap', _overlap, defaultValue: null));
      properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', _margin, defaultValue: null));
      properties.add(FlagProperty('flips', value: _flips ?? true, ifFalse: 'no flip'));
    }
    properties.add(FlagProperty('requestFocus', value: requestFocus, ifTrue: 'requests focus'));
  }
}

class _HarborPortalBuoyState extends State<HarborPortalBuoy> {
  HarborAnchor? _own;
  late final ValueNotifier<HarborAnchorSide> _landed = ValueNotifier<HarborAnchorSide>(widget.placement.side);
  late final _DismissPortalBuoyAction _dismissAction = _DismissPortalBuoyAction(this);
  bool _shown = false;

  HarborAnchor get _anchor => widget.placement.anchor ?? (_own ??= HarborAnchor(debugLabel: 'HarborPortalBuoy'));

  void _dismiss() => widget.onDismiss?.call();

  // The buoy's focus scope while it is shown with requestFocus. Held here rather than in the
  // overlay child, which the controller's hide() unmounts; a new one each time it opens, as a sheet
  // has one per opening.
  FocusScopeNode? _focus;

  FocusScopeNode _focusWhileShown() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    return _focus ??= FocusScopeNode(debugLabel: 'HarborPortalBuoy')
      ..traversalEdgeBehavior = navigator?.widget.routeTraversalEdgeBehavior ?? kDefaultRouteTraversalEdgeBehavior
      ..directionalTraversalEdgeBehavior =
          navigator?.widget.routeDirectionalTraversalEdgeBehavior ?? kDefaultRouteDirectionalTraversalEdgeBehavior;
  }

  // As the buoy goes: focus back to what the scope around it had before, only if focus is still in
  // the buoy, and the node disposed after the frame, once its FocusScope has left the tree. Disposed
  // at once, focus stayed on the disposed node and Escape reached nothing (#42, for sheets).
  void _focusLeft(final FocusScopeNode scope) {
    if (scope.hasFocus) {
      scope.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
    if (identical(_focus, scope)) {
      _focus = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      // Unless the buoy came straight back with it, moved in the same frame.
      if (!identical(_focus, scope)) {
        scope.dispose();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _focusCameBack(final FocusScopeNode scope) => _focus ??= scope;

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
    final Widget anchored = widget.placement.anchor == null ? HarborAnchorPoint(anchor: _anchor, child: widget.child) : widget.child;
    final Widget portal = OverlayPortal(
      controller: widget.controller,
      overlayChildBuilder: (final BuildContext context) {
        Widget buoy = ValueListenableBuilder<HarborAnchorSide>(
          valueListenable: _landed,
          builder: (final BuildContext context, final HarborAnchorSide side, final Widget? child) => _PortalBuoySide(side: side, child: child!),
          // A Builder, so the builder's own context is below the side it reads.
          child: Builder(builder: widget.buoyBuilder),
        );
        if (widget.requestFocus) {
          buoy = _PortalBuoyFocus(scope: _focusWhileShown(), onLeft: _focusLeft, onCameBack: _focusCameBack, child: buoy);
        }
        buoy = _PortalBuoyDismissal(
          controller: widget.controller,
          groupId: this,
          consumeOutsideTaps: widget.consumeOutsideTaps,
          onDismiss: dismissible ? _dismiss : null,
          onCameOrWent: _buoyCameOrWent,
          child: buoy,
        );
        return _PlacedLayout(
          harbor: HarborController.maybeOf(context),
          hinges: HarborPlacementEngine.hingeBounds(
            widget.hinge ?? HarborHinge.of(this.context),
            MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[],
          ),
          placement: widget.placement,
          anchor: _anchor,
          flips: widget.placement.flips ?? true,
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

/// Takes focus for a portal buoy with `requestFocus` as it opens, as a sheet with no barrier does:
/// its scope becomes the first focus of the scope around the portal buoy. As the buoy goes, it tells
/// the portal buoy before its descendants leave, so focus is handed back while the buoy's controls
/// still hold it.
class _PortalBuoyFocus extends StatefulWidget {
  const _PortalBuoyFocus({required this.scope, required this.onLeft, required this.onCameBack, required this.child});

  final FocusScopeNode scope;
  final ValueChanged<FocusScopeNode> onLeft;
  final ValueChanged<FocusScopeNode> onCameBack;
  final Widget child;

  @override
  State<_PortalBuoyFocus> createState() => _PortalBuoyFocusState();
}

class _PortalBuoyFocusState extends State<_PortalBuoyFocus> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened) {
      FocusScope.of(context).setFirstFocus(widget.scope);
    }
    _opened = true;
  }

  @override
  void deactivate() {
    widget.onLeft(widget.scope);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    widget.onCameBack(widget.scope);
  }

  @override
  Widget build(final BuildContext context) => FocusScope.withExternalFocusNode(focusScopeNode: widget.scope, child: widget.child);
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

  final HarborAnchorSide side;

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

/// Places one overlay in the water of the box it fills: a portal buoy by its anchor in the clear
/// water of the harbor around it, or a flare with no harbor above it in the water its overlay's
/// padding and keyboard leave.
class _PlacedLayout extends SingleChildRenderObjectWidget {
  const _PlacedLayout({
    this.harbor,
    this.covered = EdgeInsets.zero,
    this.keyboard,
    this.hinges = const <Rect>[],
    required this.placement,
    this.anchor,
    this.flips = false,
    required this.textDirection,
    this.landed,
    super.child,
  }) : assert(keyboard == null || placement is HarborAligned, 'Only an aligned overlay reaches over the coast.'),
       assert(harbor == null || placement is HarborAnchored, 'An aligned overlay in a harbor is placed by its buoy layer.'),
       assert(placement is HarborAligned || anchor != null, 'An anchored overlay needs its anchor.');

  /// The harbor whose clear water the overlay keeps to; with none, the box less [covered].
  final HarborController? harbor;

  /// What covers each edge of the box when there is no [harbor]: the larger of the padding and
  /// the keyboard.
  final EdgeInsets covered;

  /// The keyboard, for an aligned overlay that reaches over the coast: its water is the box less
  /// this alone. Null for one that does not.
  final EdgeInsets? keyboard;

  /// The hinges and folds the overlay keeps off, in the box's coordinates.
  final List<Rect> hinges;
  final HarborPlacement placement;

  /// The anchor an anchored overlay sits by: its placement's, or a portal buoy's own around its child.
  final HarborAnchor? anchor;

  /// Whether an anchored overlay goes to the opposite side when its own has no room.
  final bool flips;
  final TextDirection textDirection;

  /// Told the side an anchored overlay landed on, the frame after it changes.
  final ValueNotifier<HarborAnchorSide>? landed;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderPlaced(this);

  @override
  void updateRenderObject(final BuildContext context, final _RenderPlaced renderObject) {
    renderObject.config = this;
  }
}

/// Fills its box and places its child: an aligned one as it lays out, an anchored one when it
/// paints, once the harbor's clear water and the anchor are laid out for this frame.
class _RenderPlaced extends RenderShiftedBox {
  _RenderPlaced(this._config) : super(null);

  _PlacedLayout _config;
  set config(final _PlacedLayout value) {
    final _PlacedLayout old = _config;
    _config = value;
    if (attached) {
      _unlisten(old);
      _listen(value);
    }
    markNeedsLayout();
  }

  bool _placed = false;

  void _listen(final _PlacedLayout c) {
    c.harbor?.clearWater.addListener(markNeedsLayout);
  }

  void _unlisten(final _PlacedLayout c) {
    c.harbor?.clearWater.removeListener(markNeedsLayout);
  }

  // Its own layer, since an anchored one is painted again every frame.
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

  /// The harbor's clear water in this box's coordinates, or the box less what covers it when there
  /// is no harbor.
  Rect _clearWater() {
    final HarborController? harbor = _config.harbor;
    final RenderBox? box = harbor?.layoutBox;
    final HarborLayoutRecord? layout = harbor?.layoutRecord;
    return box == null || layout == null || !box.attached || !box.hasSize
        ? _config.covered.deflateRect(Offset.zero & size)
        : MatrixUtils.transformRect(box.getTransformTo(this), layout.clearWater);
  }

  @override
  Size computeDryLayout(final BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    // Only the harbor's water's size is known while laying out: its last one. A change to it lays
    // the overlay out again.
    final EdgeInsets? keyboard = _config.keyboard;
    final HarborWater water = HarborPlacementEngine.water(
      clear: _config.harbor?.layoutRecord?.clearWater ?? _config.covered.deflateRect(Offset.zero & size),
      open: keyboard?.deflateRect(Offset.zero & size),
      placement: _config.placement,
      textDirection: _config.textDirection,
      hinges: _config.hinges,
    );
    final Size room = Size(math.max(0.0, water.rect.width), math.max(0.0, water.rect.height));
    child.layout(keyboard != null ? _CoastConstraints(room, water.coastCovered) : BoxConstraints.loose(room), parentUsesSize: true);
    if (_config.placement is HarborAligned) {
      (child.parentData! as BoxParentData).offset = HarborPlacementEngine.place(
        placement: _config.placement,
        water: water.rect,
        size: child.size,
        textDirection: _config.textDirection,
      ).offset;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    final HarborPlacement placement = _config.placement;
    if (placement is HarborAligned) {
      _setPlaced(child != null);
      if (child != null) {
        context.paintChild(child, (child.parentData! as BoxParentData).offset + offset);
      }
      return;
    }
    _follow.next(markNeedsPaint);
    final RenderBox? anchorBox = _config.anchor?.box;
    _setPlaced(child != null && anchorBox != null);
    if (!_placed) {
      return;
    }
    final BoxParentData data = child!.parentData! as BoxParentData;
    final Offset was = data.offset;
    final Rect at = MatrixUtils.transformRect(anchorBox!.getTransformTo(this), Offset.zero & anchorBox.size);
    final HarborLanding landed = HarborPlacementEngine.place(
      placement: placement,
      water: HarborPlacementEngine.water(
        clear: _clearWater(),
        placement: placement,
        textDirection: _config.textDirection,
        hinges: _config.hinges,
        holding: at.center,
      ).rect,
      size: child.size,
      textDirection: _config.textDirection,
      anchorRect: at,
      flips: _config.flips,
    );
    data.offset = landed.offset;
    _report(landed.side!);
    // Layout refreshes semantics, but the overlay is placed here, after it, so a move refreshes them too.
    if (data.offset != was) {
      markNeedsSemanticsUpdate();
    }
    context.paintChild(child, data.offset + offset);
  }

  void _setPlaced(final bool placed) {
    if (placed != _placed) {
      _placed = placed;
      markNeedsSemanticsUpdate();
    }
  }

  HarborAnchorSide? _reporting;

  // The side is only known here, and nothing may be rebuilt while painting, so the buoy hears it
  // the frame after, as an anchor reports that it moved.
  void _report(final HarborAnchorSide side) {
    final ValueNotifier<HarborAnchorSide>? landed = _config.landed;
    if (landed == null || side == (_reporting ?? landed.value)) {
      return;
    }
    final bool scheduled = _reporting != null;
    _reporting = side;
    if (scheduled) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      final HarborAnchorSide? reported = _reporting;
      _reporting = null;
      if (reported != null && attached) {
        _config.landed?.value = reported;
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

/// Where a flare is raised within the clear water of its harbor.
enum HarborFlareSlot {
  top(Alignment.topCenter),
  high(Alignment(0.0, -0.55)),
  middle(Alignment.center),
  low(Alignment.bottomCenter);

  const HarborFlareSlot(this.alignment);

  final Alignment alignment;
}

/// Which harbor a flare goes to.
enum HarborFlareTarget {
  /// The port on top right now (a sheet over a page over the sea), so a low
  /// flare clears that sheet's footer.
  topmost,

  /// The outermost harbor, so the flare clears only the coast.
  sea,
}

/// Transient buoys: messages raised in a harbor's clear water for a while.
///
/// See also:
///
///  * `SnackBar` and `ScaffoldMessenger.showSnackBar`, which queue their messages one at a time;
///    flares queue per slot, so flares at different slots show together.
abstract final class HarborFlares {
  /// Raises [builder]'s flare in [target]'s clear water at [slot], lowered
  /// after [duration] (or when the returned entry is lowered). If its harbor
  /// leaves (the page is popped), the flare moves to the port now on top.
  ///
  /// Flares at the same slot or alignment take turns, as a
  /// `ScaffoldMessenger` shows its snack bars one at a time: each comes in once
  /// the one before it has left. To replace the flare that is up, lower it.
  /// [HarborFlareEntry.closed] completes once a flare has left, with why.
  ///
  /// [duration] (4 s, a `SnackBar`'s) counts only while the flare is in
  /// sight, unless [countsWhileCovered] keeps it running under a covering
  /// route: from the end of its entrance (from its start with
  /// [countsEntrance], so the flare is on screen that long, entrance
  /// included), and not while another route covers its page. Set
  /// [HarborFlareEntry.duration] to change it once the flare is up. With [persist] the flare stays until it is lowered, as a
  /// `SnackBar` with `persist` does; give it to a flare with a button, so a
  /// screen-reader user has time to reach it.
  ///
  /// [placement] places the flare instead of a slot: at an exact point of the
  /// clear water ([HarborAligned]), as an aligned [HarborBuoy] is placed, or by
  /// a [HarborAnchorPoint] ([HarborAnchored]). Give a slot or a placement, or
  /// neither for [HarborFlareSlot.high]. An [AlignmentDirectional] or an
  /// [EdgeInsetsDirectional] is resolved in the reading direction of
  /// [context], the page that raised it, whose themes the flare also keeps.
  ///
  /// An anchored flare sits on its side of the anchor (below by default), its
  /// gap away, lined up by its cross alignment, and kept inside the clear
  /// water; it never flips, so its transition knows its side. Raise it from
  /// the page that holds the anchor: an anchored flare is shown by that page's
  /// port rather than the one on top ([target] is not read), so it never sits
  /// over a sheet or dialog by an anchor beneath it. Flares at one anchor and
  /// side take turns. While the anchor is out of the tree the flare is not
  /// shown, takes no taps and is not read out, and its time stops. If its page
  /// is popped, it is lowered with [HarborFlareClosedReason.remove] rather than
  /// moving to the port now on top.
  ///
  /// The flare fades and scales in and out over [animationStyle] (220 ms each
  /// way by default). [AnimationStyle.noAnimation] shows it as it is, for a
  /// widget that brings its own entrance; [transitionBuilder] builds your own
  /// entrance and exit from harbor's animation instead. Either way a lowered
  /// flare stays at least 300 ms, so the widget's own exit can run. With
  /// reduced motion it appears and leaves at once.
  ///
  /// With [reachesCoast], the flare may reach over the coast on the edges it is
  /// against, as a fixed `SnackBar` runs under the home indicator: its water is
  /// the frame less the docks and the keyboard, not less the coast too, and its
  /// content is handed the coast it covers as `MediaQuery.padding` to keep its
  /// text clear. It is against the sides always, and against the top or bottom
  /// when it is placed there ([HarborFlareSlot.top], [HarborFlareSlot.low], or
  /// an alignment at that edge). Give it a [HarborAligned] with
  /// `margin: EdgeInsets.zero` to run edge to edge. It is for an aligned flare
  /// only: an anchored flare sits by its anchor, clear of the coast.
  ///
  /// [queue] is what it does when a flare is already up at its place: wait its
  /// turn ([HarborFlareQueue.wait]) or take it at once
  /// ([HarborFlareQueue.replace]), lowering the one up. A [HarborFlarePolicy]
  /// above [context] sets it for a subtree; [HarborFlareQueue.wait] with none.
  ///
  /// A placement's margin is how far the flare keeps in from the clear water's
  /// edges: 16 at a slot or an alignment and 8 by an anchor unless it says.
  /// [EdgeInsets.zero] lets it reach them, for a bar the width of the screen
  /// (a fixed `SnackBar`'s look). It stays in the clear water either way, off
  /// the coast and the docks. [HarborFlareEntry.hold] stops its time while it
  /// is held.
  ///
  /// The flare is a live region with a dismiss action, so a screen reader
  /// announces it and can lower it, as it does a `SnackBar`. Give
  /// [liveRegion] false when [builder]'s widget is its own live region: harbor
  /// then adds no semantics, and the widget's node is the only one announced.
  ///
  /// With no harbor above [context] (a bare `MaterialApp` in a widget test, a
  /// screen not yet built from a harbor), the flare goes to the nearest
  /// [Overlay], kept clear of `MediaQuery.padding` and `viewInsets`. With no
  /// overlay either, it is reported through [FlutterError.reportError] and
  /// returned already lowered. An anchored flare in an overlay is placed by its
  /// anchor in the same water.
  static HarborFlareEntry raise(
    final BuildContext context, {
    required final WidgetBuilder builder,
    final HarborFlareSlot? slot,
    final HarborPlacement? placement,
    @Deprecated(
      'Use placement: HarborAligned(alignment: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final AlignmentGeometry? alignment,
    final Duration? duration = const Duration(seconds: 4),
    final bool persist = false,
    final HarborFlareTarget target = HarborFlareTarget.topmost,
    final AnimationStyle? animationStyle,
    final HarborFlareTransitionBuilder? transitionBuilder,
    final bool liveRegion = true,
    @Deprecated(
      'Use placement: HarborAnchored(anchor). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final HarborAnchor? anchor,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, side: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final HarborAnchorSide? side,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, gap: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final double? gap,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, crossAlignment: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final HarborCrossAlignment? crossAlignment,
    @Deprecated(
      'Use placement: HarborAligned(margin: ...), or HarborAnchored(anchor, margin: ...). `dart fix` applies it. '
      'Deprecated after 0.6.3.',
    )
    final EdgeInsetsGeometry? margin,
    final bool countsEntrance = false,
    final bool reachesCoast = false,
    final HarborHinge? hinge,
    final bool countsWhileCovered = false,
    final HarborFlareQueue? queue,
  }) {
    assert(slot == null || alignment == null, 'Give a flare a slot or an alignment, not both.');
    assert(anchor == null || (slot == null && alignment == null), 'Give an anchored flare its anchor alone, without a slot or an alignment.');
    assert(
      placement == null || (slot == null && alignment == null && anchor == null && side == null && gap == null && crossAlignment == null && margin == null),
      'Give a flare a slot or a placement, not both, and not with the deprecated alignment, anchor, side, gap, '
      'crossAlignment or margin.',
    );
    assert(placement is! HarborAnchored || placement.anchor != null, 'An anchored flare needs an anchor.');
    assert(
      placement is! HarborAnchored || placement.flips != true,
      'A flare never flips: its transition is built for the side it was raised on. Leave flips null.',
    );
    // The deprecated anchor with reachesCoast stays as it was since 0.6.3, a no-op; spelled as a
    // placement it is a mistake.
    assert(!reachesCoast || placement is! HarborAnchored, 'reachesCoast is for an aligned flare: an anchored one sits by its anchor, clear of the coast.');
    final TextDirection textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    // Resolved where it is raised: the page that raised it decides its reading direction, wherever
    // it is shown.
    final HarborPlacement placed = switch (placement ??
        (anchor != null
            ? HarborAnchored(
                anchor,
                side: side ?? HarborAnchorSide.below,
                gap: gap ?? HarborAnchored.defaultGap,
                crossAlignment: crossAlignment ?? HarborCrossAlignment.center,
                margin: margin ?? HarborAnchored.defaultMargin,
              )
            : HarborAligned(
                alignment: alignment ?? (slot ?? HarborFlareSlot.high).alignment,
                margin: margin ?? HarborAligned.defaultMargin,
              ))) {
      HarborAligned(:final AlignmentGeometry alignment, :final EdgeInsetsGeometry margin) => HarborAligned(
        alignment: alignment.resolve(textDirection),
        margin: margin.resolve(textDirection),
      ),
      final HarborAnchored anchored => HarborAnchored(
        anchored.anchor,
        side: anchored.side,
        gap: anchored.gap,
        overlap: anchored.overlap,
        crossAlignment: anchored.crossAlignment,
        crossOffset: anchored.crossOffset,
        flips: anchored.flips,
        margin: anchored.margin.resolve(textDirection),
      ),
    };
    final HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    // A flare is built in its harbor's buoy layer, not where it was raised, so it takes the
    // themes and text style of the place that raised it, as a sheet does. Without this a page
    // that wraps itself in its own Theme raised a toast in the app's theme.
    final CapturedThemes themes = InheritedTheme.capture(from: context, to: null);
    final HarborFlareEntry entry = HarborFlareEntry(
      // A Builder, so the builder's own context sees the captured themes, not only what it returns.
      builder: (final BuildContext _) => themes.wrap(Builder(builder: builder)),
      placement: placed,
      duration: duration,
      persist: persist,
      // Sent to the sea, a flare clears only the coast.
      avoidInGlobal: target == HarborFlareTarget.topmost ? HarborController.maybeOf(context)?.clearWaterInGlobal() : null,
      raisedIn: target == HarborFlareTarget.topmost ? HarborController.maybeOf(context) : null,
      animationStyle: animationStyle,
      transitionBuilder: transitionBuilder,
      liveRegion: liveRegion,
      countsEntrance: countsEntrance,
      reachesCoast: reachesCoast,
      // Read where it is raised: the page that raised it decides, wherever it is shown.
      hinge: hinge ?? HarborHinge.of(context),
      countsWhileCovered: countsWhileCovered,
      queue: queue ?? HarborFlarePolicy.queueOf(context),
    );
    final HarborController? controller = placed is HarborAnchored
        ? _portOf(HarborController.maybeOf(context))
        : switch (target) {
            HarborFlareTarget.topmost => fleet?.topmost,
            HarborFlareTarget.sea => fleet?.sea,
          } ?? HarborController.maybeOf(context);
    if (controller != null) {
      controller.raiseFlare(entry);
    } else if (Overlay.maybeOf(context) case final OverlayState overlay) {
      (_overlayQueues[overlay] ??= _OverlayQueue(overlay)).raise(entry);
    } else {
      entry.lower(reason: HarborFlareClosedReason.remove);
      flareLeft(entry);
      FlutterError.reportError(FlutterErrorDetails(
        exception: FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('HarborFlares.raise found no Harbor, HarborSea or Overlay above the context, so the flare was not shown.'),
          ErrorHint('Mount a HarborSea in MaterialApp.builder, or raise the flare from a context inside a Navigator.'),
        ]),
        library: 'harbor',
      ));
      return entry;
    }
    return entry;
  }

  /// The port [harbor] is in: the first harbor of its route, or of its sheet over the sea.
  static HarborController? _portOf(final HarborController? harbor) {
    HarborController? port = harbor;
    while (port != null && !port.isRouteLevel) {
      port = port.parent;
    }
    return port ?? harbor;
  }

  static final Expando<_OverlayQueue> _overlayQueues = Expando<_OverlayQueue>();
}

/// The flares raised into one overlay, which take turns at each alignment as
/// they do in a harbor.
class _OverlayQueue {
  _OverlayQueue(this.overlay);

  final OverlayState overlay;
  final List<HarborFlareEntry> _flares = <HarborFlareEntry>[];
  final Map<HarborFlareEntry, OverlayEntry> _hosts = <HarborFlareEntry, OverlayEntry>{};

  /// The flares whose host has been built: those run their exit before they leave.
  final Set<HarborFlareEntry> _built = <HarborFlareEntry>{};

  void raise(final HarborFlareEntry entry) {
    queueFlare(_flares, entry);
    void lowered() {
      if (entry.showing.value) {
        return;
      }
      final OverlayEntry? host = _hosts[entry];
      if (host == null) {
        // Lowered while it waited its turn: it has no exit to run.
        entry.showing.removeListener(lowered);
        _flares.remove(entry);
        flareLeft(entry);
      } else if (!_built.contains(entry) && SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
        // Lowered before its host was ever built (raised and dismissed in one callback): there is
        // nothing to run an exit for, so the host goes now. Left in, it was built with the flare
        // already down, never heard it go, and held the slot so every later flare queued behind it.
        entry.showing.removeListener(lowered);
        host
          ..remove()
          ..dispose();
        left(entry);
      } else {
        entry.showing.removeListener(lowered);
      }
    }

    entry.showing.addListener(lowered);
    _insertInSight();
  }

  void _insertInSight() {
    for (final HarborFlareEntry entry in flaresInSight(_flares)) {
      if (!_hosts.containsKey(entry)) {
        late final OverlayEntry host;
        host = OverlayEntry(builder: (final BuildContext _) => _OverlayFlare(entry: entry, host: host, queue: this));
        _hosts[entry] = host;
        overlay.insert(host);
      }
    }
  }

  /// [entry] has run its exit and left the overlay: the next at its place comes in.
  void left(final HarborFlareEntry entry) {
    _forget(entry);
    _insertInSight();
  }

  /// The overlay went away under [entry], so the flares waiting behind it have
  /// nothing left to show them either.
  void gone(final HarborFlareEntry entry) {
    _forget(entry);
    for (final HarborFlareEntry waiting in List<HarborFlareEntry>.of(_flares)) {
      if (!_hosts.containsKey(waiting)) {
        waiting.lower(reason: HarborFlareClosedReason.remove);
      }
    }
  }

  void _forget(final HarborFlareEntry entry) {
    _flares.remove(entry);
    _hosts.remove(entry);
    _built.remove(entry);
    flareLeft(entry);
  }
}

/// A flare raised where there is no harbor: in an overlay, at its slot in the
/// water the overlay's padding and keyboard leave.
class _OverlayFlare extends StatefulWidget {
  const _OverlayFlare({required this.entry, required this.host, required this.queue});

  final HarborFlareEntry entry;
  final OverlayEntry host;
  final _OverlayQueue queue;

  @override
  State<_OverlayFlare> createState() => _OverlayFlareState();
}

class _OverlayFlareState extends State<_OverlayFlare> {
  Timer? _removal;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    widget.queue._built.add(widget.entry);
    widget.entry.showing.addListener(_changed);
    // Lowered during the build that inserted it, so it never hears the change: it leaves now.
    _changed();
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      // Leave time for the flare's own exit animation.
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
      // The overlay went away with the flare still up: nothing is left to show it.
      widget.entry.lower(reason: HarborFlareClosedReason.remove);
      widget.queue.gone(widget.entry);
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final HarborFlareEntry entry = widget.entry;
    final HarborPlacement placement = entry.placement;
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets keyboard = MediaQuery.viewInsetsOf(context);
    // Placed as a buoy is, in the overlay less its padding and keyboard: both are measured from the
    // screen's edges, so the larger one on each edge is what is covered. Reaching the coast, only
    // the keyboard covers it.
    return _PlacedLayout(
      covered: EdgeInsets.fromLTRB(
        math.max(padding.left, keyboard.left),
        math.max(padding.top, keyboard.top),
        math.max(padding.right, keyboard.right),
        math.max(padding.bottom, keyboard.bottom),
      ),
      keyboard: entry.reachesCoast && placement is HarborAligned ? keyboard : null,
      hinges: HarborPlacementEngine.hingeBounds(
        entry.hinge ?? HarborHinge.of(context),
        MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[],
      ),
      placement: placement,
      anchor: entry.anchor,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: _Flare(entry: entry),
    );
  }
}

class _Flare extends StatefulWidget {
  const _Flare({required this.entry});

  final HarborFlareEntry entry;

  @override
  State<_Flare> createState() => _FlareState();
}

class _FlareState extends State<_Flare> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.entry.animationStyle?.curve ?? Curves.linear,
    reverseCurve: widget.entry.animationStyle?.reverseCurve,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0).animate(_animation);

  Timer? _timeout;
  bool _inSight = true;

  /// Whether the flare's anchor is in the tree; always for a flare with none.
  bool _anchored = true;

  void _anchorMoved() {
    final bool anchored = widget.entry.anchor?.box != null;
    if (anchored != _anchored) {
      _anchored = anchored;
      _syncTimeout();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    _controller
      ..duration = reducedMotion ? Duration.zero : widget.entry.transitionDuration
      ..reverseDuration = reducedMotion ? Duration.zero : widget.entry.reverseTransitionDuration;
    // As a ScaffoldMessenger starts a snack bar's timer only while its route is current: a page
    // covered by another route, or kept offstage with its tickers stopped, shows nobody the flare.
    _inSight = (ModalRoute.isCurrentOf(context) ?? true) && TickerMode.valuesOf(context).enabled;
    if (_controller.isDismissed && widget.entry.showing.value) {
      _controller.forward();
    }
    _syncTimeout();
  }

  @override
  void initState() {
    super.initState();
    flareShown(widget.entry);
    widget.entry.showing.addListener(_changed);
    widget.entry.held.addListener(_syncTimeout);
    widget.entry.timing.addListener(_restartTimeout);
    _controller.addStatusListener(_statusChanged);
    if (widget.entry.anchor case final HarborAnchor anchor) {
      anchor.addListener(_anchorMoved);
      _anchored = anchor.box != null;
    }
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      _controller.reverse();
    }
    _syncTimeout();
  }

  void _statusChanged(final AnimationStatus _) => _syncTimeout();

  /// The duration was set: the time starts over with it.
  void _restartTimeout() {
    _timeout?.cancel();
    _timeout = null;
    _syncTimeout();
  }

  /// Runs the flare's time while it is fully in and in sight, and starts it over when it comes back.
  void _syncTimeout() {
    final HarborFlareEntry entry = widget.entry;
    final Duration? duration = entry.duration;
    final bool running =
        duration != null &&
        !entry.persist &&
        !entry.held.value &&
        entry.showing.value &&
        (entry.countsEntrance ? !_controller.isDismissed : _controller.isCompleted) &&
        (_inSight || entry.countsWhileCovered) &&
        _anchored;
    if (running && _timeout == null) {
      _timeout = Timer(duration, () => entry.lower(reason: HarborFlareClosedReason.timeout));
    } else if (!running) {
      _timeout?.cancel();
      _timeout = null;
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    widget.entry.showing.removeListener(_changed);
    widget.entry.held.removeListener(_syncTimeout);
    widget.entry.timing.removeListener(_restartTimeout);
    widget.entry.anchor?.removeListener(_anchorMoved);
    _controller.removeStatusListener(_statusChanged);
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _still => widget.entry.transitionDuration == Duration.zero && widget.entry.reverseTransitionDuration == Duration.zero;

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final MediaQueryData screen = _screenOf(context, media);
    return identical(screen, media) ? _content(context) : MediaQuery(data: screen, child: Builder(builder: _content));
  }

  /// [media] cut down to the one screen an aligned flare keeps to when a hinge its policy keeps off
  /// splits the screen, as `DisplayFeatureSubScreen` cuts it for a dialog: the padding of the other
  /// screen and the hinge itself are not its content's to clear. An anchored flare's screen is known
  /// only as it paints, so it reads [media] as it is.
  MediaQueryData _screenOf(final BuildContext context, final MediaQueryData media) {
    final HarborFlareEntry entry = widget.entry;
    if (entry.placement is! HarborAligned) {
      return media;
    }
    final List<Rect> hinges = HarborPlacementEngine.hingeBounds(entry.hinge ?? HarborHinge.of(context), media.displayFeatures);
    if (hinges.isEmpty) {
      return media;
    }
    final Rect whole = Offset.zero & media.size;
    final Rect screen = HarborPlacementEngine.screen(
      water: whole,
      placement: entry.placement,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      hinges: hinges,
    );
    return screen == whole ? media : media.removeDisplayFeatures(screen);
  }

  Widget _content(final BuildContext context) {
    final HarborFlareEntry entry = widget.entry;
    if (!entry.reachesCoast) {
      return _build(context);
    }
    // The coast the flare covers is known only once its layer has placed it, so it is read from
    // the constraints that layer hands it, and given to the content as its padding.
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        if (constraints is! _CoastConstraints) {
          return _build(context);
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: constraints.coast, viewPadding: constraints.coast),
          child: Builder(builder: _build),
        );
      },
    );
  }

  // The flare's entry is in scope for its builder and its transition, so either can read where
  // it hangs (HarborFlareEntry.maybeOf) or take a hold on it.
  Widget _build(final BuildContext context) => HarborFlareScope(entry: widget.entry, child: Builder(builder: _buildInScope));

  Widget _buildInScope(final BuildContext context) {
    final HarborFlareEntry entry = widget.entry;
    final Widget child = entry.builder(context);
    final Widget shown = switch (entry.transitionBuilder) {
      final HarborFlareTransitionBuilder transition => transition(context, _animation, child),
      // Shown as it is, so a widget with its own entrance doesn't play two.
      null when _still => child,
      null => FadeTransition(opacity: _animation, child: ScaleTransition(scale: _scale, child: child)),
    };
    if (!entry.liveRegion) {
      return shown;
    }
    // A live region, so a screen reader announces the flare when it appears, and a dismiss
    // action to lower it, as a SnackBar has.
    return Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () => entry.lower(reason: HarborFlareClosedReason.dismiss),
      child: shown,
    );
  }
}

/// A flare's constraints when it reaches the coast: loose, carrying the coast it covers, which
/// the flare hands its content as `MediaQuery.padding`.
class _CoastConstraints extends BoxConstraints {
  _CoastConstraints(final Size room, this.coast) : super(maxWidth: room.width, maxHeight: room.height);

  final EdgeInsets coast;

  @override
  bool operator ==(final Object other) => super == other && other is _CoastConstraints && other.coast == coast;

  @override
  int get hashCode => Object.hash(super.hashCode, coast);
}

/// Puts a flare's [HarborFlareEntry] in scope for its builder and transition: read it with
/// [HarborFlareEntry.maybeOf].
@internal
class HarborFlareScope extends InheritedWidget {
  const HarborFlareScope({super.key, required this.entry, required super.child});

  final HarborFlareEntry entry;

  @override
  bool updateShouldNotify(final HarborFlareScope oldWidget) => !identical(entry, oldWidget.entry);
}

/// Clips its child at the edge of [anchor] facing [side]: below an anchor, nothing above the
/// anchor's bottom edge is drawn. For a flare or buoy that emerges from under the field it hangs
/// from, slid in from that edge while this keeps it hidden until it clears it.
///
/// The anchor is measured each time this paints, so the clip follows an anchor that scrolls. An
/// anchored flare never flips, so its [HarborFlareEntry.side] is the side to give; read it in the
/// flare's transition with [HarborFlareEntry.maybeOf]:
///
/// ```dart
/// HarborFlares.raise(
///   context,
///   placement: HarborAnchored(searchField),
///   transitionBuilder: (context, animation, child) {
///     final HarborFlareEntry entry = HarborFlareEntry.maybeOf(context)!;
///     return HarborAnchorClip(
///       anchor: entry.anchor!,
///       side: entry.side,
///       child: SlideTransition(
///         position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(animation),
///         child: child,
///       ),
///     );
///   },
///   builder: (context) => const Text('No results'),
/// );
/// ```
///
/// With no box for its anchor (the anchor is out of the tree), it draws its child unclipped.
class HarborAnchorClip extends SingleChildRenderObjectWidget {
  const HarborAnchorClip({super.key, required this.anchor, required this.side, super.child});

  final HarborAnchor anchor;
  final HarborAnchorSide side;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderAnchorClip(anchor, side, Directionality.maybeOf(context) ?? TextDirection.ltr);

  @override
  void updateRenderObject(final BuildContext context, final RenderObject renderObject) {
    (renderObject as _RenderAnchorClip)
      ..anchor = anchor
      ..side = side
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

class _RenderAnchorClip extends RenderProxyBox {
  _RenderAnchorClip(this._anchor, this._side, this._textDirection);

  HarborAnchor _anchor;
  set anchor(final HarborAnchor value) {
    if (!identical(value, _anchor)) {
      _anchor = value;
      markNeedsPaint();
    }
  }

  HarborAnchorSide _side;
  set side(final HarborAnchorSide value) {
    if (value != _side) {
      _side = value;
      markNeedsPaint();
    }
  }

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (value != _textDirection) {
      _textDirection = value;
      markNeedsPaint();
    }
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? anchorBox = _anchor.box;
    if (child == null || anchorBox == null || !anchorBox.attached || !anchorBox.hasSize) {
      _clip.layer = null;
      super.paint(context, offset);
      return;
    }
    final Rect at = MatrixUtils.transformRect(anchorBox.getTransformTo(this), Offset.zero & anchorBox.size);
    const double far = 1e6;
    final bool ltr = _textDirection == TextDirection.ltr;
    final Rect beyond = switch (_side) {
      HarborAnchorSide.below => Rect.fromLTRB(-far, at.bottom, far, far),
      HarborAnchorSide.above => Rect.fromLTRB(-far, -far, far, at.top),
      HarborAnchorSide.start => ltr ? Rect.fromLTRB(-far, -far, at.left, far) : Rect.fromLTRB(at.right, -far, far, far),
      HarborAnchorSide.end => ltr ? Rect.fromLTRB(at.right, -far, far, far) : Rect.fromLTRB(-far, -far, at.left, far),
    };
    _clip.layer = context.pushClipRect(needsCompositing, offset, beyond, super.paint, oldLayer: _clip.layer);
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

/// Sets what flares raised beneath it do when one is already up at their place, for a subtree:
/// on a remote-driven screen, `HarborFlarePolicy(queue: HarborFlareQueue.replace)` makes a
/// newer "Saved" replace the one up rather than arrive seconds late. A flare's own
/// `HarborFlares.raise(queue:)` overrides it.
class HarborFlarePolicy extends InheritedWidget {
  const HarborFlarePolicy({super.key, required this.queue, required super.child});

  final HarborFlareQueue queue;

  /// The queue at [context]: the nearest policy's, or [HarborFlareQueue.wait] with none.
  static HarborFlareQueue queueOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborFlarePolicy>()?.queue ?? HarborFlareQueue.wait;

  @override
  bool updateShouldNotify(final HarborFlarePolicy oldWidget) => queue != oldWidget.queue;
}
