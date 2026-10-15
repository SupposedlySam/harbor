import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'barrier_label.dart';
import 'controller.dart';
import 'defaults.dart';
import 'hinge.dart';
import 'placement.dart';
import 'render_frame.dart';

part 'anchor.dart';
part 'placement_engine.dart';
part 'popover.dart';
part 'toast.dart';

/// Something floating over a frame's body: placed in the room, the part nothing covers, so it
/// clears the system edges, every bar and the keyboard without knowing about them.
///
/// Give floats to [HarborFrame.floats]. A modal float hides the floats listed before it
/// while it is up (a menu over a tooltip).
///
/// See also:
///
///  * `Scaffold.floatingActionButton`, the closest Flutter slot, and [ModalBarrier], which a modal
///    float's barrier is like.
@immutable
class HarborFloat with Diagnosticable {
  /// A float placed by [placement] in the room: at a point of it ([HarborAligned], bottom
  /// centre by default) or by an anchor ([HarborAnchored]).
  const HarborFloat({
    this.key,
    required this.child,
    final HarborPlacement? placement,
    @Deprecated(
      'Use placement: HarborAligned(alignment: ...). `dart fix` applies it. '
      'Deprecated after 0.7.0.',
    )
    final AlignmentGeometry? alignment,
    @Deprecated(
      'Use placement: HarborAligned(margin: ...). `dart fix` applies it. '
      'Deprecated after 0.7.0.',
    )
    final EdgeInsetsGeometry? margin,
    final HarborBarrier barrier = HarborBarrier.none,
    @Deprecated(
      'Use barrier: const HarborBarrier.clear(), or HarborBarrier.dimmed(color: ...) for a barrierColor. '
      '`dart fix` applies it to modal: true and modal: false. Deprecated after 0.9.1.',
    )
    final bool modal = false,
    this.onDismiss,
    @Deprecated('Use barrier: HarborBarrier.dimmed(color: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    final Color? barrierColor,
    this.requestFocus = true,
    @Deprecated('Use barrier: HarborBarrier.clear(label: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    final String? barrierLabel,
    this.within,
    this.hinge,
  }) : assert(
         !modal || identical(barrier, HarborBarrier.none),
         'Give a float a barrier, or the deprecated modal, not both.',
       ),
       assert(
         (!modal && identical(barrier, HarborBarrier.none)) || onDismiss != null,
         'A modal float needs onDismiss: a tap on its barrier, back and Escape call it.',
       ),
       assert(
         (barrierColor == null && barrierLabel == null) || identical(barrier, HarborBarrier.none),
         'barrierColor and barrierLabel are for the deprecated modal. Give them to the barrier.',
       ),
       _barrier = barrier,
       _modal = modal,
       _barrierColor = barrierColor,
       _barrierLabel = barrierLabel,
       assert(
         placement == null || (alignment == null && margin == null),
         'Give a float a placement, or the deprecated alignment and margin, not both.',
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

  /// A float anchored to [anchor], on its [side], [gap] away, overlapping it by
  /// [overlap] (a speech bubble whose tail sits over the button), and lined up
  /// with it across that side by [crossAlignment]. Kept inside the room
  /// across that side, and never past its far edge.
  @Deprecated(
    'Use HarborFloat(placement: HarborAnchored(anchor, side: HarborAnchorSide.above)); its side is below '
    'by default. `dart fix` applies it to a call; a tear-off is yours to change. Deprecated after 0.7.0.',
  )
  const HarborFloat.anchored({
    this.key,
    // Optional and deprecated in itself, though every call gives it: `dart fix` can move a call's
    // arguments only from a diagnostic on one of them, never from the one on the constructor's name,
    // and a tear-off (which has no arguments to move) must keep compiling. So it is asserted, not typed.
    // ignore: tighten_type_of_initializing_formals
    @Deprecated(
      'Use HarborFloat(placement: HarborAnchored(anchor, side: HarborAnchorSide.above)). `dart fix` applies it. '
      'Deprecated after 0.7.0.',
    )
    this._anchor,
    required this.child,
    this._side = HarborAnchorSide.above,
    this._gap = HarborAnchored.defaultGap,
    this._overlap = 0.0,
    this._crossAlignment = HarborCrossAlignment.center,
    this._crossOffset = 0.0,
    EdgeInsetsGeometry this._margin = HarborAnchored.defaultMargin,
    final HarborBarrier barrier = HarborBarrier.none,
    @Deprecated(
      'Use barrier: const HarborBarrier.clear(), or HarborBarrier.dimmed(color: ...) for a barrierColor. '
      '`dart fix` applies it to modal: true and modal: false. Deprecated after 0.9.1.',
    )
    final bool modal = false,
    this.onDismiss,
    @Deprecated('Use barrier: HarborBarrier.dimmed(color: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    final Color? barrierColor,
    this.requestFocus = true,
    @Deprecated('Use barrier: HarborBarrier.clear(label: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    final String? barrierLabel,
    this.hinge,
  }) : assert(
         !modal || identical(barrier, HarborBarrier.none),
         'Give a float a barrier, or the deprecated modal, not both.',
       ),
       assert(
         (!modal && identical(barrier, HarborBarrier.none)) || onDismiss != null,
         'A modal float needs onDismiss: a tap on its barrier, back and Escape call it.',
       ),
       assert(
         (barrierColor == null && barrierLabel == null) || identical(barrier, HarborBarrier.none),
         'barrierColor and barrierLabel are for the deprecated modal. Give them to the barrier.',
       ),
       _barrier = barrier,
       _modal = modal,
       _barrierColor = barrierColor,
       _barrierLabel = barrierLabel,
       assert(_anchor != null, 'HarborFloat.anchored needs an anchor.'),
       _placement = null,
       _alignment = null,
       within = null;

  final Key? key;
  final Widget child;

  // The placement given, or null when the float was made with the deprecated parameters, which are
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

  /// Where the float sits in the room: at a point of it, or by an anchor. An aligned float at
  /// bottom centre, 16 in from the room's edges, when none is given.
  ///
  /// An anchored float needs an anchor, and it keeps its side: [HarborAnchored.flips] null is false
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

  /// Which hinges and folds the float keeps to one side of: the screen that holds its alignment
  /// point, or for an anchored float the screen its anchor is on. Null takes its frame's
  /// [HarborHinge.of].
  final HarborHinge? hinge;

  /// Where an aligned float sits in the room; [Alignment.center] for an anchored one.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  AlignmentGeometry get alignment => switch (placement) {
    HarborAligned(:final AlignmentGeometry alignment) => alignment,
    HarborAnchored() => Alignment.center,
  };

  /// How far in from the room's edges.
  @Deprecated('Read placement.margin. Deprecated after 0.7.0.')
  EdgeInsetsGeometry get margin => placement.margin;

  /// What the float puts between itself and the page: [HarborBarrier.none] by default, so the
  /// float is not modal. With a barrier ([HarborBarrier.clear] for quick actions or a menu, so the
  /// page shows as it is; [HarborBarrier.dimmed] to tint it) the float is modal while it is up: the
  /// barrier blocks taps to the page and its bars and tells screen readers to leave the page alone,
  /// a tap on it calls [onDismiss] unless it is not `dismissible`, back and Escape always call it,
  /// and the floats listed before it are hidden.
  ///
  /// It is modal for the keyboard as a dialog route is: the float is a [FocusScope] that takes
  /// focus when it opens (see [requestFocus]), keeps Tab in a closed loop and stops arrow keys at
  /// its edges, and gives focus back to what had it when it closes.
  ///
  /// The barrier's `label` is what a screen reader announces for it ('Dismiss' when none is
  /// given); a Material app passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`.
  ///
  /// Through 0.9 this was `modal: true`, with `barrierColor` and `barrierLabel`: a clear barrier, or
  /// one tinted by `barrierColor`. Those still work, deprecated, and this reads what they made.
  HarborBarrier get barrier => _modal
      ? (_barrierColor ?? const Color(0x00000000)).a == 0
            ? HarborBarrier.clear(label: _barrierLabel)
            : HarborBarrier.dimmed(color: _barrierColor!, label: _barrierLabel)
      : _barrier;

  // The barrier given, or the deprecated modal, barrierColor and barrierLabel, which are kept so the
  // float can be made in a const constructor.
  final HarborBarrier _barrier;
  final bool _modal;
  final Color? _barrierColor;
  final String? _barrierLabel;

  /// Whether this float is modal while it is up: whether it has a [barrier].
  ///
  /// Until 0.2.0 a modal float only hid the floats before it, with taps and back reaching the page.
  bool get modal => barrier.blocks;

  /// Called when a modal float is dismissed by a tap on its barrier, by back or by Escape. Required
  /// when it has a [barrier]: the float is yours, so you take it away.
  final VoidCallback? onDismiss;

  /// Whether a modal float takes focus when it opens, as [Route.requestFocus]: its scope is
  /// focused, so a child with `autofocus: true` takes it from there. With false, focus stays where
  /// it was, and Escape from the page still dismisses the float, though not from a page of a
  /// [Navigator] nested in the frame's body: that page's route answers Escape first. Ignored for a
  /// float that is not [modal].
  final bool requestFocus;

  /// The colour of a modal float's barrier.
  @Deprecated('Read barrier.color. Deprecated after 0.9.1.')
  Color get barrierColor => barrier.color;

  /// What a screen reader announces for a modal float's barrier.
  @Deprecated('Read barrier.label. Deprecated after 0.9.1.')
  String get barrierLabel => barrier.label ?? harborBarrierDismissLabel;

  /// What an anchored float sits by; null for an aligned one.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  HarborAnchor? get anchor => switch (placement) {
    HarborAnchored(:final HarborAnchor? anchor) => anchor,
    HarborAligned() => null,
  };

  /// Which side of its anchor an anchored float sits on.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  HarborAnchorSide get side => switch (placement) {
    HarborAnchored(:final HarborAnchorSide side) => side,
    HarborAligned() => HarborAnchorSide.above,
  };

  /// How far an anchored float sits from its anchor.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  double get gap => switch (placement) {
    HarborAnchored(:final double gap) => gap,
    HarborAligned() => 0.0,
  };

  /// How far an anchored float reaches back over its anchor.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  double get overlap => switch (placement) {
    HarborAnchored(:final double overlap) => overlap,
    HarborAligned() => 0.0,
  };

  /// How an anchored float lines up with its anchor across its side; centred by default.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  HarborCrossAlignment get crossAlignment => switch (placement) {
    HarborAnchored(:final HarborCrossAlignment crossAlignment) => crossAlignment,
    HarborAligned() => HarborCrossAlignment.center,
  };

  /// How far an anchored float is moved across its side from where its cross alignment puts it.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  double get crossOffset => switch (placement) {
    HarborAnchored(:final double crossOffset) => crossOffset,
    HarborAligned() => 0.0,
  };

  /// Keeps the float inside this rectangle (in the frame's own coordinates)
  /// as well as inside the room.
  final Rect? within;

  @override
  String toStringShort() => _placement == null && _anchor != null
      ? '${objectRuntimeType(this, 'HarborFloat')}.anchored'
      : objectRuntimeType(this, 'HarborFloat');

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Key>('key', key, defaultValue: null));
    if (_placement != null) {
      properties.add(
        DiagnosticsProperty<HarborPlacement>('placement', _placement, defaultValue: const HarborAligned()),
      );
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
    properties.add(DiagnosticsProperty<HarborBarrier>('barrier', barrier, defaultValue: HarborBarrier.none));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss));
    properties.add(
      FlagProperty('requestFocus', value: requestFocus, ifFalse: 'does not take focus', defaultValue: true),
    );
  }
}

/// The old name of [HarborFloat], whose constructors keep their names.
///
/// A subclass rather than a typedef: `dart fix` renames `HarborBuoy.anchored(...)` to a
/// `HarborFloat(placement: ...)`, and a typedef cannot carry a constructor rename.
@Deprecated('Renamed HarborFloat. `dart fix` applies it.')
class HarborBuoy extends HarborFloat {
  /// The old name of [HarborFloat.new].
  @Deprecated('Renamed HarborFloat. `dart fix` applies it.')
  const HarborBuoy({
    super.key,
    required super.child,
    super.placement,
    @Deprecated('Use placement: HarborAligned(alignment: ...). `dart fix` applies it. Deprecated after 0.7.0.')
    super.alignment,
    @Deprecated('Use placement: HarborAligned(margin: ...). `dart fix` applies it. Deprecated after 0.7.0.')
    super.margin,
    super.barrier,
    @Deprecated('Use barrier: const HarborBarrier.clear(). `dart fix` applies it. Deprecated after 0.9.1.') super.modal,
    super.onDismiss,
    @Deprecated('Use barrier: HarborBarrier.dimmed(color: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    super.barrierColor,
    super.requestFocus,
    @Deprecated('Use barrier: HarborBarrier.clear(label: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    super.barrierLabel,
    super.within,
    super.hinge,
  });

  /// The old name of [HarborFloat.anchored].
  @Deprecated(
    'Use HarborFloat(placement: HarborAnchored(anchor, side: HarborAnchorSide.above)); its side is below '
    'by default. `dart fix` applies it to a call; a tear-off is yours to change. Deprecated after 0.7.0.',
  )
  const HarborBuoy.anchored({
    super.key,
    @Deprecated(
      'Use HarborFloat(placement: HarborAnchored(anchor, side: HarborAnchorSide.above)). `dart fix` applies it. '
      'Deprecated after 0.7.0.',
    )
    super.anchor,
    required super.child,
    super.side,
    super.gap,
    super.overlap,
    super.crossAlignment,
    super.crossOffset,
    super.margin,
    super.barrier,
    @Deprecated('Use barrier: const HarborBarrier.clear(). `dart fix` applies it. Deprecated after 0.9.1.') super.modal,
    super.onDismiss,
    @Deprecated('Use barrier: HarborBarrier.dimmed(color: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    super.barrierColor,
    super.requestFocus,
    @Deprecated('Use barrier: HarborBarrier.clear(label: ...). `dart fix` applies it. Deprecated after 0.9.1.')
    super.barrierLabel,
    super.hinge,
  }) : super.anchored();
}

/// The layer a frame places its floats in.
class HarborFloatLayer extends StatefulWidget {
  const HarborFloatLayer({super.key, required this.floats, required this.toasts});

  final List<HarborFloat> floats;
  final List<ShownToast> toasts;

  @override
  State<HarborFloatLayer> createState() => _HarborFloatLayerState();
}

class _HarborFloatLayerState extends State<HarborFloatLayer> {
  /// The page's history entry while a modal float is up, so back dismisses the float first (and the
  /// iOS back swipe stands aside), as it does a sheet with no barrier.
  LocalHistoryEntry? _history;
  bool _removingQuietly = false;

  HarborFloat? get _modal {
    for (final HarborFloat float in widget.floats.reversed) {
      if (float.modal) {
        return float;
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
  void didUpdateWidget(final HarborFloatLayer oldWidget) {
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

  List<HarborFloat> get floats => widget.floats;
  List<ShownToast> get toasts => widget.toasts;

  @override
  Widget build(final BuildContext context) {
    // A toast keeps inside the room of the frame that showed it, so it is placed again
    // whenever that frame's room moves (a turn, a foldable opening): read only at build,
    // it stayed boxed into the shape the screen had when the toast was shown.
    final List<Listenable> shownFromRooms = <Listenable>[
      for (final ShownToast toast in toasts)
        if (toast.shownFrom case final HarborController frame) frame.room,
    ];
    final HarborFloat? modal = _modal;
    // One shape whether or not a toast or a modal float is up, so neither coming or going
    // remounts the floats. PASSTHROUGH, so the layer still gets the frame's own constraints, which
    // carry the room. StackFit.expand handed it plain tight ones, and a modal float was
    // centred in the whole frame instead of the room.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        // Under every float and over the page and its bars: taps beside a modal float dismiss it
        // instead of reaching the page, and the barrier blocks the page's semantics.
        if (modal != null)
          Positioned.fill(
            child: ModalBarrier(
              color: modal.barrier.color,
              dismissible: modal.barrier.isDismissible,
              onDismiss: modal.barrier.isDismissible ? modal.onDismiss : null,
              semanticsLabel:
                  modal.barrier.label ?? HarborDefaults.of(context).barrierLabel ?? harborBarrierDismissLabel,
              semanticsOnTapHint: modal.barrier.onTapHint,
            ),
          ),
        ListenableBuilder(
          listenable: Listenable.merge(shownFromRooms),
          builder: (final BuildContext context, final Widget? _) => _build(context),
        ),
      ],
    );
  }

  Widget _build(final BuildContext context) {
    final int lastModal = floats.lastIndexWhere((final HarborFloat b) => b.modal);
    assert(
      floats.every(
        (final HarborFloat b) => b.placement is! HarborAnchored || (b.placement as HarborAnchored).anchor != null,
      ),
      'A HarborFloat placed by HarborAnchored needs an anchor; only a HarborPopover anchors to its child.',
    );
    final List<HarborFloat> all = <HarborFloat>[
      ...floats,
      for (final ShownToast toast in toastsInSight(toasts))
        HarborFloat(
          key: ObjectKey(toast),
          placement: toast.placement,
          hinge: toast.hinge,
          // An anchored toast goes to the page frame of the page that holds its anchor, so only an
          // aligned one is kept inside the room of the frame that showed it.
          within: toast.placement is HarborAligned ? _local(context, toast.avoidInGlobal) : null,
          child: _Toast(entry: toast),
        ),
    ];
    return _FloatLayout(
      floats: all,
      // An anchored toast sits by its anchor in the room, so it covers no system edge to reach.
      reaching: <int>{
        for (int i = 0; i < all.length; i++)
          if (all[i].child case _Toast(
            entry: final ShownToast entry,
          ) when entry.reachesSystemEdges && entry.placement is HarborAligned)
            i,
      },
      children: <Widget>[
        for (int i = 0; i < all.length; i++)
          KeyedSubtree(
            key: all[i].key ?? ValueKey<int>(i),
            child: Visibility(
              visible: lastModal < 0 || i >= lastModal,
              maintainState: true,
              child: _ModalFloatFocus(modal: all[i].modal, requestFocus: all[i].requestFocus, child: all[i].child),
            ),
          ),
      ],
    );
  }
}

/// A modal float's focus scope, as a modal route's: its own node, so focus traversal ends at its
/// edges ([FocusScopeNode]'s defaults are a dialog's: Tab loops, arrows stop). On close, the scope
/// around it falls back to the child it focused before, as a page does when a dialog pops.
///
/// Every float has one, so a float that turns modal or back keeps its child: the scope comes and goes
/// around the child, which moves under a [GlobalKey] instead of being built again.
class _ModalFloatFocus extends StatefulWidget {
  const _ModalFloatFocus({required this.modal, required this.requestFocus, required this.child});

  final bool modal;
  final bool requestFocus;
  final Widget child;

  @override
  State<_ModalFloatFocus> createState() => _ModalFloatFocusState();
}

class _ModalFloatFocusState extends State<_ModalFloatFocus> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'HarborFloat (modal)');
  final GlobalKey _child = GlobalKey(debugLabel: 'HarborFloat child');
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
  void didUpdateWidget(final _ModalFloatFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.modal) {
      _open();
    }
  }

  // As a modal route takes focus: first focus in the scope around it, so the float has focus now if
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

/// Escape (a [DismissIntent]) from anywhere in a frame calls its top modal float's
/// [HarborFloat.onDismiss], from focus in the float or on the page behind it. With no modal float up
/// it is left to the widgets above, as `RawMenuAnchor` leaves it while its menu is closed: a page
/// route answers Escape with an action that is disabled, which would stop the search there. For
/// the same reason, a page of a navigator nested in the frame's body keeps Escape from reaching
/// this.
class HarborModalFloatActions extends StatelessWidget {
  const HarborModalFloatActions({super.key, required this.floats, required this.child});

  final List<HarborFloat> floats;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final int top = floats.lastIndexWhere((final HarborFloat b) => b.modal);
    return Actions(
      actions: <Type, Action<Intent>>{if (top >= 0) DismissIntent: _DismissModalFloatAction(floats[top].onDismiss!)},
      child: child,
    );
  }
}

class _DismissModalFloatAction extends DismissAction {
  _DismissModalFloatAction(this._onDismiss);

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

class _FloatLayout extends MultiChildRenderObjectWidget {
  const _FloatLayout({required this.floats, this.reaching = const <int>{}, required super.children});

  final List<HarborFloat> floats;

  /// The floats (toasts) that may reach over the system edges, by index.
  final Set<int> reaching;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderFloatLayer(floats, Directionality.maybeOf(context) ?? TextDirection.ltr)
        .._features = MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[]
        .._hinge = HarborHinge.of(context)
        .._reaching = reaching;

  @override
  void updateRenderObject(final BuildContext context, final _RenderFloatLayer renderObject) {
    renderObject
      ..floats = floats
      ..reaching = reaching
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr
      // Read through displayFeaturesOf alone, so the layer is not rebuilt for every other change
      // to MediaQuery.
      ..features = MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[]
      ..hinge = HarborHinge.of(context);
  }
}

class _FloatParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether the last paint painted this float. An anchored float is not painted while its anchor
  /// has no box, and its offset is then stale, so it takes no taps and is not read out either.
  bool painted = false;
}

class _RenderFloatLayer extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FloatParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FloatParentData> {
  _RenderFloatLayer(this._floats, this._textDirection);

  List<HarborFloat> _floats;

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

  /// The frame's policy, for the floats with none of their own.
  HarborHinge _hinge = HarborHinge.avoidSeparating;
  set hinge(final HarborHinge value) {
    if (value != _hinge) {
      _hinge = value;
      markNeedsLayout();
    }
  }

  /// The bounds of the hinges and folds [float] keeps off: its own policy's, or the frame's.
  List<Rect> _hingesFor(final HarborFloat float) => HarborPlacementEngine.hingeBounds(float.hinge ?? _hinge, _features);

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (value == _textDirection) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  set floats(final List<HarborFloat> value) {
    _floats = value;
    markNeedsLayout();
  }

  // Its own layer, since it is painted again every frame drawn while it has an anchored float.
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
    if (child.parentData is! _FloatParentData) {
      child.parentData = _FloatParentData();
    }
  }

  @override
  Size computeDryLayout(final BoxConstraints constraints) => constraints.biggest;

  Rect _clear = Rect.zero;

  @override
  void performLayout() {
    size = constraints.biggest;
    _clear = constraints is HarborFloatConstraints ? (constraints as HarborFloatConstraints).room : Offset.zero & size;
    final Rect open = constraints is HarborFloatConstraints
        ? (constraints as HarborFloatConstraints).roomWithSystemEdges
        : _clear;
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _FloatParentData data = child.parentData! as _FloatParentData;
      final HarborFloat float = _floats[i];
      final HarborPlacement placement = float.placement;
      final bool reaches = _reaching.contains(i);
      // An anchored float is laid out in the largest screen of its room, since which screen holds
      // its anchor is only known when it paints.
      final HarborPlacementArea area = HarborPlacementEngine.area(
        clear: _clear,
        open: reaches ? open : null,
        within: float.within,
        placement: placement,
        textDirection: _textDirection,
        hinges: _hingesFor(float),
      );
      final Size room = Size(math.max(0.0, area.rect.width), math.max(0.0, area.rect.height));
      child.layout(
        reaches ? _SystemEdgeConstraints(room, area.systemEdgesCovered) : BoxConstraints.loose(room),
        parentUsesSize: true,
      );
      // Anchored floats are placed when they paint, once their anchors have a size.
      if (placement is HarborAligned) {
        data.offset = HarborPlacementEngine.place(
          placement: placement,
          area: area.rect,
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
    if (_floats.any((final HarborFloat b) => b.placement is HarborAnchored)) {
      _follow.next(markNeedsPaint);
    }
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      final _FloatParentData data = child.parentData! as _FloatParentData;
      final HarborFloat float = _floats[i];
      final HarborPlacement placement = float.placement;
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
          area: HarborPlacementEngine.area(
            clear: _clear,
            within: float.within,
            placement: placement,
            textDirection: _textDirection,
            hinges: _hingesFor(float),
            holding: at.center,
          ).rect,
          size: child.size,
          textDirection: _textDirection,
          anchorRect: at,
          // A toast never flips, so its transition knows its side (HarborToastEntry.side).
          flips: float.child is! _Toast && (placement.flips ?? false),
        ).offset;
      }
      context.paintChild(child, data.offset + offset);
      child = data.nextSibling;
      i++;
    }
  }

  @override
  bool paintsChild(final RenderBox child) => (child.parentData! as _FloatParentData).painted;

  @override
  void visitChildrenForSemantics(final RenderObjectVisitor visitor) {
    RenderBox? child = firstChild;
    while (child != null) {
      final _FloatParentData data = child.parentData! as _FloatParentData;
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
      final _FloatParentData data = child.parentData! as _FloatParentData;
      final RenderBox shown = child;
      if (data.painted &&
          result.addWithPaintOffset(
            offset: data.offset,
            position: position,
            hitTest: (final BoxHitTestResult result, final Offset transformed) =>
                shown.hitTest(result, position: transformed),
          )) {
        return true;
      }
      child = data.previousSibling;
    }
    return false;
  }
}
