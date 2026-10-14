import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'coast.dart';

/// A scaled screen: lays [child] out on a fixed reference screen (a TV's
/// 1200×675, say) and scales it to fit the real one, letterboxed.
///
/// Everything inside sees the reference size, and the real screen's insets
/// re-based into the scaled screen: cut to the part of it they actually reach
/// and scaled into its coordinates. A notch beside a letterboxed screen doesn't
/// reach it, so its system edge there is zero. Then [systemEdges] applies, so a
/// scaled screen can add a title-safe band of its own.
///
/// Mount it above the `Navigator` (in `MaterialApp.builder`) so routes, dialogs
/// and sheets are all inside the scaled screen.
///
/// See also:
///
///  * [FittedBox], which scales the same way but leaves the real screen's `MediaQuery` in place.
class HarborScaledScreen extends StatelessWidget {
  const HarborScaledScreen({
    super.key,
    required this.referenceSize,
    this.devicePixelRatio,
    final HarborSystemEdges systemEdges = HarborSystemEdges.ambient,
    @Deprecated('Renamed systemEdges. `dart fix` applies it.') final HarborSystemEdges? coast,
    this.letterbox = const Color(0xFF000000),
    required this.child,
  }) : systemEdges = coast ?? systemEdges;

  final Size referenceSize;

  /// The pixel ratio the scaled screen reports; null scales the real one.
  final double? devicePixelRatio;

  final HarborSystemEdges systemEdges;

  /// The old name of [systemEdges].
  @Deprecated('Renamed systemEdges. `dart fix` applies it.')
  HarborSystemEdges get coast => systemEdges;
  final Color letterbox;
  final Widget child;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Size>('referenceSize', referenceSize));
    properties.add(DoubleProperty('devicePixelRatio', devicePixelRatio, defaultValue: null));
    properties.add(
      DiagnosticsProperty<HarborSystemEdges>('systemEdges', systemEdges, defaultValue: HarborSystemEdges.ambient),
    );
    properties.add(ColorProperty('letterbox', letterbox, defaultValue: const Color(0xFF000000)));
  }

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData outer = MediaQuery.of(context);
    return ColoredBox(
      color: letterbox,
      child: LayoutBuilder(
        builder: (final BuildContext context, final BoxConstraints constraints) {
          final Size host = constraints.biggest;
          final double scale = math.min(host.width / referenceSize.width, host.height / referenceSize.height);
          final Size rendered = referenceSize * scale;
          final Offset origin = Offset((host.width - rendered.width) / 2, (host.height - rendered.height) / 2);
          EdgeInsets reach(final EdgeInsets insets) => EdgeInsets.fromLTRB(
            math.max(0.0, insets.left - origin.dx) / scale,
            math.max(0.0, insets.top - origin.dy) / scale,
            math.max(0.0, insets.right - (host.width - origin.dx - rendered.width)) / scale,
            math.max(0.0, insets.bottom - (host.height - origin.dy - rendered.height)) / scale,
          );
          final MediaQueryData model = outer.copyWith(
            size: referenceSize,
            devicePixelRatio: devicePixelRatio ?? outer.devicePixelRatio * scale,
            padding: reach(outer.padding),
            viewPadding: reach(outer.viewPadding),
            viewInsets: reach(outer.viewInsets),
          );
          return Center(
            child: SizedBox.fromSize(
              size: rendered,
              child: FittedBox(
                child: SizedBox.fromSize(
                  size: referenceSize,
                  child: MediaQuery(data: systemEdges.apply(model, Directionality.of(context)), child: child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
