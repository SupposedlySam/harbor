import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/docks.dart';
import '../art/palette.dart';
import '../game/fleet.dart';
import 'art/platform_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Coast and charts: where insets come from, TV, and seeing it all.
final List<GuideEntry> platformEntries = <GuideEntry>[
  GuideEntry(
    id: 'coast',
    className: 'HarborCoast',
    group: GuideGroup.platform,
    realWorld: 'A rugged coastline of cliffs and a beach',
    art: (final BuildContext context) => const CoastArt(),
    page: (final BuildContext context) => const CoastEntry(),
  ),
  GuideEntry(
    id: 'coast-title-safe',
    className: 'HarborCoast.titleSafe',
    group: GuideGroup.platform,
    realWorld: 'An old TV set with the broadcast title-safe frame marked',
    art: (final BuildContext context) => const TitleSafeTvArt(),
    page: (final BuildContext context) => const TitleSafeEntry(),
  ),
  GuideEntry(
    id: 'scale-model',
    className: 'HarborScaleModel',
    group: GuideGroup.platform,
    realWorld: 'A ship in a bottle',
    art: (final BuildContext context) => const ShipInBottleArt(),
    page: (final BuildContext context) => const ScaleModelEntry(),
  ),
  GuideEntry(
    id: 'edge',
    className: 'HarborEdge',
    group: GuideGroup.platform,
    realWorld: 'A ship’s port and starboard running lights',
    art: (final BuildContext context) => const RunningLightsArt(),
    page: (final BuildContext context) => const EdgeEntry(),
  ),
  GuideEntry(
    id: 'chart',
    className: 'HarborChart',
    group: GuideGroup.platform,
    realWorld: 'A nautical chart with a compass rose and soundings',
    art: (final BuildContext context) => const NauticalChartArt(),
    page: (final BuildContext context) => const ChartEntry(),
  ),
  GuideEntry(
    id: 'sea-trial',
    className: 'pumpSeaTrial',
    group: GuideGroup.platform,
    realWorld: 'A new ship on her sea trials, a tug alongside',
    art: (final BuildContext context) => const SeaTrialsArt(),
    page: (final BuildContext context) => const SeaTrialEntry(),
  ),
  GuideEntry(
    id: 'wake-painter',
    className: 'HarborWakePainter',
    group: GuideGroup.platform,
    realWorld: 'The V-shaped wake spreading behind a boat',
    art: (final BuildContext context) => const WakeArt(),
    page: (final BuildContext context) => const WakePainterEntry(),
  ),
];

String _n(final double v) => v.toStringAsFixed(0);

String _insets(final EdgeInsets e) => 'T ${_n(e.top)} · B ${_n(e.bottom)} · L ${_n(e.left)} · R ${_n(e.right)}';

/// Reports the `MediaQuery.size` where it sits to the readings.
class _SizeProbe extends StatelessWidget {
  const _SizeProbe({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final StageSettings? settings = StageScope.settingsOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (final Duration _) => settings?.report(label, 'MediaQuery.size  ${_n(size.width)} × ${_n(size.height)}'),
    );
    return child;
  }
}

// ─── HarborCoast ──────────────────────────────────────────────────────────────

enum _CoastChoice { ambient, fixed, none }

/// `HarborCoast`: where a harbor's coast comes from.
class CoastEntry extends StatefulWidget {
  const CoastEntry({super.key});

  @override
  State<CoastEntry> createState() => _CoastEntryState();
}

class _CoastEntryState extends State<CoastEntry> {
  _CoastChoice _choice = _CoastChoice.ambient;

  static const EdgeInsetsDirectional _fixedInsets = EdgeInsetsDirectional.symmetric(vertical: 24);

  HarborCoast get _coast => switch (_choice) {
    _CoastChoice.ambient => HarborCoast.ambient,
    _CoastChoice.fixed => const HarborCoast.fixed(_fixedInsets),
    _CoastChoice.none => HarborCoast.none,
  };

  String _label(final _CoastChoice c) => switch (c) {
    _CoastChoice.ambient => 'HarborCoast.ambient',
    _CoastChoice.fixed => 'HarborCoast.fixed(...)',
    _CoastChoice.none => 'HarborCoast.none',
  };

  String get _code => switch (_choice) {
    _CoastChoice.ambient => 'HarborCoast.ambient',
    _CoastChoice.fixed => 'HarborCoast.fixed(EdgeInsetsDirectional.symmetric(vertical: 24))',
    _CoastChoice.none => 'HarborCoast.none',
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborCoast',
    focus: const StageFocus.top(380),
    realWorld:
        'The coast is the land at the water’s edge: cliffs, beaches and rocks. However fine the harbor, no boat can '
        'moor on the cliffs; the sea simply stops there.',
    inYourApp:
        'The part of the screen the platform keeps: the status bar, the home indicator, a notch, a TV’s overscan. '
        'ambient takes MediaQuery as the platform reports it (the default), fixed(...) says exactly what the coast is '
        'whatever the device says, and none has no coast and no tide at all, for a postcard frame that must render the '
        'same everywhere (goldens, embeds). Docks absorb it; moored content keeps clear of it.',
    art: const CoastArt(),
    controls: <Widget>[
      ChoiceControl<_CoastChoice>(
        label: 'coast',
        values: _CoastChoice.values,
        value: _choice,
        labelOf: _label,
        onChanged: (final _CoastChoice c) => setState(() => _choice = c),
      ),
      Text(
        'Flip the stage’s Status bar and Home indicator switches: ambient follows them, fixed and none don’t.',
        style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
      ),
    ],
    code:
        'Harbor(\n'
        '  coast: $_code,\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  bottom: [HarborDock.quay(child: Bar())],\n'
        '  body: HarborFairway(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => StageProbe(
      label: 'The stage (what the platform reports)',
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Harbor(
            key: const ValueKey<String>('postcard'),
            coast: _coast,
            debugLabel: 'postcard',
            top: <HarborDock>[
              HarborDock.pier(
                debugLabel: 'header',
                backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
                child: StageHeader(key: const ValueKey<String>('coast header'), title: _label(_choice)),
              ),
            ],
            bottom: const <HarborDock>[
              HarborDock.quay(
                debugLabel: 'bar',
                backdrop: ColoredBox(color: Palette.night),
                child: StageBar(key: ValueKey<String>('coast bar'), label: 'HarborDock.quay'),
              ),
            ],
            body: StageProbe(
              label: 'Inside Harbor(coast: ${_label(_choice)})',
              child: HarborFairway(
                slivers: <Widget>[
                  SliverList.builder(
                    itemCount: 20,
                    itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
                  ),
                ],
              ),
            ),
          ),
          IgnorePointer(child: _CoastBands(coast: _coast)),
        ],
      ),
    ),
  );
}

/// Shades the coast a [HarborCoast] yields, as sand at the frame's edges, and
/// draws the postcard's frame.
class _CoastBands extends StatelessWidget {
  const _CoastBands({required this.coast});

  final HarborCoast coast;

  @override
  Widget build(final BuildContext context) {
    final EdgeInsets padding = coast.apply(MediaQuery.of(context), Directionality.of(context)).padding;
    return CustomPaint(key: const ValueKey<String>('coast bands'), painter: _CoastBandsPainter(padding));
  }
}

class _CoastBandsPainter extends CustomPainter {
  _CoastBandsPainter(this.padding);

  final EdgeInsets padding;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint sand = Paint()..color = const Color(0x55E3CF9A);
    final Paint edge = Paint()
      ..color = const Color(0xCCE3CF9A)
      ..strokeWidth = 2;
    void band(final Rect r, final Offset a, final Offset b, final String label) {
      if (r.isEmpty) {
        return;
      }
      canvas
        ..drawRect(r, sand)
        ..drawLine(a, b, edge);
      final TextPainter text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'Menlo',
            fontSize: 11,
            color: Color(0xFF3E2A18),
            backgroundColor: Color(0xCCE3CF9A),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(r.right - text.width - 8, r.center.dy - text.height / 2));
    }

    band(
      Rect.fromLTWH(0, 0, size.width, padding.top),
      Offset(0, padding.top),
      Offset(size.width, padding.top),
      'coast ${_n(padding.top)}',
    );
    band(
      Rect.fromLTWH(0, size.height - padding.bottom, size.width, padding.bottom),
      Offset(0, size.height - padding.bottom),
      Offset(size.width, size.height - padding.bottom),
      'coast ${_n(padding.bottom)}',
    );
    band(
      Rect.fromLTWH(0, 0, padding.left, size.height),
      Offset(padding.left, 0),
      Offset(padding.left, size.height),
      '',
    );
    band(
      Rect.fromLTWH(size.width - padding.right, 0, padding.right, size.height),
      Offset(size.width - padding.right, 0),
      Offset(size.width - padding.right, size.height),
      '',
    );
    // The postcard's own deckle edge.
    canvas.drawRect(
      (Offset.zero & size).deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Palette.sail.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(final _CoastBandsPainter oldDelegate) => oldDelegate.padding != padding;
}

// ─── HarborCoast.titleSafe + HarborTitleSafe ─────────────────────────────────

enum _SafeChoice { fraction, fixedEven, fixedRail }

/// `HarborCoast.titleSafe`: a TV's title-safe band as coast.
class TitleSafeEntry extends StatefulWidget {
  const TitleSafeEntry({super.key});

  @override
  State<TitleSafeEntry> createState() => _TitleSafeEntryState();
}

class _TitleSafeEntryState extends State<TitleSafeEntry> {
  _SafeChoice _choice = _SafeChoice.fraction;
  double _percent = 5;

  HarborTitleSafe get _safe => switch (_choice) {
    _SafeChoice.fraction => HarborTitleSafe.fraction(_percent / 100),
    _SafeChoice.fixedEven => const HarborTitleSafe.fixed(EdgeInsetsDirectional.symmetric(horizontal: 48, vertical: 27)),
    _SafeChoice.fixedRail => const HarborTitleSafe.fixed(EdgeInsetsDirectional.fromSTEB(96, 27, 48, 27)),
  };

  String _label(final _SafeChoice c) => switch (c) {
    _SafeChoice.fraction => 'fraction',
    _SafeChoice.fixedEven => 'fixed 48 · 27',
    _SafeChoice.fixedRail => 'fixed start 96',
  };

  String get _safeCode => switch (_choice) {
    _SafeChoice.fraction => 'HarborTitleSafe.fraction(${(_percent / 100).toStringAsFixed(2)})',
    _SafeChoice.fixedEven => 'HarborTitleSafe.fixed(EdgeInsetsDirectional.symmetric(horizontal: 48, vertical: 27))',
    _SafeChoice.fixedRail => 'HarborTitleSafe.fixed(EdgeInsetsDirectional.fromSTEB(96, 27, 48, 27))',
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborCoast.titleSafe',
    device: StageDevice.television,
    tide: false,
    realWorld:
        'Old tube televisions overscanned: the picture ran past the edges of the glass, and every set cropped a little '
        'differently. Broadcasters drew a title-safe frame inside the picture and kept every caption within it.',
    inYourApp:
        'A TV reports no insets, but it may still crop the edges. HarborCoast.titleSafe adds a band on top of what the '
        'platform reports (edge by edge, whichever is larger), so docks absorb it and moored content keeps clear of it '
        'like any other coast. HarborTitleSafe.fraction(0.05) is the broadcast 5% of the width and height; .fixed gives '
        'a band per edge. The stage draws the 5% guides dashed; the brass line is this setting.',
    art: const TitleSafeTvArt(),
    controls: <Widget>[
      ChoiceControl<_SafeChoice>(
        label: 'HarborTitleSafe',
        values: _SafeChoice.values,
        value: _choice,
        labelOf: _label,
        onChanged: (final _SafeChoice c) => setState(() => _choice = c),
      ),
      if (_choice == _SafeChoice.fraction)
        SliderControl(
          label: 'fraction %',
          value: _percent,
          min: 0,
          max: 10,
          divisions: 10,
          onChanged: (final double v) => setState(() => _percent = v),
        ),
    ],
    code:
        'MaterialApp(\n'
        '  builder: (context, child) => HarborSea(\n'
        '    coast: HarborCoast.titleSafe(\n'
        '      $_safeCode,\n'
        '    ),\n'
        '    child: child!,\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) {
      final EdgeInsets band = _safe.resolve(MediaQuery.sizeOf(context)).resolve(Directionality.of(context));
      // The television itself reports no insets; the stage's own 5% coast is
      // taken off so this page's title-safe band is the only one.
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Harbor(
              key: const ValueKey<String>('tv harbor'),
              newPort: true,
              coast: HarborCoast.titleSafe(_safe),
              debugLabel: 'tv page',
              top: <HarborDock>[
                HarborDock.pier(
                  debugLabel: 'header',
                  backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
                  child: const StageHeader(
                    key: ValueKey<String>('tv header'),
                    title: 'HarborCoast.titleSafe',
                    height: 64,
                  ),
                ),
              ],
              body: const StageProbe(
                label: 'TV body',
                child: HarborMoored(
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: StageMarker(
                      key: ValueKey<String>('moored card'),
                      label: 'HarborMoored',
                      width: 320,
                      height: 120,
                      color: Palette.sea,
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(key: const ValueKey<String>('safe line'), painter: _SafeLinePainter(band)),
            ),
          ],
        ),
      );
    },
  );
}

class _SafeLinePainter extends CustomPainter {
  _SafeLinePainter(this.band);

  final EdgeInsets band;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect safe = band.deflateRect(Offset.zero & size);
    final Path outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(safe);
    canvas
      ..drawPath(outside, Paint()..color = const Color(0x22E9B949))
      ..drawRect(
        safe,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Palette.brass,
      );
  }

  @override
  bool shouldRepaint(final _SafeLinePainter oldDelegate) => oldDelegate.band != band;
}

// ─── HarborScaleModel ─────────────────────────────────────────────────────────

enum _Letterbox { black, night }

/// `HarborScaleModel`: a fixed reference screen, scaled to fit.
class ScaleModelEntry extends StatefulWidget {
  const ScaleModelEntry({super.key});

  @override
  State<ScaleModelEntry> createState() => _ScaleModelEntryState();
}

class _ScaleModelEntryState extends State<ScaleModelEntry> {
  bool _titleSafe = false;
  _Letterbox _letterbox = _Letterbox.black;

  Color get _letterboxColor => _letterbox == _Letterbox.black ? const Color(0xFF000000) : Palette.night;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborScaleModel',
    realWorld:
        'A ship in a bottle is a whole ship built at a fixed small scale and slipped through the neck. Every mast and '
        'sail keeps its proportions, and the world outside the glass never touches it.',
    inYourApp:
        'Lays the app out on a fixed reference screen (a TV’s 1200 × 675) and scales it to fit, letterboxed. Inside, '
        'MediaQuery.size is the reference size, and the real insets are re-based: cut to what actually reaches the '
        'model and scaled into it. A notch or home indicator beside a letterboxed model doesn’t reach it, so its coast '
        'is 0 there (turn the phone to landscape: the home indicator does reach). Then its own coast applies.',
    art: const ShipInBottleArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'coast: titleSafe(0.05)',
        value: _titleSafe,
        onChanged: (final bool v) => setState(() => _titleSafe = v),
      ),
      ChoiceControl<_Letterbox>(
        label: 'letterbox',
        values: _Letterbox.values,
        value: _letterbox,
        labelOf: (final _Letterbox l) => l.name,
        onChanged: (final _Letterbox l) => setState(() => _letterbox = l),
      ),
    ],
    code:
        'MaterialApp(\n'
        '  builder: (context, child) => HarborScaleModel(\n'
        '    referenceSize: const Size(1200, 675),\n'
        '${_titleSafe ? '    coast: const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),\n' : ''}'
        '${_letterbox == _Letterbox.night ? '    letterbox: Palette.night,\n' : ''}'
        '    child: HarborSea(child: child!),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => StageProbe(
      label: 'The phone, outside the model',
      child: _SizeProbe(
        label: 'Size outside the model',
        child: HarborScaleModel(
          referenceSize: const Size(1200, 675),
          coast: _titleSafe ? const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)) : HarborCoast.ambient,
          letterbox: _letterboxColor,
          child: const HarborSea(
            margin: EdgeInsetsDirectional.symmetric(horizontal: 32),
            child: StageProbe(
              label: 'Inside HarborScaleModel',
              child: _SizeProbe(label: 'Size inside the model', child: _MiniTv()),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A little TV harbor: a rail, a header and a row of boat cards.
class _MiniTv extends StatelessWidget {
  const _MiniTv();

  @override
  Widget build(final BuildContext context) => ColoredBox(
    key: const ValueKey<String>('scale model screen'),
    color: Palette.deepSea,
    child: Harbor(
      debugLabel: 'scale model',
      start: const <HarborDock>[
        HarborDock.pier(
          debugLabel: 'rail',
          backdrop: PierPlanks(postsToward: AxisDirection.right),
          child: SizedBox(
            key: ValueKey<String>('scale model rail'),
            width: 96,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 48, width: 30, child: LighthouseArt(shining: false)),
                SizedBox(height: 28),
                Icon(Icons.view_module_rounded, color: Palette.brass, size: 36),
                SizedBox(height: 28),
                Icon(Icons.waves_rounded, color: Palette.foam, size: 36),
                SizedBox(height: 28),
                Icon(Icons.nights_stay_rounded, color: Palette.foam, size: 36),
              ],
            ),
          ),
        ),
      ],
      top: const <HarborDock>[
        HarborDock.pier(
          debugLabel: 'header',
          child: StageHeader(
            key: ValueKey<String>('scale model header'),
            title: 'HarborScaleModel · 1200 × 675',
            height: 96,
          ),
        ),
      ],
      body: HarborMoored(
        mooringLine: true,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < 4; i++) ...<Widget>[
              Expanded(child: _TvCard(boat: Fleet.boats[i % Fleet.boats.length])),
              if (i < 3) const SizedBox(width: 24),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TvCard extends StatelessWidget {
  const _TvCard({required this.boat});

  final Boat boat;

  @override
  Widget build(final BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: Palette.sea,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Palette.foam.withValues(alpha: 0.2), width: 2),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      children: <Widget>[
        Expanded(
          child: BoatArt(kind: boat.kind, hull: boat.hull, bob: false),
        ),
        Text(
          boat.name,
          style: const TextStyle(color: Palette.foam, fontSize: 26, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

// ─── HarborEdge ───────────────────────────────────────────────────────────────

/// `HarborEdge`: top, bottom, start and end.
class EdgeEntry extends StatefulWidget {
  const EdgeEntry({super.key});

  @override
  State<EdgeEntry> createState() => _EdgeEntryState();
}

class _EdgeEntryState extends State<EdgeEntry> {
  HarborDockKind _kind = HarborDockKind.quay;

  HarborDock _side(final HarborEdge edge) {
    final Widget child = _RunningLight(edge: edge);
    return _kind == HarborDockKind.pier
        ? HarborDock.pier(debugLabel: edge.name, child: child)
        : HarborDock.quay(debugLabel: edge.name, child: child);
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborEdge',
    realWorld:
        'A ship shows a red running light on her port side and a green one to starboard. Port and starboard belong to '
        'the ship, not to whoever is watching: turn her around and the red light is still on her port side.',
    inYourApp:
        'An edge of a harbor: top, bottom, start, end. start and end follow the reading direction rather than the '
        'screen, so a dock on start is on the left in English and on the right in Arabic. Flip the stage’s '
        'Right-to-left switch and watch them swap. HarborEdges does the arithmetic on EdgeInsetsDirectional by edge: '
        'of, only, keep, without, max, min, directional (EdgeInsets → start/end) and physical (edges → sides).',
    art: const RunningLightsArt(),
    controls: <Widget>[
      ChoiceControl<HarborDockKind>(
        label: 'side docks',
        values: HarborDockKind.values,
        value: _kind,
        labelOf: (final HarborDockKind k) => 'HarborDock.${k.name}',
        onChanged: (final HarborDockKind k) => setState(() => _kind = k),
      ),
    ],
    code:
        'Harbor(\n'
        '  start: [HarborDock.${_kind.name}(child: PortLight())],\n'
        '  end: [HarborDock.${_kind.name}(child: StarboardLight())],\n'
        '  body: body,\n'
        ')\n'
        '\n'
        'final insets = HarborEdges.directional(\n'
        '  MediaQuery.paddingOf(context),\n'
        '  Directionality.of(context),\n'
        ');\n'
        'final start = HarborEdges.of(insets, HarborEdge.start);\n'
        'final sides = HarborEdges.physical({HarborEdge.start}, Directionality.of(context));',
    stage: (final BuildContext context) => Harbor(
      debugLabel: 'edges',
      top: <HarborDock>[
        HarborDock.pier(
          debugLabel: 'header',
          backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
          child: const StageHeader(title: 'HarborEdge'),
        ),
      ],
      start: <HarborDock>[_side(HarborEdge.start)],
      end: <HarborDock>[_side(HarborEdge.end)],
      body: const StageProbe(label: 'Body, between start and end', child: _EdgeReadout()),
    ),
  );
}

class _RunningLight extends StatelessWidget {
  const _RunningLight({required this.edge});

  final HarborEdge edge;

  @override
  Widget build(final BuildContext context) {
    final bool start = edge == HarborEdge.start;
    final Color color = start ? const Color(0xFFFF3B30) : const Color(0xFF30D158);
    return Container(
      key: ValueKey<String>('edge ${edge.name}'),
      width: 76,
      color: Palette.night.withValues(alpha: 0.9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 18, spreadRadius: 4)],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'HarborEdge\n.${edge.name}',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Menlo', fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            start ? 'port' : 'starboard',
            style: TextStyle(fontSize: 11, color: Palette.foam.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _EdgeReadout extends StatelessWidget {
  const _EdgeReadout();

  @override
  Widget build(final BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    final EdgeInsetsDirectional padding = HarborEdges.directional(MediaQuery.paddingOf(context), direction);
    final ({bool left, bool top, bool right, bool bottom}) start = HarborEdges.physical(<HarborEdge>{
      HarborEdge.start,
    }, direction);
    final List<String> lines = <String>[
      'Directionality: ${direction.name}',
      'HarborEdge.start is on the ${start.left ? 'left' : 'right'}',
      'HarborEdge.end is on the ${start.left ? 'right' : 'left'}',
      'HarborEdge.start.opposite: ${HarborEdge.start.opposite.name}',
      '',
      'HarborEdges.directional(padding):',
      for (final HarborEdge e in HarborEdge.values) '  ${e.name}: ${_n(HarborEdges.of(padding, e))}',
    ];
    return HarborMoored(
      mooringLine: true,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            lines.join('\n'),
            style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, color: Palette.foam, height: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── HarborChart + HarborChartOverlay ─────────────────────────────────────────

/// `HarborChart`: who holds which edge, at which layer.
class ChartEntry extends StatefulWidget {
  const ChartEntry({super.key});

  @override
  State<ChartEntry> createState() => _ChartEntryState();
}

class _ChartEntryState extends State<ChartEntry> {
  final StageSettings _settings = StageSettings()..chart = true;
  bool _list = true;

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborChart',
    settings: _settings,
    realWorld:
        'A nautical chart shows a harbor from above: where the land is, how deep the water runs (the soundings), where '
        'the piers and breakwaters stand, with a compass rose to take bearings by.',
    inYourApp:
        'HarborChartOverlay draws every dock’s ground (piers teal, quays sand), each harbor’s clear water outlined, and '
        'the tide in blue: it’s the stage’s HarborChartOverlay switch. HarborChart.snapshot(context) returns the same '
        'as data (listed in the readings, live), and in debug and profile builds the ext.harbor.chart VM-service '
        'extension serves it as JSON, so a tool driving the app can ask where everything is.',
    art: const NauticalChartArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'list HarborChart.snapshot',
        value: _list,
        onChanged: (final bool v) => setState(() => _list = v),
      ),
      Text(
        'Open the breakwater sheet from the buoy: its harbor joins the chart.',
        style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
      ),
    ],
    code:
        'MaterialApp(\n'
        '  builder: (context, child) => HarborChartOverlay(\n'
        '    enabled: kDebugMode,\n'
        '    child: HarborSea(child: child!),\n'
        '  ),\n'
        ')\n'
        '\n'
        'for (final harbor in HarborChart.snapshot(context)) {\n'
        '  for (final dock in harbor.docks) {\n'
        '    print(\'\${dock.label} \${dock.kind.name} \${dock.edge.name} \${dock.extent}\');\n'
        '  }\n'
        '}\n'
        '\n'
        '// Over the VM service: ext.harbor.chart → {"harbors": [...]}',
    stage: (final BuildContext context) => Harbor(
      debugLabel: 'chart page',
      top: <HarborDock>[
        HarborDock.pier(
          debugLabel: 'pier header',
          wake: const HarborWake.fade(length: 12),
          backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.8)),
          child: const StageHeader(title: 'HarborChart'),
        ),
      ],
      bottom: const <HarborDock>[
        HarborDock.quay(
          debugLabel: 'quay tab bar',
          backdrop: QuayStones(),
          child: StageBar(key: ValueKey<String>('chart tab bar'), label: 'quay tab bar'),
        ),
      ],
      buoys: const <HarborBuoy>[HarborBuoy(alignment: Alignment.bottomRight, child: _SheetBuoy())],
      body: _ChartLog(
        enabled: _list,
        child: HarborFairway(
          slivers: <Widget>[
            SliverList.builder(
              itemCount: 20,
              itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetBuoy extends StatelessWidget {
  const _SheetBuoy();

  @override
  Widget build(final BuildContext context) => FilledButton.icon(
    key: const ValueKey<String>('breakwater sheet button'),
    style: FilledButton.styleFrom(backgroundColor: Palette.sail, foregroundColor: Palette.night),
    onPressed: () => unawaited(
      showHarborSheet<void>(
        context,
        breakwater: true,
        builder: (final BuildContext context) => HarborSheet(
          debugLabel: 'breakwater sheet',
          header: const StageHeader(title: 'breakwater sheet'),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'This sheet is a harbor of its own: see it on the chart and in the snapshot.',
              style: TextStyle(color: Palette.foam.withValues(alpha: 0.85)),
            ),
          ),
          footer: const StageBar(label: 'sheet footer'),
        ),
      ),
    ),
    icon: const BuoyArt(size: 22),
    label: const Text('HarborBuoy · sheet', style: TextStyle(fontFamily: 'Menlo', fontSize: 12)),
  );
}

/// Lists [HarborChart.snapshot] in the readings, refreshed twice a second.
class _ChartLog extends StatefulWidget {
  const _ChartLog({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_ChartLog> createState() => _ChartLogState();
}

class _ChartLogState extends State<_ChartLog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (final Timer _) => _report());
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) => _report());
  }

  static const String _label = 'HarborChart.snapshot(context)';
  StageSettings? _settings;

  @override
  void didUpdateWidget(final _ChartLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switched off: take the listing off the readings.
    if (oldWidget.enabled && !widget.enabled) {
      _settings?.forget(_label, this);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settings?.forget(_label, this);
    super.dispose();
  }

  void _report() {
    if (!mounted || !widget.enabled) {
      return;
    }
    final List<HarborChartEntry> chart = HarborChart.snapshot(context);
    final StringBuffer text = StringBuffer();
    for (final HarborChartEntry harbor in chart) {
      text.writeln(
        "'${harbor.label}' · depth ${harbor.depth} · clear water ${_n(harbor.clearWater.width)} × ${_n(harbor.clearWater.height)}",
      );
      for (final HarborDockRecord dock in harbor.docks) {
        text.writeln(
          '  ${dock.label ?? '(no label)'} · ${dock.kind.name} · ${dock.edge.name} · extent ${_n(dock.extent)}',
        );
      }
    }
    _settings = StageScope.settingsOf(context)?..report(_label, text.toString().trimRight(), reporter: this);
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

// ─── Sea trials ───────────────────────────────────────────────────────────────

/// `pumpSeaTrial` and `HarborTrialDevice`: widget tests on pretend devices.
class SeaTrialEntry extends StatefulWidget {
  const SeaTrialEntry({super.key});

  @override
  State<SeaTrialEntry> createState() => _SeaTrialEntryState();
}

class _SeaTrialEntryState extends State<SeaTrialEntry> {
  final StageSettings _settings = StageSettings();
  late StageDevice _device = _settings.device;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    _settings
      ..removeListener(_onSettings)
      ..dispose();
    super.dispose();
  }

  void _onSettings() {
    if (_settings.device != _device) {
      setState(() => _device = _settings.device);
    }
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'pumpSeaTrial',
    focus: const StageFocus.bottom(520),
    settings: _settings,
    realWorld:
        'Before a new ship is handed over she goes out on sea trials: flags flying, a tug standing by, she is run at '
        'speed, turned hard and stopped, and every reading is checked against what the yard promised.',
    inYourApp:
        'package:harbor/testing.dart puts a widget test on a pretend device. tester.pumpSeaTrial(app, device:) sets the '
        'test view to the HarborTrialDevice’s size and coast; trial.raiseTide() brings its keyboard in, and '
        'trial.waterline is where the keyboard’s top is. The stage’s device chips are the trial devices (the list '
        'also has television). Pick one and raise the tide.',
    art: const SeaTrialsArt(),
    code:
        "import 'package:harbor/testing.dart';\n"
        '\n'
        "testWidgets('the composer rides the keyboard', (tester) async {\n"
        '  final trial = await tester.pumpSeaTrial(\n'
        '    app,\n'
        '    device: HarborTrialDevice.${_trialName(_device)},\n'
        '  );\n'
        '  await trial.raiseTide();\n'
        '  expect(\n'
        '    tester.getRect(find.byType(Composer)).bottom,\n'
        '    trial.waterline, // ${_n(_device.size.height)} − ${_n(_device.tideHeight)} = ${_n(_device.size.height - _device.tideHeight)}\n'
        '  );\n'
        '});',
    stage: (final BuildContext context) {
      final StageSettings settings = StageScope.settingsOf(context)!;
      final StageDevice device = settings.device;
      final double waterline = device.size.height - settings.tideHeight;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Harbor(
            debugLabel: 'sea trial',
            top: <HarborDock>[
              HarborDock.pier(
                debugLabel: 'header',
                backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
                child: const StageHeader(title: 'HarborSeaTrial'),
              ),
            ],
            bottom: const <HarborDock>[
              HarborDock.quay(
                debugLabel: 'composer',
                tide: HarborTideStance.float,
                backdrop: ColoredBox(color: Palette.night),
                child: _Composer(),
              ),
            ],
            body: StageProbe(
              label: 'Trial body',
              child: HarborMoored(
                mooringLine: true,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'HarborTrialDevice.${_trialName(device)}\n'
                      'size        ${_n(device.size.width)} × ${_n(device.size.height)}\n'
                      'coast       ${_insets(device.coast)}\n'
                      'tideHeight  ${_n(device.tideHeight)}\n'
                      'tideIn      ${settings.tide >= 1}\n'
                      'waterline   ${_n(waterline)}',
                      key: const ValueKey<String>('trial readout'),
                      style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, color: Palette.foam, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (settings.tideHeight > 0)
            Positioned(
              top: waterline - 1,
              left: 0,
              right: 0,
              height: 2,
              child: const IgnorePointer(
                child: ColoredBox(key: ValueKey<String>('waterline mark'), color: Palette.buoyRed),
              ),
            ),
        ],
      );
    },
  );
}

String _trialName(final StageDevice device) => switch (device.name) {
  'iPhone 17' => 'iPhone17',
  'iPhone SE' => 'iPhoneSE',
  'Android 3-button' => 'androidThreeButton',
  'Android gesture' => 'androidGesture',
  'iPhone 17 landscape' => 'iPhone17Landscape',
  'foldable open' => 'foldableOpen',
  'dual screen cover' => 'dualScreenCover',
  _ => 'television',
};

/// A composer drawn like a text field, with no real field behind it.
class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(final BuildContext context) => HarborMooringLine(
    child: Padding(
      key: const ValueKey<String>('trial composer'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 40,
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Palette.deepSea,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.foam.withValues(alpha: 0.3)),
              ),
              child: Text('Composer', style: TextStyle(color: Palette.foam.withValues(alpha: 0.6))),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.send_rounded, color: Palette.brass),
        ],
      ),
    ),
  );
}

// ─── HarborWakePainter / harborAlphaWake ──────────────────────────────────────

enum _WakeChoice { fairway, alpha, tinted }

/// The color of the custom wake painter's haze.
const Color _tint = Palette.brass;

/// A [HarborWakePainter] of your own: instead of fading the body out, it lays
/// a brass haze over each wake band, solid at the body's edge, half at the
/// dock's inner face, and gone where the wake ends.
Widget tintedWake(final BuildContext context, final Map<HarborEdge, HarborWakeBand> wakes, final Widget body) {
  Widget haze(final HarborEdge edge, final HarborWakeBand band) {
    final double dock = band.wakeEnd <= 0 ? 0 : (band.dockEdge / band.wakeEnd).clamp(0.0, 1.0);
    final (AlignmentGeometry, AlignmentGeometry) ends = switch (edge) {
      HarborEdge.top => (Alignment.topCenter, Alignment.bottomCenter),
      HarborEdge.bottom => (Alignment.bottomCenter, Alignment.topCenter),
      HarborEdge.start => (AlignmentDirectional.centerStart, AlignmentDirectional.centerEnd),
      HarborEdge.end => (AlignmentDirectional.centerEnd, AlignmentDirectional.centerStart),
    };
    return IgnorePointer(
      key: ValueKey<String>('tinted wake ${edge.name}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: ends.$1,
            end: ends.$2,
            colors: <Color>[_tint.withValues(alpha: 0.85), _tint.withValues(alpha: 0.45), _tint.withValues(alpha: 0.0)],
            stops: <double>[0, dock, 1],
          ),
        ),
      ),
    );
  }

  final TextDirection direction = Directionality.of(context);
  return Stack(
    fit: StackFit.expand,
    children: <Widget>[
      body,
      for (final MapEntry<HarborEdge, HarborWakeBand> wake in wakes.entries)
        if (wake.value.wakeEnd > 0)
          switch (wake.key) {
            HarborEdge.top => Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: wake.value.wakeEnd,
              child: haze(wake.key, wake.value),
            ),
            HarborEdge.bottom => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: wake.value.wakeEnd,
              child: haze(wake.key, wake.value),
            ),
            HarborEdge.start => Positioned.directional(
              textDirection: direction,
              start: 0,
              top: 0,
              bottom: 0,
              width: wake.value.wakeEnd,
              child: haze(wake.key, wake.value),
            ),
            HarborEdge.end => Positioned.directional(
              textDirection: direction,
              end: 0,
              top: 0,
              bottom: 0,
              width: wake.value.wakeEnd,
              child: haze(wake.key, wake.value),
            ),
          },
    ],
  );
}

/// `HarborWakePainter` and `harborAlphaWake`: how the wake is painted.
class WakePainterEntry extends StatefulWidget {
  const WakePainterEntry({super.key});

  @override
  State<WakePainterEntry> createState() => _WakePainterEntryState();
}

class _WakePainterEntryState extends State<WakePainterEntry> {
  _WakeChoice _choice = _WakeChoice.fairway;
  double _length = 24;

  String _label(final _WakeChoice c) => switch (c) {
    _WakeChoice.fairway => 'null (fairway wake)',
    _WakeChoice.alpha => 'harborAlphaWake',
    _WakeChoice.tinted => 'tintedWake (your own)',
  };

  HarborWakePainter? get _painter => switch (_choice) {
    _WakeChoice.fairway => null,
    _WakeChoice.alpha => harborAlphaWake,
    _WakeChoice.tinted => tintedWake,
  };

  String get _code {
    final String header =
        '  top: [\n'
        '    HarborDock.pier(\n'
        '      wake: HarborWake.fade(length: ${_n(_length)}),\n'
        '      child: Header(),\n'
        '    ),\n'
        '  ],\n';
    return switch (_choice) {
      _WakeChoice.fairway =>
        'Harbor(\n'
            '$header'
            '  // No wakePainter: the fairway fades its rows;\n'
            '  // the open water behind them stays as it is.\n'
            '  body: Stack(children: [NightSky(), HarborFairway(slivers: [boats])]),\n'
            ')',
      _WakeChoice.alpha =>
        'Harbor(\n'
            '$header'
            '  wakePainter: harborAlphaWake, // the whole body fades\n'
            '  body: Stack(children: [\n'
            '    NightSky(),\n'
            '    HarborFairway(wake: false, slivers: [boats]),\n'
            '  ]),\n'
            ')',
      _WakeChoice.tinted =>
        'Widget tintedWake(\n'
            '  BuildContext context,\n'
            '  Map<HarborEdge, HarborWakeBand> wakes,\n'
            '  Widget body,\n'
            ') => Stack(fit: StackFit.expand, children: [\n'
            '  body,\n'
            '  for (final MapEntry(:key, :value) in wakes.entries)\n'
            '    Positioned(\n'
            '      top: 0, left: 0, right: 0,\n'
            '      height: value.wakeEnd, // dock face at value.dockEdge\n'
            '      child: BrassHaze(),\n'
            '    ),\n'
            ']);\n'
            '\n'
            'Harbor(\n'
            '$header'
            '  wakePainter: tintedWake,\n'
            '  body: Stack(children: [\n'
            '    NightSky(),\n'
            '    HarborFairway(wake: false, slivers: [boats]),\n'
            '  ]),\n'
            ')',
    };
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborWakePainter',
    focus: const StageFocus.top(440),
    realWorld:
        'A moving boat leaves a wake: a V of waves spreading out behind her at the same angle whatever her size, '
        'fading as it goes, with churned water right astern.',
    inYourApp:
        'How a harbor paints the wake where content passes under a dock with a fade wake. With no wakePainter (the '
        'default) each fairway fades its own rows and open water stays put. harborAlphaWake is the default painter '
        'as a function: give it to Harbor(wakePainter:) to fade the whole body, background and all. Or write your own '
        '(context, wakes, body) → Widget: each band says where the dock’s face (dockEdge) and the wake’s end (wakeEnd) '
        'are, from the body’s edge. Here, a brass haze.',
    art: const WakeArt(),
    controls: <Widget>[
      ChoiceControl<_WakeChoice>(
        label: 'wakePainter',
        values: _WakeChoice.values,
        value: _choice,
        labelOf: _label,
        onChanged: (final _WakeChoice c) => setState(() => _choice = c),
      ),
      SliderControl(
        label: 'length',
        value: _length,
        min: 0,
        max: 48,
        onChanged: (final double v) => setState(() => _length = v),
      ),
    ],
    code: _code,
    stage: (final BuildContext context) => Harbor(
      debugLabel: 'wake page',
      wakePainter: _painter,
      top: <HarborDock>[
        HarborDock.pier(
          debugLabel: 'header',
          wake: HarborWake.fade(length: _length),
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.55)),
          child: const StageHeader(key: ValueKey<String>('wake header'), title: 'HarborWakePainter'),
        ),
      ],
      body: StageProbe(
        label: 'Body',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const CustomPaint(painter: _NightSkyPainter()),
            HarborFairway(
              wake: _choice == _WakeChoice.fairway,
              slivers: <Widget>[
                SliverList.builder(
                  itemCount: 30,
                  itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Open water behind the rows: a night sky with a moon near the top, so the
/// difference between a fairway's wake and a whole-body wake shows.
class _NightSkyPainter extends CustomPainter {
  const _NightSkyPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0A1630), Palette.deepSea],
        ).createShader(Offset.zero & size),
    );
    final math.Random random = math.Random(7);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height * 0.5),
        1,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
    final Offset moon = Offset(size.width * 0.72, 92);
    canvas
      ..drawCircle(moon, 40, Paint()..color = const Color(0x33FFF3C4))
      ..drawCircle(moon, 26, Paint()..color = const Color(0xFFFFF3C4));
  }

  @override
  bool shouldRepaint(final _NightSkyPainter oldDelegate) => false;
}
