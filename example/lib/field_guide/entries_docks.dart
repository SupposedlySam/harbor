import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import 'art/docks_art.dart';
import 'art/pier_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Docks: what claims an edge, and how.
final List<GuideEntry> dockEntries = <GuideEntry>[
  GuideEntry(
    id: 'dock-pier',
    className: 'HarborDock.pier',
    group: GuideGroup.docks,
    realWorld: 'A wooden pier on piles, built out over the water',
    art: (final BuildContext context) => const PierArt(),
    page: (final BuildContext context) => const PierEntry(),
  ),
  GuideEntry(
    id: 'dock-quay',
    className: 'HarborDock.quay',
    group: GuideGroup.docks,
    realWorld: 'A stone quay wall with bollards, a boat moored alongside',
    art: (final BuildContext context) => const QuayArt(),
    page: (final BuildContext context) => const QuayEntry(),
  ),
  GuideEntry(
    id: 'dock-stacking',
    className: 'bottom: [composer, tabBar]',
    group: GuideGroup.docks,
    realWorld: 'Two boats rafted up, one tied outside the other',
    art: (final BuildContext context) => const RaftedArt(),
    page: (final BuildContext context) => const StackingEntry(),
  ),
  GuideEntry(
    id: 'dock-state',
    className: 'HarborDockState',
    group: GuideGroup.docks,
    realWorld: 'Harbor lights: one lit, one out, a drawbridge raised',
    art: (final BuildContext context) => const HarborLightsArt(),
    page: (final BuildContext context) => const DockStateEntry(),
  ),
  GuideEntry(
    id: 'dock-resting-extent',
    className: 'HarborDock.restingExtent + HarborFollow',
    group: GuideGroup.docks,
    realWorld: 'A bascule drawbridge: one leaf resting down, one raised',
    art: (final BuildContext context) => const BasculeArt(),
    page: (final BuildContext context) => const RestingExtentEntry(),
  ),
  GuideEntry(
    id: 'dock-hit-test',
    className: 'HarborDock.hitTestBehavior',
    group: GuideGroup.docks,
    realWorld: 'A gangway gate, one leaf shut and one open',
    art: (final BuildContext context) => const GangwayGateArt(),
    page: (final BuildContext context) => const HitTestEntry(),
  ),
];

/// `HarborDock.pier`: a dock the body sails under.
class PierEntry extends StatefulWidget {
  const PierEntry({super.key});

  @override
  State<PierEntry> createState() => _PierEntryState();
}

class _PierEntryState extends State<PierEntry> {
  HarborWakeKind _wake = HarborWakeKind.fade;
  double _length = 16;
  double _blur = 0;
  HarborRest _rest = HarborRest.wakeEnd;
  bool _backdrop = true;

  HarborWake get _harborWake => switch (_wake) {
    HarborWakeKind.none => HarborWake.none,
    HarborWakeKind.fade => HarborWake.fade(length: _length, blurSigma: _blur, restsAt: _rest),
    HarborWakeKind.hairline => const HarborWake.hairline(color: Palette.brass),
  };

  String get _wakeCode => switch (_wake) {
    HarborWakeKind.none => 'HarborWake.none',
    HarborWakeKind.fade =>
      'HarborWake.fade(length: ${_length.toStringAsFixed(0)}, blurSigma: ${_blur.toStringAsFixed(0)}, restsAt: HarborRest.${_rest.name})',
    HarborWakeKind.hairline => 'HarborWake.hairline()',
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborDock.pier',
    tryThis: const <TryStep>[
      TryStep('Scroll the rows up under the pier', 'They slide under the planks and fade out at the pier\'s face: content sails under a pier, and its wake fades it.'),
      TryStep('Slide length to 40', 'The fade runs further and the first row rests lower: the wake and the resting line move together.'),
      TryStep('Pick restsAt: dockEdge', 'The first row moves up to the pier\'s face and starts inside the fade: rows can rest under the wake, not past it.'),
      TryStep('Switch off backdrop, then slide blurSigma to 15', 'With the planks gone you see the rows under the pier frosted: the wake can blur the water as well as fade it.'),
      TryStep('Pick wake: hairline', 'The fade goes and a brass line marks the pier\'s face, with the first row resting right at it.'),
    ],
    focus: const StageFocus.top(440),
    realWorld:
        'A pier is built out over the water on piles. Boats sail underneath it and tie up beside it; the water runs right '
        'up to the shore beneath the deck.',
    inYourApp:
        'A header (or any bar) the content scrolls under. The body runs the full height, the pier pads itself below the '
        'status bar, and its measured height reaches the body as MediaQuery.padding, so the first row rests clear of it. '
        'Its wake fades the rows as they pass under.',
    art: const PierArt(),
    controls: <Widget>[
      ChoiceControl<HarborWakeKind>(
        label: 'wake',
        values: HarborWakeKind.values,
        value: _wake,
        labelOf: (final HarborWakeKind k) => k.name,
        onChanged: (final HarborWakeKind k) => setState(() => _wake = k),
      ),
      if (_wake == HarborWakeKind.fade) ...<Widget>[
        SliderControl(label: 'length', value: _length, min: 0, max: 48, onChanged: (final double v) => setState(() => _length = v)),
        SliderControl(label: 'blurSigma', value: _blur, min: 0, max: 30, onChanged: (final double v) => setState(() => _blur = v)),
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
        'Harbor(\n'
        '  top: [\n'
        '    HarborDock.pier(\n'
        '      wake: $_wakeCode,\n'
        '${_backdrop ? '      backdrop: PierPlanks(),\n' : ''}'
        '      child: Header(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborFairway(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        HarborDock.pier(
          wake: _harborWake,
          backdrop: _backdrop ? ColoredBox(color: Palette.plank.withValues(alpha: 0.82)) : null,
          debugLabel: 'pier',
          child: const StageHeader(title: 'HarborDock.pier'),
        ),
      ],
      body: StageProbe(
        label: 'Harbor body (under the pier)',
        child: HarborFairway(
          slivers: <Widget>[
            SliverList.builder(itemCount: 30, itemBuilder: (final BuildContext context, final int i) => StageRow(index: i)),
          ],
        ),
      ),
    ),
  );
}

/// A dock of either kind, for the entries that switch between them.
HarborDock _dockOf(final HarborDockKind kind, {required final Widget child, final Widget? backdrop, final String? debugLabel}) =>
    kind == HarborDockKind.quay
    ? HarborDock.quay(backdrop: backdrop, debugLabel: debugLabel, child: child)
    : HarborDock.pier(
        wake: const HarborWake.fade(length: 12),
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

Widget _rows({final int count = 30}) => HarborFairway(
  slivers: <Widget>[
    SliverList.builder(itemCount: count, itemBuilder: (final BuildContext context, final int i) => StageRow(index: i)),
  ],
);

/// `HarborDock.quay`: a dock the body starts below.
class QuayEntry extends StatefulWidget {
  const QuayEntry({super.key});

  @override
  State<QuayEntry> createState() => _QuayEntryState();
}

class _QuayEntryState extends State<QuayEntry> {
  bool _top = true;
  bool _bottom = true;
  double _minimum = 16;

  @override
  Widget build(final BuildContext context) => GuidePage(
    // No focus, the whole phone: its switches take away the top quay as well as the bottom one.
    className: 'HarborDock.quay',
    tryThis: const <TryStep>[
      TryStep('Scroll the rows', 'They stop at the quays\' edges and never pass under: a quay takes its ground, and Readings show padding T 0 · B 0.'),
      TryStep('Switch off top quay', 'The body\'s outline jumps to the top of the screen and Readings show padding T 62: the body now meets the status bar.'),
      TryStep('Open The stage and pick Device: iPhone SE', 'No home indicator here, yet the bar stays 16 off the bottom edge: that is the quay\'s minimum.'),
      TryStep('Slide minimum to 0', 'The bar drops onto the bottom edge: with no home indicator and no minimum, nothing holds it off the glass.'),
    ],
    realWorld:
        'A quay is a stone wall built on the shore, with bollards along its edge. Boats lie alongside it; the water '
        'starts where the stone ends, and nothing sails underneath.',
    inYourApp:
        'A bar that takes its ground, like a child of a Column: the body starts where it ends, so content never runs under '
        'it, and a probe in the body reads padding 0 on that edge. A bottom quay is a tab bar; minimum keeps it 16 off the '
        'edge of a phone with no home indicator (try the iPhone SE).',
    art: const QuayArt(),
    controls: <Widget>[
      ToggleControl(label: 'top quay', value: _top, onChanged: (final bool v) => setState(() => _top = v)),
      ToggleControl(label: 'bottom quay', value: _bottom, onChanged: (final bool v) => setState(() => _bottom = v)),
      if (_bottom)
        SliderControl(label: 'minimum', value: _minimum, min: 0, max: 40, onChanged: (final double v) => setState(() => _minimum = v)),
    ],
    code:
        'Harbor(\n'
        '${_top ? '  top: [HarborDock.quay(backdrop: QuayStones(), child: Header())],\n' : ''}'
        '${_bottom ? '  bottom: [HarborDock.quay(minimum: ${_minimum.toStringAsFixed(0)}, child: TabBar())],\n' : ''}'
        '  body: HarborFairway(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        if (_top)
          const HarborDock.quay(
            backdrop: QuayStones(),
            debugLabel: 'quay',
            child: StageHeader(key: ValueKey<String>('top quay'), title: 'HarborDock.quay'),
          ),
      ],
      bottom: <HarborDock>[
        if (_bottom)
          HarborDock.quay(
            minimum: _minimum,
            backdrop: const QuayStones(),
            debugLabel: 'bottom quay',
            child: StageBar(key: const ValueKey<String>('bottom quay'), label: 'HarborDock.quay(minimum: ${_minimum.toStringAsFixed(0)})'),
          ),
      ],
      body: StageProbe(label: 'Harbor body (below the quay)', child: _MarkedBody(child: _rows())),
    ),
  );
}

/// Docks stacking on one edge.
class StackingEntry extends StatefulWidget {
  const StackingEntry({super.key});

  @override
  State<StackingEntry> createState() => _StackingEntryState();
}

class _StackingEntryState extends State<StackingEntry> {
  bool _second = true;
  HarborDockKind _composer = HarborDockKind.quay;
  HarborDockKind _tabBar = HarborDockKind.quay;

  /// A quay listed inside a pier: the harbor asserts on it.
  bool get _quayInsidePier => _second && _composer == HarborDockKind.quay && _tabBar == HarborDockKind.pier;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'bottom: [composer, tabBar]',
    tryThis: const <TryStep>[
      TryStep('Pick composer: pier', 'The body\'s outline drops past the composer to the tab bar: rows sail under a pier but stop at a quay.'),
      TryStep('Pick tabBar: pier', 'The body runs to the bottom of the screen under both docks, which still stack in the order they are listed.'),
      TryStep('Pick composer: quay, with tabBar still pier', 'The stage shows the assert: a quay is built on the shore, so it must be listed nearer the edge than any pier.'),
      TryStep('Switch off second dock (tabBar)', 'The composer quay alone takes the edge, above the home indicator: docks stack from the edge in, like a Column.'),
    ],
    focus: const StageFocus.bottom(480),
    realWorld:
        'When the quay is full, boats raft up: the second boat ties alongside the first instead of the wall, and anyone '
        'going ashore climbs across. The raft is as wide as both boats together.',
    inYourApp:
        'Docks on one edge are listed in reading order (bottom: top to bottom) and stack from the edge in, like a Column. '
        'Two quays add up and the body ends above both; a pier over a quay reaches past it, so rows sail under the '
        'composer but stop at the tab bar. Quays are always nearer the edge than piers.',
    art: const RaftedArt(),
    controls: <Widget>[
      ToggleControl(label: 'second dock (tabBar)', value: _second, onChanged: (final bool v) => setState(() => _second = v)),
      ChoiceControl<HarborDockKind>(
        label: 'composer',
        values: HarborDockKind.values,
        value: _composer,
        labelOf: (final HarborDockKind k) => k.name,
        onChanged: (final HarborDockKind k) => setState(() => _composer = k),
      ),
      if (_second)
        ChoiceControl<HarborDockKind>(
          label: 'tabBar',
          values: HarborDockKind.values,
          value: _tabBar,
          labelOf: (final HarborDockKind k) => k.name,
          onChanged: (final HarborDockKind k) => setState(() => _tabBar = k),
        ),
    ],
    code:
        'Harbor(\n'
        '  bottom: [\n'
        '    HarborDock.${_composer.name}(child: Composer()),\n'
        '${_second ? '    HarborDock.${_tabBar.name}(child: TabBar()),\n' : ''}'
        '  ],\n'
        '  body: HarborFairway(slivers: [messages]),\n'
        ')${_quayInsidePier ? '\n// Asserts: a quay listed inside a pier.' : ''}',
    stage: (final BuildContext context) => _quayInsidePier
        ? const _AssertCard(
            message:
                'A quay on the bottom edge is listed inside a pier, and the harbor asserts.\n\n'
                'Quays are built on the shore: list them nearer the edge than piers (on the bottom edge, after them).',
          )
        : Harbor(
            top: <HarborDock>[
              HarborDock.pier(
                backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.75)),
                child: const StageHeader(title: 'Stacking'),
              ),
            ],
            bottom: <HarborDock>[
              _dockOf(
                _composer,
                backdrop: _composer == HarborDockKind.quay
                    ? const QuayStones()
                    : ColoredBox(color: Palette.plank.withValues(alpha: 0.82)),
                debugLabel: 'composer',
                child: StageBar(
                  key: const ValueKey<String>('composer'),
                  label: 'composer: HarborDock.${_composer.name}',
                  icon: Icons.edit_rounded,
                ),
              ),
              if (_second)
                _dockOf(
                  _tabBar,
                  backdrop: _tabBar == HarborDockKind.quay ? const QuayStones() : ColoredBox(color: Palette.plank.withValues(alpha: 0.82)),
                  debugLabel: 'tabBar',
                  child: StageBar(
                    key: const ValueKey<String>('tabBar'),
                    label: 'tabBar: HarborDock.${_tabBar.name}',
                    icon: Icons.space_dashboard_rounded,
                  ),
                ),
            ],
            body: StageProbe(label: 'Harbor body', child: _MarkedBody(child: _rows())),
          ),
  );
}

class _AssertCard extends StatelessWidget {
  const _AssertCard({required this.message});

  final String message;

  @override
  Widget build(final BuildContext context) => HarborMoored(
    mooringLine: true,
    // On the bottom edge, where the docks it refuses would be, so the page's bottom view shows it.
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

/// `HarborDockState`: open, dark or withdrawn.
class DockStateEntry extends StatefulWidget {
  const DockStateEntry({super.key});

  @override
  State<DockStateEntry> createState() => _DockStateEntryState();
}

class _DockStateEntryState extends State<DockStateEntry> {
  HarborDockState _state = HarborDockState.open;
  HarborExtentPolicy _policy = HarborExtentPolicy.hold;
  double _duration = 1200;
  int _taps = 0;
  bool _playing = false;

  /// Withdraws the header, waits for it to go, and brings it back, so the
  /// extent policy can be watched both ways.
  Future<void> _play() async {
    setState(() {
      _playing = true;
      _state = HarborDockState.withdrawn;
    });
    await Future<void>.delayed(Duration(milliseconds: _duration.round() + 700));
    if (!mounted) {
      return;
    }
    setState(() => _state = HarborDockState.open);
    await Future<void>.delayed(Duration(milliseconds: _duration.round()));
    if (mounted) {
      setState(() => _playing = false);
    }
  }

  String get _hint => switch (_state) {
    HarborDockState.open =>
      'open: the lamp is lit, the header is drawn and its button counts taps. The gold outline (the body) starts below it.',
    HarborDockState.dark =>
      'dark: the header is gone, but the rows have not moved: the dashed box is the ground it still holds. Its button '
          'is gone too, so taps there do nothing.',
    HarborDockState.withdrawn => switch (_policy) {
      HarborExtentPolicy.hold =>
        'withdrawn + hold: the header slides up and away; the body waits until it has gone, then takes the ground.',
      HarborExtentPolicy.follow =>
        'withdrawn + follow: the body rises with the header as it slides, a frame at a time.',
      HarborExtentPolicy.release =>
        'withdrawn + release: the body takes the ground at once; the header slides away over the rows.',
    },
  };

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborDockState',
    tryThis: const <TryStep>[
      TryStep('Tap taps: 0 in the header', 'The count goes up: an open dock is drawn, takes taps, and the body starts below it.'),
      TryStep('Pick state: dark', 'The header vanishes but the rows stay put under a dashed box: a dark dock keeps its ground, and its button takes no taps.'),
      TryStep('Pick state: open, tap Withdraw and return (hold)', 'The header slides away and only then does the body rise to the top: hold gives the ground back once the dock has gone.'),
      TryStep('Pick extentPolicy: follow, tap Withdraw and return', 'The body rises right behind the header as it slides, a frame at a time, and drops back with it on the way in.'),
      TryStep('Pick extentPolicy: release, tap Withdraw and return', 'The body takes the top at once and the header slides out over the rows: release hands the ground over immediately.'),
    ],
    focus: const StageFocus.top(440),
    realWorld:
        'A harbor\'s lights tell you what is in service. A lit lamp is a working berth; a lamp that is out still stands '
        'where it stands; a drawbridge raised is out of the way altogether.',
    inYourApp:
        'open: drawn, tappable, its ground taken. dark: not drawn or tappable, but it keeps its ground, so nothing moves. '
        'withdrawn: it slides out toward its edge and gives its ground back. HarborExtentPolicy says when the body gets '
        'that ground: hold (once the dock has gone), follow (as it slides) or release (at once).',
    art: const HarborLightsArt(),
    controls: <Widget>[
      GuideHint(text: _hint),
      ChoiceControl<HarborDockState>(
        label: 'state',
        values: HarborDockState.values,
        value: _state,
        labelOf: (final HarborDockState s) => s.name,
        onChanged: (final HarborDockState s) => setState(() => _state = s),
      ),
      ChoiceControl<HarborExtentPolicy>(
        label: 'extentPolicy',
        values: HarborExtentPolicy.values,
        value: _policy,
        labelOf: (final HarborExtentPolicy p) => p.name,
        onChanged: (final HarborExtentPolicy p) => setState(() => _policy = p),
      ),
      SliderControl(label: 'duration', value: _duration, min: 100, max: 2000, onChanged: (final double v) => setState(() => _duration = v)),
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
        'HarborDock.quay(\n'
        '  state: HarborDockState.${_state.name},\n'
        '  extentPolicy: HarborExtentPolicy.${_policy.name},\n'
        '  duration: const Duration(milliseconds: ${_duration.toStringAsFixed(0)}),\n'
        '  child: Header(),\n'
        ')',
    stage: (final BuildContext context) => Stack(
      children: <Widget>[
        Positioned.fill(
          child: Harbor(
            top: <HarborDock>[
              HarborDock.quay(
                state: _state,
                extentPolicy: _policy,
                duration: Duration(milliseconds: _duration.round()),
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
            bottom: const <HarborDock>[
              HarborDock.quay(backdrop: QuayStones(), child: StageBar(label: 'tab bar (stays open)')),
            ],
            body: StageProbe(label: 'Harbor body', child: _MarkedBody(child: _rows())),
          ),
        ),
        // Where a dark dock still stands: its ground, held.
        if (_state == HarborDockState.dark)
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

/// The header on the dock-state stage: a harbor lamp that's lit while the
/// dock is open, its state, and a button that counts taps.
class _LampHeader extends StatelessWidget {
  const _LampHeader({super.key, required this.state, required this.taps, required this.onTap});

  static const double height = 52;

  final HarborDockState state;
  final int taps;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: height,
    child: HarborMooringLine(
      child: Row(
        children: <Widget>[
          Icon(
            state == HarborDockState.open ? Icons.light_rounded : Icons.light_outlined,
            color: state == HarborDockState.open ? Palette.brass : Palette.foam.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'state: ${state.name}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 15, fontWeight: FontWeight.w700, color: Palette.foam),
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

/// A dashed outline where a dark dock stands, unseen.
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

/// `HarborDock.restingExtent` and `HarborFollow`: a rail that opens over content, or pushes it.
class RestingExtentEntry extends StatefulWidget {
  const RestingExtentEntry({super.key});

  @override
  State<RestingExtentEntry> createState() => _RestingExtentEntryState();
}

class _RestingExtentEntryState extends State<RestingExtentEntry> {
  bool _expanded = false;
  double _resting = 72;
  HarborFollow _follow = HarborFollow.resting;

  Widget _panel(final String key, final HarborFollow follow, final Color color) => HarborMoored(
    edges: const <HarborEdge>{HarborEdge.start},
    follow: follow,
    child: Container(
      key: ValueKey<String>(key),
      height: 170,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadiusDirectional.horizontal(end: Radius.circular(12))),
      child: Text(
        'HarborMoored(\n  follow: HarborFollow.${follow.name},\n)',
        style: const TextStyle(fontFamily: 'Menlo', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborDock.restingExtent + HarborFollow',
    tryThis: const <TryStep>[
      TryStep('Slide restingExtent to 100', 'The closed rail and both panels move to 100: restingExtent is the ground the rail holds at rest.'),
      TryStep('Tap the rail', 'It opens to 210 and the HarborFollow.live panel moves with it; the resting panel holds still and the rail opens over it.'),
      TryStep('Pick follow: live', 'The second panel jumps out to the open rail too: live content follows the rail as it grows.'),
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
      SliderControl(label: 'restingExtent', value: _resting, min: 56, max: 110, onChanged: (final double v) => setState(() => _resting = v)),
      ChoiceControl<HarborFollow>(
        label: 'follow',
        values: HarborFollow.values,
        value: _follow,
        labelOf: (final HarborFollow f) => f.name,
        onChanged: (final HarborFollow f) => setState(() => _follow = f),
      ),
    ],
    code:
        'Harbor(\n'
        '  start: [\n'
        '    HarborDock.pier(\n'
        '      restingExtent: ${_resting.toStringAsFixed(0)},\n'
        '      child: Rail(open: $_expanded),\n'
        '    ),\n'
        '  ],\n'
        '  body: Column(children: [\n'
        '    HarborMoored(follow: HarborFollow.live, child: panel),\n'
        '    HarborMoored(follow: HarborFollow.${_follow.name}, child: page),\n'
        '  ]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      start: <HarborDock>[
        HarborDock.pier(
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
        label: 'Harbor body (under the rail)',
        child: HarborMoored(
          edges: HarborEdge.vertical,
          extra: const EdgeInsetsDirectional.only(top: 12),
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

/// `HarborDock.hitTestBehavior`: whether taps on a dock reach what's under it.
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
    className: 'HarborDock.hitTestBehavior',
    tryThis: const <TryStep>[
      TryStep('Tap a row below the header', 'The row taps counter in the bottom bar goes up: rows clear of the header take taps.'),
      TryStep('Tap the header beside its title', 'Nothing counts: opaque, the default, stops taps on the dock\'s ground, even over a row scrolled under it.'),
      TryStep('Pick hitTestBehavior: translucent, tap beside the title', 'The row under the header counts the tap: translucent lets taps on the dock\'s empty parts through.'),
      TryStep('Tap the title itself', 'No count: the header\'s own text still takes its tap; only its empty parts pass taps on.'),
    ],
    realWorld:
        'A gate at the head of the gangway down to the pontoon. Shut, nobody passes it; open, people walk straight '
        'through to the boats beyond.',
    inYourApp:
        'Whether a tap on a dock\'s ground stops there. Opaque (the default) means a tap on the header never reaches a '
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
        'HarborDock.pier(\n'
        '  hitTestBehavior: HitTestBehavior.${_behavior.name},\n'
        '  // A backdrop that takes no taps of its own.\n'
        '  backdrop: IgnorePointer(child: Frosting()),\n'
        '  child: Header(),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        HarborDock.pier(
          hitTestBehavior: _behavior,
          wake: const HarborWake.fade(length: 10),
          // A ColoredBox takes taps itself, so the backdrop ignores them.
          backdrop: IgnorePointer(child: ColoredBox(color: Palette.night.withValues(alpha: 0.6))),
          debugLabel: 'header',
          child: StageHeader(key: const ValueKey<String>('gate header'), title: 'hitTestBehavior: ${_behavior.name}'),
        ),
      ],
      bottom: <HarborDock>[
        HarborDock.quay(
          backdrop: const QuayStones(),
          child: StageBar(
            key: const ValueKey<String>('tap counter'),
            label: 'row taps: $_total${_last == null ? '' : ' (last: row ${_last! + 1})'}',
            icon: Icons.touch_app_rounded,
          ),
        ),
      ],
      body: StageProbe(
        label: 'Harbor body',
        child: HarborFairway(
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
                          style: const TextStyle(fontFamily: 'Menlo', color: Palette.brass, fontWeight: FontWeight.w700),
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
