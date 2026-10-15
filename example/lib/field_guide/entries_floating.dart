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

/// Floats, toasts, sheets and dialogs, and keeping things in sight: what floats
/// in the room, the pages that open over a page, and keeping things in sight.
final List<GuideEntry> floatingEntries = <GuideEntry>[
  GuideEntry(
    id: 'buoy',
    className: 'HarborFloat',
    group: GuideGroup.floating,
    realWorld: 'Like a buoy: it floats free in the room',
    art: (final BuildContext context) => const HarborBuoyArt(),
    page: (final BuildContext context) => const HarborFloatEntry(),
  ),
  GuideEntry(
    id: 'buoy-anchored',
    className: 'HarborFloat + HarborAnchored',
    group: GuideGroup.floating,
    realWorld: 'Like a mooring buoy: chained to its anchor',
    art: (final BuildContext context) => const MooringBuoyArt(),
    page: (final BuildContext context) => const AnchoredFloatEntry(),
  ),
  GuideEntry(
    id: 'buoy-modal',
    className: 'HarborFloat(barrier:)',
    group: GuideGroup.floating,
    realWorld: 'Like the harbor master’s launch: the others clear its way',
    art: (final BuildContext context) => const HarborLaunchArt(),
    page: (final BuildContext context) => const ModalFloatEntry(),
  ),
  GuideEntry(
    id: 'buoy-portal',
    className: 'HarborPopover',
    group: GuideGroup.floating,
    realWorld: 'Like a dan buoy: thrown in wherever the boat is',
    art: (final BuildContext context) => const DanBuoyArt(),
    page: (final BuildContext context) => const PopoverEntry(),
  ),
  GuideEntry(
    id: 'signals',
    className: 'HarborToasts.show',
    group: GuideGroup.floating,
    realWorld: 'Like signal flags: run up for a while, then down',
    art: (final BuildContext context) => const SignalFlagsArt(),
    page: (final BuildContext context) => const ToastsEntry(),
  ),
  GuideEntry(
    id: 'sheet',
    className: 'HarborSheet',
    group: GuideGroup.sheets,
    realWorld: 'Like a sail and its sheet: as big as it needs',
    art: (final BuildContext context) => const SailSheetArt(),
    page: (final BuildContext context) => const HarborSheetEntry(),
  ),
  GuideEntry(
    id: 'sheet-draggable',
    className: 'HarborSheet.draggable',
    group: GuideGroup.sheets,
    realWorld: 'Like a sail on a halyard: hauled up, reefed or full',
    art: (final BuildContext context) => const HalyardArt(),
    page: (final BuildContext context) => const DraggableSheetEntry(),
  ),
  GuideEntry(
    id: 'sheet-breakwater',
    className: 'showHarborSheet(coversPage: true)',
    group: GuideGroup.sheets,
    realWorld: 'Like a breakwater: the page keeps clear behind it',
    art: (final BuildContext context) => const BreakwaterArt(),
    page: (final BuildContext context) => const CoversPageEntry(),
  ),
  GuideEntry(
    id: 'dialog',
    className: 'showHarborDialog(inheritRoom:)',
    group: GuideGroup.sheets,
    realWorld: 'Like the harbor master’s window: it answers from the room',
    art: (final BuildContext context) => const HarborOfficeArt(),
    page: (final BuildContext context) => const DialogEntry(),
  ),
  GuideEntry(
    id: 'lighthouse-reveal',
    className: 'HarborKeepInSight(keepInSight:)',
    group: GuideGroup.lighthouse,
    realWorld: 'Like a lighthouse beam: it keeps a boat in sight',
    art: (final BuildContext context) => const LighthouseBeamArt(),
    page: (final BuildContext context) => const KeepInSightEntry(),
  ),
  GuideEntry(
    id: 'beacon-obscured',
    className: 'HarborKeepInSight(onObscured:)',
    group: GuideGroup.lighthouse,
    realWorld: 'Like a light behind a headland: how much is hidden',
    art: (final BuildContext context) => const HeadlandBeaconArt(),
    page: (final BuildContext context) => const ObscuredEntry(),
  ),
  GuideEntry(
    id: 'lighthouse-region',
    className: 'HarborKeepInSightRegion',
    group: GuideGroup.lighthouse,
    realWorld: 'Like a boat lift: raised just clear of what covers it',
    art: (final BuildContext context) => const BoatLiftArt(),
    page: (final BuildContext context) => const LiftEntry(),
  ),
];

// ---------------------------------------------------------------------------
// Shared stage parts.

/// The header every demo here puts on its top edge: a frosted overlay bar naming the class.
HarborBar _headerBar(
  final String title, {
  final HarborEdgeEffect edgeEffect = HarborEdgeEffect.none,
  final Widget? trailing,
  final Key? key,
}) => HarborBar.overlay(
  edgeEffect: edgeEffect,
  backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.82)),
  debugLabel: 'header',
  child: KeyedSubtree(
    key: key,
    child: trailing == null
        ? StageHeader(title: title)
        : SizedBox(
            height: 52,
            child: HarborClear.rowInsets(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Menlo',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Palette.foam,
                      ),
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
  ),
);

/// A bottom solid bar: a tab bar or composer.
HarborBar _bottomBar(final String label, {final Key? key}) => HarborBar.solid(
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
    label: Text(
      label,
      style: const TextStyle(fontFamily: 'Menlo', fontSize: 12, fontWeight: FontWeight.w700),
    ),
    style: FilledButton.styleFrom(
      backgroundColor: Palette.brass,
      foregroundColor: Palette.night,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minimumSize: const Size(0, 40),
    ),
  );
}

/// A float on the stage: a red pill with a can buoy drawn on it.
class _FloatTag extends StatelessWidget {
  const _FloatTag({super.key, required this.label, this.color = Palette.buoyRed});

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
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Menlo',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The sea backdrop for a body that has no list in it.
class _SeaBackdrop extends StatelessWidget {
  const _SeaBackdrop({this.hint, this.child});

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
          HarborClear(
            rowInsets: true,
            padding: const EdgeInsetsDirectional.only(top: 12),
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
// 1. HarborFloat

const Map<String, Alignment> _alignments = <String, Alignment>{
  'topCenter': Alignment.topCenter,
  'topRight': Alignment.topRight,
  'center': Alignment.center,
  'bottomLeft': Alignment.bottomLeft,
  'bottomCenter': Alignment.bottomCenter,
  'bottomRight': Alignment.bottomRight,
};

/// `HarborFloat`: something floating in the room.
class HarborFloatEntry extends StatefulWidget {
  const HarborFloatEntry({super.key});

  @override
  State<HarborFloatEntry> createState() => _HarborFloatEntryState();
}

class _HarborFloatEntryState extends State<HarborFloatEntry> {
  String _alignment = 'bottomRight';
  double _margin = 16;
  bool _header = true;
  bool _tabBar = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFloat',
    tryThis: const <TryStep>[
      TryStep(
        'Pick alignment: topCenter, then bottomLeft',
        'The float sits just under the header, then just above the tab bar: it floats in the room between the bars.',
      ),
      TryStep(
        'Drag margin to 48',
        'The float moves 48 points in from the tab bar and the screen edge: margin is kept inside the room.',
      ),
      TryStep(
        'Switch off tab bar (solid)',
        'The float drops to just above the home indicator: with no solid bar, the room runs down to the system edge.',
      ),
      TryStep(
        'Switch tab bar (solid) back on and show the keyboard',
        'The float moves up and stays margin above the keyboard: the keyboard becomes the floor of the room.',
      ),
      TryStep(
        'Pick alignment: topCenter, switch off header (overlay)',
        'The float rises to just under the status bar: without the overlay bar, the room starts at the system edge.',
      ),
    ],
    realWorld:
        'A buoy floats on its own in open water, away from the quays and piers, so every boat can see it. Nothing is '
        'built over it, and it never runs aground on the shore.',
    inYourApp:
        'A floating button, a bubble or a menu. It sits at its alignment in the room, the rectangle no system edge, '
        'bar or keyboard covers, so it clears the status bar, your header, your tab bar and the keyboard without '
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
      SliderControl(
        label: 'margin',
        value: _margin,
        min: 0,
        max: 48,
        onChanged: (final double v) => setState(() => _margin = v),
      ),
      ToggleControl(
        label: 'header (overlay)',
        value: _header,
        onChanged: (final bool v) => setState(() => _header = v),
      ),
      ToggleControl(label: 'tab bar (solid)', value: _tabBar, onChanged: (final bool v) => setState(() => _tabBar = v)),
    ],
    code:
        'HarborFrame(\n'
        '${_header ? '  top: [HarborBar.overlay(child: Header())],\n' : ''}'
        '${_tabBar ? '  bottom: [HarborBar.solid(child: TabBar())],\n' : ''}'
        '  floats: [\n'
        '    HarborFloat(\n'
        '      placement: HarborAligned(\n'
        '        alignment: Alignment.$_alignment,\n'
        '        margin: const EdgeInsets.all(${_f(_margin)}),\n'
        '      ),\n'
        '      child: Fab(),\n'
        '    ),\n'
        '  ],\n'
        '  body: HarborScrollView(slivers: [boats]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[if (_header) _headerBar('HarborFrame')],
      bottom: <HarborBar>[if (_tabBar) _bottomBar('HarborBar.solid', key: const ValueKey<String>('float tab bar'))],
      floats: <HarborFloat>[
        HarborFloat(
          placement: HarborAligned(alignment: _alignments[_alignment]!, margin: EdgeInsets.all(_margin)),
          child: const _FloatTag(key: ValueKey<String>('free float'), label: 'HarborFloat'),
        ),
      ],
      body: StageProbe(
        label: 'frame body',
        child: HarborScrollView(slivers: <Widget>[_rows(24)]),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 2. HarborFloat + HarborAnchored

enum _AnchorTo { barButton, boat }

/// `HarborFloat` + `HarborAnchored` + `HarborAnchor` + `HarborAnchorPoint`: a float anchored to something.
class AnchoredFloatEntry extends StatefulWidget {
  const AnchoredFloatEntry({super.key});

  @override
  State<AnchoredFloatEntry> createState() => _AnchoredFloatEntryState();
}

class _AnchoredFloatEntryState extends State<AnchoredFloatEntry> {
  final HarborAnchor _barAnchor = HarborAnchor(debugLabel: 'launch button');
  final HarborAnchor _boatAnchor = HarborAnchor(debugLabel: 'boat');
  HarborAnchorSide _side = HarborAnchorSide.above;
  double _gap = 8;
  double _overlap = 0;
  _AnchorTo _anchorTo = _AnchorTo.barButton;

  /// Where the draggable boat is, as a fraction of the body.
  Offset _boat = const Offset(0.5, 0.45);

  @override
  void dispose() {
    _barAnchor.dispose();
    _boatAnchor.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFloat + HarborAnchored',
    tryThis: const <TryStep>[
      TryStep(
        'Drag the boat around the water',
        'The bubble follows it, gap above, and anchor switches to draggable boat: the float is anchored to its HarborAnchorPoint.',
      ),
      TryStep(
        'Pick side: below, then start, then end',
        'The bubble moves round to that side of the boat, its tail pointing back at it.',
      ),
      TryStep(
        'Drag gap to 32, then overlap to 20',
        'gap pushes the bubble away from the boat; overlap pulls it back toward it, over the gap.',
      ),
      TryStep(
        'Pick side: above, drag the boat up into the header',
        'The boat slides under the header but the bubble stops just below it: the float stays in the room.',
      ),
      TryStep(
        'Tap HarborAnchorPoint in the bottom bar',
        'The bubble goes back above the bar button: the same float, given the other anchor.',
      ),
    ],
    realWorld:
        'A mooring buoy floats on the surface, but it is chained to an anchor dug into the seabed. It swings round its '
        'anchor with the wind and tide, and never drifts away from it.',
    inYourApp:
        'A bubble or tooltip that sits by a widget. Give a HarborAnchor to a HarborAnchorPoint round the widget and to '
        'the float\'s HarborAnchored placement. The float sits on its side of the anchor, gap away, and is kept in the '
        'room: drag the boat to the header and the bubble stops at the header instead of going under it.',
    art: const MooringBuoyArt(),
    controls: <Widget>[
      ChoiceControl<_AnchorTo>(
        label: 'anchor',
        values: _AnchorTo.values,
        value: _anchorTo,
        labelOf: (final _AnchorTo a) => a == _AnchorTo.boat ? 'draggable boat' : 'bar button',
        onChanged: (final _AnchorTo a) => setState(() => _anchorTo = a),
      ),
      ChoiceControl<HarborAnchorSide>(
        label: 'side',
        values: HarborAnchorSide.values,
        value: _side,
        labelOf: (final HarborAnchorSide s) => s.name,
        onChanged: (final HarborAnchorSide s) => setState(() => _side = s),
      ),
      SliderControl(
        label: 'gap',
        value: _gap,
        min: 0,
        max: 32,
        onChanged: (final double v) => setState(() => _gap = v),
      ),
      SliderControl(
        label: 'overlap',
        value: _overlap,
        min: 0,
        max: 20,
        onChanged: (final double v) => setState(() => _overlap = v),
      ),
    ],
    code:
        'final launch = HarborAnchor();\n\n'
        'HarborFrame(\n'
        '  bottom: [\n'
        '    HarborBar.solid(\n'
        '      child: BottomBar(child: HarborAnchorPoint(anchor: launch, child: LaunchButton())),\n'
        '    ),\n'
        '  ],\n'
        '  floats: [\n'
        '    HarborFloat(\n'
        '      placement: HarborAnchored(\n'
        '        ${_anchorTo == _AnchorTo.boat ? 'boat' : 'launch'},\n'
        '        side: HarborAnchorSide.${_side.name},\n'
        '        gap: ${_f(_gap)},\n'
        '        overlap: ${_f(_overlap)},\n'
        '      ),\n'
        '      child: SpeechBubble(),\n'
        '    ),\n'
        '  ],\n'
        '  body: Stack(children: [\n'
        '    Positioned(child: HarborAnchorPoint(anchor: boat, child: Boat())),\n'
        '  ]),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('HarborFloat + HarborAnchored', key: const ValueKey<String>('anchored header'))],
      bottom: <HarborBar>[
        HarborBar.solid(
          backdrop: const ColoredBox(color: Palette.night),
          debugLabel: 'bottom bar',
          child: SizedBox(
            height: 64,
            child: Center(
              child: HarborAnchorPoint(
                anchor: _barAnchor,
                child: _StageButton(
                  key: const ValueKey<String>('anchor button'),
                  label: 'HarborAnchorPoint',
                  icon: Icons.anchor_rounded,
                  onPressed: () => setState(() => _anchorTo = _AnchorTo.barButton),
                ),
              ),
            ),
          ),
        ),
      ],
      floats: <HarborFloat>[
        HarborFloat(
          placement: HarborAnchored(
            _anchorTo == _AnchorTo.boat ? _boatAnchor : _barAnchor,
            side: _side,
            gap: _gap,
            overlap: _overlap,
          ),
          child: _SpeechBubble(key: const ValueKey<String>('anchored float'), side: _side, text: 'HarborAnchored'),
        ),
      ],
      body: _SeaBackdrop(
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

  final HarborAnchorSide side;
  final String text;

  static const double _tail = 9;

  @override
  Widget build(final BuildContext context) => CustomPaint(
    painter: _BubblePainter(side),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        12 + (side == HarborAnchorSide.end ? _tail : 0),
        10 + (side == HarborAnchorSide.below ? _tail : 0),
        12 + (side == HarborAnchorSide.start ? _tail : 0),
        10 + (side == HarborAnchorSide.above ? _tail : 0),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Menlo', color: Palette.night, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
  );
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.side);

  final HarborAnchorSide side;

  @override
  void paint(final Canvas canvas, final Size size) {
    const double t = _SpeechBubble._tail;
    final Rect body = Rect.fromLTRB(
      side == HarborAnchorSide.end ? t : 0,
      side == HarborAnchorSide.below ? t : 0,
      size.width - (side == HarborAnchorSide.start ? t : 0),
      size.height - (side == HarborAnchorSide.above ? t : 0),
    );
    final Path tail = switch (side) {
      HarborAnchorSide.above =>
        Path()
          ..moveTo(body.center.dx - t, body.bottom - 1)
          ..lineTo(body.center.dx, size.height)
          ..lineTo(body.center.dx + t, body.bottom - 1),
      HarborAnchorSide.below =>
        Path()
          ..moveTo(body.center.dx - t, body.top + 1)
          ..lineTo(body.center.dx, 0)
          ..lineTo(body.center.dx + t, body.top + 1),
      HarborAnchorSide.start =>
        Path()
          ..moveTo(body.right - 1, body.center.dy - t)
          ..lineTo(size.width, body.center.dy)
          ..lineTo(body.right - 1, body.center.dy + t),
      HarborAnchorSide.end =>
        Path()
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
// HarborPopover

/// `HarborPopover`: an anchored float opened from deep in the tree.
class PopoverEntry extends StatefulWidget {
  const PopoverEntry({super.key});

  @override
  State<PopoverEntry> createState() => _PopoverEntryState();
}

class _PopoverEntryState extends State<PopoverEntry> {
  static const int _rowCount = 12;

  final List<OverlayPortalController> _menus = List<OverlayPortalController>.generate(
    _rowCount,
    (final int i) => OverlayPortalController(debugLabel: 'row $i menu'),
  );
  HarborAnchorSide _side = HarborAnchorSide.below;
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
    className: 'HarborPopover',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the first row',
        'A menu opens just below it, in the room, though the row is deep in the list. Tap the row again to close it.',
      ),
      TryStep(
        'Tap the third row, then pick side: above',
        'The menu moves to the third row (one menu at a time), then to the space above it.',
      ),
      TryStep(
        'With side: above, tap the first row',
        'There is no room above it under the header, so the menu flips below the row instead.',
      ),
      TryStep(
        'Pick side: below, scroll to the end, tap the last row',
        'There is no room below it above the tab bar, so the menu flips above the row.',
      ),
      TryStep(
        'Switch off flips',
        'The menu goes back below the row but is held clear of the tab bar, so it sits over its own row.',
      ),
    ],
    realWorld:
        'A dan buoy is a float with a flag on a pole, kept on deck to be thrown over the side. It goes in wherever the '
        'boat is, and floats on the open water clear of the boat.',
    inYourApp:
        'A menu or popover opened from a list row or a button deep in the page, or from another package, that cannot '
        'be listed in HarborFrame.floats. It sits by its row in the room. Tap a row near the bottom: there is no room '
        'below it above the tab bar, so the menu flips above the row instead.',
    art: const DanBuoyArt(),
    controls: <Widget>[
      ChoiceControl<HarborAnchorSide>(
        label: 'side',
        values: const <HarborAnchorSide>[HarborAnchorSide.above, HarborAnchorSide.below],
        value: _side,
        labelOf: (final HarborAnchorSide s) => s.name,
        onChanged: (final HarborAnchorSide s) => setState(() => _side = s),
      ),
      ToggleControl(label: 'flips', value: _flips, onChanged: (final bool v) => setState(() => _flips = v)),
    ],
    code:
        'final menu = OverlayPortalController();\n\n'
        '// In a row, anywhere below the frame:\n'
        'HarborPopover(\n'
        '  controller: menu,\n'
        '  placement: HarborAnchored(\n'
        '    null, // anchored to its child\n'
        '    side: HarborAnchorSide.${_side.name},\n'
        '    flips: $_flips,\n'
        '  ),\n'
        '  popoverBuilder: (context) => RowMenu(),\n'
        '  child: GestureDetector(onTap: menu.toggle, child: Row()),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('HarborPopover')],
      bottom: <HarborBar>[_bottomBar('HarborBar.solid', key: const ValueKey<String>('popover tab bar'))],
      body: HarborScrollView(
        key: const ValueKey<String>('popover stage'),
        slivers: <Widget>[
          SliverList.builder(
            itemCount: _rowCount,
            itemBuilder: (final BuildContext context, final int i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(i),
              child: HarborPopover(
                placement: HarborAnchored(null, side: _side, flips: _flips),
                controller: _menus[i],
                popoverBuilder: (final BuildContext context) =>
                    _FloatTag(key: const ValueKey<String>('popover'), label: 'Menu for row ${i + 1}'),
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
// 3. HarborFloat(barrier:)

/// `HarborFloat(barrier:)`: a modal float, which hides the floats listed before it.
class ModalFloatEntry extends StatefulWidget {
  const ModalFloatEntry({super.key});

  @override
  State<ModalFloatEntry> createState() => _ModalFloatEntryState();
}

class _ModalFloatEntryState extends State<ModalFloatEntry> {
  bool _launchUp = true;
  bool _modal = true;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFloat(barrier:)',
    tryThis: const <TryStep>[
      TryStep(
        'Tap the page beside the launch',
        'The launch goes and HarborFloat (listed first) comes back: the float\'s barrier took the tap and called onDismiss.',
      ),
      TryStep(
        'Tap Call the launch',
        'The launch returns and HarborFloat (listed first) is hidden: a modal float hides every float listed before it.',
      ),
      TryStep('Press Escape', 'The launch is dismissed, as by a tap beside it or back.'),
      TryStep(
        'Tap Call the launch, then switch off modal',
        'Both floats stay up, and a tap beside the launch leaves it up: no barrier, nothing hidden.',
      ),
    ],
    realWorld:
        'When the harbor master’s launch comes through with its blue light on, every other boat moves out of its way. '
        'While it is there, it is the only one in the channel.',
    inYourApp:
        'A menu or a panel that should be the only float while it is up. A float with a barrier is modal: '
        'HarborBarrier.clear() keeps the page in view, HarborBarrier.dimmed() tints it. A tap beside it or back closes it '
        '(through onDismiss) instead of reaching the page, and it hides every float listed before it (a tooltip, a '
        'floating button) until it goes. Floats listed after it stay up.',
    art: const HarborLaunchArt(),
    controls: <Widget>[
      ToggleControl(label: 'launch up', value: _launchUp, onChanged: (final bool v) => setState(() => _launchUp = v)),
      ToggleControl(label: 'modal', value: _modal, onChanged: (final bool v) => setState(() => _modal = v)),
    ],
    code:
        'HarborFrame(\n'
        '  floats: [\n'
        '    HarborFloat(placement: HarborAligned(alignment: Alignment.bottomCenter), child: Tooltip()),\n'
        '${_launchUp ? (_modal ? '    HarborFloat(barrier: HarborBarrier.clear(), onDismiss: close, child: QuickActions()), // hides the tooltip\n' : '    HarborFloat(child: QuickActions()), // floats beside it\n') : ''}'
        '  ],\n'
        '  ...\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('HarborFloat(barrier:)', key: const ValueKey<String>('modal header'))],
      bottom: <HarborBar>[_bottomBar('HarborBar.solid', key: const ValueKey<String>('modal tab bar'))],
      floats: <HarborFloat>[
        const HarborFloat(
          placement: HarborAligned(alignment: Alignment.bottomCenter),
          child: _FloatTag(
            key: ValueKey<String>('listed first'),
            label: 'HarborFloat (listed first)',
            color: Color(0xFF2E7D5B),
          ),
        ),
        if (_launchUp)
          HarborFloat(
            placement: const HarborAligned(alignment: Alignment.center),
            barrier: _modal ? const HarborBarrier.clear() : HarborBarrier.none,
            onDismiss: _modal ? () => setState(() => _launchUp = false) : null,
            child: _LaunchPanel(
              key: const ValueKey<String>('modal float'),
              modal: _modal,
              onClose: () => setState(() => _launchUp = false),
            ),
          ),
      ],
      body: Builder(
        builder: (final BuildContext context) => CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: HarborClear(
                rowInsets: true,
                edges: const <HarborEdge>{HarborEdge.top, HarborEdge.start, HarborEdge.end},
                padding: const EdgeInsetsDirectional.only(top: 12),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.white, width: 1.5),
    ),
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
                    'HarborFloat(barrier: ${modal ? 'clear' : 'none'})',
                    style: const TextStyle(
                      fontFamily: 'Menlo',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              modal
                  ? 'Harbor master coming through. The floats before me are hidden.'
                  : 'Not modal: the floats before me stay up.',
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
// 4. HarborToasts.show

const Map<HarborToastSlot, String> _slotFlags = <HarborToastSlot, String>{
  HarborToastSlot.top: 'K',
  HarborToastSlot.high: 'C',
  HarborToastSlot.middle: 'D',
  HarborToastSlot.low: 'U',
};

/// `HarborToasts.show`: a transient float, shown in the page on top.
class ToastsEntry extends StatefulWidget {
  const ToastsEntry({super.key});

  @override
  State<ToastsEntry> createState() => _ToastsEntryState();
}

class _ToastsEntryState extends State<ToastsEntry> {
  HarborToastTarget _target = HarborToastTarget.topmost;
  HarborToastSlot _last = HarborToastSlot.low;

  void _show(final BuildContext context, final HarborToastSlot slot) {
    setState(() => _last = slot);
    HarborToasts.show(
      context,
      slot: slot,
      target: _target,
      builder: (final BuildContext context) => _ToastPennant(slot: slot, target: _target),
    );
  }

  Widget _showButtons(final BuildContext context, {required final String prefix}) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      for (final HarborToastSlot slot in HarborToastSlot.values)
        _StageButton(
          key: ValueKey<String>('$prefix ${slot.name}'),
          label: slot.name,
          icon: Icons.flag_rounded,
          onPressed: () => _show(context, slot),
        ),
    ],
  );

  void _openSheet(final BuildContext context) => unawaited(
    showHarborSheet<void>(
      context,
      builder: (final BuildContext context) => HarborSheet(
        debugLabel: 'toasts sheet',
        surface: const Sailcloth(),
        header: const SheetHeader(key: ValueKey<String>('toasts sheet header'), title: 'A sheet on top'),
        footer: const HarborClear.rowInsets(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: StageMarker(key: ValueKey<String>('toasts sheet footer'), label: 'sheet footer', color: Palette.sea),
          ),
        ),
        body: HarborScrollView.box(
          shrinkWrap: true,
          child: HarborClear.rowInsets(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Show from here: topmost lands in this sheet’s room, above its footer; root lands over everything, clear of the system edges only.',
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.8), height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  _showButtons(context, prefix: 'sheet show'),
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
    className: 'HarborToasts.show',
    tryThis: const <TryStep>[
      TryStep(
        'Tap top, high, middle and low, one at a time',
        'Each toast lands at its slot in the room between the header and the tab bar, and hides after four seconds.',
      ),
      TryStep(
        'Show the keyboard, then tap low',
        'The toast lands just above the keyboard, not under it: the keyboard is the floor of the room.',
      ),
      TryStep(
        'Hide the keyboard, pick target: root, tap top',
        'The toast lands just under the status bar, over the header: root keeps clear of the system edges only, not the bars.',
      ),
      TryStep(
        'Pick target: topmost, tap Open a sheet, tap low in it',
        'The toast lands in the sheet\'s room, above its footer: topmost shows it in the page on top.',
      ),
      TryStep(
        'Pick target: root, then tap low in the sheet',
        'The toast lands over the sheet\'s footer, just above the home indicator: root shows it in the root, over every frame.',
      ),
    ],
    realWorld:
        'A flare fired from a boat says one thing to everyone in sight, then burns out. By day ships say it with flags: '
        'each letter of the international code is its own flag, run up a halyard for others to read, and taken down '
        'once the message is passed.',
    inYourApp:
        'A toast: a float shown for a while in the room of the page on top, a page or a sheet over the page. Its slot '
        'places it high or low in that room; topmost sends it to the sheet over the page, root to the root, clear of '
        'the system edges only.',
    art: const SignalFlagsArt(),
    controls: <Widget>[
      ChoiceControl<HarborToastTarget>(
        label: 'target',
        values: HarborToastTarget.values,
        value: _target,
        labelOf: (final HarborToastTarget t) => t.name,
        onChanged: (final HarborToastTarget t) => setState(() => _target = t),
      ),
    ],
    code:
        'HarborToasts.show(\n'
        '  context,\n'
        '  slot: HarborToastSlot.${_last.name},\n'
        '  target: HarborToastTarget.${_target.name},\n'
        '  builder: (context) => const Toast(\'Flags up\'),\n'
        ');',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('HarborToasts.show')],
      bottom: <HarborBar>[_bottomBar('HarborBar.solid', key: const ValueKey<String>('toasts tab bar'))],
      body: Builder(
        builder: (final BuildContext context) => _SeaBackdrop(
          child: HarborClear(
            rowInsets: true,
            padding: const EdgeInsetsDirectional.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Show a toast at each HarborToastSlot:',
                  style: TextStyle(color: Palette.foam.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 8),
                _showButtons(context, prefix: 'show'),
                const SizedBox(height: 16),
                _StageButton(
                  key: const ValueKey<String>('open toasts sheet'),
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

/// A shown toast: two code flags and what it was shown with.
class _ToastPennant extends StatelessWidget {
  const _ToastPennant({required this.slot, required this.target});

  final HarborToastSlot slot;
  final HarborToastTarget target;

  @override
  Widget build(final BuildContext context) => Material(
    key: const ValueKey<String>('toast'),
    color: Palette.night.withValues(alpha: 0.94),
    shape: const StadiumBorder(side: BorderSide(color: Palette.brass, width: 1.5)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CodeFlag(letter: _slotFlags[slot]!),
          const SizedBox(width: 3),
          CodeFlag(letter: target == HarborToastTarget.root ? 'N' : 'A'),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${slot.name} · ${target.name}',
              style: const TextStyle(
                fontFamily: 'Menlo',
                color: Palette.foam,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 5. HarborSheet

/// `HarborSheet`: a content-sized sheet with an overlay header and a footer that rides the keyboard.
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
  HarborKeyboardStance _footerKeyboard = HarborKeyboardStance.rides;
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
    final Widget button = HarborClear.rowInsets(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: BrassAction(
          key: const ValueKey<String>('sheet footer'),
          label: 'Make sail',
          onPressed: () => HarborSheet.close(context),
        ),
      ),
    );
    if (_footerKeyboard != HarborKeyboardStance.reserves) {
      return button;
    }
    // A HarborKeyboardSpace holds the keyboard's ground: here a tray of flags to
    // pick from, which the keyboard takes the place of. The button above it
    // never moves when they trade.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        button,
        const SizedBox(height: 12),
        const HarborKeyboardSpace(child: _FlagTray()),
      ],
    );
  }

  String get _footerHint => switch (_footerKeyboard) {
    HarborKeyboardStance.rides =>
      'rides: drag the keyboard up and the Make sail button rides it, so it is always in reach.',
    HarborKeyboardStance.stays =>
      'stays: the button stays where it is and the keyboard covers it; the rows end at the keyboard. For a '
          'footer you don\'t need while typing.',
    HarborKeyboardStance.reserves =>
      'reserves: the flag tray holds the keyboard\'s ground. Drag the keyboard up: it takes the tray\'s place '
          'and the button above it doesn\'t move.',
  };

  Widget _sheet(final BuildContext context) => HarborSheet(
    debugLabel: 'HarborSheet',
    surface: const Sailcloth(),
    header: _hasHeader ? const SheetHeader(key: ValueKey<String>('sheet header'), title: 'HarborSheet') : null,
    // The plain footer rides the keyboard; another stance takes the sheet's own footer bar, changed.
    footer: _hasFooter && _footerKeyboard == HarborKeyboardStance.rides ? _footer(context) : null,
    footerBar: _hasFooter && _footerKeyboard != HarborKeyboardStance.rides
        ? HarborSheet.defaultFooterBar(_footer(context)).copyWith(keyboard: _footerKeyboard)
        : null,
    maxExtentFraction: _maxExtent / 100,
    body: HarborScrollView.box(
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
    tryThis: const <TryStep>[
      TryStep(
        'Tap Hoist the HarborSheet',
        'The sheet is as tall as its three rows, and Make sail sits clear of the home indicator.',
      ),
      TryStep(
        'Drag rows to 16',
        'The sheet stops growing at maxExtent % of the space below the status bar, and its body scrolls.',
      ),
      TryStep(
        'Show the keyboard',
        'footer keyboard rides: Make sail rides up on the keyboard, and the sheet stays within the space above it.',
      ),
      TryStep(
        'Pick footer keyboard: stays',
        'Make sail stays put and the keyboard covers it, while the rows still end above the keyboard.',
      ),
      TryStep(
        'Pick footer keyboard: reserves, then hide the keyboard',
        'A flag tray takes the keyboard\'s place, and Make sail doesn\'t move as they trade: HarborKeyboardSpace holds its ground.',
      ),
    ],
    // The whole phone: at a high maxExtent with many rows the sheet reaches up near the status bar,
    // and the button that hoists it is mid-page.
    realWorld:
        'On a sailboat the sheet is the line that trims a sail, run from the sail’s corner back to a winch in the '
        'cockpit. Hoisting and trimming the sail is how you make sail.',
    inYourApp:
        'A sheet as tall as its content, up to maxExtentFraction of the space above the keyboard, past which its body '
        'scrolls. It is a page: its header is an overlay bar its body runs under, its footer a solid bar that rides the '
        'keyboard and clears the home indicator once. Drag the keyboard up to see the footer ride it.',
    art: const SailSheetArt(),
    controls: <Widget>[
      GuideHint(text: _footerHint),
      ToggleControl(label: 'header', value: _hasHeader, onChanged: (final bool v) => _set(() => _hasHeader = v)),
      ToggleControl(label: 'footer', value: _hasFooter, onChanged: (final bool v) => _set(() => _hasFooter = v)),
      ChoiceControl<HarborKeyboardStance>(
        label: 'footer keyboard',
        values: HarborKeyboardStance.values,
        value: _footerKeyboard,
        labelOf: (final HarborKeyboardStance s) => s.name,
        onChanged: (final HarborKeyboardStance s) => _set(() => _footerKeyboard = s),
      ),
      SliderControl(
        label: 'maxExtent %',
        value: _maxExtent,
        min: 30,
        max: 100,
        onChanged: (final double v) => _set(() => _maxExtent = v),
      ),
      SliderControl(
        label: 'rows',
        value: _rows,
        min: 1,
        max: 16,
        divisions: 15,
        onChanged: (final double v) => _set(() => _rows = v),
      ),
    ],
    code:
        'showHarborSheet(\n'
        '  context,\n'
        '  builder: (context) => HarborSheet(\n'
        '${_hasHeader ? '    header: SheetHeader(title: \'HarborSheet\'),\n' : ''}'
        '${_hasFooter ? (_footerKeyboard == HarborKeyboardStance.rides ? '    footer: MakeSailButton(),\n' : '    footerBar: HarborSheet.defaultFooterBar(${_footerKeyboard == HarborKeyboardStance.reserves ? 'Column(children: [MakeSailButton(), HarborKeyboardSpace(child: FlagTray())])' : 'MakeSailButton()'})\n'
                        '        .copyWith(keyboard: HarborKeyboardStance.${_footerKeyboard.name}),\n') : ''}'
        '    maxExtentFraction: ${_fraction(_maxExtent)},\n'
        '    body: HarborScrollView.box(shrinkWrap: true, child: ${_rows.round()}Rows()),\n'
        '  ),\n'
        ');',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('A page')],
      body: Builder(
        builder: (final BuildContext context) => _SeaBackdrop(
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
          builder: (final BuildContext context, final ScrollController controller) =>
              HarborScrollView(controller: controller, slivers: <Widget>[_rows(30)]),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSheet.draggable',
    tryThis: const <TryStep>[
      TryStep('Tap Hoist HarborSheet.draggable', 'It opens at rest % of the space below the status bar.'),
      TryStep(
        'Drag its header, or its list, all the way up',
        'It stops at max %: the list hauls the sheet up as well as the header does.',
      ),
      TryStep(
        'Show the keyboard',
        'The sheet rides up with the keyboard: its heights are shares of the space between the status bar and the keyboard.',
      ),
      TryStep(
        'Hide the keyboard, drag it down past min % and let go',
        'It closes. Let go above min % and it springs back to rest instead.',
      ),
      TryStep(
        'Drag rest % to 30, then hoist it again',
        'It opens lower. The heights are read when the sheet is hoisted, so change them first.',
      ),
    ],
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
        '    builder: (context, controller) => HarborScrollView(\n'
        '      controller: controller,\n'
        '      slivers: [boats],\n'
        '    ),\n'
        '  ),\n'
        ');',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('A page')],
      body: Builder(
        builder: (final BuildContext context) => _SeaBackdrop(
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
// 7. showHarborSheet(coversPage: true)

/// `showHarborSheet(coversPage: true)`: a sheet the page keeps clear of.
class CoversPageEntry extends StatefulWidget {
  const CoversPageEntry({super.key});

  @override
  State<CoversPageEntry> createState() => _CoversPageEntryState();
}

class _CoversPageEntryState extends State<CoversPageEntry> {
  bool _coversPage = true;
  String _barrier = 'none';

  // The three kinds of barrier, by the name the picker and the code show.
  static const Map<String, HarborBarrier> _barriers = <String, HarborBarrier>{
    'dimmed': HarborBarrier.dimmed(),
    'clear': HarborBarrier.clear(),
    'none': HarborBarrier.none,
  };

  static const int _count = 14;

  void _open(final BuildContext context) => unawaited(
    showHarborSheet<void>(
      context,
      coversPage: _coversPage,
      barrier: _barriers[_barrier]!,
      builder: (final BuildContext context) => HarborSheet(
        debugLabel: 'coversPage sheet',
        surface: const Sailcloth(),
        header: const SheetHeader(key: ValueKey<String>('coversPage sheet header'), title: 'Covers the page'),
        body: HarborScrollView.box(
          shrinkWrap: true,
          child: HarborClear.rowInsets(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _coversPage
                    ? 'coversPage: true. Scroll the list: its last row comes to rest above this sheet.'
                    : 'coversPage: false. Scroll the list: its last rows stay hidden under this sheet.',
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
    className: 'showHarborSheet(coversPage: true)',
    tryThis: const <TryStep>[
      TryStep(
        'Tap Open sheet in the header',
        'The sheet slides up over the list, and the list is not dimmed: with barrier none the page stays live.',
      ),
      TryStep(
        'Scroll the list to the end',
        'Its last row comes to rest on the sheet\'s top edge instead of under it: the page keeps clear of the sheet.',
      ),
      TryStep(
        'Close the sheet with its ×, switch off coversPage, open it again',
        'Scroll to the end: the last rows now stay under the sheet. Without coversPage the page is never told it is there.',
      ),
      TryStep(
        'Close it, pick barrier: dimmed, open it again',
        'The page dims, and a tap on it closes the sheet instead of scrolling the list.',
      ),
    ],
    // The whole phone: the button that opens the sheet is in the header, the list it shelters at the
    // bottom.
    realWorld:
        'A breakwater is a long wall of rock built out from the shore. The swell breaks on its far side, and the water '
        'behind it stays calm, so boats can lie there in shelter.',
    inYourApp:
        'A sheet that reports how far it covers the page that opened it, as it slides in, is dragged and slides out. '
        'The page keeps clear of it: a scroll view’s last row stays reachable above the sheet, a lifted canvas element '
        'stays in sight. With barrier none, the page stays live under the sheet.',
    art: const BreakwaterArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'coversPage',
        value: _coversPage,
        onChanged: (final bool v) => setState(() => _coversPage = v),
      ),
      ChoiceControl<String>(
        label: 'barrier',
        values: _barriers.keys.toList(),
        value: _barrier,
        labelOf: (final String b) => b,
        onChanged: (final String b) => setState(() => _barrier = b),
      ),
    ],
    code:
        'showHarborSheet(\n'
        '  context,\n'
        '  coversPage: $_coversPage,\n'
        '  barrier: ${_barrier == 'none' ? 'HarborBarrier.none' : 'const HarborBarrier.$_barrier()'},\n'
        '  builder: (context) => HarborSheet(header: title, body: note),\n'
        ');\n\n'
        '// The page that opened it:\n'
        'HarborScrollView(slivers: [boats]) // ${_coversPage ? 'its last row rests above the sheet' : 'its last rows end under the sheet'}',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        _headerBar(
          'Moorings',
          trailing: Builder(
            builder: (final BuildContext context) => _StageButton(
              key: const ValueKey<String>('open coversPage sheet'),
              label: 'Open sheet',
              icon: Icons.waves_rounded,
              onPressed: () => _open(context),
            ),
          ),
        ),
      ],
      body: StageProbe(
        label: 'The list, under the sheet',
        child: HarborScrollView(key: const ValueKey<String>('coversPage list'), slivers: <Widget>[_rows(_count)]),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 8. showHarborDialog(inheritRoom:)

/// `showHarborDialog(inheritRoom:)`: a dialog that keeps clear of the page's bars.
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
      inheritRoom: _inherit,
      // The stage's own navigator, so the dialog opens inside the phone.
      useRootNavigator: false,
      builder: (final BuildContext context) => const HarborClear(
        padding: EdgeInsetsDirectional.all(10),
        child: _CallBox(key: ValueKey<String>('call box')),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'showHarborDialog(inheritRoom:)',
    tryThis: const <TryStep>[
      TryStep(
        'Tap Call the harbor master',
        'The card fills the room between the header and the composer: with inheritRoom it keeps clear of the page\'s bars.',
      ),
      TryStep(
        'Tap the header, outside the card',
        'The dialog closes: its barrier takes the tap, so the header never gets it.',
      ),
      TryStep(
        'Switch off inheritRoom, call again',
        'The card now covers the header and the composer, stopping only at the status bar and the home indicator.',
      ),
      TryStep(
        'Switch inheritRoom on, show the keyboard, call again',
        'The card ends just above the keyboard: the keyboard is the floor of its room too.',
      ),
    ],
    realWorld:
        'The harbor master works from an office on the quay. You call in on the radio, or speak through the window, '
        'and the answer comes from between the roof and the sill.',
    inYourApp:
        'A dialog is a page: by default it sees only the system edges, so it may cover the page’s header and composer. '
        'With inheritRoom, it sees the page’s bars as system edges too, and stays between them: a menu opened from a '
        'message stays between the header and the composer.',
    art: const HarborOfficeArt(),
    controls: <Widget>[
      ToggleControl(label: 'inheritRoom', value: _inherit, onChanged: (final bool v) => setState(() => _inherit = v)),
    ],
    code:
        'showHarborDialog(\n'
        '  context, // inside the page\'s HarborFrame\n'
        '  inheritRoom: $_inherit,\n'
        '  builder: (context) => const HarborClear(\n'
        '    padding: EdgeInsetsDirectional.all(10),\n'
        '    child: CallBox(),\n'
        '  ),\n'
        ');',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[_headerBar('Harbor master', key: const ValueKey<String>('office header'))],
      bottom: <HarborBar>[_bottomBar('Composer (solid)', key: const ValueKey<String>('office footer'))],
      body: Builder(
        builder: (final BuildContext context) => _SeaBackdrop(
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

/// The radio call box: a card that fills the room it is given.
class _CallBox extends StatelessWidget {
  const _CallBox({super.key});

  @override
  Widget build(final BuildContext context) => Material(
    color: const Color(0xFF263D4F),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Palette.brass, width: 1.5),
    ),
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
                  'This card fills the room it was given. Its top and bottom show where that room ends.',
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
// 9. HarborKeepInSight.reveal + HarborKeepInSight(keepInSight:)

/// `HarborKeepInSight.reveal` + `HarborKeepInSight(keepInSight:)`: a field kept in sight as the keyboard rises.
class KeepInSightEntry extends StatefulWidget {
  const KeepInSightEntry({super.key});

  @override
  State<KeepInSightEntry> createState() => _KeepInSightEntryState();
}

class _KeepInSightEntryState extends State<KeepInSightEntry> {
  final FocusNode _focus = FocusNode(debugLabel: 'kept field');
  final GlobalKey _field = GlobalKey(debugLabel: 'kept field');
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
      HarborKeepInSight.reveal(field, clearance: _clearance);
    }
  }

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborKeepInSight(keepInSight:)',
    tryThis: const <TryStep>[
      TryStep(
        'Show the keyboard before touching the field',
        'Nothing scrolls and the field goes under the keyboard: with onlyWhileFocused, HarborKeepInSight waits for focus.',
      ),
      TryStep(
        'Hide the keyboard, tap the field, show it again',
        'The list scrolls so the field sits clearance above the keyboard: HarborKeepInSight keeps it in sight.',
      ),
      TryStep(
        'Drag clearance to 40, hide and show the keyboard',
        'The field now stops 40 points above the keyboard: clearance is used the next time the keyboard rises.',
      ),
      TryStep(
        'Switch off keepInSight, scroll up, hide and show the keyboard',
        'The field is left under the keyboard. Tap reveal in the header to bring it up by hand.',
      ),
    ],
    // The whole phone: the reveal button is in the header, the field and the keyboard at the bottom.
    realWorld:
        'A lighthouse sweeps its beam out over the water, and when it falls on a boat the boat stands out in the dark. '
        'Its keeper’s job is to keep ships in sight of the light.',
    inYourApp:
        'HarborKeepInSight.reveal scrolls a widget into sight, clearance clear of the bars and the keyboard. A '
        'HarborKeepInSight with keepInSight does it for you whenever the keyboard rises or the bottom grows; with '
        'onlyWhileFocused, only while focus is inside it. Tap the field, then show the keyboard.',
    art: const LighthouseBeamArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'keepInSight',
        value: _keepInSight,
        onChanged: (final bool v) => setState(() => _keepInSight = v),
      ),
      ToggleControl(
        label: 'onlyWhileFocused',
        value: _onlyWhileFocused,
        onChanged: (final bool v) => setState(() => _onlyWhileFocused = v),
      ),
      SliderControl(
        label: 'clearance',
        value: _clearance,
        min: 0,
        max: 48,
        onChanged: (final double v) => setState(() => _clearance = v),
      ),
    ],
    code:
        'HarborScrollView(slivers: [\n'
        '  boats,\n'
        '  SliverToBoxAdapter(\n'
        '    child: HarborKeepInSight(\n'
        '      keepInSight: $_keepInSight,\n'
        '      onlyWhileFocused: $_onlyWhileFocused,\n'
        '      clearance: ${_f(_clearance)},\n'
        '      child: Field(),\n'
        '    ),\n'
        '  ),\n'
        '])\n\n'
        '// Or by hand:\n'
        'HarborKeepInSight.reveal(fieldContext, clearance: ${_f(_clearance)});',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        _headerBar(
          'A scroll view',
          edgeEffect: const HarborEdgeEffect.fade(length: 12),
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
        label: 'Scroll view (body ends at the keyboard)',
        child: HarborScrollView(
          key: const ValueKey<String>('reveal scroll view'),
          slivers: <Widget>[
            _rows(9),
            SliverToBoxAdapter(
              child: HarborClear.rowInsets(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: HarborKeepInSight(
                    keepInSight: _keepInSight,
                    onlyWhileFocused: _onlyWhileFocused,
                    clearance: _clearance,
                    child: KeyedSubtree(
                      key: const ValueKey<String>('kept field'),
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
/// (the stage draws the keyboard).
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
              border: Border.all(
                color: focused ? Palette.brass : Palette.foam.withValues(alpha: 0.4),
                width: focused ? 2 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: focused ? Palette.brass : Palette.foam.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    focused ? 'HarborKeepInSight field' : 'Tap me, then show the keyboard',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Palette.foam.withValues(alpha: focused ? 1 : 0.6)),
                  ),
                ),
                if (focused)
                  Container(width: 2, height: 20, margin: const EdgeInsets.only(left: 2), color: Palette.brass),
              ],
            ),
          );
        },
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 10. HarborKeepInSight(onObscured:)

/// `HarborKeepInSight(onObscured:)`: how much of a widget the bars cover.
class ObscuredEntry extends StatefulWidget {
  const ObscuredEntry({super.key});

  @override
  State<ObscuredEntry> createState() => _ObscuredEntryState();
}

class _ObscuredEntryState extends State<ObscuredEntry> {
  final ValueNotifier<double> _covered = ValueNotifier<double>(0);
  bool _startsUnderBars = true;

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
    className: 'HarborKeepInSight(onObscured:)',
    tryThis: const <TryStep>[
      TryStep('Scroll the list up slowly', 'covered climbs from 0% as the hero title slides under the header.'),
      TryStep(
        'Keep scrolling until covered reads 100%',
        'The header\'s own title has faded in: the page hands the title from the hero to the header.',
      ),
      TryStep('Scroll back to the top', 'covered drops to 0% and the header\'s title fades out again.'),
      TryStep(
        'Switch off startsUnderBars',
        'The hero now starts below the header instead of running up under it, and covered stays 0% until you scroll.',
      ),
    ],
    // The top of the phone: the hero slides under the header, whose title and readout answer it.
    focus: const StageFocus.top(500),
    realWorld:
        'Sailing along a coast, you watch a harbor light slide behind a headland: first its foot goes, then half the '
        'tower, then the light itself. How much is hidden tells you where you are.',
    inYourApp:
        'A widget that reports how much of itself the bars on its edge cover, from 0 in the room to 1 under them. '
        'Scroll the hero title under the header and hand off to the header’s own title as it goes.',
    art: const HeadlandBeaconArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'startsUnderBars',
        value: _startsUnderBars,
        onChanged: (final bool v) => setState(() => _startsUnderBars = v),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Align(alignment: Alignment.centerLeft, child: _readout()),
      ),
    ],
    code:
        'final covered = ValueNotifier<double>(0);\n\n'
        'HarborKeepInSight(\n'
        '  onObscured: (v) => covered.value = v, // 0 clear, 1 under the header\n'
        '  child: HeroTitle(),\n'
        ')\n\n'
        '// In the header:\n'
        'ValueListenableBuilder(\n'
        '  valueListenable: covered,\n'
        '  builder: (context, v, _) => Opacity(opacity: v, child: Title()),\n'
        ')\n\n'
        'HarborScrollView(startsUnderBars: $_startsUnderBars, slivers: [hero, ...])',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        HarborBar.overlay(
          edgeEffect: const HarborEdgeEffect.fade(length: 12),
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.78)),
          debugLabel: 'header',
          child: SizedBox(
            key: const ValueKey<String>('obscured header'),
            height: 52,
            child: HarborClear.rowInsets(
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
      body: HarborScrollView(
        key: const ValueKey<String>('hero scroll view'),
        startsUnderBars: _startsUnderBars,
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
                    child: HarborClear.rowInsets(
                      child: HarborKeepInSight(
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
// 11. HarborKeepInSightRegion + HarborKeepInSight(lift: true)

/// `HarborKeepInSightRegion` + `HarborKeepInSight(lift: true)`: content lifted clear of a sheet.
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
      coversPage: true,
      barrier: HarborBarrier.none,
      builder: (final BuildContext context) => HarborSheet(
        debugLabel: 'lift sheet',
        surface: const Sailcloth(),
        header: const SheetHeader(key: ValueKey<String>('lift sheet header'), title: 'Covers the page'),
        body: HarborScrollView.box(
          shrinkWrap: true,
          child: Column(children: <Widget>[for (int i = 0; i < 3; i++) StageRow(index: i)]),
        ),
      ),
    ),
  );

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborKeepInSightRegion',
    tryThis: const <TryStep>[
      TryStep(
        'Tap Open sheet in the header',
        'The boat rises to stay clearance above the sheet: the region lifts it just as far as it needs to.',
      ),
      TryStep('Drag clearance to 120', 'The boat rises further, to stay 120 points above the sheet.'),
      TryStep('Switch off lift', 'The boat drops back to where it was placed, under the sheet.'),
      TryStep(
        'Switch on holdPosition, then switch lift back on',
        'The boat stays put under the sheet: holdPosition is for an element being dragged.',
      ),
      TryStep('Switch off holdPosition', 'Let go, the boat rises clear of the sheet.'),
    ],
    // The whole phone: the button that opens the sheet is in the header, the boat it lifts at the
    // bottom.
    realWorld:
        'A boat lift is a tall gantry on wheels that straddles a slip. Slings go under the hull, and the boat is raised '
        'clear of the water, just as high as it needs to be.',
    inYourApp:
        'A region that lifts its content when a HarborKeepInSight(lift: true) inside it would be covered by what covers the '
        'bottom (a coversPage sheet, the keyboard): up just far enough to keep it clearance clear, and back down when '
        'the cover goes. holdPosition keeps it where it is, for an element being dragged.',
    art: const BoatLiftArt(),
    controls: <Widget>[
      ToggleControl(label: 'lift', value: _lift, onChanged: (final bool v) => setState(() => _lift = v)),
      SliderControl(
        label: 'clearance',
        value: _clearance,
        min: 0,
        max: 120,
        onChanged: (final double v) => setState(() => _clearance = v),
      ),
      ToggleControl(label: 'holdPosition', value: _hold, onChanged: (final bool v) => setState(() => _hold = v)),
    ],
    code:
        'HarborKeepInSightRegion(\n'
        '  child: Stack(children: [\n'
        '    Positioned(\n'
        '      bottom: 60,\n'
        '      child: HarborKeepInSight(\n'
        '        lift: $_lift,\n'
        '        clearance: ${_f(_clearance)},\n'
        '        holdPosition: $_hold,\n'
        '        child: Boat(),\n'
        '      ),\n'
        '    ),\n'
        '  ]),\n'
        ')\n\n'
        'showHarborSheet(context, coversPage: true, barrier: HarborBarrier.none, builder: ...);',
    stage: (final BuildContext context) => HarborFrame(
      top: <HarborBar>[
        _headerBar(
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
      body: _SeaBackdrop(
        hint: 'Open the sheet: the boat rises clearance clear of it.',
        child: HarborKeepInSightRegion(
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Center(
                  child: HarborKeepInSight(
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
                          SizedBox(
                            height: 60,
                            child: BoatArt(kind: BoatKind.yacht, hull: Palette.hulls[3], bob: false),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'HarborKeepInSight(lift:)',
                            style: TextStyle(
                              fontFamily: 'Menlo',
                              fontSize: 11,
                              color: Palette.foam,
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
      ),
    ),
  );
}

/// The flags a sheet footer with a HarborKeyboardSpace offers while the keyboard is down.
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
