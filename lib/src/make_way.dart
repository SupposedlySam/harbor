import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'dock.dart';
import 'edge.dart';

/// Asks the docks on [edge] to make way while [active]: to go dark (keep their
/// ground) or withdraw (give it back). For a panel that takes over the bottom
/// edge, or lyrics that need the whole screen.
///
/// The claim goes to the nearest harbor above, from the closest outward, that
/// has a dock on [edge], and is counted: the dock comes back only once every
/// claim on it is released. It is released when this widget leaves the tree.
class HarborMakeWay extends StatefulWidget {
  const HarborMakeWay({
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
  State<HarborMakeWay> createState() => _HarborMakeWayState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborEdge>('edge', edge));
    properties.add(EnumProperty<HarborYield>('mode', mode, defaultValue: HarborYield.withdraw));
    properties.add(FlagProperty('active', value: active, ifFalse: 'inactive'));
  }
}

class _HarborMakeWayState extends State<HarborMakeWay> {
  HarborClaim? _claim;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(final HarborMakeWay oldWidget) {
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
    _claim = HarborController.maybeOf(context)?.makeWay(widget.edge, mode: widget.mode);
  }

  @override
  void dispose() {
    _claim?.release();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

/// A pontoon: a dock moored to the nearest harbor from deeper in the tree,
/// for a bar that belongs to the content rather than to the page (an unsaved
/// changes bar, a hint, a floating pill). It joins the docks on [edge],
/// innermost, measured and stacked like any other, and leaves when this widget
/// does. It is built where the harbor's docks are, so it sees the harbor's
/// inherited widgets, not this widget's.
///
/// A pontoon joins on the frame after it arrives, and its content follows
/// changes a frame behind.
class HarborPontoon extends StatefulWidget {
  const HarborPontoon({super.key, required this.edge, required this.dock, this.active = true, required this.child});

  final HarborEdge edge;
  final HarborDock dock;
  final bool active;

  /// The content this pontoon belongs to. Built in place.
  final Widget child;

  @override
  State<HarborPontoon> createState() => _HarborPontoonState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborEdge>('edge', edge));
    properties.add(DiagnosticsProperty<HarborDock>('dock', dock));
    properties.add(FlagProperty('active', value: active, ifFalse: 'inactive'));
  }
}

class _HarborPontoonState extends State<HarborPontoon> {
  HarborController? _controller;
  Object? _handle;

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
  void didUpdateWidget(final HarborPontoon oldWidget) {
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
    final Object? handle = _handle;
    if (handle == null) {
      _handle = controller.addPontoon(widget.edge, widget.dock);
    } else {
      controller.updatePontoon(handle, widget.edge, widget.dock);
    }
  }

  void _remove() {
    final Object? handle = _handle;
    if (handle != null) {
      _controller?.removePontoon(handle);
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
