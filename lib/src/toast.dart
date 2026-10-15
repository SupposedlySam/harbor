part of 'float.dart';

/// Where a toast is shown within the room of its frame.
enum HarborToastSlot {
  top(Alignment.topCenter),
  high(Alignment(0.0, -0.55)),
  middle(Alignment.center),
  low(Alignment.bottomCenter);

  const HarborToastSlot(this.alignment);

  final Alignment alignment;
}

/// Which frame a toast goes to.
enum HarborToastTarget {
  /// The page frame on top right now (a sheet over a page over the root), so a low
  /// toast clears that sheet's footer.
  topmost,

  /// The outermost frame, the root's, so the toast clears only the system edges.
  root;

  /// The old name of [root].
  @Deprecated('Renamed root. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
  static const HarborToastTarget sea = root;
}

/// Transient floats: messages shown in a frame's room for a while.
///
/// See also:
///
///  * `SnackBar` and `ScaffoldMessenger.showSnackBar`, which queue their messages one at a time;
///    toasts queue per slot, so toasts at different slots show together.
abstract final class HarborToasts {
  /// What the deprecated `duration:` reads when it is left out, so that `duration: null`, which
  /// never ran out, can be told apart from it.
  static const Duration _unsetDuration = Duration(microseconds: -1);

  /// Shows [builder]'s toast in [target]'s room at [slot], hidden
  /// once its [timing] runs out (or when the returned entry is hidden). If its frame
  /// leaves (the page is popped), the toast moves to the page frame now on top.
  ///
  /// Toasts at the same slot or alignment take turns, as a
  /// `ScaffoldMessenger` shows its snack bars one at a time: each comes in once
  /// the one before it has left. To replace the toast that is up, hide it.
  /// [HarborToastEntry.closed] completes once a toast has left, with why.
  ///
  /// [timing] is how long the toast stays: 4 s, a `SnackBar`'s, when null. Its duration counts
  /// only while the toast is in sight, unless [HarborToastTiming.countsWhileCovered] keeps it
  /// running under a covering route: from the end of its entrance (from its start with
  /// [HarborToastTiming.countsEntrance], so the toast is on screen that long, entrance
  /// included), and not while another route covers its page. Set
  /// [HarborToastEntry.duration] to change it once the toast is up.
  /// [HarborToastTiming.untilHidden] keeps the toast until it is hidden, as a
  /// `SnackBar` with `persist` does; give it to a toast with a button, so a
  /// screen-reader user has time to reach it.
  ///
  /// [placement] places the toast instead of a slot: at an exact point of the
  /// room ([HarborAligned]), as an aligned [HarborFloat] is placed, or by
  /// a [HarborAnchorPoint] ([HarborAnchored]). Give a slot or a placement, or
  /// neither for [HarborToastSlot.high]. An [AlignmentDirectional] or an
  /// [EdgeInsetsDirectional] is resolved in the reading direction of
  /// [context], the page that showed it, whose themes the toast also keeps.
  ///
  /// An anchored toast sits on its side of the anchor (below by default), its
  /// gap away, lined up by its cross alignment, and kept inside the
  /// room; it never flips, so its transition knows its side. Show it from
  /// the page that holds the anchor: an anchored toast is shown by that page's
  /// page frame rather than the one on top ([target] is not read), so it never sits
  /// over a sheet or dialog by an anchor beneath it. Toasts at one anchor and
  /// side take turns. While the anchor is out of the tree the toast is not
  /// shown, takes no taps and is not read out, and its time stops. If its page
  /// is popped, it is hidden with [HarborToastClosedReason.remove] rather than
  /// moving to the page frame now on top.
  ///
  /// The toast fades and scales in and out over [animationStyle] (220 ms each
  /// way by default). [AnimationStyle.noAnimation] shows it as it is, for a
  /// widget that brings its own entrance; [transitionBuilder] builds your own
  /// entrance and exit from harbor's animation instead. Either way a hidden
  /// toast stays at least 300 ms, so the widget's own exit can run. With
  /// reduced motion it appears and leaves at once.
  ///
  /// With [reachesSystemEdges], the toast may reach over the system edges on the edges it is
  /// against, as a fixed `SnackBar` runs under the home indicator: its room is
  /// the frame less the bars and the keyboard, not less the system edges too, and its
  /// content is handed the system edges it covers as `MediaQuery.padding` to keep its
  /// text clear. It is against the sides always, and against the top or bottom
  /// when it is placed there ([HarborToastSlot.top], [HarborToastSlot.low], or
  /// an alignment at that edge). Give it a [HarborAligned] with
  /// `margin: EdgeInsets.zero` to run edge to edge. It is for an aligned toast
  /// only: an anchored toast sits by its anchor, clear of the system edges.
  ///
  /// [queue] is what it does when a toast is already up at its place: wait its
  /// turn ([HarborToastQueue.wait]) or take it at once
  /// ([HarborToastQueue.replace]), hiding the one up. Null takes [HarborDefaults.toastQueue] at
  /// [context]: [HarborToastQueue.wait] unless a scope above sets it. Likewise a null [timing],
  /// [animationStyle] or [hinge] takes [HarborDefaults.toastTiming],
  /// [HarborDefaults.toastAnimationStyle] or [HarborDefaults.hinge], and a toast at a [slot] (or at
  /// none) keeps [HarborDefaults.toastMargin] in from the room's edges; a toast given a [placement]
  /// keeps the placement's own margin.
  ///
  /// A placement's margin is how far the toast keeps in from the room's
  /// edges: 16 at a slot or an alignment and 8 by an anchor unless it says.
  /// [EdgeInsets.zero] lets it reach them, for a bar the width of the screen
  /// (a fixed `SnackBar`'s look). It stays in the room either way, off
  /// the system edges and the bars. [HarborToastEntry.hold] stops its time while it
  /// is held.
  ///
  /// The toast is a live region with a dismiss action, so a screen reader
  /// announces it and can hide it, as it does a `SnackBar`. Give
  /// [liveRegion] false when [builder]'s widget is its own live region: harbor
  /// then adds no semantics, and the widget's node is the only one announced.
  ///
  /// With no frame above [context] (a bare `MaterialApp` in a widget test, a
  /// screen not yet built from a frame), the toast goes to the nearest
  /// [Overlay], kept clear of `MediaQuery.padding` and `viewInsets`. With no
  /// overlay either, it is reported through [FlutterError.reportError] and
  /// returned already hidden. An anchored toast in an overlay is placed by its
  /// anchor in the same room.
  static HarborToastEntry show(
    final BuildContext context, {
    required final WidgetBuilder builder,
    final HarborToastSlot? slot,
    final HarborPlacement? placement,
    @Deprecated(
      'Use placement: HarborAligned(alignment: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAligned added after `dart fix`, or '
      'the import widened.',
    )
    final AlignmentGeometry? alignment,
    final HarborToastTiming? timing,
    @Deprecated(
      'Use timing: HarborToastTiming(duration: ...), or HarborToastTiming.untilHidden for null. '
      '`dart fix` applies it in a file that imports package:harbor/harbor.dart. Deprecated after 0.9.0. A file that '
      'imports harbor with `show` needs HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final Duration? duration = _unsetDuration,
    @Deprecated(
      'Use timing: HarborToastTiming.untilHidden for true, and leave out false. `dart fix` applies it to true and '
      'false, in a file that imports package:harbor/harbor.dart. Deprecated after 0.9.0. A file that imports harbor '
      'with `show` needs HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final bool? persist,
    final HarborToastTarget target = HarborToastTarget.topmost,
    final AnimationStyle? animationStyle,
    final HarborToastTransitionBuilder? transitionBuilder,
    final bool liveRegion = true,
    @Deprecated(
      'Use placement: HarborAnchored(anchor). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final HarborAnchor? anchor,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, side: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final HarborAnchorSide? side,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, gap: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final double? gap,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, crossAlignment: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final HarborCrossAlignment? crossAlignment,
    @Deprecated(
      'Use placement: HarborAligned(margin: ...), or HarborAnchored(anchor, margin: ...). `dart fix` applies it in a '
      'file that imports package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write '
      'placement: by hand. Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAligned and '
      'HarborAnchored added after `dart fix`, or the import widened.',
    )
    final EdgeInsetsGeometry? margin,
    @Deprecated(
      'Use timing: HarborToastTiming(countsEntrance: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart. Deprecated after 0.9.0. A file that imports harbor with `show` needs '
      'HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final bool? countsEntrance,
    final bool reachesSystemEdges = false,
    final HarborHinge? hinge,
    @Deprecated(
      'Use timing: HarborToastTiming(countsWhileCovered: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart. Deprecated after 0.9.0. A file that imports harbor with `show` needs '
      'HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final bool? countsWhileCovered,
    final HarborToastQueue? queue,
  }) {
    assert(slot == null || alignment == null, 'Give a toast a slot or an alignment, not both.');
    assert(
      anchor == null || (slot == null && alignment == null),
      'Give an anchored toast its anchor alone, without a slot or an alignment.',
    );
    assert(
      placement == null ||
          (slot == null &&
              alignment == null &&
              anchor == null &&
              side == null &&
              gap == null &&
              crossAlignment == null &&
              margin == null),
      'Give a toast a slot or a placement, not both, and not with the deprecated alignment, anchor, side, gap, '
      'crossAlignment or margin.',
    );
    assert(
      timing == null ||
          (identical(duration, _unsetDuration) &&
              persist == null &&
              countsEntrance == null &&
              countsWhileCovered == null),
      'Give a toast its timing, not with the deprecated duration, persist, countsEntrance or countsWhileCovered.',
    );
    assert(placement is! HarborAnchored || placement.anchor != null, 'An anchored toast needs an anchor.');
    assert(
      placement is! HarborAnchored || placement.flips != true,
      'A toast never flips: its transition is built for the side it was shown on. Leave flips null.',
    );
    // The deprecated anchor with reachesCoast stays as it was since 0.6.3, a no-op; spelled as a
    // placement it is a mistake.
    assert(
      !reachesSystemEdges || placement is! HarborAnchored,
      'reachesSystemEdges is for an aligned toast: an anchored one sits by its anchor, clear of the system edges.',
    );
    final TextDirection textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    // Read once, where it is shown from: what the page that showed it, and the root above it, chose
    // for what this call leaves out.
    final HarborDefaults defaults = HarborDefaults.read(context);
    // Resolved where it is shown from: the page that showed it decides its reading direction, wherever
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
                alignment: alignment ?? (slot ?? HarborToastSlot.high).alignment,
                // The defaults' margin is for a toast at a slot, or at none: the deprecated alignment
                // keeps the margin it had, so a call `dart fix` moves to a placement sits where it did.
                margin: margin ?? (alignment == null ? defaults.toastMargin : null) ?? HarborAligned.defaultMargin,
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
    final HarborFrameRegistry? registry = HarborFrameRegistryScope.maybeOf(context);
    // A toast is built in its frame's float layer, not where it was shown from, so it takes the
    // themes and text style of the place that showed it, as a sheet does. Without this a page
    // that wraps itself in its own Theme showed a toast in the app's theme.
    final CapturedThemes themes = InheritedTheme.capture(from: context, to: null);
    final ShownToast entry = ShownToast(
      // A Builder, so the builder's own context sees the captured themes, not only what it returns.
      builder: (final BuildContext _) => themes.wrap(Builder(builder: builder)),
      placement: placed,
      // The deprecated spellings, merged: persist was a duration that never ran out.
      timing:
          timing ??
          // The defaults' timing is for a call that says nothing about time; the deprecated
          // spellings keep the defaults they had.
          (identical(duration, _unsetDuration) &&
                  persist == null &&
                  countsEntrance == null &&
                  countsWhileCovered == null
              ? defaults.toastTiming ?? const HarborToastTiming()
              : null) ??
          HarborToastTiming(
            duration: persist ?? false
                ? null
                : identical(duration, _unsetDuration)
                ? HarborToastTiming.defaultDuration
                : duration,
            countsEntrance: countsEntrance ?? false,
            countsWhileCovered: countsWhileCovered ?? false,
          ),
      // Sent to the root, a toast clears only the system edges.
      avoidInGlobal: target == HarborToastTarget.topmost ? HarborController.maybeOf(context)?.roomInGlobal() : null,
      shownFrom: target == HarborToastTarget.topmost ? HarborController.maybeOf(context) : null,
      animationStyle: animationStyle ?? defaults.toastAnimationStyle,
      transitionBuilder: transitionBuilder,
      liveRegion: liveRegion,
      reachesSystemEdges: reachesSystemEdges,
      // Read where it is shown from: the page that showed it decides, wherever it is shown.
      hinge: hinge ?? defaults.hinge ?? HarborHinge.avoidSeparating,
      queue: queue ?? defaults.toastQueue ?? HarborToastQueue.wait,
    );
    final HarborController? controller = placed is HarborAnchored
        ? _pageOf(HarborController.maybeOf(context))
        : switch (target) {
                HarborToastTarget.topmost => registry?.topmost,
                HarborToastTarget.root => registry?.root,
              } ??
              HarborController.maybeOf(context);
    if (controller != null) {
      controller.showToast(entry);
    } else if (Overlay.maybeOf(context) case final OverlayState overlay) {
      (_overlayQueues[overlay] ??= _OverlayQueue(overlay)).raise(entry);
    } else {
      entry.hideAs(HarborToastClosedReason.remove);
      toastLeft(entry);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
              'HarborToasts.show found no HarborFrame, HarborRoot or Overlay above the context, so the toast was not shown.',
            ),
            ErrorHint(
              'Mount a HarborRoot in MaterialApp.builder, or show the toast from a context inside a Navigator.',
            ),
          ]),
          library: 'harbor',
        ),
      );
      return entry;
    }
    return entry;
  }

  /// The old name of [show].
  @Deprecated('Renamed show. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
  static HarborToastEntry raise(
    final BuildContext context, {
    required final WidgetBuilder builder,
    final HarborToastSlot? slot,
    final HarborPlacement? placement,
    @Deprecated(
      'Use placement: HarborAligned(alignment: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAligned added after `dart fix`, or '
      'the import widened.',
    )
    final AlignmentGeometry? alignment,
    final HarborToastTiming? timing,
    @Deprecated(
      'Use timing: HarborToastTiming(duration: ...), or HarborToastTiming.untilHidden for null. '
      '`dart fix` applies it in a file that imports package:harbor/harbor.dart. Deprecated after 0.9.0. A file that '
      'imports harbor with `show` needs HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final Duration? duration = _unsetDuration,
    @Deprecated(
      'Use timing: HarborToastTiming.untilHidden for true, and leave out false. `dart fix` applies it to true and '
      'false, in a file that imports package:harbor/harbor.dart. Deprecated after 0.9.0. A file that imports harbor '
      'with `show` needs HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final bool? persist,
    final HarborToastTarget target = HarborToastTarget.topmost,
    final AnimationStyle? animationStyle,
    final HarborToastTransitionBuilder? transitionBuilder,
    final bool liveRegion = true,
    @Deprecated(
      'Use placement: HarborAnchored(anchor). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final HarborAnchor? anchor,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, side: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final HarborAnchorSide? side,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, gap: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final double? gap,
    @Deprecated(
      'Use placement: HarborAnchored(anchor, crossAlignment: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write placement: by hand. '
      'Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAnchored added after `dart fix`, or '
      'the import widened.',
    )
    final HarborCrossAlignment? crossAlignment,
    @Deprecated(
      'Use placement: HarborAligned(margin: ...), or HarborAnchored(anchor, margin: ...). `dart fix` applies it in a '
      'file that imports package:harbor/harbor.dart, except to a call that gives both anchor and alignment: write '
      'placement: by hand. Deprecated after 0.7.0. A file that imports harbor with `show` needs HarborAligned and '
      'HarborAnchored added after `dart fix`, or the import widened.',
    )
    final EdgeInsetsGeometry? margin,
    @Deprecated(
      'Use timing: HarborToastTiming(countsEntrance: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart. Deprecated after 0.9.0. A file that imports harbor with `show` needs '
      'HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final bool? countsEntrance,
    @Deprecated('Renamed reachesSystemEdges. `dart fix` applies it in a file that imports package:harbor/harbor.dart.')
    final bool reachesCoast = false,
    final HarborHinge? hinge,
    @Deprecated(
      'Use timing: HarborToastTiming(countsWhileCovered: ...). `dart fix` applies it in a file that imports '
      'package:harbor/harbor.dart. Deprecated after 0.9.0. A file that imports harbor with `show` needs '
      'HarborToastTiming added after `dart fix`, or the import widened.',
    )
    final bool? countsWhileCovered,
    final HarborToastQueue? queue,
  }) => show(
    context,
    builder: builder,
    slot: slot,
    placement: placement,
    alignment: alignment,
    timing: timing,
    duration: duration,
    persist: persist,
    target: target,
    animationStyle: animationStyle,
    transitionBuilder: transitionBuilder,
    liveRegion: liveRegion,
    anchor: anchor,
    side: side,
    gap: gap,
    crossAlignment: crossAlignment,
    margin: margin,
    countsEntrance: countsEntrance,
    reachesSystemEdges: reachesCoast,
    hinge: hinge,
    countsWhileCovered: countsWhileCovered,
    queue: queue,
  );

  /// The page frame [frame] is in: the first frame of its route, or of its sheet over the root.
  static HarborController? _pageOf(final HarborController? frame) {
    HarborController? page = frame;
    while (page != null && !page.isRouteLevel) {
      page = page.parent;
    }
    return page ?? frame;
  }

  static final Expando<_OverlayQueue> _overlayQueues = Expando<_OverlayQueue>();
}

/// The toasts shown in one overlay, which take turns at each alignment as
/// they do in a frame.
class _OverlayQueue {
  _OverlayQueue(this.overlay);

  final OverlayState overlay;
  final List<ShownToast> _toasts = <ShownToast>[];
  final Map<ShownToast, OverlayEntry> _hosts = <ShownToast, OverlayEntry>{};

  /// The toasts whose host has been built: those run their exit before they leave.
  final Set<ShownToast> _built = <ShownToast>{};

  void raise(final ShownToast entry) {
    queueToast(_toasts, entry);
    void lowered() {
      if (entry.showing.value) {
        return;
      }
      final OverlayEntry? host = _hosts[entry];
      if (host == null) {
        // Hidden while it waited its turn: it has no exit to run.
        entry.showing.removeListener(lowered);
        _toasts.remove(entry);
        toastLeft(entry);
      } else if (!_built.contains(entry) &&
          SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks) {
        // Hidden before its host was ever built (shown and dismissed in one callback): there is
        // nothing to run an exit for, so the host goes now. Left in, it was built with the toast
        // already hidden, never heard it go, and held the slot so every later toast queued behind it.
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
    for (final ShownToast entry in toastsInSight(_toasts)) {
      if (!_hosts.containsKey(entry)) {
        late final OverlayEntry host;
        host = OverlayEntry(
          builder: (final BuildContext _) => _OverlayToast(entry: entry, host: host, queue: this),
        );
        _hosts[entry] = host;
        overlay.insert(host);
      }
    }
  }

  /// [entry] has run its exit and left the overlay: the next at its place comes in.
  void left(final ShownToast entry) {
    _forget(entry);
    _insertInSight();
  }

  /// The overlay went away under [entry], so the toasts waiting behind it have
  /// nothing left to show them either.
  void gone(final ShownToast entry) {
    _forget(entry);
    for (final ShownToast waiting in List<ShownToast>.of(_toasts)) {
      if (!_hosts.containsKey(waiting)) {
        waiting.hideAs(HarborToastClosedReason.remove);
      }
    }
  }

  void _forget(final ShownToast entry) {
    _toasts.remove(entry);
    _hosts.remove(entry);
    _built.remove(entry);
    toastLeft(entry);
  }
}

/// A toast shown where there is no frame: in an overlay, at its slot in the
/// room the overlay's padding and keyboard leave.
class _OverlayToast extends StatefulWidget {
  const _OverlayToast({required this.entry, required this.host, required this.queue});

  final ShownToast entry;
  final OverlayEntry host;
  final _OverlayQueue queue;

  @override
  State<_OverlayToast> createState() => _OverlayToastState();
}

class _OverlayToastState extends State<_OverlayToast> {
  Timer? _removal;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    widget.queue._built.add(widget.entry);
    widget.entry.showing.addListener(_changed);
    // Hidden during the build that inserted it, so it never hears the change: it leaves now.
    _changed();
  }

  void _changed() {
    if (!widget.entry.showing.value) {
      // Leave time for the toast's own exit animation.
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
      // The overlay went away with the toast still up: nothing is left to show it.
      widget.entry.hideAs(HarborToastClosedReason.remove);
      widget.queue.gone(widget.entry);
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ShownToast entry = widget.entry;
    final HarborPlacement placement = entry.placement;
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets keyboard = MediaQuery.viewInsetsOf(context);
    // Placed as a float is, in the overlay less its padding and keyboard: both are measured from the
    // screen's edges, so the larger one on each edge is what is covered. Reaching the system edges,
    // only the keyboard covers it.
    return _PlacedLayout(
      covered: EdgeInsets.fromLTRB(
        math.max(padding.left, keyboard.left),
        math.max(padding.top, keyboard.top),
        math.max(padding.right, keyboard.right),
        math.max(padding.bottom, keyboard.bottom),
      ),
      keyboard: entry.reachesSystemEdges && placement is HarborAligned ? keyboard : null,
      hinges: HarborPlacementEngine.hingeBounds(
        entry.hinge ?? HarborHinge.of(context),
        MediaQuery.maybeDisplayFeaturesOf(context) ?? const <DisplayFeature>[],
      ),
      placement: placement,
      anchor: entry.anchor,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: _Toast(entry: entry),
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({required this.entry});

  final ShownToast entry;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.entry.animationStyle?.curve ?? Curves.linear,
    reverseCurve: widget.entry.animationStyle?.reverseCurve,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0).animate(_animation);

  Timer? _timeout;
  bool _inSight = true;

  /// Whether the toast's anchor is in the tree; always for a toast with none.
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
    // covered by another route, or kept offstage with its tickers stopped, shows nobody the toast.
    _inSight = (ModalRoute.isCurrentOf(context) ?? true) && TickerMode.valuesOf(context).enabled;
    if (_controller.isDismissed && widget.entry.showing.value) {
      _controller.forward();
    }
    _syncTimeout();
  }

  @override
  void initState() {
    super.initState();
    toastShown(widget.entry);
    widget.entry.showing.addListener(_changed);
    widget.entry.held.addListener(_syncTimeout);
    widget.entry.restarts.addListener(_restartTimeout);
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

  /// Runs the toast's time while it is fully in and in sight, and starts it over when it comes back.
  void _syncTimeout() {
    final ShownToast entry = widget.entry;
    final Duration? duration = entry.duration;
    final bool running =
        duration != null &&
        !entry.held.value &&
        entry.showing.value &&
        (entry.countsEntrance ? !_controller.isDismissed : _controller.isCompleted) &&
        (_inSight || entry.countsWhileCovered) &&
        _anchored;
    if (running && _timeout == null) {
      _timeout = Timer(duration, () => entry.hideAs(HarborToastClosedReason.timeout));
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
    widget.entry.restarts.removeListener(_restartTimeout);
    widget.entry.anchor?.removeListener(_anchorMoved);
    _controller.removeStatusListener(_statusChanged);
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _still =>
      widget.entry.transitionDuration == Duration.zero && widget.entry.reverseTransitionDuration == Duration.zero;

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final MediaQueryData screen = _screenOf(context, media);
    return identical(screen, media)
        ? _content(context)
        : MediaQuery(
            data: screen,
            child: Builder(builder: _content),
          );
  }

  /// [media] cut down to the one screen an aligned toast keeps to when a hinge its policy keeps off
  /// splits the screen, as `DisplayFeatureSubScreen` cuts it for a dialog: the padding of the other
  /// screen and the hinge itself are not its content's to clear. An anchored toast's screen is known
  /// only as it paints, so it reads [media] as it is.
  MediaQueryData _screenOf(final BuildContext context, final MediaQueryData media) {
    final ShownToast entry = widget.entry;
    if (entry.placement is! HarborAligned) {
      return media;
    }
    final List<Rect> hinges = HarborPlacementEngine.hingeBounds(
      entry.hinge ?? HarborHinge.of(context),
      media.displayFeatures,
    );
    if (hinges.isEmpty) {
      return media;
    }
    final Rect whole = Offset.zero & media.size;
    final Rect screen = HarborPlacementEngine.screen(
      area: whole,
      placement: entry.placement,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      hinges: hinges,
    );
    return screen == whole ? media : media.removeDisplayFeatures(screen);
  }

  Widget _content(final BuildContext context) {
    final ShownToast entry = widget.entry;
    if (!entry.reachesSystemEdges) {
      return _build(context);
    }
    // The system edges the toast covers are known only once its layer has placed it, so it is read from
    // the constraints that layer hands it, and given to the content as its padding.
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        if (constraints is! _SystemEdgeConstraints) {
          return _build(context);
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: constraints.systemEdges, viewPadding: constraints.systemEdges),
          child: Builder(builder: _build),
        );
      },
    );
  }

  // The toast's entry is in scope for its builder and its transition, so either can read where
  // it hangs (HarborToastEntry.maybeOf) or take a hold on it.
  Widget _build(final BuildContext context) => HarborToastScope(
    entry: widget.entry,
    child: Builder(builder: _buildInScope),
  );

  Widget _buildInScope(final BuildContext context) {
    final ShownToast entry = widget.entry;
    final Widget child = entry.builder(context);
    final Widget shown = switch (entry.transitionBuilder) {
      final HarborToastTransitionBuilder transition => transition(context, _animation, child),
      // Shown as it is, so a widget with its own entrance doesn't play two.
      null when _still => child,
      null => FadeTransition(
        opacity: _animation,
        child: ScaleTransition(scale: _scale, child: child),
      ),
    };
    if (!entry.liveRegion) {
      return shown;
    }
    // A live region, so a screen reader announces the toast when it appears, and a dismiss
    // action to hide it, as a SnackBar has.
    return Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () => entry.hideAs(HarborToastClosedReason.dismiss),
      child: shown,
    );
  }
}

/// Puts a toast's [HarborToastEntry] in scope for its builder and transition: read it with
/// [HarborToastEntry.maybeOf].
@internal
class HarborToastScope extends InheritedWidget {
  const HarborToastScope({super.key, required this.entry, required super.child});

  final ShownToast entry;

  @override
  bool updateShouldNotify(final HarborToastScope oldWidget) => !identical(entry, oldWidget.entry);
}

/// Sets what toasts shown beneath it do when one is already up at their place, for a subtree:
/// now `HarborDefaultsScope(defaults: HarborDefaults(toastQueue: queue))`, which it builds.
///
/// Since it builds a [HarborDefaultsScope], it is no longer an [InheritedWidget]: code that looked
/// it up by type finds nothing, and reads [HarborDefaults.toastQueue] instead.
class HarborFlarePolicy extends StatelessWidget {
  @Deprecated(
    'Use HarborDefaultsScope(defaults: HarborDefaults(toastQueue: ...)). `dart fix` applies it in a file that imports '
    'package:harbor/harbor.dart. Deprecated after 0.9.1. A file that imports harbor with `show` needs '
    'HarborDefaultsScope and HarborDefaults added after `dart fix`, or the import widened.',
  )
  const HarborFlarePolicy({super.key, required this.queue, required this.child});

  final HarborToastQueue queue;

  final Widget child;

  /// The queue at [context]: [HarborDefaults.toastQueue] there, read without a dependency.
  @Deprecated('Use HarborDefaults.read(context).toastQueue. Deprecated after 0.9.1.')
  static HarborToastQueue queueOf(final BuildContext context) =>
      HarborDefaults.read(context).toastQueue ?? HarborToastQueue.wait;

  @override
  Widget build(final BuildContext context) => HarborDefaultsScope(
    defaults: HarborDefaults(toastQueue: queue),
    child: child,
  );
}
