import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'dock.dart';
import 'edge.dart';

/// Asks the bars on [edge] to hide while [active]: to go dark (keep their
/// space) or withdraw (give it back). For a panel that takes over the bottom
/// edge, or lyrics that need the whole screen.
///
/// The claim goes to the nearest frame above, from the closest outward, that
/// has a bar on [edge], and is counted: the bar comes back only once every
/// claim on it is released. It is released when this widget leaves the tree.
///
/// A claim taken while the tree is being built reaches the frame in the next
/// frame drawn: the frame sits above this widget and has already been built in
/// this one, so for one frame drawn the bar is still in place and everything
/// reads the old padding. Then the bar goes, or slides out over its duration. To
/// hide it in the frame drawn as a mode starts, take the claim where the mode
/// starts, in the tap that opens it, with `HarborFrame.of(context).hideBar(edge)`,
/// and release it when the mode ends; a claim taken outside a build is applied
/// in the next frame drawn. A page that opens with the bar already gone builds
/// the bar with `state: HarborBarState.withdrawn` instead.
///
/// See also:
///
///  * [Visibility] with `maintainSize`, which a dark bar behaves like. Flutter has no way to ask a
///    `Scaffold`'s bars to hide from inside its body.
class HarborHideBar extends StatefulWidget {
  const HarborHideBar({
    super.key,
    required this.edge,
    this.mode = HarborYield.withdraw,
    this.active = true,
    required this.child,
  });

  final HarborEdge edge;
  final HarborYield mode;
  final bool active;
  final Widget child;

  @override
  State<HarborHideBar> createState() => _HarborMakeWayState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborEdge>('edge', edge));
    properties.add(EnumProperty<HarborYield>('mode', mode, defaultValue: HarborYield.withdraw));
    properties.add(FlagProperty('active', value: active, ifFalse: 'inactive'));
  }
}

class _HarborMakeWayState extends State<HarborHideBar> {
  HarborClaim? _claim;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(final HarborHideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.edge != widget.edge || oldWidget.mode != widget.mode || oldWidget.active != widget.active) {
      _claim?.release();
      _claim = null;
      _sync();
    }
  }

  void _sync() {
    if (!widget.active) {
      _claim?.release();
      _claim = null;
      return;
    }
    if (_claim != null) {
      return;
    }
    _claim = HarborController.maybeOf(context)?.hideBar(widget.edge, mode: widget.mode);
  }

  @override
  void dispose() {
    _claim?.release();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

/// A bar attached to the nearest frame from deeper in the tree, for a bar that
/// belongs to the content rather than to the page (an unsaved changes bar, a
/// hint, a floating pill). It joins the bars on [edge], innermost, measured and
/// stacked like any other, and leaves when this widget does. It is built where
/// the frame's bars are, so it sees the frame's inherited widgets, not this
/// widget's.
///
/// An attached bar joins in the frame drawn after it arrives, and its content
/// follows changes a drawn frame behind.
///
/// See also:
///
///  * `ScaffoldState.showBottomSheet`, which also puts a widget into an ancestor's frame from deep in
///    the tree.
class HarborAttachedBar extends StatefulWidget {
  const HarborAttachedBar({super.key, required this.edge, required this.bar, this.active = true, required this.child});

  final HarborEdge edge;

  /// The bar to attach.
  final HarborBar bar;

  /// The old name of [bar].
  @Deprecated('Renamed bar. `dart fix` applies it.')
  HarborBar get dock => bar;
  final bool active;

  /// The content this bar belongs to. Built in place.
  final Widget child;

  @override
  State<HarborAttachedBar> createState() => _HarborPontoonState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborEdge>('edge', edge));
    properties.add(DiagnosticsProperty<HarborBar>('bar', bar));
    properties.add(FlagProperty('active', value: active, ifFalse: 'inactive'));
  }
}

class _HarborPontoonState extends State<HarborAttachedBar> {
  HarborController? _controller;
  HarborAttachedBarHandle? _handle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final HarborController? controller = HarborController.maybeOf(context);
    if (!identical(controller, _controller)) {
      _remove();
      _controller = controller;
    }
    _sync();
  }

  @override
  void didUpdateWidget(final HarborAttachedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final HarborController? controller = _controller;
    if (controller == null) {
      return;
    }
    if (!widget.active) {
      _remove();
      return;
    }
    final HarborAttachedBarHandle? handle = _handle;
    if (handle == null) {
      _handle = controller.attachBar(widget.edge, widget.bar);
    } else {
      controller.updateAttachedBar(handle, widget.edge, widget.bar);
    }
  }

  void _remove() {
    final HarborAttachedBarHandle? handle = _handle;
    if (handle != null) {
      _controller?.detachBar(handle);
      _handle = null;
    }
  }

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

/// The old name of [HarborAttachedBar], which takes the old name of its bar.
///
/// A subclass rather than a typedef, so the new constructor can keep [HarborAttachedBar.bar]
/// required.
@Deprecated('Renamed HarborAttachedBar. `dart fix` applies it.')
class HarborPontoon extends HarborAttachedBar {
  /// The old name of [HarborAttachedBar.new].
  @Deprecated('Renamed HarborAttachedBar. `dart fix` applies it.')
  const HarborPontoon({
    super.key,
    required super.edge,
    @Deprecated('Renamed bar. `dart fix` applies it.') final HarborBar? dock,
    super.active,
    required super.child,
  }) : assert(dock != null, 'dock is required.'),
       super(bar: dock ?? const HarborBar.reserve(extent: 0.0));
}
