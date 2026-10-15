part of 'float.dart';

/// An anchored float opened from anywhere: a menu from a list row, a popover
/// from a button, declared where it is opened rather than in [HarborFrame.floats].
///
/// It is an [OverlayPortal]: while [controller] shows it, [popoverBuilder]'s
/// popover floats in the nearest [Overlay] and is placed by [placement], as an
/// anchored [HarborFloat] is, in the room of the frame around this
/// widget: by the placement's anchor (or by [child] when it has none), on its
/// side, its gap away, lined up by its cross alignment, its margin in from the
/// room's edges. When that side has no room and the opposite side has, it
/// flips there (unless [HarborAnchored.flips] is false); otherwise it is kept
/// inside the room. [sideOf] tells the popover which side it landed on.
///
/// With [onDismiss], it closes as a `MenuAnchor` does: a tap outside both the
/// popover and [child], Escape while focus is in either, and back all call it.
///
/// It leaves focus where it was when it opens, as a `MenuAnchor` does, unless
/// [requestFocus] is true.
///
/// To show it in the frame drawn as it is built, call `controller.show()` before then,
/// in `initState`: an [OverlayPortalController] keeps a `show()` made before
/// its portal is attached, and the portal shows as it attaches, with no
/// post-frame callback.
///
/// See also:
///
///  * [RawMenuAnchor] and `MenuAnchor`, which also open from an [OverlayPortal] and add menu
///    semantics and keyboard navigation, which this does not.
class HarborPopover extends StatefulWidget {
  const HarborPopover({
    super.key,
    required this.controller,
    required this.popoverBuilder,
    required this.child,
    final HarborAnchored? placement,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, side: HarborAnchorSide.above). `dart fix` applies it in a file that '
      'imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final HarborAnchor? anchor,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored added after `dart fix`, or the import widened.',
    )
    final HarborAnchorSide? side,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, gap: ...). `dart fix` applies it in a file '
      'that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final double? gap,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, overlap: ...). `dart fix` applies it in a '
      'file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` '
      'needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final double? overlap,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, crossAlignment: ...). `dart fix` applies it '
      'in a file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with '
      '`show` needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final HarborCrossAlignment? crossAlignment,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, crossOffset: ...). `dart fix` applies it in '
      'a file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` '
      'needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final double? crossOffset,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, margin: ...). `dart fix` applies it in a '
      'file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` '
      'needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final EdgeInsetsGeometry? margin,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, flips: ...). `dart fix` applies it in a file '
      'that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    final bool? flips,
    this.onDismiss,
    this.consumeOutsideTaps = false,
    this.requestFocus = false,
    this.hinge,
  }) : assert(
         !requestFocus || onDismiss != null,
         'A HarborPopover that takes focus needs an onDismiss, so Escape can close it and a keyboard user is not left in it.',
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
         'Give a popover a placement, or the deprecated anchor, side, gap, overlap, crossAlignment, crossOffset, '
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

  /// Shows and hides the popover.
  final OverlayPortalController controller;

  /// Builds the popover. Its context is this widget's, so it reads the same
  /// themes and frame.
  final WidgetBuilder popoverBuilder;

  /// The old name of [popoverBuilder].
  @Deprecated('Renamed popoverBuilder. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
  WidgetBuilder get buoyBuilder => popoverBuilder;

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

  /// Where the popover sits by its anchor. A null [HarborAnchored.anchor] anchors it to [child], and a
  /// null [HarborAnchored.flips] flips it when its side has no room.
  ///
  /// Given no placement, it sits above [child], as it did before placements: a popover's side
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

  /// What the popover sits by. Null anchors it to [child].
  @Deprecated('Read placement.anchor. Deprecated after 0.7.0.')
  HarborAnchor? get anchor => placement.anchor;

  /// Which side of its anchor the popover sits on before any flip.
  @Deprecated('Read placement.side. Deprecated after 0.7.0.')
  HarborAnchorSide get side => placement.side;

  /// How far the popover sits from its anchor.
  @Deprecated('Read placement.gap. Deprecated after 0.7.0.')
  double get gap => placement.gap;

  /// How far the popover reaches back over its anchor.
  @Deprecated('Read placement.overlap. Deprecated after 0.7.0.')
  double get overlap => placement.overlap;

  /// How the popover lines up with its anchor across its side; centred by default.
  @Deprecated('Read placement.crossAlignment. Deprecated after 0.7.0.')
  HarborCrossAlignment get crossAlignment => placement.crossAlignment;

  /// How far the popover is moved across its side from where its cross alignment puts it.
  @Deprecated('Read placement.crossOffset. Deprecated after 0.7.0.')
  double get crossOffset => placement.crossOffset;

  /// How far in from the room's edges.
  @Deprecated('Read placement.margin. Deprecated after 0.7.0.')
  EdgeInsetsGeometry get margin => placement.margin;

  /// Whether the popover goes to the opposite side of its anchor when its side has no room and that
  /// side has.
  @Deprecated('Read placement.flips. Deprecated after 0.7.0.')
  bool get flips => placement.flips ?? true;

  /// Called while the popover is shown when a tap lands outside both the popover and [child] (a
  /// [TapRegion] group, as a `MenuAnchor`'s), when Escape is pressed with focus in either, and on
  /// back, before back reaches the page. Hide the popover in it. Null leaves the popover up until
  /// [controller] hides it.
  final VoidCallback? onDismiss;

  /// Whether a tap outside that calls [onDismiss] stops there, as
  /// [RawMenuAnchor.consumeOutsideTaps]: true for a menu whose closing tap must not also press
  /// what is under it. By default the tap goes on, as it does for a `MenuAnchor`.
  final bool consumeOutsideTaps;

  /// Which hinges and folds the popover keeps to one side of: the screen that holds its anchor, as
  /// a Material menu keeps to the screen of its button. Null takes the page's [HarborHinge.of].
  final HarborHinge? hinge;

  /// Whether the popover takes keyboard focus when it opens, as a sheet with no barrier does with
  /// `requestFocus: true`. False by default, which leaves focus where it was, as a `MenuAnchor`
  /// does.
  ///
  /// With true, the popover is a [FocusScope] of its own that becomes the first focus of the scope
  /// around [child] (the page's, or a modal float's or dialog's), so it has focus now if that scope
  /// does, and a control in it with `autofocus: true` takes it from there. A popover is not
  /// modal, so Tab past its last control does what it does at a route's edge (the navigator's
  /// `routeTraversalEdgeBehavior`) rather than going round inside it. When it closes, focus goes
  /// back to what the scope around it had focused before, but only if focus is still in the popover.
  /// Escape from focus in it still calls [onDismiss], which it requires.
  final bool requestFocus;

  /// The side of its anchor the popover around [context] landed on: its placement's side, or the
  /// opposite one after it flipped. A popover reads it to point its arrow at the anchor. It is
  /// placed when it paints, so after a flip this changes on the next frame drawn.
  static HarborAnchorSide sideOf(final BuildContext context) {
    final HarborAnchorSide? side = maybeSideOf(context);
    assert(side != null, 'HarborPopover.sideOf was called from outside a popover\'s popoverBuilder.');
    return side!;
  }

  /// [sideOf], or null outside a popover.
  static HarborAnchorSide? maybeSideOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PopoverSide>()?.side;

  @override
  State<HarborPopover> createState() => _HarborPopoverState();

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

class _HarborPopoverState extends State<HarborPopover> {
  HarborAnchor? _own;
  late final ValueNotifier<HarborAnchorSide> _landed = ValueNotifier<HarborAnchorSide>(widget.placement.side);
  late final _DismissPopoverAction _dismissAction = _DismissPopoverAction(this);
  bool _shown = false;

  HarborAnchor get _anchor => widget.placement.anchor ?? (_own ??= HarborAnchor(debugLabel: 'HarborPopover'));

  void _dismiss() => widget.onDismiss?.call();

  // The popover's focus scope while it is shown with requestFocus. Held here rather than in the
  // overlay child, which the controller's hide() unmounts; a new one each time it opens, as a sheet
  // has one per opening.
  FocusScopeNode? _focus;

  FocusScopeNode _focusWhileShown() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    return _focus ??= FocusScopeNode(debugLabel: 'HarborPopover')
      ..traversalEdgeBehavior = navigator?.widget.routeTraversalEdgeBehavior ?? kDefaultRouteTraversalEdgeBehavior
      ..directionalTraversalEdgeBehavior =
          navigator?.widget.routeDirectionalTraversalEdgeBehavior ?? kDefaultRouteDirectionalTraversalEdgeBehavior;
  }

  // As the popover goes: focus back to what the scope around it had before, only if focus is still in
  // the popover, and the node disposed after the frame, once its FocusScope has left the tree. Disposed
  // at once, focus stayed on the disposed node and Escape reached nothing (#42, for sheets).
  void _focusLeft(final FocusScopeNode scope) {
    if (scope.hasFocus) {
      scope.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
    if (identical(_focus, scope)) {
      _focus = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      // Unless the popover came straight back with it, moved in the same frame drawn.
      if (!identical(_focus, scope)) {
        scope.dispose();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _focusCameBack(final FocusScopeNode scope) => _focus ??= scope;

  // The controller is the caller's and tells no one when it shows or hides, so the popover reports
  // it as it comes and goes. After the frame: it comes and goes while the overlay builds.
  void _popoverCameOrWent() => WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
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
    final Widget anchored = widget.placement.anchor == null
        ? HarborAnchorPoint(anchor: _anchor, child: widget.child)
        : widget.child;
    final Widget portal = OverlayPortal(
      controller: widget.controller,
      overlayChildBuilder: (final BuildContext context) {
        Widget float = ValueListenableBuilder<HarborAnchorSide>(
          valueListenable: _landed,
          builder: (final BuildContext context, final HarborAnchorSide side, final Widget? child) =>
              _PopoverSide(side: side, child: child!),
          // A Builder, so the builder's own context is below the side it reads.
          child: Builder(builder: widget.popoverBuilder),
        );
        if (widget.requestFocus) {
          float = _PopoverFocus(
            scope: _focusWhileShown(),
            onLeft: _focusLeft,
            onCameBack: _focusCameBack,
            child: float,
          );
        }
        float = _PopoverDismissal(
          controller: widget.controller,
          groupId: this,
          consumeOutsideTaps: widget.consumeOutsideTaps,
          onDismiss: dismissible ? _dismiss : null,
          onCameOrWent: _popoverCameOrWent,
          child: float,
        );
        return _PlacedLayout(
          frame: HarborController.maybeOf(context),
          hinges: HarborPlacementEngine.hingeBounds(
            widget.hinge ?? HarborHinge.of(this.context),
            MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[],
          ),
          placement: widget.placement,
          anchor: _anchor,
          flips: widget.placement.flips ?? true,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          landed: _landed,
          child: float,
        );
      },
      // The anchor is in the popover's tap region group, as a MenuAnchor's button is in its menu's, so
      // a tap on it is its own (a toggle) and never also an outside tap. This and the Actions below
      // stay in the tree without onDismiss, switched off, so setting it does not remount the child.
      child: TapRegion(groupId: this, enabled: dismissible, child: anchored),
    );
    // Above the portal, so Escape from focus in the popover or in the child reaches it. Mapped only
    // while the popover is shown: a disabled action would still stop Escape from reaching an enclosing
    // dialog or route. RawMenuAnchor maps its own the same way.
    return Actions(
      actions: <Type, Action<Intent>>{if (dismissible && _shown) DismissIntent: _dismissAction},
      child: portal,
    );
  }
}

/// Takes focus for a popover with `requestFocus` as it opens, as a sheet with no barrier does:
/// its scope becomes the first focus of the scope around the popover. As the popover goes, it tells
/// the popover before its descendants leave, so focus is handed back while the popover's controls
/// still hold it.
class _PopoverFocus extends StatefulWidget {
  const _PopoverFocus({required this.scope, required this.onLeft, required this.onCameBack, required this.child});

  final FocusScopeNode scope;
  final ValueChanged<FocusScopeNode> onLeft;
  final ValueChanged<FocusScopeNode> onCameBack;
  final Widget child;

  @override
  State<_PopoverFocus> createState() => _PopoverFocusState();
}

class _PopoverFocusState extends State<_PopoverFocus> {
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
  Widget build(final BuildContext context) =>
      FocusScope.withExternalFocusNode(focusScopeNode: widget.scope, child: widget.child);
}

/// Escape (a [DismissIntent]) dismisses the popover while it is shown, as `RawMenuAnchor`'s
/// `DismissMenuAction` does.
class _DismissPopoverAction extends DismissAction {
  _DismissPopoverAction(this._popover);

  final _HarborPopoverState _popover;

  @override
  bool isEnabled(final DismissIntent intent) =>
      _popover.widget.onDismiss != null && _popover.widget.controller.isShowing;

  @override
  void invoke(final DismissIntent intent) => _popover._dismiss();
}

class _PopoverSide extends InheritedWidget {
  const _PopoverSide({required this.side, required super.child});

  final HarborAnchorSide side;

  @override
  bool updateShouldNotify(final _PopoverSide oldWidget) => side != oldWidget.side;
}

/// While a popover is shown: its tap region, which calls [onDismiss] on a tap outside the
/// group, and the page's history entry, so back dismisses the popover first, as it does a modal
/// [HarborFloat]. Both are off without [onDismiss]; the region stays, so the popover keeps its state.
class _PopoverDismissal extends StatefulWidget {
  const _PopoverDismissal({
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
  State<_PopoverDismissal> createState() => _PopoverDismissalState();
}

class _PopoverDismissalState extends State<_PopoverDismissal> {
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
  void didUpdateWidget(final _PopoverDismissal oldWidget) {
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

/// The old name of [HarborPopover], which takes the old name of its builder.
///
/// A subclass rather than a typedef, so the new constructor can keep [HarborPopover.popoverBuilder]
/// required.
@Deprecated('Renamed HarborPopover. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
class HarborPortalBuoy extends HarborPopover {
  /// The old name of [HarborPopover.new].
  @Deprecated('Renamed HarborPopover. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
  const HarborPortalBuoy({
    super.key,
    required super.controller,
    @Deprecated('Renamed popoverBuilder. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
    final WidgetBuilder? buoyBuilder,
    required super.child,
    super.placement,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, side: HarborAnchorSide.above). `dart fix` applies it in a file that '
      'imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.anchor,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored added after `dart fix`, or the import widened.',
    )
    super.side,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, gap: ...). `dart fix` applies it in a file '
      'that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.gap,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, overlap: ...). `dart fix` applies it in a '
      'file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` '
      'needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.overlap,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, crossAlignment: ...). `dart fix` applies it '
      'in a file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with '
      '`show` needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.crossAlignment,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, crossOffset: ...). `dart fix` applies it in '
      'a file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` '
      'needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.crossOffset,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, margin: ...). `dart fix` applies it in a '
      'file that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` '
      'needs HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.margin,
    @Deprecated(
      'Use placement: HarborAnchored(null, side: HarborAnchorSide.above, flips: ...). `dart fix` applies it in a file '
      'that imports package:harbor/harbor.dart. Deprecated after 0.7.0. A file that imports harbor with `show` needs '
      'HarborAnchored and HarborAnchorSide added after `dart fix`, or the import widened.',
    )
    super.flips,
    super.onDismiss,
    super.consumeOutsideTaps,
    super.requestFocus,
    super.hinge,
  }) : assert(buoyBuilder != null, 'buoyBuilder is required.'),
       super(popoverBuilder: buoyBuilder ?? _noPopover);

  /// The old name of [HarborPopover.sideOf].
  @Deprecated('Renamed HarborPopover.sideOf. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
  static HarborAnchorSide sideOf(final BuildContext context) => HarborPopover.sideOf(context);

  /// The old name of [HarborPopover.maybeSideOf].
  @Deprecated(
    'Renamed HarborPopover.maybeSideOf. `dart fix` applies it in a file that imports package:harbor/harbor.dart.',
  )
  static HarborAnchorSide? maybeSideOf(final BuildContext context) => HarborPopover.maybeSideOf(context);
}

/// What a [HarborPortalBuoy] built without its deprecated `buoyBuilder` falls back to: never
/// shown, since the builder is asserted.
Widget _noPopover(final BuildContext context) => const SizedBox.shrink();
