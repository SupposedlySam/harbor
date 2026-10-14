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

/// System edges and the inspector: where insets come from, TV, and seeing it all.
final List<GuideEntry> platformEntries = <GuideEntry>[
  GuideEntry(
    id: 'coast',
    className: 'HarborSystemEdges',
    group: GuideGroup.platform,
    realWorld: 'Like a coastline: where the screen stops being yours',
    art: (final BuildContext context) => const CoastArt(),
    page: (final BuildContext context) => const CoastEntry(),
  ),
  GuideEntry(
    id: 'coast-title-safe',
    className: 'HarborSystemEdges.titleSafe',
    group: GuideGroup.platform,
    realWorld: 'Like an old TV’s title-safe frame: captions stay inside it',
    art: (final BuildContext context) => const TitleSafeTvArt(),
    page: (final BuildContext context) => const TitleSafeEntry(),
  ),
  GuideEntry(
    id: 'scale-model',
    className: 'HarborScaledScreen',
    group: GuideGroup.platform,
    realWorld: 'Like a ship in a bottle: a whole screen at a fixed scale',
    art: (final BuildContext context) => const ShipInBottleArt(),
    page: (final BuildContext context) => const ScaleModelEntry(),
  ),
  GuideEntry(
    id: 'edge',
    className: 'HarborEdge',
    group: GuideGroup.platform,
    realWorld: 'Like port and starboard: sides that belong to the ship',
    art: (final BuildContext context) => const RunningLightsArt(),
    page: (final BuildContext context) => const EdgeEntry(),
  ),
  GuideEntry(
    id: 'chart',
    className: 'HarborInspector',
    group: GuideGroup.platform,
    realWorld: 'Like a chart: who holds which edge',
    art: (final BuildContext context) => const NauticalChartArt(),
    page: (final BuildContext context) => const ChartEntry(),
  ),
  GuideEntry(
    id: 'sea-trial',
    className: 'pumpHarborTrial',
    group: GuideGroup.platform,
    realWorld: 'Like sea trials: every reading checked on a pretend device',
    art: (final BuildContext context) => const SeaTrialsArt(),
    page: (final BuildContext context) => const SeaTrialEntry(),
  ),
  GuideEntry(
    id: 'wake-painter',
    className: 'HarborEdgeEffectPainter',
    group: GuideGroup.platform,
    realWorld: 'Like a boat’s wake: how the fade under a bar is painted',
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

// ─── HarborSystemEdges ────────────────────────────────────────────────────────

enum _CoastChoice { ambient, fixed, none }

/// `HarborSystemEdges`: where a frame's system edges come from.
class CoastEntry extends StatefulWidget {
  const CoastEntry({super.key});

  @override
  State<CoastEntry> createState() => _CoastEntryState();
}

class _CoastEntryState extends State<CoastEntry> {
  _CoastChoice _choice = _CoastChoice.ambient;

  static const EdgeInsetsDirectional _fixedInsets = EdgeInsetsDirectional.symmetric(vertical: 24);

  HarborSystemEdges get _coast => switch (_choice) {
    _CoastChoice.ambient => HarborSystemEdges.ambient,
    _CoastChoice.fixed => const HarborSystemEdges.fixed(_fixedInsets),
    _CoastChoice.none => HarborSystemEdges.none,
  };

  String _label(final _CoastChoice c) => switch (c) {
    _CoastChoice.ambient => 'HarborSystemEdges.ambient',
    _CoastChoice.fixed => 'HarborSystemEdges.fixed(...)',
    _CoastChoice.none => 'HarborSystemEdges.none',
  };

  String get _code => switch (_choice) {
    _CoastChoice.ambient => 'HarborSystemEdges.ambient',
    _CoastChoice.fixed => 'HarborSystemEdges.fixed(EdgeInsetsDirectional.symmetric(vertical: 24))',
    _CoastChoice.none => 'HarborSystemEdges.none',
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    // No focus, the whole phone: the system edges are at the bottom as well as the top, and the Home
    // indicator switch changes only the bottom.
    className: 'HarborSystemEdges',
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage, switch off Status bar, then pick Device: iPhone SE',
        'On the iPhone 17 the top band stays, since the island keeps its inset with no status bar; on the SE it goes and the header moves up to the top: ambient takes the system edges the platform reports.',
      ),
      TryStep(
        'Pick systemEdges: HarborSystemEdges.fixed(...)',
        'The system edges are 24 top and bottom though Status bar is still off: fixed says what they are, whatever the device reports.',
      ),
      TryStep(
        'Pick HarborSystemEdges.ambient and iPhone 17 landscape',
        'Sand bands appear down both sides and the bar sits 21 up: ambient follows the landscape phone\'s side insets.',
      ),
      TryStep(
        'Pick systemEdges: HarborSystemEdges.none',
        'Every band goes and the header and bar sit on the glass: none has no system edges, for a frame that must look the same anywhere.',
      ),
      TryStep(
        'Tap the keyboard button under the gauge',
        'The rows don\'t move: none ignores the keyboard too, though Readings still show the stage\'s keyboard.',
      ),
    ],
    realWorld:
        'Drawn as a coastline: cliffs, beaches and rocks, where the sea simply stops and no boat can moor. The system '
        'edges are the part of the screen where your content stops in the same way.',
    inYourApp:
        'The part of the screen the platform keeps: the status bar, the home indicator, a notch, a TV’s overscan. '
        'ambient takes MediaQuery as the platform reports it (the default), fixed(...) says exactly what the system '
        'edges are whatever the device says, and none has no system edges and ignores the keyboard, for a postcard '
        'frame that must render the same everywhere (goldens, embeds). Bars absorb them; HarborClear content keeps '
        'clear of them.',
    art: const CoastArt(),
    controls: <Widget>[
      ChoiceControl<_CoastChoice>(
        label: 'systemEdges',
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
        'HarborFrame(\n'
        '  systemEdges: $_code,\n'
        '  top: [HarborBar.overlay(child: Header())],\n'
        '  bottom: [HarborBar.solid(child: Bar())],\n'
        '  body: HarborScrollView(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => StageProbe(
      label: 'The stage (what the platform reports)',
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          HarborFrame(
            key: const ValueKey<String>('postcard'),
            systemEdges: _coast,
            debugLabel: 'postcard',
            top: <HarborBar>[
              HarborBar.overlay(
                debugLabel: 'header',
                backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
                child: StageHeader(key: const ValueKey<String>('coast header'), title: _label(_choice)),
              ),
            ],
            bottom: const <HarborBar>[
              HarborBar.solid(
                debugLabel: 'bar',
                backdrop: ColoredBox(color: Palette.night),
                child: StageBar(key: ValueKey<String>('coast bar'), label: 'HarborBar.solid'),
              ),
            ],
            body: StageProbe(
              label: 'Inside HarborFrame(systemEdges: ${_label(_choice)})',
              child: HarborScrollView(
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

/// Shades the system edges a [HarborSystemEdges] yields, as sand at the frame's edges, and
/// draws the postcard's frame.
class _CoastBands extends StatelessWidget {
  const _CoastBands({required this.coast});

  final HarborSystemEdges coast;

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
    void band(final Rect r, final Offset a, final Offset b) {
      if (r.isEmpty) {
        return;
      }
      canvas
        ..drawRect(r, sand)
        ..drawLine(a, b, edge);
    }

    // Each reading is drawn inside the side system edge, so a landscape phone's rounded corner and its
    // notch side cannot clip it, and it is drawn even when its band is empty: a reading of 0 (the
    // home indicator off) is the answer the page is there to show, not a reason to hide it.
    void reading(final String label, {required final bool top}) {
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
      final double band = top ? padding.top : padding.bottom;
      final double y = band >= text.height
          ? (top ? band / 2 : size.height - band / 2) - text.height / 2
          : (top ? band + 2 : size.height - band - text.height - 2);
      text.paint(canvas, Offset(size.width - padding.right - text.width - 8, y));
    }

    band(Rect.fromLTWH(0, 0, size.width, padding.top), Offset(0, padding.top), Offset(size.width, padding.top));
    band(
      Rect.fromLTWH(0, size.height - padding.bottom, size.width, padding.bottom),
      Offset(0, size.height - padding.bottom),
      Offset(size.width, size.height - padding.bottom),
    );
    band(Rect.fromLTWH(0, 0, padding.left, size.height), Offset(padding.left, 0), Offset(padding.left, size.height));
    band(
      Rect.fromLTWH(size.width - padding.right, 0, padding.right, size.height),
      Offset(size.width - padding.right, 0),
      Offset(size.width - padding.right, size.height),
    );
    reading('inset ${_n(padding.top)}', top: true);
    reading('inset ${_n(padding.bottom)}', top: false);
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

// ─── HarborSystemEdges.titleSafe + HarborTitleSafe ───────────────────────────

enum _SafeChoice { fraction, fixedEven, fixedRail }

/// `HarborSystemEdges.titleSafe`: a TV's title-safe band as a system edge.
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
    className: 'HarborSystemEdges.titleSafe',
    tryThis: const <TryStep>[
      TryStep(
        'Slide fraction % to 10',
        'The brass line moves in to 10% and the header and HarborClear card follow it: bars and HarborClear content keep clear.',
      ),
      TryStep(
        'Slide fraction % to 0',
        'The line reaches the edges and the card sits in the corner: a TV reports no insets of its own.',
      ),
      TryStep(
        'Pick HarborTitleSafe: fixed start 96',
        'The left band widens to 96 while the others stay 48 and 27: .fixed gives a band per edge.',
      ),
      TryStep(
        'Open The stage and switch on Right-to-left',
        'The wide band moves to the right and the card with it: the start edge follows the reading direction.',
      ),
    ],
    device: StageDevice.television,
    tide: false,
    realWorld:
        'Old tube televisions overscanned: the picture ran past the edges of the glass, and every set cropped a little '
        'differently. Broadcasters drew a title-safe frame inside the picture and kept every caption within it.',
    inYourApp:
        'A TV reports no insets, but it may still crop the edges. HarborSystemEdges.titleSafe adds a band on top of '
        'what the platform reports (edge by edge, whichever is larger), so bars absorb it and HarborClear content keeps '
        'clear of it like any other system edge. HarborTitleSafe.fraction(0.05) is the broadcast 5% of the width and '
        'height; .fixed gives a band per edge. The stage draws the 5% guides dashed; the brass line is this setting.',
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
        '  builder: (context, child) => HarborRoot(\n'
        '    systemEdges: HarborSystemEdges.titleSafe(\n'
        '      $_safeCode,\n'
        '    ),\n'
        '    child: child!,\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) {
      final EdgeInsets band = _safe.resolve(MediaQuery.sizeOf(context)).resolve(Directionality.of(context));
      // The television itself reports no insets; the stage's own 5% band is
      // taken off so this page's title-safe band is the only one.
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            HarborFrame(
              key: const ValueKey<String>('tv harbor'),
              isPage: true,
              systemEdges: HarborSystemEdges.titleSafe(_safe),
              debugLabel: 'tv page',
              top: <HarborBar>[
                HarborBar.overlay(
                  debugLabel: 'header',
                  backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
                  child: const StageHeader(
                    key: ValueKey<String>('tv header'),
                    title: 'HarborSystemEdges.titleSafe',
                    height: 64,
                  ),
                ),
              ],
              body: const StageProbe(
                label: 'TV body',
                child: HarborClear(
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: StageMarker(
                      key: ValueKey<String>('moored card'),
                      label: 'HarborClear',
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

// ─── HarborScaledScreen ───────────────────────────────────────────────────────

enum _Letterbox { black, night }

/// `HarborScaledScreen`: a fixed reference screen, scaled to fit.
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
    className: 'HarborScaledScreen',
    tryThis: const <TryStep>[
      TryStep(
        'Pick letterbox: night',
        'The bands above and below the TV turn dark navy: the letterbox fills what the 16:9 screen leaves of the phone.',
      ),
      TryStep(
        'Open The stage and pick Device: iPhone 17 landscape',
        'The screen is pillarboxed now, and Readings show the home indicator reaching it, scaled up to B 35 inside the scaled screen.',
      ),
      TryStep(
        'Switch on systemEdges: titleSafe(0.05)',
        'The TV\'s header and rail move in from its edges: the scaled screen adds its own title-safe band to what reaches it.',
      ),
    ],
    realWorld:
        'Drawn as a ship in a bottle: a whole ship built at a fixed small scale, every mast and sail in proportion, '
        'and the world outside the glass never touches it.',
    inYourApp:
        'Lays the app out on a fixed reference screen (a TV’s 1200 × 675) and scales it to fit, letterboxed. Inside, '
        'MediaQuery.size is the reference size, and the real insets are re-based: cut to what actually reaches the '
        'scaled screen and scaled into it. A notch or home indicator beside a letterboxed screen doesn’t reach it, so '
        'its system edge is 0 there (turn the phone to landscape: the home indicator does reach). Then its own '
        'systemEdges apply.',
    art: const ShipInBottleArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'systemEdges: titleSafe(0.05)',
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
        '  builder: (context, child) => HarborScaledScreen(\n'
        '    referenceSize: const Size(1200, 675),\n'
        '${_titleSafe ? '    systemEdges: const HarborSystemEdges.titleSafe(HarborTitleSafe.fraction(0.05)),\n' : ''}'
        '${_letterbox == _Letterbox.night ? '    letterbox: Palette.night,\n' : ''}'
        '    child: HarborRoot(child: child!),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => StageProbe(
      label: 'The phone, outside the scaled screen',
      child: _SizeProbe(
        label: 'Size outside the scaled screen',
        child: HarborScaledScreen(
          referenceSize: const Size(1200, 675),
          systemEdges: _titleSafe
              ? const HarborSystemEdges.titleSafe(HarborTitleSafe.fraction(0.05))
              : HarborSystemEdges.ambient,
          letterbox: _letterboxColor,
          child: const HarborRoot(
            margin: EdgeInsetsDirectional.symmetric(horizontal: 32),
            child: StageProbe(
              label: 'Inside HarborScaledScreen',
              child: _SizeProbe(label: 'Size inside the scaled screen', child: _MiniTv()),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A little TV frame: a rail, a header and a row of boat cards.
class _MiniTv extends StatelessWidget {
  const _MiniTv();

  @override
  Widget build(final BuildContext context) => ColoredBox(
    key: const ValueKey<String>('scale model screen'),
    color: Palette.deepSea,
    child: HarborFrame(
      debugLabel: 'scale model',
      start: const <HarborBar>[
        HarborBar.overlay(
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
      top: const <HarborBar>[
        HarborBar.overlay(
          debugLabel: 'header',
          child: StageHeader(
            key: ValueKey<String>('scale model header'),
            title: 'HarborScaledScreen · 1200 × 675',
            height: 96,
          ),
        ),
      ],
      body: HarborClear(
        rowInsets: true,
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
  HarborBarKind _kind = HarborBarKind.solid;

  HarborBar _side(final HarborEdge edge) {
    final Widget child = _RunningLight(edge: edge);
    return _kind == HarborBarKind.overlay
        ? HarborBar.overlay(debugLabel: edge.name, child: child)
        : HarborBar.solid(debugLabel: edge.name, child: child);
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborEdge',
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage and switch on Right-to-left',
        'The red port light moves to the right and the green to the left: start and end follow the reading direction.',
      ),
      TryStep(
        'Pick Device: iPhone 17 landscape',
        'Each side bar reaches the glass and holds its light past the 62-point inset: side bars absorb the system edges too.',
      ),
      TryStep(
        'Pick side bars: HarborBar.overlay',
        'The body widens under both lights, but its text still keeps clear of them: overlay bars on start and end, like top and bottom.',
      ),
    ],
    realWorld:
        'Drawn as a ship’s running lights: red on her port side, green to starboard. Port and starboard belong to the '
        'ship, not to whoever is watching: turn her around and the red light is still on her port side.',
    inYourApp:
        'An edge of a frame: top, bottom, start, end. start and end follow the reading direction rather than the '
        'screen, so a bar on start is on the left in English and on the right in Arabic. Flip the stage’s '
        'Right-to-left switch and watch them swap. HarborEdges does the arithmetic on EdgeInsetsDirectional by edge: '
        'of, only, keep, without, max, min, directional (EdgeInsets → start/end) and physical (edges → sides).',
    art: const RunningLightsArt(),
    controls: <Widget>[
      ChoiceControl<HarborBarKind>(
        label: 'side bars',
        values: HarborBarKind.values,
        value: _kind,
        labelOf: (final HarborBarKind k) => 'HarborBar.${k.name}',
        onChanged: (final HarborBarKind k) => setState(() => _kind = k),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  start: [HarborBar.${_kind.name}(child: PortLight())],\n'
        '  end: [HarborBar.${_kind.name}(child: StarboardLight())],\n'
        '  body: body,\n'
        ')\n'
        '\n'
        'final insets = HarborEdges.directional(\n'
        '  MediaQuery.paddingOf(context),\n'
        '  Directionality.of(context),\n'
        ');\n'
        'final start = HarborEdges.of(insets, HarborEdge.start);\n'
        'final sides = HarborEdges.physical({HarborEdge.start}, Directionality.of(context));',
    stage: (final BuildContext context) => HarborFrame(
      debugLabel: 'edges',
      top: <HarborBar>[
        HarborBar.overlay(
          debugLabel: 'header',
          backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
          child: const StageHeader(title: 'HarborEdge'),
        ),
      ],
      start: <HarborBar>[_side(HarborEdge.start)],
      end: <HarborBar>[_side(HarborEdge.end)],
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
    return HarborClear(
      rowInsets: true,
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

// ─── HarborInspector + HarborInspectorOverlay ─────────────────────────────────

/// `HarborInspector`: who holds which edge, at which layer.
class ChartEntry extends StatefulWidget {
  const ChartEntry({super.key});

  @override
  State<ChartEntry> createState() => _ChartEntryState();
}

class _ChartEntryState extends State<ChartEntry> {
  final StageSettings _settings = StageSettings()..chart = true;
  bool _list = true;
  bool _sheet = false;

  /// The stage's page, for a context inside the stage's navigator to open the sheet from.
  final GlobalKey _page = GlobalKey(debugLabel: 'chart page');

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  /// Opens the covering sheet on the stage, or closes it. The switch follows the sheet, so it
  /// goes off when the sheet is dismissed on the stage too.
  void _setSheet(final bool open) {
    final BuildContext? page = _page.currentContext;
    if (page == null || open == _sheet) {
      return;
    }
    setState(() => _sheet = open);
    if (!open) {
      Navigator.of(page).pop();
      return;
    }
    unawaited(
      showHarborSheet<void>(
        page,
        coversPage: true,
        builder: (final BuildContext context) => HarborSheet(
          debugLabel: 'covering sheet',
          header: const StageHeader(title: 'covering sheet'),
          body: Padding(
            key: const ValueKey<String>('covering sheet body'),
            padding: const EdgeInsets.all(16),
            child: Text(
              'This sheet is a frame of its own: see it in the inspector and in the snapshot.',
              style: TextStyle(color: Palette.foam.withValues(alpha: 0.85)),
            ),
          ),
          footer: const StageBar(label: 'sheet footer'),
        ),
      ).then((final void _) {
        if (mounted) {
          setState(() => _sheet = false);
        }
      }),
    );
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborInspector',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button under the gauge',
        'A blue band covers the keyboard: the inspector draws it over the teal overlay bars and sand solid bars.',
      ),
      TryStep(
        'Switch on covering sheet',
        'A sheet opens and its frame joins the inspector and the Readings\' list: every frame on screen is shown.',
      ),
      TryStep(
        'Switch off list HarborInspector.snapshot',
        'The listing leaves Readings: it was HarborInspector.snapshot(context), the same data the overlay draws.',
      ),
      TryStep(
        'Open The stage and switch off HarborInspectorOverlay',
        'The shading goes but nothing moves: the overlay is a debug drawing over the layout, not part of it.',
      ),
    ],
    settings: _settings,
    realWorld:
        'Drawn as a nautical chart, which shows a harbor from above: where the land is, how deep the water runs, where '
        'the piers and breakwaters stand. The inspector shows a screen the same way: who holds which edge.',
    inYourApp:
        'HarborInspectorOverlay draws every bar’s ground (overlay bars teal, solid bars sand), each frame’s room '
        'outlined, and the keyboard in blue: it’s the stage’s HarborInspectorOverlay switch. '
        'HarborInspector.snapshot(context) returns the same as data (listed in the readings, live), and in debug and '
        'profile builds the ext.harbor.inspector VM-service extension serves it as JSON, so a tool driving the app can '
        'ask where everything is.',
    art: const NauticalChartArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'list HarborInspector.snapshot',
        value: _list,
        onChanged: (final bool v) => setState(() => _list = v),
      ),
      // In an app a button on the page opens the sheet; here the switch stands in for it, so
      // the whole phone stays in view while you flip it.
      ToggleControl(label: 'covering sheet', value: _sheet, onChanged: _setSheet),
      Text(
        'Open the covering sheet: its frame joins the inspector.',
        style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
      ),
    ],
    code:
        'MaterialApp(\n'
        '  builder: (context, child) => HarborInspectorOverlay(\n'
        '    enabled: kDebugMode,\n'
        '    child: HarborRoot(child: child!),\n'
        '  ),\n'
        ')\n'
        '\n'
        'for (final frame in HarborInspector.snapshot(context)) {\n'
        '  for (final bar in frame.bars) {\n'
        '    print(\'\${bar.label} \${bar.kind.name} \${bar.edge.name} \${bar.extent}\');\n'
        '  }\n'
        '}\n'
        '\n'
        '// Over the VM service: ext.harbor.inspector → {"frames": [...]}',
    stage: (final BuildContext context) => HarborFrame(
      key: _page,
      debugLabel: 'inspector page',
      top: <HarborBar>[
        HarborBar.overlay(
          debugLabel: 'header',
          edgeEffect: const HarborEdgeEffect.fade(length: 12),
          backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.8)),
          child: const StageHeader(title: 'HarborInspector'),
        ),
      ],
      bottom: const <HarborBar>[
        HarborBar.solid(
          debugLabel: 'tab bar',
          backdrop: QuayStones(),
          child: StageBar(key: ValueKey<String>('chart tab bar'), label: 'solid tab bar'),
        ),
      ],
      body: _ChartLog(
        enabled: _list,
        child: HarborScrollView(
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

/// Lists [HarborInspector.snapshot] in the readings, refreshed twice a second.
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

  static const String _label = 'HarborInspector.snapshot(context)';
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
    final List<HarborInspectorEntry> frames = HarborInspector.snapshot(context);
    final StringBuffer text = StringBuffer();
    for (final HarborInspectorEntry frame in frames) {
      text.writeln("'${frame.label}' · depth ${frame.depth} · room ${_n(frame.room.width)} × ${_n(frame.room.height)}");
      for (final HarborBarRecord bar in frame.bars) {
        text.writeln('  ${bar.label ?? '(no label)'} · ${bar.kind.name} · ${bar.edge.name} · extent ${_n(bar.extent)}');
      }
    }
    _settings = StageScope.settingsOf(context)?..report(_label, text.toString().trimRight(), reporter: this);
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

// ─── Trials ───────────────────────────────────────────────────────────────────

/// `pumpHarborTrial` and `HarborTrialDevice`: widget tests on pretend devices.
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
    // No focus, the whole phone: a device chip changes the whole screen, and the readout of its size, system
    // edges and keyboard top is at the top, with the keyboard and the composer at the bottom.
    className: 'pumpHarborTrial',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button under the gauge',
        'The composer rides up to the red keyboardTop line and the readout says keyboardShown true: what trial.showKeyboard() does in a test.',
      ),
      TryStep(
        'Open The stage and pick Device: iPhone SE',
        'The readout and the code card switch to HarborTrialDevice.iPhoneSE, with its own size, system edges and keyboardTop.',
      ),
      TryStep(
        'Pick Device: iPhone 17 landscape',
        'A short keyboard on a short screen: keyboardTop is 202, and the composer still rides it.',
      ),
      TryStep(
        'Hide the keyboard and switch off Home indicator',
        'The composer drops to the bottom edge: a bar that rides the keyboard sits on the home indicator until the keyboard comes.',
      ),
    ],
    settings: _settings,
    realWorld:
        'Drawn as sea trials: before a new ship is handed over she is run at speed, turned hard and stopped, a tug '
        'standing by, and every reading is checked against what the yard promised.',
    inYourApp:
        'package:harbor_test puts a widget test on a pretend device. tester.pumpHarborTrial(app, device:) sets the '
        'test view to the HarborTrialDevice’s size and system edges; trial.showKeyboard() brings its keyboard in, and '
        'trial.keyboardTop is where the keyboard’s top is. The stage’s device chips are the trial devices (the list '
        'also has television). Pick one and show the keyboard.',
    art: const SeaTrialsArt(),
    code:
        "import 'package:harbor_test/harbor_test.dart';\n"
        '\n'
        "testWidgets('the composer rides the keyboard', (tester) async {\n"
        '  final trial = await tester.pumpHarborTrial(\n'
        '    app,\n'
        '    device: HarborTrialDevice.${_trialName(_device)},\n'
        '  );\n'
        '  await trial.showKeyboard();\n'
        '  expect(\n'
        '    tester.getRect(find.byType(Composer)).bottom,\n'
        '    trial.keyboardTop, // ${_n(_device.size.height)} − ${_n(_device.tideHeight)} = ${_n(_device.size.height - _device.tideHeight)}\n'
        '  );\n'
        '});',
    stage: (final BuildContext context) {
      final StageSettings settings = StageScope.settingsOf(context)!;
      final StageDevice device = settings.device;
      final double waterline = device.size.height - settings.tideHeight;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          HarborFrame(
            debugLabel: 'trial',
            top: <HarborBar>[
              HarborBar.overlay(
                debugLabel: 'header',
                backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
                child: const StageHeader(title: 'HarborTrial'),
              ),
            ],
            bottom: const <HarborBar>[
              HarborBar.solid(
                debugLabel: 'composer',
                keyboard: HarborKeyboardStance.rides,
                backdrop: ColoredBox(color: Palette.night),
                child: _Composer(),
              ),
            ],
            body: StageProbe(
              label: 'Trial body',
              child: HarborClear(
                rowInsets: true,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'HarborTrialDevice.${_trialName(device)}\n'
                      'size            ${_n(device.size.width)} × ${_n(device.size.height)}\n'
                      'systemEdges     ${_insets(device.coast)}\n'
                      'keyboardHeight  ${_n(device.tideHeight)}\n'
                      'keyboardShown   ${settings.tide >= 1}\n'
                      'keyboardTop     ${_n(waterline)}',
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
  'Android 3-button landscape' => 'androidThreeButtonLandscape',
  'Android gesture landscape' => 'androidGestureLandscape',
  'foldable open' => 'foldableOpen',
  'dual screen open' => 'dualScreenOpen',
  'dual screen cover' => 'dualScreenCover',
  _ => 'television',
};

/// A composer drawn like a text field, with no real field behind it.
class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(final BuildContext context) => HarborClear.rowInsets(
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

// ─── HarborEdgeEffectPainter / HarborFadeMask.alphaFade ───────────────────────

enum _WakeChoice { fairway, alpha, tinted }

/// The color of the custom edge effect painter's haze.
const Color _tint = Palette.brass;

/// A [HarborEdgeEffectPainter] of your own: instead of fading the body out, it lays
/// a brass haze over each fade band, solid at the body's edge, half at the
/// bar's inner face, and gone where the fade ends.
Widget tintedFade(final BuildContext context, final Map<HarborEdge, HarborFadeBand> bands, final Widget body) {
  Widget haze(final HarborEdge edge, final HarborFadeBand band) {
    final double dock = band.fadeEnd <= 0 ? 0 : (band.barFace / band.fadeEnd).clamp(0.0, 1.0);
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
      for (final MapEntry<HarborEdge, HarborFadeBand> wake in bands.entries)
        if (wake.value.fadeEnd > 0)
          switch (wake.key) {
            HarborEdge.top => Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: wake.value.fadeEnd,
              child: haze(wake.key, wake.value),
            ),
            HarborEdge.bottom => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: wake.value.fadeEnd,
              child: haze(wake.key, wake.value),
            ),
            HarborEdge.start => Positioned.directional(
              textDirection: direction,
              start: 0,
              top: 0,
              bottom: 0,
              width: wake.value.fadeEnd,
              child: haze(wake.key, wake.value),
            ),
            HarborEdge.end => Positioned.directional(
              textDirection: direction,
              end: 0,
              top: 0,
              bottom: 0,
              width: wake.value.fadeEnd,
              child: haze(wake.key, wake.value),
            ),
          },
    ],
  );
}

/// `HarborEdgeEffectPainter` and `HarborFadeMask.alphaFade`: how the edge effect is painted.
class WakePainterEntry extends StatefulWidget {
  const WakePainterEntry({super.key});

  @override
  State<WakePainterEntry> createState() => _WakePainterEntryState();
}

class _WakePainterEntryState extends State<WakePainterEntry> {
  _WakeChoice _choice = _WakeChoice.fairway;
  double _length = 24;

  String _label(final _WakeChoice c) => switch (c) {
    _WakeChoice.fairway => 'null (scroll view fade)',
    _WakeChoice.alpha => 'HarborFadeMask.alphaFade',
    _WakeChoice.tinted => 'tintedFade (your own)',
  };

  HarborEdgeEffectPainter? get _painter => switch (_choice) {
    _WakeChoice.fairway => null,
    _WakeChoice.alpha => HarborFadeMask.alphaFade,
    _WakeChoice.tinted => tintedFade,
  };

  String get _code {
    final String header =
        '  top: [\n'
        '    HarborBar.overlay(\n'
        '      edgeEffect: HarborEdgeEffect.fade(length: ${_n(_length)}),\n'
        '      child: Header(),\n'
        '    ),\n'
        '  ],\n';
    return switch (_choice) {
      _WakeChoice.fairway =>
        'HarborFrame(\n'
            '$header'
            '  // No edgeEffectPainter: the scroll view fades its rows;\n'
            '  // the background behind them stays as it is.\n'
            '  body: Stack(children: [NightSky(), HarborScrollView(slivers: [boats])]),\n'
            ')',
      _WakeChoice.alpha =>
        'HarborFrame(\n'
            '$header'
            '  edgeEffectPainter: HarborFadeMask.alphaFade, // the whole body fades\n'
            '  body: Stack(children: [\n'
            '    NightSky(),\n'
            '    HarborScrollView(edgeEffects: false, slivers: [boats]),\n'
            '  ]),\n'
            ')',
      _WakeChoice.tinted =>
        'Widget tintedFade(\n'
            '  BuildContext context,\n'
            '  Map<HarborEdge, HarborFadeBand> bands,\n'
            '  Widget body,\n'
            ') => Stack(fit: StackFit.expand, children: [\n'
            '  body,\n'
            '  for (final MapEntry(:key, :value) in bands.entries)\n'
            '    Positioned(\n'
            '      top: 0, left: 0, right: 0,\n'
            '      height: value.fadeEnd, // bar face at value.barFace\n'
            '      child: BrassHaze(),\n'
            '    ),\n'
            ']);\n'
            '\n'
            'HarborFrame(\n'
            '$header'
            '  edgeEffectPainter: tintedFade,\n'
            '  body: Stack(children: [\n'
            '    NightSky(),\n'
            '    HarborScrollView(edgeEffects: false, slivers: [boats]),\n'
            '  ]),\n'
            ')',
    };
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborEdgeEffectPainter',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the rows up under the header',
        'The rows fade at the header but the moon and stars behind them stay sharp: with no edgeEffectPainter, a scroll view fades its rows.',
      ),
      TryStep(
        'Pick edgeEffectPainter: HarborFadeMask.alphaFade',
        'Now the night sky fades under the header too: alphaFade fades the whole body, background and all.',
      ),
      TryStep(
        'Pick edgeEffectPainter: tintedFade (your own)',
        'A brass haze lies over the band instead of a fade: your own painter is handed each band\'s barFace and fadeEnd.',
      ),
      TryStep(
        'Slide length to 48',
        'The haze now reaches 48 past the header: length sets fadeEnd, and the painter draws the new band.',
      ),
    ],
    focus: const StageFocus.top(440),
    realWorld:
        'Drawn as a boat’s wake: a V of waves spreading out behind her, fading as it goes. The edge effect is the fade '
        'where content passes under a bar.',
    inYourApp:
        'How a frame paints the edge effect where content passes under a bar with a fade. With no edgeEffectPainter '
        '(the default) each scroll view fades its own rows and the rest of the body stays put. HarborFadeMask.alphaFade '
        'is the default painter as a function: give it to HarborFrame(edgeEffectPainter:) to fade the whole body, '
        'background and all. Or write your own (context, bands, body) → Widget: each band says where the bar’s face '
        '(barFace) and the fade’s end (fadeEnd) are, from the body’s edge. Here, a brass haze.',
    art: const WakeArt(),
    controls: <Widget>[
      ChoiceControl<_WakeChoice>(
        label: 'edgeEffectPainter',
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
    stage: (final BuildContext context) => HarborFrame(
      debugLabel: 'edge effect page',
      edgeEffectPainter: _painter,
      top: <HarborBar>[
        HarborBar.overlay(
          debugLabel: 'header',
          edgeEffect: HarborEdgeEffect.fade(length: _length),
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.55)),
          child: const StageHeader(key: ValueKey<String>('wake header'), title: 'HarborEdgeEffectPainter'),
        ),
      ],
      body: StageProbe(
        label: 'Body',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const CustomPaint(painter: _NightSkyPainter()),
            HarborScrollView(
              edgeEffects: _choice == _WakeChoice.fairway,
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

/// A background behind the rows: a night sky with a moon near the top, so the
/// difference between a scroll view's fade and a whole-body fade shows.
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
