import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _bar(final String label, final double height) => SizedBox(
  key: ValueKey<String>(label),
  height: height,
  width: double.infinity,
  child: Text(label),
);

Widget _app(final Widget home, {final HarborCoast coast = HarborCoast.ambient, final EdgeInsetsDirectional? margin}) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborSea(coast: coast, margin: margin, child: child!),
  home: Material(child: home),
);

Widget _box(final String label, final double width, final double height) =>
    SizedBox(key: ValueKey<String>(label), width: width, height: height);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

void main() {
  testWidgets('a sliver dock first in a fairway takes the status bar and pins there', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: HarborFairway(
            slivers: <Widget>[
              HarborSliverDock(child: _bar('dock', 48)),
              HarborSliverDock(child: _bar('tabs', 40)),
              SliverList.builder(itemCount: 50, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50)),
            ],
          ),
        ),
      ),
    );
    expect(_rect(tester, 'dock').top, 62);
    expect(_rect(tester, 'tabs').top, 62 + 48);
    await tester.drag(find.byType(Scrollable), const Offset(0, -600));
    await tester.pumpAndSettle();
    // Both stay pinned, stacked, below the status bar.
    expect(_rect(tester, 'dock').top, 62);
    expect(_rect(tester, 'tabs').top, 62 + 48);
  });

  testWidgets('a sliver dock under a pier pins below the pier', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          body: HarborFairway(
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              HarborSliverDock(child: _bar('tabs', 40)),
              SliverList.builder(itemCount: 50, itemBuilder: (final BuildContext c, final int i) => const SizedBox(height: 50)),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'tabs').top, _rect(tester, 'header').bottom);
  });

  testWidgets('a horizontal fairway pads both ends by the mooring line and runs to the frame edge', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        HarborFairway(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: HarborFairway(
                  scrollDirection: Axis.horizontal,
                  slivers: <Widget>[
                    SliverList.builder(
                      itemCount: 20,
                      itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('card$i'), width: 120),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      ),
    );
    expect(_rect(tester, 'card0').left, 16);
    expect(tester.getRect(find.byType(Scrollable).last).width, 402);
    await tester.drag(find.byType(Scrollable).last, const Offset(-5000, 0));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'card19').right, 402 - 16);
  });

  testWidgets('a horizontal fairway clears a side cutout plus the margin in landscape', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Center(
          child: SizedBox(
            height: 100,
            child: HarborFairway(
              scrollDirection: Axis.horizontal,
              slivers: <Widget>[
                SliverList.builder(itemCount: 20, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('card$i'), width: 120)),
              ],
            ),
          ),
        ),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      ),
      device: HarborTrialDevice.iPhone17Landscape,
    );
    expect(_rect(tester, 'card0').left, 62 + 16);
  });

  testWidgets('a dark dock keeps its ground; a withdrawn one gives it back', (final tester) async {
    final ValueNotifier<HarborDockState> state = ValueNotifier<HarborDockState>(HarborDockState.open);
    await tester.pumpSeaTrial(
      _app(
        ValueListenableBuilder<HarborDockState>(
          valueListenable: state,
          builder: (final BuildContext context, final HarborDockState s, final Widget? _) => Harbor(
            top: <HarborDock>[HarborDock.pier(key: const ValueKey<String>('h'), state: s, child: _bar('header', 50))],
            body: const HarborMoored(child: SizedBox.expand(key: ValueKey<String>('body'))),
          ),
        ),
      ),
    );
    expect(_rect(tester, 'body').top, 62 + 50);
    state.value = HarborDockState.dark;
    await tester.pumpAndSettle();
    expect(_rect(tester, 'body').top, 62 + 50);
    state.value = HarborDockState.withdrawn;
    await tester.pumpAndSettle();
    expect(_rect(tester, 'body').top, 62);
  });

  testWidgets('a hold policy keeps the ground until the dock has gone', (final tester) async {
    final ValueNotifier<HarborDockState> state = ValueNotifier<HarborDockState>(HarborDockState.open);
    await tester.pumpSeaTrial(
      _app(
        ValueListenableBuilder<HarborDockState>(
          valueListenable: state,
          builder: (final BuildContext context, final HarborDockState s, final Widget? _) => Harbor(
            bottom: <HarborDock>[
              HarborDock.quay(key: const ValueKey<String>('s'), state: s, duration: const Duration(milliseconds: 200), child: _bar('strip', 60)),
            ],
            body: const SizedBox.expand(key: ValueKey<String>('body')),
          ),
        ),
      ),
    );
    final double resting = _rect(tester, 'body').bottom;
    state.value = HarborDockState.withdrawn;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_rect(tester, 'body').bottom, resting);
    await tester.pumpAndSettle();
    expect(_rect(tester, 'body').bottom, 874);
  });

  testWidgets('a dock that withdraws at high tide leaves while the keyboard is up', (final tester) async {
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          bodyClearsTide: false,
          bottom: <HarborDock>[HarborDock.pier(withdrawsAtHighTide: true, child: _bar('tools', 50))],
          body: const SizedBox.expand(),
        ),
      ),
    );
    expect(tester.getSize(find.byType(HarborDockSlot).first).height, greaterThan(0));
    await trial.raiseTide();
    final RenderBox frame = tester.renderObject<RenderBox>(find.byType(HarborDockSlot).first);
    expect(frame.size.height, 0);
  });

  testWidgets('a signal goes to the port on top and clears its footer', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          debugLabel: 'page',
          bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', 56))],
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    HarborSignals.raise(pageContext, slot: HarborSignalSlot.low, builder: (final BuildContext c) => _bar('toast', 30), duration: null);
    await tester.pumpAndSettle();
    expect(_rect(tester, 'toast').bottom, lessThanOrEqualTo(_rect(tester, 'nav').top));
  });

  testWidgets('an anchored buoy sits above its anchor in a dock, overlapping it', (final tester) async {
    final HarborAnchor anchor = HarborAnchor();
    addTearDown(anchor.dispose);
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          bottom: <HarborDock>[
            HarborDock.quay(
              child: SizedBox(
                height: 56,
                child: Center(child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(key: ValueKey<String>('button'), width: 40, height: 40))),
              ),
            ),
          ],
          buoys: <HarborBuoy>[
            HarborBuoy.anchored(anchor: anchor, gap: 4, overlap: 10, child: const SizedBox(key: ValueKey<String>('bubble'), width: 100, height: 30)),
          ],
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    final Rect button = _rect(tester, 'button');
    final Rect bubble = _rect(tester, 'bubble');
    expect(bubble.bottom, button.top - 4 + 10);
    expect(bubble.center.dx, button.center.dx);
  });

  testWidgets('an anchored buoy before its anchor sits on the right under right-to-left', (final tester) async {
    final HarborAnchor anchor = HarborAnchor();
    addTearDown(anchor.dispose);
    await tester.pumpSeaTrial(
      _app(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Harbor(
            buoys: <HarborBuoy>[
              HarborBuoy.anchored(anchor: anchor, side: HarborBuoySide.before, child: _box('before', 60, 30)),
            ],
            body: Center(child: HarborAnchorPoint(anchor: anchor, child: _box('button', 40, 40))),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(_rect(tester, 'before').left, _rect(tester, 'button').right + 8);
  });

  testWidgets('an anchored buoy whose anchor is not in the tree takes no taps', (final tester) async {
    final HarborAnchor anchor = HarborAnchor();
    addTearDown(anchor.dispose);
    int pageTaps = 0;
    int bubbleTaps = 0;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          buoys: <HarborBuoy>[
            HarborBuoy.anchored(
              anchor: anchor,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => bubbleTaps++, child: _box('bubble', 100, 30)),
            ),
          ],
          body: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => pageTaps++, child: const SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    expect(pageTaps, 1);
    expect(bubbleTaps, 0);
  });

  testWidgets('an anchored buoy whose anchor leaves takes no taps where it last sat', (final tester) async {
    final HarborAnchor anchor = HarborAnchor();
    addTearDown(anchor.dispose);
    final ValueNotifier<bool> anchored = ValueNotifier<bool>(true);
    addTearDown(anchored.dispose);
    int pageTaps = 0;
    int bubbleTaps = 0;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          buoys: <HarborBuoy>[
            HarborBuoy.anchored(
              anchor: anchor,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => bubbleTaps++, child: _box('bubble', 100, 30)),
            ),
          ],
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => pageTaps++,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: anchored,
                builder: (final BuildContext context, final bool value, final Widget? _) =>
                    value ? HarborAnchorPoint(anchor: anchor, child: _box('button', 40, 40)) : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final Offset bubbleCenter = _rect(tester, 'bubble').center;
    await tester.tapAt(bubbleCenter);
    expect(bubbleTaps, 1);

    anchored.value = false;
    await tester.pump();
    await tester.pump();
    await tester.tapAt(bubbleCenter);
    expect(pageTaps, 1);
    expect(bubbleTaps, 1);
  });

  group('A portal buoy', () {
    Widget page({required final OverlayPortalController menu, required final Alignment rowAt, final TextDirection? direction}) {
      final Widget harbor = Harbor(
        bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', 56))],
        body: Align(
          alignment: rowAt,
          child: HarborPortalBuoy(
            controller: menu,
            side: HarborBuoySide.below,
            buoyBuilder: (final BuildContext context) => _box('menu', 200, 120),
            child: _bar('row', 48),
          ),
        ),
      );
      return _app(direction == null ? harbor : Directionality(textDirection: direction, child: harbor));
    }

    testWidgets('opens below its row when the menu fits there', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      await tester.pumpSeaTrial(page(menu: menu, rowAt: Alignment.topCenter));
      menu.show();
      await tester.pump();
      expect(_rect(tester, 'menu').top, _rect(tester, 'row').bottom + 8);
      expect(_rect(tester, 'menu').center.dx, _rect(tester, 'row').center.dx);
    });

    testWidgets('opened from a row near the bottom, flips above it, clear of the bottom dock', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      final HarborSeaTrial trial = await tester.pumpSeaTrial(page(menu: menu, rowAt: Alignment.bottomCenter));
      menu.show();
      await tester.pump();
      final Rect row = _rect(tester, 'row');
      expect(_rect(tester, 'menu').bottom, row.top - 8);
      expect(_rect(tester, 'menu').bottom, lessThanOrEqualTo(_rect(tester, 'nav').top));
      expect(find.byKey(const ValueKey<String>('menu')), isInClearWater(trial.clearWaterAround(find.byKey(const ValueKey<String>('row')))));
    });

    testWidgets('opened from a row near the bottom with the keyboard up, flips above it, clear of the keyboard', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      final HarborSeaTrial trial = await tester.pumpSeaTrial(page(menu: menu, rowAt: Alignment.bottomCenter));
      await trial.raiseTide();
      menu.show();
      await tester.pump();
      final Rect row = _rect(tester, 'row');
      expect(row.bottom, trial.waterline);
      expect(_rect(tester, 'menu').bottom, row.top - 8);
      expect(find.byKey(const ValueKey<String>('menu')), isInClearWater(trial.clearWaterAround(find.byKey(const ValueKey<String>('row')))));
    });

    testWidgets('follows its row as the keyboard rises while it is open', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      final HarborSeaTrial trial = await tester.pumpSeaTrial(page(menu: menu, rowAt: Alignment.bottomCenter));
      menu.show();
      await tester.pump();
      await trial.raiseTide();
      expect(_rect(tester, 'menu').bottom, _rect(tester, 'row').top - 8);
      expect(_rect(tester, 'menu').bottom, lessThanOrEqualTo(trial.waterline));
    });

    testWidgets('takes taps where it is placed, and lets the rest reach the page', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      int menuTaps = 0;
      int pageTaps = 0;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => pageTaps++,
              child: Center(
                child: HarborPortalBuoy(
                  controller: menu,
                  side: HarborBuoySide.below,
                  buoyBuilder: (final BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => menuTaps++, child: _box('menu', 200, 120)),
                  child: _bar('row', 48),
                ),
              ),
            ),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      await tester.tapAt(_rect(tester, 'menu').center);
      await tester.tapAt(_rect(tester, 'menu').topLeft - const Offset(0, 100));
      expect((menuTaps, pageTaps), (1, 1));
    });

    testWidgets('too tall for either side, is clamped into the clear water', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', 56))],
            body: Center(
              child: HarborPortalBuoy(
                controller: menu,
                side: HarborBuoySide.below,
                buoyBuilder: (final BuildContext context) => _box('menu', 200, 600),
                child: _bar('row', 48),
              ),
            ),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      final Rect water = trial.clearWaterAround(find.byKey(const ValueKey<String>('row')));
      expect(_rect(tester, 'menu').bottom, water.bottom - 8);
      expect(find.byKey(const ValueKey<String>('menu')), isInClearWater(water));
    });

    testWidgets('anchored to a HarborAnchor elsewhere, sits by that anchor rather than its own child', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      final HarborAnchor anchor = HarborAnchor();
      addTearDown(anchor.dispose);
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            top: <HarborDock>[HarborDock.quay(child: HarborAnchorPoint(anchor: anchor, child: _bar('header', 50)))],
            body: Center(
              child: HarborPortalBuoy(
                controller: menu,
                anchor: anchor,
                side: HarborBuoySide.below,
                buoyBuilder: (final BuildContext context) => _box('menu', 200, 120),
                child: _bar('row', 48),
              ),
            ),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      expect(_rect(tester, 'menu').top, _rect(tester, 'header').bottom + 8);
    });

    testWidgets('after its anchor sits on the left under right-to-left', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      await tester.pumpSeaTrial(
        _app(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Harbor(
              body: Center(
                child: HarborPortalBuoy(
                  controller: menu,
                  side: HarborBuoySide.after,
                  buoyBuilder: (final BuildContext context) => _box('menu', 60, 30),
                  child: _box('button', 40, 40),
                ),
              ),
            ),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      expect(_rect(tester, 'menu').right, _rect(tester, 'button').left - 8);
    });

    testWidgets('after its anchor that does not fit on the left flips to the right under right-to-left', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      await tester.pumpSeaTrial(
        _app(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Harbor(
              body: Align(
                alignment: Alignment.centerLeft,
                child: HarborPortalBuoy(
                  controller: menu,
                  side: HarborBuoySide.after,
                  buoyBuilder: (final BuildContext context) => _box('menu', 60, 30),
                  child: _box('button', 40, 40),
                ),
              ),
            ),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      expect(_rect(tester, 'menu').left, _rect(tester, 'button').right + 8);
    });
  });

  testWidgets('a lifted beacon rises clear of a breakwater sheet and settles back', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const HarborLighthouseRegion(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 700,
                      left: 100,
                      child: HarborBeacon(lift: true, clearance: 20, child: SizedBox(key: ValueKey<String>('boat'), width: 60, height: 40)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => const HarborSheet(body: SizedBox(height: 300)),
    ));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    final Rect boat = _rect(tester, 'boat');
    final Rect sheet = tester.getRect(find.byType(HarborSheet));
    expect(boat.bottom, lessThanOrEqualTo(sheet.top - 20 + 1));
  });

  testWidgets('a beacon reports how much of it the header covers', (final tester) async {
    final List<double> reports = <double>[];
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          body: HarborFairway(
            slivers: <Widget>[
              SliverToBoxAdapter(child: HarborBeacon(onObscured: reports.add, child: const SizedBox(height: 100))),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(reports.last, 0.0);
    await tester.drag(find.byType(Scrollable), const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(reports.last, closeTo(0.5, 0.05));
  });

  testWidgets('a title-safe coast keeps a TV page inside its band', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        const Harbor(body: HarborMoored(child: SizedBox.expand(key: ValueKey<String>('page')))),
        coast: const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),
      ),
      device: HarborTrialDevice.television,
    );
    expect(_rect(tester, 'page'), const Rect.fromLTRB(96, 54, 1920 - 96, 1080 - 54));
  });

  testWidgets('a scale model lays out at its reference size and re-bases the coast', (final tester) async {
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) =>
            HarborScaleModel(referenceSize: const Size(1200, 675), child: HarborSea(child: child!)),
        home: Builder(
          builder: (final BuildContext context) => Text(
            '${MediaQuery.sizeOf(context)} ${MediaQuery.paddingOf(context)}',
            key: const ValueKey<String>('probe'),
          ),
        ),
      ),
    );
    final Text probe = tester.widget<Text>(find.byKey(const ValueKey<String>('probe')));
    // A letterboxed 16:9 model on a tall phone is clear of the island and the home indicator.
    expect(probe.data, 'Size(1200.0, 675.0) EdgeInsets.zero');
  });

  testWidgets('a draggable sheet rests at its fraction of the space above the keyboard', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      builder: (final BuildContext context) => HarborSheet.draggable(
        header: _bar('sheetHeader', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: <Widget>[
            SliverList.builder(itemCount: 40, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('item$i'), height: 50)),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final Rect header = _rect(tester, 'sheetHeader');
    // Half of the space between the status bar and the bottom.
    expect(header.top, closeTo(874 - (874 - 62) * 0.5, 1));
    // The first item rests below the header and its wake.
    expect(_rect(tester, 'item0').top, header.bottom + 12);
  });

  testWidgets('a content-sized sheet footer clears the home indicator once', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      builder: (final BuildContext context) => HarborSheet(
        header: _bar('sheetHeader', 40),
        footer: _bar('footer', 48),
        body: const SizedBox(key: ValueKey<String>('content'), height: 120),
      ),
    ));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'footer').bottom, 874 - 34);
    expect(_rect(tester, 'content').bottom, lessThanOrEqualTo(_rect(tester, 'footer').top + 0.5));
  });

  testWidgets('a dry dock runs to the screen edge, whatever its minimum', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          minimum: const EdgeInsetsDirectional.only(bottom: 16),
          bottom: <HarborDock>[
            HarborDock.quay(tide: HarborTideStance.dryDock, minimum: 24, child: _bar('tray', 120)),
          ],
          body: const SizedBox.expand(),
        ),
      ),
    );
    expect(_rect(tester, 'tray').bottom, 874);
  });

  testWidgets('a floating dock never dips while a short keyboard comes in', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          bottom: <HarborDock>[HarborDock.quay(tide: HarborTideStance.float, child: _bar('composer', 56))],
          body: const SizedBox.expand(),
        ),
      ),
    );
    expect(_rect(tester, 'composer').bottom, 874 - 34);
    // As the platform has it: the bottom padding is gone as soon as any
    // keyboard is in, while the keyboard itself is still coming up.
    Future<void> keyboard(final double height) async {
      tester.view
        ..padding = FakeViewPadding(top: 62, bottom: height > 0 ? 0 : 34)
        ..viewInsets = FakeViewPadding(bottom: height);
      await tester.pump();
    }

    for (final double height in <double>[1, 17, 33]) {
      await keyboard(height);
      expect(_rect(tester, 'composer').bottom, 874 - 34, reason: 'keyboard $height: covered by the home indicator');
    }
    await keyboard(100);
    expect(_rect(tester, 'composer').bottom, 874 - 100, reason: 'above the home indicator it rides the keyboard');
    await keyboard(0);
    expect(_rect(tester, 'composer').bottom, 874 - 34);
  });

  testWidgets('a content-sized sheet with a header has no gap above its footer', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      builder: (final BuildContext context) => HarborSheet(
        header: _bar('sheetHeader', 60),
        footer: _bar('footer', 48),
        // The fairway runs under the header pier, so it shrink-wraps to the
        // header, its wake and its rows: no more.
        body: HarborFairway.box(
          shrinkWrap: true,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 3; i++) SizedBox(key: ValueKey<String>('row $i'), height: 56),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'row 0').top, _rect(tester, 'sheetHeader').bottom + 12);
    expect(_rect(tester, 'row 2').bottom, _rect(tester, 'footer').top);
    expect(_rect(tester, 'footer').bottom, 874 - 34);
  });

  testWidgets('a sticky pill sticks below the header until its card scrolls away', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          body: const HarborFairway(
            slivers: <Widget>[
              SliverToBoxAdapter(child: SizedBox(height: 100)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 400,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: HarborSticky(gap: 8, child: SizedBox(key: ValueKey<String>('pill'), width: 80, height: 30)),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    final double headerBottom = _rect(tester, 'header').bottom;
    await tester.drag(find.byType(Scrollable), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'pill').top, headerBottom + 8);
    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pumpAndSettle();
    // Its card is nearly gone; the pill leaves with it rather than outliving it.
    expect(_rect(tester, 'pill').top, lessThan(headerBottom + 8));
  });

  testWidgets('a centered control overlaps a breakwater by no more than its budget', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const HarborCenter(overlapBudget: 12, child: SizedBox(key: ValueKey<String>('controls'), width: 100, height: 200));
            },
          ),
        ),
      ),
    );
    expect(_rect(tester, 'controls').center.dy, 874 / 2);
    unawaited(showHarborSheet<void>(
      pageContext,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => const HarborSheet(body: SizedBox(height: 420)),
    ));
    await tester.pumpAndSettle();
    final Rect sheet = tester.getRect(find.byType(HarborSheet));
    expect(_rect(tester, 'controls').bottom, lessThanOrEqualTo(sheet.top + 12 + 0.5));
  });

  testWidgets('open water under a pier with a wake is not faded; only fairways are', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(wake: const HarborWake.fade(), child: _bar('header', 50))],
          body: HarborOpenWater(builder: (final BuildContext c, final HarborWatersData w) => const ColoredBox(color: Colors.red)),
        ),
      ),
    );
    expect(find.byType(HarborWakeMask), findsNothing);
  });

  testWidgets('a component harbor reports its port\'s frame size, which the keyboard does not shrink', (final tester) async {
    late BuildContext inner;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          body: Harbor(
            body: Builder(
              builder: (final BuildContext context) {
                inner = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    await trial.raiseTide();
    expect(HarborWaters.of(inner).frameSize, const Size(402, 874));
  });

  testWidgets('a non-modal sheet closes from its own builder context, leaving the page', (final tester) async {
    late BuildContext pageContext;
    late BuildContext sheetContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand(key: ValueKey<String>('page'));
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) {
        sheetContext = context;
        return const HarborSheet(body: SizedBox(key: ValueKey<String>('sheet body'), height: 100));
      },
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('sheet body')), findsOneWidget);
    HarborSheet.close(sheetContext);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('sheet body')), findsNothing);
    expect(find.byKey(const ValueKey<String>('page')), findsOneWidget);
  });

  testWidgets('a fairway can start in open water under a translucent header', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(wake: const HarborWake.fade(length: 10), child: _bar('header', 50))],
          body: HarborFairway(
            startsInOpenWater: true,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(key: ValueKey<String>('hero'), height: 300)),
              HarborSliverDock(child: _bar('tabs', 40)),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    expect(_rect(tester, 'hero').top, 0);
    await tester.drag(find.byType(Scrollable), const Offset(0, -600));
    await tester.pumpAndSettle();
    // Pinned at the docks' face, not at the end of the wake.
    expect(_rect(tester, 'tabs').top, _rect(tester, 'header').bottom);
  });

  testWidgets('a sticky pill sticks below sliver docks pinned in its fairway', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          body: HarborFairway(
            slivers: <Widget>[
              HarborSliverDock(child: _bar('tabs', 40)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 500,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: HarborSticky(gap: 8, child: SizedBox(key: ValueKey<String>('pill'), width: 80, height: 30)),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'pill').top, _rect(tester, 'tabs').bottom + 8);
  });

  testWidgets('ensureVisible on a scrolled horizontal fairway keeps the target clear of its end', (final tester) async {
    final List<GlobalKey> keys = List<GlobalKey>.generate(20, (final int _) => GlobalKey());
    await tester.pumpSeaTrial(
      _app(
        Center(
          child: SizedBox(
            height: 100,
            child: HarborFairway(
              scrollDirection: Axis.horizontal,
              revealMargin: 24,
              slivers: <Widget>[
                SliverList.builder(itemCount: 20, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: keys[i], width: 120)),
              ],
            ),
          ),
        ),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      ),
    );
    for (final int i in <int>[4, 6, 8, 10]) {
      await Scrollable.ensureVisible(keys[i].currentContext!, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(keys[i])).right, lessThanOrEqualTo(402 - 16 - 24 + 0.5));
    }
  });

  testWidgets('a focused field in a scrolled fairway is revealed above the keyboard', (final tester) async {
    final FocusNode focus = FocusNode();
    addTearDown(focus.dispose);
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          bottom: <HarborDock>[HarborDock.quay(child: _bar('footer', 60))],
          body: HarborFairway(
            controller: controller,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: 600)),
              SliverToBoxAdapter(
                child: HarborBeacon(
                  keepInSight: true,
                  onlyWhileFocused: true,
                  clearance: 16,
                  child: TextField(key: const ValueKey<String>('field'), focusNode: focus),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 600)),
            ],
          ),
        ),
      ),
      device: HarborTrialDevice.iPhoneSE,
    );
    controller.jumpTo(300);
    await tester.pump();
    focus.requestFocus();
    await tester.pump();
    await trial.raiseTide();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_rect(tester, 'field').bottom, lessThanOrEqualTo(trial.waterline - 16 + 0.5));
  });

  group('focus moving into a beacon kept in sight with the keyboard up', () {
    Future<HarborSeaTrial> pumpForm(final WidgetTester tester, final FocusNode first, final FocusNode second) =>
        tester.pumpSeaTrial(
          _app(
            Harbor(
              body: HarborFairway(
                slivers: <Widget>[
                  SliverToBoxAdapter(child: TextField(focusNode: first)),
                  const SliverToBoxAdapter(child: SizedBox(height: 520)),
                  SliverToBoxAdapter(
                    child: HarborBeacon(
                      keepInSight: true,
                      onlyWhileFocused: true,
                      clearance: 16,
                      child: Column(
                        key: const ValueKey<String>('group'),
                        children: <Widget>[
                          TextField(key: const ValueKey<String>('second'), focusNode: second),
                          _box('submit', 120, 56),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 1200)),
                ],
              ),
            ),
          ),
        );

    for (final (String how, void Function(FocusNode first, FocusNode second) move)
        in <(String, void Function(FocusNode, FocusNode))>[
          ('a tap', (final FocusNode first, final FocusNode second) => second.requestFocus()),
          ('the next-field action', (final FocusNode first, final FocusNode second) => first.nextFocus()),
        ]) {
      testWidgets('by $how reveals the whole beacon, not only the field\'s caret', (final tester) async {
        final FocusNode first = FocusNode();
        final FocusNode second = FocusNode();
        addTearDown(first.dispose);
        addTearDown(second.dispose);
        final HarborSeaTrial trial = await pumpForm(tester, first, second);
        first.requestFocus();
        await tester.pump();
        await trial.raiseTide(settle: true);
        expect(
          tester.getRect(find.byKey(const ValueKey<String>('submit'), skipOffstage: false)).top,
          greaterThan(trial.waterline),
          reason: 'it starts under the keyboard',
        );

        move(first, second);
        await tester.pumpAndSettle();
        expect(second.hasPrimaryFocus, isTrue);
        final Finder group = find.byKey(const ValueKey<String>('group'));
        expect(group, isInClearWater(trial.clearWaterAround(group)));
        expect(_rect(tester, 'submit').bottom, moreOrLessEquals(trial.waterline - 16, epsilon: 0.5));
      });
    }
  });

  testWidgets('a signal skips a new port embedded in a page', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 120, height: 80, child: Harbor(newPort: true, coast: HarborCoast.none, body: SizedBox.expand())),
              );
            },
          ),
        ),
      ),
    );
    HarborSignals.raise(pageContext, slot: HarborSignalSlot.middle, builder: (final BuildContext c) => _bar('flag', 20), duration: null);
    await tester.pumpAndSettle();
    expect(_rect(tester, 'flag').center.dy, closeTo(874 / 2, 60));
  });

  testWidgets('content that starts in open water keeps the coast it starts under', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 52))],
          body: const HarborFairway(
            startsInOpenWater: true,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: HarborMoored(clear: HarborClear.coast, edges: <HarborEdge>{HarborEdge.top}, child: SizedBox(key: ValueKey<String>('title'), height: 30)),
              ),
            ],
          ),
        ),
      ),
    );
    expect(_rect(tester, 'title').top, 62);
  });

  for (final HarborSheetBarrier barrier in <HarborSheetBarrier>[HarborSheetBarrier.none, HarborSheetBarrier.dismissible]) {
    testWidgets('the page lays out against a breakwater sheet where it is drawn, in every frame of its slide (${barrier.name})', (final tester) async {
      late BuildContext pageContext;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Builder(
              builder: (final BuildContext context) {
                pageContext = context;
                return const HarborMoored(edges: <HarborEdge>{HarborEdge.bottom}, child: SizedBox.expand(key: ValueKey<String>('page')));
              },
            ),
          ),
        ),
      );
      // Clear of the home indicator with no sheet up.
      final double clear = _rect(tester, 'page').bottom;
      void expectPageMeetsSheet(final String when) {
        final double sheetTop = tester.getRect(find.byType(HarborSheet)).top;
        expect(_rect(tester, 'page').bottom, closeTo(math.min(clear, sheetTop), 0.5), reason: when);
      }

      unawaited(showHarborSheet<void>(
        pageContext,
        breakwater: true,
        barrier: barrier,
        builder: (final BuildContext context) => const HarborSheet(body: SizedBox(height: 300)),
      ));
      for (int frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
        expectPageMeetsSheet('opening, frame $frame');
      }
      await tester.pumpAndSettle();
      expect(_rect(tester, 'page').bottom, 874 - 300);
      closeHarborSheet(tester.element(find.byType(HarborSheet)));
      for (int frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 40));
        expectPageMeetsSheet('closing, frame $frame');
      }
      await tester.pumpAndSettle();
      expect(_rect(tester, 'page').bottom, clear);
    });
  }

  testWidgets('the page lays out against a draggable breakwater sheet where it is drawn, as it slides in and is dragged', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const HarborMoored(edges: <HarborEdge>{HarborEdge.bottom}, child: SizedBox.expand(key: ValueKey<String>('page')));
            },
          ),
        ),
      ),
    );
    final double clear = _rect(tester, 'page').bottom;
    void expectPageMeetsSheet(final String when) {
      final double sheetTop = _rect(tester, 'handle').top;
      expect(_rect(tester, 'page').bottom, closeTo(math.min(clear, sheetTop), 0.5), reason: when);
    }

    unawaited(showHarborSheet<void>(
      pageContext,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => HarborSheet.draggable(
        header: _bar('handle', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ));
    // The first frame measures the sheet; it follows from the next one on.
    await tester.pump();
    for (int frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 40));
      expectPageMeetsSheet('opening, frame $frame');
    }
    await tester.pumpAndSettle();
    final TestGesture drag = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey<String>('handle'))));
    for (int step = 0; step < 4; step++) {
      await drag.moveBy(const Offset(0, -30));
      await tester.pump();
      expectPageMeetsSheet('dragged up, step $step');
    }
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a draggable breakwater sheet reports its resting height, not the screen', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      breakwater: true,
      builder: (final BuildContext context) => HarborSheet.draggable(
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(MediaQuery.paddingOf(pageContext).bottom, closeTo((874 - 62) * 0.5, 2));
  });

  testWidgets('a draggable sheet paints its surface only as tall as it is dragged', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      builder: (final BuildContext context) => HarborSheet.draggable(
        surface: const ColoredBox(key: ValueKey<String>('surface'), color: Colors.blue),
        header: _bar('sheetHeader', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: <Widget>[
            SliverList.builder(itemCount: 40, itemBuilder: (final BuildContext c, final int i) => ColoredBox(key: ValueKey<String>('item$i'), color: Colors.white, child: const SizedBox(height: 50))),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'surface').top, closeTo(_rect(tester, 'sheetHeader').top, 1));
    expect(find.byKey(const ValueKey<String>('item0')).hitTestable(), findsOneWidget);
  });

  testWidgets('a sheet carries the text style of the page that opened it', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        DefaultTextStyle(
          style: const TextStyle(fontSize: 21, color: Colors.teal),
          child: Harbor(
            body: Builder(
              builder: (final BuildContext context) {
                pageContext = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => const HarborSheet(body: Text('lyrics', key: ValueKey<String>('lyrics'))),
    ));
    await tester.pumpAndSettle();
    final BuildContext lyrics = tester.element(find.byKey(const ValueKey<String>('lyrics')));
    expect(DefaultTextStyle.of(lyrics).style.fontSize, 21);
    expect(DefaultTextStyle.of(lyrics).style.color, Colors.teal);
  });

  testWidgets('a draggable sheet hauls up by its header', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      builder: (final BuildContext context) => HarborSheet.draggable(
        header: _bar('handle', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final double rest = _rect(tester, 'handle').top;
    await tester.drag(find.byKey(const ValueKey<String>('handle')), const Offset(0, -200));
    await tester.pumpAndSettle();
    // Snapped to the ceiling: 0.88 of the space below the status bar.
    expect(_rect(tester, 'handle').top, lessThan(rest - 150));
    expect(_rect(tester, 'handle').top, closeTo(874 - (874 - 62) * 0.88, 2));
  });

  testWidgets('a content-sized sheet never runs into the status bar', (final tester) async {
    late BuildContext pageContext;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      builder: (final BuildContext context) => HarborSheet(
        maxExtentFraction: 1.0,
        header: _bar('sheetHeader', 40),
        body: HarborFairway.box(shrinkWrap: true, child: const SizedBox(height: 3000)),
      ),
    ));
    await tester.pumpAndSettle();
    await trial.raiseTide();
    expect(_rect(tester, 'sheetHeader').top, greaterThanOrEqualTo(62 - 0.5));
  });

  testWidgets('a signal raised in a nested harbor clears that harbor\'s header too', (final tester) async {
    late BuildContext tabContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', 56))],
          body: Harbor(
            top: <HarborDock>[HarborDock.pier(child: _bar('tab header', 80))],
            body: Builder(
              builder: (final BuildContext context) {
                tabContext = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    HarborSignals.raise(tabContext, slot: HarborSignalSlot.top, builder: (final BuildContext c) => _bar('flag', 20), duration: null);
    await tester.pumpAndSettle();
    expect(_rect(tester, 'flag').top, greaterThanOrEqualTo(_rect(tester, 'tab header').bottom));
  });

  testWidgets('a chart overlay above the sea charts the harbors beneath it', (final tester) async {
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborChartOverlay(child: HarborSea(child: child!)),
        home: Harbor(top: <HarborDock>[HarborDock.pier(debugLabel: 'header', child: _bar('header', 50))], body: const SizedBox.expand()),
      ),
    );
    await tester.pump();
    final BuildContext overlay = tester.element(find.byType(HarborSea));
    final List<HarborChartEntry> chart = HarborChart.snapshot(overlay);
    expect(chart.expand((final HarborChartEntry e) => e.docks).any((final HarborDockRecord d) => d.label == 'header'), isTrue);
  });

  testWidgets('a sea inside a harbor keeps its own tide and signals', (final tester) async {
    late BuildContext inside;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          newPort: true,
          bottom: <HarborDock>[HarborDock.quay(child: _bar('outer nav', 56))],
          body: Center(
            child: SizedBox(
              width: 200,
              height: 300,
              child: MediaQuery(
                data: const MediaQueryData(size: Size(200, 300), viewInsets: EdgeInsets.only(bottom: 120)),
                child: HarborSea(
                  child: Harbor(
                    body: Builder(
                      builder: (final BuildContext context) {
                        inside = context;
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(HarborTide.of(inside).height, 120);
    HarborSignals.raise(inside, slot: HarborSignalSlot.top, builder: (final BuildContext c) => _bar('inner flag', 20), duration: null);
    await tester.pumpAndSettle();
    final Rect stage = tester.getRect(find.byType(HarborSea).last);
    expect(stage.contains(_rect(tester, 'inner flag').center), isTrue);
  });

  testWidgets('a translucent dock with a backdrop lets taps through its empty ground', (final tester) async {
    int taps = 0;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: const <HarborDock>[
            HarborDock.pier(
              hitTestBehavior: HitTestBehavior.translucent,
              backdrop: ColoredBox(color: Colors.brown),
              child: SizedBox(height: 60),
            ),
          ],
          body: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++, child: const SizedBox.expand()),
        ),
      ),
    );
    await tester.tapAt(const Offset(200, 80));
    expect(taps, 1);
  });

  testWidgets('a sticky pill sticks at the docks under a scale', (final tester) async {
    await tester.pumpSeaTrial(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 201,
            height: 437,
            child: FittedBox(
              child: SizedBox(
                width: 402,
                height: 874,
                child: MediaQuery(
                  data: const MediaQueryData(size: Size(402, 874)),
                  child: HarborSea(
                    child: Harbor(
                      top: <HarborDock>[HarborDock.pier(child: _bar('header', 100))],
                      body: const HarborFairway(
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 600,
                              child: Column(
                                children: <Widget>[
                                  HarborSticky(gap: 0, child: SizedBox(key: ValueKey<String>('pill'), height: 20, width: 80)),
                                  Expanded(child: SizedBox()),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 2000)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'pill').top, closeTo(_rect(tester, 'header').bottom, 0.6));
  });

  testWidgets('a harbor that paints its own wake keeps its fairways from fading twice', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          wakePainter: HarborWakeMask.alphaWake,
          top: <HarborDock>[HarborDock.pier(wake: const HarborWake.fade(), child: _bar('header', 50))],
          body: const HarborFairway(slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))]),
        ),
      ),
    );
    final Iterable<HarborWakeMask> masks = tester.widgetList<HarborWakeMask>(find.byType(HarborWakeMask));
    expect(masks.where((final HarborWakeMask m) => m.wakes.isNotEmpty), hasLength(1));
  });

  testWidgets('a breakwater sheet covers the page under a scale', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 201,
            height: 437,
            child: FittedBox(
              child: SizedBox(
                width: 402,
                height: 874,
                child: MediaQuery(
                  data: const MediaQueryData(size: Size(402, 874)),
                  child: HarborSea(
                    child: Navigator(
                      onGenerateRoute: (final RouteSettings _) => PageRouteBuilder<void>(
                        pageBuilder: (final BuildContext c, final Animation<double> a, final Animation<double> b) => Harbor(
                          body: Builder(
                            builder: (final BuildContext context) {
                              pageContext = context;
                              return const SizedBox.expand();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      pageContext,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => const HarborSheet(body: SizedBox(height: 300)),
    ));
    await tester.pumpAndSettle();
    expect(MediaQuery.paddingOf(pageContext).bottom, closeTo(300, 1));
  });

  testWidgets('a horizontal box fairway in a column is as tall as its row and keeps its ends clear', (final tester) async {
    final ValueNotifier<double> chipHeight = ValueNotifier<double>(40);
    addTearDown(chipHeight.dispose);
    await tester.pumpSeaTrial(
      _app(
        HarborMoored(
          child: Column(
            children: <Widget>[
              HarborFairway.box(
                key: const ValueKey<String>('chips'),
                scrollDirection: Axis.horizontal,
                child: ValueListenableBuilder<double>(
                  valueListenable: chipHeight,
                  builder: (final BuildContext context, final double height, final Widget? _) => Row(
                    children: <Widget>[
                      for (int i = 0; i < 8; i++) SizedBox(key: ValueKey<String>('chip$i'), width: 90, height: height),
                    ],
                  ),
                ),
              ),
              _bar('after', 20),
            ],
          ),
        ),
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      ),
    );
    expect(_rect(tester, 'chips').height, 40);
    expect(_rect(tester, 'after').top, _rect(tester, 'chips').bottom);
    expect(_rect(tester, 'chip0').left, 16);
    await tester.drag(find.byType(Scrollable), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'chip7').right, 402 - 16);
    chipHeight.value = 56;
    await tester.pump();
    expect(_rect(tester, 'chips').height, 56, reason: 'it follows its row as the row grows');
    expect(_rect(tester, 'after').top, _rect(tester, 'chips').bottom);
  });

  testWidgets('the steady coast holds the home indicator while the keyboard is up', (final tester) async {
    late BuildContext footer;
    late BuildContext underQuay;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          body: Column(
            children: <Widget>[
              Expanded(
                child: Harbor(
                  bottom: <HarborDock>[HarborDock.quay(child: _bar('tabs', 40))],
                  body: Builder(
                    builder: (final BuildContext context) {
                      underQuay = context;
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
              Builder(
                builder: (final BuildContext context) {
                  footer = context;
                  return const SizedBox(height: 40);
                },
              ),
            ],
          ),
        ),
      ),
    );
    expect(HarborWaters.steadyCoastOf(footer, HarborEdge.bottom), 34);
    expect(HarborWaters.steadyCoastOf(footer, HarborEdge.top), 62, reason: 'the coast alone, not the header');
    expect(HarborWaters.steadyCoastOf(underQuay, HarborEdge.bottom), 0, reason: 'the quay absorbed it');
    await trial.raiseTide();
    expect(HarborWaters.of(footer).coast.bottom, 0, reason: 'the live coast goes as the keyboard comes in');
    expect(HarborWaters.steadyCoastOf(footer, HarborEdge.bottom), 34);
  });

  testWidgets('the steady coast is cast off with its edge', (final tester) async {
    late BuildContext castOff;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: HarborCastOff(
            edges: const <HarborEdge>{HarborEdge.bottom},
            child: Builder(
              builder: (final BuildContext context) {
                castOff = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    expect(HarborWaters.steadyCoastOf(castOff, HarborEdge.top), 62, reason: 'positive control');
    expect(HarborWaters.steadyCoastOf(castOff, HarborEdge.bottom), 0);
  });

  testWidgets('a fairway keeps its minimum at an end nothing covers', (final tester) async {
    Future<double> lastRowBottom(final HarborTrialDevice device) async {
      await tester.pumpSeaTrial(
        _app(
          HarborFairway(
            minimum: const EdgeInsetsDirectional.only(bottom: 16),
            slivers: <Widget>[
              SliverList.builder(itemCount: 30, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50)),
            ],
          ),
        ),
        device: device,
      );
      await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
      await tester.pumpAndSettle();
      return _rect(tester, 'row29').bottom;
    }

    expect(await lastRowBottom(HarborTrialDevice.iPhoneSE), 667 - 16);
    expect(await lastRowBottom(HarborTrialDevice.iPhone17), 874 - 34, reason: 'the larger of the two, not both');
  });

  testWidgets('a fairway sliver keeps its minimum at an end nothing covers', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        CustomScrollView(
          slivers: <Widget>[
            HarborFairwaySliver(
              minimum: const EdgeInsetsDirectional.only(bottom: 16),
              sliver: SliverList.builder(itemCount: 30, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50)),
            ),
          ],
        ),
      ),
      device: HarborTrialDevice.iPhoneSE,
    );
    await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'row29').bottom, 667 - 16);
  });

  testWidgets('a footer moored on the bottom alone clears the coast and the keyboard, not the header', (final tester) async {
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          bodyClearsTide: false,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: HarborMoored(edges: const <HarborEdge>{HarborEdge.bottom}, child: _bar('footer', 40)),
          ),
        ),
      ),
    );
    expect(_rect(tester, 'footer').bottom, 874 - 34);
    await trial.raiseTide();
    expect(_rect(tester, 'footer').bottom, trial.waterline);
    expect(_rect(tester, 'footer').height, 40);
  });

  group('insets take EdgeInsetsGeometry, resolved against the reading direction', () {
    Widget rtl(final Widget home, {final HarborCoast coast = HarborCoast.ambient, final EdgeInsetsGeometry? margin}) => MaterialApp(
      builder: (final BuildContext context, final Widget? child) => Directionality(
        textDirection: TextDirection.rtl,
        child: HarborSea(coast: coast, margin: margin, child: child!),
      ),
      home: Material(child: home),
    );
    Widget rows() => SliverList.builder(
      itemCount: 30,
      itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50),
    );

    testWidgets("the sea's mooring line keeps a physical left on the left", (final tester) async {
      await tester.pumpSeaTrial(rtl(HarborMooringLine(child: _bar('row', 40)), margin: const EdgeInsets.only(left: 24)));
      expect(_rect(tester, 'row').left, 24);
      expect(_rect(tester, 'row').right, 402);
    });

    testWidgets("a harbor's margin and minimum keep a physical side where they say", (final tester) async {
      await tester.pumpSeaTrial(
        rtl(
          Harbor(
            margin: const EdgeInsets.only(right: 12),
            minimum: const EdgeInsets.only(left: 30),
            body: HarborMoored(mooringLine: true, child: _bar('form', 40)),
          ),
        ),
      );
      expect(_rect(tester, 'form').left, 30);
      expect(_rect(tester, 'form').right, 402 - 12);
    });

    testWidgets("a fairway's padding and minimum keep a physical side where they say", (final tester) async {
      await tester.pumpSeaTrial(
        rtl(HarborFairway(padding: const EdgeInsets.only(left: 12), minimum: const EdgeInsets.only(bottom: 16), slivers: <Widget>[rows()])),
        device: HarborTrialDevice.iPhoneSE,
      );
      expect(_rect(tester, 'row0').left, 12);
      expect(_rect(tester, 'row0').right, 375);
      await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row29').bottom, 667 - 16);
    });

    testWidgets('a fairway sliver takes the same', (final tester) async {
      await tester.pumpSeaTrial(
        rtl(
          CustomScrollView(
            slivers: <Widget>[
              HarborFairwaySliver(padding: const EdgeInsets.only(left: 12), minimum: const EdgeInsets.only(bottom: 16), sliver: rows()),
            ],
          ),
        ),
        device: HarborTrialDevice.iPhoneSE,
      );
      expect(_rect(tester, 'row0').left, 12);
      await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row29').bottom, 667 - 16);
    });

    testWidgets("paddingOf resolves its extra and minimum the way it resolves what it returns", (final tester) async {
      late EdgeInsets padding;
      await tester.pumpSeaTrial(
        rtl(
          Builder(
            builder: (final BuildContext context) {
              padding = HarborFairway.paddingOf(
                context,
                extra: const EdgeInsets.only(left: 5),
                minimum: const EdgeInsetsDirectional.only(bottom: 16).add(const EdgeInsets.only(bottom: 4)),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
        device: HarborTrialDevice.iPhoneSE,
      );
      expect(padding, const EdgeInsets.only(left: 5, top: 20, bottom: 20));
    });

    testWidgets("a moored widget's minimum and extra, and clearanceOf, keep a physical side where they say", (final tester) async {
      late EdgeInsetsDirectional clearance;
      await tester.pumpSeaTrial(
        rtl(
          Builder(
            builder: (final BuildContext context) {
              clearance = HarborMoored.clearanceOf(context, minimum: const EdgeInsets.only(left: 30), extra: const EdgeInsets.only(right: 6));
              return HarborMoored(minimum: const EdgeInsets.only(left: 30), extra: const EdgeInsets.only(right: 6), child: _bar('form', 40));
            },
          ),
        ),
      );
      expect(_rect(tester, 'form').left, 30);
      expect(_rect(tester, 'form').right, 402 - 6);
      expect(clearance, const EdgeInsetsDirectional.fromSTEB(6, 62, 30, 34));
    });

    testWidgets('a fixed coast and a fixed title-safe band keep a physical side where they say', (final tester) async {
      Future<EdgeInsets> paddingUnder(final HarborCoast coast) async {
        late EdgeInsets padding;
        await tester.pumpSeaTrial(
          rtl(
            Builder(
              builder: (final BuildContext context) {
                padding = MediaQuery.paddingOf(context);
                return const SizedBox.shrink();
              },
            ),
            coast: coast,
          ),
        );
        return padding;
      }

      expect(await paddingUnder(const HarborCoast.fixed(EdgeInsets.only(left: 40))), const EdgeInsets.only(left: 40));
      expect(
        await paddingUnder(const HarborCoast.titleSafe(HarborTitleSafe.fixed(EdgeInsets.only(left: 40)))),
        const EdgeInsets.only(left: 40, top: 62, bottom: 34),
      );
    });

    testWidgets('a directional inset still follows the reading direction', (final tester) async {
      await tester.pumpSeaTrial(rtl(HarborMooringLine(child: _bar('row', 40)), margin: const EdgeInsetsDirectional.only(start: 24)));
      expect(_rect(tester, 'row').right, 402 - 24);
      expect(_rect(tester, 'row').left, 0);
    });
  });
}
