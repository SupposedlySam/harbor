import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'dock.dart';
import 'edge.dart';

/// One harbor on a chart, in global coordinates.
@immutable
class HarborChartEntry {
  const HarborChartEntry({
    required this.label,
    required this.depth,
    required this.frame,
    required this.body,
    required this.clearWater,
    required this.docks,
    required this.obstruction,
    required this.tide,
  });

  final String label;

  /// How many harbors this one sits inside.
  final int depth;
  final Rect frame;
  final Rect body;
  final Rect clearWater;
  final List<HarborDockRecord> docks;
  final EdgeInsetsDirectional obstruction;
  final double tide;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'depth': depth,
    'frame': _rect(frame),
    'body': _rect(body),
    'clearWater': _rect(clearWater),
    'tide': tide,
    'obstruction': <String, double>{
      for (final HarborEdge e in HarborEdge.values) e.name: HarborEdges.of(obstruction, e),
    },
    'docks': <Map<String, Object?>>[
      for (final HarborDockRecord d in docks)
        <String, Object?>{
          'label': d.label,
          'edge': d.edge.name,
          'kind': d.kind.name,
          'state': d.state.name,
          'tide': '${d.tide}'.split('.').last,
          'extent': d.extent,
          'restingExtent': d.restingExtent,
          'rect': _rect(d.rect),
        },
    ],
  };

  static Map<String, double> _rect(final Rect r) => <String, double>{
    'left': r.left,
    'top': r.top,
    'width': r.width,
    'height': r.height,
  };
}

/// The harbor chart: who holds which edge, at which layer, in every harbor
/// in a view.
abstract final class HarborChart {
  /// Every harbor in [context]'s view, outermost first, from its last layout.
  static List<HarborChartEntry> snapshot(final BuildContext context) {
    final HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    return fleet == null ? const <HarborChartEntry>[] : snapshotOf(fleet);
  }

  static List<HarborChartEntry> snapshotOf(final HarborFleet fleet) {
    final List<HarborChartEntry> entries = <HarborChartEntry>[];
    for (final HarborController harbor in fleet.harbors) {
      final RenderBox? box = harbor.renderBox;
      final HarborLayoutRecord? layout = harbor.lastLayout;
      if (box == null || layout == null || !box.attached || !box.hasSize) {
        continue;
      }
      final Matrix4 toGlobal = box.getTransformTo(null);
      Rect global(final Rect r) => MatrixUtils.transformRect(toGlobal, r);
      int depth = 0;
      for (HarborController? p = harbor.parent; p != null; p = p.parent) {
        depth++;
      }
      entries.add(
        HarborChartEntry(
          label: harbor.debugLabel ?? 'harbor',
          depth: depth,
          frame: global(layout.frame),
          body: global(layout.body),
          clearWater: global(layout.clearWater),
          docks: <HarborDockRecord>[
            for (final HarborDockRecord d in layout.docks)
              HarborDockRecord(
                edge: d.edge,
                kind: d.kind,
                rect: global(d.rect),
                extent: d.extent,
                restingExtent: d.restingExtent,
                state: d.state,
                tide: d.tide,
                label: d.label,
              ),
          ],
          obstruction: layout.obstruction,
          tide: layout.tide,
        ),
      );
    }
    return entries;
  }

  static HarborFleet? _serviceFleet;
  static bool _registered = false;

  /// Serves the chart of [fleet] over the VM service as `ext.harbor.chart`, so
  /// a tool driving the app can ask where everything is. Debug and profile only.
  static void serve(final HarborFleet fleet) {
    _serviceFleet = fleet;
    if (_registered || kReleaseMode) {
      return;
    }
    _registered = true;
    try {
      developer.registerExtension('ext.harbor.chart', (final String method, final Map<String, String> params) async {
        final HarborFleet? f = _serviceFleet;
        final List<Map<String, Object?>> json = f == null
            ? const <Map<String, Object?>>[]
            : <Map<String, Object?>>[for (final HarborChartEntry e in snapshotOf(f)) e.toJson()];
        return developer.ServiceExtensionResponse.result(jsonEncode(<String, Object?>{'harbors': json}));
      });
    } on Object {
      // Already registered in this isolate.
    }
  }
}

/// Draws the chart over [child]: every dock's ground (piers in teal, quays in
/// sand), each harbor's clear water outlined, and the tide in blue.
class HarborChartOverlay extends StatefulWidget {
  const HarborChartOverlay({super.key, this.enabled = true, this.labelStyle, required this.child});

  final bool enabled;

  /// Merged over the dock labels' own style (9 pt, white on a dark band).
  ///
  /// Set a `fontFamily` the test has loaded to make the labels readable in
  /// widget tests and goldens: with none, `flutter_test` draws them in its box
  /// test font, and the labels carry each dock's extent.
  final TextStyle? labelStyle;

  final Widget child;

  @override
  State<HarborChartOverlay> createState() => _HarborChartOverlayState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
    properties.add(DiagnosticsProperty<TextStyle>('labelStyle', labelStyle, defaultValue: null));
  }
}

class _HarborChartOverlayState extends State<HarborChartOverlay> with SingleTickerProviderStateMixin {
  /// The fleet the harbors beneath join, when this overlay sits above the
  /// outermost harbor (as it does in `MaterialApp.builder`).
  HarborFleet? _ownFleet;

  late final Ticker _ticker = createTicker((final Duration _) => _repaint.value++);
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(final HarborChartOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    if (fleet == null) {
      if (_ownFleet == null) {
        _ownFleet = HarborFleet();
        HarborChart.serve(_ownFleet!);
      }
      fleet = _ownFleet;
    }
    final Widget painted = CustomPaint(
      foregroundPainter: widget.enabled ? _ChartPainter(context, fleet!, _repaint, labelStyle: widget.labelStyle) : null,
      child: widget.child,
    );
    return _ownFleet == null ? painted : HarborFleetScope(fleet: _ownFleet!, child: painted);
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.context, this.fleet, final Listenable repaint, {final TextStyle? labelStyle})
    : labelStyle = _labelStyle.merge(labelStyle),
      super(repaint: repaint);

  static const TextStyle _labelStyle = TextStyle(fontSize: 9, color: Color(0xFFFFFFFF), backgroundColor: Color(0x99000000));

  final BuildContext context;
  final HarborFleet fleet;
  final TextStyle labelStyle;

  @override
  void paint(final Canvas canvas, final Size size) {
    final RenderObject? self = context.findRenderObject();
    if (self is! RenderBox || !self.attached) {
      return;
    }
    // Global rects mapped into this overlay's own coordinates, so a scale
    // between the overlay and the screen (a preview, a scale model) is honored.
    Rect local(final Rect global) => Rect.fromPoints(self.globalToLocal(global.topLeft), self.globalToLocal(global.bottomRight));
    for (final HarborChartEntry entry in HarborChart.snapshotOf(fleet)) {
      final Rect clear = local(entry.clearWater);
      canvas.drawRect(
        clear.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xCCFFD54F),
      );
      for (final HarborDockRecord dock in entry.docks) {
        final Rect r = local(dock.rect);
        final Color color = dock.kind == HarborDockKind.pier ? const Color(0x5526C6DA) : const Color(0x55E0B070);
        canvas.drawRect(r, Paint()..color = color);
        canvas.drawRect(
          r.deflate(0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color.withValues(alpha: 1.0),
        );
        final TextPainter label = TextPainter(
          text: TextSpan(
            text: '${dock.label ?? dock.kind.name} ${dock.extent.toStringAsFixed(0)}',
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, r.topLeft + const Offset(2, 2));
      }
      if (entry.tide > 0) {
        final Rect frame = local(entry.frame);
        canvas.drawRect(
          Rect.fromLTRB(frame.left, frame.bottom - entry.tide, frame.right, frame.bottom),
          Paint()..color = const Color(0x332196F3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(final _ChartPainter oldDelegate) => true;
}
