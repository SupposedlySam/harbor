import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/docks.dart';
import '../art/open_sea_art.dart';
import '../art/palette.dart';
import '../art/sea.dart';
import '../game/fleet.dart';
import '../field_guide/field_guide.dart';
import '../game/widgets.dart';

/// The Open Sea tab: a full-screen feed of voyages, one boat to a page.
///
/// It is a component harbor inside Harbor Town's body. Its header is a pier
/// with a frosted fade wake over open water that runs under the status bar; a
/// fairway of sea moods in the header runs edge to edge; each voyage card is
/// moored in the clear water between the header and the tab bar; a shanty
/// drawer is a non-modal breakwater sheet the header withdraws for; and the fog
/// horn is a buoy at the bottom of the clear water while the next voyage loads.
class OpenSeaTab extends StatelessWidget {
  const OpenSeaTab({super.key});

  @override
  Widget build(final BuildContext context) => _VoyageHarbor(
    debugLabel: 'open sea',
    title: 'Open Sea',
    boats: Fleet.boats,
    makeWay: HarborYield.withdraw,
    newPort: false,
  );
}

/// One boat's voyage, followed on its own page: a new port with a way back in
/// its header and the same feed and drawer as the Open Sea tab. Here the
/// header goes dark for the drawer rather than withdrawing, because it holds
/// the back button and keeps its ground.
class VoyagePage extends StatelessWidget {
  const VoyagePage({super.key, required this.boat});

  final Boat boat;

  @override
  Widget build(final BuildContext context) => HarborPage(
    child: _VoyageHarbor(
      debugLabel: 'voyage ${boat.name}',
      title: boat.name,
      boats: <Boat>[boat],
      makeWay: HarborYield.dark,
      newPort: true,
      showBack: true,
    ),
  );
}

/// The weather a skipper can choose for the open water.
enum _Weather {
  calm('Calm', Icons.wb_sunny_rounded, SeaMood.calm),
  choppy('Choppy', Icons.waves_rounded, SeaMood.choppy),
  stormy('Stormy', Icons.thunderstorm_rounded, SeaMood.stormy),
  night('Night', Icons.dark_mode_rounded, SeaMood.night),
  fogBank('Fog bank', Icons.cloud_rounded, SeaMood.choppy, fog: 0.6),
  moonlit('Moonlit', Icons.nightlight_round, SeaMood.night, moon: true),
  squall('Squall', Icons.bolt_rounded, SeaMood.stormy, fog: 0.25),
  doldrums('Doldrums', Icons.air_rounded, SeaMood.calm, fog: 0.15),
  tradeWinds('Trade winds', Icons.sailing_rounded, SeaMood.choppy);

  const _Weather(this.label, this.icon, this.mood, {this.fog = 0.0, this.moon = false});

  final String label;
  final IconData icon;
  final SeaMood mood;
  final double fog;
  final bool moon;
}

const List<String> _destinations = <String>['Lantern Point', 'Puffin Rock', 'Seal Island', 'Mermaid Shoal', 'Cape Brine'];

/// The harbor both the tab and the voyage page are built from.
class _VoyageHarbor extends StatefulWidget {
  const _VoyageHarbor({
    required this.debugLabel,
    required this.title,
    required this.boats,
    required this.makeWay,
    required this.newPort,
    this.showBack = false,
  });

  final String debugLabel;
  final String title;
  final List<Boat> boats;

  /// How the header makes way while the shanty drawer is open.
  final HarborYield makeWay;
  final bool newPort;
  final bool showBack;

  @override
  State<_VoyageHarbor> createState() => _VoyageHarborState();
}

class _VoyageHarborState extends State<_VoyageHarbor> {
  static const Duration _fogHornFor = Duration(milliseconds: 1400);

  final PageController _pages = PageController();
  _Weather _weather = _Weather.calm;
  bool _singing = false;
  Timer? _fogHorn;

  @override
  void initState() {
    super.initState();
    _soundFogHorn();
  }

  @override
  void dispose() {
    _fogHorn?.cancel();
    _pages.dispose();
    super.dispose();
  }

  /// Shows the fog horn for a moment, as if the next voyage were loading.
  void _soundFogHorn() {
    _fogHorn?.cancel();
    _fogHorn = Timer(_fogHornFor, () {
      if (mounted) {
        setState(() => _fogHorn = null);
      }
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _singShanty(final BuildContext context, final Boat boat) async {
    setState(() => _singing = true);
    await showHarborSheet<void>(
      context,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      useRootNavigator: true,
      // A non-modal sheet: it closes itself if this harbor leaves first.
      builder: (final BuildContext _) => _ShantyDrawer(key: const ValueKey<String>('shanty drawer'), boat: boat),
    );
    if (mounted) {
      setState(() => _singing = false);
    }
  }

  void _follow(final Boat boat) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (final BuildContext context) => VoyagePage(boat: boat)));
  }

  @override
  Widget build(final BuildContext context) {
    final bool following = widget.boats.length == 1;
    return Harbor(
      newPort: widget.newPort,
      debugLabel: widget.debugLabel,
      top: <HarborDock>[
        HarborDock.pier(
          debugLabel: '${widget.debugLabel} header',
          wake: const HarborWake.fade(length: 16, blurSigma: 14),
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.35)),
          child: _OpenSeaHeader(
            title: widget.title,
            subtitle: following ? '${widget.boats.single.kindLabel} voyage' : '${widget.boats.length} voyages under way',
            showBack: widget.showBack,
            weather: _weather,
            onWeather: (final _Weather weather) => setState(() => _weather = weather),
            onFogHorn: _soundFogHorn,
          ),
        ),
      ],
      buoys: <HarborBuoy>[
        if (_fogHorn != null)
          const HarborBuoy(
            key: ValueKey<String>('fog horn buoy'),
            alignment: Alignment.bottomCenter,
            child: _FogHorn(key: ValueKey<String>('fog horn')),
          ),
      ],
      // Open water under everything, the status bar and the header included.
      // The feed is no fairway, so it takes the wake itself and fades as it
      // passes under the header; the sea is left as it is.
      body: Builder(
        builder: (final BuildContext context) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            HarborOpenWater(
              builder: (final BuildContext context, final HarborWatersData waters) => Sea(
                mood: _weather.mood,
                child: SkyOverlay(fog: _weather.fog, moon: _weather.moon, moonTop: waters.coast.top + 12),
              ),
            ),
            HarborWakeMask(
              wakes: HarborWaters.of(context).wakes,
              child: HarborMakeWay(
                edge: HarborEdge.top,
                mode: widget.makeWay,
                active: _singing,
                child: PageView.builder(
                  controller: _pages,
                  scrollDirection: Axis.vertical,
                  itemCount: widget.boats.length,
                  onPageChanged: (final int _) => _soundFogHorn(),
                  itemBuilder: (final BuildContext context, final int index) {
                    final Boat boat = widget.boats[index];
                    return _VoyageBerth(
                      boat: boat,
                      singing: _singing,
                      onSing: (final BuildContext context) => _singShanty(context, boat),
                      onFollow: following ? null : () => _follow(boat),
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
}

/// The header on the pier: a title plank and a fairway of sea moods.
class _OpenSeaHeader extends StatelessWidget {
  const _OpenSeaHeader({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.weather,
    required this.onWeather,
    required this.onFogHorn,
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final _Weather weather;
  final ValueChanged<_Weather> onWeather;
  final VoidCallback onFogHorn;

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      PierHeader(
        title: title,
        subtitle: subtitle,
        showBack: showBack,
        leading: showBack ? null : const FieldGuideButton(),
        trailing: BrassButton(icon: Icons.campaign_rounded, tooltip: 'Sound the fog horn', onPressed: onFogHorn),
      ),
      SizedBox(
        height: 44,
        // A horizontal fairway in a dock: the dock leaves the side insets in
        // its MediaQuery, so the chips run past a cutout and rest on the
        // mooring line at both ends.
        child: HarborFairway(
          scrollDirection: Axis.horizontal,
          slivers: <Widget>[
            SliverList.separated(
              itemCount: _Weather.values.length,
              separatorBuilder: (final BuildContext context, final int index) => const SizedBox(width: 8),
              itemBuilder: (final BuildContext context, final int index) {
                final _Weather chip = _Weather.values[index];
                return Center(
                  child: ChoiceChip(
                    key: ValueKey<String>('mood ${chip.name}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    avatar: Icon(chip.icon, size: 16, color: chip == weather ? Palette.night : Palette.foam),
                    showCheckmark: false,
                    label: Text(chip.label),
                    labelStyle: TextStyle(color: chip == weather ? Palette.night : Palette.foam),
                    selectedColor: Palette.brass,
                    backgroundColor: Palette.night.withValues(alpha: 0.4),
                    side: BorderSide(color: Palette.brass.withValues(alpha: 0.6)),
                    selected: chip == weather,
                    onSelected: (final bool _) => onWeather(chip),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}

/// One page of the feed: a voyage card moored in the clear water, below the
/// header and above the tab bar (or the shanty drawer, while it is open).
class _VoyageBerth extends StatelessWidget {
  const _VoyageBerth({required this.boat, required this.singing, required this.onSing, required this.onFollow});

  final Boat boat;
  final bool singing;
  final ValueChanged<BuildContext> onSing;
  final VoidCallback? onFollow;

  @override
  Widget build(final BuildContext context) => HarborMoored(
    mooringLine: true,
    extra: const EdgeInsetsDirectional.symmetric(vertical: 8),
    child: LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        // Sized from the frame, which the keyboard never shrinks, and capped
        // by the water that is left, so it reflows above the drawer.
        final Size frame = HarborWaters.of(context, aspect: HarborWatersAspect.frame).frameSize;
        final double height = math.min(constraints.maxHeight, frame.height * 0.72);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: ValueKey<String>('voyage card ${boat.id}'),
            width: double.infinity,
            height: height,
            child: _VoyageCard(boat: boat, singing: singing, onSing: () => onSing(context), onFollow: onFollow),
          ),
        );
      },
    ),
  );
}

class _VoyageCard extends StatelessWidget {
  const _VoyageCard({required this.boat, required this.singing, required this.onSing, required this.onFollow});

  final Boat boat;
  final bool singing;
  final VoidCallback onSing;
  final VoidCallback? onFollow;

  @override
  Widget build(final BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String destination = _destinations[(boat.id + 2) % _destinations.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.night.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.brass.withValues(alpha: 0.5)),
        boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 18, color: Colors.black38, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(0.0, constraints.maxHeight - 32)),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('VOYAGE ${boat.id + 1}', style: text.labelSmall?.copyWith(color: Palette.brass, letterSpacing: 2)),
                        const Spacer(),
                        Text('${boat.knots} kn', style: text.labelMedium?.copyWith(color: Palette.foam)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 96),
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(child: VoyageChartArt(seed: boat.id)),
                            Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.55,
                                child: BoatArt(kind: boat.kind, hull: boat.hull, flag: boat.flag),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(boat.name, style: text.headlineSmall?.copyWith(color: Palette.foam, fontWeight: FontWeight.w700)),
                    Text(
                      '${boat.kindLabel} · ${boat.captain} · ${boat.voyages} voyages logged',
                      style: TextStyle(color: Palette.foam.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.anchor_rounded, size: 16, color: Palette.brass),
                        const SizedBox(width: 6),
                        Flexible(child: Text('${boat.homePort}  ⟶  $destination', style: const TextStyle(color: Palette.foam))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BrassAction(
                      label: singing ? 'All hands singing…' : 'Sing a shanty',
                      icon: Icons.music_note_rounded,
                      onPressed: singing ? null : onSing,
                    ),
                    if (onFollow != null) ...<Widget>[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: singing ? null : onFollow,
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Follow this voyage'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: Palette.foam,
                          side: BorderSide(color: Palette.foam.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                    const LogbookNote(
                      pattern: 'Pier over open water · moored cards · breakwater drawer · fog horn buoy',
                      tryThis:
                          'Pick a sea mood: the chips run edge to edge but start on the mooring line. Swipe up for '
                          'the next voyage and the fog horn sounds just above the tab bar. Sing a shanty: the header '
                          'withdraws here (on a followed voyage it goes dark, keeping the back button\'s ground) '
                          'and the card reflows above the drawer.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The fog horn: a buoy that bobs at the bottom of the clear water while the
/// next voyage loads.
class _FogHorn extends StatelessWidget {
  const _FogHorn({super.key});

  @override
  Widget build(final BuildContext context) => Material(
    color: Palette.night.withValues(alpha: 0.92),
    shape: const StadiumBorder(side: BorderSide(color: Palette.brass, width: 1.5)),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BuoyArt(size: 24),
          SizedBox(width: 8),
          SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.brass)),
          SizedBox(width: 10),
          Flexible(child: Text('Fog horn! Charting the next voyage…', style: TextStyle(color: Palette.foam))),
        ],
      ),
    ),
  );
}

/// The shanty drawer: a sheet of lyrics that covers the tab bar while the
/// feed stays live above it.
class _ShantyDrawer extends StatelessWidget {
  const _ShantyDrawer({super.key, required this.boat});

  final Boat boat;

  @override
  Widget build(final BuildContext context) {
    final List<List<String>> verses = _shantyFor(boat);
    return HarborSheet(
      debugLabel: 'shanty drawer',
      maxExtentFraction: 0.42,
      surface: const Sailcloth(),
      header: SheetHeader(title: 'The ${boat.name} Shanty'),
      body: HarborFairway(
        padding: const EdgeInsetsDirectional.only(bottom: 16),
        slivers: <Widget>[
          SliverList.builder(
            itemCount: verses.length,
            itemBuilder: (final BuildContext context, final int index) => HarborMooringLine(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(index.isEven ? Icons.music_note_rounded : Icons.queue_music_rounded, color: Palette.brass, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        verses[index].join('\n'),
                        style: TextStyle(
                          color: Palette.foam,
                          height: 1.45,
                          fontStyle: index.isOdd ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<List<String>> _shantyFor(final Boat boat) {
    const List<String> chorus = <String>[
      'So heave away, me hearties, heave!',
      'The tide is turning, time to leave!',
    ];
    final String name = boat.name;
    final String captain = boat.captain;
    return switch (boat.id % 3) {
      0 => <List<String>>[
        <String>['Oh, the $name sailed at the break of day,', 'with $captain singing all the way.'],
        chorus,
        <String>['We passed the gulls on the harbor wall,', 'they squawked and stole our biscuits all.'],
        chorus,
        <String>['And when we spy the lighthouse beam,', 'we\'ll dock in time for tea and cream.'],
        chorus,
      ],
      1 => <List<String>>[
        <String>['Haul on the halyard, the $name\'s away,', 'out past the buoys and into the bay.'],
        chorus,
        <String>['The fog came in like a woolly sheep,', '$captain blew the horn: beep beep!'],
        chorus,
        <String>['We lost an oar and we found a crab,', 'he\'s first mate now, and terribly fab.'],
        chorus,
      ],
      _ => <List<String>>[
        <String>['Way-hey, blow the wind westerly,', 'the $name rolls and the sea is merry.'],
        chorus,
        <String>['$captain says the barometer\'s low,', 'so batten the hatches and on we go.'],
        chorus,
        <String>['Ten knots, twelve knots, out to the shoal,', 'and back for a bowl of chowder, whole.'],
        chorus,
      ],
    };
  }
}
