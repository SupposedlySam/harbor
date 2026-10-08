import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'dock.dart';
import 'harbor.dart';
import 'render_harbor.dart';
import 'tide.dart';
import 'wake.dart';

/// A sheet's heights, for a draggable sheet: fractions of the space above the keyboard.
@immutable
class HarborSheetExtent {
  const HarborSheetExtent({this.rest = 0.5, this.max = 0.88, this.min = 0.25, this.snap = true, this.snapSizes});

  /// Where the sheet opens and rests.
  final double rest;

  /// The taller snap and the ceiling.
  final double max;

  /// The drag floor; released below it, the sheet closes.
  final double min;

  final bool snap;

  /// The heights a released sheet snaps to, in increasing order, between [min]
  /// and [max]; [max] is always one. Defaults to [rest] and [max].
  final List<double>? snapSizes;

  List<double> get _snaps => <double>{...(snapSizes ?? <double>[rest]), max}.toList()..sort();
}

/// A sheet's surface: a new port with its own docks. Its header is a pier the
/// body sails under, with a wake; its footer is a quay that floats on the
/// tide and keeps [footerMinimum] above the screen's edge on a phone with no
/// home indicator. Neither is given a height: both are measured.
///
/// The sheet keeps the coast at the bottom (the home indicator), so its footer
/// clears it once and nothing else in it has to.
class HarborSheet extends StatelessWidget {
  /// A sheet as tall as its content, up to [maxExtentFraction] of the space
  /// above the keyboard, past which its body scrolls.
  const HarborSheet({
    super.key,
    this.header,
    this.footer,
    required Widget this.body,
    this.surface,
    this.headerWake = const HarborWake.fade(length: 12.0),
    this.footerWake = const HarborWake.hairline(),
    this.footerMinimum = 16.0,
    this.footerTide = HarborTideStance.float,
    this.maxExtentFraction = 0.9,
    this.debugLabel,
    this.contentBuilder,
    this.clip,
    this.dragToClose = false,
  }) : builder = null,
       extent = null;

  /// A sheet whose content is a list: it rests at [extent]'s rest height, drags
  /// to its ceiling, and closes when dragged below its floor. [builder] must
  /// give its fairway the controller it is handed, so dragging the list drags
  /// the sheet.
  const HarborSheet.draggable({
    super.key,
    this.header,
    this.footer,
    required Widget Function(BuildContext context, ScrollController controller) this.builder,
    this.extent = const HarborSheetExtent(),
    this.surface,
    this.headerWake = const HarborWake.fade(length: 12.0),
    this.footerWake = const HarborWake.hairline(),
    this.footerMinimum = 16.0,
    this.footerTide = HarborTideStance.float,
    this.debugLabel,
    this.contentBuilder,
    this.clip,
  }) : body = null,
       maxExtentFraction = null,
       dragToClose = false;

  final Widget? header;
  final Widget? footer;
  final Widget? body;
  final Widget Function(BuildContext context, ScrollController controller)? builder;
  final HarborSheetExtent? extent;

  /// Painted under the whole sheet: its color and corners.
  final Widget? surface;
  final HarborWake headerWake;
  final HarborWake footerWake;
  final double footerMinimum;
  final HarborTideStance footerTide;
  final double? maxExtentFraction;
  final String? debugLabel;

  /// Wraps everything over the [surface] (header, body and footer), above the surface so ink
  /// shows. For a Material app, so text fields and ink work in the sheet:
  ///
  /// ```dart
  /// contentBuilder: (context, content) => Material(
  ///   type: MaterialType.transparency,
  ///   textStyle: DefaultTextStyle.of(context).style, // keep the opener's text style
  ///   child: content,
  /// ),
  /// ```
  ///
  /// harbor's core imports no design library: Flutter 3.47 moved Material and Cupertino into
  /// packages of their own (`material_ui`, `cupertino_ui`), and a layout package should not choose
  /// one for every app that uses it.
  final TransitionBuilder? contentBuilder;

  /// Clips the sheet to this shape, so a body that runs edge to edge (a photo)
  /// follows the surface's rounded top.
  final ShapeBorder? clip;

  /// Lets a content-sized sheet be dragged down to close, by any part of it
  /// that doesn't scroll, when [showHarborSheet] opened it. A draggable sheet
  /// always closes when dragged below its floor.
  final bool dragToClose;

  Harbor _harbor(final Widget body, {required final bool hug, final Widget? header}) => Harbor(
    newPort: true,
    sizing: hug ? HarborSizing.hugBody : HarborSizing.fill,
    maxExtentFraction: hug ? maxExtentFraction : null,
    debugLabel: debugLabel ?? 'sheet',
    top: <HarborDock>[
      if ((header ?? this.header) != null)
        HarborDock.pier(wake: headerWake, debugLabel: 'sheet header', child: (header ?? this.header)!),
    ],
    bottom: <HarborDock>[
      if (footer != null)
        HarborDock.quay(
          tide: footerTide,
          wake: footerWake,
          minimum: footerMinimum,
          debugLabel: 'sheet footer',
          child: footer!,
        ),
    ],
    body: body,
  );

  @override
  Widget build(final BuildContext context) {
    final HarborSheetExtent? extent = this.extent;
    if (extent != null) {
      // The surface goes inside the draggable sheet, so it is as tall as the
      // sheet is dragged, not as tall as the space the sheet can be dragged in.
      return _DraggableSheetBody(sheet: this, extent: extent);
    }
    final Widget sheet = _surfaced(context, _harbor(body!, hug: true));
    if (!dragToClose) {
      return sheet;
    }
    final _SheetHostScope? host = _SheetHostScope.maybeOf(context);
    assert(host != null, 'HarborSheet(dragToClose: true) closes only a sheet that showHarborSheet opened.');
    return GestureDetector(
      onVerticalDragUpdate: (final DragUpdateDetails details) => host?.host.dragBy(details.primaryDelta ?? 0.0),
      onVerticalDragEnd: (final DragEndDetails details) => host?.host.dragEnd(details.primaryVelocity ?? 0.0),
      child: sheet,
    );
  }

  Widget _surfaced(final BuildContext context, final Widget content) {
    Widget sheet = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(child: surface ?? const SizedBox.shrink()),
        // Over the surface, not around it: ink paints under a Material's child.
        if (contentBuilder case final TransitionBuilder wrap) wrap(context, content) else content,
      ],
    );
    final ShapeBorder? clip = this.clip;
    if (clip != null) {
      sheet = ClipPath(
        clipper: ShapeBorderClipper(shape: clip, textDirection: Directionality.maybeOf(context)),
        clipBehavior: Clip.antiAlias,
        child: sheet,
      );
    }
    return sheet;
  }
}

class _DraggableSheetBody extends StatefulWidget {
  const _DraggableSheetBody({required this.sheet, required this.extent});

  final HarborSheet sheet;
  final HarborSheetExtent extent;

  @override
  State<_DraggableSheetBody> createState() => _DraggableSheetBodyState();
}

class _DraggableSheetBodyState extends State<_DraggableSheetBody> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  double _available = 0.0;

  HarborSheetExtent get _extent => widget.extent;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The header is a handle: dragging it drags the sheet.
  void _drag(final DragUpdateDetails details) {
    if (!_controller.isAttached || _available <= 0) {
      return;
    }
    final double size = (_controller.size - (details.primaryDelta ?? 0.0) / _available).clamp(0.0, _extent.max);
    _controller.jumpTo(size);
  }

  void _release(final DragEndDetails details) {
    if (!_controller.isAttached) {
      return;
    }
    final double velocity = details.primaryVelocity ?? 0.0;
    final double size = _controller.size;
    if (size <= _extent.min + 0.001 || velocity > 1200) {
      _close();
      return;
    }
    double target = size;
    if (_extent.snap) {
      // As a dragged list snaps: a fling goes to the next size its way, a
      // slow release to the nearest.
      final List<double> snaps = _extent._snaps;
      if (velocity < -400) {
        target = snaps.firstWhere((final double snap) => snap > size + 0.001, orElse: () => snaps.last);
      } else if (velocity > 400) {
        target = snaps.lastWhere((final double snap) => snap < size - 0.001, orElse: () => snaps.first);
      } else {
        target = snaps.reduce((final double a, final double b) => (size - a).abs() <= (size - b).abs() ? a : b);
      }
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
      return;
    }
    unawaited(_controller.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic));
  }

  void _close() {
    final _SheetHostScope? host = _SheetHostScope.maybeOf(context);
    if (host != null) {
      host.close();
      return;
    }
    // Opened some other way (showModalBottomSheet, showGeneralDialog): the
    // sheet is the popup route's content, so closing it closes the route. In
    // a page, a sheet rests at its floor.
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    if (route is PopupRoute<Object?> && route.isCurrent) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final _SheetHostScope? host = _SheetHostScope.maybeOf(context);
    final double tide = MediaQuery.viewInsetsOf(context).bottom;
    // Fractions are of the space above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: tide),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) {
            _available = constraints.maxHeight;
            return _draggable(host);
          },
        ),
      ),
    );
  }

  Widget _draggable(final _SheetHostScope? host) {
    host?.host._draggable = true;
    // Its measured box is the whole screen, so report the resting height
    // until the first drag reports the real one.
    if (host != null && !host.host.hasDragExtent) {
      WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
        if (!host.host.hasDragExtent) {
          host.reportExtent(_extent.rest);
        }
      });
    }
    final HarborSheet sheet = widget.sheet;
    final Widget? header = sheet.header == null
        ? null
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _drag,
            onVerticalDragEnd: _release,
            child: sheet.header,
          );
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (final DraggableScrollableNotification n) {
        host?.reportExtent(n.extent);
        if (n.extent <= n.minExtent + 0.001) {
          _close();
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        expand: true,
        initialChildSize: _extent.rest,
        minChildSize: _extent.min,
        maxChildSize: _extent.max,
        snap: _extent.snap,
        snapSizes: _extent.snap ? _extent._snaps : null,
        builder: (final BuildContext context, final ScrollController controller) => _MeasureHeight(
          onTop: (final double top) => host?.host.reportTop(top, fromSheet: true),
          child: sheet._surfaced(
            context,
            sheet._harbor(
              Builder(builder: (final BuildContext context) => sheet.builder!(context, controller)),
              hug: false,
              header: header,
            ),
          ),
        ),
      ),
    );
  }
}

/// How a sheet sits over the page that opened it.
enum HarborSheetBarrier {
  /// A dimmed barrier that closes the sheet when tapped.
  dismissible,

  /// A clear barrier: the page stays visible, and taps on it close the sheet.
  clear,

  /// No barrier at all: the page stays live underneath (a drawer that covers
  /// the tab bar while the page keeps playing).
  none,
}

/// Opens [builder]'s sheet (usually a [HarborSheet]) over [context]'s harbor.
///
/// With [breakwater] set, the sheet reports how far it covers the bottom of
/// the harbor that opened it, animated as it slides in and out and as it is
/// dragged, and that harbor's content keeps clear of it: a fairway's last row
/// stays reachable, a lifted canvas element stays in sight.
///
/// A sheet with a barrier is a route, as a modal bottom sheet is: [routeSettings]
/// reach navigator observers and route-name analytics, and the barrier is
/// announced with [barrierLabel] ('Close sheet' when none is given; a Material app
/// passes `MaterialLocalizations.of(context).modalBarrierDismissLabel` for the
/// localized one). A sheet with [HarborSheetBarrier.none] is not a route, so it
/// has neither.
///
/// [maxWidth] caps a sheet on a wide screen. A Material app that wants the
/// bottom sheet theme's cap passes
/// `Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640`.
Future<T?> showHarborSheet<T>(
  final BuildContext context, {
  required final WidgetBuilder builder,
  final bool breakwater = false,
  final HarborSheetBarrier barrier = HarborSheetBarrier.dismissible,
  final Color barrierColor = const Color(0x66000000),
  final double? maxWidth,
  final bool useRootNavigator = false,
  final bool keepsTopCoast = false,
  final RouteSettings? routeSettings,
  final String? barrierLabel,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final HarborController? presenter = HarborController.maybeOf(context);
  // The sheet is built in the navigator's overlay, so it takes the themes and
  // text style of the page that opened it, as a modal bottom sheet does.
  final CapturedThemes themes = InheritedTheme.capture(from: context, to: navigator.context);
  final _SheetHost host = _SheetHost(
    // A Builder, so the builder's own context sees the captured themes, not only what it returns:
    // `Theme.of(context)` in a sheet's builder read the navigator's theme, not the page's.
    builder: (final BuildContext _) => themes.wrap(Builder(builder: builder)),
    maxWidth: maxWidth,
    keepsTopCoast: keepsTopCoast,
    presenter: breakwater ? presenter : null,
  );
  if (barrier == HarborSheetBarrier.none) {
    final OverlayState overlay = navigator.overlay!;
    // A non-modal sheet lives in the navigator's overlay, not in a route of its own, so it is tied
    // to the page's route by hand: back closes it first, it hides while another page is on top,
    // and it leaves when its page does. It also leaves with the harbor that opened it.
    final _NonModalSheet<T> sheet = _NonModalSheet<T>(host: host, overlay: overlay, route: ModalRoute.of(context));
    void presenterLeft() => sheet.closeNow();
    presenter?.addLeaveListener(presenterLeft);
    return sheet.open().whenComplete(() => presenter?.removeLeaveListener(presenterLeft));
  }
  return navigator.push<T>(
    _HarborSheetRoute<T>(
      host: host,
      barrierColor: barrier == HarborSheetBarrier.dismissible ? barrierColor : const Color(0x00000000),
      barrierLabel: barrierLabel ?? 'Close sheet',
      settings: routeSettings,
    ),
  );
}

class _SheetHost {
  _SheetHost({required this.builder, required this.maxWidth, required this.keepsTopCoast, required this.presenter});

  final WidgetBuilder builder;
  final double? maxWidth;
  final bool keepsTopCoast;
  final HarborController? presenter;

  final ValueNotifier<double> coverage = ValueNotifier<double>(0.0);
  HarborBreakwater? _breakwater;
  double _height = 0.0;
  double _progress = 0.0;
  double? _dragExtent;
  double _available = 0.0;
  double _tide = 0.0;
  VoidCallback? close;

  /// What slides the sheet in and out, for dragging it down by hand.
  AnimationController? slide;

  // The reveal is curved, so the drag goes through the curve's inverse to
  // keep the sheet under the finger.
  static const Curve _reveal = Curves.easeOutCubic;

  static double _unreveal(final double shown) {
    double low = 0.0;
    double high = 1.0;
    for (int i = 0; i < 24; i++) {
      final double mid = (low + high) / 2;
      if (_reveal.transform(mid) < shown) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  void dragBy(final double delta) {
    final AnimationController? slide = this.slide;
    if (slide == null || _height <= 0) {
      return;
    }
    final double shown = (_reveal.transform(slide.value) - delta / _height).clamp(0.0, 1.0);
    slide.value = _unreveal(shown);
  }

  void dragEnd(final double velocity) {
    final AnimationController? slide = this.slide;
    if (slide == null) {
      return;
    }
    // As a modal bottom sheet has it: a fling down, or let go under half shown.
    if (velocity > 700 || _reveal.transform(slide.value) < 0.5) {
      close?.call();
    } else {
      unawaited(slide.forward());
    }
  }

  /// Where the sheet's visible top is, in global coordinates.
  final ValueNotifier<double> topInGlobal = ValueNotifier<double>(double.infinity);

  void attach() {
    _breakwater ??= presenter?.addBreakwaterEdge(topInGlobal);
  }

  void reportTop(final double top, {required final bool fromSheet}) {
    // A draggable sheet's outer box is the whole drag area; only the sheet
    // inside it knows where its top is.
    if (_draggable && !fromSheet) {
      return;
    }
    topInGlobal.value = top;
  }

  void detach() {
    _breakwater?.remove();
    _breakwater = null;
  }

  bool get hasDragExtent => _dragExtent != null;
  bool _draggable = false;

  void _update() {
    if (_draggable && _dragExtent == null) {
      // A draggable sheet's measured box is the whole screen; wait for its extent.
      coverage.value = 0.0;
      return;
    }
    final double height = _dragExtent != null ? _dragExtent! * _available + _tide : _height;
    coverage.value = math.max(0.0, height * _progress);
  }

  set progress(final double value) {
    _progress = value;
    _update();
  }

  void measured(final double height) {
    if (height != _height) {
      _height = height;
      _update();
    }
  }

  void reportExtent(final double extent, final double available, final double tide) {
    _dragExtent = extent;
    _available = available;
    _tide = tide;
    _update();
  }

  // Kept to one screen of a foldable, never across its hinge, as a Material bottom sheet is.
  Widget build(final BuildContext context, final Animation<double> transition) =>
      DisplayFeatureSubScreen(child: Builder(builder: (final BuildContext context) => _build(context, transition)));

  Widget _build(final BuildContext context, final Animation<double> transition) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    // With reduced motion the sheet is simply there: its route still takes its time, but nothing slides.
    final Animation<double> animation = mediaQuery.disableAnimations ? kAlwaysCompleteAnimation : transition;
    // Built inside the sheet, so its context can close the sheet.
    Widget sheet = Builder(builder: builder);
    // A sheet stops short of the status bar unless it keeps the top coast.
    final double top = keepsTopCoast ? 0.0 : mediaQuery.padding.top;
    sheet = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity, maxHeight: math.max(0.0, mediaQuery.size.height - top)),
      child: sheet,
    );
    final double tide = mediaQuery.viewInsets.bottom;
    return _SheetHostScope(
      host: this,
      available: math.max(0.0, mediaQuery.size.height - tide - top),
      tide: tide,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: !keepsTopCoast,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: animation,
            builder: (final BuildContext context, final Widget? child) => ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _reveal.transform(animation.value),
                child: child,
              ),
            ),
            child: _MeasureHeight(
              onHeight: measured,
              onTop: (final double top) => reportTop(top, fromSheet: false),
              child: sheet,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHostScope extends InheritedWidget {
  const _SheetHostScope({required this.host, required this.available, required this.tide, required super.child});

  final _SheetHost host;
  final double available;
  final double tide;

  static _SheetHostScope? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SheetHostScope>();

  void reportExtent(final double extent) => host.reportExtent(extent, available, tide);

  void close() => host.close?.call();

  @override
  bool updateShouldNotify(final _SheetHostScope oldWidget) => false;
}

class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({this.onHeight, required this.onTop, super.child});

  final ValueChanged<double>? onHeight;

  /// Told where this box's top is in global coordinates, after each paint.
  final ValueChanged<double> onTop;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderMeasureHeight(onHeight, onTop);

  @override
  void updateRenderObject(final BuildContext context, final _RenderMeasureHeight renderObject) {
    renderObject
      ..onHeight = onHeight
      ..onTop = onTop;
  }
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight, this.onTop);

  ValueChanged<double>? onHeight;
  ValueChanged<double> onTop;
  double? _lastTop;

  @override
  void performLayout() {
    super.performLayout();
    final double height = size.height;
    // Breakwater listeners lay out other routes, so tell them after this pass.
    final ValueChanged<double>? onHeight = this.onHeight;
    if (onHeight != null) {
      WidgetsBinding.instance.addPostFrameCallback((final Duration _) => onHeight(height));
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    super.paint(context, offset);
    final double top = localToGlobal(Offset.zero).dy;
    if (top != _lastTop) {
      _lastTop = top;
      WidgetsBinding.instance.addPostFrameCallback((final Duration _) => onTop(top));
    }
  }
}

class _HarborSheetRoute<T> extends PopupRoute<T> {
  _HarborSheetRoute({required this.host, required this.barrierColor, required this.barrierLabel, super.settings});

  final _SheetHost host;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  final String barrierLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  void install() {
    super.install();
    host
      ..close = () {
        if (isActive && isCurrent) {
          navigator?.pop();
        }
      }
      ..slide = controller
      ..attach();
    animation!.addListener(_tick);
  }

  void _tick() => host.progress = animation!.value;

  @override
  void dispose() {
    animation?.removeListener(_tick);
    host.detach();
    super.dispose();
  }

  @override
  Widget buildPage(final BuildContext context, final Animation<double> animation, final Animation<double> secondaryAnimation) =>
      host.build(context, animation);
}

class _NonModalSheet<T> {
  _NonModalSheet({required this.host, required this.overlay, required this.route});

  final _SheetHost host;
  final OverlayState overlay;

  /// The page that opened the sheet. Tied to it with a local history entry, so back (and a
  /// pop) closes the sheet before the page, and the iOS back swipe stands aside while it is up.
  ///
  /// NOT COVERED: a `PopScope` inside the sheet. It registers with the nearest ModalRoute, and
  /// a sheet with no barrier deliberately is not one; wrap the PAGE in the PopScope instead.
  final ModalRoute<Object?>? route;
  LocalHistoryEntry? _history;
  late final AnimationController _animation = AnimationController(
    vsync: overlay,
    duration: const Duration(milliseconds: 280),
  );
  OverlayEntry? _entry;
  final Completer<T?> _done = Completer<T?>();

  Future<T?> open() {
    host
      ..close = _close
      ..slide = _animation
      ..attach();
    _animation.addListener(() => host.progress = _animation.value);
    final ModalRoute<Object?>? route = this.route;
    _entry = OverlayEntry(
      builder: (final BuildContext context) {
        final Widget sheet = host.build(context, _animation);
        if (route == null) {
          return sheet;
        }
        // Hidden, and out of reach, while another page is on top of the one that opened it.
        return ListenableBuilder(
          listenable: Listenable.merge(<Listenable?>[route.animation, route.secondaryAnimation]),
          builder: (final BuildContext context, final Widget? child) {
            if (!route.isActive) {
              WidgetsBinding.instance.addPostFrameCallback((final Duration _) => closeNow());
            }
            return Visibility(visible: route.isCurrent, maintainState: true, child: child!);
          },
          child: sheet,
        );
      },
    );
    overlay.insert(_entry!);
    if (route != null) {
      _history = LocalHistoryEntry(
        onRemove: () {
          _history = null;
          unawaited(_close());
        },
      );
      route.addLocalHistoryEntry(_history!);
      // Popped or replaced: the sheet goes with it.
      unawaited(route.completed.whenComplete(closeNow));
    }
    _animation.forward();
    return _done.future;
  }

  /// Takes the sheet's entry out of its page's history, when it closes some other way.
  void _leaveHistory() {
    final LocalHistoryEntry? history = _history;
    _history = null;
    final ModalRoute<Object?>? route = this.route;
    if (history != null && route != null && route.isActive) {
      route.removeLocalHistoryEntry(history);
    }
  }

  bool _closing = false;

  /// Removes the sheet at once, with no animation: its page is leaving.
  void closeNow() {
    final OverlayEntry? entry = _entry;
    if (entry == null) {
      return;
    }
    _entry = null;
    _closing = true;
    _leaveHistory();
    host.detach();
    _animation.stop();
    try {
      entry.remove();
    } on Object {
      // The overlay is already going.
    }
    _animation.dispose();
    if (!_done.isCompleted) {
      _done.complete(null);
    }
  }

  Future<void> _close() async {
    if (_entry == null || _closing) {
      return;
    }
    _closing = true;
    _leaveHistory();
    host.detach();
    if (overlay.mounted) {
      await _animation.reverse();
    }
    _entry?.remove();
    _entry = null;
    _animation.dispose();
    if (!_done.isCompleted) {
      _done.complete(null);
    }
  }
}

/// Closes the sheet [context] is in, whichever way it was opened.
void closeHarborSheet(final BuildContext context) {
  final _SheetHostScope? scope = _SheetHostScope.maybeOf(context);
  if (scope != null && scope.host.close != null) {
    scope.close();
    return;
  }
  Navigator.maybePop(context);
}
