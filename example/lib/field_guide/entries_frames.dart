import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import 'art/frames_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Frames: the harbor and the sea it sits in.
final List<GuideEntry> frameEntries = <GuideEntry>[
  GuideEntry(
    id: 'frame-harbor',
    className: 'Harbor',
    group: GuideGroup.frames,
    realWorld: 'A bay sheltered by two breakwater arms, with a town on the shore',
    art: (final BuildContext context) => const HarborArt(),
    page: (final BuildContext context) => const HarborEntry(),
  ),
  GuideEntry(
    id: 'frame-sea',
    className: 'HarborSea',
    group: GuideGroup.frames,
    realWorld: 'The open ocean, out to the horizon',
    art: (final BuildContext context) => const HarborSeaArt(),
    page: (final BuildContext context) => const HarborSeaEntry(),
  ),
  GuideEntry(
    id: 'frame-new-port',
    className: 'Harbor(newPort: true)',
    group: GuideGroup.frames,
    realWorld: 'A second harbor town further up the coast, with its own quays',
    art: (final BuildContext context) => const NewPortArt(),
    page: (final BuildContext context) => const NewPortEntry(),
  ),
  GuideEntry(
    id: 'frame-hug-body',
    className: 'HarborSizing.hugBody',
    group: GuideGroup.frames,
    realWorld: 'A skiff on a davit, hoisted just as high as the boat',
    art: (final BuildContext context) => const HugBodyArt(),
    page: (final BuildContext context) => const HugBodyEntry(),
  ),
];

/// A body that shows its own box: a tinted panel with a label at each end.
class _BodyBox extends StatelessWidget {
  const _BodyBox({required this.label, this.child});

  final String label;
  final Widget? child;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('harbor body'),
    decoration: BoxDecoration(
      color: Palette.shallows.withValues(alpha: 0.22),
      border: Border.all(color: Palette.brass, width: 2),
    ),
    child: SizedBox.expand(
      child: HarborMoored(
        edges: HarborEdge.vertical,
        extra: const EdgeInsetsDirectional.symmetric(vertical: 8),
        child: Column(
          children: <Widget>[
            HarborMooringLine(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, color: Palette.brass, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (child != null) Expanded(child: child!),
          ],
        ),
      ),
    ),
  );
}

/// `Harbor`: a frame with docked edges and a body of water in the middle.
class HarborEntry extends StatefulWidget {
  const HarborEntry({super.key});

  @override
  State<HarborEntry> createState() => _HarborEntryState();
}

class _HarborEntryState extends State<HarborEntry> {
  bool _top = true;
  bool _bottom = true;
  bool _clearsTide = true;
  double _margin = 16;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'Harbor',
    realWorld:
        'A harbor is a bay of calm water sheltered by breakwaters, with quays and piers built along its edges and a town '
        'on the shore. Boats come in through the mouth and tie up wherever there is room.',
    inYourApp:
        'A page, a tab or a sheet: a frame whose top, bottom, start and end edges docks are built against. The body (your '
        'content) fills whatever the quays leave, and is told through MediaQuery.padding what still reaches over it.',
    art: const HarborArt(),
    controls: <Widget>[
      ToggleControl(label: 'top dock', value: _top, onChanged: (final bool v) => setState(() => _top = v)),
      ToggleControl(label: 'bottom dock', value: _bottom, onChanged: (final bool v) => setState(() => _bottom = v)),
      ToggleControl(label: 'bodyClearsTide', value: _clearsTide, onChanged: (final bool v) => setState(() => _clearsTide = v)),
      SliderControl(label: 'margin', value: _margin, min: 0, max: 48, onChanged: (final double v) => setState(() => _margin = v)),
    ],
    code:
        'Harbor(\n'
        '  margin: EdgeInsetsDirectional.symmetric(horizontal: ${_margin.toStringAsFixed(0)}),\n'
        '  bodyClearsTide: $_clearsTide,\n'
        '${_top ? '  top: [HarborDock.quay(child: Header())],\n' : ''}'
        '${_bottom ? '  bottom: [HarborDock.quay(child: TabBar())],\n' : ''}'
        '  body: HarborMoored(child: HarborMooringLine(child: Row())),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      debugLabel: 'Harbor',
      margin: EdgeInsetsDirectional.symmetric(horizontal: _margin),
      bodyClearsTide: _clearsTide,
      top: <HarborDock>[
        if (_top)
          const HarborDock.quay(
            backdrop: QuayStones(),
            debugLabel: 'top',
            child: StageHeader(key: ValueKey<String>('top dock'), title: 'top: HarborDock.quay'),
          ),
      ],
      bottom: <HarborDock>[
        if (_bottom)
          const HarborDock.quay(
            backdrop: QuayStones(),
            debugLabel: 'bottom',
            child: StageBar(key: ValueKey<String>('bottom dock'), label: 'bottom: HarborDock.quay'),
          ),
      ],
      body: StageProbe(
        label: 'Harbor body',
        child: _BodyBox(
          label: 'body',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const HarborMooringLine(
                child: StageMarker(key: ValueKey<String>('mooring marker'), label: 'HarborMooringLine', color: Palette.sea),
              ),
              const SizedBox(height: 8),
              HarborMooringLine(
                child: Text(
                  'Rows keep the margin; the body itself runs to the frame\'s edge.',
                  style: TextStyle(color: Palette.foam.withValues(alpha: 0.8)),
                ),
              ),
              const Spacer(),
              const HarborMooringLine(child: StageMarker(label: 'body ends here', color: Palette.plank, height: 36)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// What the stage's own sea (or a nested one) shows: its coast, drawn.
class _SeaView extends StatelessWidget {
  const _SeaView({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) => StageProbe(
    label: label,
    child: HarborOpenWater(
      builder: (final BuildContext context, final HarborWatersData waters) {
        final EdgeInsets coast = waters.coast.resolve(Directionality.of(context));
        Widget band(final String text) => ColoredBox(
          color: Palette.brass.withValues(alpha: 0.35),
          child: Align(
            alignment: AlignmentDirectional.bottomEnd,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(text, style: const TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Palette.foam)),
            ),
          ),
        );
        return Stack(
          children: <Widget>[
            const Positioned.fill(child: HarborSeaArt()),
            Positioned(top: 0, left: 0, right: 0, height: coast.top, child: band('coast T ${coast.top.toStringAsFixed(0)}')),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: coast.bottom,
              child: band('coast B ${coast.bottom.toStringAsFixed(0)}'),
            ),
            Positioned.fill(
              child: HarborMoored(
                mooringLine: true,
                extra: const EdgeInsetsDirectional.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const StageMarker(key: ValueKey<String>('moored marker'), label: 'HarborMoored', color: Palette.sea),
                    const Spacer(),
                    Text(
                      'This is the sea: it reads the coast from MediaQuery and hands it to everything on it.',
                      style: TextStyle(color: Palette.night.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// `HarborSea`: the root every harbor floats on.
class HarborSeaEntry extends StatefulWidget {
  const HarborSeaEntry({super.key});

  @override
  State<HarborSeaEntry> createState() => _HarborSeaEntryState();
}

class _HarborSeaEntryState extends State<HarborSeaEntry> {
  bool _nested = false;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSea',
    realWorld:
        'The open sea runs out to the horizon, and every harbor on every coast is built on it. It has no quays of its '
        'own; it is just the water, and the coast around it.',
    inYourApp:
        'The root. Mount it once, above the Navigator (MaterialApp.builder), so every route, dialog and sheet shares its '
        'coast, its tide gauge and its signals. It moves nothing out of the keyboard\'s way itself. A sea mounted inside '
        'another harbor is a world of its own: it reads whatever MediaQuery says there (an outer pier included) as coast.',
    art: const HarborSeaArt(),
    controls: <Widget>[
      ToggleControl(label: 'nested HarborSea', value: _nested, onChanged: (final bool v) => setState(() => _nested = v)),
    ],
    code: _nested
        ? 'Harbor(\n'
              '  top: [HarborDock.pier(child: Header())],\n'
              '  // A world of its own: the pier reads as its coast.\n'
              '  body: HarborSea(child: preview),\n'
              ')'
        : 'MaterialApp(\n'
              '  builder: (context, child) => HarborSea(\n'
              '    margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),\n'
              '    child: child!,\n'
              '  ),\n'
              '  home: const HomePage(),\n'
              ')',
    stage: (final BuildContext context) => _nested
        ? Harbor(
            debugLabel: 'outer',
            top: <HarborDock>[
              HarborDock.pier(
                backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.8)),
                child: const StageHeader(key: ValueKey<String>('outer pier'), title: 'outer Harbor pier'),
              ),
            ],
            body: const HarborSea(
              margin: EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: _SeaView(label: 'nested HarborSea'),
            ),
          )
        : const _SeaView(label: 'the stage\'s HarborSea'),
  );
}

/// `Harbor(newPort: true)`: a harbor that starts fresh, with only the coast.
class NewPortEntry extends StatefulWidget {
  const NewPortEntry({super.key});

  @override
  State<NewPortEntry> createState() => _NewPortEntryState();
}

class _NewPortEntryState extends State<NewPortEntry> {
  bool _newPort = false;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'Harbor(newPort: true)',
    realWorld:
        'Further up the coast is another harbor town with its own quays and breakwater. Ships that put in there tie up '
        'to its walls; the first town\'s piers are nothing to them.',
    inYourApp:
        'A harbor inside another sees the outer harbor\'s docks as part of its coast, the way a component inside a page '
        'should. A new port (a route, a sheet, a dialog) starts fresh: it sees only the coast, so its header goes under '
        'the status bar, not under the page\'s header.',
    art: const NewPortArt(),
    controls: <Widget>[
      ToggleControl(label: 'newPort', value: _newPort, onChanged: (final bool v) => setState(() => _newPort = v)),
    ],
    code:
        'Harbor(\n'
        '  top: [HarborDock.pier(child: PageHeader())],\n'
        '  body: Harbor(\n'
        '    newPort: $_newPort,\n'
        '    top: [HarborDock.pier(child: InnerHeader())],\n'
        '    body: HarborFairway(slivers: [rows]),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      debugLabel: 'outer Harbor',
      top: <HarborDock>[
        HarborDock.pier(
          backdrop: IgnorePointer(child: ColoredBox(color: Palette.night.withValues(alpha: 0.55))),
          debugLabel: 'outer pier',
          child: const StageHeader(key: ValueKey<String>('outer header'), title: 'outer Harbor'),
        ),
      ],
      body: StageProbe(
        label: 'outer Harbor body',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Palette.brass.withValues(alpha: 0.6), width: 2))),
            child: Harbor(
              newPort: _newPort,
              debugLabel: 'inner Harbor',
              top: <HarborDock>[
                HarborDock.pier(
                  wake: const HarborWake.fade(length: 12),
                  backdrop: ColoredBox(color: Palette.brass.withValues(alpha: 0.75)),
                  debugLabel: 'inner pier',
                  child: StageHeader(
                    key: const ValueKey<String>('inner header'),
                    title: 'Harbor(newPort: $_newPort)',
                    color: Palette.night,
                  ),
                ),
              ],
              body: StageProbe(
                label: 'inner Harbor body',
                child: HarborFairway(
                  slivers: <Widget>[
                    SliverList.builder(itemCount: 20, itemBuilder: (final BuildContext context, final int i) => StageRow(index: i)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// `HarborSizing.hugBody`: a harbor as tall as its body and quays.
class HugBodyEntry extends StatefulWidget {
  const HugBodyEntry({super.key});

  @override
  State<HugBodyEntry> createState() => _HugBodyEntryState();
}

class _HugBodyEntryState extends State<HugBodyEntry> {
  HarborSizing _sizing = HarborSizing.hugBody;
  double _height = 180;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSizing.hugBody',
    realWorld:
        'A davit on the quay hoists a skiff out of the water. The winch takes in just enough cable to lift the boat clear, '
        'so the load hangs exactly as tall as the boat it carries.',
    inYourApp:
        'A harbor that is as tall as its body and quays, not as tall as the space it is given: a content-sized sheet or '
        'panel. HarborSizing.fill (the default) takes the whole height, as a page does.',
    art: const HugBodyArt(),
    controls: <Widget>[
      ChoiceControl<HarborSizing>(
        label: 'sizing',
        values: HarborSizing.values,
        value: _sizing,
        labelOf: (final HarborSizing s) => s.name,
        onChanged: (final HarborSizing s) => setState(() => _sizing = s),
      ),
      SliderControl(label: 'body height', value: _height, min: 60, max: 520, onChanged: (final double v) => setState(() => _height = v)),
    ],
    code:
        'Harbor(\n'
        '  sizing: HarborSizing.${_sizing.name},\n'
        '  bottom: [HarborDock.quay(child: Actions())],\n'
        '  body: SizedBox(height: ${_height.toStringAsFixed(0)}, child: Crate()),\n'
        ')',
    stage: (final BuildContext context) => Stack(
      children: <Widget>[
        // The page underneath, dimmed.
        Positioned.fill(
          child: Opacity(
            opacity: 0.35,
            child: HarborMoored(
              edges: const <HarborEdge>{HarborEdge.top},
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[for (int i = 0; i < 14; i++) StageRow(index: i)],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Palette.night,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: <BoxShadow>[BoxShadow(blurRadius: 14, color: Colors.black54)],
            ),
            child: HarborCastOff(
              edges: const <HarborEdge>{HarborEdge.top},
              child: Harbor(
                key: const ValueKey<String>('sized harbor'),
                sizing: _sizing,
                debugLabel: 'hugBody harbor',
                bottom: const <HarborDock>[
                  HarborDock.quay(
                    backdrop: QuayStones(),
                    child: StageBar(label: 'HarborDock.quay', icon: Icons.precision_manufacturing_rounded),
                  ),
                ],
                body: StageProbe(
                  label: 'Harbor body (${_sizing.name})',
                  child: SizedBox(
                    key: const ValueKey<String>('sized body'),
                    height: _height,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(width: 72, height: 72, child: CrateArt()),
                          const SizedBox(height: 6),
                          Text(
                            'body ${_height.toStringAsFixed(0)} tall',
                            style: const TextStyle(fontFamily: 'Menlo', color: Palette.brass, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
