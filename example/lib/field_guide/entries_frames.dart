import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import 'art/frames_art.dart';
import 'entry.dart';
import 'guide_page.dart';
import 'stage.dart';
import 'stage_kit.dart';

/// Frames: the frame and the root it sits in.
final List<GuideEntry> frameEntries = <GuideEntry>[
  GuideEntry(
    id: 'frame-harbor',
    className: 'HarborFrame',
    group: GuideGroup.frames,
    realWorld: 'Like a sheltered bay: walls at the edges, room inside',
    art: (final BuildContext context) => const HarborArt(),
    page: (final BuildContext context) => const HarborEntry(),
  ),
  GuideEntry(
    id: 'frame-sea',
    className: 'HarborRoot',
    group: GuideGroup.frames,
    realWorld: 'Like the open sea: every frame sits on it',
    art: (final BuildContext context) => const HarborSeaArt(),
    page: (final BuildContext context) => const HarborRootEntry(),
  ),
  GuideEntry(
    id: 'frame-new-port',
    className: 'HarborFrame(isPage: true)',
    group: GuideGroup.frames,
    realWorld: 'Like a second harbor up the coast: it starts fresh',
    art: (final BuildContext context) => const NewPortArt(),
    page: (final BuildContext context) => const PageEntry(),
  ),
  GuideEntry(
    id: 'frame-hug-body',
    className: 'HarborSizing.hug',
    group: GuideGroup.frames,
    realWorld: 'Like a skiff on a davit: hoisted as high as the boat',
    art: (final BuildContext context) => const HugBodyArt(),
    page: (final BuildContext context) => const HugBodyEntry(),
  ),
];

/// A body that shows its own box: a tinted panel with a label at each end.
class _BodyBox extends StatelessWidget {
  const _BodyBox({required this.label, this.child});

  final String label;
  final Widget? child;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('harbor body'),
    decoration: BoxDecoration(
      color: Palette.shallows.withValues(alpha: 0.22),
      border: Border.all(color: Palette.brass, width: 2),
    ),
    child: SizedBox.expand(
      child: HarborClear(
        edges: HarborEdge.vertical,
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        child: Column(
          children: <Widget>[
            HarborClear.rowInsets(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Menlo',
                        fontSize: 13,
                        color: Palette.brass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (child != null) Expanded(child: child!),
          ],
        ),
      ),
    ),
  );
}

/// `HarborFrame`: a frame with bars on its edges and a body in the room between.
class HarborEntry extends StatefulWidget {
  const HarborEntry({super.key});

  @override
  State<HarborEntry> createState() => _HarborEntryState();
}

class _HarborEntryState extends State<HarborEntry> {
  bool _top = true;
  bool _bottom = true;
  bool _clearsKeyboard = true;
  double _margin = 16;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFrame',
    tryThis: const <TryStep>[
      TryStep(
        'Slide margin to 40',
        'The HarborClear.rowInsets marker moves in, but the body\'s brass box stays put: rows keep the margin, the body runs edge to edge.',
      ),
      TryStep(
        'Switch off top bar',
        'The body\'s box rises to the top of the screen, yet its label still clears the status bar: HarborClear keeps content off the system edges.',
      ),
      TryStep(
        'Tap the keyboard button under the gauge',
        'The keyboard covers the bottom bar and the body now ends at its top: bodyClearsKeyboard keeps the body above the keyboard.',
      ),
      TryStep(
        'Switch off bodyClearsKeyboard, keyboard still up',
        'The body runs down under the keyboard to the bottom bar, and Readings show how far the keyboard reaches over it.',
      ),
    ],
    realWorld:
        'A harbor is a bay of calm water sheltered by breakwaters, with quays and piers built along its edges and a town '
        'on the shore. Boats come in through the mouth and tie up wherever there is room.',
    inYourApp:
        'A page, a tab or a sheet: a frame whose top, bottom, start and end edges each hold bars. The body (your '
        'content) fills the room the solid bars leave, and is told through MediaQuery.padding what still reaches over it.',
    art: const HarborArt(),
    controls: <Widget>[
      ToggleControl(label: 'top bar', value: _top, onChanged: (final bool v) => setState(() => _top = v)),
      ToggleControl(label: 'bottom bar', value: _bottom, onChanged: (final bool v) => setState(() => _bottom = v)),
      ToggleControl(
        label: 'bodyClearsKeyboard',
        value: _clearsKeyboard,
        onChanged: (final bool v) => setState(() => _clearsKeyboard = v),
      ),
      SliderControl(
        label: 'margin',
        value: _margin,
        min: 0,
        max: 48,
        onChanged: (final double v) => setState(() => _margin = v),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  margin: EdgeInsetsDirectional.symmetric(horizontal: ${_margin.toStringAsFixed(0)}),\n'
        '  bodyClearsKeyboard: $_clearsKeyboard,\n'
        '${_top ? '  top: [HarborBar.solid(child: Header())],\n' : ''}'
        '${_bottom ? '  bottom: [HarborBar.solid(child: TabBar())],\n' : ''}'
        '  body: HarborClear(child: HarborClear.rowInsets(child: Row())),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      debugLabel: 'HarborFrame',
      margin: EdgeInsetsDirectional.symmetric(horizontal: _margin),
      bodyClearsKeyboard: _clearsKeyboard,
      top: <HarborBar>[
        if (_top)
          const HarborBar.solid(
            backdrop: QuayStones(),
            debugLabel: 'top',
            child: StageHeader(key: ValueKey<String>('top bar'), title: 'top: HarborBar.solid'),
          ),
      ],
      bottom: <HarborBar>[
        if (_bottom)
          const HarborBar.solid(
            backdrop: QuayStones(),
            debugLabel: 'bottom',
            child: StageBar(key: ValueKey<String>('bottom bar'), label: 'bottom: HarborBar.solid'),
          ),
      ],
      body: StageProbe(
        label: 'frame body',
        child: _BodyBox(
          label: 'body',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const HarborClear.rowInsets(
                child: StageMarker(
                  key: ValueKey<String>('row insets marker'),
                  label: 'HarborClear.rowInsets',
                  color: Palette.sea,
                ),
              ),
              const SizedBox(height: 8),
              HarborClear.rowInsets(
                child: Text(
                  'Rows keep the margin; the body itself runs to the frame\'s edge.',
                  style: TextStyle(color: Palette.foam.withValues(alpha: 0.8)),
                ),
              ),
              const Spacer(),
              const HarborClear.rowInsets(
                child: StageMarker(label: 'body ends here', color: Palette.plank, height: 36),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// What the stage's own root (or a nested one) shows: its system edges, drawn.
class _RootView extends StatelessWidget {
  const _RootView({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) => StageProbe(
    label: label,
    child: Builder(
      builder: (final BuildContext context) {
        final HarborRoomData room = HarborRoom.of(context);
        final EdgeInsets edges = room.systemEdges.resolve(Directionality.of(context));
        Widget band() => ColoredBox(color: Palette.brass.withValues(alpha: 0.35));
        // The readings sit inside the side insets and are always drawn, so a corner or a notch never
        // cuts them off, and a 0 inset reads 0 rather than vanishing with its band.
        Widget label(final String text) => Text(
          text,
          style: const TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Palette.foam),
        );
        return Stack(
          children: <Widget>[
            const Positioned.fill(child: HarborSeaArt()),
            Positioned(top: 0, left: 0, right: 0, height: edges.top, child: band()),
            Positioned(bottom: 0, left: 0, right: 0, height: edges.bottom, child: band()),
            Positioned(
              key: const ValueKey<String>('system edge labels'),
              bottom: edges.bottom + 4,
              right: edges.right + 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  label('systemEdges T ${edges.top.toStringAsFixed(0)}'),
                  label('systemEdges B ${edges.bottom.toStringAsFixed(0)}'),
                ],
              ),
            ),
            Positioned.fill(
              child: HarborClear(
                rowInsets: true,
                padding: const EdgeInsetsDirectional.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const StageMarker(key: ValueKey<String>('clear marker'), label: 'HarborClear', color: Palette.sea),
                    const Spacer(),
                    Text(
                      'This is the root: it reads the system edges from MediaQuery and hands them to everything under it.',
                      style: TextStyle(color: Palette.night.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// `HarborRoot`: the root every frame sits on.
class HarborRootEntry extends StatefulWidget {
  const HarborRootEntry({super.key});

  @override
  State<HarborRootEntry> createState() => _HarborRootEntryState();
}

class _HarborRootEntryState extends State<HarborRootEntry> {
  bool _nested = false;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborRoot',
    tryThis: const <TryStep>[
      TryStep(
        'Open The stage, switch off Status bar, then pick Device: iPhone SE',
        'On the iPhone 17 the top band stays 62, since the island is hardware and keeps its inset; on the SE it goes to 0 and the HarborClear marker moves up: the root reads its system edges from MediaQuery.',
      ),
      TryStep(
        'Switch Status bar on, pick Device: iPhone 17 landscape',
        'The marker steps in to 78, the 62-point side inset plus the root\'s 16 margin, and the bottom band thins to 21.',
      ),
      TryStep(
        'Tap the keyboard button under the gauge',
        'The bottom band drops to 0 under the keyboard, but nothing under the root moves: HarborRoot clears nothing out of its way itself.',
      ),
      TryStep(
        'Switch on nested HarborRoot',
        'The top band grows and the marker sits below the outer bar: a root inside a frame reads that bar as a system edge.',
      ),
    ],
    realWorld:
        'The open sea runs out to the horizon, and every harbor on every coast is built on it. It has no quays of its '
        'own; it is just the water, and the coast around it.',
    inYourApp:
        'The root. Mount it once, above the Navigator (MaterialApp.builder), so every route, dialog and sheet shares its '
        'system edges, its keyboard and its toasts. It moves nothing out of the keyboard\'s way itself. A root mounted '
        'inside another frame is a world of its own: it reads whatever MediaQuery says there (an outer bar included) as '
        'system edges.',
    art: const HarborSeaArt(),
    controls: <Widget>[
      ToggleControl(
        label: 'nested HarborRoot',
        value: _nested,
        onChanged: (final bool v) => setState(() => _nested = v),
      ),
    ],
    code: _nested
        ? 'HarborFrame(\n'
              '  top: [HarborBar.overlay(child: Header())],\n'
              '  // A world of its own: the bar reads as a system edge.\n'
              '  body: HarborRoot(child: preview),\n'
              ')'
        : 'MaterialApp(\n'
              '  builder: (context, child) => HarborRoot(\n'
              '    margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),\n'
              '    child: child!,\n'
              '  ),\n'
              '  home: const HomePage(),\n'
              ')',
    stage: (final BuildContext context) => _nested
        ? HarborFrame(
            debugLabel: 'outer',
            top: <HarborBar>[
              HarborBar.overlay(
                backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.8)),
                child: const StageHeader(key: ValueKey<String>('outer bar'), title: 'outer HarborBar.overlay'),
              ),
            ],
            body: const HarborRoot(
              margin: EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: _RootView(label: 'nested HarborRoot'),
            ),
          )
        : const _RootView(label: 'the stage\'s HarborRoot'),
  );
}

/// `HarborFrame(isPage: true)`: a frame that starts fresh, with only the system edges.
class PageEntry extends StatefulWidget {
  const PageEntry({super.key});

  @override
  State<PageEntry> createState() => _PageEntryState();
}

class _PageEntryState extends State<PageEntry> {
  bool _isPage = false;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborFrame(isPage: true)',
    tryThis: const <TryStep>[
      TryStep(
        'Scroll the rows up under HarborFrame(isPage: false)',
        'They slide under the brass header and fade at its edge: the inner frame\'s rows run under its own overlay bar.',
      ),
      TryStep(
        'Switch on isPage',
        'The inner header jumps up level with the outer one, under the status bar: a page sees only the system edges, not outer bars.',
      ),
      TryStep(
        'Open The stage, pick Device: iPhone SE, switch off Status bar',
        'Both headers move up to the top together: the system edges are all a page answers to. (On the iPhone 17 the island keeps its inset, so they would stay.)',
      ),
      TryStep(
        'Switch off isPage',
        'The inner header drops back below the outer one: a nested frame counts the outer bar as a system edge.',
      ),
    ],
    realWorld:
        'Further up the coast is another harbor town with its own quays and breakwater. Ships that put in there tie up '
        'to its walls; the first town\'s piers are nothing to them.',
    inYourApp:
        'A frame inside another sees the outer frame\'s bars as system edges, the way a component inside a page should. '
        'A page (a route, a sheet, a dialog) starts fresh: it sees only the system edges, so its header goes under the '
        'status bar, not under the outer page\'s header. HarborFrame.page(...) is the same as isPage: true.',
    art: const NewPortArt(),
    controls: <Widget>[
      ToggleControl(label: 'isPage', value: _isPage, onChanged: (final bool v) => setState(() => _isPage = v)),
    ],
    code:
        'HarborFrame(\n'
        '  top: [HarborBar.overlay(child: PageHeader())],\n'
        '  body: HarborFrame(\n'
        '    isPage: $_isPage,\n'
        '    top: [HarborBar.overlay(child: InnerHeader())],\n'
        '    body: HarborScrollView(slivers: [rows]),\n'
        '  ),\n'
        ')',
    stage: (final BuildContext context) => HarborFrame(
      debugLabel: 'outer frame',
      top: <HarborBar>[
        HarborBar.overlay(
          backdrop: IgnorePointer(child: ColoredBox(color: Palette.night.withValues(alpha: 0.55))),
          debugLabel: 'outer bar',
          child: const StageHeader(key: ValueKey<String>('outer header'), title: 'outer HarborFrame'),
        ),
      ],
      body: StageProbe(
        label: 'outer frame body',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: Palette.brass.withValues(alpha: 0.6), width: 2)),
            ),
            child: HarborFrame(
              isPage: _isPage,
              debugLabel: 'inner frame',
              top: <HarborBar>[
                HarborBar.overlay(
                  edgeEffect: const HarborEdgeEffect.fade(length: 12),
                  backdrop: ColoredBox(color: Palette.brass.withValues(alpha: 0.75)),
                  debugLabel: 'inner bar',
                  child: StageHeader(
                    key: const ValueKey<String>('inner header'),
                    title: 'HarborFrame(isPage: $_isPage)',
                    color: Palette.night,
                  ),
                ),
              ],
              body: StageProbe(
                label: 'inner frame body',
                child: HarborScrollView(
                  slivers: <Widget>[
                    SliverList.builder(
                      itemCount: 20,
                      itemBuilder: (final BuildContext context, final int i) => StageRow(index: i),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// `HarborSizing.hug`: a frame as tall as its body and solid bars.
class HugBodyEntry extends StatefulWidget {
  const HugBodyEntry({super.key});

  @override
  State<HugBodyEntry> createState() => _HugBodyEntryState();
}

class _HugBodyEntryState extends State<HugBodyEntry> {
  HarborSizing _sizing = const HarborSizing.hug();
  double _height = 180;

  @override
  Widget build(final BuildContext context) => GuidePage(
    className: 'HarborSizing.hug',
    tryThis: const <TryStep>[
      TryStep(
        'Slide body height to 300',
        'The sheet grows with its body and stays on the bottom: hug() makes the frame as tall as its body plus its bar.',
      ),
      TryStep(
        'Open The stage and pick Device: iPhone SE',
        'The sheet is 34 shorter: no home indicator for the bar to absorb, and the frame hugs what is left.',
      ),
      TryStep(
        'Pick sizing: fill',
        'The sheet takes the whole screen whatever the body asks for: fill, the default, is how a page sizes.',
      ),
      TryStep(
        'Slide body height again',
        'Only the label changes and the sheet stays full height: under fill, the body is given the space, not asked for it.',
      ),
    ],
    realWorld:
        'A davit on the quay hoists a skiff out of the water. The winch takes in just enough cable to lift the boat clear, '
        'so the load hangs exactly as tall as the boat it carries.',
    inYourApp:
        'A frame that is as tall as its body and solid bars, not as tall as the space it is given: a content-sized sheet or '
        'panel. HarborSizing.fill (the default) takes the whole height, as a page does.',
    art: const HugBodyArt(),
    controls: <Widget>[
      ChoiceControl<HarborSizing>(
        label: 'sizing',
        values: const <HarborSizing>[HarborSizing.hug(), HarborSizing.fill],
        value: _sizing,
        labelOf: (final HarborSizing s) => s.hugs ? 'hug()' : 'fill',
        onChanged: (final HarborSizing s) => setState(() => _sizing = s),
      ),
      SliderControl(
        label: 'body height',
        value: _height,
        min: 60,
        max: 520,
        onChanged: (final double v) => setState(() => _height = v),
      ),
    ],
    code:
        'HarborFrame(\n'
        '  sizing: HarborSizing.${_sizing.hugs ? 'hug()' : 'fill'},\n'
        '  bottom: [HarborBar.solid(child: Actions())],\n'
        '  body: SizedBox(height: ${_height.toStringAsFixed(0)}, child: Crate()),\n'
        ')',
    stage: (final BuildContext context) => Stack(
      children: <Widget>[
        // The page underneath, dimmed.
        Positioned.fill(
          child: Opacity(
            opacity: 0.35,
            child: HarborClear(
              edges: const <HarborEdge>{HarborEdge.top},
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[for (int i = 0; i < 14; i++) StageRow(index: i)],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Palette.night,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              boxShadow: <BoxShadow>[BoxShadow(blurRadius: 14, color: Colors.black54)],
            ),
            child: HarborHandled(
              edges: const <HarborEdge>{HarborEdge.top},
              child: HarborFrame(
                key: const ValueKey<String>('sized frame'),
                sizing: _sizing,
                debugLabel: 'hugBody frame',
                bottom: const <HarborBar>[
                  HarborBar.solid(
                    backdrop: QuayStones(),
                    child: StageBar(label: 'HarborBar.solid', icon: Icons.precision_manufacturing_rounded),
                  ),
                ],
                body: StageProbe(
                  label: 'frame body (${_sizing.hugs ? 'hug' : 'fill'})',
                  child: SizedBox(
                    key: const ValueKey<String>('sized body'),
                    height: _height,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(width: 72, height: 72, child: CrateArt()),
                          const SizedBox(height: 6),
                          Text(
                            'body ${_height.toStringAsFixed(0)} tall',
                            style: const TextStyle(fontFamily: 'Menlo', color: Palette.brass, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
