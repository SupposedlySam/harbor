import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/docks.dart';
import '../art/palette.dart';
import '../art/sea.dart';
import '../game/fleet.dart';
import '../game/widgets.dart';

/// The Shipyard: a pushed route and a new port where you arrange and paint
/// boats (scenes #21 to #24).
///
/// - **Shipyard canvas (#21):** the body runs under the keyboard
///   (`bodyClearsTide: false`). Boats sit in a [HarborLighthouseRegion], each
///   one a [HarborBeacon] that lifts while selected, so a boat the paint sheet
///   would cover rises until it is 80 clear of the sheet's top.
/// - **Paint shop (#22):** a non-modal breakwater sheet whose footer is a dry
///   dock: the color tray takes exactly the keyboard's ground, so nothing
///   moves when you switch tabs or the keyboard comes and goes.
/// - **Tool strip (#23):** a bottom pier that withdraws at high tide and holds
///   its ground until it has fully slid out.
/// - **Unsaved changes (#24):** a [HarborPontoon] moored from deep in the
///   canvas stacks an "Unsaved changes" bar above the tool strip.
class ShipyardPage extends StatefulWidget {
  const ShipyardPage({super.key});

  @override
  State<ShipyardPage> createState() => _ShipyardPageState();
}

class _ShipyardPageState extends State<ShipyardPage> {
  final ShipyardYard _yard = ShipyardYard.launchDay();

  // The paint sheet is non-modal and closes itself when the shipyard leaves.
  @override
  void dispose() {
    _yard.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => HarborPage(
    child: Harbor(
      newPort: true,
      bodyClearsTide: false,
      debugLabel: 'shipyard',
      top: <HarborDock>[
        HarborDock.pier(
          debugLabel: 'shipyard header',
          backdrop: const PierPlanks(),
          child: PierHeader(
            title: 'Shipyard',
            showBack: true,
            trailing: Builder(
              builder: (final BuildContext context) => Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListenableBuilder(
                    listenable: _yard,
                    builder: (final BuildContext context, final Widget? _) => BrassButton(
                      key: const ValueKey<String>('ceremony toggle'),
                      icon: _yard.ceremony ? Icons.celebration_rounded : Icons.celebration_outlined,
                      tooltip: 'Launch ceremony',
                      onPressed: _yard.toggleCeremony,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey<String>('launch'),
                    onPressed: () => _launchFleet(context, _yard),
                    style: TextButton.styleFrom(foregroundColor: Palette.brass),
                    icon: const Icon(Icons.anchor_rounded, size: 18),
                    label: const Text('Launch'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      bottom: <HarborDock>[
        HarborDock.pier(
          debugLabel: 'tool strip',
          withdrawsAtHighTide: true,
          extentPolicy: HarborExtentPolicy.hold,
          backdrop: const PierPlanks(postsToward: AxisDirection.up),
          child: ToolStrip(yard: _yard),
        ),
      ],
      body: ShipyardCanvas(yard: _yard),
    ),
  );
}

/// Raises a signal sending every boat on the water down the slipway.
void _launchFleet(final BuildContext context, final ShipyardYard yard) {
  final int count = yard.boats.length;
  HarborSignals.raise(
    context,
    slot: HarborSignalSlot.low,
    builder: (final BuildContext context) => SignalFlag(
      message: count == 0 ? 'Nothing on the slipway yet' : '$count ${count == 1 ? 'boat' : 'boats'} down the slipway!',
      icon: Icons.sailing_rounded,
    ),
  );
}

/// What kind of thing sits on the shipyard's water.
enum YardPieceKind { boat, crate }

/// A boat or a crate on the shipyard's water, at a position given as a share
/// of the canvas (so it stays put when the screen turns).
class YardPiece {
  YardPiece({
    required this.id,
    required this.kind,
    required this.at,
    this.name = '',
    this.boatKind = BoatKind.sailboat,
    this.hull = Palette.buoyRed,
    this.flag,
  });

  final int id;
  final YardPieceKind kind;

  /// Where the piece's center is, as a fraction of the canvas.
  Offset at;
  String name;
  final BoatKind boatKind;
  Color hull;
  Color? flag;
}

/// The shipyard's state: what is on the water, which boat is on the
/// paint-shop stand, and whether anything changed since the last save.
class ShipyardYard extends ChangeNotifier {
  ShipyardYard(this._pieces);

  /// Four boats from the fleet register, the last one low in the water.
  factory ShipyardYard.launchDay() {
    const List<Offset> berths = <Offset>[Offset(0.28, 0.38), Offset(0.72, 0.47), Offset(0.3, 0.58), Offset(0.7, 0.72)];
    return ShipyardYard(<YardPiece>[
      for (int i = 0; i < berths.length; i++)
        YardPiece(
          id: i,
          kind: YardPieceKind.boat,
          at: berths[i],
          name: Fleet.boats[i].name,
          boatKind: Fleet.boats[i].kind,
          hull: Fleet.boats[i].hull,
          flag: Fleet.boats[i].flag,
        ),
    ]);
  }

  final List<YardPiece> _pieces;
  int _nextId = 100;
  int? _selectedId;
  int? _draggingId;
  bool _dirty = false;
  bool _ceremony = false;

  List<YardPiece> get pieces => List<YardPiece>.unmodifiable(_pieces);

  List<YardPiece> get boats => _pieces.where((final YardPiece p) => p.kind == YardPieceKind.boat).toList();

  YardPiece? get selected {
    for (final YardPiece piece in _pieces) {
      if (piece.id == _selectedId) {
        return piece;
      }
    }
    return null;
  }

  int? get selectedId => _selectedId;
  int? get draggingId => _draggingId;
  bool get dirty => _dirty;

  /// Whether the launch ceremony card is up in the middle of the canvas.
  bool get ceremony => _ceremony;

  void toggleCeremony() {
    _ceremony = !_ceremony;
    notifyListeners();
  }

  void select(final int? id) {
    if (_selectedId != id) {
      _selectedId = id;
      notifyListeners();
    }
  }

  void startDrag(final int id) {
    _draggingId = id;
    notifyListeners();
  }

  void drag(final int id, final Offset fraction) {
    final YardPiece piece = _pieces.firstWhere((final YardPiece p) => p.id == id);
    piece.at = Offset((piece.at.dx + fraction.dx).clamp(0.05, 0.95), (piece.at.dy + fraction.dy).clamp(0.05, 0.95));
    _dirty = true;
    notifyListeners();
  }

  void endDrag() {
    _draggingId = null;
    notifyListeners();
  }

  void rename(final String name) => _edit((final YardPiece boat) => boat.name = name);

  void paintHull(final Color color) => _edit((final YardPiece boat) => boat.hull = color);

  void paintFlag(final Color? color) => _edit((final YardPiece boat) => boat.flag = color);

  void _edit(final void Function(YardPiece boat) change) {
    final YardPiece? boat = selected;
    if (boat == null) {
      return;
    }
    change(boat);
    _dirty = true;
    notifyListeners();
  }

  /// Floats a fresh boat from the register onto the water.
  void addBoat() {
    final int id = _nextId++;
    final Boat model = Fleet.boats[(id + 4) % Fleet.boats.length];
    _pieces.add(
      YardPiece(
        id: id,
        kind: YardPieceKind.boat,
        at: _freeBerth(id),
        name: model.name,
        boatKind: model.kind,
        hull: model.hull,
        flag: model.flag,
      ),
    );
    _dirty = true;
    notifyListeners();
  }

  /// Swings a crate of cargo onto the water.
  void addCrate() {
    final int id = _nextId++;
    _pieces.add(YardPiece(id: id, kind: YardPieceKind.crate, at: _freeBerth(id)));
    _dirty = true;
    notifyListeners();
  }

  /// Clears the slipway of everything.
  void clear() {
    if (_pieces.isEmpty) {
      return;
    }
    _pieces.clear();
    _selectedId = null;
    _dirty = true;
    notifyListeners();
  }

  void save() {
    _dirty = false;
    notifyListeners();
  }

  static Offset _freeBerth(final int id) {
    const List<Offset> berths = <Offset>[
      Offset(0.5, 0.42),
      Offset(0.2, 0.5),
      Offset(0.8, 0.6),
      Offset(0.45, 0.68),
      Offset(0.62, 0.34),
      Offset(0.18, 0.7),
    ];
    return berths[id % berths.length];
  }
}

/// The shipyard's open water: the sea, the boats and crates on it, and the
/// logbook note. Moors the "Unsaved changes" pontoon from down here.
class ShipyardCanvas extends StatefulWidget {
  const ShipyardCanvas({super.key, required this.yard});

  final ShipyardYard yard;

  @override
  State<ShipyardCanvas> createState() => _ShipyardCanvasState();
}

class _ShipyardCanvasState extends State<ShipyardCanvas> {
  bool _sheetOpen = false;

  ShipyardYard get _yard => widget.yard;

  void _tapBoat(final YardPiece boat) {
    // A second tap on the boat being painted puts the brushes down.
    if (_yard.selectedId == boat.id) {
      _yard.select(null);
      return;
    }
    _yard.select(boat.id);
    if (_sheetOpen) {
      return;
    }
    _sheetOpen = true;
    unawaited(
      showHarborSheet<void>(
        context,
        breakwater: true,
        barrier: HarborSheetBarrier.none,
        builder: (final BuildContext context) => PaintShop(yard: _yard),
      ).then((final void _) {
        _sheetOpen = false;
        if (mounted) {
          _yard.select(null);
        }
      }),
    );
  }

  void _save() {
    _yard.save();
    HarborSignals.raise(
      context,
      slot: HarborSignalSlot.low,
      builder: (final BuildContext context) => const SignalFlag(message: 'Shipyard saved!', icon: Icons.save_rounded),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return ListenableBuilder(
      listenable: _yard,
      builder: (final BuildContext context, final Widget? note) => HarborPontoon(
        edge: HarborEdge.bottom,
        active: _yard.dirty,
        dock: HarborDock.pier(
          key: const ValueKey<String>('unsaved'),
          debugLabel: 'unsaved changes',
          withdrawsAtHighTide: true,
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.9)),
          child: UnsavedBar(onSave: _save),
        ),
        child: Stack(
          children: <Widget>[
            // Reduce motion stills the sea.
            Positioned.fill(
              child: TickerMode(enabled: !still, child: const Sea()),
            ),
            Positioned.fill(
              child: HarborLighthouseRegion(
                child: LayoutBuilder(
                  builder: (final BuildContext context, final BoxConstraints constraints) =>
                      _pieces(constraints.biggest, still: still),
                ),
              ),
            ),
            Positioned(top: 0, left: 0, right: 0, child: note!),
            if (_yard.ceremony)
              Positioned.fill(
                // Centered on the screen, never more than 12 under a dock or the sheet.
                child: HarborCenter(
                  overlapBudget: 12,
                  child: LaunchCeremony(
                    boats: _yard.boats.length,
                    onLaunch: () => _launchFleet(context, _yard),
                    onClose: _yard.toggleCeremony,
                  ),
                ),
              ),
          ],
        ),
      ),
      child: const HarborMoored(
        edges: <HarborEdge>{HarborEdge.top, HarborEdge.start, HarborEdge.end},
        mooringLine: true,
        child: LogbookNote(
          pattern: 'Body under the keyboard · beacon lift · dry dock · tool strip · pontoon',
          tryThis:
              'Drag boats around and tap one to paint it: a low boat rises 80 clear of the paint sheet. '
              'Rename it and the keyboard takes the color tray\'s exact ground. Any change moors an '
              'Unsaved bar above the tool strip, which withdraws while the keyboard is up.',
        ),
      ),
    );
  }

  Widget _pieces(final Size canvas, {required final bool still}) {
    final List<Widget> children = <Widget>[];
    for (final YardPiece piece in _yard.pieces) {
      final bool boat = piece.kind == YardPieceKind.boat;
      final Size size = boat ? const Size(_boatWidth, _boatWidth / 1.4 + _plateHeight) : const Size.square(40);
      final bool selected = piece.id == _yard.selectedId;
      Widget art = boat ? YardBoat(piece: piece, selected: selected, bob: !still) : const CrateArt(size: 40);
      if (boat) {
        art = HarborBeacon(lift: selected, clearance: 80, holdPosition: _yard.draggingId == piece.id, child: art);
      }
      children.add(
        Positioned(
          key: ValueKey<int>(piece.id),
          left: piece.at.dx * canvas.width - size.width / 2,
          top: piece.at.dy * canvas.height - size.height / 2,
          width: size.width,
          height: size.height,
          child: GestureDetector(
            key: ValueKey<String>(boat ? 'boat-${piece.id}' : 'crate-${piece.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: boat ? () => _tapBoat(piece) : null,
            onPanStart: (final DragStartDetails _) => _yard.startDrag(piece.id),
            onPanUpdate: (final DragUpdateDetails details) =>
                _yard.drag(piece.id, Offset(details.delta.dx / canvas.width, details.delta.dy / canvas.height)),
            onPanEnd: (final DragEndDetails _) => _yard.endDrag(),
            onPanCancel: _yard.endDrag,
            child: art,
          ),
        ),
      );
    }
    return Stack(children: children);
  }
}

/// The launch ceremony card: a bottle for the bow and a button that sends the
/// fleet down the slipway. Sits in the middle of the canvas via [HarborCenter].
class LaunchCeremony extends StatelessWidget {
  const LaunchCeremony({super.key, required this.boats, required this.onLaunch, required this.onClose});

  final int boats;
  final VoidCallback onLaunch;
  final VoidCallback onClose;

  @override
  Widget build(final BuildContext context) => Material(
    key: const ValueKey<String>('ceremony card'),
    color: Palette.sail,
    borderRadius: BorderRadius.circular(16),
    elevation: 6,
    child: SizedBox(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.wine_bar_rounded, color: Palette.plankDark),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Launch ceremony',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Palette.plankDark),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Palette.plankDark),
                ),
              ],
            ),
            Text(
              'Break a bottle on $boats ${boats == 1 ? 'bow' : 'bows'}.',
              style: const TextStyle(color: Color(0xFF4E342E), height: 1.3),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: BrassAction(label: 'Down the slipway', onPressed: onLaunch),
            ),
          ],
        ),
      ),
    ),
  );
}

const double _boatWidth = 96;
const double _plateHeight = 20;

/// A boat on the shipyard's water, with its name plate, ringed in brass while
/// it is on the paint-shop stand.
class YardBoat extends StatelessWidget {
  const YardBoat({super.key, required this.piece, required this.selected, this.bob = true});

  final YardPiece piece;
  final bool selected;
  final bool bob;

  @override
  Widget build(final BuildContext context) => Column(
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Palette.brass : Colors.transparent, width: 2),
          color: selected ? Palette.brass.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: BoatArt(kind: piece.boatKind, hull: piece.hull, flag: piece.flag, bob: bob),
      ),
      SizedBox(
        height: _plateHeight,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected ? Palette.brass : Palette.night.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              piece.name.isEmpty ? 'Unnamed' : piece.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: selected ? Palette.night : Palette.foam),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The tool strip on the bottom pier: add a boat, add a crate, clear the slipway.
class ToolStrip extends StatelessWidget {
  const ToolStrip({super.key, required this.yard});

  final ShipyardYard yard;

  @override
  Widget build(final BuildContext context) => SizedBox(
    key: const ValueKey<String>('tool strip'),
    height: 64,
    child: HarborMooringLine(
      child: Row(
        children: <Widget>[
          _Tool(
            key: const ValueKey<String>('add boat'),
            icon: Icons.directions_boat_rounded,
            label: 'Add boat',
            onTap: yard.addBoat,
          ),
          _Tool(
            key: const ValueKey<String>('add crate'),
            icon: Icons.inventory_2_rounded,
            label: 'Add crate',
            onTap: yard.addCrate,
          ),
          _Tool(
            key: const ValueKey<String>('clear'),
            icon: Icons.cleaning_services_rounded,
            label: 'Clear',
            onTap: yard.clear,
          ),
        ],
      ),
    ),
  );
}

class _Tool extends StatelessWidget {
  const _Tool({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => Expanded(
    child: InkResponse(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: Palette.sail),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Palette.sail, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

/// The "Unsaved changes · Save" bar the canvas moors as a pontoon.
class UnsavedBar extends StatelessWidget {
  const UnsavedBar({super.key, required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(final BuildContext context) => SizedBox(
    key: const ValueKey<String>('unsaved bar'),
    height: 48,
    child: HarborMooringLine(
      child: Row(
        children: <Widget>[
          const Icon(Icons.edit_note_rounded, color: Palette.brass),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Unsaved changes', style: TextStyle(color: Palette.foam)),
          ),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(foregroundColor: Palette.brass),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

/// The paint shop's tabs.
enum PaintTab {
  name('Name', Icons.badge_rounded),
  hull('Hull', Icons.format_paint_rounded),
  flag('Flag', Icons.flag_rounded);

  const PaintTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The paint shop: a non-modal breakwater sheet with one height across its
/// tabs. Its header holds the tab row; its body is a deck of fixed height (the
/// name field, or a preview); its footer is a dry dock as tall as the tide's
/// high-water mark, filled by the color tray while the keyboard is down and
/// covered by the keyboard while it is up.
class PaintShop extends StatefulWidget {
  const PaintShop({super.key, required this.yard});

  final ShipyardYard yard;

  @override
  State<PaintShop> createState() => _PaintShopState();
}

class _PaintShopState extends State<PaintShop> {
  final TextEditingController _name = TextEditingController();
  PaintTab _tab = PaintTab.name;
  int? _boundId;
  bool _closing = false;

  ShipyardYard get _yard => widget.yard;

  @override
  void initState() {
    super.initState();
    _yard.addListener(_yardChanged);
    _yardChanged();
  }

  @override
  void dispose() {
    _yard.removeListener(_yardChanged);
    _name.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) {
      return;
    }
    _closing = true;
    closeHarborSheet(context);
  }

  void _yardChanged() {
    final YardPiece? boat = _yard.selected;
    if (boat == null) {
      // Deselected (or cleared away): the stand is empty, so the sheet goes.
      _close();
      return;
    }
    if (boat.id != _boundId) {
      _boundId = boat.id;
      _name.text = boat.name;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _pick(final PaintTab tab) {
    if (tab != PaintTab.name) {
      // Off the Name tab the keyboard goes down and the tray takes its ground.
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(final BuildContext context) {
    final YardPiece? boat = _yard.selected;
    return HarborPage(
      child: HarborSheet(
        key: const ValueKey<String>('paint panel'),
        debugLabel: 'paint shop',
        surface: const Sailcloth(),
        headerWake: HarborWake.none,
        header: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SheetHeader(
              title: boat == null ? 'Paint shop' : 'Paint shop · ${boat.name.isEmpty ? 'Unnamed' : boat.name}',
            ),
            _TabRow(current: _tab, onPick: _pick),
          ],
        ),
        body: HarborMoored(
          edges: const <HarborEdge>{HarborEdge.top},
          tide: false,
          child: SizedBox(height: 64, child: HarborMooringLine(child: _deck(boat))),
        ),
        // A dry dock: the keyboard's ground, kept at high water either way.
        footerTide: HarborTideStance.dryDock,
        footerMinimum: 0,
        footerWake: HarborWake.none,
        footer: HarborDryDock(key: const ValueKey<String>('dry dock'), child: boat == null ? null : _tray(boat)),
      ),
    );
  }

  Widget _deck(final YardPiece? boat) {
    final Widget preview = SizedBox(
      width: 64,
      child: boat == null ? null : BoatArt(kind: boat.boatKind, hull: boat.hull, flag: boat.flag, bob: false),
    );
    final Widget detail = switch (_tab) {
      PaintTab.name => TextField(
        key: const ValueKey<String>('name field'),
        controller: _name,
        onChanged: _yard.rename,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(color: Palette.foam),
        decoration: const InputDecoration(isDense: true, labelText: 'Name on the stern', border: OutlineInputBorder()),
      ),
      PaintTab.hull => const _DeckLabel(title: 'Hull paint', subtitle: 'Pick a pot below: the hull takes it at once.'),
      PaintTab.flag => const _DeckLabel(title: 'Masthead flag', subtitle: 'Run up a color, or strike the flag.'),
    };
    return Row(
      children: <Widget>[
        preview,
        const SizedBox(width: 12),
        Expanded(child: detail),
      ],
    );
  }

  Widget _tray(final YardPiece boat) {
    final List<Widget> items = switch (_tab) {
      PaintTab.name => <Widget>[
        for (final String name in _suggestions)
          ActionChip(
            label: Text(name),
            onPressed: () {
              _name.text = name;
              _yard.rename(name);
            },
          ),
      ],
      PaintTab.hull => <Widget>[
        for (final Color color in _paints)
          PaintPot(
            key: ValueKey<String>('hull ${color.toARGB32()}'),
            color: color,
            chosen: boat.hull == color,
            onTap: () => _yard.paintHull(color),
          ),
      ],
      PaintTab.flag => <Widget>[
        PaintPot(color: null, chosen: boat.flag == null, onTap: () => _yard.paintFlag(null)),
        for (final Color color in _paints)
          PaintPot(
            key: ValueKey<String>('flag ${color.toARGB32()}'),
            color: color,
            chosen: boat.flag == color,
            onTap: () => _yard.paintFlag(color),
          ),
      ],
    };
    final HarborTideState tide = HarborTide.of(context);
    return ColoredBox(
      color: Palette.night.withValues(alpha: 0.35),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
        child: HarborMooringLine(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(switch (_tab) {
                PaintTab.name => 'Name board · or type one above',
                PaintTab.hull => 'Paint pots',
                PaintTab.flag => 'Signal locker',
              }, style: const TextStyle(color: Palette.rope, fontWeight: FontWeight.w700)),
              if (tide.highWaterIsEstimate)
                Text(
                  'estimate: this tray is sized to a guessed keyboard until one has risen',
                  key: const ValueKey<String>('estimate hint'),
                  style: TextStyle(fontSize: 10, color: Palette.foam.withValues(alpha: 0.6)),
                ),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 10, children: items),
            ],
          ),
        ),
      ),
    );
  }

  static const List<String> _suggestions = <String>[
    'Moonraker',
    'Puffin',
    'Squall',
    'Marigold',
    'Lantern',
    'Spindrift',
    'Sea Biscuit',
    'Cormorant',
  ];

  static const List<Color> _paints = <Color>[
    ...Palette.hulls,
    Palette.brass,
    Palette.shallows,
    Palette.night,
    Palette.plank,
  ];
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.current, required this.onPick});

  final PaintTab current;
  final ValueChanged<PaintTab> onPick;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: 44,
    child: HarborMooringLine(
      child: Row(
        children: <Widget>[
          for (final PaintTab tab in PaintTab.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Material(
                  color: tab == current ? Palette.brass : Palette.night.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    key: ValueKey<String>('tab ${tab.name}'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onPick(tab),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(tab.icon, size: 16, color: tab == current ? Palette.night : Palette.foam),
                        const SizedBox(width: 6),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: tab == current ? Palette.night : Palette.foam,
                            fontWeight: FontWeight.w700,
                          ),
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

class _DeckLabel extends StatelessWidget {
  const _DeckLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        title,
        style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w700),
      ),
      Text(subtitle, style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12)),
    ],
  );
}

/// A pot of paint in the tray; a null [color] strikes the flag.
class PaintPot extends StatelessWidget {
  const PaintPot({super.key, required this.color, required this.chosen, required this.onTap});

  final Color? color;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color ?? Palette.night,
        shape: BoxShape.circle,
        border: Border.all(color: chosen ? Palette.brass : Palette.foam.withValues(alpha: 0.3), width: chosen ? 3 : 1),
      ),
      child: color == null ? const Icon(Icons.block_rounded, color: Palette.foam, size: 20) : null,
    ),
  );
}
