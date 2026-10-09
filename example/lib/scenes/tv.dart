import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/docks.dart';
import '../art/palette.dart';
import '../art/sea.dart';
import '../game/fleet.dart';
import '../game/settings.dart';
import '../game/widgets.dart';

/// The rail's width at rest, title-safe coast included.
const double _railResting = 96;

/// The rail's width while it has focus, title-safe coast included.
const double _railOpen = 240;

/// How far a focused card keeps in from whatever covers the edge of its row.
const double _revealMargin = 24;

/// The pages the lighthouse rail sails between.
enum TvPage {
  fleetWall('Fleet wall', Icons.view_module_rounded),
  openSea('Open sea', Icons.waves_rounded),
  longVoyage('Long voyage', Icons.nights_stay_rounded);

  const TvPage(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Lighthouse TV: Harbor Town on a television. It lives in a 1200×675 scale
/// model with a title-safe coast, which the rail (a start pier with a resting
/// extent) absorbs. The rail opens to show its labels while it has focus;
/// the fleet wall follows it live, the open sea lets it open over the voyage
/// card, and a long voyage asks it to go dark.
class TvHarborTown extends StatefulWidget {
  const TvHarborTown({super.key});

  @override
  State<TvHarborTown> createState() => _TvHarborTownState();
}

class _TvHarborTownState extends State<TvHarborTown> {
  TvPage _page = TvPage.fleetWall;
  bool _railFocused = false;
  bool _voyage = false;

  @override
  Widget build(final BuildContext context) {
    final double coastStart = HarborEdges.directional(MediaQuery.paddingOf(context), Directionality.of(context)).start;
    return HarborPage(
      child: ColoredBox(
        color: Palette.deepSea,
        child: Harbor(
          newPort: true,
          debugLabel: 'lighthouse tv',
          start: <HarborDock>[
            HarborDock.pier(
              debugLabel: 'rail',
              restingExtent: _railResting,
              backdrop: const PierPlanks(postsToward: AxisDirection.right),
              child: ExcludeFocus(
                excluding: _voyage,
                child: _Rail(
                  width: ((_railFocused ? _railOpen : _railResting) - coastStart).clamp(0.0, double.infinity),
                  open: _railFocused,
                  current: _page,
                  onFocusChange: (final bool focused) => setState(() => _railFocused = focused),
                  onSelect: (final TvPage page) => setState(() => _page = page),
                  onBackToPhone: () => HarborSettings.of(context).tv = false,
                ),
              ),
            ),
          ],
          body: switch (_page) {
            TvPage.fleetWall => const _FleetWall(),
            TvPage.openSea => const _OpenSea(),
            TvPage.longVoyage => _LongVoyage(underway: _voyage, onToggle: () => setState(() => _voyage = !_voyage)),
          },
        ),
      ),
    );
  }
}

// ─── The rail ─────────────────────────────────────────────────────────────────

class _Rail extends StatelessWidget {
  const _Rail({
    required this.width,
    required this.open,
    required this.current,
    required this.onFocusChange,
    required this.onSelect,
    required this.onBackToPhone,
  });

  /// The rail's own width, inside the coast its dock absorbs.
  final double width;
  final bool open;
  final TvPage current;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<TvPage> onSelect;
  final VoidCallback onBackToPhone;

  @override
  Widget build(final BuildContext context) {
    // The dock absorbs the start coast; the title-safe band across it (top and
    // bottom) is left for the rail to keep clear of.
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        key: const ValueKey<String>('rail'),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        padding: EdgeInsets.only(top: padding.top + 8, bottom: padding.bottom + 8),
        child: ClipRect(
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 40,
                child: Center(child: SizedBox(width: 24, child: LighthouseArt())),
              ),
              const SizedBox(height: 16),
              for (final TvPage page in TvPage.values)
                _RailItem(
                  key: ValueKey<String>('rail ${page.name}'),
                  icon: page.icon,
                  label: page.label,
                  selected: page == current,
                  open: open,
                  onPressed: () => onSelect(page),
                ),
              const Spacer(),
              _RailItem(
                key: const ValueKey<String>('rail phone'),
                icon: Icons.phone_iphone_rounded,
                label: 'Back to the phone',
                selected: false,
                open: open,
                onPressed: onBackToPhone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.open,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final Color color = selected ? Palette.brass : Palette.foam;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        focusColor: Palette.brass.withValues(alpha: 0.35),
        child: SizedBox(
          height: 44,
          child: Row(
            children: <Widget>[
              SizedBox(width: 36, child: Icon(icon, color: color)),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: open ? 1 : 0,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fleet wall ───────────────────────────────────────────────────────────────

class _FleetWall extends StatelessWidget {
  const _FleetWall();

  static final List<(String, List<Boat>)> _rows = <(String, List<Boat>)>[
    (
      'Sailing tonight',
      Fleet.boats.where((final Boat b) => b.kind == BoatKind.sailboat || b.kind == BoatKind.yacht).toList(),
    ),
    (
      'Working boats',
      Fleet.boats.where((final Boat b) => b.kind == BoatKind.tug || b.kind == BoatKind.trawler).toList(),
    ),
    (
      'Ferries and rowboats',
      Fleet.boats.where((final Boat b) => b.kind == BoatKind.ferry || b.kind == BoatKind.rowboat).toList(),
    ),
  ];

  @override
  Widget build(final BuildContext context) => HarborFairway(
    key: const ValueKey<String>('fleet wall'),
    revealMargin: _revealMargin,
    padding: const EdgeInsetsDirectional.only(bottom: 16),
    slivers: <Widget>[
      const SliverToBoxAdapter(
        // Follows the rail live: its start moves as the rail opens.
        child: HarborMoored(
          key: ValueKey<String>('fleet wall heading'),
          edges: <HarborEdge>{HarborEdge.start},
          mooringLine: true,
          extra: EdgeInsetsDirectional.only(end: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Fleet wall',
                style: TextStyle(color: Palette.foam, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              LogbookNote(
                pattern: 'Rail that opens on focus; D-pad reveal',
                tryThis:
                    'Move with the arrow keys. Step left onto the rail and it opens: this wall '
                    'follows it live. Along a row, focus brings each card clear of the rail with a '
                    '24 margin, thanks to the fairway\'s reveal.',
              ),
            ],
          ),
        ),
      ),
      for (int r = 0; r < _rows.length; r++) ...<Widget>[
        SliverToBoxAdapter(
          child: HarborMooringLine(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                _rows[r].$1,
                style: const TextStyle(color: Palette.brass, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 150,
            child: HarborFairway(
              key: ValueKey<String>('fleet row $r'),
              scrollDirection: Axis.horizontal,
              primary: false,
              revealMargin: _revealMargin,
              slivers: <Widget>[
                SliverList.separated(
                  itemCount: _rows[r].$2.length,
                  separatorBuilder: (final BuildContext context, final int i) => const SizedBox(width: 16),
                  itemBuilder: (final BuildContext context, final int i) => _BoatCard(
                    key: ValueKey<String>('boat ${_rows[r].$2[i].id}'),
                    boat: _rows[r].$2[i],
                    autofocus: r == 0 && i == 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _BoatCard extends StatefulWidget {
  const _BoatCard({super.key, required this.boat, this.autofocus = false});

  final Boat boat;
  final bool autofocus;

  @override
  State<_BoatCard> createState() => _BoatCardState();
}

class _BoatCardState extends State<_BoatCard> {
  bool _focused = false;

  // Focus traversal reveals the card through the fairways, which widen it by
  // their reveal margin and whatever covers their edges: no reveal of its own.
  void _onFocusChange(final bool focused) => setState(() => _focused = focused);

  @override
  Widget build(final BuildContext context) {
    final Boat boat = widget.boat;
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _focused ? 1.06 : 1.0,
      child: Material(
        color: Palette.night.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: _focused ? Palette.brass : Palette.foam.withValues(alpha: 0.15),
            width: _focused ? 3 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          autofocus: widget.autofocus,
          onFocusChange: _onFocusChange,
          onTap: () => HarborFlares.raise(
            context,
            slot: HarborFlareSlot.low,
            builder: (final BuildContext context) => SignalFlag(message: '${boat.name} hails the lighthouse'),
          ),
          child: SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: BoatArt(kind: boat.kind, hull: boat.hull, flag: boat.flag, bob: _focused),
                    ),
                  ),
                  Text(
                    boat.name,
                    style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${boat.captain} · ${boat.knots} kn',
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Open sea ─────────────────────────────────────────────────────────────────

class _OpenSea extends StatelessWidget {
  const _OpenSea();

  @override
  Widget build(final BuildContext context) => Stack(
    children: <Widget>[
      // Open water: the sea runs under the rail, to the screen's edge.
      const Positioned.fill(child: Sea(mood: SeaMood.night)),
      const PositionedDirectional(end: 80, bottom: 60, width: 120, child: LighthouseArt()),
      // At rest: the rail opens over the card rather than pushing it.
      HarborMoored(
        follow: HarborFollow.resting,
        mooringLine: true,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            key: const ValueKey<String>('voyage card'),
            width: 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.night.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Palette.brass.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Tonight\'s voyage',
                      style: TextStyle(color: Palette.foam, fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gullhaven → Foghorn Bay · 14 nautical miles',
                      style: TextStyle(color: Palette.foam.withValues(alpha: 0.75)),
                    ),
                    const LogbookNote(
                      pattern: 'Rail at rest: HarborFollow.resting',
                      tryThis:
                          'This card keeps clear of the rail as it rests. Step left onto the rail: it '
                          'opens over the card, and the card holds still.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── Long voyage ──────────────────────────────────────────────────────────────

class _LongVoyage extends StatelessWidget {
  const _LongVoyage({required this.underway, required this.onToggle});

  final bool underway;
  final VoidCallback onToggle;

  @override
  Widget build(final BuildContext context) => HarborMakeWay(
    edge: HarborEdge.start,
    mode: HarborYield.dark,
    active: underway,
    child: Stack(
      children: <Widget>[
        const Positioned.fill(child: Sea(mood: SeaMood.stormy)),
        HarborMoored(
          mooringLine: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                underway ? 'Underway: rail lights out' : 'A long voyage',
                style: const TextStyle(color: Palette.foam, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                width: 560,
                child: LogbookNote(
                  pattern: 'Make way: the rail goes dark',
                  tryThis:
                      'Set sail and this page asks the rail to make way with HarborYield.dark: it '
                      'goes dark and stops taking focus, but keeps its ground, so nothing here moves. '
                      'Make port to light it again.',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 260,
                child: BrassAction(
                  key: const ValueKey<String>('voyage toggle'),
                  label: underway ? 'Make port' : 'Set sail',
                  icon: underway ? Icons.anchor_rounded : Icons.sailing_rounded,
                  onPressed: onToggle,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
