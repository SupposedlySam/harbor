import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/palette.dart';
import '../game/fleet.dart';
import 'art/content_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Content (how content keeps clear, sails under or ignores the docks) and
/// talking to the harbor (content asking the docks for room).
final List<GuideEntry> contentEntries = <GuideEntry>[
  GuideEntry(
    id: 'content-moored',
    className: 'HarborMoored',
    group: GuideGroup.content,
    realWorld: 'A boat moored alongside a quay, held off the wall by fenders',
    art: (final BuildContext context) => const MooredArt(),
    page: (final BuildContext context) => const MooredEntry(),
  ),
  GuideEntry(
    id: 'content-mooring-line',
    className: 'HarborMooringLine',
    group: GuideGroup.content,
    realWorld: 'Boats lined up along a quay, all tied to one mooring line',
    art: (final BuildContext context) => const MooringLineArt(),
    page: (final BuildContext context) => const MooringLineEntry(),
  ),
  GuideEntry(
    id: 'content-fairway',
    className: 'HarborFairway',
    group: GuideGroup.content,
    realWorld: 'A buoyed channel leading boats in from the sea',
    art: (final BuildContext context) => const FairwayArt(),
    page: (final BuildContext context) => const FairwayEntry(),
  ),
  GuideEntry(
    id: 'content-fairway-sliver',
    className: 'HarborFairwaySliver',
    group: GuideGroup.content,
    realWorld: 'A single channel marker on its chain',
    art: (final BuildContext context) => const FairwaySliverArt(),
    page: (final BuildContext context) => const FairwaySliverEntry(),
  ),
  GuideEntry(
    id: 'content-sliver-dock',
    className: 'HarborSliverDock',
    group: GuideGroup.content,
    realWorld: 'A landing stage on a gangway pinned to the quay',
    art: (final BuildContext context) => const SliverDockArt(),
    page: (final BuildContext context) => const SliverDockEntry(),
  ),
  GuideEntry(
    id: 'content-sticky',
    className: 'HarborSticky',
    group: GuideGroup.content,
    realWorld: 'Barnacles clinging to a hull',
    art: (final BuildContext context) => const StickyArt(),
    page: (final BuildContext context) => const StickyEntry(),
  ),
  GuideEntry(
    id: 'content-center',
    className: 'HarborCenter',
    group: GuideGroup.content,
    realWorld: 'A compass rose, a ship held mid-channel',
    art: (final BuildContext context) => const CenterArt(),
    page: (final BuildContext context) => const CenterEntry(),
  ),
  GuideEntry(
    id: 'content-open-water',
    className: 'HarborOpenWater',
    group: GuideGroup.content,
    realWorld: 'A depth chart with its soundings',
    art: (final BuildContext context) => const OpenWaterArt(),
    page: (final BuildContext context) => const OpenWaterEntry(),
  ),
  GuideEntry(
    id: 'content-cast-off',
    className: 'HarborCastOff',
    group: GuideGroup.content,
    realWorld: 'Casting a line off its bollard',
    art: (final BuildContext context) => const CastOffArt(),
    page: (final BuildContext context) => const CastOffEntry(),
  ),
  GuideEntry(
    id: 'talk-make-way',
    className: 'HarborMakeWay',
    group: GuideGroup.talk,
    realWorld: 'A small sailboat giving way to a ship in the channel',
    art: (final BuildContext context) => const MakeWayArt(),
    page: (final BuildContext context) => const MakeWayEntry(),
  ),
  GuideEntry(
    id: 'talk-pontoon',
    className: 'HarborPontoon',
    group: GuideGroup.talk,
    realWorld: 'A floating pontoon tied to the quay',
    art: (final BuildContext context) => const PontoonArt(),
    page: (final BuildContext context) => const PontoonEntry(),
  ),
];

// Shared bits for this group's stages.

Color get _dockColor => Palette.plank.withValues(alpha: 0.86);
Color get _barColor => Palette.stoneDark.withValues(alpha: 0.92);

HarborDock _pierHeader({final HarborWake wake = HarborWake.none, final String title = 'HarborDock.pier'}) => HarborDock.pier(
  wake: wake,
  backdrop: ColoredBox(color: _dockColor),
  debugLabel: 'pier header',
  child: StageHeader(key: const ValueKey<String>('pier header'), title: title),
);

HarborDock _quayBar({final String label = 'HarborDock.quay', final Widget? child}) => HarborDock.quay(
  backdrop: ColoredBox(color: _barColor),
  debugLabel: 'quay bar',
  child: KeyedSubtree(key: const ValueKey<String>('quay bar'), child: child ?? StageBar(label: label)),
);

HarborDock _bottomPier({final String label = 'HarborDock.pier (bottom)'}) => HarborDock.pier(
  backdrop: ColoredBox(color: _barColor),
  debugLabel: 'bottom pier',
  child: StageBar(key: const ValueKey<String>('bottom pier'), label: label),
);

List<Widget> _rows(final int from, final int count) => <Widget>[
  for (int i = from; i < from + count; i++) StageRow(index: i),
];

String _n(final double v) => v.toStringAsFixed(0);

/// A box that fills where it lands, outlined and labeled, so you can see
/// exactly where a widget was put.
class _LandedBox extends StatelessWidget {
  const _LandedBox({super.key, required this.label, this.color = Palette.buoyRed, this.detail});

  final String label;
  final String? detail;
  final Color color;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.22),
      border: Border.all(color: color, width: 2),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: const TextStyle(fontFamily: 'Menlo', fontSize: 16, fontWeight: FontWeight.w700, color: Palette.foam)),
          if (detail != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                detail!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Menlo', fontSize: 12, color: Palette.foam.withValues(alpha: 0.8)),
              ),
            ),
        ],
      ),
    ),
  );
}

/// A bar that sits in a scroll view: a sliver dock's strip, an unsaved bar.
class _Strip extends StatelessWidget {
  const _Strip({super.key, required this.label, this.color = Palette.brass, this.trailing, this.height = 44});

  final String label;
  final Color color;
  final Widget? trailing;
  final double height;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: height,
    child: HarborMooringLine(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Menlo', fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          ?trailing,
        ],
      ),
    ),
  );
}

// 1. HarborMoored ------------------------------------------------------------

enum _EdgeSet {
  all('all', 'HarborEdge.all'),
  top('top', '{HarborEdge.top}'),
  bottom('bottom', '{HarborEdge.bottom}'),
  horizontal('horizontal', 'HarborEdge.horizontal');

  const _EdgeSet(this.label, this.code);

  final String label;
  final String code;

  Set<HarborEdge> get edges => switch (this) {
    all => HarborEdge.all,
    top => const <HarborEdge>{HarborEdge.top},
    bottom => const <HarborEdge>{HarborEdge.bottom},
    horizontal => HarborEdge.horizontal,
  };
}

/// `HarborMoored`: content kept clear of everything in its way.
class MooredEntry extends StatefulWidget {
  const MooredEntry({super.key});

  @override
  State<MooredEntry> createState() => _MooredEntryState();
}

class _MooredEntryState extends State<MooredEntry> {
  _EdgeSet _edges = _EdgeSet.all;
  HarborClear _clear = HarborClear.everything;
  bool _tide = true;
  bool _mooringLine = false;
  double _minimum = 0;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborMoored',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the keyboard button',
        'The red box\'s bottom edge rises to the keyboard\'s top: HarborMoored keeps clear of the keyboard as well as the docks.',
      ),
      TryStep(
        'Switch tide off, keyboard still up',
        'The box drops back to the quay bar and the keyboard covers its bottom: it still clears the docks, not the keyboard.',
      ),
      TryStep(
        'Pick edges: horizontal',
        'The box\'s top runs up under the header to the top of the screen: only the left and right edges are kept clear.',
      ),
      TryStep(
        'Pick edges: all, then clear: coast',
        'The top sits just under the status bar, behind the header: coast clears the device\'s insets but not the docks.',
      ),
      TryStep(
        'Switch mooringLine on',
        'The sides pull in by the page margin, so the box lines up with rows that use HarborMooringLine.',
      ),
    ],
    realWorld:
        'A moored boat is made fast with a bow line and a stern line to bollards on the quay, and fenders hang between '
        'the hull and the wall. Whatever the tide and the traffic do, it stays put, clear of the stone.',
    inYourApp:
        'A form, a fixed button, a block of text: padded clear of the coast, the docks and (at the bottom) the keyboard '
        'on the edges you choose. It then casts those edges off, so nothing inside it clears them again.',
    art: const MooredArt(),
    controls: <Widget>[
      ChoiceControl<_EdgeSet>(
        label: 'edges',
        values: _EdgeSet.values,
        value: _edges,
        labelOf: (final _EdgeSet e) => e.label,
        onChanged: (final _EdgeSet e) => setState(() => _edges = e),
      ),
      ChoiceControl<HarborClear>(
        label: 'clear',
        values: HarborClear.values,
        value: _clear,
        labelOf: (final HarborClear c) => c.name,
        onChanged: (final HarborClear c) => setState(() => _clear = c),
      ),
      ToggleControl(label: 'tide', value: _tide, onChanged: (final bool v) => setState(() => _tide = v)),
      ToggleControl(label: 'mooringLine', value: _mooringLine, onChanged: (final bool v) => setState(() => _mooringLine = v)),
      SliderControl(label: 'minimum', value: _minimum, min: 0, max: 48, onChanged: (final double v) => setState(() => _minimum = v)),
    ],
    code:
        'Harbor(\n'
        '  bodyClearsTide: false,\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  bottom: [HarborDock.quay(child: Bar())],\n'
        '  body: HarborMoored(\n'
        '    edges: ${_edges.code},\n'
        '    clear: HarborClear.${_clear.name},\n'
        '    tide: $_tide,\n'
        '    mooringLine: $_mooringLine,\n'
        '    minimum: EdgeInsetsDirectional.all(${_n(_minimum)}),\n'
        '    child: Form(),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      bodyClearsTide: false,
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[_quayBar()],
      body: StageProbe(
        label: 'Harbor body (around HarborMoored)',
        child: HarborMoored(
          edges: _edges.edges,
          clear: _clear,
          tide: _tide,
          mooringLine: _mooringLine,
          minimum: EdgeInsetsDirectional.all(_minimum),
          child: const StageProbe(
            label: 'inside HarborMoored (cast off)',
            child: _LandedBox(
              key: ValueKey<String>('moored box'),
              label: 'HarborMoored',
              detail: 'This box is where it lands.\nRaise the tide to see it\nkeep clear of the keyboard.',
            ),
          ),
        ),
      ),
    ),
  );
}

// 2. HarborMooringLine -------------------------------------------------------

/// `HarborMooringLine`: a row lined up on the page margin.
class MooringLineEntry extends StatefulWidget {
  const MooringLineEntry({super.key});

  @override
  State<MooringLineEntry> createState() => _MooringLineEntryState();
}

class _MooringLineEntryState extends State<MooringLineEntry> {
  bool _mooringLine = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborMooringLine',
    tryThis: const <TryStep>[
      TryStep(
        'Switch HarborMooringLine off',
        'The boat rows jump out to the screen\'s edges, past the brass lines; on, they sit on the lines while stripes run edge to edge.',
      ),
      TryStep(
        'Switch it on, open The stage, pick iPhone 17 landscape',
        'The rows move in by the side cutout plus the margin, on both sides; the striped backgrounds still run edge to edge.',
      ),
      TryStep(
        'Pick Device: dual screen cover',
        'Only the right side moves in, where this device has its inset: the line follows what is in the way on each side.',
      ),
      TryStep(
        'Switch on Right-to-left',
        'The boat moves to the right end of each row, but the wider gap stays on the physical right, where the inset is.',
      ),
    ],
    realWorld:
        'In a marina, boats lie side by side along a quay, each made fast to the same long mooring line. However long '
        'or short each boat is, they all line up on that one rope.',
    inYourApp:
        'A row that lines up with the page margin: the harbor\'s margin plus whatever is in the way at the sides (a '
        'cutout in landscape, a rail). The list itself still runs edge to edge. Try the landscape device and '
        'right-to-left.',
    art: const MooringLineArt(),
    controls: <Widget>[
      ToggleControl(label: 'HarborMooringLine', value: _mooringLine, onChanged: (final bool v) => setState(() => _mooringLine = v)),
    ],
    code: _mooringLine
        ? 'SliverList.builder(\n'
              '  itemBuilder: (context, i) => ColoredBox(\n'
              '    color: stripe,            // runs edge to edge\n'
              '    child: HarborMooringLine(child: BoatRow(i)),\n'
              '  ),\n'
              ')'
        : 'SliverList.builder(\n'
              '  itemBuilder: (context, i) => ColoredBox(\n'
              '    color: stripe,\n'
              '    child: BoatRow(i),        // touches the edge\n'
              '  ),\n'
              ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: StageProbe(
              label: 'Harbor body',
              child: HarborFairway(
                slivers: <Widget>[
                  SliverList.list(
                    children: <Widget>[
                      for (int i = 0; i < 14; i++) _MooringRow(index: i, mooringLine: _mooringLine),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // The mooring line itself, drawn where it falls on each side.
          Positioned.fill(
            child: IgnorePointer(
              child: HarborOpenWater(
                builder: (final BuildContext context, final HarborWatersData waters) {
                  final EdgeInsets coast = MediaQuery.paddingOf(context);
                  final EdgeInsets margin = waters.margin.resolve(Directionality.of(context));
                  return Stack(
                    children: <Widget>[
                      Positioned(left: coast.left + margin.left, top: 0, bottom: 0, width: 1.5, child: const _GuideLine()),
                      Positioned(right: coast.right + margin.right, top: 0, bottom: 0, width: 1.5, child: const _GuideLine()),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GuideLine extends StatelessWidget {
  const _GuideLine();

  @override
  Widget build(final BuildContext context) => ColoredBox(color: Palette.brass.withValues(alpha: 0.7));
}

class _MooringRow extends StatelessWidget {
  const _MooringRow({required this.index, required this.mooringLine});

  final int index;
  final bool mooringLine;

  @override
  Widget build(final BuildContext context) {
    final Boat boat = Fleet.boats[index % Fleet.boats.length];
    final Widget content = Container(
      key: ValueKey<String>('line $index'),
      height: 52,
      decoration: BoxDecoration(color: Palette.sea.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: <Widget>[
          SizedBox(width: 50, child: BoatArt(kind: boat.kind, hull: boat.hull, bob: false)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mooringLine ? 'HarborMooringLine · ${boat.name}' : boat.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return ColoredBox(
      key: ValueKey<String>('strip $index'),
      color: index.isEven ? Palette.deepSea : Palette.night,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: mooringLine ? HarborMooringLine(child: content) : content,
      ),
    );
  }
}

// 3. HarborFairway -----------------------------------------------------------

/// `HarborFairway`: a scroll view that runs under the docks and rests clear.
class FairwayEntry extends StatefulWidget {
  const FairwayEntry({super.key});

  @override
  State<FairwayEntry> createState() => _FairwayEntryState();
}

class _FairwayEntryState extends State<FairwayEntry> {
  static const int _rowCount = 16;
  static const int _cardCount = 8;

  Axis _axis = Axis.vertical;
  bool _openWater = false;
  double _padding = 0;
  double _revealMargin = 0;
  final GlobalKey _revealTarget = GlobalKey();

  bool get _vertical => _axis == Axis.vertical;
  int get _target => _vertical ? 12 : 4;

  void _reveal() {
    final BuildContext? target = _revealTarget.currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFairway',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the list on the phone',
        'Rows slide under the header and fade in its wake, but the first and last rows come to rest clear of header and quay bar.',
      ),
      TryStep(
        'Tap ensureVisible(row 13)',
        'Row 13 scrolls up to sit just above the quay bar, not under it: reveals land clear of the docks.',
      ),
      TryStep(
        'Set revealMargin to 48 and tap the button again',
        'Row 13 now stops 48 above the quay bar: room for whatever sits under a focused field.',
      ),
      TryStep(
        'Switch startsInOpenWater on, scroll to the top',
        'The first row starts at the very top of the screen, under the header, as a hero image would.',
      ),
      TryStep(
        'Pick scrollDirection: horizontal',
        'Cards scroll sideways and rest on the page margin at each end; the button now reveals card 5.',
      ),
    ],
    realWorld:
        'A fairway is the buoyed channel into a harbor: red and green lateral marks lead boats in from the open sea, '
        'past the breakwater, to their berths.',
    inYourApp:
        'A scroll view whose viewport runs the full frame, under the docks, while its first and last rows come to rest '
        'clear of them. Your padding is added to the clearance, and every reveal (ensureVisible, a focused field) '
        'lands clear of the docks too, plus revealMargin.',
    art: const FairwayArt(),
    controls: <Widget>[
      ChoiceControl<Axis>(
        label: 'scrollDirection',
        values: Axis.values,
        value: _axis,
        labelOf: (final Axis a) => a.name,
        onChanged: (final Axis a) => setState(() => _axis = a),
      ),
      ToggleControl(label: 'startsInOpenWater', value: _openWater, onChanged: (final bool v) => setState(() => _openWater = v)),
      SliderControl(label: 'padding', value: _padding, min: 0, max: 32, onChanged: (final double v) => setState(() => _padding = v)),
      SliderControl(
        label: 'revealMargin',
        value: _revealMargin,
        min: 0,
        max: 48,
        onChanged: (final double v) => setState(() => _revealMargin = v),
      ),
      // In an app the reveal comes from a focused field or a jump-to; here a button in the controls
      // stands in for it, so the rows and the quay they land on stay in view while you press it.
      _ActionControl(
        key: const ValueKey<String>('reveal button'),
        label: 'ensureVisible(${_vertical ? 'row' : 'card'} ${_target + 1})',
        onPressed: _reveal,
      ),
    ],
    code:
        'Harbor(\n'
        '  top: [HarborDock.pier(wake: HarborWake.fade(length: 12), child: Header())],\n'
        '  bottom: [HarborDock.quay(child: Bar())],\n'
        '  body: HarborFairway(\n'
        '    scrollDirection: Axis.${_axis.name},\n'
        '${_openWater ? '    startsInOpenWater: true,\n' : ''}'
        '    padding: EdgeInsetsDirectional.all(${_n(_padding)}),\n'
        '    revealMargin: ${_n(_revealMargin)},\n'
        '    slivers: [SliverList.list(children: rows)],\n'
        '  ),\n'
        ')\n'
        '// The reveal:\n'
        'Scrollable.ensureVisible(row$_target.currentContext!,\n'
        '    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader(wake: const HarborWake.fade(length: 12))],
      bottom: <HarborDock>[_quayBar()],
      body: StageProbe(
        label: 'Harbor body (the fairway runs under the pier)',
        child: HarborFairway(
          key: ValueKey<String>('fairway ${_axis.name}'),
          scrollDirection: _axis,
          startsInOpenWater: _openWater,
          padding: EdgeInsetsDirectional.all(_padding),
          revealMargin: _revealMargin,
          slivers: <Widget>[
            if (_vertical)
              SliverList.list(
                children: <Widget>[
                  for (int i = 0; i < _rowCount; i++)
                    KeyedSubtree(key: i == _target ? _revealTarget : null, child: StageRow(index: i)),
                ],
              )
            else
              // All the cards are built, so the reveal can find the one it
              // wants even while it's off past the end.
              SliverToBoxAdapter(
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < _cardCount; i++) _FairwayCard(key: i == _target ? _revealTarget : null, index: i),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A button in the controls, for an option that is an action rather than a setting.
class _ActionControl extends StatelessWidget {
  const _ActionControl({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.brass,
          side: const BorderSide(color: Palette.brass),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontFamily: 'Menlo', fontSize: 12)),
      ),
    ),
  );
}

class _FairwayCard extends StatelessWidget {
  const _FairwayCard({super.key, required this.index});

  final int index;

  @override
  Widget build(final BuildContext context) {
    final Boat boat = Fleet.boats[index % Fleet.boats.length];
    return Center(
      child: Container(
        key: ValueKey<String>('stage card $index'),
        width: 150,
        height: 190,
        margin: const EdgeInsetsDirectional.only(end: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Palette.sea, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: <Widget>[
            Expanded(child: BoatArt(kind: boat.kind, hull: boat.hull, bob: false)),
            Text('${index + 1}. ${boat.name}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// 4. HarborFairwaySliver -----------------------------------------------------

/// `HarborFairwaySliver`: one leg of a channel in your own scroll view.
class FairwaySliverEntry extends StatefulWidget {
  const FairwaySliverEntry({super.key});

  @override
  State<FairwaySliverEntry> createState() => _FairwaySliverEntryState();
}

class _FairwaySliverEntryState extends State<FairwaySliverEntry> {
  bool _first = true;
  bool _last = true;

  Widget _wrap(final bool on, final Widget sliver, {required final bool leading}) =>
      on ? HarborFairwaySliver(clearLeading: leading, clearTrailing: !leading, sliver: sliver) : sliver;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFairwaySliver',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the list to the top, then the bottom',
        'Row 1 rests below the header and row 18 above the bottom bar: the two wrapped slivers keep clear of their ends.',
      ),
      TryStep(
        'Switch first sliver off, scroll to the top',
        'Row 1 now starts at the top of the screen, under the header: nothing at that end keeps clear any more.',
      ),
      TryStep(
        'Switch last sliver off, scroll to the bottom',
        'Row 18 ends at the screen\'s bottom edge, behind the bottom bar: an unwrapped sliver ignores the docks.',
      ),
    ],
    realWorld:
        'A single channel marker: one buoy on its chain, numbered, marking one leg of the channel. A whole fairway is '
        'a row of them; sometimes you only need the first and the last.',
    inYourApp:
        'For a CustomScrollView you build yourself: wrap the sliver at each end, and it keeps clear of the docks at '
        'that end (and widens reveals that pass through it). Everything in between is yours.',
    art: const FairwaySliverArt(),
    controls: <Widget>[
      ToggleControl(label: 'first sliver', value: _first, onChanged: (final bool v) => setState(() => _first = v)),
      ToggleControl(label: 'last sliver', value: _last, onChanged: (final bool v) => setState(() => _last = v)),
    ],
    code:
        'CustomScrollView(\n'
        '  slivers: [\n'
        '${_first ? '    HarborFairwaySliver(clearTrailing: false, sliver: firstRows),\n' : '    firstRows,\n'}'
        '    middleRows,\n'
        '${_last ? '    HarborFairwaySliver(clearLeading: false, sliver: lastRows),\n' : '    lastRows,\n'}'
        '  ],\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[_bottomPier()],
      body: StageProbe(
        label: 'Harbor body (your CustomScrollView)',
        child: CustomScrollView(
          key: const ValueKey<String>('custom scroll view'),
          slivers: <Widget>[
            _wrap(_first, SliverList.list(children: _rows(0, 3)), leading: true),
            SliverList.list(children: _rows(3, 12)),
            _wrap(_last, SliverList.list(children: _rows(15, 3)), leading: false),
          ],
        ),
      ),
    ),
  );
}

// 5. HarborSliverDock --------------------------------------------------------

/// `HarborSliverDock`: a header inside the scroll that pins and stacks.
class SliverDockEntry extends StatefulWidget {
  const SliverDockEntry({super.key});

  @override
  State<SliverDockEntry> createState() => _SliverDockEntryState();
}

class _SliverDockEntryState extends State<SliverDockEntry> {
  bool _second = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSliverDock',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the list up on the phone',
        'The Cargo strip scrolls with the rows, then pins under the header: it has become a dock for everything after it.',
      ),
      TryStep('Keep scrolling', 'The Crew strip pins beneath Cargo, and the rows pass under both.'),
      TryStep('Switch second HarborSliverDock off', 'Crew is gone: only Cargo pins under the header.'),
      TryStep('Scroll back to the top', 'Cargo lets go and scrolls back into place between the rows.'),
    ],
    realWorld:
        'A landing stage floats on the water at the foot of a gangway. The gangway is pinned to the quay at the top, so '
        'however far you come down it, the top stays where it is, and the stage rises to meet you.',
    inYourApp:
        'A header or tab strip inside a fairway. It scrolls with the rows, then pins at the face of the docks above it '
        'and becomes a dock for everything after it. A second one pins beneath the first.',
    art: const SliverDockArt(),
    controls: <Widget>[
      ToggleControl(label: 'second HarborSliverDock', value: _second, onChanged: (final bool v) => setState(() => _second = v)),
    ],
    code:
        'HarborFairway(\n'
        '  slivers: [\n'
        '    intro,\n'
        '    HarborSliverDock(backdrop: ColoredBox(color: plank), child: Text(\'Cargo\')),\n'
        '    cargoRows,\n'
        '${_second ? '    HarborSliverDock(backdrop: ColoredBox(color: stone), child: Text(\'Crew\')),\n' : ''}'
        '    crewRows,\n'
        '  ],\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      body: StageProbe(
        label: 'Harbor body',
        child: HarborFairway(
          key: const ValueKey<String>('sliver dock fairway'),
          slivers: <Widget>[
            SliverList.list(children: _rows(0, 3)),
            HarborSliverDock(
              backdrop: ColoredBox(color: Palette.plankDark.withValues(alpha: 0.95)),
              child: const _Strip(key: ValueKey<String>('sliver dock 1'), label: 'HarborSliverDock · Cargo'),
            ),
            SliverList.list(children: _rows(3, 6)),
            if (_second)
              HarborSliverDock(
                backdrop: ColoredBox(color: Palette.stoneDark.withValues(alpha: 0.95)),
                child: const _Strip(key: ValueKey<String>('sliver dock 2'), label: 'HarborSliverDock · Crew', color: Palette.foam),
              ),
            SliverList.list(children: _rows(9, 24)),
          ],
        ),
      ),
    ),
  );
}

// 6. HarborSticky ------------------------------------------------------------

/// `HarborSticky`: a pill that rides with its item, then sticks.
class StickyEntry extends StatefulWidget {
  const StickyEntry({super.key});

  @override
  State<StickyEntry> createState() => _StickyEntryState();
}

class _StickyEntryState extends State<StickyEntry> {
  double _gap = 8;
  bool _pinned = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSticky',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the list up on the phone',
        'The red Tuesday pill rides up with its card, then sticks just below the HarborSliverDock strip while the card is under it.',
      ),
      TryStep(
        'Keep scrolling until the card leaves',
        'The pill stays inside its card and leaves with it: it never floats free of its item.',
      ),
      TryStep(
        'Drag gap to 24 while the pill is stuck',
        'The pill moves down at once to sit 24 below the strip; at 0 it touches it.',
      ),
      TryStep(
        'Switch pinned HarborSliverDock off',
        'With no strip pinned, the pill sticks just below the header instead: it clears whatever is pinned above.',
      ),
    ],
    focus: const StageFocus.top(500),
    realWorld:
        'A barnacle cements itself to a hull and goes wherever the boat goes. It never leaves the hull: when the boat '
        'sails off, so does the barnacle.',
    inYourApp:
        'A pill (a date, a count, a label) that rides with its item as it scrolls, then sticks just below the docks and '
        'any pinned sliver docks while the item is still under them, and leaves with the item. Scroll the tall card '
        'up under the header.',
    art: const StickyArt(),
    controls: <Widget>[
      SliderControl(label: 'gap', value: _gap, min: 0, max: 24, onChanged: (final double v) => setState(() => _gap = v)),
      ToggleControl(label: 'pinned HarborSliverDock', value: _pinned, onChanged: (final bool v) => setState(() => _pinned = v)),
    ],
    code:
        'Container(\n'
        '  height: 560,\n'
        '  child: Column(\n'
        '    children: [\n'
        '      HarborSticky(gap: ${_n(_gap)}, child: Pill(\'Tuesday\')),\n'
        '      Expanded(child: Log()),\n'
        '    ],\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      body: HarborFairway(
        key: const ValueKey<String>('sticky fairway'),
        slivers: <Widget>[
          SliverList.list(children: _rows(0, 2)),
          if (_pinned)
            HarborSliverDock(
              backdrop: ColoredBox(color: Palette.plankDark.withValues(alpha: 0.95)),
              child: const _Strip(key: ValueKey<String>('sticky sliver dock'), label: 'HarborSliverDock'),
            ),
          SliverToBoxAdapter(
            child: HarborMooringLine(
              child: Container(
                key: const ValueKey<String>('tall item'),
                height: 560,
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Palette.sea,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.brass.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HarborSticky(
                      gap: _gap,
                      child: Container(
                        key: const ValueKey<String>('sticky pill'),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Palette.buoyRed, borderRadius: BorderRadius.circular(20)),
                        child: const Text(
                          'HarborSticky · Tuesday',
                          style: TextStyle(fontFamily: 'Menlo', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < 7; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${8 + i}:00  ${Fleet.boats[i].name} came in',
                          style: TextStyle(color: Palette.foam.withValues(alpha: 0.85)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverList.list(children: _rows(2, 20)),
        ],
      ),
    ),
  );
}

// 7. HarborCenter ------------------------------------------------------------

/// `HarborCenter`: controls centered in the frame, within an overlap budget.
class CenterEntry extends StatefulWidget {
  const CenterEntry({super.key});

  @override
  State<CenterEntry> createState() => _CenterEntryState();
}

class _CenterEntryState extends State<CenterEntry> {
  double _budget = 24;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborCenter',
    tryThis: const <TryStep>[
      TryStep(
        'Compare the box with the brass line',
        'The player box is centered on the whole screen (the brass line), not on the water between header and bottom bar.',
      ),
      TryStep(
        'Tap the keyboard button',
        'The box moves up only far enough to overlap the keyboard by 24, the overlapBudget, rather than recentering.',
      ),
      TryStep('Drag overlapBudget to 0', 'The box rises to sit fully above the keyboard.'),
      TryStep(
        'Drag overlapBudget to 160',
        'The box stays centered on the screen and lets the keyboard cover its bottom: within budget, it does not move.',
      ),
    ],
    realWorld:
        'A compass rose sits at the heart of a chart, and a ship keeps to the middle of the channel: centered on the '
        'whole thing, not on whatever bit of it is left.',
    inYourApp:
        'Controls centered in the harbor\'s frame (the middle of the screen, not the middle of the leftover water), '
        'nudged just far enough that they overlap the docks and the keyboard by no more than overlapBudget. Drag the '
        'tide high.',
    art: const CenterArt(),
    controls: <Widget>[
      SliderControl(label: 'overlapBudget', value: _budget, min: 0, max: 160, onChanged: (final double v) => setState(() => _budget = v)),
    ],
    code:
        'Harbor(\n'
        '  bodyClearsTide: false,\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  bottom: [HarborDock.pier(child: Bar())],\n'
        '  body: HarborCenter(\n'
        '    overlapBudget: ${_n(_budget)},\n'
        '    child: PlayerControls(),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      bodyClearsTide: false,
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[_bottomPier()],
      body: Stack(
        children: <Widget>[
          // The frame's middle, for reference.
          Positioned.fill(
            child: Center(
              child: Container(key: const ValueKey<String>('frame middle'), height: 1.5, color: Palette.brass.withValues(alpha: 0.6)),
            ),
          ),
          Positioned.fill(
            child: StageProbe(
              label: 'Harbor body',
              child: HarborCenter(
                overlapBudget: _budget,
                child: Container(
                  key: const ValueKey<String>('centered controls'),
                  width: 260,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Palette.night.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Palette.brass, width: 2),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('HarborCenter', style: TextStyle(fontFamily: 'Menlo', fontWeight: FontWeight.w700, fontSize: 16)),
                      SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.skip_previous_rounded, size: 40, color: Palette.foam),
                          SizedBox(width: 12),
                          Icon(Icons.play_circle_fill_rounded, size: 72, color: Palette.brass),
                          SizedBox(width: 12),
                          Icon(Icons.skip_next_rounded, size: 40, color: Palette.foam),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// 8. HarborOpenWater + HarborWaters ------------------------------------------

/// `HarborOpenWater`: content that ignores the docks but is told where they are.
class OpenWaterEntry extends StatefulWidget {
  const OpenWaterEntry({super.key});

  @override
  State<OpenWaterEntry> createState() => _OpenWaterEntryState();
}

class _OpenWaterEntryState extends State<OpenWaterEntry> {
  HarborDockKind _bottom = HarborDockKind.pier;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborOpenWater',
    tryThis: const <TryStep>[
      TryStep(
        'Read the shaded bands',
        'The chart runs under everything; red bands show the coast (62 top, 34 bottom) and brass ones the docks (114, 90).',
      ),
      TryStep(
        'Pick bottom dock: quay',
        'The chart stops at the bar and both bottom bands read 0: a quay takes its ground from the body.',
      ),
      TryStep(
        'Pick bottom dock: pier, then tap the keyboard button',
        'The chart ends at the keyboard and the bottom bands go: the body clears the tide, so nothing below reaches it.',
      ),
      TryStep(
        'Lower the keyboard, pick Device: iPhone 17 landscape',
        'frameSize reads 874 × 402, the top coast band goes and the bottom one reads 21: the bands follow the device.',
      ),
    ],
    realWorld:
        'A chart covers the whole sea, but marks how deep it is everywhere: soundings in the open water, contour lines, '
        'shading where it shoals. You can sail anywhere; the chart tells you what is there.',
    inYourApp:
        'A background, a map or a hero that runs full bleed and ignores the docks, while its builder is told how far '
        'each one reaches (HarborWaters: waters.coast, waters.docks, waters.wakes, waters.frameSize) so it can place '
        'what it draws. Here it shades a band for each.',
    art: const OpenWaterArt(),
    controls: <Widget>[
      ChoiceControl<HarborDockKind>(
        label: 'bottom dock',
        values: HarborDockKind.values,
        value: _bottom,
        labelOf: (final HarborDockKind k) => k.name,
        onChanged: (final HarborDockKind k) => setState(() => _bottom = k),
      ),
    ],
    code:
        'Harbor(\n'
        '  top: [HarborDock.pier(child: Header())],\n'
        '  bottom: [HarborDock.${_bottom.name}(child: Bar())],\n'
        '  body: HarborOpenWater(\n'
        '    builder: (context, waters) => Stack(children: [\n'
        '      Chart(),\n'
        '      Band(top: 0, height: waters.docks.top),\n'
        '      Band(top: 0, height: waters.coast.top),\n'
        '      Band(bottom: 0, height: waters.docks.bottom),\n'
        '      Band(bottom: 0, height: waters.coast.bottom),\n'
        '    ]),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[if (_bottom == HarborDockKind.pier) _bottomPier() else _quayBar()],
      body: StageProbe(
        label: 'Harbor body (open water)',
        child: HarborOpenWater(
          builder: (final BuildContext context, final HarborWatersData waters) => Stack(
            key: const ValueKey<String>('open water'),
            children: <Widget>[
              const Positioned.fill(child: CustomPaint(painter: _ChartBackdropPainter())),
              ..._bands(waters, top: true),
              ..._bands(waters, top: false),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Palette.night.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'HarborOpenWater\nframeSize ${_n(waters.frameSize.width)} × ${_n(waters.frameSize.height)}\n'
                    'wakes ${waters.wakes.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, color: Palette.foam),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _bands(final HarborWatersData waters, {required final bool top}) {
    final double docks = top ? waters.docks.top : waters.docks.bottom;
    final double coast = top ? waters.coast.top : waters.coast.bottom;
    final String edge = top ? 'top' : 'bottom';
    Widget band(final String name, final double height, final Color color, final Alignment align) => Positioned(
      key: ValueKey<String>('$name band $edge'),
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.32),
          border: Border(
            top: top ? BorderSide.none : BorderSide(color: color, width: 2),
            bottom: top ? BorderSide(color: color, width: 2) : BorderSide.none,
          ),
        ),
        child: height < 14
            ? null
            : Text(
                'waters.$name.$edge ${_n(height)}',
                style: TextStyle(fontFamily: 'Menlo', fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
      ),
    );
    return <Widget>[
      band('docks', docks, Palette.brass, top ? Alignment.bottomRight : Alignment.topRight),
      band('coast', coast, Palette.buoyRed, top ? Alignment.bottomLeft : Alignment.topLeft),
    ];
  }
}

/// The open water's background: a chart with soundings.
class _ChartBackdropPainter extends CustomPainter {
  const _ChartBackdropPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1B4F72));
    final Paint contour = Paint()
      ..color = Palette.foam.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (double r = 80; r < size.longestSide; r += 70) {
      canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.9), r, contour);
    }
    for (int i = 0; i < 40; i++) {
      final double x = (i * 97 % 360) / 360 * size.width;
      final double y = (i * 211 % 800) / 800 * size.height;
      final TextPainter sounding = TextPainter(
        text: TextSpan(
          text: '${3 + i % 17}',
          style: TextStyle(color: Palette.foam.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      sounding.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(final _ChartBackdropPainter oldDelegate) => false;
}

// 9. HarborCastOff -----------------------------------------------------------

enum _CastEdges {
  all('all', 'HarborEdge.all'),
  vertical('vertical', 'HarborEdge.vertical');

  const _CastEdges(this.label, this.code);

  final String label;
  final String code;

  Set<HarborEdge> get edges => this == all ? HarborEdge.all : HarborEdge.vertical;
}

/// `HarborCastOff`: casts off the edges a hand-padded layer already cleared.
class CastOffEntry extends StatefulWidget {
  const CastOffEntry({super.key});

  @override
  State<CastOffEntry> createState() => _CastOffEntryState();
}

class _CastOffEntryState extends State<CastOffEntry> {
  bool _castOff = true;
  _CastEdges _edges = _CastEdges.all;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborCastOff',
    tryThis: const <TryStep>[
      TryStep(
        'Switch HarborCastOff off',
        'The brass SafeArea box shrinks inside the red one by the header and bottom bar again: the gap is cleared twice.',
      ),
      TryStep(
        'Switch it back on',
        'The boxes match: HarborCastOff told the SafeArea those edges were already cleared.',
      ),
      TryStep(
        'Open The stage, pick Device: iPhone 17 landscape',
        'The red box clears the side cutouts too, and the SafeArea still adds nothing.',
      ),
      TryStep(
        'Pick edges: vertical',
        'Only top and bottom are cast off now: the SafeArea pads the side cutouts a second time.',
      ),
    ],
    realWorld:
        'Casting off is lifting a line\'s eye off its bollard so the boat is free. Once it is off, nobody ashore is '
        'holding that line any more.',
    inYourApp:
        'For a layer you pad by hand from MediaQuery. HarborCastOff tells everything beneath it that those edges are '
        'cleared, so MediaQuery and HarborWaters read 0 there. Turn it off and the SafeArea inside clears them a second '
        'time: the doubled gap.',
    art: const CastOffArt(),
    controls: <Widget>[
      ToggleControl(label: 'HarborCastOff', value: _castOff, onChanged: (final bool v) => setState(() => _castOff = v)),
      ChoiceControl<_CastEdges>(
        label: 'edges',
        values: _CastEdges.values,
        value: _edges,
        labelOf: (final _CastEdges e) => e.label,
        onChanged: (final _CastEdges e) => setState(() => _edges = e),
      ),
    ],
    code: _castOff
        ? 'Padding(\n'
              '  padding: MediaQuery.paddingOf(context),\n'
              '  child: HarborCastOff(\n'
              '    edges: ${_edges.code},\n'
              '    child: SafeArea(child: Content()), // adds 0\n'
              '  ),\n'
              ')'
        : 'Padding(\n'
              '  padding: MediaQuery.paddingOf(context),\n'
              '  child: SafeArea(child: Content()), // pads again\n'
              ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[_bottomPier()],
      body: Builder(
        builder: (final BuildContext context) {
          final Widget inner = StageProbe(
            label: _castOff ? 'under HarborCastOff' : 'under the hand padding (no cast off)',
            child: SafeArea(
              child: _LandedBox(
                key: const ValueKey<String>('inner safe area'),
                label: 'SafeArea inside',
                color: Palette.brass,
                detail: _castOff ? 'clears nothing again' : 'clears the docks a second time',
              ),
            ),
          );
          return Padding(
            padding: MediaQuery.paddingOf(context),
            child: DecoratedBox(
              key: const ValueKey<String>('hand padded box'),
              decoration: BoxDecoration(border: Border.all(color: Palette.buoyRed, width: 2)),
              child: _castOff ? HarborCastOff(edges: _edges.edges, child: inner) : inner,
            ),
          );
        },
      ),
    ),
  );
}

// 10. HarborMakeWay ----------------------------------------------------------

/// `HarborMakeWay`: content asking a dock to go dark or withdraw.
class MakeWayEntry extends StatefulWidget {
  const MakeWayEntry({super.key});

  @override
  State<MakeWayEntry> createState() => _MakeWayEntryState();
}

class _MakeWayEntryState extends State<MakeWayEntry> {
  HarborYield _mode = HarborYield.withdraw;
  bool _top = false;
  bool _bottom = false;

  String _claim(final HarborEdge edge) => 'HarborMakeWay(edge: HarborEdge.${edge.name}, mode: HarborYield.${_mode.name}, child: ...)';

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborMakeWay',
    tryThis: const <TryStep>[
      TryStep('Switch on make way: bottom', 'The tab bar slides away and the list runs to the bottom of the screen: withdraw gives its ground back.'),
      TryStep('Pick mode: dark, with make way: bottom still on', 'The tab bar vanishes but keeps its ground: the list still ends where the tab bar was, and nothing moves.'),
      TryStep('Switch on make way: top', 'The header goes the same way, and in withdraw mode the rows rise toward the status bar.'),
      TryStep('Switch both off', 'Both docks come back; the claims were released.'),
    ],
    realWorld:
        'In a narrow channel a small sailboat gives way to a big ship that can only steer in the channel: it bears away '
        'to the edge, or heaves to, and comes back once the ship has passed.',
    inYourApp:
        'Content asks the docks on an edge to make way while it is in the tree: go dark (not drawn, not tappable, ground '
        'kept so nothing moves) or withdraw (slide out and give the ground back). Claims are counted and released when '
        'the widget leaves.',
    art: const MakeWayArt(),
    controls: <Widget>[
      ChoiceControl<HarborYield>(
        label: 'mode',
        values: HarborYield.values,
        value: _mode,
        labelOf: (final HarborYield m) => m.name,
        onChanged: (final HarborYield m) => setState(() => _mode = m),
      ),
      // In an app the claim comes from content (a panel, a search field); here the switches stand in
      // for it, so the whole phone stays in view while you flip them.
      ToggleControl(label: 'make way: top', value: _top, onChanged: (final bool v) => setState(() => _top = v)),
      ToggleControl(label: 'make way: bottom', value: _bottom, onChanged: (final bool v) => setState(() => _bottom = v)),
    ],
    code:
        '// Declarative: while it is in the tree.\n'
        '${_top ? _claim(HarborEdge.top) : '// (top: no claim)'}\n'
        '${_bottom ? _claim(HarborEdge.bottom) : '// (bottom: no claim)'}\n'
        '\n'
        '// Imperative: hold the claim, release it later.\n'
        'final claim = HarborController.of(context)\n'
        '    .makeWay(HarborEdge.bottom, mode: HarborYield.${_mode.name});\n'
        'claim.release();',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[_quayBar(label: 'Tab bar (HarborDock.quay)')],
      body: HarborMakeWay(
        edge: HarborEdge.top,
        mode: _mode,
        active: _top,
        child: HarborMakeWay(
          edge: HarborEdge.bottom,
          mode: _mode,
          active: _bottom,
          child: StageProbe(
            label: 'Harbor body',
            child: HarborFairway(
              key: const ValueKey<String>('make way fairway'),
              slivers: <Widget>[
                SliverList.list(children: _rows(0, 16)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// 11. HarborPontoon ----------------------------------------------------------

/// `HarborPontoon`: a dock moored from deep in the tree.
class PontoonEntry extends StatefulWidget {
  const PontoonEntry({super.key});

  @override
  State<PontoonEntry> createState() => _PontoonEntryState();
}

class _PontoonEntryState extends State<PontoonEntry> {
  HarborDockKind _kind = HarborDockKind.pier;
  bool _dirty = false;

  void _setDirty(final bool dirty) => setState(() => _dirty = dirty);

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborPontoon',
    tryThis: const <TryStep>[
      TryStep(
        'Tap Edit on the Cargo manifest card',
        'An Unsaved changes bar moors above the tab bar: a dock added from deep inside the list, not by the page.',
      ),
      TryStep(
        'Scroll the list to the bottom',
        'The last row rests just above the unsaved bar: the pontoon is measured like any dock, and as a pier the list runs under it.',
      ),
      TryStep(
        'Tap Save on the bar',
        'The bar leaves and the dirty switch turns off: the form\'s own flag drives the pontoon.',
      ),
      TryStep(
        'Pick dock: quay, then switch dirty on',
        'The list now ends above the bar instead of running under it: a quay takes its ground from the body.',
      ),
    ],
    // The whole phone: the form that moors the pontoon sits near the top, the pontoon lands at the
    // bottom, above the tab bar.
    realWorld:
        'A pontoon is a floating deck on cylindrical floats, tied to the quay and held by guide piles. It is put in '
        'where a berth is needed, and towed away when it is not.',
    inYourApp:
        'A bar that belongs to the content, not the page (an unsaved-changes bar, a hint), moored to the nearest harbor '
        'from deep in the tree. It joins the docks on its edge, innermost, measured like any other: here, above the '
        'tab bar. Tap Edit in the manifest, or flip dirty.',
    art: const PontoonArt(),
    controls: <Widget>[
      ChoiceControl<HarborDockKind>(
        label: 'dock',
        values: HarborDockKind.values,
        value: _kind,
        labelOf: (final HarborDockKind k) => k.name,
        onChanged: (final HarborDockKind k) => setState(() => _kind = k),
      ),
      // The form's Edit and Save drive the same flag; the switch is here so it can be flipped while
      // you watch the bottom of the phone.
      ToggleControl(label: 'dirty', value: _dirty, onChanged: _setDirty),
    ],
    code:
        '// Deep in the body, in the form:\n'
        'HarborPontoon(\n'
        '  edge: HarborEdge.bottom,\n'
        '  active: dirty,\n'
        '  dock: HarborDock.${_kind.name}(child: UnsavedBar(onSave: save)),\n'
        '  child: ManifestForm(),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_pierHeader()],
      bottom: <HarborDock>[_quayBar(label: 'Tab bar (HarborDock.quay)')],
      body: StageProbe(
        label: 'Harbor body',
        child: HarborFairway(
          key: const ValueKey<String>('pontoon fairway'),
          slivers: <Widget>[
            SliverList.list(children: _rows(0, 2)),
            // Several layers down, as a real form would be.
            SliverToBoxAdapter(
              child: HarborMooringLine(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _ManifestForm(kind: _kind, dirty: _dirty, onDirty: _setDirty),
                ),
              ),
            ),
            SliverList.list(children: _rows(2, 14)),
          ],
        ),
      ),
    ),
  );
}

/// A form deep in the body that moors a pontoon while it has unsaved changes.
///
/// The flag is the entry's, so the `dirty` switch in the controls drives it too.
class _ManifestForm extends StatelessWidget {
  const _ManifestForm({required this.kind, required this.dirty, required this.onDirty});

  final HarborDockKind kind;
  final bool dirty;
  final ValueChanged<bool> onDirty;

  @override
  Widget build(final BuildContext context) {
    final Widget bar = ColoredBox(
      color: Palette.buoyRed,
      child: _Strip(
        key: const ValueKey<String>('unsaved bar'),
        label: 'HarborPontoon · Unsaved changes',
        color: Colors.white,
        height: 52,
        trailing: TextButton(
          key: const ValueKey<String>('save button'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () => onDirty(false),
          child: const Text('Save'),
        ),
      ),
    );
    return HarborPontoon(
      edge: HarborEdge.bottom,
      active: dirty,
      dock: kind == HarborDockKind.pier
          ? HarborDock.pier(debugLabel: 'pontoon', child: bar)
          : HarborDock.quay(debugLabel: 'pontoon', child: bar),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.sea,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.brass.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.inventory_2_rounded, color: Palette.brass),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dirty ? 'Cargo manifest (edited)' : 'Cargo manifest',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.foam),
              ),
            ),
            FilledButton(
              key: const ValueKey<String>('deep edit button'),
              style: FilledButton.styleFrom(backgroundColor: Palette.brass, foregroundColor: Palette.night),
              onPressed: () => onDirty(!dirty),
              child: Text(dirty ? 'Undo' : 'Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
