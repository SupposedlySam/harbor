import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import 'art/docks_art.dart';
import 'art/folds_art.dart';
import 'art/pier_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Bars: what claims an edge, and how.
final List<GuideEntry> dockEntries = <GuideEntry>[
  GuideEntry(
    id: 'dock-pier',
    className: 'HarborBar.overlay',
    group: GuideGroup.docks,
    realWorld: 'Like a pier on piles: the body runs under it',
    art: (final BuildContext context) => const PierArt(),
    page: (final BuildContext context) => const OverlayBarEntry(),
  ),
  GuideEntry(
    id: 'dock-quay',
    className: 'HarborBar.solid',
    group: GuideGroup.docks,
    realWorld: 'Like a quay: the body stops at it',
    art: (final BuildContext context) => const QuayArt(),
    page: (final BuildContext context) => const SolidBarEntry(),
  ),
  GuideEntry(
    id: 'dock-stacking',
    className: 'bottom: [composer, tabBar]',
    group: GuideGroup.docks,
    realWorld: 'Like two boats rafted up: bars stack from the edge in',
    art: (final BuildContext context) => const RaftedArt(),
    page: (final BuildContext context) => const StackingEntry(),
  ),
  GuideEntry(
    id: 'dock-state',
    className: 'HarborBarState',
    group: GuideGroup.docks,
    realWorld: 'Like harbor lights: lit, out, or a drawbridge raised',
    art: (final BuildContext context) => const HarborLightsArt(),
    page: (final BuildContext context) => const BarStateEntry(),
  ),
  GuideEntry(
    id: 'dock-resting-extent',
    className: 'HarborBar.restingExtent + HarborFollow',
    group: GuideGroup.docks,
    realWorld: 'Like a drawbridge: its footing stays as the leaf rises',
    art: (final BuildContext context) => const BasculeArt(),
    page: (final BuildContext context) => const RestingExtentEntry(),
  ),
  GuideEntry(
    id: 'dock-hit-test',
    className: 'HarborBar.hitTestBehavior',
    group: GuideGroup.docks,
    realWorld: 'Like a gangway gate: shut, or open to walk through',
    art: (final BuildContext context) => const GangwayGateArt(),
    page: (final BuildContext context) => const HitTestEntry(),
  ),
  GuideEntry(
    id: 'dock-reserve',
    className: 'HarborBar.reserve',
    group: GuideGroup.docks,
    realWorld: 'Like a berth marked RESERVED: held before anything arrives',
    art: (final BuildContext context) => const ReservedBerthArt(),
    page: (final BuildContext context) => const ReserveEntry(),
  ),
];

/// `HarborBar.overlay`: a bar the body runs under.
class OverlayBarEntry extends StatefulWidget {
  const OverlayBarEntry({super.key});

  @override
  State<OverlayBarEntry> createState() => _OverlayBarEntryState();
}

class _OverlayBarEntryState extends State<OverlayBarEntry> {
  HarborEdgeEffectKind _effect = HarborEdgeEffectKind.fade;
  double _length = 16;
  double _blur = 0;
  HarborRest _rest = HarborRest.fadeEnd;
  bool _backdrop = true;

  HarborEdgeEffect get _edgeEffect => switch (_effect) {
    HarborEdgeEffectKind.none => HarborEdgeEffect.none,
    HarborEdgeEffectKind.fade => HarborEdgeEffect.fade(length: _length, blurSigma: _blur, restsAt: _rest),
    HarborEdgeEffectKind.hairline => const HarborEdgeEffect.hairline(color: Palette.brass),
  };

  String get _edgeEffectCode => switch (_effect) {
    HarborEdgeEffectKind.none => 'HarborEdgeEffect.none',
    HarborEdgeEffectKind.fade =>
      'HarborEdgeEffect.fade(length: ${_length.toStringAsFixed(0)}, blurSigma: ${_blur.toStringAsFixed(0)}, restsAt: HarborRest.${_rest.name})',
    HarborEdgeEffectKind.hairline => 'HarborEdgeEffect.hairline()',
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBar.overlay',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the rows up under the bar',
        'They slide under the planks and fade out at the bar\'s face: content runs under an overlay bar, and its edge effect fades it.',
      ),
      TryStep(
        'Slide length to 40',
        'The fade runs further and the first row rests lower: the fade and the resting line move together.',
      ),
      TryStep(
        'Pick restsAt: barFace',
        'The first row moves up to the bar\'s face and starts inside the fade: rows can rest under the fade, not past it.',
      ),
      TryStep(
        'Switch off backdrop, then slide blurSigma to 15',
        'With the planks gone you see the rows under the bar frosted: the edge effect can blur the content as well as fade it.',
      ),
      TryStep(
        'Pick edgeEffect: hairline',
        'The fade goes and a brass line marks the bar\'s face, with the first row resting right at it.',
      ),
      TryStep(
        'Open The stage, switch off Status bar, then pick Device: iPhone SE',
        'On the iPhone 17 the bar still pads its title clear of the island; on the SE its planks start at the very top: a bar absorbs whatever system edge the hardware leaves.',
      ),
    ],
    focus: const StageFocus.top(440),
    realWorld:
        'A pier is built out over the water on piles. Boats sail underneath it and tie up beside it; the water runs right '
        'up to the shore beneath the deck.',
    inYourApp:
        'A header (or any bar) the content scrolls under. The body runs the full height, the bar pads itself below the '
        'status bar, and its measured height reaches the body as MediaQuery.padding, so the first row rests clear of it. '
        'Its edge effect fades the rows as they pass under.',
    art: const PierArt(),
    controls: <Widget>[
      ChoiceControl<HarborEdgeEffectKind>(
        label: 'edgeEffect',
        values: HarborEdgeEffectKind.values,
        value: _effect,
        labelOf: (final HarborEdgeEffectKind k) => k.name,
        onChanged: (final HarborEdgeEffectKind k) => setState(() => _effect = k),
      ),
      if (_effect == HarborEdgeEffectKind.fade) ...<Widget>[
        SliderControl(
          label: 'length',
          value: _length,
          min: 0,
          max: 48,
          onChanged: (final double v) => setState(() => _length = v),
        ),
        SliderControl(
          label: 'blurSigma',
          value: _blur,
          min: 0,
          max: 30,
          onChanged: (final double v) => setState(() => _blur = v),
        ),
        ChoiceControl<HarborRest>(
          label: 'restsAt',
          values: HarborRest.values,
          value: _rest,
          labelOf: (final HarborRest r) => r.name,
          onChanged: (final HarborRest r) => setState(() => _rest = r),
        ),
      ],
      ToggleControl(label: 'backdrop', value: _backdrop, onChanged: (final bool v) => setState(() => _backdrop = v)),
    ],
    code:
        'HarborFrame(\n'
        '  top: [\n'
        '    HarborBar.overlay(\n'
        '      edgeEffect: $_edgeEffectCode,\n'
        '${_backdrop ? '      backdrop: PierPlanks(),\n' : ''}'
        '      child: Header(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborScrollView(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        HarborBar.overlay(
          edgeEffect: _edgeEffect,
          backdrop: _backdrop ? ColoredBox(color: Palette.plank.withValues(alpha: 0.82)) : null,
          debugLabel: 'overlay bar',
          child: const StageHeader(title: 'HarborBar.overlay'),
        ),
      ],
      body: StageProbe(
        label: 'frame body (under the bar)',
        child: HarborScrollView(
          slivers: <Widget>[
            SliverList.builder(
              itemCount: 30,
              itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A bar of either kind, for the entries that switch between them.
HarborBar _barOf(
  final HarborBarKind kind, {
  required final Widget child,
  final Widget? backdrop,
  final String? debugLabel,
}) => kind == HarborBarKind.solid
    ? HarborBar.solid(backdrop: backdrop, debugLabel: debugLabel, child: child)
    : HarborBar.overlay(
        edgeEffect: const HarborEdgeEffect.fade(length: 12),
        backdrop: backdrop,
        debugLabel: debugLabel,
        child: child,
      );

/// A body that marks its own box, so you can see where it starts and ends.
class _MarkedBody extends StatelessWidget {
  const _MarkedBody({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('harbor body'),
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(border: Border.all(color: Palette.brass, width: 2)),
    child: SizedBox.expand(child: child),
  );
}

Widget _rows({final int count = 30}) => HarborScrollView(
  slivers: <Widget>[
    SliverList.builder(
      itemCount: count,
      itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
    ),
  ],
);

/// `HarborBar.solid`: a bar the body starts below.
class SolidBarEntry extends StatefulWidget {
  const SolidBarEntry({super.key});

  @override
  State<SolidBarEntry> createState() => _SolidBarEntryState();
}

class _SolidBarEntryState extends State<SolidBarEntry> {
  bool _top = true;
  bool _bottom = true;
  double _minimum = 16;

  @override
  Widget build(final BuildContext context) => GuidePage(
    // No focus, the whole phone: its switches take away the top bar as well as the bottom one.
    className: 'HarborBar.solid',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the rows',
        'They stop at the bars\' edges and never pass under: a solid bar takes its ground, and Readings show padding T 0 · B 0.',
      ),
      TryStep(
        'Switch off top bar',
        'The body\'s outline jumps to the top of the screen and Readings show padding T 62: the body now meets the status bar.',
      ),
      TryStep(
        'Open The stage and pick Device: iPhone SE',
        'No home indicator here, yet the bar stays 16 off the bottom edge: that is the bar\'s minimum.',
      ),
      TryStep(
        'Slide minimum to 0',
        'The bar drops onto the bottom edge: with no home indicator and no minimum, nothing holds it off the glass.',
      ),
    ],
    realWorld:
        'A quay is a stone wall built on the shore, with bollards along its edge. Boats lie alongside it; the water '
        'starts where the stone ends, and nothing sails underneath.',
    inYourApp:
        'A bar that takes its ground, like a child of a Column: the body starts where it ends, so content never runs under '
        'it, and a probe in the body reads padding 0 on that edge. A bottom solid bar is a tab bar; minimum keeps it 16 off the '
        'edge of a phone with no home indicator (try the iPhone SE).',
    art: const QuayArt(),
    controls: <Widget>[
      ToggleControl(label: 'top bar', value: _top, onChanged: (final bool v) => setState(() => _top = v)),
      ToggleControl(label: 'bottom bar', value: _bottom, onChanged: (final bool v) => setState(() => _bottom = v)),
      if (_bottom)
        SliderControl(
          label: 'minimum',
          value: _minimum,
          min: 0,
          max: 40,
          onChanged: (final double v) => setState(() => _minimum = v),
        ),
    ],
    code:
        'HarborFrame(\n'
        '${_top ? '  top: [HarborBar.solid(backdrop: QuayStones(), child: Header())],\n' : ''}'
        '${_bottom ? '  bottom: [HarborBar.solid(minimum: ${_minimum.toStringAsFixed(0)}, child: TabBar())],\n' : ''}'
        '  body: HarborScrollView(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        if (_top)
          const HarborBar.solid(
            backdrop: QuayStones(),
            debugLabel: 'top bar',
            child: StageHeader(key: ValueKey<String>('top bar'), title: 'HarborBar.solid'),
          ),
      ],
      bottom: <HarborBar>[
        if (_bottom)
          HarborBar.solid(
            minimum: _minimum,
            backdrop: const QuayStones(),
            debugLabel: 'bottom bar',
            child: StageBar(
              key: const ValueKey<String>('bottom bar'),
              label: 'HarborBar.solid(minimum: ${_minimum.toStringAsFixed(0)})',
            ),
          ),
      ],
      body: StageProbe(
        label: 'frame body (below the bar)',
        child: _MarkedBody(child: _rows()),
      ),
    ),
  );
}

/// Bars stacking on one edge.
class StackingEntry extends StatefulWidget {
  const StackingEntry({super.key});

  @override
  State<StackingEntry> createState() => _StackingEntryState();
}

class _StackingEntryState extends State<StackingEntry> {
  bool _second = true;
  HarborBarKind _composer = HarborBarKind.solid;
  HarborBarKind _tabBar = HarborBarKind.solid;

  /// A solid bar listed inside an overlay bar: the frame asserts on it.
  bool get _solidInsideOverlay => _second && _composer == HarborBarKind.solid && _tabBar == HarborBarKind.overlay;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'bottom: [composer, tabBar]',
    tryThis: const <TryStep>[
      TryStep(
        'Pick composer: overlay',
        'The body\'s outline drops past the composer to the tab bar: rows run under an overlay bar but stop at a solid one.',
      ),
      TryStep(
        'Pick tabBar: overlay',
        'The body runs to the bottom of the screen under both bars, which still stack in the order they are listed.',
      ),
      TryStep(
        'Pick composer: solid, with tabBar still overlay',
        'The stage shows the assert: a solid bar must be listed nearer the edge than any overlay bar.',
      ),
      TryStep(
        'Switch off second bar (tabBar)',
        'The solid composer alone takes the edge, above the home indicator: bars stack from the edge in, like a Column.',
      ),
    ],
    focus: const StageFocus.bottom(480),
    realWorld:
        'When the quay is full, boats raft up: the second boat ties alongside the first instead of the wall, and anyone '
        'going ashore climbs across. The raft is as wide as both boats together.',
    inYourApp:
        'Bars on one edge are listed in reading order (bottom: top to bottom) and stack from the edge in, like a Column. '
        'Two solid bars add up and the body ends above both; an overlay bar over a solid one reaches past it, so rows run '
        'under the composer but stop at the tab bar. Solid bars are always nearer the edge than overlay bars.',
    art: const RaftedArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'second bar (tabBar)',
        value: _second,
        onChanged: (final bool v) => setState(() => _second = v),
      ),
      ChoiceControl<HarborBarKind>(
        label: 'composer',
        values: HarborBarKind.values,
        value: _composer,
        labelOf: (final HarborBarKind k) => k.name,
        onChanged: (final HarborBarKind k) => setState(() => _composer = k),
      ),
      if (_second)
        ChoiceControl<HarborBarKind>(
          label: 'tabBar',
          values: HarborBarKind.values,
          value: _tabBar,
          labelOf: (final HarborBarKind k) => k.name,
          onChanged: (final HarborBarKind k) => setState(() => _tabBar = k),
        ),
    ],
    code:
        'HarborFrame(\n'
        '  bottom: [\n'
        '    HarborBar.${_composer.name}(child: Composer()),\n'
        '${_second ? '    HarborBar.${_tabBar.name}(child: TabBar()),\n' : ''}'
        '  ],\n'
        '  body: HarborScrollView(slivers: [messages]),\n'
        ')${_solidInsideOverlay ? '\n// Asserts: a solid bar listed inside an overlay bar.' : ''}',
    stage: (final BuildContext context) => _solidInsideOverlay
        ? const _AssertCard(
            message:
                'A solid bar on the bottom edge is listed inside an overlay bar, and the frame asserts.\n\n'
                'List solid bars nearer the edge than overlay bars (on the bottom edge, after them).',
          )
        : HarborFrame(
            top: <HarborBar>[
              HarborBar.overlay(
                backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.75)),
                child: const StageHeader(title: 'Stacking'),
              ),
            ],
            bottom: <HarborBar>[
              _barOf(
                _composer,
                backdrop: _composer == HarborBarKind.solid
                    ? const QuayStones()
                    : ColoredBox(color: Palette.plank.withValues(alpha: 0.82)),
                debugLabel: 'composer',
                child: StageBar(
                  key: const ValueKey<String>('composer'),
                  label: 'composer: HarborBar.${_composer.name}',
                  icon: Icons.edit_rounded,
                ),
              ),
              if (_second)
                _barOf(
                  _tabBar,
                  backdrop: _tabBar == HarborBarKind.solid
                      ? const QuayStones()
                      : ColoredBox(color: Palette.plank.withValues(alpha: 0.82)),
                  debugLabel: 'tabBar',
                  child: StageBar(
                    key: const ValueKey<String>('tabBar'),
                    label: 'tabBar: HarborBar.${_tabBar.name}',
                    icon: Icons.space_dashboard_rounded,
                  ),
                ),
            ],
            body: StageProbe(
              label: 'frame body',
              child: _MarkedBody(child: _rows()),
            ),
          ),
  );
}

class _AssertCard extends StatelessWidget {
  const _AssertCard({required this.message});

  final String message;

  @override
  Widget build(final BuildContext context) => HarborClear(
    rowInsets: true,
    // On the bottom edge, where the bars it refuses would be, so the page's bottom view shows it.
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        key: const ValueKey<String>('assert card'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.night,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.buoyRed, width: 2),
        ),
        child: Text(message, style: const TextStyle(color: Palette.foam, height: 1.4)),
      ),
    ),
  );
}

/// `HarborBarState`: open, dark or withdrawn.
class BarStateEntry extends StatefulWidget {
  const BarStateEntry({super.key});

  @override
  State<BarStateEntry> createState() => _BarStateEntryState();
}

class _BarStateEntryState extends State<BarStateEntry> {
  HarborBarState _state = HarborBarState.open;
  HarborExtentPolicy _policy = HarborExtentPolicy.hold;
  double _duration = 1200;
  int _taps = 0;
  bool _playing = false;

  /// Withdraws the header, waits for it to go, and brings it back, so the
  /// extent policy can be watched both ways.
  Future<void> _play() async {
    setState(() {
      _playing = true;
      _state = HarborBarState.withdrawn;
    });
    await Future<void>.delayed(Duration(milliseconds: _duration.round() + 700));
    if (!mounted) {
      return;
    }
    setState(() => _state = HarborBarState.open);
    await Future<void>.delayed(Duration(milliseconds: _duration.round()));
    if (mounted) {
      setState(() => _playing = false);
    }
  }

  String get _hint => switch (_state) {
    HarborBarState.open =>
      'open: the lamp is lit, the header is drawn and its button counts taps. The gold outline (the body) starts below it.',
    HarborBarState.dark =>
      'dark: the header is gone, but the rows have not moved: the dashed box is the ground it still holds. Its button '
          'is gone too, so taps there do nothing.',
    HarborBarState.withdrawn => switch (_policy) {
      HarborExtentPolicy.hold =>
        'withdrawn + hold: the header slides up and away; the body waits until it has gone, then takes the ground.',
      HarborExtentPolicy.follow =>
        'withdrawn + follow: the body rises with the header as it slides, a drawn frame at a time.',
      HarborExtentPolicy.release =>
        'withdrawn + release: the body takes the ground at once; the header slides away over the rows.',
    },
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBarState',
    tryThis: const <TryStep>[
      TryStep(
        'Tap taps: 0 in the header',
        'The count goes up: an open bar is drawn, takes taps, and the body starts below it.',
      ),
      TryStep(
        'Pick state: dark',
        'The header vanishes but the rows stay put under a dashed box: a dark bar keeps its ground, and its button takes no taps.',
      ),
      TryStep(
        'Pick state: open, tap Withdraw and return (hold)',
        'The header slides away and only then does the body rise to the top: hold gives the ground back once the bar has gone.',
      ),
      TryStep(
        'Pick extentPolicy: follow, tap Withdraw and return',
        'The body rises right behind the header as it slides, a drawn frame at a time, and drops back with it on the way in.',
      ),
      TryStep(
        'Pick extentPolicy: release, tap Withdraw and return',
        'The body takes the top at once and the header slides out over the rows: release hands the ground over immediately.',
      ),
    ],
    focus: const StageFocus.top(440),
    realWorld:
        'A harbor\'s lights tell you what is in service. A lit lamp is a working berth; a lamp that is out still stands '
        'where it stands; a drawbridge raised is out of the way altogether.',
    inYourApp:
        'open: drawn, tappable, its ground taken. dark: not drawn or tappable, but it keeps its ground, so nothing moves. '
        'withdrawn: it slides out toward its edge and gives its ground back. HarborExtentPolicy says when the body gets '
        'that ground: hold (once the bar has gone), follow (as it slides) or release (at once).',
    art: const HarborLightsArt(),
    controls: <Widget>[
      GuideHint(text: _hint),
      ChoiceControl<HarborBarState>(
        label: 'state',
        values: HarborBarState.values,
        value: _state,
        labelOf: (final HarborBarState s) => s.name,
        onChanged: (final HarborBarState s) => setState(() => _state = s),
      ),
      ChoiceControl<HarborExtentPolicy>(
        label: 'extentPolicy',
        values: HarborExtentPolicy.values,
        value: _policy,
        labelOf: (final HarborExtentPolicy p) => p.name,
        onChanged: (final HarborExtentPolicy p) => setState(() => _policy = p),
      ),
      SliderControl(
        label: 'duration',
        value: _duration,
        min: 100,
        max: 2000,
        onChanged: (final double v) => setState(() => _duration = v),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          key: const ValueKey<String>('play withdraw'),
          onPressed: _playing ? null : _play,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Withdraw and return (${_policy.name})'),
        ),
      ),
    ],
    code:
        'HarborBar.solid(\n'
        '  state: HarborBarState.${_state.name},\n'
        '  extentPolicy: HarborExtentPolicy.${_policy.name},\n'
        '  animationStyle: AnimationStyle(duration: Duration(milliseconds: ${_duration.toStringAsFixed(0)})),\n'
        '  child: Header(),\n'
        ')',
    stage: (final BuildContext context) => Stack(
      children: <Widget>[
        Positioned.fill(
          child: HarborFrame(
            top: <HarborBar>[
              HarborBar.solid(
                state: _state,
                animationStyle: AnimationStyle(duration: Duration(milliseconds: _duration.round())),
                extentPolicy: _policy,
                backdrop: const QuayStones(),
                debugLabel: 'header',
                child: _LampHeader(
                  key: const ValueKey<String>('state header'),
                  state: _state,
                  taps: _taps,
                  onTap: () => setState(() => _taps++),
                ),
              ),
            ],
            bottom: const <HarborBar>[
              HarborBar.solid(
                backdrop: QuayStones(),
                child: StageBar(label: 'tab bar (stays open)'),
              ),
            ],
            body: StageProbe(
              label: 'frame body',
              child: _MarkedBody(child: _rows()),
            ),
          ),
        ),
        // Where a dark bar still stands: its ground, held.
        if (_state == HarborBarState.dark)
          Positioned(
            top: MediaQuery.paddingOf(context).top,
            left: 0,
            right: 0,
            height: _LampHeader.height,
            child: const IgnorePointer(child: _HeldGround()),
          ),
      ],
    ),
  );
}

/// The header on the bar-state stage: a harbor lamp that's lit while the
/// bar is open, its state, and a button that counts taps.
class _LampHeader extends StatelessWidget {
  const _LampHeader({super.key, required this.state, required this.taps, required this.onTap});

  static const double height = 52;

  final HarborBarState state;
  final int taps;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: height,
    child: HarborClear.rowInsets(
      child: Row(
        children: <Widget>[
          Icon(
            state == HarborBarState.open ? Icons.light_rounded : Icons.light_outlined,
            color: state == HarborBarState.open ? Palette.brass : Palette.foam.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'state: ${state.name}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Palette.foam,
              ),
            ),
          ),
          FilledButton.tonal(
            key: const ValueKey<String>('header button'),
            onPressed: onTap,
            child: Text('taps: $taps'),
          ),
        ],
      ),
    ),
  );
}

/// A dashed outline where a dark bar stands, unseen.
class _HeldGround extends StatelessWidget {
  const _HeldGround();

  @override
  Widget build(final BuildContext context) => CustomPaint(
    key: const ValueKey<String>('held ground'),
    painter: const _DashedBoxPainter(),
    child: Center(
      child: Text(
        'dark: ground held, nothing drawn',
        style: TextStyle(fontFamily: 'Menlo', fontSize: 12, color: Palette.foam.withValues(alpha: 0.75)),
      ),
    ),
  );
}

class _DashedBoxPainter extends CustomPainter {
  const _DashedBoxPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint paint = Paint()
      ..color = Palette.brass
      ..strokeWidth = 2;
    final Rect box = (Offset.zero & size).deflate(3);
    void dashes(final Offset from, final Offset to) {
      final double length = (to - from).distance;
      final Offset step = (to - from) / length;
      for (double d = 0; d < length; d += 12) {
        canvas.drawLine(from + step * d, from + step * (d + 6).clamp(0, length), paint);
      }
    }

    dashes(box.topLeft, box.topRight);
    dashes(box.topRight, box.bottomRight);
    dashes(box.bottomRight, box.bottomLeft);
    dashes(box.bottomLeft, box.topLeft);
  }

  @override
  bool shouldRepaint(final _DashedBoxPainter oldDelegate) => false;
}

/// A rail on the start edge that opens when tapped.
class _Rail extends StatelessWidget {
  const _Rail({required this.width, required this.expanded, required this.onTap});

  final double width;
  final bool expanded;
  final VoidCallback onTap;

  static const List<(IconData, String)> _items = <(IconData, String)>[
    (Icons.anchor_rounded, 'Moorings'),
    (Icons.sailing_rounded, 'Fleet'),
    (Icons.map_rounded, 'Charts'),
    (Icons.settings_rounded, 'Office'),
  ];

  @override
  Widget build(final BuildContext context) => GestureDetector(
    key: const ValueKey<String>('rail'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: width,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12),
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) {
            final bool labels = constraints.maxWidth >= 140;
            return ClipRect(
              child: Column(
                children: <Widget>[
                  for (final (IconData icon, String label) in _items)
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: <Widget>[
                          SizedBox(width: 56, child: Icon(icon, color: Palette.brass)),
                          if (labels)
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Icon(expanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Palette.foam),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// `HarborBar.restingExtent` and `HarborFollow`: a rail that opens over content, or pushes it.
class RestingExtentEntry extends StatefulWidget {
  const RestingExtentEntry({super.key});

  @override
  State<RestingExtentEntry> createState() => _RestingExtentEntryState();
}

class _RestingExtentEntryState extends State<RestingExtentEntry> {
  bool _expanded = false;
  double _resting = 72;
  HarborFollow _follow = HarborFollow.resting;

  Widget _panel(final String key, final HarborFollow follow, final Color color) => HarborClear(
    edges: const <HarborEdge>{HarborEdge.start},
    follow: follow,
    child: Container(
      key: ValueKey<String>(key),
      height: 170,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadiusDirectional.horizontal(end: Radius.circular(12)),
      ),
      child: Text(
        'HarborClear(\n  follow: HarborFollow.${follow.name},\n)',
        style: const TextStyle(fontFamily: 'Menlo', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBar.restingExtent + HarborFollow',
    tryThis: const <TryStep>[
      TryStep(
        'Slide restingExtent to 100',
        'The closed rail and both panels move to 100: restingExtent is the ground the rail holds at rest.',
      ),
      TryStep(
        'Tap the rail',
        'It opens to 210 and the HarborFollow.live panel moves with it; the resting panel holds still and the rail opens over it.',
      ),
      TryStep(
        'Pick follow: live',
        'The second panel jumps out to the open rail too: live content follows the rail as it grows.',
      ),
      TryStep('Switch off rail open', 'The rail closes and both panels come back to its resting width.'),
    ],
    realWorld:
        'A bascule bridge rests down across the channel and swings its leaf up to let a tall boat through. Its footing on '
        'the bank never changes, however high the leaf goes.',
    inYourApp:
        'A rail on the start edge that grows when it takes focus. restingExtent is the width it holds at rest; content '
        'with HarborFollow.live moves with the rail as it opens, and content with HarborFollow.resting holds still and '
        'lets the rail open over it. Tap the rail to open it.',
    art: const BasculeArt(),
    controls: <Widget>[
      ToggleControl(label: 'rail open', value: _expanded, onChanged: (final bool v) => setState(() => _expanded = v)),
      SliderControl(
        label: 'restingExtent',
        value: _resting,
        min: 56,
        max: 110,
        onChanged: (final double v) => setState(() => _resting = v),
      ),
      ChoiceControl<HarborFollow>(
        label: 'follow',
        values: HarborFollow.values,
        value: _follow,
        labelOf: (final HarborFollow f) => f.name,
        onChanged: (final HarborFollow f) => setState(() => _follow = f),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  start: [\n'
        '    HarborBar.overlay(\n'
        '      restingExtent: ${_resting.toStringAsFixed(0)},\n'
        '      child: Rail(open: $_expanded),\n'
        '    ),\n'
        '  ],\n'
        '  body: Column(children: [\n'
        '    HarborClear(follow: HarborFollow.live, child: panel),\n'
        '    HarborClear(follow: HarborFollow.${_follow.name}, child: page),\n'
        '  ]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      start: <HarborBar>[
        HarborBar.overlay(
          restingExtent: _resting,
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.92)),
          debugLabel: 'rail',
          child: _Rail(
            width: _expanded ? 210 : _resting,
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ),
      ],
      body: StageProbe(
        label: 'frame body (under the rail)',
        child: HarborClear(
          edges: HarborEdge.vertical,
          padding: const EdgeInsetsDirectional.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _panel('panel live', HarborFollow.live, Palette.sea),
              _panel('panel second', _follow, Palette.plank),
            ],
          ),
        ),
      ),
    ),
  );
}

/// `HarborBar.hitTestBehavior`: whether taps on a bar reach what's under it.
class HitTestEntry extends StatefulWidget {
  const HitTestEntry({super.key});

  @override
  State<HitTestEntry> createState() => _HitTestEntryState();
}

class _HitTestEntryState extends State<HitTestEntry> {
  HitTestBehavior _behavior = HitTestBehavior.opaque;
  final Map<int, int> _taps = <int, int>{};
  int _total = 0;
  int? _last;
  final ScrollController _scroll = ScrollController(initialScrollOffset: 150);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _tap(final int i) => setState(() {
    _taps[i] = (_taps[i] ?? 0) + 1;
    _total++;
    _last = i;
  });

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBar.hitTestBehavior',
    tryThis: const <TryStep>[
      TryStep(
        'Tap a row below the header',
        'The row taps counter in the bottom bar goes up: rows clear of the header take taps.',
      ),
      TryStep(
        'Tap the header beside its title',
        'Nothing counts: opaque, the default, stops taps on the bar\'s ground, even over a row scrolled under it.',
      ),
      TryStep(
        'Pick hitTestBehavior: translucent, tap beside the title',
        'The row under the header counts the tap: translucent lets taps on the bar\'s empty parts through.',
      ),
      TryStep(
        'Tap the title itself',
        'No count: the header\'s own text still takes its tap; only its empty parts pass taps on.',
      ),
    ],
    realWorld:
        'A gate at the head of the gangway down to the pontoon. Shut, nobody passes it; open, people walk straight '
        'through to the boats beyond.',
    inYourApp:
        'Whether a tap on a bar\'s ground stops there. Opaque (the default) means a tap on the header never reaches a '
        'row scrolled under it. Translucent lets taps on the header\'s empty parts through to the rows beneath; its own '
        'buttons and text still take theirs. Tap the header beside its title and watch the counter.',
    art: const GangwayGateArt(),
    controls: <Widget>[
      ChoiceControl<HitTestBehavior>(
        label: 'hitTestBehavior',
        values: HitTestBehavior.values,
        value: _behavior,
        labelOf: (final HitTestBehavior b) => b.name,
        onChanged: (final HitTestBehavior b) => setState(() => _behavior = b),
      ),
    ],
    code:
        'HarborBar.overlay(\n'
        '  hitTestBehavior: HitTestBehavior.${_behavior.name},\n'
        '  // A backdrop that takes no taps of its own.\n'
        '  backdrop: IgnorePointer(child: Frosting()),\n'
        '  child: Header(),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        HarborBar.overlay(
          hitTestBehavior: _behavior,
          edgeEffect: const HarborEdgeEffect.fade(length: 10),
          // A ColoredBox takes taps itself, so the backdrop ignores them.
          backdrop: IgnorePointer(child: ColoredBox(color: Palette.night.withValues(alpha: 0.6))),
          debugLabel: 'header',
          child: StageHeader(key: const ValueKey<String>('gate header'), title: 'hitTestBehavior: ${_behavior.name}'),
        ),
      ],
      bottom: <HarborBar>[
        HarborBar.solid(
          backdrop: const QuayStones(),
          child: StageBar(
            key: const ValueKey<String>('tap counter'),
            label: 'row taps: $_total${_last == null ? '' : ' (last: row ${_last! + 1})'}',
            icon: Icons.touch_app_rounded,
          ),
        ),
      ],
      body: StageProbe(
        label: 'frame body',
        child: HarborScrollView(
          controller: _scroll,
          slivers: <Widget>[
            SliverList.builder(
              itemCount: 30,
              itemBuilder: (final BuildContext context, final int i) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _tap(i),
                child: Stack(
                  children: <Widget>[
                    StageRow(index: i),
                    if (_taps[i] != null)
                      PositionedDirectional(
                        end: 24,
                        top: 16,
                        child: Text(
                          '${_taps[i]} tap${_taps[i] == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontFamily: 'Menlo',
                            color: Palette.brass,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `HarborBar.reserve`: an edge held for something drawn elsewhere.
class ReserveEntry extends StatefulWidget {
  const ReserveEntry({super.key});

  @override
  State<ReserveEntry> createState() => _ReserveEntryState();
}

class _ReserveEntryState extends State<ReserveEntry> {
  double _extent = 80;
  HarborBarKind _kind = HarborBarKind.overlay;
  bool _tabBar = false;

  /// The tab bar's own height, over the system edge it absorbs.
  static const double _tabBarHeight = 56;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBar.reserve',
    focus: const StageFocus.bottom(440),
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage, pick Device: iPhone 17 and scroll the rows to the end',
        'The last row comes to rest on the brass footer, 80 up: the reserve held its ground, though the footer is drawn '
            'over the frame, not in it.',
      ),
      TryStep(
        'On iPhone 17, slide extent to 20',
        'The footer stops at 34, not 20, and Readings show padding B 34: a reserve reaches the larger of the system edge and its '
            'extent, so nothing it stands in for sits on the home indicator.',
      ),
      TryStep(
        'Pick Device: iPhone SE',
        'With no home indicator the footer is exactly 20 high, and Readings show padding B 20.',
      ),
      TryStep(
        'Pick Device: iPhone 17 and kind: solid',
        'The brass outline of the body stops at the footer and the rows no longer pass under it: a solid reserve takes its ground.',
      ),
      TryStep(
        'On iPhone 17, switch on tab bar outside',
        'The footer moves up onto the tab bar and keeps its full extent: past the bars outside it, a reserve reaches its '
            'extent beyond theirs.',
      ),
    ],
    realWorld:
        'A harbor master paints out a berth and puts up a RESERVED sign before the boat arrives. Nothing is tied up there '
        'yet, but nobody else moors in it.',
    inYourApp:
        'HarborBar.reserve(extent: 80) holds an edge for something drawn elsewhere: a footer in an overlay, a bar a parent '
        'paints. It reaches 80 in from the edge, system edge included (the larger of the system edge and 80 when it is '
        'outermost), or 80 past the bars outside it. It paints nothing and takes no taps, so what it stands in for gets '
        'them. It is an overlay bar by default, so the body runs under it and rests clear of it; kind: solid makes the body '
        'stop at it.',
    art: const ReservedBerthArt(),
    controls: <Widget>[
      SliderControl(
        label: 'extent',
        value: _extent,
        min: 0,
        max: 140,
        divisions: 14,
        onChanged: (final double v) => setState(() => _extent = v),
      ),
      ChoiceControl<HarborBarKind>(
        label: 'kind',
        values: HarborBarKind.values,
        value: _kind,
        labelOf: (final HarborBarKind k) => k.name,
        onChanged: (final HarborBarKind k) => setState(() => _kind = k),
      ),
      ToggleControl(label: 'tab bar outside', value: _tabBar, onChanged: (final bool v) => setState(() => _tabBar = v)),
    ],
    code:
        'Stack(\n'
        '  children: [\n'
        '    HarborFrame(\n'
        '      bottom: [\n'
        '        HarborBar.reserve(extent: ${_extent.toStringAsFixed(0)}${_kind == HarborBarKind.solid ? ', kind: HarborBarKind.solid' : ''}),\n'
        '${_tabBar ? '        HarborBar.solid(child: TabBar()),\n' : ''}'
        '      ],\n'
        '      body: HarborScrollView(slivers: [boats]),\n'
        '    ),\n'
        '    // Drawn over the frame, in the ground the reserve holds.\n'
        '    Positioned(bottom: ${_tabBar ? 'tabBar' : '0'}, left: 0, right: 0, child: Footer()),\n'
        '  ],\n'
        ')',
    stage: (final BuildContext context) {
      // The footer is drawn by the stage, not the frame: it is told where the reserve is, as a
      // parent painting a bar would be.
      final double systemEdge = MediaQuery.viewPaddingOf(context).bottom;
      final double below = _tabBar ? _tabBarHeight + systemEdge : 0;
      final double reach = _tabBar ? _extent : (_extent > systemEdge ? _extent : systemEdge);
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          HarborFrame(
            debugLabel: 'reserve page',
            bottom: <HarborBar>[
              HarborBar.reserve(extent: _extent, kind: _kind, debugLabel: 'reserve'),
              if (_tabBar)
                const HarborBar.solid(
                  debugLabel: 'tab bar',
                  backdrop: QuayStones(),
                  child: StageBar(
                    key: ValueKey<String>('reserve tab bar'),
                    label: 'HarborBar.solid',
                    height: _tabBarHeight,
                  ),
                ),
            ],
            body: StageProbe(
              label: 'frame body',
              child: _MarkedBody(child: _rows()),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: below,
            height: reach,
            child: DecoratedBox(
              key: const ValueKey<String>('reserve footer'),
              decoration: BoxDecoration(
                color: Palette.brass.withValues(alpha: 0.82),
                border: const Border(top: BorderSide(color: Palette.plankDark, width: 2)),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    reach >= 20 ? 'Drawn elsewhere · ${reach.toStringAsFixed(0)}' : '',
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Palette.night,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
