import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/docks.dart';
import '../art/palette.dart';
import '../art/sea.dart';
import '../game/fleet.dart';
import '../game/settings.dart';
import '../field_guide/field_guide.dart';
import '../game/widgets.dart';

/// The Harbor Office: the harbor master's desk. A pier header over a
/// fairway of grouped rows on the mooring line: the switches (chart,
/// right-to-left, TV), the paperwork (sheets and a pushed page), the signal
/// locker and a postcard of the harbor in a fixed frame.
class OfficeTab extends StatelessWidget {
  const OfficeTab({super.key});

  @override
  Widget build(final BuildContext context) => Harbor(
    debugLabel: 'harbor office',
    top: const <HarborDock>[
      HarborDock.pier(
        debugLabel: 'office header',
        wake: HarborWake.fade(length: 12, blurSigma: 20),
        backdrop: PierPlanks(),
        child: PierHeader(title: 'Harbor Office', subtitle: 'The harbor master is in', leading: FieldGuideButton()),
      ),
    ],
    body: HarborFairway(
      key: const ValueKey<String>('office fairway'),
      padding: const EdgeInsetsDirectional.only(top: 8, bottom: 24),
      slivers: <Widget>[
        SliverList.list(
          children: const <Widget>[_SwitchesGroup(), _PaperworkGroup(), _FlareGroup(), _PostcardGroup()],
        ),
      ],
    ),
  );
}

// ─── Groups ─────────────────────────────────────────────────────────────────

/// A titled group of rows on the mooring line, on a ledger card.
class _LedgerGroup extends StatelessWidget {
  const _LedgerGroup({required this.title, required this.children, this.note});

  final String title;
  final LogbookNote? note;
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) => HarborMooringLine(
    child: Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Palette.brass,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontSize: 12,
              ),
            ),
          ),
          ?note,
          Material(
            color: Palette.night.withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Palette.brass.withValues(alpha: 0.25)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    ),
  );
}

/// A row in a ledger group that opens something.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => ListTile(
    leading: Icon(icon, color: Palette.brass),
    title: Text(
      title,
      style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(subtitle, style: TextStyle(color: Palette.foam.withValues(alpha: 0.7))),
    trailing: Icon(
      Directionality.of(context) == TextDirection.ltr ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
      color: Palette.foam.withValues(alpha: 0.6),
    ),
    onTap: onTap,
  );
}

/// #31: the harbor master's switches.
class _SwitchesGroup extends StatelessWidget {
  const _SwitchesGroup();

  @override
  Widget build(final BuildContext context) {
    final HarborSettings settings = HarborSettings.of(context);
    return _LedgerGroup(
      title: 'Switches',
      note: const LogbookNote(
        pattern: 'Switches: chart, right-to-left, TV',
        tryThis:
            'Raise the chart to see every dock\'s ground, the clear water and the tide. '
            'Flip to right-to-left and watch start and end trade sides. TV mode moors the '
            'whole harbor in a 1200×675 scale model.',
      ),
      children: <Widget>[
        SwitchListTile(
          key: const ValueKey<String>('chart switch'),
          secondary: const Icon(Icons.map_rounded, color: Palette.brass),
          title: const Text('Harbor chart', style: TextStyle(color: Palette.foam)),
          subtitle: Text('Who holds which edge', style: TextStyle(color: Palette.foam.withValues(alpha: 0.7))),
          value: settings.chart,
          onChanged: (final bool value) => settings.chart = value,
        ),
        SwitchListTile(
          key: const ValueKey<String>('rtl switch'),
          secondary: const Icon(Icons.swap_horiz_rounded, color: Palette.brass),
          title: const Text('Right-to-left', style: TextStyle(color: Palette.foam)),
          subtitle: Text('Sail the other way round', style: TextStyle(color: Palette.foam.withValues(alpha: 0.7))),
          value: settings.rtl,
          onChanged: (final bool value) => settings.rtl = value,
        ),
        SwitchListTile(
          key: const ValueKey<String>('tv switch'),
          secondary: const Icon(Icons.tv_rounded, color: Palette.brass),
          title: const Text('Lighthouse TV', style: TextStyle(color: Palette.foam)),
          subtitle: Text(
            'Scale model with a title-safe coast',
            style: TextStyle(color: Palette.foam.withValues(alpha: 0.7)),
          ),
          value: settings.tv,
          onChanged: (final bool value) => settings.tv = value,
        ),
      ],
    );
  }
}

/// #25, #26, #27, #30: sheets and a pushed page.
class _PaperworkGroup extends StatelessWidget {
  const _PaperworkGroup();

  @override
  Widget build(final BuildContext context) => _LedgerGroup(
    title: 'Paperwork',
    children: <Widget>[
      _LedgerRow(
        icon: Icons.inventory_2_rounded,
        title: 'Cargo manifest',
        subtitle: 'A sheet as tall as its cargo',
        onTap: () => showCargoManifest(context),
      ),
      _LedgerRow(
        icon: Icons.event_note_rounded,
        title: 'Charter board',
        subtitle: 'A sheet you can haul up',
        onTap: () => showCharterBoard(context),
      ),
      _LedgerRow(
        icon: Icons.gavel_rounded,
        title: 'Harbor rules',
        subtitle: 'Read them before you sign',
        onTap: () => unawaited(
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (final BuildContext context) => const HarborRulesPage())),
        ),
      ),
      _LedgerRow(
        icon: Icons.storefront_rounded,
        title: 'Chandlery',
        subtitle: 'A shop with its own shelves',
        onTap: () => showChandlery(context),
      ),
    ],
  );
}

/// #28: flares by slot, and a flare that outlives its page.
class _FlareGroup extends StatelessWidget {
  const _FlareGroup();

  void _raise(final BuildContext context, final HarborFlareSlot slot, final String message) => HarborFlares.raise(
    context,
    slot: slot,
    builder: (final BuildContext context) => SignalFlag(message: message),
  );

  @override
  Widget build(final BuildContext context) => _LedgerGroup(
    title: 'Signal locker',
    note: const LogbookNote(
      pattern: 'Flares by slot',
      tryThis:
          'Raise a flag at each slot: they float in the clear water, past the header and the '
          'tab bar. "Raise and leave" opens the signal tower, raises a low flag there and '
          'shuts it at once: the flag moves to the page now on top and keeps flying.',
    ),
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            _FlagButton(label: 'Top', onPressed: () => _raise(context, HarborFlareSlot.top, 'Fog on the top deck')),
            _FlagButton(label: 'High', onPressed: () => _raise(context, HarborFlareSlot.high, 'Gulls sighted aloft')),
            _FlagButton(
              label: 'Middle',
              onPressed: () => _raise(context, HarborFlareSlot.middle, 'Steady as she goes'),
            ),
            _FlagButton(label: 'Low', onPressed: () => _raise(context, HarborFlareSlot.low, 'Cargo stowed below')),
            _FlagButton(
              key: const ValueKey<String>('raise and leave'),
              label: 'Raise and leave',
              icon: Icons.logout_rounded,
              onPressed: () => unawaited(
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (final BuildContext context) => const _SignalTowerPage())),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({super.key, required this.label, required this.onPressed, this.icon = Icons.flag_rounded});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: Palette.foam,
      side: BorderSide(color: Palette.brass.withValues(alpha: 0.7)),
    ),
  );
}

/// #29: a postcard of the harbor, a fixed frame with no coast and no tide.
class _PostcardGroup extends StatelessWidget {
  const _PostcardGroup();

  @override
  Widget build(final BuildContext context) => const _LedgerGroup(
    title: 'Postcard',
    note: LogbookNote(
      pattern: 'A fixed frame with no coast or tide',
      tryThis:
          'This postcard is a whole harbor (a pier header, a quay footer and a fairway) in a '
          '300×200 frame with HarborCoast.none. Turn the phone, raise the keyboard, try any '
          'device: it lays out the same every time.',
    ),
    children: <Widget>[
      Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: HarborPostcard()),
      ),
    ],
  );
}

/// A miniature harbor in a 300×200 frame that ignores the coast and the tide.
class HarborPostcard extends StatelessWidget {
  const HarborPostcard({super.key});

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Palette.sail, width: 4),
      boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 8, color: Colors.black45, offset: Offset(0, 3))],
    ),
    child: SizedBox(
      key: const ValueKey<String>('postcard frame'),
      width: 300,
      height: 200,
      child: Harbor(
        // A new port: no outer docks or wakes reach in. Flares still fly on the
        // page, the topmost route-level port, not in this embedded frame.
        newPort: true,
        coast: HarborCoast.none,
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        debugLabel: 'postcard',
        top: const <HarborDock>[
          HarborDock.pier(
            debugLabel: 'postcard header',
            wake: HarborWake.fade(length: 8),
            backdrop: PierPlanks(),
            child: SizedBox(
              key: ValueKey<String>('postcard header'),
              height: 30,
              child: HarborMooringLine(
                child: Center(
                  child: Text(
                    'Greetings from Gullhaven',
                    style: TextStyle(color: Palette.foam, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const <HarborDock>[
          HarborDock.quay(
            debugLabel: 'postcard footer',
            backdrop: QuayStones(),
            child: SizedBox(
              height: 24,
              child: Center(
                child: Text('Wish you were here ⚓', style: TextStyle(color: Palette.foam, fontSize: 11)),
              ),
            ),
          ),
        ],
        body: Stack(
          children: <Widget>[
            const Positioned.fill(child: Sea(mood: SeaMood.calm)),
            HarborFairway(
              primary: false,
              slivers: <Widget>[
                SliverList.builder(
                  itemCount: 6,
                  itemBuilder: (final BuildContext context, final int i) {
                    final Boat boat = Fleet.boats[i];
                    return HarborMooringLine(
                      child: SizedBox(
                        height: 30,
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 36,
                              child: BoatArt(kind: boat.kind, hull: boat.hull, flag: boat.flag, bob: false),
                            ),
                            const SizedBox(width: 8),
                            Text(boat.name, style: const TextStyle(color: Palette.foam, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── #25 Cargo manifest ───────────────────────────────────────────────────────

const List<(String, int, Color)> _crates = <(String, int, Color)>[
  ('Kelp, pressed', 40, Color(0xFF5C8A4A)),
  ('Lantern oil', 25, Color(0xFFB07A4B)),
  ('Spare oars', 18, Color(0xFF8A5A33)),
  ('Salted herring', 60, Color(0xFF6E7378)),
  ('Sailcloth bolts', 32, Color(0xFFD8C9A8)),
  ('Brass fittings', 22, Color(0xFFE9B949)),
  ('Rope, hemp', 45, Color(0xFFD8B47A)),
  ('Ship biscuits', 15, Color(0xFFC49A6C)),
  ('Tar barrels', 70, Color(0xFF4A4E52)),
  ('Gull feed', 10, Color(0xFFEFEFEF)),
  ('Charts, rolled', 5, Color(0xFF3D5A98)),
  ('Fog horn reeds', 3, Color(0xFFE2463A)),
];

/// Opens the cargo manifest: a content-sized sheet whose footer floats on the
/// keyboard and clears the home indicator once.
void showCargoManifest(final BuildContext context) => unawaited(
  showHarborSheet<void>(
    context,
    builder: (final BuildContext context) => HarborPage(
      child: HarborSheet(
        debugLabel: 'cargo manifest',
        surface: const Sailcloth(),
        header: const SheetHeader(title: 'Cargo manifest'),
        footer: HarborMooringLine(
          child: Padding(
            key: const ValueKey<String>('cargo footer'),
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => HarborSheet.close(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: Palette.foam,
                      side: BorderSide(color: Palette.foam.withValues(alpha: 0.5)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BrassAction(
                    label: 'Load cargo',
                    icon: Icons.inventory_rounded,
                    onPressed: () {
                      HarborSheet.close(context);
                      HarborFlares.raise(
                        context,
                        slot: HarborFlareSlot.low,
                        builder: (final BuildContext context) => const SignalFlag(message: 'Cargo loaded, cast off!'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        body: HarborFairway.box(
          shrinkWrap: true,
          child: HarborMooringLine(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const LogbookNote(
                  pattern: 'Content-sized sheet',
                  tryThis:
                      'The header is a pier, the footer a quay that floats on the tide. Tap the field: '
                      'the footer rides the keyboard, and when room runs out the crates scroll '
                      'instead of spilling over. The home indicator is cleared once, by the footer.',
                ),
                const SizedBox(height: 8),
                const TextField(
                  key: ValueKey<String>('cargo field'),
                  style: TextStyle(color: Palette.foam),
                  decoration: InputDecoration(
                    labelText: 'Bound for which port?',
                    hintText: 'Kelp Cove',
                    prefixIcon: Icon(Icons.place_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                for (final (String name, int weight, Color color) in _crates)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: <Widget>[
                        CrateArt(size: 28, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(name, style: const TextStyle(color: Palette.foam)),
                        ),
                        Text(
                          '$weight kg',
                          style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

// ─── #26 Charter board ────────────────────────────────────────────────────────

/// Opens the charter board: a draggable sheet resting at half the space above
/// the keyboard, hauled up to 0.88.
void showCharterBoard(final BuildContext context) => unawaited(
  showHarborSheet<void>(context, builder: (final BuildContext context) => const HarborPage(child: _CharterBoard())),
);

class _CharterBoard extends StatefulWidget {
  const _CharterBoard();

  @override
  State<_CharterBoard> createState() => _CharterBoardState();
}

class _CharterBoardState extends State<_CharterBoard> {
  String _query = '';

  @override
  Widget build(final BuildContext context) {
    final String query = _query.toLowerCase();
    final List<Boat> boats = Fleet.boats
        .where((final Boat b) => query.isEmpty || '${b.name} ${b.captain} ${b.homePort}'.toLowerCase().contains(query))
        .toList();
    return HarborSheet.draggable(
      debugLabel: 'charter board',
      surface: const Sailcloth(),
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SheetHeader(key: ValueKey<String>('charter header'), title: 'Charter board'),
          HarborMooringLine(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                key: const ValueKey<String>('charter search'),
                style: const TextStyle(color: Palette.foam),
                onChanged: (final String value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search boats, captains, ports',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
      builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
        controller: controller,
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: HarborMooringLine(
              child: LogbookNote(
                pattern: 'Draggable sheet, heights above the keyboard',
                tryThis:
                    'It rests at half the water and hauls up to 0.88. Tap the search: the sheet\'s '
                    'heights become fractions of the space above the keyboard, so it never hides '
                    'under it. Drag it low to send it away.',
              ),
            ),
          ),
          SliverList.builder(
            itemCount: boats.length,
            itemBuilder: (final BuildContext context, final int i) => BoatRow(
              boat: boats[i],
              onTap: () {
                HarborSheet.close(context);
                HarborFlares.raise(
                  context,
                  slot: HarborFlareSlot.low,
                  builder: (final BuildContext context) => SignalFlag(message: '${boats[i].name} is chartered!'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── #27 Harbor rules ────────────────────────────────────────────────────────

const List<String> _rules = <String>[
  'Keep to the starboard side of the channel, and give way to anything bigger than you.',
  'No wake inside the breakwater. The gulls are napping.',
  'Moor only at a numbered berth, and pay your dues at the office before sundown.',
  'Lanterns lit from dusk till dawn. A dark boat is a lost boat.',
  'Fog horns are for fog. Not for greeting your cousin on the east quay.',
  'Nets, crates and oars are not to be left on the boardwalk.',
  'The harbor master\'s word is final, especially about the biscuits.',
  'Sound one long blast leaving the berth and two short coming about.',
  'Report any loose buoy, drifting dinghy or suspicious sea serpent to the office.',
  'Children under ten may row only with a grown sailor aboard.',
];

/// A new port whose header is a quay: the rules start below it rather than
/// sailing under it, and the "I agree" button keeps 16 off a bare bottom edge.
class HarborRulesPage extends StatelessWidget {
  const HarborRulesPage({super.key});

  @override
  Widget build(final BuildContext context) => HarborPage(
    child: Harbor(
      newPort: true,
      debugLabel: 'harbor rules',
      top: const <HarborDock>[
        HarborDock.quay(
          debugLabel: 'rules header',
          backdrop: PierPlanks(),
          child: PierHeader(key: ValueKey<String>('rules header'), title: 'Harbor rules', showBack: true),
        ),
      ],
      body: ColoredBox(
        color: Palette.deepSea,
        child: Column(
          children: <Widget>[
            Expanded(
              // The button below keeps clear of the bottom, so the rules don't.
              child: HarborCastOff(
                edges: const <HarborEdge>{HarborEdge.bottom},
                tide: true,
                child: HarborFairway(
                  padding: const EdgeInsetsDirectional.only(top: 8, bottom: 16),
                  slivers: <Widget>[
                    const SliverToBoxAdapter(
                      child: HarborMooringLine(
                        child: LogbookNote(
                          pattern: 'Quay header, moored text, a minimum off a bare edge',
                          tryThis:
                              'The header is a quay, so the rules start below it, like a Column. The '
                              '"I agree" button is moored to the bottom with a 16 minimum: on a phone '
                              'with no home indicator it still keeps off the edge.',
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: _rules.length,
                      itemBuilder: (final BuildContext context, final int i) => HarborMooringLine(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${i + 1}.',
                                  style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Expanded(
                                child: Text(_rules[i], style: const TextStyle(color: Palette.foam, height: 1.35)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HarborMoored(
              edges: const <HarborEdge>{HarborEdge.bottom},
              minimum: const EdgeInsetsDirectional.only(bottom: 16),
              extra: const EdgeInsetsDirectional.only(top: 8),
              child: HarborMooringLine(
                child: BrassAction(
                  key: const ValueKey<String>('i agree'),
                  label: 'I agree',
                  icon: Icons.handshake_rounded,
                  onPressed: () {
                    Navigator.of(context).maybePop();
                    HarborFlares.raise(
                      context,
                      slot: HarborFlareSlot.low,
                      builder: (final BuildContext context) => const SignalFlag(message: 'Welcome aboard, sailor!'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── #28 Raise and leave ──────────────────────────────────────────────────────

/// The signal tower: raises a low flare as soon as it opens, then shuts at
/// once. The flare moves to the page now on top and keeps flying.
class _SignalTowerPage extends StatefulWidget {
  const _SignalTowerPage();

  @override
  State<_SignalTowerPage> createState() => _SignalTowerPageState();
}

class _SignalTowerPageState extends State<_SignalTowerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (!mounted) {
        return;
      }
      HarborFlares.raise(
        context,
        slot: HarborFlareSlot.low,
        duration: const Duration(seconds: 4),
        builder: (final BuildContext context) =>
            const SignalFlag(key: ValueKey<String>('tower signal'), message: 'Raised in the tower, still flying'),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(final BuildContext context) => const HarborPage(
    child: Harbor(
      newPort: true,
      debugLabel: 'signal tower',
      top: <HarborDock>[
        HarborDock.pier(
          backdrop: PierPlanks(),
          child: PierHeader(title: 'Signal tower', showBack: true),
        ),
      ],
      body: ColoredBox(
        color: Palette.deepSea,
        child: Center(child: SizedBox(width: 120, child: LighthouseArt())),
      ),
    ),
  );
}

// ─── #30 Chandlery ────────────────────────────────────────────────────────────

/// Opens the chandlery: a sheet with a component harbor inside, whose own
/// pier header sits below the sheet's.
void showChandlery(final BuildContext context) => unawaited(
  showHarborSheet<void>(
    context,
    builder: (final BuildContext context) => const HarborPage(
      child: HarborSheet(
        debugLabel: 'chandlery',
        surface: Sailcloth(),
        // A hairline rather than a fade, so the shop's own header sits flush below.
        headerWake: HarborWake.hairline(),
        header: SheetHeader(key: ValueKey<String>('chandlery sheet header'), title: 'Chandlery'),
        body: SizedBox(height: 420, child: _Chandlery()),
      ),
    ),
  ),
);

enum _Shelf {
  ropes('Ropes', Icons.cable_rounded, <String>[
    'Hemp line, 20 fathoms',
    'Mooring warp',
    'Heaving line',
    'Bowline practice cord',
    'Halyard, braided',
    'Sheet, double-braid',
  ]),
  sails('Sails', Icons.sailing_rounded, <String>[
    'Jib, patched',
    'Mainsail, tan',
    'Storm trysail',
    'Spinnaker, striped',
    'Genoa, tired',
    'Topsail, square',
  ]),
  lanterns('Lanterns', Icons.light_rounded, <String>[
    'Masthead lantern',
    'Port light (red)',
    'Starboard light (green)',
    'Stern lantern',
    'Anchor light',
    'Storm lantern',
  ]);

  const _Shelf(this.label, this.icon, this.goods);

  final String label;
  final IconData icon;
  final List<String> goods;
}

/// The shop inside the chandlery sheet: a component harbor (not a new port)
/// that sees the sheet's header as coast.
class _Chandlery extends StatefulWidget {
  const _Chandlery();

  @override
  State<_Chandlery> createState() => _ChandleryState();
}

class _ChandleryState extends State<_Chandlery> {
  _Shelf _shelf = _Shelf.ropes;

  @override
  Widget build(final BuildContext context) => Harbor(
    debugLabel: 'chandlery shop',
    top: <HarborDock>[
      HarborDock.pier(
        debugLabel: 'shelf chips',
        wake: const HarborWake.fade(length: 10),
        backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.85)),
        child: SizedBox(
          key: const ValueKey<String>('chandlery shelves'),
          height: 52,
          child: HarborFairway(
            scrollDirection: Axis.horizontal,
            primary: false,
            slivers: <Widget>[
              SliverList.separated(
                itemCount: _Shelf.values.length,
                separatorBuilder: (final BuildContext context, final int i) => const SizedBox(width: 8),
                itemBuilder: (final BuildContext context, final int i) {
                  final _Shelf shelf = _Shelf.values[i];
                  return Center(
                    child: ChoiceChip(
                      avatar: Icon(shelf.icon, size: 18),
                      label: Text(shelf.label),
                      selected: shelf == _shelf,
                      onSelected: (final bool _) => setState(() => _shelf = shelf),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ],
    body: HarborFairway(
      primary: false,
      slivers: <Widget>[
        const SliverToBoxAdapter(
          child: HarborMooringLine(
            child: LogbookNote(
              pattern: 'A component harbor nested in a sheet',
              tryThis:
                  'The shop is a Harbor of its own, not a new port, so it sees the sheet\'s header '
                  'as coast: its shelf chips dock right below it. Scroll the goods under the chips.',
            ),
          ),
        ),
        SliverList.builder(
          itemCount: _shelf.goods.length,
          itemBuilder: (final BuildContext context, final int i) => HarborMooringLine(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_shelf.icon, color: Palette.brass),
              title: Text(_shelf.goods[i], style: const TextStyle(color: Palette.foam)),
              trailing: Text('${3 + i * 2} shells', style: const TextStyle(color: Palette.rope)),
            ),
          ),
        ),
      ],
    ),
  );
}
