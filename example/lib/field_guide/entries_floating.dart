import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/palette.dart';
import '../game/widgets.dart';
import 'art/beacon_art.dart';
import 'art/floating_art.dart';
import 'art/sheet_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Afloat, sheets and dialogs, and the lighthouse: what floats in the clear
/// water, the new ports that open over a page, and keeping things in sight.
final List<GuideEntry> floatingEntries = <GuideEntry>[
  GuideEntry(
    id: 'buoy',
    className: 'HarborBuoy',
    group: GuideGroup.floating,
    realWorld: 'A red can buoy floating free in open water',
    art: (final BuildContext context) => const HarborBuoyArt(),
    page: (final BuildContext context) => const HarborBuoyEntry(),
  ),
  GuideEntry(
    id: 'buoy-anchored',
    className: 'HarborBuoy.anchored',
    group: GuideGroup.floating,
    realWorld: 'A mooring buoy on a chain to an anchor on the seabed',
    art: (final BuildContext context) => const MooringBuoyArt(),
    page: (final BuildContext context) => const AnchoredBuoyEntry(),
  ),
  GuideEntry(
    id: 'buoy-modal',
    className: 'HarborBuoy(modal: true)',
    group: GuideGroup.floating,
    realWorld: 'The harbor master’s launch, clearing other boats out of its way',
    art: (final BuildContext context) => const HarborLaunchArt(),
    page: (final BuildContext context) => const ModalBuoyEntry(),
  ),
  GuideEntry(
    id: 'buoy-portal',
    className: 'HarborPortalBuoy',
    group: GuideGroup.floating,
    realWorld: 'A dan buoy thrown over the side, wherever the boat happens to be',
    art: (final BuildContext context) => const DanBuoyArt(),
    page: (final BuildContext context) => const PortalBuoyEntry(),
  ),
  GuideEntry(
    id: 'signals',
    className: 'HarborFlares.raise',
    group: GuideGroup.floating,
    realWorld: 'International signal flags run up a halyard',
    art: (final BuildContext context) => const SignalFlagsArt(),
    page: (final BuildContext context) => const FlaresEntry(),
  ),
  GuideEntry(
    id: 'sheet',
    className: 'HarborSheet',
    group: GuideGroup.sheets,
    realWorld: 'A sail, trimmed by its sheet',
    art: (final BuildContext context) => const SailSheetArt(),
    page: (final BuildContext context) => const HarborSheetEntry(),
  ),
  GuideEntry(
    id: 'sheet-draggable',
    className: 'HarborSheet.draggable',
    group: GuideGroup.sheets,
    realWorld: 'A sail hauled up its mast on a halyard, reefed or full',
    art: (final BuildContext context) => const HalyardArt(),
    page: (final BuildContext context) => const DraggableSheetEntry(),
  ),
  GuideEntry(
    id: 'sheet-breakwater',
    className: 'showHarborSheet(breakwater: true)',
    group: GuideGroup.sheets,
    realWorld: 'A rock breakwater sheltering the harbor from the swell',
    art: (final BuildContext context) => const BreakwaterArt(),
    page: (final BuildContext context) => const BreakwaterEntry(),
  ),
  GuideEntry(
    id: 'dialog',
    className: 'showHarborDialog(inheritClearWater:)',
    group: GuideGroup.sheets,
    realWorld: 'The harbor master’s office window, where the radio call is taken',
    art: (final BuildContext context) => const HarborOfficeArt(),
    page: (final BuildContext context) => const DialogEntry(),
  ),
  GuideEntry(
    id: 'lighthouse-reveal',
    className: 'HarborBeacon(keepInSight:)',
    group: GuideGroup.lighthouse,
    realWorld: 'A lighthouse sweeping its beam onto a boat',
    art: (final BuildContext context) => const LighthouseBeamArt(),
    page: (final BuildContext context) => const KeepInSightEntry(),
  ),
  GuideEntry(
    id: 'beacon-obscured',
    className: 'HarborBeacon(onObscured:)',
    group: GuideGroup.lighthouse,
    realWorld: 'A harbor light half hidden behind a headland',
    art: (final BuildContext context) => const HeadlandBeaconArt(),
    page: (final BuildContext context) => const ObscuredBeaconEntry(),
  ),
  GuideEntry(
    id: 'lighthouse-region',
    className: 'HarborLighthouseRegion',
    group: GuideGroup.lighthouse,
    realWorld: 'A boat lift raising a boat out of the water',
    art: (final BuildContext context) => const BoatLiftArt(),
    page: (final BuildContext context) => const LiftEntry(),
  ),
];

// ---------------------------------------------------------------------------
// Shared stage parts.

/// The header every demo here docks: a frosted pier naming the class.
HarborDock _headerDock(final String title, {final HarborWake wake = HarborWake.none, final Widget? trailing, final Key? key}) =>
    HarborDock.pier(
      wake: wake,
      backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.82)),
      debugLabel: 'header',
      child: KeyedSubtree(
        key: key,
        child: trailing == null
            ? StageHeader(title: title)
            : SizedBox(
                height: 52,
                child: HarborMooringLine(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Menlo', fontSize: 14, fontWeight: FontWeight.w700, color: Palette.foam),
                        ),
                      ),
                      trailing,
                    ],
                  ),
                ),
              ),
      ),
    );

/// A bottom quay: a tab bar or composer.
HarborDock _tabBarDock(final String label, {final Key? key}) => HarborDock.quay(
  backdrop: const ColoredBox(color: Palette.night),
  debugLabel: 'tab bar',
  child: StageBar(key: key, label: label, icon: Icons.sailing_rounded),
);

Widget _rows(final int count, {final int from = 0}) => SliverList.builder(
  itemCount: count,
  itemBuilder: (final BuildContext context, final int i) => StageRow(index: from + i),
);

/// A compact brass button for the stage.
class _StageButton extends StatelessWidget {
  const _StageButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon ?? Icons.sailing_rounded, size: 18),
    label: Text(label, style: const TextStyle(fontFamily: 'Menlo', fontSize: 12, fontWeight: FontWeight.w700)),
    style: FilledButton.styleFrom(
      backgroundColor: Palette.brass,
      foregroundColor: Palette.night,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 40),
    ),
  );
}

/// A buoy on the stage: a red pill with a can buoy drawn on it.
class _BuoyTag extends StatelessWidget {
  const _BuoyTag({super.key, required this.label, this.color = Palette.buoyRed});

  final String label;
  final Color color;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white, width: 1.5),
      boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 8, color: Colors.black45, offset: Offset(0, 3))],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CanBuoyIcon(),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: const TextStyle(fontFamily: 'Menlo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

/// The open-water backdrop for a body that has no list in it.
class _OpenWater extends StatelessWidget {
  const _OpenWater({this.hint, this.child});

  final String? hint;
  final Widget? child;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Palette.sea, Palette.deepSea],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (hint != null)
          HarborMoored(
            mooringLine: true,
            extra: const EdgeInsetsDirectional.only(top: 12),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 13, height: 1.35),
              ),
            ),
          ),
        ?child,
      ],
    ),
  );
}

String _f(final double v) => v.toStringAsFixed(0);
String _fraction(final double percent) => (percent / 100).toStringAsFixed(2);

// ---------------------------------------------------------------------------
// 1. HarborBuoy

const Map<String, Alignment> _alignments = <String, Alignment>{
  'topCenter': Alignment.topCenter,
  'topRight': Alignment.topRight,
  'center': Alignment.center,
  'bottomLeft': Alignment.bottomLeft,
  'bottomCenter': Alignment.bottomCenter,
  'bottomRight': Alignment.bottomRight,
};

/// `HarborBuoy`: something afloat in the clear water.
class HarborBuoyEntry extends StatefulWidget {
  const HarborBuoyEntry({super.key});

  @override
  State<HarborBuoyEntry> createState() => _HarborBuoyEntryState();
}

class _HarborBuoyEntryState extends State<HarborBuoyEntry> {
  String _alignment = 'bottomRight';
  double _margin = 16;
  bool _header = true;
  bool _tabBar = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBuoy',
    realWorld:
        'A buoy floats on its own in open water, away from the quays and piers, so every boat can see it. Nothing is '
        'built over it, and it never runs aground on the shore.',
    inYourApp:
        'A floating button, a bubble or a menu. It sits at its alignment in the clear water, the rectangle no coast, '
        'dock or keyboard covers, so it clears the status bar, your header, your tab bar and the keyboard without '
        'knowing any of their sizes.',
    art: const HarborBuoyArt(),
    controls: <Widget>[
      ChoiceControl<String>(
        label: 'alignment',
        values: _alignments.keys.toList(),
        value: _alignment,
        labelOf: (final String a) => a,
        onChanged: (final String a) => setState(() => _alignment = a),
      ),
      SliderControl(label: 'margin', value: _margin, min: 0, max: 48, onChanged: (final double v) => setState(() => _margin = v)),
      ToggleControl(label: 'header (pier)', value: _header, onChanged: (final bool v) => setState(() => _header = v)),
      ToggleControl(label: 'tab bar (quay)', value: _tabBar, onChanged: (final bool v) => setState(() => _tabBar = v)),
    ],
    code:
        'Harbor(\n'
        '${_header ? '  top: [HarborDock.pier(child: Header())],\n' : ''}'
        '${_tabBar ? '  bottom: [HarborDock.quay(child: TabBar())],\n' : ''}'
        '  buoys: [\n'
        '    HarborBuoy(\n'
        '      alignment: Alignment.$_alignment,\n'
        '      margin: const EdgeInsets.all(${_f(_margin)}),\n'
        '      child: Fab(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborFairway(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[if (_header) _headerDock('Harbor')],
      bottom: <HarborDock>[if (_tabBar) _tabBarDock('HarborDock.quay', key: const ValueKey<String>('buoy tab bar'))],
      buoys: <HarborBuoy>[
        HarborBuoy(
          alignment: _alignments[_alignment]!,
          margin: EdgeInsets.all(_margin),
          child: const _BuoyTag(key: ValueKey<String>('free buoy'), label: 'HarborBuoy'),
        ),
      ],
      body: StageProbe(
        label: 'Harbor body',
        child: HarborFairway(slivers: <Widget>[_rows(24)]),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 2. HarborBuoy.anchored

enum _AnchorTo { dockButton, boat }

/// `HarborBuoy.anchored` + `HarborAnchor` + `HarborAnchorPoint`: a buoy moored by something.
class AnchoredBuoyEntry extends StatefulWidget {
  const AnchoredBuoyEntry({super.key});

  @override
  State<AnchoredBuoyEntry> createState() => _AnchoredBuoyEntryState();
}

class _AnchoredBuoyEntryState extends State<AnchoredBuoyEntry> {
  final HarborAnchor _dockAnchor = HarborAnchor(debugLabel: 'launch button');
  final HarborAnchor _boatAnchor = HarborAnchor(debugLabel: 'boat');
  HarborBuoySide _side = HarborBuoySide.above;
  double _gap = 8;
  double _overlap = 0;
  _AnchorTo _anchorTo = _AnchorTo.dockButton;

  /// Where the draggable boat is, as a fraction of the body.
  Offset _boat = const Offset(0.5, 0.45);

  @override
  void dispose() {
    _dockAnchor.dispose();
    _boatAnchor.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBuoy.anchored',
    realWorld:
        'A mooring buoy floats on the surface, but it is chained to an anchor dug into the seabed. It swings round its '
        'anchor with the wind and tide, and never drifts away from it.',
    inYourApp:
        'A bubble or tooltip that sits by a widget. Give a HarborAnchor to a HarborAnchorPoint round the widget (the '
        'anchor) and to the buoy (the chain). The buoy sits on its side of the anchor, gap away, and is kept in the '
        'clear water: drag the boat to the header and the bubble stops at the header instead of going under it.',
    art: const MooringBuoyArt(),
    controls: <Widget>[
      ChoiceControl<_AnchorTo>(
        label: 'anchor',
        values: _AnchorTo.values,
        value: _anchorTo,
        labelOf: (final _AnchorTo a) => a == _AnchorTo.boat ? 'draggable boat' : 'dock button',
        onChanged: (final _AnchorTo a) => setState(() => _anchorTo = a),
      ),
      ChoiceControl<HarborBuoySide>(
        label: 'side',
        values: HarborBuoySide.values,
        value: _side,
        labelOf: (final HarborBuoySide s) => s.name,
        onChanged: (final HarborBuoySide s) => setState(() => _side = s),
      ),
      SliderControl(label: 'gap', value: _gap, min: 0, max: 32, onChanged: (final double v) => setState(() => _gap = v)),
      SliderControl(label: 'overlap', value: _overlap, min: 0, max: 20, onChanged: (final double v) => setState(() => _overlap = v)),
    ],
    code:
        'final launch = HarborAnchor();\n\n'
        'Harbor(\n'
        '  bottom: [\n'
        '    HarborDock.quay(\n'
        '      child: Dock(child: HarborAnchorPoint(anchor: launch, child: LaunchButton())),\n'
        '    ),\n'
        '  ],\n'
        '  buoys: [\n'
        '    HarborBuoy.anchored(\n'
        '      anchor: ${_anchorTo == _AnchorTo.boat ? 'boat' : 'launch'},\n'
        '      side: HarborBuoySide.${_side.name},\n'
        '      gap: ${_f(_gap)},\n'
        '      overlap: ${_f(_overlap)},\n'
        '      child: SpeechBubble(),\n'
        '    ),\n'
        '  ],\n'
        '  body: Stack(children: [\n'
        '    Positioned(child: HarborAnchorPoint(anchor: boat, child: Boat())),\n'
        '  ]),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('HarborBuoy.anchored', key: const ValueKey<String>('anchored header'))],
      bottom: <HarborDock>[
        HarborDock.quay(
          backdrop: const ColoredBox(color: Palette.night),
          debugLabel: 'dock',
          child: SizedBox(
            height: 64,
            child: Center(
              child: HarborAnchorPoint(
                anchor: _dockAnchor,
                child: _StageButton(
                  key: const ValueKey<String>('anchor button'),
                  label: 'HarborAnchorPoint',
                  icon: Icons.anchor_rounded,
                  onPressed: () => setState(() => _anchorTo = _AnchorTo.dockButton),
                ),
              ),
            ),
          ),
        ),
      ],
      buoys: <HarborBuoy>[
        HarborBuoy.anchored(
          anchor: _anchorTo == _AnchorTo.boat ? _boatAnchor : _dockAnchor,
          side: _side,
          gap: _gap,
          overlap: _overlap,
          child: _SpeechBubble(key: const ValueKey<String>('anchored buoy'), side: _side, text: 'HarborBuoy.anchored'),
        ),
      ],
      body: _OpenWater(
        hint: 'Drag the boat around. Pick “draggable boat” to anchor the bubble to it.',
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints box) {
            const Size boat = Size(92, 56);
            return Stack(
              children: <Widget>[
                Positioned(
                  left: _boat.dx * box.maxWidth - boat.width / 2,
                  top: _boat.dy * box.maxHeight - boat.height / 2,
                  width: boat.width,
                  height: boat.height,
                  child: GestureDetector(
                    key: const ValueKey<String>('draggable anchor'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (final DragStartDetails _) => setState(() => _anchorTo = _AnchorTo.boat),
                    onPanUpdate: (final DragUpdateDetails d) => setState(() {
                      final double halfW = boat.width / 2 / box.maxWidth;
                      final double halfH = boat.height / 2 / box.maxHeight;
                      _boat = Offset(
                        (_boat.dx + d.delta.dx / box.maxWidth).clamp(halfW, 1 - halfW),
                        (_boat.dy + d.delta.dy / box.maxHeight).clamp(halfH, 1 - halfH),
                      );
                    }),
                    child: HarborAnchorPoint(
                      anchor: _boatAnchor,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Palette.foam.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Palette.brass, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: BoatArt(kind: BoatKind.trawler, hull: Palette.hulls[3], bob: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// A speech bubble whose tail points back at its anchor.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.side, required this.text});

  final HarborBuoySide side;
  final String text;

  static const double _tail = 9;

  @override
  Widget build(final BuildContext context) => CustomPaint(
    painter: _BubblePainter(side),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        12 + (side == HarborBuoySide.end ? _tail : 0),
        10 + (side == HarborBuoySide.below ? _tail : 0),
        12 + (side == HarborBuoySide.start ? _tail : 0),
        10 + (side == HarborBuoySide.above ? _tail : 0),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Menlo', color: Palette.night, fontWeight: FontWeight.w700, fontSize: 12)),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.side);

  final HarborBuoySide side;

  @override
  void paint(final Canvas canvas, final Size size) {
    const double t = _SpeechBubble._tail;
    final Rect body = Rect.fromLTRB(
      side == HarborBuoySide.end ? t : 0,
      side == HarborBuoySide.below ? t : 0,
      size.width - (side == HarborBuoySide.start ? t : 0),
      size.height - (side == HarborBuoySide.above ? t : 0),
    );
    final Path tail = switch (side) {
      HarborBuoySide.above => Path()
        ..moveTo(body.center.dx - t, body.bottom - 1)
        ..lineTo(body.center.dx, size.height)
        ..lineTo(body.center.dx + t, body.bottom - 1),
      HarborBuoySide.below => Path()
        ..moveTo(body.center.dx - t, body.top + 1)
        ..lineTo(body.center.dx, 0)
        ..lineTo(body.center.dx + t, body.top + 1),
      HarborBuoySide.start => Path()
        ..moveTo(body.right - 1, body.center.dy - t)
        ..lineTo(size.width, body.center.dy)
        ..lineTo(body.right - 1, body.center.dy + t),
      HarborBuoySide.end => Path()
        ..moveTo(body.left + 1, body.center.dy - t)
        ..lineTo(0, body.center.dy)
        ..lineTo(body.left + 1, body.center.dy + t),
    };
    final Paint fill = Paint()..color = Palette.sail;
    canvas
      ..drawShadow(Path()..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(14))), Colors.black, 4, false)
      ..drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(14)), fill)
      ..drawPath(tail..close(), fill);
  }

  @override
  bool shouldRepaint(final _BubblePainter oldDelegate) => oldDelegate.side != side;
}

// ---------------------------------------------------------------------------
// HarborPortalBuoy

/// `HarborPortalBuoy`: an anchored buoy opened from deep in the tree.
class PortalBuoyEntry extends StatefulWidget {
  const PortalBuoyEntry({super.key});

  @override
  State<PortalBuoyEntry> createState() => _PortalBuoyEntryState();
}

class _PortalBuoyEntryState extends State<PortalBuoyEntry> {
  static const int _rowCount = 12;

  final List<OverlayPortalController> _menus = List<OverlayPortalController>.generate(
    _rowCount,
    (final int i) => OverlayPortalController(debugLabel: 'row $i menu'),
  );
  HarborBuoySide _side = HarborBuoySide.below;
  bool _flips = true;

  void _toggle(final int row) {
    for (int i = 0; i < _menus.length; i++) {
      if (i == row) {
        _menus[i].toggle();
      } else {
        _menus[i].hide();
      }
    }
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborPortalBuoy',
    realWorld:
        'A dan buoy is a float with a flag on a pole, kept on deck to be thrown over the side. It goes in wherever the '
        'boat is, and floats on the open water clear of the boat.',
    inYourApp:
        'A menu or popover opened from a list row or a button deep in the page, or from another package, that cannot '
        'be listed in Harbor.buoys. It sits by its row in the clear water. Tap a row near the bottom: there is no room '
        'below it above the tab bar, so the menu flips above the row instead.',
    art: const DanBuoyArt(),
    controls: <Widget>[
      ChoiceControl<HarborBuoySide>(
        label: 'side',
        values: const <HarborBuoySide>[HarborBuoySide.above, HarborBuoySide.below],
        value: _side,
        labelOf: (final HarborBuoySide s) => s.name,
        onChanged: (final HarborBuoySide s) => setState(() => _side = s),
      ),
      ToggleControl(label: 'flips', value: _flips, onChanged: (final bool v) => setState(() => _flips = v)),
    ],
    code:
        'final menu = OverlayPortalController();\n\n'
        '// In a row, anywhere below the harbor:\n'
        'HarborPortalBuoy(\n'
        '  controller: menu,\n'
        '  side: HarborBuoySide.${_side.name},\n'
        '  flips: $_flips,\n'
        '  buoyBuilder: (context) => RowMenu(),\n'
        '  child: GestureDetector(onTap: menu.toggle, child: Row()),\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('HarborPortalBuoy')],
      bottom: <HarborDock>[_tabBarDock('HarborDock.quay', key: const ValueKey<String>('portal tab bar'))],
      body: HarborFairway(
        key: const ValueKey<String>('portal stage'),
        slivers: <Widget>[
          SliverList.builder(
            itemCount: _rowCount,
            itemBuilder: (final BuildContext context, final int i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(i),
              child: HarborPortalBuoy(
                controller: _menus[i],
                side: _side,
                flips: _flips,
                buoyBuilder: (final BuildContext context) =>
                    _BuoyTag(key: const ValueKey<String>('portal buoy'), label: 'Menu for row ${i + 1}'),
                child: StageRow(index: i),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 3. HarborBuoy(modal: true)

/// `HarborBuoy(modal: true)`: a buoy that hides the buoys listed before it.
class ModalBuoyEntry extends StatefulWidget {
  const ModalBuoyEntry({super.key});

  @override
  State<ModalBuoyEntry> createState() => _ModalBuoyEntryState();
}

class _ModalBuoyEntryState extends State<ModalBuoyEntry> {
  bool _launchUp = true;
  bool _modal = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBuoy(modal: true)',
    realWorld:
        'When the harbor master’s launch comes through with its blue light on, every other boat moves out of its way. '
        'While it is there, it is the only one in the channel.',
    inYourApp:
        'A menu or a panel that should be the only thing afloat while it is up. A modal buoy puts a barrier over the '
        'page, so a tap beside it or back closes it (through onDismiss) instead of reaching the page, and it hides every '
        'buoy listed before it (a tooltip, a floating button) until it goes. Buoys listed after it stay up.',
    art: const HarborLaunchArt(),
    controls: <Widget>[
      ToggleControl(label: 'launch up', value: _launchUp, onChanged: (final bool v) => setState(() => _launchUp = v)),
      ToggleControl(label: 'modal', value: _modal, onChanged: (final bool v) => setState(() => _modal = v)),
    ],
    code:
        'Harbor(\n'
        '  buoys: [\n'
        '    HarborBuoy(alignment: Alignment.bottomCenter, child: Tooltip()),\n'
        '${_launchUp ? (_modal ? '    HarborBuoy(modal: true, onDismiss: close, child: QuickActions()), // a barrier; hides the tooltip\n' : '    HarborBuoy(child: QuickActions()), // floats beside it\n') : ''}'
        '  ],\n'
        '  ...\n'
        ')',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('HarborBuoy(modal:)', key: const ValueKey<String>('modal header'))],
      bottom: <HarborDock>[_tabBarDock('HarborDock.quay', key: const ValueKey<String>('modal tab bar'))],
      buoys: <HarborBuoy>[
        const HarborBuoy(
          alignment: Alignment.bottomCenter,
          child: _BuoyTag(key: ValueKey<String>('listed first'), label: 'HarborBuoy (listed first)', color: Color(0xFF2E7D5B)),
        ),
        if (_launchUp)
          HarborBuoy(
            modal: _modal,
            onDismiss: _modal ? () => setState(() => _launchUp = false) : null,
            alignment: Alignment.center,
            child: _LaunchPanel(
              key: const ValueKey<String>('modal buoy'),
              modal: _modal,
              onClose: () => setState(() => _launchUp = false),
            ),
          ),
      ],
      body: Builder(
        builder: (final BuildContext context) => CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: HarborMoored(
                mooringLine: true,
                edges: const <HarborEdge>{HarborEdge.top, HarborEdge.start, HarborEdge.end},
                extra: const EdgeInsetsDirectional.only(top: 12),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _StageButton(
                    key: const ValueKey<String>('call the launch'),
                    label: 'Call the launch',
                    icon: Icons.local_police_rounded,
                    onPressed: () => setState(() => _launchUp = true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The harbor master's launch, as a panel of quick actions.
class _LaunchPanel extends StatelessWidget {
  const _LaunchPanel({super.key, required this.modal, required this.onClose});

  final bool modal;
  final VoidCallback onClose;

  @override
  Widget build(final BuildContext context) => Material(
    color: const Color(0xFF1E4E9C),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white, width: 1.5)),
    elevation: 6,
    child: SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.local_police_rounded, color: Color(0xFF9CC7FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HarborBuoy(modal: $modal)',
                    style: const TextStyle(fontFamily: 'Menlo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              modal ? 'Harbor master coming through. The buoys before me are hidden.' : 'Not modal: the buoys before me stay up.',
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const ValueKey<String>('launch away'),
                onPressed: onClose,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Stand down'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 4. HarborFlares.raise

const Map<HarborFlareSlot, String> _slotFlags = <HarborFlareSlot, String>{
  HarborFlareSlot.top: 'K',
  HarborFlareSlot.high: 'C',
  HarborFlareSlot.middle: 'D',
  HarborFlareSlot.low: 'U',
};

/// `HarborFlares.raise`: a transient buoy, raised in the port on top.
class FlaresEntry extends StatefulWidget {
  const FlaresEntry({super.key});

  @override
  State<FlaresEntry> createState() => _FlaresEntryState();
}

class _FlaresEntryState extends State<FlaresEntry> {
  HarborFlareTarget _target = HarborFlareTarget.topmost;
  HarborFlareSlot _last = HarborFlareSlot.low;

  void _raise(final BuildContext context, final HarborFlareSlot slot) {
    setState(() => _last = slot);
    HarborFlares.raise(
      context,
      slot: slot,
      target: _target,
      builder: (final BuildContext context) => _FlarePennant(slot: slot, target: _target),
    );
  }

  Widget _raiseButtons(final BuildContext context, {required final String prefix}) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      for (final HarborFlareSlot slot in HarborFlareSlot.values)
        _StageButton(
          key: ValueKey<String>('$prefix ${slot.name}'),
          label: slot.name,
          icon: Icons.flag_rounded,
          onPressed: () => _raise(context, slot),
        ),
    ],
  );

  void _openSheet(final BuildContext context) => unawaited(
    showHarborSheet<void>(
      context,
      builder: (final BuildContext context) => HarborSheet(
        debugLabel: 'flares sheet',
        surface: const Sailcloth(),
        header: const SheetHeader(key: ValueKey<String>('flares sheet header'), title: 'A sheet on top'),
        footer: const HarborMooringLine(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: StageMarker(key: ValueKey<String>('flares sheet footer'), label: 'sheet footer', color: Palette.sea),
          ),
        ),
        body: HarborFairway.box(
          shrinkWrap: true,
          child: HarborMooringLine(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Raise from here: topmost lands in this sheet’s clear water, above its footer; sea lands over everything, clear of the coast only.',
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.8), height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  _raiseButtons(context, prefix: 'sheet raise'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFlares.raise',
    realWorld:
        'A flare fired from a boat says one thing to everyone in sight, then burns out. By day ships say it with flags: '
        'each letter of the international code is its own flag, run up a halyard for others to read, and taken down '
        'once the message is passed.',
    inYourApp:
        'A toast. A flare is a buoy raised for a while in the clear water of the port on top: a page, or a sheet over the '
        'page. Its slot places it high or low in that water; topmost sends it to the sheet over the page, sea to the '
        'outermost harbor, clear of the coast only.',
    art: const SignalFlagsArt(),
    controls: <Widget>[
      ChoiceControl<HarborFlareTarget>(
        label: 'target',
        values: HarborFlareTarget.values,
        value: _target,
        labelOf: (final HarborFlareTarget t) => t.name,
        onChanged: (final HarborFlareTarget t) => setState(() => _target = t),
      ),
    ],
    code:
        'HarborFlares.raise(\n'
        '  context,\n'
        '  slot: HarborFlareSlot.${_last.name},\n'
        '  target: HarborFlareTarget.${_target.name},\n'
        '  builder: (context) => const Toast(\'Flags up\'),\n'
        ');',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('HarborFlares.raise')],
      bottom: <HarborDock>[_tabBarDock('HarborDock.quay', key: const ValueKey<String>('flares tab bar'))],
      body: Builder(
        builder: (final BuildContext context) => _OpenWater(
          child: HarborMoored(
            mooringLine: true,
            extra: const EdgeInsetsDirectional.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Raise a flare at each HarborFlareSlot:', style: TextStyle(color: Palette.foam.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                _raiseButtons(context, prefix: 'raise'),
                const SizedBox(height: 16),
                _StageButton(
                  key: const ValueKey<String>('open flares sheet'),
                  label: 'Open a sheet',
                  icon: Icons.vertical_align_top_rounded,
                  onPressed: () => _openSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A raised flare: two code flags and what it was raised with.
class _FlarePennant extends StatelessWidget {
  const _FlarePennant({required this.slot, required this.target});

  final HarborFlareSlot slot;
  final HarborFlareTarget target;

  @override
  Widget build(final BuildContext context) => Material(
    key: const ValueKey<String>('flare'),
    color: Palette.night.withValues(alpha: 0.94),
    shape: const StadiumBorder(side: BorderSide(color: Palette.brass, width: 1.5)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CodeFlag(letter: _slotFlags[slot]!),
          const SizedBox(width: 3),
          CodeFlag(letter: target == HarborFlareTarget.sea ? 'N' : 'A'),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${slot.name} · ${target.name}',
              style: const TextStyle(fontFamily: 'Menlo', color: Palette.foam, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 5. HarborSheet

/// `HarborSheet`: a content-sized sheet with a pier header and a floating footer.
class HarborSheetEntry extends StatefulWidget {
  const HarborSheetEntry({super.key});

  @override
  State<HarborSheetEntry> createState() => _HarborSheetEntryState();
}

class _HarborSheetEntryState extends State<HarborSheetEntry> {
  /// Bumped on every change, so an open sheet rebuilds with the controls.
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  bool _hasHeader = true;
  bool _hasFooter = true;
  HarborTideStance _footerTide = HarborTideStance.float;
  double _maxExtent = 90;
  double _rows = 3;

  @override
  void dispose() {
    _revision.dispose();
    super.dispose();
  }

  void _set(final VoidCallback change) {
    setState(change);
    _revision.value++;
  }

  Widget _footer(final BuildContext context) {
    final Widget button = HarborMooringLine(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: BrassAction(
          key: const ValueKey<String>('sheet footer'),
          label: 'Make sail',
          onPressed: () => HarborSheet.close(context),
        ),
      ),
    );
    if (_footerTide != HarborTideStance.dryDock) {
      return button;
    }
    // A dry dock holds the keyboard's ground: here a tray of flags to pick
    // from, which the keyboard takes the place of. The button above it never
    // moves when they trade.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        button,
        const SizedBox(height: 12),
        const HarborDryDock(child: _FlagTray()),
      ],
    );
  }

  String get _footerHint => switch (_footerTide) {
    HarborTideStance.float =>
      'float: drag the tide up and the Make sail button rides the keyboard, so it is always in reach.',
    HarborTideStance.pilings =>
      'pilings: the button stays where it is and the keyboard covers it; the rows end at the keyboard. For a '
          'footer you don\'t need while typing.',
    HarborTideStance.dryDock =>
      'dryDock: the flag tray holds the keyboard\'s ground. Drag the tide up: the keyboard takes the tray\'s place '
          'and the button above it doesn\'t move.',
  };

  Widget _sheet(final BuildContext context) => HarborSheet(
    debugLabel: 'HarborSheet',
    surface: const Sailcloth(),
    header: _hasHeader ? const SheetHeader(key: ValueKey<String>('sheet header'), title: 'HarborSheet') : null,
    footer: _hasFooter ? _footer(context) : null,
    footerTide: _footerTide,
    maxExtentFraction: _maxExtent / 100,
    body: HarborFairway.box(
      shrinkWrap: true,
      child: Column(
        key: const ValueKey<String>('sheet body'),
        children: <Widget>[for (int i = 0; i < _rows.round(); i++) StageRow(index: i)],
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSheet',
    // The whole phone: at a high maxExtent with many rows the sheet reaches up near the status bar,
    // and the button that hoists it is mid-page.
    realWorld:
        'On a sailboat the sheet is the line that trims a sail, run from the sail’s corner back to a winch in the '
        'cockpit. Hoisting and trimming the sail is how you make sail.',
    inYourApp:
        'A sheet as tall as its content, up to maxExtentFraction of the space above the keyboard, past which its body '
        'scrolls. It is a new port: its header is a pier its body sails under, its footer a quay that floats on the tide '
        'and clears the home indicator once. Drag the tide up to see the footer ride the keyboard.',
    art: const SailSheetArt(),
    controls: <Widget>[
      GuideHint(text: _footerHint),
      ToggleControl(label: 'header', value: _hasHeader, onChanged: (final bool v) => _set(() => _hasHeader = v)),
      ToggleControl(label: 'footer', value: _hasFooter, onChanged: (final bool v) => _set(() => _hasFooter = v)),
      ChoiceControl<HarborTideStance>(
        label: 'footerTide',
        values: HarborTideStance.values,
        value: _footerTide,
        labelOf: (final HarborTideStance s) => s.name,
        onChanged: (final HarborTideStance s) => _set(() => _footerTide = s),
      ),
      SliderControl(
        label: 'maxExtent %',
        value: _maxExtent,
        min: 30,
        max: 100,
        onChanged: (final double v) => _set(() => _maxExtent = v),
      ),
      SliderControl(label: 'rows', value: _rows, min: 1, max: 16, divisions: 15, onChanged: (final double v) => _set(() => _rows = v)),
    ],
    code:
        'showHarborSheet(\n'
        '  context,\n'
        '  builder: (context) => HarborSheet(\n'
        '${_hasHeader ? '    header: SheetHeader(title: \'HarborSheet\'),\n' : ''}'
        '${_hasFooter ? (_footerTide == HarborTideStance.dryDock ? '    footer: Column(children: [MakeSailButton(), HarborDryDock(child: FlagTray())]),\n' : '    footer: MakeSailButton(),\n') : ''}'
        '    footerTide: HarborTideStance.${_footerTide.name},\n'
        '    maxExtentFraction: ${_fraction(_maxExtent)},\n'
        '    body: HarborFairway.box(shrinkWrap: true, child: ${_rows.round()}Rows()),\n'
        '  ),\n'
        ');',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('A page')],
      body: Builder(
        builder: (final BuildContext context) => _OpenWater(
          child: Center(
            child: _StageButton(
              key: const ValueKey<String>('open sheet'),
              label: 'Hoist the HarborSheet',
              onPressed: () => unawaited(
                showHarborSheet<void>(
                  context,
                  builder: (final BuildContext context) => ListenableBuilder(
                    listenable: _revision,
                    builder: (final BuildContext context, final Widget? _) => _sheet(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 6. HarborSheet.draggable

/// `HarborSheet.draggable` + `HarborSheetExtent`: a sheet you haul up and down.
class DraggableSheetEntry extends StatefulWidget {
  const DraggableSheetEntry({super.key});

  @override
  State<DraggableSheetEntry> createState() => _DraggableSheetEntryState();
}

class _DraggableSheetEntryState extends State<DraggableSheetEntry> {
  // Percent, so the sliders read whole numbers.
  double _rest = 50;
  double _max = 88;
  double _min = 25;

  void _setRest(final double v) => setState(() {
    _rest = v;
    if (_max < _rest + 5) {
      _max = _rest + 5;
    }
    if (_min > _rest) {
      _min = _rest;
    }
  });

  void _setMax(final double v) => setState(() {
    _max = v;
    if (_rest > _max - 5) {
      _rest = _max - 5;
    }
    if (_min > _rest) {
      _min = _rest;
    }
  });

  void _setMin(final double v) => setState(() {
    _min = v;
    if (_rest < _min) {
      _rest = _min;
    }
    if (_max < _rest + 5) {
      _max = _rest + 5;
    }
  });

  void _open(final BuildContext context) {
    // The heights are taken when the sheet is hoisted.
    final HarborSheetExtent extent = HarborSheetExtent(rest: _rest / 100, max: _max / 100, min: _min / 100);
    unawaited(
      showHarborSheet<void>(
        context,
        builder: (final BuildContext context) => HarborSheet.draggable(
          debugLabel: 'HarborSheet.draggable',
          surface: const Sailcloth(),
          extent: extent,
          header: const SheetHeader(key: ValueKey<String>('drag header'), title: 'Haul me up'),
          builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
            controller: controller,
            slivers: <Widget>[_rows(30)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSheet.draggable',
    realWorld:
        'A sail is hauled up its mast on a halyard. In a blow you hoist it only partway and tie in a reef; in light '
        'air you hoist it to the top. Let the halyard go and the sail comes down.',
    inYourApp:
        'A sheet whose body is a list. It opens at its rest height, drags (by its header or its list) up to max, and '
        'closes when dragged below min. Heights are fractions of the space between the status bar and the keyboard. '
        'The heights are taken when the sheet is hoisted: change them, then hoist it again.',
    art: const HalyardArt(),
    controls: <Widget>[
      SliderControl(label: 'rest %', value: _rest, min: 20, max: 85, onChanged: _setRest),
      SliderControl(label: 'max %', value: _max, min: 30, max: 95, onChanged: _setMax),
      SliderControl(label: 'min %', value: _min, min: 5, max: 60, onChanged: _setMin),
    ],
    code:
        'showHarborSheet(\n'
        '  context,\n'
        '  builder: (context) => HarborSheet.draggable(\n'
        '    header: SheetHeader(title: \'Haul me up\'),\n'
        '    extent: const HarborSheetExtent(rest: ${_fraction(_rest)}, max: ${_fraction(_max)}, min: ${_fraction(_min)}),\n'
        '    builder: (context, controller) => HarborFairway(\n'
        '      controller: controller,\n'
        '      slivers: [boats],\n'
        '    ),\n'
        '  ),\n'
        ');',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('A page')],
      body: Builder(
        builder: (final BuildContext context) => _OpenWater(
          hint: 'Hoist the sheet, then drag its header up and down.',
          child: Center(
            child: _StageButton(
              key: const ValueKey<String>('open draggable sheet'),
              label: 'Hoist HarborSheet.draggable',
              onPressed: () => _open(context),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 7. showHarborSheet(breakwater: true)

/// `showHarborSheet(breakwater: true)`: a sheet the page keeps clear of.
class BreakwaterEntry extends StatefulWidget {
  const BreakwaterEntry({super.key});

  @override
  State<BreakwaterEntry> createState() => _BreakwaterEntryState();
}

class _BreakwaterEntryState extends State<BreakwaterEntry> {
  bool _breakwater = true;
  HarborSheetBarrier _barrier = HarborSheetBarrier.none;

  static const int _count = 14;

  void _open(final BuildContext context) => unawaited(
    showHarborSheet<void>(
      context,
      breakwater: _breakwater,
      barrier: _barrier,
      builder: (final BuildContext context) => HarborSheet(
        debugLabel: 'breakwater sheet',
        surface: const Sailcloth(),
        header: const SheetHeader(key: ValueKey<String>('breakwater sheet header'), title: 'The breakwater'),
        body: HarborFairway.box(
          shrinkWrap: true,
          child: HarborMooringLine(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _breakwater
                    ? 'breakwater: true. Scroll the list: its last row comes to rest above this sheet.'
                    : 'breakwater: false. Scroll the list: its last rows stay hidden under this sheet.',
                style: TextStyle(color: Palette.foam.withValues(alpha: 0.85), height: 1.4),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'showHarborSheet(breakwater: true)',
    // The whole phone: the button that opens the sheet is in the header, the list it shelters at the
    // bottom.
    realWorld:
        'A breakwater is a long wall of rock built out from the shore. The swell breaks on its far side, and the water '
        'behind it stays calm, so boats can lie there in shelter.',
    inYourApp:
        'A sheet that reports how far it covers the page that opened it, as it slides in, is dragged and slides out. '
        'The page keeps clear of it: a fairway’s last row stays reachable above the sheet, a lifted canvas element '
        'stays in sight. With barrier none, the page stays live under the sheet.',
    art: const BreakwaterArt(),
    controls: <Widget>[
      ToggleControl(label: 'breakwater', value: _breakwater, onChanged: (final bool v) => setState(() => _breakwater = v)),
      ChoiceControl<HarborSheetBarrier>(
        label: 'barrier',
        values: HarborSheetBarrier.values,
        value: _barrier,
        labelOf: (final HarborSheetBarrier b) => b.name,
        onChanged: (final HarborSheetBarrier b) => setState(() => _barrier = b),
      ),
    ],
    code:
        'showHarborSheet(\n'
        '  context,\n'
        '  breakwater: $_breakwater,\n'
        '  barrier: HarborSheetBarrier.${_barrier.name},\n'
        '  builder: (context) => HarborSheet(header: title, body: note),\n'
        ');\n\n'
        '// The page that opened it:\n'
        'HarborFairway(slivers: [boats]) // ${_breakwater ? 'its last row rests above the sheet' : 'its last rows end under the sheet'}',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        _headerDock(
          'Moorings',
          trailing: Builder(
            builder: (final BuildContext context) => _StageButton(
              key: const ValueKey<String>('open breakwater sheet'),
              label: 'Open sheet',
              icon: Icons.waves_rounded,
              onPressed: () => _open(context),
            ),
          ),
        ),
      ],
      body: StageProbe(
        label: 'The list, under the sheet',
        child: HarborFairway(key: const ValueKey<String>('breakwater list'), slivers: <Widget>[_rows(_count)]),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 8. showHarborDialog(inheritClearWater:)

/// `showHarborDialog(inheritClearWater:)`: a dialog that keeps clear of the page's docks.
class DialogEntry extends StatefulWidget {
  const DialogEntry({super.key});

  @override
  State<DialogEntry> createState() => _DialogEntryState();
}

class _DialogEntryState extends State<DialogEntry> {
  bool _inherit = true;

  void _open(final BuildContext context) => unawaited(
    showHarborDialog<void>(
      context,
      inheritClearWater: _inherit,
      // The stage's own navigator, so the dialog opens inside the phone.
      useRootNavigator: false,
      builder: (final BuildContext context) => const HarborMoored(
        extra: EdgeInsetsDirectional.all(10),
        child: _CallBox(key: ValueKey<String>('call box')),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'showHarborDialog(inheritClearWater:)',
    realWorld:
        'The harbor master works from an office on the quay. You call in on the radio, or speak through the window, '
        'and the answer comes from between the roof and the sill.',
    inYourApp:
        'A dialog is a new port: by default it sees only the coast, so it may cover the page’s header and composer. '
        'With inheritClearWater, it sees the page’s docks as coast too, and stays between them: a menu opened from a '
        'message stays between the header and the composer.',
    art: const HarborOfficeArt(),
    controls: <Widget>[
      ToggleControl(label: 'inheritClearWater', value: _inherit, onChanged: (final bool v) => setState(() => _inherit = v)),
    ],
    code:
        'showHarborDialog(\n'
        '  context, // inside the page\'s Harbor\n'
        '  inheritClearWater: $_inherit,\n'
        '  builder: (context) => const HarborMoored(\n'
        '    extra: EdgeInsetsDirectional.all(10),\n'
        '    child: CallBox(),\n'
        '  ),\n'
        ');',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[_headerDock('Harbor master', key: const ValueKey<String>('office header'))],
      bottom: <HarborDock>[_tabBarDock('Composer (quay)', key: const ValueKey<String>('office footer'))],
      body: Builder(
        builder: (final BuildContext context) => _OpenWater(
          child: Center(
            child: _StageButton(
              key: const ValueKey<String>('open dialog'),
              label: 'Call the harbor master',
              icon: Icons.settings_input_antenna_rounded,
              onPressed: () => _open(context),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The radio call box: a card that fills the clear water it is given.
class _CallBox extends StatelessWidget {
  const _CallBox({super.key});

  @override
  Widget build(final BuildContext context) => Material(
    color: const Color(0xFF263D4F),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Palette.brass, width: 1.5)),
    elevation: 8,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.settings_input_antenna_rounded, color: Palette.brass),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'showHarborDialog',
                  style: TextStyle(fontFamily: 'Menlo', color: Palette.foam, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Palette.night, borderRadius: BorderRadius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Channel 16. Harbor master here, go ahead.\n\n'
                  'This card fills the clear water it was given. Its top and bottom show where that water ends.',
                  style: TextStyle(color: Color(0xFF9CCC65), fontFamily: 'Menlo', fontSize: 12, height: 1.45),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          BrassAction(
            key: const ValueKey<String>('over and out'),
            label: 'Over and out',
            icon: Icons.call_end_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 9. HarborLighthouse.reveal + HarborBeacon(keepInSight:)

/// `HarborLighthouse.reveal` + `HarborBeacon(keepInSight:)`: a field kept in sight as the keyboard rises.
class KeepInSightEntry extends StatefulWidget {
  const KeepInSightEntry({super.key});

  @override
  State<KeepInSightEntry> createState() => _KeepInSightEntryState();
}

class _KeepInSightEntryState extends State<KeepInSightEntry> {
  final FocusNode _focus = FocusNode(debugLabel: 'beacon field');
  final GlobalKey _field = GlobalKey(debugLabel: 'beacon field');
  bool _keepInSight = true;
  bool _onlyWhileFocused = true;
  double _clearance = 16;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _reveal() {
    final BuildContext? field = _field.currentContext;
    if (field != null) {
      HarborLighthouse.reveal(field, clearance: _clearance);
    }
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBeacon(keepInSight:)',
    // The whole phone: the reveal button is in the header, the field and the keyboard at the bottom.
    realWorld:
        'A lighthouse sweeps its beam out over the water, and when it falls on a boat the boat stands out in the dark. '
        'Its keeper’s job is to keep ships in sight of the light.',
    inYourApp:
        'HarborLighthouse.reveal scrolls a widget into sight, clearance clear of the docks and the keyboard. A '
        'HarborBeacon with keepInSight does it for you whenever the keyboard rises or the bottom grows; with '
        'onlyWhileFocused, only while focus is inside it. Tap the field, then raise the tide.',
    art: const LighthouseBeamArt(),
    controls: <Widget>[
      ToggleControl(label: 'keepInSight', value: _keepInSight, onChanged: (final bool v) => setState(() => _keepInSight = v)),
      ToggleControl(
        label: 'onlyWhileFocused',
        value: _onlyWhileFocused,
        onChanged: (final bool v) => setState(() => _onlyWhileFocused = v),
      ),
      SliderControl(label: 'clearance', value: _clearance, min: 0, max: 48, onChanged: (final double v) => setState(() => _clearance = v)),
    ],
    code:
        'HarborFairway(slivers: [\n'
        '  boats,\n'
        '  SliverToBoxAdapter(\n'
        '    child: HarborBeacon(\n'
        '      keepInSight: $_keepInSight,\n'
        '      onlyWhileFocused: $_onlyWhileFocused,\n'
        '      clearance: ${_f(_clearance)},\n'
        '      child: Field(),\n'
        '    ),\n'
        '  ),\n'
        '])\n\n'
        '// Or by hand:\n'
        'HarborLighthouse.reveal(fieldContext, clearance: ${_f(_clearance)});',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        _headerDock(
          'A fairway',
          wake: const HarborWake.fade(length: 12),
          key: const ValueKey<String>('reveal header'),
          trailing: _StageButton(
            key: const ValueKey<String>('reveal'),
            label: 'reveal',
            icon: Icons.flare_rounded,
            onPressed: _reveal,
          ),
        ),
      ],
      body: StageProbe(
        label: 'Fairway (body ends at the waterline)',
        child: HarborFairway(
          key: const ValueKey<String>('reveal fairway'),
          slivers: <Widget>[
            _rows(9),
            SliverToBoxAdapter(
              child: HarborMooringLine(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: HarborBeacon(
                    keepInSight: _keepInSight,
                    onlyWhileFocused: _onlyWhileFocused,
                    clearance: _clearance,
                    child: KeyedSubtree(
                      key: const ValueKey<String>('beacon field'),
                      child: _FocusField(key: _field, focusNode: _focus),
                    ),
                  ),
                ),
              ),
            ),
            _rows(6, from: 9),
          ],
        ),
      ),
    ),
  );
}

/// A focusable box that looks like a text field, without a real keyboard
/// (the stage's tide is the keyboard).
class _FocusField extends StatelessWidget {
  const _FocusField({super.key, required this.focusNode});

  final FocusNode focusNode;

  @override
  Widget build(final BuildContext context) => Focus(
    focusNode: focusNode,
    child: GestureDetector(
      onTap: focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (final BuildContext context, final Widget? _) {
          final bool focused = focusNode.hasFocus;
          return Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Palette.night.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: focused ? Palette.brass : Palette.foam.withValues(alpha: 0.4), width: focused ? 2 : 1),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.edit_rounded, size: 18, color: focused ? Palette.brass : Palette.foam.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    focused ? 'HarborBeacon field' : 'Tap me, then raise the tide',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Palette.foam.withValues(alpha: focused ? 1 : 0.6)),
                  ),
                ),
                if (focused) Container(width: 2, height: 20, margin: const EdgeInsets.only(left: 2), color: Palette.brass),
              ],
            ),
          );
        },
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 10. HarborBeacon(onObscured:)

/// `HarborBeacon(onObscured:)`: how much of a widget the docks cover.
class ObscuredBeaconEntry extends StatefulWidget {
  const ObscuredBeaconEntry({super.key});

  @override
  State<ObscuredBeaconEntry> createState() => _ObscuredBeaconEntryState();
}

class _ObscuredBeaconEntryState extends State<ObscuredBeaconEntry> {
  final ValueNotifier<double> _covered = ValueNotifier<double>(0);
  bool _startsInOpenWater = true;

  @override
  void dispose() {
    _covered.dispose();
    super.dispose();
  }

  Widget _readout({final Key? key}) => ValueListenableBuilder<double>(
    valueListenable: _covered,
    builder: (final BuildContext context, final double covered, final Widget? _) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Palette.brass, borderRadius: BorderRadius.circular(10)),
      child: Text(
        'covered ${(covered * 100).round()}%',
        style: const TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Palette.night, fontWeight: FontWeight.w700),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborBeacon(onObscured:)',
    // The top of the phone: the hero slides under the header, whose title and readout answer it.
    focus: const StageFocus.top(500),
    realWorld:
        'Sailing along a coast, you watch a harbor light slide behind a headland: first its foot goes, then half the '
        'tower, then the light itself. How much is hidden tells you where you are.',
    inYourApp:
        'A beacon that reports how much of itself the docks on its edge cover, from 0 in clear water to 1 under them. '
        'Scroll the hero title under the header and hand off to the header’s own title as it goes.',
    art: const HeadlandBeaconArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'startsInOpenWater',
        value: _startsInOpenWater,
        onChanged: (final bool v) => setState(() => _startsInOpenWater = v),
      ),
      Padding(padding: const EdgeInsets.only(top: 4), child: Align(alignment: Alignment.centerLeft, child: _readout())),
    ],
    code:
        'final covered = ValueNotifier<double>(0);\n\n'
        'HarborBeacon(\n'
        '  onObscured: (v) => covered.value = v, // 0 clear, 1 under the header\n'
        '  child: HeroTitle(),\n'
        ')\n\n'
        '// In the header:\n'
        'ValueListenableBuilder(\n'
        '  valueListenable: covered,\n'
        '  builder: (context, v, _) => Opacity(opacity: v, child: Title()),\n'
        ')\n\n'
        'HarborFairway(startsInOpenWater: $_startsInOpenWater, slivers: [hero, ...])',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        HarborDock.pier(
          wake: const HarborWake.fade(length: 12),
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.78)),
          debugLabel: 'header',
          child: SizedBox(
            key: const ValueKey<String>('obscured header'),
            height: 52,
            child: HarborMooringLine(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _covered,
                      builder: (final BuildContext context, final double covered, final Widget? _) => Opacity(
                        opacity: covered,
                        child: const Text(
                          'The Lighthouse',
                          key: ValueKey<String>('header title'),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Palette.foam),
                        ),
                      ),
                    ),
                  ),
                  _readout(key: const ValueKey<String>('covered readout')),
                ],
              ),
            ),
          ),
        ),
      ],
      body: HarborFairway(
        key: const ValueKey<String>('hero fairway'),
        startsInOpenWater: _startsInOpenWater,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const LighthouseBeamArt(),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: HarborMooringLine(
                      child: HarborBeacon(
                        onObscured: (final double v) => _covered.value = v,
                        child: const Text(
                          'The Lighthouse',
                          key: ValueKey<String>('hero title'),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: <Shadow>[Shadow(blurRadius: 8, color: Colors.black)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _rows(20),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 11. HarborLighthouseRegion + HarborBeacon(lift: true)

/// `HarborLighthouseRegion` + `HarborBeacon(lift: true)`: content lifted clear of a sheet.
class LiftEntry extends StatefulWidget {
  const LiftEntry({super.key});

  @override
  State<LiftEntry> createState() => _LiftEntryState();
}

class _LiftEntryState extends State<LiftEntry> {
  bool _lift = true;
  double _clearance = 40;
  bool _hold = false;

  void _open(final BuildContext context) => unawaited(
    showHarborSheet<void>(
      context,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => HarborSheet(
        debugLabel: 'lift sheet',
        surface: const Sailcloth(),
        header: const SheetHeader(key: ValueKey<String>('lift sheet header'), title: 'A breakwater sheet'),
        body: HarborFairway.box(
          shrinkWrap: true,
          child: Column(children: <Widget>[for (int i = 0; i < 3; i++) StageRow(index: i)]),
        ),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborLighthouseRegion',
    // The whole phone: the button that opens the sheet is in the header, the boat it lifts at the
    // bottom.
    realWorld:
        'A boat lift is a tall gantry on wheels that straddles a slip. Slings go under the hull, and the boat is raised '
        'clear of the water, just as high as it needs to be.',
    inYourApp:
        'A region that lifts its content when a HarborBeacon(lift: true) inside it would be covered by what covers the '
        'bottom (a breakwater sheet, the keyboard): up just far enough to keep it clearance clear, and back down when '
        'the cover goes. holdPosition keeps it where it is, for an element being dragged.',
    art: const BoatLiftArt(),
    controls: <Widget>[
      ToggleControl(label: 'lift', value: _lift, onChanged: (final bool v) => setState(() => _lift = v)),
      SliderControl(label: 'clearance', value: _clearance, min: 0, max: 120, onChanged: (final double v) => setState(() => _clearance = v)),
      ToggleControl(label: 'holdPosition', value: _hold, onChanged: (final bool v) => setState(() => _hold = v)),
    ],
    code:
        'HarborLighthouseRegion(\n'
        '  child: Stack(children: [\n'
        '    Positioned(\n'
        '      bottom: 60,\n'
        '      child: HarborBeacon(\n'
        '        lift: $_lift,\n'
        '        clearance: ${_f(_clearance)},\n'
        '        holdPosition: $_hold,\n'
        '        child: Boat(),\n'
        '      ),\n'
        '    ),\n'
        '  ]),\n'
        ')\n\n'
        'showHarborSheet(context, breakwater: true, barrier: HarborSheetBarrier.none, builder: ...);',
    stage: (final BuildContext context) => Harbor(
      top: <HarborDock>[
        _headerDock(
          'A canvas',
          trailing: Builder(
            builder: (final BuildContext context) => _StageButton(
              key: const ValueKey<String>('open lift sheet'),
              label: 'Open sheet',
              icon: Icons.waves_rounded,
              onPressed: () => _open(context),
            ),
          ),
        ),
      ],
      body: _OpenWater(
        hint: 'Open the breakwater sheet: the boat rises clearance clear of it.',
        child: HarborLighthouseRegion(
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Center(
                  child: HarborBeacon(
                    lift: _lift,
                    clearance: _clearance,
                    holdPosition: _hold,
                    child: Container(
                      key: const ValueKey<String>('lift boat'),
                      width: 150,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Palette.foam.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Palette.brass, width: 1.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(height: 60, child: BoatArt(kind: BoatKind.yacht, hull: Palette.hulls[3], bob: false)),
                          const SizedBox(height: 4),
                          const Text(
                            'HarborBeacon(lift:)',
                            style: TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Palette.foam, fontWeight: FontWeight.w700),
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
      ),
    ),
  );
}

/// The flags a dry-docked sheet footer offers while the keyboard is down.
class _FlagTray extends StatelessWidget {
  const _FlagTray();

  static const List<String> _letters = <String>['A', 'C', 'D', 'E', 'F', 'K', 'N', 'U'];

  @override
  Widget build(final BuildContext context) => ColoredBox(
    key: const ValueKey<String>('flag tray'),
    color: Palette.deepSea,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: 18,
          runSpacing: 16,
          children: <Widget>[for (final String letter in _letters) CodeFlag(letter: letter, width: 54, height: 40)],
        ),
      ),
    ),
  );
}
