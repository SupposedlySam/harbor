import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import 'art/tide_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// The tide: the keyboard, and how docks meet it.
final List<GuideEntry> tideEntries = <GuideEntry>[
  GuideEntry(
    id: 'tide-of',
    className: 'HarborTide.of',
    group: GuideGroup.tide,
    realWorld: 'A harbor tide clock on a post, and a tide staff in the water',
    art: (final BuildContext context) => const HarborTideArt(),
    page: (final BuildContext context) => const TideOfEntry(),
  ),
  GuideEntry(
    id: 'tide-float',
    className: 'HarborTideStance.float',
    group: GuideGroup.tide,
    realWorld: 'A floating dock on guide piles, rising and falling with the water',
    art: (final BuildContext context) => const FloatingDockArt(),
    page: (final BuildContext context) => const FloatEntry(),
  ),
  GuideEntry(
    id: 'tide-pilings',
    className: 'HarborTideStance.pilings',
    group: GuideGroup.tide,
    realWorld: 'A fixed pier on tall pilings, the water rising up the piles',
    art: (final BuildContext context) => const PilingsArt(),
    page: (final BuildContext context) => const PilingsEntry(),
  ),
  GuideEntry(
    id: 'tide-float-pilings',
    className: 'HarborTideStance.float + .pilings',
    group: GuideGroup.tide,
    realWorld: 'A floating pontoon moored beside a fixed pier',
    art: (final BuildContext context) => const FloatAndPilingsArt(),
    page: (final BuildContext context) => const FloatAndPilingsEntry(),
  ),
  GuideEntry(
    id: 'tide-dry-dock',
    className: 'HarborTideStance.dryDock',
    group: GuideGroup.tide,
    realWorld: 'A graving dry dock: a ship on keel blocks, the gate holding the sea out',
    art: (final BuildContext context) => const DryDockArt(),
    page: (final BuildContext context) => const DryDockEntry(),
  ),
  GuideEntry(
    id: 'tide-coast',
    className: 'HarborCoastStance',
    group: GuideGroup.tide,
    realWorld: 'A seawall, with high and low water marked on its face',
    art: (final BuildContext context) => const SeawallArt(),
    page: (final BuildContext context) => const CoastStanceEntry(),
  ),
  GuideEntry(
    id: 'tide-withdraws',
    className: 'HarborDock.withdrawsAtHighTide',
    group: GuideGroup.tide,
    realWorld: 'A slipway, with a boat hauled out before the tide comes up the ramp',
    art: (final BuildContext context) => const SlipwayArt(),
    page: (final BuildContext context) => const WithdrawsAtHighTideEntry(),
  ),
  GuideEntry(
    id: 'tide-body-clears',
    className: 'Harbor.bodyClearsTide',
    group: GuideGroup.tide,
    realWorld: 'A lock gate, holding the water back or letting it in',
    art: (final BuildContext context) => const LockGateArt(),
    page: (final BuildContext context) => const BodyClearsTideEntry(),
  ),
];

/// The surfaces the tide pages' docks are drawn in.
const Color _pontoon = Color(0xFF1E6A93);
final Color _pierDeck = Palette.plank.withValues(alpha: 0.95);
const Color _stoneDock = Palette.stoneDark;

/// The stage's header: a pier naming the page's class.
HarborDock _header(final String title) => HarborDock.pier(
  wake: const HarborWake.fade(length: 12),
  backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.85)),
  debugLabel: 'header',
  child: StageHeader(key: const ValueKey<String>('stage header'), title: title),
);

/// A floating composer: a bottom quay that rides the keyboard.
HarborDock _composerDock({final HarborTideStance tide = HarborTideStance.float, final String? label}) =>
    HarborDock.quay(
      tide: tide,
      backdrop: const ColoredBox(color: _pontoon),
      debugLabel: 'composer',
      child: StageBar(
        key: const ValueKey<String>('composer'),
        label: label ?? 'tide: ${tide.name}',
        icon: Icons.edit_rounded,
      ),
    );

/// A tab bar on pilings: a bottom quay that stays put under the keyboard.
HarborDock _tabBarDock() => HarborDock.quay(
  backdrop: ColoredBox(color: _pierDeck),
  debugLabel: 'tab bar',
  child: const StageBar(key: ValueKey<String>('tab bar'), label: 'tide: pilings', icon: Icons.grid_view_rounded),
);

/// The harbor's body on a tide page: a list of boats, marked where it ends
/// and probed for what it's told.
class _Body extends StatelessWidget {
  const _Body({this.label = 'Harbor body', this.child});

  final String label;
  final Widget? child;

  @override
  Widget build(final BuildContext context) => StageProbe(
    label: label,
    child: SizedBox.expand(
      key: const ValueKey<String>('tide body'),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child:
                child ??
                HarborFairway(
                  slivers: <Widget>[
                    SliverList.builder(
                      itemCount: 30,
                      itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
                    ),
                  ],
                ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: _BodyEnd())),
        ],
      ),
    ),
  );
}

/// A brass line where the body ends.
class _BodyEnd extends StatelessWidget {
  const _BodyEnd();

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: Palette.brass, borderRadius: BorderRadius.circular(6)),
        child: const Text(
          'body ends here',
          style: TextStyle(fontFamily: 'Menlo', fontSize: 11, fontWeight: FontWeight.w700, color: Palette.night),
        ),
      ),
      Container(height: 3, color: Palette.brass),
    ],
  );
}

String _f(final double v) => v.toStringAsFixed(0);

// 1. HarborTide.of ------------------------------------------------------------

/// `HarborTide.of`: reading the tide.
class TideOfEntry extends StatefulWidget {
  const TideOfEntry({super.key});

  @override
  State<TideOfEntry> createState() => _TideOfEntryState();
}

class _TideOfEntryState extends State<TideOfEntry> {
  final StageSettings _settings = StageSettings();
  bool _clears = true;

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    settings: _settings,
    className: 'HarborTide.of',
    // The whole phone: the readout sits at the top of the body and the keyboard it reads comes up
    // from the bottom; a bottom crop cut the readout off until the tide was in.
    realWorld:
        'A harbor posts its tide on a clock at the quay, its hand pointing from low water to high, and a tide staff '
        'stands in the water so anyone can read the height off its bands.',
    inYourApp:
        'Reads the keyboard as the harbor sees it: its full height, how much of it still reaches this spot (remaining), '
        'its high-water mark and its phase. For information, never for layout. highWater is an estimate (40% of the '
        'screen) until the keyboard settles high once; drag the tide all the way up and let go to see it settle.',
    art: const HarborTideArt(),
    controls: <Widget>[
      ToggleControl(label: 'bodyClearsTide', value: _clears, onChanged: (final bool v) => setState(() => _clears = v)),
    ],
    code:
        'Harbor(\n'
        '  bodyClearsTide: $_clears,\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  body: Builder(builder: (context) {\n'
        '    final tide = HarborTide.of(context);\n'
        '    return Text(\'\${tide.height} · \${tide.remaining} · \'\n'
        '        \'\${tide.highWater} · \${tide.phase}\');\n'
        '  }),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      bodyClearsTide: _clears,
      top: <HarborDock>[_header('HarborTide.of')],
      body: StageProbe(
        label: 'Harbor body',
        child: ColoredBox(
          key: const ValueKey<String>('tide body'),
          color: Palette.deepSea,
          child: HarborMoored(
            edges: const <HarborEdge>{HarborEdge.top},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: _TideReadout(keyboard: _settings.tideHeight),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A tide card: everything `HarborTide.of` says where it sits.
class _TideReadout extends StatelessWidget {
  const _TideReadout({required this.keyboard});

  /// The stage keyboard's height, to compare with.
  final double keyboard;

  @override
  Widget build(final BuildContext context) {
    final HarborTideState tide = HarborTide.of(context);
    Widget line(final String name, final String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 170,
            child: Text(
              name,
              style: TextStyle(fontFamily: 'Menlo', fontSize: 14, color: Palette.foam.withValues(alpha: 0.75)),
            ),
          ),
          Text(
            value,
            key: ValueKey<String>('tide $name'),
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Palette.brass,
            ),
          ),
        ],
      ),
    );
    final double fill = tide.highWater <= 0 ? 0.0 : (tide.height / tide.highWater).clamp(0.0, 1.0);
    return Container(
      key: const ValueKey<String>('tide readout'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.night.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.brass.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'HarborTide.of(context)',
            style: TextStyle(fontFamily: 'Menlo', fontSize: 15, fontWeight: FontWeight.w700, color: Palette.foam),
          ),
          const SizedBox(height: 8),
          line('height', _f(tide.height)),
          line('remaining', _f(tide.remaining)),
          line('highWater', _f(tide.highWater)),
          line('highWaterIsEstimate', '${tide.highWaterIsEstimate}'),
          line('phase', tide.phase.name),
          line('isIn', '${tide.isIn}'),
          const SizedBox(height: 10),
          // A little tide staff: the height against the high-water mark.
          Text(
            tide.highWaterIsEstimate ? 'high water: an estimate (40% of the screen)' : 'high water: settled',
            style: TextStyle(fontSize: 12, color: Palette.foam.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(child: ColoredBox(color: Color(0xFF0E2236))),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: const ColoredBox(color: Palette.shallows),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'stage keyboard ${_f(keyboard)}',
            style: TextStyle(fontFamily: 'Menlo', fontSize: 12, color: Palette.foam.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// 2. HarborTideStance.float ----------------------------------------------------

/// `HarborTideStance.float`: a dock that rides the keyboard.
class FloatEntry extends StatefulWidget {
  const FloatEntry({super.key});

  @override
  State<FloatEntry> createState() => _FloatEntryState();
}

class _FloatEntryState extends State<FloatEntry> {
  HarborTideStance _tide = HarborTideStance.float;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborTideStance.float',
    focus: const StageFocus.bottom(460),
    realWorld:
        'A floating dock sits on air drums and is held to tall guide piles by hoops. When the tide comes in it slides up '
        'the piles, so its deck is always just above the water and boats can always come alongside.',
    inYourApp:
        'A bottom dock that rides up on the keyboard and sits on the waterline: a composer, a sheet\'s footer. Its coast '
        'is live, so the home indicator\'s height goes away once the keyboard covers it. Switch to pilings to compare.',
    art: const FloatingDockArt(),
    controls: <Widget>[
      ChoiceControl<HarborTideStance>(
        label: 'tide',
        values: const <HarborTideStance>[HarborTideStance.float, HarborTideStance.pilings],
        value: _tide,
        labelOf: (final HarborTideStance t) => t.name,
        onChanged: (final HarborTideStance t) => setState(() => _tide = t),
      ),
    ],
    code:
        'Harbor(\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  bottom: [\n'
        '    HarborDock.quay(\n'
        '      tide: HarborTideStance.${_tide.name},\n'
        '      child: Composer(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborFairway(slivers: [messages]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_header('HarborTideStance.float')],
      bottom: <HarborDock>[_composerDock(tide: _tide)],
      body: const _Body(),
    ),
  );
}

// 3. HarborTideStance.pilings --------------------------------------------------

/// `HarborTideStance.pilings`: a dock the keyboard covers.
class PilingsEntry extends StatelessWidget {
  const PilingsEntry({super.key});

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborTideStance.pilings',
    focus: const StageFocus.bottom(460),
    realWorld:
        'A fixed pier is built high on tall pilings driven into the seabed. The deck never moves: the tide climbs the '
        'piles underneath it, and the weed and barnacles on them show how high the water reaches.',
    inYourApp:
        'A bottom dock that stays where it is while the keyboard comes up over it: a tab bar. It is the default. Its coast '
        'is steady, so it keeps the home indicator\'s height under the keyboard, and the body still ends at the '
        'waterline, above the keyboard, not above the hidden tab bar.',
    art: const PilingsArt(),
    code:
        'Harbor(\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  bottom: [\n'
        '    HarborDock.quay(\n'
        '      tide: HarborTideStance.pilings, // the default\n'
        '      child: TabBar(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborFairway(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_header('HarborTideStance.pilings')],
      bottom: <HarborDock>[_tabBarDock()],
      body: const _Body(),
    ),
  );
}

// 4. Float and pilings together ------------------------------------------------

/// A floating composer over a tab bar on pilings.
class FloatAndPilingsEntry extends StatelessWidget {
  const FloatAndPilingsEntry({super.key});

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborTideStance.float + .pilings',
    focus: const StageFocus.bottom(480),
    realWorld:
        'A floating pontoon is often moored beside a fixed pier. At low water the pontoon sits well below the pier deck; '
        'as the tide comes in it rides up its guide piles while the pier stays exactly where it was built.',
    inYourApp:
        'bottom: [composer (float), tabBar (pilings)]. At low tide the composer sits on the tab bar. As the keyboard '
        'rises past the tab bar, the composer rides on the keyboard and the tab bar stays under it.',
    art: const FloatAndPilingsArt(),
    code:
        'Harbor(\n'
        '  bottom: [\n'
        '    HarborDock.quay(tide: HarborTideStance.float, child: Composer()),\n'
        '    HarborDock.quay(tide: HarborTideStance.pilings, child: TabBar()),\n'
        '  ],\n'
        '  body: HarborFairway(slivers: [messages]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_header('float + pilings')],
      bottom: <HarborDock>[_composerDock(), _tabBarDock()],
      body: const _Body(),
    ),
  );
}

// 5. HarborTideStance.dryDock + HarborDryDock -----------------------------------

/// `HarborTideStance.dryDock` with a `HarborDryDock` inside.
class DryDockEntry extends StatefulWidget {
  const DryDockEntry({super.key});

  @override
  State<DryDockEntry> createState() => _DryDockEntryState();
}

class _DryDockEntryState extends State<DryDockEntry> {
  bool _showsAtHighTide = false;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborTideStance.dryDock',
    focus: const StageFocus.bottom(480),
    realWorld:
        'A graving dry dock is a stone basin with a gate. With the gate shut and the water pumped out, a ship sits on '
        'keel blocks on the dry floor; open the gate and the sea fills exactly the same basin.',
    inYourApp:
        'A bottom dock that keeps the keyboard\'s ground at high-water height whether the keyboard is up or down. Its '
        'child holds a HarborDryDock: at low tide it shows a panel (these swatches) in the keyboard\'s place, and at high '
        'tide the keyboard covers that exact ground, so nothing above moves. Raise the tide once so high water settles.',
    art: const DryDockArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'showsChildAtHighTide',
        value: _showsAtHighTide,
        onChanged: (final bool v) => setState(() => _showsAtHighTide = v),
      ),
    ],
    code:
        'Harbor(\n'
        '  bottom: [\n'
        '    HarborDock.quay(\n'
        '      tide: HarborTideStance.dryDock,\n'
        '      child: Column(mainAxisSize: MainAxisSize.min, children: [\n'
        '        StyleTabs(),\n'
        '        HarborDryDock(\n'
        '${_showsAtHighTide ? '          showsChildAtHighTide: true,\n' : ''}'
        '          child: ColorSwatches(),\n'
        '        ),\n'
        '      ]),\n'
        '    ),\n'
        '  ],\n'
        '  body: editor,\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_header('HarborTideStance.dryDock')],
      bottom: <HarborDock>[
        HarborDock.quay(
          tide: HarborTideStance.dryDock,
          backdrop: const ColoredBox(color: _stoneDock),
          debugLabel: 'dry dock',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _StyleTabs(),
              HarborDryDock(
                key: const ValueKey<String>('dry dock ground'),
                showsChildAtHighTide: _showsAtHighTide,
                child: const _Swatches(),
              ),
            ],
          ),
        ),
      ],
      body: const _Body(),
    ),
  );
}

/// The dry dock's tab row, reading its high-water mark.
class _StyleTabs extends StatelessWidget {
  const _StyleTabs();

  @override
  Widget build(final BuildContext context) {
    final HarborTideState tide = HarborTide.of(context);
    return Container(
      key: const ValueKey<String>('dry dock tabs'),
      height: 48,
      color: Palette.stone,
      child: HarborMooringLine(
        child: Row(
          children: <Widget>[
            const Icon(Icons.format_bold_rounded, color: Palette.foam),
            const SizedBox(width: 10),
            const Icon(Icons.palette_rounded, color: Palette.brass),
            const SizedBox(width: 10),
            const Icon(Icons.keyboard_rounded, color: Palette.foam),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'highWater ${_f(tide.highWater)}${tide.highWaterIsEstimate ? ' (estimate)' : ''}',
                key: const ValueKey<String>('dry dock high water'),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Palette.foam,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color swatches: the panel that takes the keyboard's place.
class _Swatches extends StatelessWidget {
  const _Swatches();

  static const List<Color> _colors = <Color>[
    ...Palette.hulls,
    Palette.brass,
    Palette.shallows,
    Palette.plank,
    Palette.rope,
  ];

  @override
  Widget build(final BuildContext context) => ColoredBox(
    key: const ValueKey<String>('dry dock swatches'),
    color: Palette.stoneDark,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            for (final Color c in _colors)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// 6. HarborCoastStance --------------------------------------------------------

/// `HarborCoastStance`: how a dock takes the coast on its edge.
class CoastStanceEntry extends StatefulWidget {
  const CoastStanceEntry({super.key});

  @override
  State<CoastStanceEntry> createState() => _CoastStanceEntryState();
}

class _CoastStanceEntryState extends State<CoastStanceEntry> {
  HarborCoastStance _coast = HarborCoastStance.live;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborCoastStance',
    focus: const StageFocus.bottom(460),
    realWorld:
        'A seawall is where the land meets the sea: the coast itself. High and low water are marked on its face, and how '
        'much of the wall shows depends on the tide.',
    inYourApp:
        'How a dock takes the coast on its edge (here, the home indicator). live: as it is now, so it goes to zero while '
        'the keyboard is up (floating docks). steady: as it is with the keyboard down, so the dock holds its height '
        '(pilings). none: not at all, for a child that runs to the screen\'s edge itself (dry docks). The hatched band is '
        'the coast the dock took.',
    art: const SeawallArt(),
    controls: <Widget>[
      ChoiceControl<HarborCoastStance>(
        label: 'coast',
        values: HarborCoastStance.values,
        value: _coast,
        labelOf: (final HarborCoastStance c) => c.name,
        onChanged: (final HarborCoastStance c) => setState(() => _coast = c),
      ),
    ],
    code:
        'HarborDock.quay(\n'
        '  tide: HarborTideStance.float,\n'
        '  coast: HarborCoastStance.${_coast.name},\n'
        '  child: Composer(),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_header('HarborCoastStance')],
      bottom: <HarborDock>[
        HarborDock.quay(
          tide: HarborTideStance.float,
          coast: _coast,
          backdrop: const _CoastGround(barHeight: 56),
          debugLabel: 'composer',
          child: StageBar(
            key: const ValueKey<String>('composer'),
            label: 'coast: ${_coast.name}',
            icon: Icons.edit_rounded,
          ),
        ),
      ],
      body: const _Body(),
    ),
  );
}

/// A dock's ground: the bar's part, and the coast it took, hatched, with the
/// dock's measured height.
class _CoastGround extends StatelessWidget {
  const _CoastGround({required this.barHeight});

  final double barHeight;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    key: const ValueKey<String>('coast dock ground'),
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final double height = constraints.maxHeight;
      final double coast = (height - barHeight).clamp(0.0, double.infinity);
      return Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: _pontoon)),
          if (coast > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: coast,
              child: CustomPaint(
                painter: const _HatchPainter(),
                child: Center(
                  child: Text(
                    'coast ${_f(coast)}',
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Palette.night,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 10,
            child: Text(
              'dock ${_f(height)}',
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Palette.brass,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.rope);
    final Paint line = Paint()
      ..color = Palette.plank.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -size.height; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(final _HatchPainter oldDelegate) => false;
}

// 7. HarborDock.withdrawsAtHighTide ---------------------------------------------

/// `HarborDock.withdrawsAtHighTide`: a tool strip that leaves while the keyboard is up.
class WithdrawsAtHighTideEntry extends StatefulWidget {
  const WithdrawsAtHighTideEntry({super.key});

  @override
  State<WithdrawsAtHighTideEntry> createState() => _WithdrawsAtHighTideEntryState();
}

class _WithdrawsAtHighTideEntryState extends State<WithdrawsAtHighTideEntry> {
  bool _withdraws = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborDock.withdrawsAtHighTide',
    focus: const StageFocus.bottom(480),
    realWorld:
        'Some boats live on a slipway: a ramp into the water. Before the tide comes up the ramp they are hauled out on '
        'their cradles by the winch, and launched again when it suits.',
    inYourApp:
        'A dock that withdraws while the keyboard is up and comes back when it goes down: a tool strip that would '
        'otherwise park mid-screen on top of a floating composer. It gives its ground back, so the body grows into it.',
    art: const SlipwayArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'withdrawsAtHighTide',
        value: _withdraws,
        onChanged: (final bool v) => setState(() => _withdraws = v),
      ),
    ],
    code:
        'Harbor(\n'
        '  bottom: [\n'
        '    HarborDock.quay(\n'
        '      tide: HarborTideStance.float,\n'
        '      withdrawsAtHighTide: $_withdraws,\n'
        '      child: ToolStrip(),\n'
        '    ),\n'
        '    HarborDock.quay(tide: HarborTideStance.float, child: Composer()),\n'
        '  ],\n'
        '  body: notes,\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_header('withdrawsAtHighTide')],
      bottom: <HarborDock>[
        HarborDock.quay(
          tide: HarborTideStance.float,
          withdrawsAtHighTide: _withdraws,
          backdrop: ColoredBox(color: _pierDeck),
          debugLabel: 'tool strip',
          child: _ToolStrip(withdraws: _withdraws),
        ),
        _composerDock(),
      ],
      body: const _Body(),
    ),
  );
}

class _ToolStrip extends StatelessWidget {
  const _ToolStrip({required this.withdraws});

  final bool withdraws;

  @override
  Widget build(final BuildContext context) => SizedBox(
    key: const ValueKey<String>('tool strip'),
    height: 44,
    child: HarborMooringLine(
      child: Row(
        children: <Widget>[
          for (final IconData icon in const <IconData>[
            Icons.format_bold_rounded,
            Icons.format_italic_rounded,
            Icons.image_rounded,
            Icons.attach_file_rounded,
          ]) ...<Widget>[Icon(icon, color: Palette.sail, size: 22), const SizedBox(width: 14)],
          Expanded(
            child: Text(
              'withdrawsAtHighTide: $withdraws',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Palette.sail,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// 8. Harbor.bodyClearsTide ------------------------------------------------------

/// `Harbor.bodyClearsTide`: whether the body ends at the waterline.
class BodyClearsTideEntry extends StatefulWidget {
  const BodyClearsTideEntry({super.key});

  @override
  State<BodyClearsTideEntry> createState() => _BodyClearsTideEntryState();
}

class _BodyClearsTideEntryState extends State<BodyClearsTideEntry> {
  bool _clears = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'Harbor.bodyClearsTide',
    focus: const StageFocus.bottom(480),
    realWorld:
        'A lock gate holds the water back: on one side the level stays low, on the other it is high. Open the paddles and '
        'the water comes through until both sides match.',
    inYourApp:
        'On (the default), the body ends at the waterline, like a resizing Scaffold: the probe reads padding 0 and keyboard '
        '0. Off, the body runs on under the keyboard and is told how far it reaches in MediaQuery.viewInsets. Either '
        'way, the HarborMoored box keeps clear of it.',
    art: const LockGateArt(),
    controls: <Widget>[
      ToggleControl(label: 'bodyClearsTide', value: _clears, onChanged: (final bool v) => setState(() => _clears = v)),
    ],
    code:
        'Harbor(\n'
        '  bodyClearsTide: $_clears,\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  body: Stack(children: [\n'
        '    HarborFairway(slivers: [boats]),\n'
        '    Align(\n'
        '      alignment: Alignment.bottomCenter,\n'
        '      child: HarborMoored(edges: {HarborEdge.bottom}, child: SaveButton()),\n'
        '    ),\n'
        '  ]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      bodyClearsTide: _clears,
      top: <HarborDock>[_header('Harbor.bodyClearsTide')],
      body: _Body(
        label: 'Harbor body (bodyClearsTide: $_clears)',
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: HarborFairway(
                slivers: <Widget>[
                  SliverList.builder(
                    itemCount: 30,
                    itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: HarborMoored(
                edges: <HarborEdge>{HarborEdge.bottom},
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: StageMarker(
                    key: ValueKey<String>('moored marker'),
                    label: 'HarborMoored',
                    color: Palette.buoyRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
