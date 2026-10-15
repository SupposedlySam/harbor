// #142: a root-overlay portal's child, declared in a page whose frame has a bottom bar, reads that
// frame's room. Flutter hands the child the overlay's MediaQuery padding; a frame in the child
// splits it into system edges and bars by the declaring frame's room, which had none at the bottom.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const Key _content = Key('content');
const Widget _box = ColoredBox(key: _content, color: Color(0xFF000000), child: SizedBox.expand());

/// A tab host (a frame with a solid bottom bar) whose page declares a root-overlay portal showing
/// [overlayChild].
Future<void> _host(final WidgetTester tester, {required final Widget overlayChild}) async {
  final OverlayPortalController portal = OverlayPortalController()..show();
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: HarborFrame(
        bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 50))],
        body: Center(
          child: OverlayPortal(
            controller: portal,
            overlayLocation: OverlayChildLocation.rootOverlay,
            overlayChildBuilder: (final BuildContext _) => overlayChild,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // iPhone 17: a 62 status bar and a 34 home indicator on an 874-tall screen.
  const double homeIndicatorTop = 874.0 - 34.0;

  testWidgets('positive control: the declaring page reads no bottom system edge (its bar holds it)', (
    final tester,
  ) async {
    late BuildContext page;
    final OverlayPortalController portal = OverlayPortalController();
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 50))],
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return OverlayPortal(
                controller: portal,
                overlayChildBuilder: (final BuildContext _) => const SizedBox(),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
    expect(MediaQuery.paddingOf(page).bottom, 0.0);
    expect(HarborRoom.of(page).systemEdges.bottom, 0.0);
  });

  testWidgets("the bare overlay child gets the root overlay's padding from Flutter", (final tester) async {
    await _host(tester, overlayChild: const SafeArea(child: _box));
    expect(tester.getRect(find.byKey(_content)).bottom, homeIndicatorTop);
  });

  group('the overlay child wrapped in HarborFrame.page', () {
    testWidgets('keeps a HarborClear body clear of the home indicator', (final tester) async {
      await _host(
        tester,
        overlayChild: const HarborFrame.page(body: HarborClear(child: _box)),
      );
      expect(tester.getRect(find.byKey(_content)), const Rect.fromLTRB(0, 62, 402, homeIndicatorTop));
    });

    testWidgets("reads the root's system edges in its room", (final tester) async {
      late BuildContext body;
      await _host(
        tester,
        overlayChild: HarborFrame.page(
          body: Builder(
            builder: (final BuildContext context) {
              body = context;
              return const HarborClear(clearsBars: false, child: _box);
            },
          ),
        ),
      );
      final HarborRoomData room = HarborRoom.of(body);
      expect(room.systemEdges.bottom, 34.0);
      expect(room.systemEdgesSteady.bottom, 34.0);
      expect(room.bars.bottom, 0.0);
      expect(MediaQuery.paddingOf(body).bottom, 34.0);
      expect(tester.getRect(find.byKey(_content)).bottom, homeIndicatorTop);
    });

    testWidgets('lays its own bottom bar above the home indicator', (final tester) async {
      await _host(
        tester,
        overlayChild: const HarborFrame.page(
          bottom: <HarborBar>[HarborBar.solid(child: SizedBox(key: _content, height: 50))],
          body: SizedBox.expand(),
        ),
      );
      expect(tester.getRect(find.byKey(_content)).bottom, homeIndicatorTop);
    });
  });

  testWidgets('a frame (not a page) in the overlay child takes the bottom as system edge, not as bar', (
    final tester,
  ) async {
    late BuildContext body;
    await _host(
      tester,
      overlayChild: HarborFrame(
        body: Builder(
          builder: (final BuildContext context) {
            body = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    expect(HarborRoom.of(body).systemEdges.bottom, 34.0);
    expect(HarborRoom.of(body).bars.bottom, 0.0);
  });

  testWidgets('a page nested in the tab host, outside any overlay, still ignores the host bar and edge', (
    final tester,
  ) async {
    late BuildContext body;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: 56))],
          bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 50))],
          body: HarborFrame.page(
            body: Builder(
              builder: (final BuildContext context) {
                body = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    final HarborRoomData room = HarborRoom.of(body);
    expect(room.systemEdges.top, 62.0, reason: "the status bar, without the host's header");
    expect(room.bars.top, 0.0);
    expect(room.systemEdges.bottom, 0.0, reason: "the host's bar holds the home indicator");
  });

  // The owner's review of the first fix, which read any padding above the outer room as an
  // overlay's: padding the app raises with its own MediaQuery is not an overlay's, and must be
  // split as it always was. Each expectation is what main gave before #142.
  group("padding the app raises above a nested frame is not the root's", () {
    /// A page with a 50 overlay header and a 56 solid bottom bar, the app's MediaQuery raising the
    /// padding to [top] or [bottom], and below it [depth] frames (the innermost a page when [page]).
    Future<BuildContext> raised(
      final WidgetTester tester, {
      final double? top,
      final double? bottom,
      final bool page = false,
      final int depth = 1,
    }) async {
      late BuildContext body;
      Widget nested = Builder(
        builder: (final BuildContext context) {
          body = context;
          return const HarborClear(child: _box);
        },
      );
      for (int i = 0; i < depth; i++) {
        nested = page && i == 0 ? HarborFrame.page(body: nested) : HarborFrame(body: nested);
      }
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: 50))],
            bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 56))],
            body: Builder(
              builder: (final BuildContext context) {
                final MediaQueryData data = MediaQuery.of(context);
                return MediaQuery(
                  data: data.copyWith(
                    padding: data.padding.copyWith(top: top, bottom: bottom),
                    viewPadding: data.viewPadding.copyWith(top: top, bottom: bottom),
                  ),
                  child: nested,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return body;
    }

    testWidgets('top 140 over a frame: the status bar is the system edge, the rest is bar', (final tester) async {
      final HarborRoomData room = HarborRoom.of(await raised(tester, top: 140));
      expect(room.systemEdges.top, 62.0);
      expect(room.bars.top, 112.0);
    });

    testWidgets('top 140 over a page: its content starts below the status bar', (final tester) async {
      await raised(tester, top: 140, page: true);
      expect(tester.getRect(find.byKey(_content)).top, 62.0);
    });

    testWidgets('bottom 120 over a frame: no bottom system edge (the bar holds it)', (final tester) async {
      final HarborRoomData room = HarborRoom.of(await raised(tester, bottom: 120));
      expect(room.systemEdges.bottom, 0.0);
    });

    testWidgets('top 140 over two frames: the inner one splits it as the outer did', (final tester) async {
      final HarborRoomData room = HarborRoom.of(await raised(tester, top: 140, depth: 2));
      expect(room.systemEdges.top, 62.0);
      expect(room.bars.top, 112.0);
    });
  });
}
