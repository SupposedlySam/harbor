import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/docks.dart';
import '../art/fleet_art.dart';
import '../art/palette.dart';
import '../art/sea.dart';
import '../game/fleet.dart';
import '../game/widgets.dart';

// ---------------------------------------------------------------------------
// #9 Fleet registry
// ---------------------------------------------------------------------------

/// The Fleet tab: the harbor's registry of every boat afloat (#9).
///
/// Its header is a frosted pier holding the title and a search field, so the
/// rows sail under it and come to rest past its wake. The tab lives in Harbor
/// Town's body, which ends at the waterline while the tab bar stands on
/// pilings: focus the search and the keyboard covers the tab bar without
/// moving it, while the last row stays reachable above the keyboard.
class FleetTab extends StatefulWidget {
  const FleetTab({super.key});

  @override
  State<FleetTab> createState() => _FleetTabState();
}

class _FleetTabState extends State<FleetTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Boat> get _boats {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return Fleet.boats;
    }
    return <Boat>[
      for (final Boat boat in Fleet.boats)
        if (<String>[
          boat.name,
          boat.captain,
          boat.homePort,
          boat.kindLabel,
        ].any((final String field) => field.toLowerCase().contains(query)))
          boat,
    ];
  }

  Future<void> _refresh(final BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) {
      return;
    }
    HarborFlares.raise(
      context,
      slot: HarborFlareSlot.low,
      builder: (final BuildContext context) => SignalFlag(
        message: 'Registry updated: ${Fleet.boats.length} boats accounted for',
        icon: Icons.fact_check_rounded,
      ),
    );
  }

  void _open(final Boat boat) {
    FocusScope.of(context).unfocus();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (final BuildContext context) => BoatDetailPage(boat: boat)));
  }

  @override
  Widget build(final BuildContext context) {
    final List<Boat> boats = _boats;
    return ColoredBox(
      color: Palette.deepSea,
      child: Harbor(
        debugLabel: 'fleet registry',
        top: <HarborDock>[
          HarborDock.pier(
            debugLabel: 'registry header',
            wake: const HarborWake.fade(length: 12, blurSigma: 18),
            backdrop: const PierPlanks(opacity: 0.55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PierHeader(
                  title: 'Fleet Registry',
                  subtitle: '${boats.length} of ${Fleet.boats.length} boats afloat',
                  trailing: const Padding(padding: EdgeInsets.all(8), child: BuoyArt(size: 24)),
                ),
                HarborMooringLine(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RegistrySearch(
                      controller: _search,
                      onChanged: (final String value) => setState(() => _query = value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        body: Builder(
          builder: (final BuildContext context) => RefreshIndicator(
            // Appears below the header rather than behind it.
            edgeOffset: HarborWaters.of(context).docks.top,
            color: Palette.night,
            backgroundColor: Palette.brass,
            onRefresh: () => _refresh(context),
            child: HarborFairway(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: <Widget>[
                const SliverToBoxAdapter(
                  child: HarborMooringLine(
                    child: LogbookNote(
                      pattern: 'Frosted pier header · fairway on the mooring line',
                      tryThis:
                          'Scroll: the boats sail under the planks and fade in the wake. Tap the search and the '
                          'keyboard covers the tab bar (it stands on pilings) while the last boat still docks above '
                          'the keyboard. Pull down to refresh: the anchor drops just below the header.',
                    ),
                  ),
                ),
                if (boats.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyRegistry())
                else
                  SliverList.builder(
                    itemCount: boats.length,
                    itemBuilder: (final BuildContext context, final int i) => BoatRow(
                      key: ValueKey<String>('boat row ${boats[i].id}'),
                      boat: boats[i],
                      onTap: () => _open(boats[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrySearch extends StatelessWidget {
  const _RegistrySearch({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(final BuildContext context) => TextField(
    key: const ValueKey<String>('registry search'),
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    style: const TextStyle(color: Palette.night),
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Palette.sail.withValues(alpha: 0.92),
      hintText: 'Search the registry…',
      hintStyle: TextStyle(color: Palette.plankDark.withValues(alpha: 0.7)),
      prefixIcon: const Icon(Icons.search_rounded, color: Palette.plankDark),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
    ),
  );
}

class _EmptyRegistry extends StatelessWidget {
  const _EmptyRegistry();

  @override
  Widget build(final BuildContext context) => HarborMooringLine(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: <Widget>[
          const GullArt(size: 40),
          const SizedBox(height: 12),
          Text('No boat by that name in these waters.', style: TextStyle(color: Palette.foam.withValues(alpha: 0.8))),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// #10–#14 Boat detail
// ---------------------------------------------------------------------------

/// A boat's page in the registry (#10–#14), pushed as a new port.
///
/// - **#10 hero:** open water (a sea and the boat) runs under the header and
///   the status bar; its title block keeps clear of the coast alone.
/// - **#11 title handoff:** a beacon on the hero title reports how much of it
///   the header covers, and the header's title fades in by as much.
/// - **#12 logbook tabs:** two sliver docks that pin under the header, stacked.
/// - **#13 crew carousel:** a horizontal fairway, edge to edge, padded at both
///   ends by the mooring line.
/// - **#14 charter pill:** a pontoon moored from deep inside the tab strip,
///   which the last voyage tile rests above.
class BoatDetailPage extends StatefulWidget {
  const BoatDetailPage({super.key, required this.boat});

  final Boat boat;

  @override
  State<BoatDetailPage> createState() => _BoatDetailPageState();
}

enum _LogbookTab { logbook, crew, cargo }

enum _VoyageSort { newest, longest, cargo }

class _BoatDetailPageState extends State<BoatDetailPage> {
  final ValueNotifier<double> _titleOpacity = ValueNotifier<double>(0.0);
  final ScrollController _scroll = ScrollController();
  final GlobalKey _sortStripKey = GlobalKey(debugLabel: 'sort strip');
  final Map<_LogbookTab, GlobalKey> _sections = <_LogbookTab, GlobalKey>{
    for (final _LogbookTab tab in _LogbookTab.values) tab: GlobalKey(debugLabel: tab.name),
  };
  _LogbookTab _tab = _LogbookTab.logbook;
  _VoyageSort _sort = _VoyageSort.newest;

  @override
  void dispose() {
    _titleOpacity.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls so the section's top meets the bottom of the pinned strips.
  void _jumpTo(final _LogbookTab tab) {
    setState(() => _tab = tab);
    final RenderObject? section = _sections[tab]!.currentContext?.findRenderObject();
    final RenderObject? strip = _sortStripKey.currentContext?.findRenderObject();
    if (section is! RenderBox || strip is! RenderBox) {
      return;
    }
    final double delta = section.localToGlobal(Offset.zero).dy - strip.localToGlobal(Offset(0, strip.size.height)).dy;
    final ScrollPosition position = _scroll.position;
    final double target = (position.pixels + delta).clamp(position.minScrollExtent, position.maxScrollExtent);
    _scroll.animateTo(target, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(final BuildContext context) {
    final Boat boat = widget.boat;
    final List<_Voyage> voyages = _Voyage.of(boat, _sort);
    return HarborPage(
      child: Harbor(
        newPort: true,
        debugLabel: 'boat detail',
        top: <HarborDock>[
          HarborDock.pier(
            debugLabel: 'boat header',
            wake: const HarborWake.fade(length: 8, blurSigma: 16),
            backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.35)),
            child: PierHeader(
              key: const ValueKey<String>('boat header'),
              title: boat.name,
              subtitle: boat.kindLabel,
              showBack: true,
              titleOpacity: _titleOpacity,
              trailing: BrassButton(
                icon: Icons.bookmark_add_rounded,
                tooltip: 'Moor in favorites',
                onPressed: () => HarborFlares.raise(
                  context,
                  builder: (final BuildContext context) =>
                      SignalFlag(message: '${boat.name} moored in your favorites'),
                ),
              ),
            ),
          ),
        ],
        body: Builder(
          builder: (final BuildContext context) => ColoredBox(
            color: Palette.deepSea,
            child: HarborFairway(
              controller: _scroll,
              // The hero starts at the frame's top, under the header; the
              // strips still pin at the header's face.
              startsInOpenWater: true,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _BoatHero(
                    key: const ValueKey<String>('boat hero'),
                    boat: boat,
                    onTitleObscured: (final double covered) => _titleOpacity.value = covered,
                  ),
                ),
                HarborSliverDock(
                  backdrop: const _StripBackdrop(),
                  child: _TabStrip(boat: boat, current: _tab, onSelect: _jumpTo),
                ),
                HarborSliverDock(
                  backdrop: const _StripBackdrop(),
                  child: _SortStrip(
                    key: _sortStripKey,
                    current: _sort,
                    onSelect: (final _VoyageSort sort) => setState(() => _sort = sort),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LogbookSection(key: _sections[_LogbookTab.logbook], boat: boat),
                ),
                SliverToBoxAdapter(child: _CrewSection(key: _sections[_LogbookTab.crew])),
                SliverToBoxAdapter(
                  child: HarborMooringLine(
                    key: _sections[_LogbookTab.cargo],
                    child: const _SectionTitle(title: 'Cargo runs', icon: Icons.inventory_2_rounded),
                  ),
                ),
                SliverPadding(
                  padding: HarborMoored.clearanceOf(
                    context,
                    edges: HarborEdge.horizontal,
                    tide: false,
                    mooringLine: true,
                    extra: const EdgeInsetsDirectional.only(bottom: 16),
                  ).resolve(Directionality.of(context)),
                  sliver: SliverGrid.builder(
                    itemCount: voyages.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (final BuildContext context, final int i) =>
                        _VoyageTile(key: ValueKey<String>('voyage tile $i'), voyage: voyages[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// #10 + #11: the hero.

class _BoatHero extends StatelessWidget {
  const _BoatHero({super.key, required this.boat, required this.onTitleObscured});

  final Boat boat;
  final ValueChanged<double> onTitleObscured;

  @override
  Widget build(final BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Stack(
      children: <Widget>[
        // Open water: the sea runs under the status bar and the header.
        Positioned.fill(
          child: HarborOpenWater(
            builder: (final BuildContext context, final HarborWatersData waters) => Stack(
              children: <Widget>[
                const Positioned.fill(child: Sea()),
                PositionedDirectional(top: waters.coast.top + 70, start: 40, child: const GullArt(size: 28)),
                PositionedDirectional(top: waters.coast.top + 96, end: 56, child: const GullArt(size: 18)),
              ],
            ),
          ),
        ),
        // The title block clears the status bar only, so it sits under the
        // translucent header.
        HarborMoored(
          clear: HarborClear.coast,
          edges: const <HarborEdge>{HarborEdge.top},
          child: Column(
            key: const ValueKey<String>('hero title block'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 260,
                  child: BoatArt(kind: boat.kind, hull: boat.hull, flag: boat.flag),
                ),
              ),
              HarborMooringLine(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${boat.kindLabel.toUpperCase()} · No. ${boat.id + 1}',
                      style: text.labelMedium?.copyWith(color: Palette.brass, letterSpacing: 1.6),
                    ),
                    const SizedBox(height: 4),
                    HarborBeacon(
                      onObscured: onTitleObscured,
                      child: Text(
                        boat.name,
                        key: const ValueKey<String>('hero title'),
                        style: text.headlineMedium?.copyWith(color: Palette.foam, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${boat.captain} · home port ${boat.homePort} · ${boat.knots} knots',
                      style: TextStyle(color: Palette.foam.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// #12: the logbook tabs and the sort strip, two sliver docks that stack.

class _StripBackdrop extends StatelessWidget {
  const _StripBackdrop();

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Palette.deepSea.withValues(alpha: 0.97),
      border: Border(bottom: BorderSide(color: Palette.foam.withValues(alpha: 0.08))),
    ),
  );
}

class _TabStrip extends StatefulWidget {
  const _TabStrip({required this.boat, required this.current, required this.onSelect});

  static const double height = 48;

  final Boat boat;
  final _LogbookTab current;
  final ValueChanged<_LogbookTab> onSelect;

  @override
  State<_TabStrip> createState() => _TabStripState();
}

class _TabStripState extends State<_TabStrip> {
  // Kept identical across rebuilds, so the pontoon isn't re-moored each frame.
  late final HarborDock _charter = HarborDock.pier(
    debugLabel: 'charter pill',
    hitTestBehavior: HitTestBehavior.translucent,
    child: _CharterPill(boat: widget.boat),
  );

  @override
  Widget build(final BuildContext context) {
    Widget tab(final _LogbookTab tab, final String label, final IconData icon) {
      final bool selected = tab == widget.current;
      final Color color = selected ? Palette.brass : Palette.foam.withValues(alpha: 0.7);
      return Expanded(
        child: InkWell(
          onTap: () => widget.onSelect(tab),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: selected ? Palette.brass : Colors.transparent, width: 2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // The charter pill is moored from here, deep inside the page's scroll
    // view: it joins the page's bottom docks like any other.
    return HarborPontoon(
      edge: HarborEdge.bottom,
      dock: _charter,
      child: SizedBox(
        key: const ValueKey<String>('logbook tabs'),
        height: _TabStrip.height,
        child: HarborMooringLine(
          child: Row(
            children: <Widget>[
              tab(_LogbookTab.logbook, 'Logbook', Icons.menu_book_rounded),
              tab(_LogbookTab.crew, 'Crew', Icons.groups_rounded),
              tab(_LogbookTab.cargo, 'Cargo', Icons.inventory_2_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortStrip extends StatelessWidget {
  const _SortStrip({super.key, required this.current, required this.onSelect});

  static const double height = 40;

  final _VoyageSort current;
  final ValueChanged<_VoyageSort> onSelect;

  @override
  Widget build(final BuildContext context) {
    Widget chip(final _VoyageSort sort, final String label) => Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: ChoiceChip(
        labelStyle: const TextStyle(fontSize: 12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        label: Text(label),
        selected: sort == current,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (final bool _) => onSelect(sort),
      ),
    );

    return SizedBox(
      key: const ValueKey<String>('sort strip'),
      height: _SortStrip.height,
      // A horizontal fairway of chips, so they run edge to edge on a narrow phone.
      child: HarborFairway.box(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            Text('Sort by', style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12)),
            chip(_VoyageSort.newest, 'Newest'),
            chip(_VoyageSort.longest, 'Longest'),
            chip(_VoyageSort.cargo, 'Most cargo'),
          ],
        ),
      ),
    );
  }
}

// #14: the charter pill, a pontoon's dock.

class _CharterPill extends StatelessWidget {
  const _CharterPill({required this.boat});

  final Boat boat;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    // Only as tall as the pill: a dock is measured, and a bare Center would
    // claim the whole page.
    child: Center(
      heightFactor: 1,
      child: Material(
        key: const ValueKey<String>('charter pill'),
        color: Palette.brass,
        shape: const StadiumBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => HarborFlares.raise(
            context,
            slot: HarborFlareSlot.low,
            builder: (final BuildContext context) => SignalFlag(
              message: '${boat.captain} will meet you at the ${boat.homePort} quay',
              icon: Icons.sailing_rounded,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.sailing_rounded, color: Palette.night),
                SizedBox(width: 8),
                Text(
                  'Book a charter',
                  style: TextStyle(color: Palette.night, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// The logbook section, with a tall voyage whose count pill sticks.

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Palette.brass, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Palette.foam)),
      ],
    ),
  );
}

class _LogbookSection extends StatelessWidget {
  const _LogbookSection({super.key, required this.boat});

  final Boat boat;

  static const List<String> _entries = <String>[
    'Cast off at first light, a fair breeze from the south-west.',
    'Passed the Gullhaven light at noon. Gulls very interested in the sandwiches.',
    'Fog bank off Kelp Cove; sounded the horn and kept to the channel buoys.',
    'Becalmed for an hour. Bosun taught the cook three new knots.',
    'Wind backed westerly; reefed the main and made good time.',
    'Sighted a pod of porpoises riding the bow wave.',
    'Lantern lit at dusk. Anchored in the lee of Foghorn Bay.',
    'Home on the morning tide, all hands well and the hold full.',
  ];

  @override
  Widget build(final BuildContext context) => HarborMooringLine(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        const LogbookNote(
          pattern: 'Open water hero · title handoff · sliver docks · horizontal fairway · pontoon',
          tryThis:
              'Scroll up: the boat sails under the frosted header and its name fades into the header as it passes '
              'beneath. The tabs and the sort strip pin under the header, one below the other. The voyage pill '
              'sticks until its voyage scrolls away. Swipe the crew from edge to edge, and find the charter pill '
              'moored from inside the tab strip: the last cargo run docks just above it.',
        ),
        const _SectionTitle(title: 'Longest voyage', icon: Icons.explore_rounded),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF103A5C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Palette.brass.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              key: const ValueKey<String>('longest voyage'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Rides with the voyage, then sticks below the pinned strips until
                // the voyage itself has scrolled away.
                HarborSticky(
                  gap: 8,
                  child: _VoyageCountPill(key: const ValueKey<String>('voyage pill'), voyages: boat.voyages),
                ),
                const SizedBox(height: 12),
                SizedBox(height: 150, child: VoyageChartArt(seed: boat.id + 7)),
                const SizedBox(height: 12),
                for (int i = 0; i < _entries.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 52,
                          child: Text(
                            'Day ${i + 1}',
                            style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _entries[i],
                            style: TextStyle(color: Palette.foam.withValues(alpha: 0.85), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _VoyageCountPill extends StatelessWidget {
  const _VoyageCountPill({super.key, required this.voyages});

  final int voyages;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Palette.night,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Palette.brass),
      boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 6, color: Colors.black38)],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        '⚓ $voyages voyages',
        style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// #13: the crew carousel.

class _CrewSection extends StatelessWidget {
  const _CrewSection({super.key});

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const HarborMooringLine(
        child: _SectionTitle(title: 'Crew aboard', icon: Icons.groups_rounded),
      ),
      SizedBox(
        height: 150,
        // Edge to edge; the mooring line pads both ends.
        child: HarborFairway(
          key: const ValueKey<String>('crew carousel'),
          scrollDirection: Axis.horizontal,
          slivers: <Widget>[
            SliverList.separated(
              itemCount: Fleet.crew.length,
              separatorBuilder: (final BuildContext context, final int i) => const SizedBox(width: 12),
              itemBuilder: (final BuildContext context, final int i) =>
                  _CrewCard(key: ValueKey<String>('crew ${Fleet.crew[i].name}'), sailor: Fleet.crew[i]),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CrewCard extends StatelessWidget {
  const _CrewCard({super.key, required this.sailor});

  final Sailor sailor;

  @override
  Widget build(final BuildContext context) => SizedBox(
    width: 112,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF103A5C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sailor.color.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SailorArt(color: sailor.color),
          const SizedBox(height: 8),
          Text(
            sailor.name,
            style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w700),
          ),
          Text(sailor.role, style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    ),
  );
}

// The cargo runs: a grid of voyage tiles on the mooring line.

@immutable
class _Voyage {
  const _Voyage({
    required this.number,
    required this.to,
    required this.cargo,
    required this.crates,
    required this.days,
  });

  final int number;
  final String to;
  final String cargo;
  final int crates;
  final int days;

  static const List<String> _ports = <String>['Gullhaven', 'Kelp Cove', 'Saltmarsh', 'Brinestead', 'Foghorn Bay'];
  static const List<String> _cargo = <String>[
    'Lobster pots',
    'Sailcloth',
    'Lamp oil',
    'Ship biscuits',
    'Rope coils',
    'Barrels of cider',
    'Fresh herring',
  ];

  static List<_Voyage> of(final Boat boat, final _VoyageSort sort) {
    final List<_Voyage> voyages = List<_Voyage>.generate(12, (final int i) {
      final int n = boat.id * 5 + i;
      return _Voyage(
        number: 12 - i,
        to: _ports[(n * 3) % _ports.length],
        cargo: _cargo[(n * 5) % _cargo.length],
        crates: 2 + (n * 7) % 11,
        days: 1 + (n * 4) % 9,
      );
    });
    switch (sort) {
      case _VoyageSort.newest:
        break;
      case _VoyageSort.longest:
        voyages.sort((final _Voyage a, final _Voyage b) => b.days.compareTo(a.days));
      case _VoyageSort.cargo:
        voyages.sort((final _Voyage a, final _Voyage b) => b.crates.compareTo(a.crates));
    }
    return voyages;
  }
}

class _VoyageTile extends StatelessWidget {
  const _VoyageTile({super.key, required this.voyage});

  final _Voyage voyage;

  @override
  Widget build(final BuildContext context) => Material(
    color: const Color(0xFF103A5C),
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => HarborFlares.raise(
        context,
        builder: (final BuildContext context) =>
            SignalFlag(message: 'Voyage ${voyage.number}: ${voyage.crates} crates of ${voyage.cargo.toLowerCase()}'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: VoyageChartArt(seed: voyage.number * 31 + voyage.crates)),
            const SizedBox(height: 8),
            Text(
              'No. ${voyage.number} to ${voyage.to}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const CrateArt(size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${voyage.crates} · ${voyage.cargo}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.75), fontSize: 12),
                  ),
                ),
                Text('${voyage.days}d', style: const TextStyle(color: Palette.brass, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
