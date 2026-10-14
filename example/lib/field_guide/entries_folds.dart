import 'dart:ui' show DisplayFeature;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import 'art/folds_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Folds and hinges: dual screens and foldables, and what keeps off the crease.
final List<GuideEntry> foldEntries = <GuideEntry>[
  GuideEntry(
    id: 'hinge',
    className: 'HarborHinge',
    group: GuideGroup.folds,
    realWorld: 'Like a lock’s gates: nothing lies across the line between them',
    art: (final BuildContext context) => const LockGatesArt(),
    page: (final BuildContext context) => const HingeEntry(),
  ),
  GuideEntry(
    id: 'panes',
    className: 'HarborPanes',
    group: GuideGroup.folds,
    realWorld: 'Like twin locks: two panes side by side, a page in each',
    art: (final BuildContext context) => const TwinLocksArt(),
    page: (final BuildContext context) => const PanesEntry(),
  ),
  GuideEntry(
    id: 'posture',
    className: 'HarborPosture',
    group: GuideGroup.folds,
    realWorld: 'Like a logbook: how it is held decides how the page is used',
    art: (final BuildContext context) => const LogbookArt(),
    page: (final BuildContext context) => const PostureEntry(),
  ),
];

String _n(final double v) => v.toStringAsFixed(0);

/// A fold or hinge in a few words: which way it runs, where, and how open it is.
String _feature(final DisplayFeature f) {
  final bool down = f.bounds.height >= f.bounds.width;
  final String at = down
      ? 'x ${_n(f.bounds.left)}–${_n(f.bounds.right)}'
      : 'y ${_n(f.bounds.top)}–${_n(f.bounds.bottom)}';
  return '${f.type.name} $at ${f.state.name.replaceFirst('posture', '').toLowerCase()}';
}

String _features(final Iterable<DisplayFeature> features) =>
    features.isEmpty ? 'none' : features.map(_feature).join(', ');

/// Reports what the hinge policy at its place keeps off, and the posture, to the readings.
class _HingeProbe extends StatelessWidget {
  const _HingeProbe({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final HarborHinge hinge = HarborHinge.of(context);
    final List<DisplayFeature> features = MediaQuery.displayFeaturesOf(context);
    final String reading =
        'HarborHinge.of    ${hinge.name}\n'
        'HarborPosture.of  ${HarborPosture.of(context).name}\n'
        'displayFeatures   ${_features(features)}\n'
        'kept off          ${_features(hinge.keptOff(features))}';
    final StageSettings? settings = StageScope.settingsOf(context);
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) => settings?.report('The page’s hinge', reading));
    return child;
  }
}

Widget _rows({final int count = 24}) => HarborScrollView(
  slivers: <Widget>[
    SliverList.builder(
      itemCount: count,
      itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
    ),
  ],
);

// ─── HarborHinge ──────────────────────────────────────────────────────────────

/// Where the entry sets the policy.
enum _HingeOn {
  page('HarborFrame(hinge:)'),
  bars('HarborFrame(barHinge:)'),
  float('HarborFloat(hinge:)');

  const _HingeOn(this.label);

  final String label;
}

/// `HarborHinge`: which hinges and folds the bars and overlays keep off.
class HingeEntry extends StatefulWidget {
  const HingeEntry({super.key});

  @override
  State<HingeEntry> createState() => _HingeEntryState();
}

class _HingeEntryState extends State<HingeEntry> {
  HarborHinge _policy = HarborHinge.avoidSeparating;
  _HingeOn _on = _HingeOn.page;

  String get _policyCode => 'HarborHinge.${_policy.name}';

  @override
  Widget build(final BuildContext context) => GuidePage(
    // No focus, the whole device: the header, the tab bar and the float all keep to one screen.
    className: 'HarborHinge',
    device: StageDevice.dualScreenOpen,
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage and pick Device: dual screen open',
        'The header and the tab bar stop at the hinge and the HarborFloat sits in the middle of the left screen: '
            'avoidSeparating, the default, keeps off a hinge 34 wide.',
      ),
      TryStep(
        'On dual screen open, pick policy: never',
        'The bars run across the hinge and the float sits on it, half on each screen: never treats the two screens as one.',
      ),
      TryStep(
        'Pick Device: foldable open, then policy: avoidSeparating, then always',
        'Flat, the fold has no width, so avoidSeparating lets the bars cross it; always stops them at the crease.',
      ),
      TryStep(
        'On foldable open, pick Posture: book, then policy: avoidOccluding',
        'Half open, avoidSeparating keeps off the fold too; avoidOccluding crosses it again, since only a hinge with width hides content.',
      ),
      TryStep(
        'Pick Device: dual screen open, policy: never and set on: HarborFrame(barHinge:)',
        'The bars cross the hinge but the float goes back to the left screen: barHinge sets the bars alone, and the '
            'overlays keep the root’s avoidSeparating.',
      ),
      TryStep(
        'On dual screen open, open The stage and switch on Right-to-left',
        'The header and the tab bar move to the right screen, where reading starts.',
      ),
    ],
    realWorld:
        'Drawn as a lock’s gates, hung on iron hinges in the stone walls. Where the two leaves meet the water cannot '
        'pass, and no boat lies across the line between them: each waits on its own side, as content does at a hinge.',
    inYourApp:
        'A dual-screen device has a hinge between its screens, and a foldable has a fold. HarborHinge says which of them '
        'harbor keeps things off: a header or tab bar keeps to the screen where reading starts, and a float, toast, '
        'sheet or dialog keeps to one screen. avoidSeparating (the default) keeps off a hinge with width and a half-open '
        'fold, avoidOccluding only a hinge with width, always every fold, and never nothing. Set the app’s on '
        'HarborRoot(hinge:), a page’s on HarborFrame(hinge:), only its bars’ on HarborFrame(barHinge:), and one '
        'overlay’s on its own hinge:. The nearest wins.',
    art: const LockGatesArt(),
    controls: <Widget>[
      ChoiceControl<HarborHinge>(
        label: 'policy',
        values: HarborHinge.values,
        value: _policy,
        labelOf: (final HarborHinge h) => h.name,
        onChanged: (final HarborHinge h) => setState(() => _policy = h),
      ),
      ChoiceControl<_HingeOn>(
        label: 'set on',
        values: _HingeOn.values,
        value: _on,
        labelOf: (final _HingeOn o) => o.label,
        onChanged: (final _HingeOn o) => setState(() => _on = o),
      ),
      Text(
        'Pick dual screen open or foldable open on The stage (and a Posture for the foldable): a phone has no hinge, so '
        'every policy looks the same on it.',
        style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
      ),
    ],
    code:
        '// The app’s default, for every page:\n'
        'HarborRoot(hinge: HarborHinge.avoidSeparating, child: child!)\n'
        '\n'
        'HarborFrame(\n'
        '${_on == _HingeOn.page ? '  hinge: $_policyCode,\n' : ''}'
        '${_on == _HingeOn.bars ? '  barHinge: $_policyCode,\n' : ''}'
        '  top: [HarborBar.overlay(child: Header())],\n'
        '  bottom: [HarborBar.solid(child: TabBar())],\n'
        '  floats: [\n'
        '    HarborFloat(\n'
        '${_on == _HingeOn.float ? '      hinge: $_policyCode,\n' : ''}'
        '      placement: HarborAligned(), // bottom centre\n'
        '      child: NowPlaying(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborScrollView(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      key: const ValueKey<String>('hinge harbor'),
      debugLabel: 'hinge page',
      hinge: _on == _HingeOn.page ? _policy : null,
      barHinge: _on == _HingeOn.bars ? _policy : null,
      top: <HarborBar>[
        HarborBar.overlay(
          debugLabel: 'header',
          edgeEffect: const HarborEdgeEffect.fade(length: 12),
          backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
          child: const StageHeader(key: ValueKey<String>('hinge header'), title: 'Header'),
        ),
      ],
      bottom: const <HarborBar>[
        HarborBar.solid(
          debugLabel: 'tab bar',
          backdrop: ColoredBox(color: Palette.night),
          child: StageBar(key: ValueKey<String>('hinge tab bar'), label: 'Tab bar'),
        ),
      ],
      floats: <HarborFloat>[
        HarborFloat(
          hinge: _on == _HingeOn.float ? _policy : null,
          placement: const HarborAligned(),
          child: const StageMarker(key: ValueKey<String>('hinge buoy'), label: 'HarborFloat', width: 220),
        ),
      ],
      body: _HingeProbe(
        child: StageProbe(label: 'Frame body', child: _rows()),
      ),
    ),
  );
}

// ─── HarborPanes ──────────────────────────────────────────────────────────────

/// The panes' own `hinge:`, or the page's when null.
enum _PanesHinge {
  page(null, 'null (the page’s)'),
  always(HarborHinge.always, 'always'),
  never(HarborHinge.never, 'never');

  const _PanesHinge(this.hinge, this.label);

  final HarborHinge? hinge;
  final String label;
}

/// `HarborPanes`: two panes either side of a hinge, side by side when wide, one alone otherwise.
class PanesEntry extends StatefulWidget {
  const PanesEntry({super.key});

  @override
  State<PanesEntry> createState() => _PanesEntryState();
}

class _PanesEntryState extends State<PanesEntry> {
  HarborPanePriority _priority = HarborPanePriority.start;
  double _minWideWidth = 840;
  double _startPercent = 50;
  _PanesHinge _hinge = _PanesHinge.page;

  @override
  Widget build(final BuildContext context) => GuidePage(
    // No focus, the whole device: the panes are the whole screen.
    className: 'HarborPanes',
    device: StageDevice.dualScreenOpen,
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage and pick Device: dual screen open',
        'Inbox fills the left screen and Message the right, each with a header of its own: the panes go either side of '
            'the hinge, and Readings show modeOf wide.',
      ),
      TryStep(
        'Pick Device: iPhone 17',
        'Only Inbox is left: 402 is under minWideWidth 840, so priority’s pane is shown alone and modeOf reads single.',
      ),
      TryStep(
        'On iPhone 17, pick priority: end',
        'Message takes the phone instead: priority picks the pane a narrow screen keeps.',
      ),
      TryStep(
        'Pick Device: foldable open, then slide minWideWidth to 700 and startFraction % to 30',
        'Flat, the fold keeps nothing apart and the screen is 750 wide: past minWideWidth the panes go side by side, '
            'Inbox taking 30% whatever the crease.',
      ),
      TryStep(
        'On foldable open, pick Posture: book',
        'The panes jump to the fold: a half-open fold is kept off, so it decides where they meet, not startFraction.',
      ),
      TryStep(
        'Pick Posture: tabletop',
        'The foldable turns on its side, Inbox above the fold and Message below, and modeOf reads tall.',
      ),
    ],
    realWorld:
        'Drawn as twin locks: two chambers side by side with a stone wall between them. Each takes its own boat and is '
        'worked on its own; when traffic is light only one is used.',
    inYourApp:
        'Two panes, modelled on Windows’ TwoPaneView: list and detail, or two pages. Either side of a hinge the policy keeps '
        'off; side by side when the width reaches minWideWidth (840, Material’s expanded width), one above the other '
        'from minTallHeight (off by default), and otherwise priority’s pane alone. startFraction is the start pane’s share '
        'when no hinge decides it. Each pane is a screen of its own, with its own size and only its outer system edges, '
        'so each is a HarborFrame with bars of its own. HarborPanes.modeOf(context) tells a list whether its detail is on screen.',
    art: const TwinLocksArt(),
    controls: <Widget>[
      ChoiceControl<HarborPanePriority>(
        label: 'priority',
        values: HarborPanePriority.values,
        value: _priority,
        labelOf: (final HarborPanePriority p) => p.name,
        onChanged: (final HarborPanePriority p) => setState(() => _priority = p),
      ),
      SliderControl(
        label: 'minWideWidth',
        value: _minWideWidth,
        min: 400,
        max: 1200,
        divisions: 16,
        onChanged: (final double v) => setState(() => _minWideWidth = v),
      ),
      SliderControl(
        label: 'startFraction %',
        value: _startPercent,
        min: 20,
        max: 80,
        divisions: 12,
        onChanged: (final double v) => setState(() => _startPercent = v),
      ),
      ChoiceControl<_PanesHinge>(
        label: 'hinge',
        values: _PanesHinge.values,
        value: _hinge,
        labelOf: (final _PanesHinge h) => h.label,
        onChanged: (final _PanesHinge h) => setState(() => _hinge = h),
      ),
    ],
    code:
        'HarborPanes(\n'
        '  start: HarborFrame(top: [HarborBar.overlay(child: Header())], body: inbox),\n'
        '  end: HarborFrame(top: [HarborBar.overlay(child: Header())], body: message),\n'
        '  priority: HarborPanePriority.${_priority.name},\n'
        '  minWideWidth: ${_n(_minWideWidth)},\n'
        '  startFraction: ${(_startPercent / 100).toStringAsFixed(2)},\n'
        '${_hinge.hinge == null ? '' : '  hinge: HarborHinge.${_hinge.name},\n'}'
        ')',
    stage: (final BuildContext context) => _HingeProbe(
      child: HarborPanes(
        key: const ValueKey<String>('panes'),
        priority: _priority,
        minWideWidth: _minWideWidth,
        startFraction: _startPercent / 100,
        hinge: _hinge.hinge,
        start: const _Pane(side: 'start', title: 'Inbox', list: true),
        end: const _Pane(side: 'end', title: 'Message', list: false),
      ),
    ),
  );
}

/// One pane: a frame of its own with a header, a list or a message under it.
class _Pane extends StatelessWidget {
  const _Pane({required this.side, required this.title, required this.list});

  final String side;
  final String title;
  final bool list;

  @override
  Widget build(final BuildContext context) {
    final HarborPanesMode mode = HarborPanes.modeOf(context)!;
    final StageSettings? settings = StageScope.settingsOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (final Duration _) => settings?.report('HarborPanes.modeOf', mode.name),
    );
    return ColoredBox(
      key: ValueKey<String>('$side pane'),
      color: list ? Palette.deepSea : const Color(0xFF123A5E),
      child: HarborFrame(
        debugLabel: '$side pane',
        top: <HarborBar>[
          HarborBar.overlay(
            debugLabel: '$side header',
            edgeEffect: const HarborEdgeEffect.fade(length: 10),
            backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
            child: StageHeader(key: ValueKey<String>('$side header'), title: '$side: $title'),
          ),
        ],
        body: StageProbe(
          label: '$side pane',
          child: list
              ? _rows()
              : HarborClear(
                  rowInsets: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'From: harbor master\n\nThe end pane. HarborPanes.modeOf(context) is ${mode.name}, so a tap on a '
                      'row ${mode == HarborPanesMode.single ? 'opens this as a page of its own' : 'shows its message here'}.',
                      key: ValueKey<String>('$side mode'),
                      style: const TextStyle(color: Palette.foam, fontSize: 15, height: 1.4),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── HarborPosture ────────────────────────────────────────────────────────────

/// `HarborPosture`: how a foldable is held, read from its fold.
class PostureEntry extends StatefulWidget {
  const PostureEntry({super.key});

  @override
  State<PostureEntry> createState() => _PostureEntryState();
}

class _PostureEntryState extends State<PostureEntry> {
  final StageSettings _settings = StageSettings(device: StageDevice.foldableOpen);
  late HarborPosture _held = _settings.posture;
  bool _follows = true;

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
    if (_settings.posture != _held) {
      setState(() => _held = _settings.posture);
    }
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    // No focus, the whole device: the fold runs through the middle of it.
    className: 'HarborPosture',
    settings: _settings,
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage, pick Device: foldable open and posture: flat',
        'One screen: the video on top and the controls on a solid bar at the bottom, the crease running through the video, '
            'and HarborPosture.flat on it.',
      ),
      TryStep(
        'On foldable open, pick posture: tabletop',
        'The foldable turns on its side, half open: the video moves above the fold and the controls below it, as '
            'Android’s tabletop guidance has it.',
      ),
      TryStep(
        'Still in tabletop, switch off follows posture',
        'The page lays out as if it were flat, and the video now bends over the fold: reading HarborPosture.of is what '
            'moved it.',
      ),
      TryStep(
        'Switch follows posture back on and pick posture: book',
        'The video takes the left page and the controls the right: held like a book, the two panes are its pages.',
      ),
      TryStep(
        'Pick Device: dual screen open, then posture: tabletop',
        'A hinge half open is a posture too: the video sits on the upper screen and the controls on the lower one.',
      ),
    ],
    realWorld:
        'Drawn as a logbook open on the chart table, flat while the mate writes in it, or standing half open like a book '
        'to be read across both pages. How it is held decides how the page is used, as with a foldable.',
    inYourApp:
        'HarborPosture.of(context) is how a foldable is held, from the half-open fold or hinge in MediaQuery.displayFeatures: '
        'flat, tabletop (half open with the fold across the screen, the lower half on a table) or book (half open with the '
        'fold down the middle). A page reads it to rearrange itself: on a table a HarborPanes puts its start pane above the '
        'fold and its end pane below, so a video sits above its controls; in a book the two panes are its pages.',
    art: const LogbookArt(),
    controls: <Widget>[
      ChoiceControl<HarborPosture>(
        label: 'posture',
        values: HarborPosture.values,
        value: _held,
        labelOf: (final HarborPosture p) => p.name,
        onChanged: (final HarborPosture p) => _settings.posture = p,
      ),
      ToggleControl(
        label: 'follows posture',
        value: _follows,
        onChanged: (final bool v) => setState(() => _follows = v),
      ),
      Text(
        'posture is the stage’s Posture, here for the asking: it only changes a device with a fold or a hinge.',
        style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
      ),
    ],
    code: _follows
        ? 'final HarborPosture posture = HarborPosture.of(context);\n'
              'if (posture == HarborPosture.flat) return OnePage();\n'
              '// tabletop: video above the fold, controls below;\n'
              '// book: the video on one page, the controls on the other.\n'
              'return HarborPanes(\n'
              '  start: HarborFrame(top: [HarborBar.overlay(child: Header())], body: Video()),\n'
              '  end: HarborFrame(bottom: [HarborBar.solid(child: Controls())], body: chapters),\n'
              ');'
        : '// The same page however the foldable is held:\n'
              'return OnePage();\n'
              '\n'
              'HarborFrame(\n'
              '  top: [HarborBar.overlay(child: Header())],\n'
              '  bottom: [HarborBar.solid(child: Controls())],\n'
              '  body: Column(children: [Video(), chapters]),\n'
              ')',
    stage: (final BuildContext context) => _HingeProbe(
      child: Builder(
        builder: (final BuildContext context) {
          final HarborPosture posture = HarborPosture.of(context);
          if (!_follows || posture == HarborPosture.flat) {
            return _player(posture, video: true, controls: true);
          }
          return HarborPanes(
            key: const ValueKey<String>('posture panes'),
            start: _player(posture, video: true, controls: false),
            end: _player(posture, video: false, controls: true),
          );
        },
      ),
    ),
  );

  /// A player page: a header and the video, the controls on a solid bar, or both on one page.
  Widget _player(final HarborPosture posture, {required final bool video, required final bool controls}) => HarborFrame(
    debugLabel: video ? 'video' : 'controls',
    top: <HarborBar>[
      if (video)
        HarborBar.overlay(
          debugLabel: 'header',
          backdrop: ColoredBox(color: Palette.plank.withValues(alpha: 0.85)),
          child: const StageHeader(title: 'Now playing'),
        ),
    ],
    bottom: <HarborBar>[
      if (controls)
        const HarborBar.solid(
          debugLabel: 'controls',
          backdrop: ColoredBox(color: Palette.night),
          child: _PlayerControls(),
        ),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (video)
          // Up to three fifths of the page with the list under it, all of a pane of its own.
          Flexible(
            flex: controls ? 3 : 1,
            child: HarborClear(
              edges: const <HarborEdge>{HarborEdge.top},
              child: _Video(posture: posture),
            ),
          ),
        // Below the video, which already cleared the header: the list leaves the top alone.
        if (controls)
          Expanded(
            flex: 2,
            child: video
                ? HarborHandled(edges: const <HarborEdge>{HarborEdge.top}, child: _rows(count: 12))
                : _rows(count: 12),
          ),
      ],
    ),
  );
}

/// The video: a dark frame with a play button and the posture written on it.
class _Video extends StatelessWidget {
  const _Video({required this.posture});

  final HarborPosture posture;

  @override
  Widget build(final BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        key: const ValueKey<String>('posture video'),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Palette.shallows, Palette.sea],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.play_circle_fill_rounded, size: 56, color: Palette.foam),
            const SizedBox(height: 8),
            Text(
              'HarborPosture.${posture.name}',
              key: const ValueKey<String>('posture label'),
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Palette.foam,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A player's controls, drawn and not wired: back, play, forward and a scrubber.
class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(final BuildContext context) => SizedBox(
    key: const ValueKey<String>('posture controls'),
    height: 64,
    child: HarborClear.rowInsets(
      child: Row(
        children: <Widget>[
          const Icon(Icons.replay_10_rounded, color: Palette.foam),
          const SizedBox(width: 12),
          const Icon(Icons.pause_circle_filled_rounded, color: Palette.brass, size: 36),
          const SizedBox(width: 12),
          const Icon(Icons.forward_10_rounded, color: Palette.foam),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 0.4,
                color: Palette.brass,
                backgroundColor: Palette.foam.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
