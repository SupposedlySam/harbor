import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bar.dart';
import 'controller.dart';
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
    final HarborBarState state = HarborBarState.withdrawn,
    @Deprecated('Use state: HarborBarState.dark or .withdrawn. `dart fix` applies it. Deprecated after 0.9.1.')
    final HarborYield? mode,
    this.active = true,
    required this.child,
  }) : assert(
         state != HarborBarState.open,
         'HarborHideBar hides a bar dark or withdrawn; set active: false to open it.',
       ),
       assert(
         mode == null ||
             identical(state, HarborBarState.withdrawn) ||
             identical(state, HarborBarState.dark) == identical(mode, HarborYield.dark),
         'state and the deprecated mode disagree. Give state alone.',
       ),
       state = mode == null
           ? state
           : identical(mode, HarborYield.dark)
           ? HarborBarState.dark
           : HarborBarState.withdrawn;

  final HarborEdge edge;

  /// How the bars hide: [HarborBarState.dark] keeps their space, [HarborBarState.withdrawn] (the
  /// default) gives it back. Never [HarborBarState.open].
  final HarborBarState state;

  /// The old spelling of [state].
  @Deprecated('Read state. Deprecated after 0.9.1.')
  HarborYield get mode => state == HarborBarState.dark ? HarborYield.dark : HarborYield.withdraw;
  final bool active;
  final Widget child;

  @override
  State<HarborHideBar> createState() => _HarborMakeWayState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborEdge>('edge', edge));
    properties.add(EnumProperty<HarborBarState>('state', state, defaultValue: HarborBarState.withdrawn));
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
    if (oldWidget.edge != widget.edge || oldWidget.state != widget.state || oldWidget.active != widget.active) {
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
    _claim = HarborController.maybeOf(context)?.hideBar(widget.edge, state: widget.state);
  }

  @override
  void dispose() {
    _claim?.release();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}
