import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import 'art/docks.dart';
import 'art/palette.dart';
import 'field_guide/field_guide.dart';
import 'game/widgets.dart';
import 'scenes/fleet.dart';
import 'scenes/office.dart';
import 'scenes/open_sea.dart';
import 'scenes/radio.dart';
import 'scenes/shipyard.dart';

/// Harbor Town: the shell. Its tab bar is a quay on pilings, so the keyboard
/// covers it rather than lifting it, while each tab's body ends at the
/// waterline. The Launch button in the middle carries an anchor for the tide
/// bonus bubble, and holding it raises a modal buoy of quick actions.
class HarborTown extends StatefulWidget {
  const HarborTown({super.key});

  @override
  State<HarborTown> createState() => _HarborTownState();
}

enum TownTab { openSea, fleet, radio, office }

class _HarborTownState extends State<HarborTown> {
  TownTab _tab = TownTab.openSea;
  final HarborAnchor _launch = HarborAnchor(debugLabel: 'launch');
  bool _bubble = true;
  bool _quickActions = false;

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  void _openShipyard() {
    setState(() => _quickActions = false);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (final BuildContext context) => const ShipyardPage()));
  }

  @override
  Widget build(final BuildContext context) {
    return HarborPage(
      child: Harbor(
        newPort: true,
        debugLabel: 'harbor town',
        bottom: <HarborDock>[
          HarborDock.quay(
            debugLabel: 'tab bar',
            backdrop: const QuayStones(),
            child: TownTabBar(
              current: _tab,
              launchAnchor: _launch,
              onSelect: (final TownTab tab) => setState(() => _tab = tab),
              onLaunch: _openShipyard,
              onLaunchHold: () => setState(() {
                _bubble = false;
                _quickActions = true;
              }),
            ),
          ),
        ],
        buoys: <HarborBuoy>[
          if (_bubble)
            HarborBuoy.anchored(
              key: const ValueKey<String>('tide bonus'),
              anchor: _launch,
              gap: 2,
              overlap: 6,
              child: GestureDetector(
                onTap: () => setState(() => _bubble = false),
                child: const _TideBonusBubble(),
              ),
            ),
          if (_quickActions)
            HarborBuoy(
              key: const ValueKey<String>('quick actions'),
              modal: true,
              onDismiss: () => setState(() => _quickActions = false),
              alignment: Alignment.bottomCenter,
              child: _QuickActions(
                onClose: () => setState(() => _quickActions = false),
                onShipyard: _openShipyard,
              ),
            ),
        ],
        body: IndexedStack(
          index: _tab.index,
          children: const <Widget>[OpenSeaTab(), FleetTab(), RadioTab(), OfficeTab()],
        ),
      ),
    );
  }
}

/// The tab bar on the quay.
class TownTabBar extends StatelessWidget {
  const TownTabBar({
    super.key,
    required this.current,
    required this.launchAnchor,
    required this.onSelect,
    required this.onLaunch,
    required this.onLaunchHold,
  });

  final TownTab current;
  final HarborAnchor launchAnchor;
  final ValueChanged<TownTab> onSelect;
  final VoidCallback onLaunch;
  final VoidCallback onLaunchHold;

  @override
  Widget build(final BuildContext context) {
    Widget item(final TownTab tab, final IconData icon, final String label) {
      final bool selected = tab == current;
      return Expanded(
        child: InkResponse(
          key: ValueKey<String>('town tab ${tab.name}'),
          onTap: () => onSelect(tab),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: selected ? Palette.brass : Palette.foam.withValues(alpha: 0.7)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: selected ? Palette.brass : Palette.foam.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: Row(
        children: <Widget>[
          item(TownTab.openSea, Icons.waves_rounded, 'Open Sea'),
          item(TownTab.fleet, Icons.directions_boat_rounded, 'Fleet'),
          Expanded(
            child: Center(
              child: HarborAnchorPoint(
                anchor: launchAnchor,
                child: GestureDetector(
                  key: const ValueKey<String>('launch button'),
                  onTap: onLaunch,
                  onLongPress: onLaunchHold,
                  child: Container(
                    width: 56,
                    height: 36,
                    decoration: BoxDecoration(color: Palette.brass, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.anchor_rounded, color: Palette.night),
                  ),
                ),
              ),
            ),
          ),
          item(TownTab.radio, Icons.radio_rounded, 'Radio'),
          item(TownTab.office, Icons.account_balance_rounded, 'Office'),
        ],
      ),
    );
  }
}

class _TideBonusBubble extends StatelessWidget {
  const _TideBonusBubble();

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Palette.buoyRed, borderRadius: BorderRadius.circular(12)),
        child: const Text('Tap ⚓ to launch a boat · hold for more', style: TextStyle(color: Colors.white, fontSize: 12)),
      ),
      CustomPaint(size: const Size(14, 8), painter: _Caret()),
    ],
  );
}

class _Caret extends CustomPainter {
  @override
  void paint(final Canvas canvas, final Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = Palette.buoyRed,
  );

  @override
  bool shouldRepaint(final _Caret oldDelegate) => false;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onClose, required this.onShipyard});

  final VoidCallback onClose;
  final VoidCallback onShipyard;

  @override
  Widget build(final BuildContext context) => Material(
    color: Palette.night.withValues(alpha: 0.96),
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(leading: const Icon(Icons.construction_rounded), title: const Text('Open the shipyard'), onTap: onShipyard),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Open the field guide'),
            onTap: () {
              onClose();
              FieldGuideButton.open(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_rounded),
            title: const Text('Raise a signal'),
            onTap: () {
              onClose();
              HarborSignals.raise(context, slot: HarborSignalSlot.low, builder: (final BuildContext c) => const SignalFlag(message: 'All hands on deck!'));
            },
          ),
          ListTile(leading: const Icon(Icons.close_rounded), title: const Text('Close'), onTap: onClose),
        ],
      ),
    ),
  );
}
