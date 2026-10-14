import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import 'art/tide_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// The keyboard, and how bars meet it.
final List<GuideEntry> tideEntries = <GuideEntry>[
  GuideEntry(
    id: 'tide-of',
    className: 'HarborKeyboard.of',
    group: GuideGroup.tide,
    realWorld: 'Like a tide clock and a tide staff: it reads how far up the keyboard is',
    art: (final BuildContext context) => const HarborTideArt(),
    page: (final BuildContext context) => const TideOfEntry(),
  ),
  GuideEntry(
    id: 'tide-float',
    className: 'HarborKeyboardStance.rides',
    group: GuideGroup.tide,
    realWorld: 'Like a floating dock on guide piles: the bar rises with the keyboard',
    art: (final BuildContext context) => const FloatingDockArt(),
    page: (final BuildContext context) => const FloatEntry(),
  ),
  GuideEntry(
    id: 'tide-pilings',
    className: 'HarborKeyboardStance.stays',
    group: GuideGroup.tide,
    realWorld: 'Like a pier on tall pilings: the bar stays put and the keyboard comes up over it',
    art: (final BuildContext context) => const PilingsArt(),
    page: (final BuildContext context) => const PilingsEntry(),
  ),
  GuideEntry(
    id: 'tide-float-pilings',
    className: 'HarborKeyboardStance.rides + .stays',
    group: GuideGroup.tide,
    realWorld: 'Like a pontoon beside a fixed pier: one bar rides, the other stays',
    art: (final BuildContext context) => const FloatAndPilingsArt(),
    page: (final BuildContext context) => const FloatAndPilingsEntry(),
  ),
  GuideEntry(
    id: 'tide-dry-dock',
    className: 'HarborKeyboardStance.reserves',
    group: GuideGroup.tide,
    realWorld: 'Like a dry dock, the same basin wet or dry: the bar keeps the keyboard\'s space either way',
    art: (final BuildContext context) => const DryDockArt(),
    page: (final BuildContext context) => const DryDockEntry(),
  ),
  GuideEntry(
    id: 'tide-coast',
    className: 'HarborSystemEdgeStance',
    group: GuideGroup.tide,
    realWorld: 'Like a seawall marked with high and low water: how much of the system edge a bar takes',
    art: (final BuildContext context) => const SeawallArt(),
    page: (final BuildContext context) => const CoastStanceEntry(),
  ),
  GuideEntry(
    id: 'tide-withdraws',
    className: 'HarborBar.withdrawsAtHighTide',
    group: GuideGroup.tide,
    realWorld: 'Like a boat hauled up a slipway: the bar leaves while the keyboard is up',
    art: (final BuildContext context) => const SlipwayArt(),
    page: (final BuildContext context) => const WithdrawsAtHighTideEntry(),
  ),
  GuideEntry(
    id: 'tide-body-clears',
    className: 'HarborFrame.bodyClearsKeyboard',
    group: GuideGroup.tide,
    realWorld: 'Like a lock gate: the body ends at the keyboard, or runs on under it',
    art: (final BuildContext context) => const LockGateArt(),
    page: (final BuildContext context) => const BodyClearsTideEntry(),
  ),
];

/// The surfaces the keyboard pages' bars are drawn in.
const Color _composerColor = Color(0xFF1E6A93);
final Color _tabBarColor = Palette.plank.withValues(alpha: 0.95);
const Color _reserveColor = Palette.stoneDark;

/// The stage's header: an overlay bar naming the page's class.
HarborBar _header(final String title) => HarborBar.overlay(
  edgeEffect: const HarborEdgeEffect.fade(length: 12),
  backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.85)),
  debugLabel: 'header',
  child: StageHeader(key: const ValueKey<String>('stage header'), title: title),
);

/// A composer: a bottom solid bar that rides the keyboard.
HarborBar _composerBar({final HarborKeyboardStance keyboard = HarborKeyboardStance.rides, final String? label}) =>
    HarborBar.solid(
      keyboard: keyboard,
      backdrop: const ColoredBox(color: _composerColor),
      debugLabel: 'composer',
      child: StageBar(
        key: const ValueKey<String>('composer'),
        label: label ?? 'keyboard: ${keyboard.name}',
        icon: Icons.edit_rounded,
      ),
    );

/// A tab bar: a bottom solid bar that stays put under the keyboard.
HarborBar _tabBar() => HarborBar.solid(
  backdrop: ColoredBox(color: _tabBarColor),
  debugLabel: 'tab bar',
  child: const StageBar(key: ValueKey<String>('tab bar'), label: 'keyboard: stays', icon: Icons.grid_view_rounded),
);

/// The frame's body on a keyboard page: a list of boats, marked where it ends
/// and probed for what it's told.
class _Body extends StatelessWidget {
  const _Body({this.label = 'HarborFrame body', this.child});

  final String label;
  final Widget? child;

  @override
  Widget build(final BuildContext context) => StageProbe(
    label: label,
    child: SizedBox.expand(
      key: const ValueKey<String>('stage body'),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child:
                child ??
                HarborScrollView(
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

// 1. HarborKeyboard.of --------------------------------------------------------

/// `HarborKeyboard.of`: reading the keyboard.
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
    className: 'HarborKeyboard.of',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'height climbs to 336, phase goes opening then shown, and settledHeight settles at 336 instead of the 40% estimate.',
      ),
      TryStep(
        'Switch bodyClearsKeyboard off',
        'remaining jumps from 0 to 336: the body now runs under the keyboard, so all of it reaches the readout.',
      ),
      TryStep(
        'Tap the keyboard button again',
        'phase reads closing while it slides, then hidden; settledHeight keeps 336, the last height the keyboard settled at.',
      ),
      TryStep(
        'Drag the gauge beside the stage to about 5 and let go',
        'height, remaining and settledHeight all read 168: the settled height follows wherever the keyboard settles, down as well as up.',
      ),
    ],
    // The whole phone: the readout sits at the top of the body and the keyboard it reads comes up
    // from the bottom; a bottom crop cut the readout off until the keyboard was up.
    realWorld:
        'Like a tide clock at the quay and a tide staff in the water, which anyone can read but nothing is built on: '
        'it tells you how far up the keyboard is.',
    inYourApp:
        'Reads the keyboard as the frame sees it: its full height, how much of it still reaches this spot (remaining), '
        'its settled height and its phase. For information, never for layout. settledHeight is an estimate (40% of '
        'the screen) until the keyboard settles once; bring the keyboard all the way up and let go to see it settle.',
    art: const HarborTideArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'bodyClearsKeyboard',
        value: _clears,
        onChanged: (final bool v) => setState(() => _clears = v),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  bodyClearsKeyboard: $_clears,\n'
        '  top: [HarborBar.overlay(child: Header())],\n'
        '  body: Builder(builder: (context) {\n'
        '    final keyboard = HarborKeyboard.of(context);\n'
        '    return Text(\'\${keyboard.height} · \${keyboard.remaining} · \'\n'
        '        \'\${keyboard.settledHeight} · \${keyboard.phase}\');\n'
        '  }),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      bodyClearsKeyboard: _clears,
      top: <HarborBar>[_header('HarborKeyboard.of')],
      body: StageProbe(
        label: 'HarborFrame body',
        child: ColoredBox(
          key: const ValueKey<String>('stage body'),
          color: Palette.deepSea,
          child: HarborClear(
            edges: const <HarborEdge>{HarborEdge.top},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: _KeyboardReadout(keyboard: _settings.tideHeight),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A keyboard card: everything `HarborKeyboard.of` says where it sits.
class _KeyboardReadout extends StatelessWidget {
  const _KeyboardReadout({required this.keyboard});

  /// The stage keyboard's height, to compare with.
  final double keyboard;

  @override
  Widget build(final BuildContext context) {
    final HarborKeyboardState state = HarborKeyboard.of(context);
    Widget line(final String name, final String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 200,
            child: Text(
              name,
              style: TextStyle(fontFamily: 'Menlo', fontSize: 14, color: Palette.foam.withValues(alpha: 0.75)),
            ),
          ),
          Text(
            value,
            key: ValueKey<String>('keyboard $name'),
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
    final double fill = state.settledHeight <= 0 ? 0.0 : (state.height / state.settledHeight).clamp(0.0, 1.0);
    return Container(
      key: const ValueKey<String>('keyboard readout'),
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
            'HarborKeyboard.of(context)',
            style: TextStyle(fontFamily: 'Menlo', fontSize: 15, fontWeight: FontWeight.w700, color: Palette.foam),
          ),
          const SizedBox(height: 8),
          line('height', _f(state.height)),
          line('remaining', _f(state.remaining)),
          line('settledHeight', _f(state.settledHeight)),
          line('settledHeightIsEstimate', '${state.settledHeightIsEstimate}'),
          line('phase', state.phase.name),
          line('isShown', '${state.isShown}'),
          const SizedBox(height: 10),
          // A little gauge: the height against the settled height.
          Text(
            state.settledHeightIsEstimate
                ? 'settled height: an estimate (40% of the screen)'
                : 'settled height: measured',
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

// 2. HarborKeyboardStance.rides -----------------------------------------------

/// `HarborKeyboardStance.rides`: a bar that rides the keyboard.
class FloatEntry extends StatefulWidget {
  const FloatEntry({super.key});

  @override
  State<FloatEntry> createState() => _FloatEntryState();
}

class _FloatEntryState extends State<FloatEntry> {
  HarborKeyboardStance _keyboard = HarborKeyboardStance.rides;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborKeyboardStance.rides',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The composer rides up on top of the keyboard, and the list ends just above it.',
      ),
      TryStep(
        'Drag the gauge beside the stage slowly up from the bottom',
        'The composer waits until the keyboard has covered the home indicator, then sits on the keyboard\'s top at every height.',
      ),
      TryStep(
        'Pick keyboard: stays, with the keyboard up',
        'The composer drops back to the bottom and the keyboard covers it, but the list still ends at the keyboard\'s top edge.',
      ),
    ],
    focus: const StageFocus.bottom(460),
    realWorld:
        'Like a floating dock held to guide piles, which slides up them as the tide comes in: the bar rises with the '
        'keyboard and sits on top of it.',
    inYourApp:
        'A bottom bar that rides up on the keyboard and sits on its top edge: a composer, a sheet\'s footer. Its system '
        'edge is live, so the home indicator\'s height goes away once the keyboard covers it. Switch to stays to compare.',
    art: const FloatingDockArt(),
    controls: <Widget>[
      ChoiceControl<HarborKeyboardStance>(
        label: 'keyboard',
        values: const <HarborKeyboardStance>[HarborKeyboardStance.rides, HarborKeyboardStance.stays],
        value: _keyboard,
        labelOf: (final HarborKeyboardStance k) => k.name,
        onChanged: (final HarborKeyboardStance k) => setState(() => _keyboard = k),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  top: [HarborBar.overlay(child: Header())],\n'
        '  bottom: [\n'
        '    HarborBar.solid(\n'
        '      keyboard: HarborKeyboardStance.${_keyboard.name},\n'
        '      child: Composer(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborScrollView(slivers: [messages]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_header('HarborKeyboardStance.rides')],
      bottom: <HarborBar>[_composerBar(keyboard: _keyboard)],
      body: const _Body(),
    ),
  );
}

// 3. HarborKeyboardStance.stays -----------------------------------------------

/// `HarborKeyboardStance.stays`: a bar the keyboard covers.
class PilingsEntry extends StatelessWidget {
  const PilingsEntry({super.key});

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborKeyboardStance.stays',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The keyboard slides up over the tab bar, which stays put underneath: a bar that stays does not move with the keyboard.',
      ),
      TryStep(
        'Watch the brass body ends here line',
        'It sits on the keyboard\'s top edge, not on the hidden tab bar: the body still ends at the keyboard.',
      ),
      TryStep(
        'Drag the gauge beside the stage down to about 2',
        'The keyboard now covers only the tab bar\'s lower part, so the body ends at the tab bar until the keyboard passes it.',
      ),
    ],
    focus: const StageFocus.bottom(460),
    realWorld:
        'Like a fixed pier on tall pilings, whose deck never moves while the tide climbs the piles underneath: the bar '
        'stays put and the keyboard comes up over it.',
    inYourApp:
        'A bottom bar that stays where it is while the keyboard comes up over it: a tab bar. It is the default. Its '
        'system edge is steady, so it keeps the home indicator\'s height under the keyboard, and the body still ends '
        'at the keyboard\'s top, not above the hidden tab bar.',
    art: const PilingsArt(),
    code:
        'HarborFrame(\n'
        '  top: [HarborBar.overlay(child: Header())],\n'
        '  bottom: [\n'
        '    HarborBar.solid(\n'
        '      keyboard: HarborKeyboardStance.stays, // the default\n'
        '      child: TabBar(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborScrollView(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_header('HarborKeyboardStance.stays')],
      bottom: <HarborBar>[_tabBar()],
      body: const _Body(),
    ),
  );
}

// 4. Rides and stays together -------------------------------------------------

/// A composer that rides the keyboard over a tab bar that stays.
class FloatAndPilingsEntry extends StatelessWidget {
  const FloatAndPilingsEntry({super.key});

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborKeyboardStance.rides + .stays',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The composer lifts off the tab bar and rides the keyboard; the tab bar stays where it is, under the keyboard.',
      ),
      TryStep(
        'Drag the gauge beside the stage down to about 2',
        'The composer settles back on the tab bar: it only rides once the keyboard rises past the tab bar.',
      ),
      TryStep(
        'Watch the body ends here line as you drag',
        'It always sits on the composer\'s top edge: the body ends at the top bar, wherever the keyboard has put it.',
      ),
    ],
    focus: const StageFocus.bottom(480),
    realWorld:
        'Like a floating pontoon moored beside a fixed pier, which rides up its guide piles with the tide while the '
        'pier stays where it was built: one bar rides the keyboard, the other stays.',
    inYourApp:
        'bottom: [composer (rides), tabBar (stays)]. With the keyboard down the composer sits on the tab bar. As the '
        'keyboard rises past the tab bar, the composer rides on the keyboard and the tab bar stays under it.',
    art: const FloatAndPilingsArt(),
    code:
        'HarborFrame(\n'
        '  bottom: [\n'
        '    HarborBar.solid(keyboard: HarborKeyboardStance.rides, child: Composer()),\n'
        '    HarborBar.solid(keyboard: HarborKeyboardStance.stays, child: TabBar()),\n'
        '  ],\n'
        '  body: HarborScrollView(slivers: [messages]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_header('rides + stays')],
      bottom: <HarborBar>[_composerBar(), _tabBar()],
      body: const _Body(),
    ),
  );
}

// 5. HarborKeyboardStance.reserves + HarborKeyboardSpace ---------------------

/// `HarborKeyboardStance.reserves` with a `HarborKeyboardSpace` inside.
class DryDockEntry extends StatefulWidget {
  const DryDockEntry({super.key});

  @override
  State<DryDockEntry> createState() => _DryDockEntryState();
}

class _DryDockEntryState extends State<DryDockEntry> {
  bool _showsWhileShown = false;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborKeyboardStance.reserves',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The swatches give way to the keyboard and the tab row reads settledHeight 336, no longer an estimate.',
      ),
      TryStep(
        'Tap the keyboard button again',
        'The swatches come back in exactly the keyboard\'s ground, so the tab row and the list above it never move.',
      ),
      TryStep(
        'Switch showsChildWhileShown on, tap the keyboard button',
        'The swatches stay drawn while the keyboard slides over them, instead of vanishing the moment it starts in.',
      ),
      TryStep(
        'Drag the gauge beside the stage to about 5 and let go',
        'settledHeight drops to 168 and the ground shrinks to match: the bar keeps the height the keyboard last settled at.',
      ),
    ],
    focus: const StageFocus.bottom(480),
    realWorld:
        'Like a dry dock, a stone basin that is the same basin whether it is pumped dry or flooded: the bar keeps the '
        'keyboard\'s ground whether the keyboard is up or down.',
    inYourApp:
        'A bottom bar that keeps the keyboard\'s ground at its settled height whether the keyboard is up or down. Its '
        'child holds a HarborKeyboardSpace: with the keyboard down it shows a panel (these swatches) in the keyboard\'s '
        'place, and with it up the keyboard covers that exact ground, so nothing above moves. Show the keyboard once '
        'so its height settles.',
    art: const DryDockArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'showsChildWhileShown',
        value: _showsWhileShown,
        onChanged: (final bool v) => setState(() => _showsWhileShown = v),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  bottom: [\n'
        '    HarborBar.solid(\n'
        '      keyboard: HarborKeyboardStance.reserves,\n'
        '      child: Column(mainAxisSize: MainAxisSize.min, children: [\n'
        '        StyleTabs(),\n'
        '        HarborKeyboardSpace(\n'
        '${_showsWhileShown ? '          showsChildWhileShown: true,\n' : ''}'
        '          child: ColorSwatches(),\n'
        '        ),\n'
        '      ]),\n'
        '    ),\n'
        '  ],\n'
        '  body: editor,\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_header('HarborKeyboardStance.reserves')],
      bottom: <HarborBar>[
        HarborBar.solid(
          keyboard: HarborKeyboardStance.reserves,
          backdrop: const ColoredBox(color: _reserveColor),
          debugLabel: 'reserve',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _StyleTabs(),
              HarborKeyboardSpace(
                key: const ValueKey<String>('keyboard space'),
                showsChildWhileShown: _showsWhileShown,
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

/// The reserving bar's tab row, reading the keyboard's settled height.
class _StyleTabs extends StatelessWidget {
  const _StyleTabs();

  @override
  Widget build(final BuildContext context) {
    final HarborKeyboardState keyboard = HarborKeyboard.of(context);
    return Container(
      key: const ValueKey<String>('reserve tabs'),
      height: 48,
      color: Palette.stone,
      child: HarborClear.rowInsets(
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
                'settledHeight ${_f(keyboard.settledHeight)}${keyboard.settledHeightIsEstimate ? ' (estimate)' : ''}',
                key: const ValueKey<String>('reserve settled height'),
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
    key: const ValueKey<String>('reserve swatches'),
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

// 6. HarborSystemEdgeStance ---------------------------------------------------

/// `HarborSystemEdgeStance`: how a bar takes the system edge on its edge.
class CoastStanceEntry extends StatefulWidget {
  const CoastStanceEntry({super.key});

  @override
  State<CoastStanceEntry> createState() => _CoastStanceEntryState();
}

class _CoastStanceEntryState extends State<CoastStanceEntry> {
  HarborSystemEdgeStance _systemEdges = HarborSystemEdgeStance.live;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSystemEdgeStance',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The composer rides the keyboard and the hatched system edge 34 band goes: live drops the home indicator under the keyboard.',
      ),
      TryStep(
        'Pick systemEdges: steady',
        'The hatched band comes back between composer and keyboard: steady keeps the home indicator\'s height with the keyboard up or down.',
      ),
      TryStep(
        'Pick systemEdges: none, then tap the keyboard button',
        'No band at all, even with the keyboard down: the bar runs to the screen\'s edge, for a child that clears the edge itself.',
      ),
      TryStep(
        'Pick systemEdges: live, then Device: Android 3-button',
        'The band reads system edge 48: the system edge is whatever the device puts at the bottom, here its three-button bar.',
      ),
    ],
    focus: const StageFocus.bottom(460),
    realWorld:
        'Like a seawall, where the land meets the sea, with high and low water marked on its face: how much of the '
        'system edge a bar takes can change with the keyboard.',
    inYourApp:
        'How a bar takes the system edge on its edge (here, the home indicator). live: as it is now, so it goes to zero '
        'while the keyboard is up (bars that ride). steady: as it is with the keyboard down, so the bar holds its '
        'height (bars that stay). none: not at all, for a child that runs to the screen\'s edge itself (bars that '
        'reserve). The hatched band is the system edge the bar took.',
    art: const SeawallArt(),
    controls: <Widget>[
      ChoiceControl<HarborSystemEdgeStance>(
        label: 'systemEdges',
        values: HarborSystemEdgeStance.values,
        value: _systemEdges,
        labelOf: (final HarborSystemEdgeStance s) => s.name,
        onChanged: (final HarborSystemEdgeStance s) => setState(() => _systemEdges = s),
      ),
    ],
    code:
        'HarborBar.solid(\n'
        '  keyboard: HarborKeyboardStance.rides,\n'
        '  systemEdges: HarborSystemEdgeStance.${_systemEdges.name},\n'
        '  child: Composer(),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_header('HarborSystemEdgeStance')],
      bottom: <HarborBar>[
        HarborBar.solid(
          keyboard: HarborKeyboardStance.rides,
          systemEdges: _systemEdges,
          backdrop: const _SystemEdgeGround(barHeight: 56),
          debugLabel: 'composer',
          child: StageBar(
            key: const ValueKey<String>('composer'),
            label: 'systemEdges: ${_systemEdges.name}',
            icon: Icons.edit_rounded,
          ),
        ),
      ],
      body: const _Body(),
    ),
  );
}

/// A bar's ground: the bar's own part, and the system edge it took, hatched,
/// with the bar's measured height.
class _SystemEdgeGround extends StatelessWidget {
  const _SystemEdgeGround({required this.barHeight});

  final double barHeight;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    key: const ValueKey<String>('system edge bar ground'),
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final double height = constraints.maxHeight;
      final double systemEdge = (height - barHeight).clamp(0.0, double.infinity);
      return Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: _composerColor)),
          if (systemEdge > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: systemEdge,
              child: CustomPaint(
                painter: const _HatchPainter(),
                child: Center(
                  child: Text(
                    'system edge ${_f(systemEdge)}',
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
              'bar ${_f(height)}',
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

// 7. HarborBar.withdrawsAtHighTide --------------------------------------------

/// `HarborBar.withdrawsAtHighTide`: a tool strip that leaves while the keyboard is up.
class WithdrawsAtHighTideEntry extends StatefulWidget {
  const WithdrawsAtHighTideEntry({super.key});

  @override
  State<WithdrawsAtHighTideEntry> createState() => _WithdrawsAtHighTideEntryState();
}

class _WithdrawsAtHighTideEntryState extends State<WithdrawsAtHighTideEntry> {
  bool _withdraws = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBar.withdrawsAtHighTide',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The tool strip slides away and the composer rides the keyboard alone; the list grows into the strip\'s ground.',
      ),
      TryStep(
        'Tap the keyboard button again',
        'The strip slides back on top of the composer once the keyboard is down.',
      ),
      TryStep(
        'Drag the gauge beside the stage up to about 3',
        'The strip is already gone: it withdraws as soon as any keyboard is up, not only at full height.',
      ),
      TryStep(
        'Switch withdrawsAtHighTide off, keyboard still up',
        'The strip comes back and rides the keyboard on top of the composer, taking its room from the list.',
      ),
    ],
    focus: const StageFocus.bottom(480),
    realWorld:
        'Like a boat on a slipway, hauled out before the tide comes up the ramp and launched again when it suits: the '
        'bar leaves while the keyboard is up, and comes back after.',
    inYourApp:
        'A bar that withdraws while the keyboard is up and comes back when it goes down: a tool strip that would '
        'otherwise park mid-screen on top of a composer that rides the keyboard. It gives its ground back, so the body grows into it.',
    art: const SlipwayArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'withdrawsAtHighTide',
        value: _withdraws,
        onChanged: (final bool v) => setState(() => _withdraws = v),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  bottom: [\n'
        '    HarborBar.solid(\n'
        '      keyboard: HarborKeyboardStance.rides,\n'
        '      withdrawsAtHighTide: $_withdraws,\n'
        '      child: ToolStrip(),\n'
        '    ),\n'
        '    HarborBar.solid(keyboard: HarborKeyboardStance.rides, child: Composer()),\n'
        '  ],\n'
        '  body: notes,\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_header('withdrawsAtHighTide')],
      bottom: <HarborBar>[
        HarborBar.solid(
          keyboard: HarborKeyboardStance.rides,
          withdrawsAtHighTide: _withdraws,
          backdrop: ColoredBox(color: _tabBarColor),
          debugLabel: 'tool strip',
          child: _ToolStrip(withdraws: _withdraws),
        ),
        _composerBar(),
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
    child: HarborClear.rowInsets(
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

// 8. HarborFrame.bodyClearsKeyboard -------------------------------------------

/// `HarborFrame.bodyClearsKeyboard`: whether the body ends at the keyboard's top.
class BodyClearsTideEntry extends StatefulWidget {
  const BodyClearsTideEntry({super.key});

  @override
  State<BodyClearsTideEntry> createState() => _BodyClearsTideEntryState();
}

class _BodyClearsTideEntryState extends State<BodyClearsTideEntry> {
  bool _clears = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFrame.bodyClearsKeyboard',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The body ends here line rises to the keyboard\'s top and the red HarborClear marker rides above it.',
      ),
      TryStep(
        'Look at HarborFrame body under Readings',
        'keyboard reads 0: with bodyClearsKeyboard on, the body never hears of the keyboard, as under a resizing Scaffold.',
      ),
      TryStep(
        'Switch bodyClearsKeyboard off',
        'The line drops to the screen\'s bottom, under the keyboard, but the marker stays above it: HarborClear keeps clear.',
      ),
      TryStep(
        'Look at HarborFrame body under Readings again',
        'keyboard now reads 336: the body runs under the keyboard and is told how far in MediaQuery.viewInsets.',
      ),
      TryStep(
        'Tap the keyboard button, then flip the switch',
        'Nothing moves with the keyboard down: the setting only matters while the keyboard is up.',
      ),
    ],
    focus: const StageFocus.bottom(480),
    realWorld:
        'Like a lock gate, which holds the water back or lets it through: the body ends at the keyboard, or runs on '
        'under it.',
    inYourApp:
        'On (the default), the body ends at the keyboard\'s top, like a resizing Scaffold: the probe reads padding 0 '
        'and keyboard 0. Off, the body runs on under the keyboard and is told how far it reaches in '
        'MediaQuery.viewInsets. Either way, the HarborClear box keeps clear of it.',
    art: const LockGateArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'bodyClearsKeyboard',
        value: _clears,
        onChanged: (final bool v) => setState(() => _clears = v),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  bodyClearsKeyboard: $_clears,\n'
        '  top: [HarborBar.overlay(child: Header())],\n'
        '  body: Stack(children: [\n'
        '    HarborScrollView(slivers: [boats]),\n'
        '    Align(\n'
        '      alignment: Alignment.bottomCenter,\n'
        '      child: HarborClear(edges: {HarborEdge.bottom}, child: SaveButton()),\n'
        '    ),\n'
        '  ]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      bodyClearsKeyboard: _clears,
      top: <HarborBar>[_header('HarborFrame.bodyClearsKeyboard')],
      body: _Body(
        label: 'HarborFrame body (bodyClearsKeyboard: $_clears)',
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: HarborScrollView(
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
              child: HarborClear(
                edges: <HarborEdge>{HarborEdge.bottom},
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: StageMarker(
                    key: ValueKey<String>('clear marker'),
                    label: 'HarborClear',
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
