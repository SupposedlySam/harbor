import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

// How a sheet hands the coast to its header, body and footer: the top coast with
// `keepsTopCoast` (#75) and the side coast (#76).

const double _headerHeight = 40.0;

// The header's default fade wake, which the body is padded by under the header.
const double _headerWake = 12.0;

/// A full-width box that records the `MediaQuery.padding` it is built with.
Widget _probe(final String key, final double height, final Map<String, EdgeInsets> padding) => Builder(
  builder: (final BuildContext context) {
    padding[key] = MediaQuery.paddingOf(context);
    return SizedBox(key: ValueKey<String>(key), height: height, width: double.infinity);
  },
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

/// Pumps a page in a harbor on [device] and returns its context, to open sheets from.
Future<BuildContext> _page(final WidgetTester tester, final HarborTrialDevice device) async {
  late BuildContext page;
  await tester.pumpSeaTrial(
    WidgetsApp(
      color: const Color(0xFF000000),
      pageRouteBuilder: <T>(final RouteSettings settings, final WidgetBuilder builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (final BuildContext context, final Animation<double> _, final Animation<double> _) =>
            builder(context),
      ),
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: Harbor(
        body: Builder(
          builder: (final BuildContext context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
    device: device,
  );
  return page;
}

/// Opens a sheet with a surface, a header, a body and a footer, each recording its padding.
///
/// The body is not moored unless [mooredBody], so it shows what the sheet hands it rather
/// than what a moored widget would clear for itself.
Future<Map<String, EdgeInsets>> _open(
  final WidgetTester tester,
  final HarborTrialDevice device, {
  required final bool draggable,
  final bool keepsTopCoast = false,
  final bool? clearsTopCoast,
  final bool? clearsSides,
  final bool mooredBody = false,
}) async {
  final BuildContext page = await _page(tester, device);
  final Map<String, EdgeInsets> padding = <String, EdgeInsets>{};
  const Widget surface = SizedBox.expand(key: ValueKey<String>('surface'));
  Widget body() => mooredBody ? HarborMoored(child: _probe('body', 100.0, padding)) : _probe('body', 100.0, padding);
  unawaited(
    showHarborSheet<void>(
      page,
      keepsTopCoast: keepsTopCoast,
      builder: (final BuildContext context) => draggable
          ? HarborSheet.draggable(
              extent: const HarborSheetExtent(rest: 1.0, max: 1.0),
              clearsTopCoast: clearsTopCoast ?? true,
              clearsSides: clearsSides ?? false,
              surface: surface,
              header: _probe('header', _headerHeight, padding),
              footer: _probe('footer', 40.0, padding),
              builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
                controller: controller,
                slivers: <Widget>[SliverToBoxAdapter(child: body())],
              ),
            )
          : HarborSheet(
              clearsTopCoast: clearsTopCoast ?? true,
              clearsSides: clearsSides ?? false,
              surface: surface,
              header: _probe('header', _headerHeight, padding),
              footer: _probe('footer', 40.0, padding),
              body: body(),
            ),
    ),
  );
  await tester.pumpAndSettle();
  return padding;
}

void main() {
  const HarborTrialDevice phone = HarborTrialDevice.iPhone17;
  final double statusBar = phone.coast.top;

  group('HarborSheet(clearsTopCoast: false) with keepsTopCoast (#75)', () {
    testWidgets('a content-sized sheet: the header sits at the top of the surface and reads no top coast', (
      final tester,
    ) async {
      final Map<String, EdgeInsets> padding = await _open(
        tester,
        phone,
        draggable: false,
        keepsTopCoast: true,
        clearsTopCoast: false,
      );
      expect(_rect(tester, 'header').top, _rect(tester, 'surface').top);
      expect(padding['header']!.top, 0.0);
      // Under the header and its wake, not the status bar as well.
      expect(padding['body']!.top, _headerHeight + _headerWake);
    });

    testWidgets('a draggable sheet keeps the full height and casts off the top coast for its content', (
      final tester,
    ) async {
      final Map<String, EdgeInsets> padding = await _open(
        tester,
        phone,
        draggable: true,
        keepsTopCoast: true,
        clearsTopCoast: false,
      );
      // The geometry keepsTopCoast gives: the surface reaches the top of the screen.
      expect(_rect(tester, 'surface').top, 0.0);
      expect(_rect(tester, 'header').top, 0.0);
      expect(padding['header']!.top, 0.0);
      // The body's list rests under the header, not under the header and the status bar.
      expect(_rect(tester, 'body').top, _headerHeight + _headerWake);
    });

    testWidgets('the default still hands the top coast to the header (keepsTopCoast unchanged)', (final tester) async {
      await _open(tester, phone, draggable: true, keepsTopCoast: true);
      expect(_rect(tester, 'surface').top, 0.0);
      expect(_rect(tester, 'header').top, statusBar);
      expect(_rect(tester, 'body').top, statusBar + _headerHeight + _headerWake);
    });

    testWidgets('the default on a content-sized sheet still pads the header by the top coast', (final tester) async {
      await _open(tester, phone, draggable: false, keepsTopCoast: true);
      expect(_rect(tester, 'header').top, _rect(tester, 'surface').top + statusBar);
    });

    for (final bool draggable in <bool>[false, true]) {
      testWidgets('without keepsTopCoast it changes nothing (draggable: $draggable)', (final tester) async {
        await _open(tester, phone, draggable: draggable);
        final Rect surface = _rect(tester, 'surface');
        final Rect header = _rect(tester, 'header');
        final Rect body = _rect(tester, 'body');
        await tester.pumpWidget(const SizedBox());
        await _open(tester, phone, draggable: draggable, clearsTopCoast: false);
        expect(_rect(tester, 'surface'), surface);
        expect(_rect(tester, 'header'), header);
        expect(_rect(tester, 'body'), body);
        // Short of the status bar, so nothing reaches it either way.
        if (draggable) {
          expect(surface.top, statusBar);
          expect(header.top, statusBar);
        }
      });
    }
  });

  group('HarborSheet(clearsSides:) on a phone on its side (#76)', () {
    const HarborTrialDevice landscape = HarborTrialDevice.iPhone17Landscape;
    final double left = landscape.coast.left;
    final double right = landscape.size.width - landscape.coast.right;

    for (final bool draggable in <bool>[false, true]) {
      testWidgets('true: header, body and footer clear the side coast and cast it off (draggable: $draggable)', (
        final tester,
      ) async {
        final Map<String, EdgeInsets> padding = await _open(tester, landscape, draggable: draggable, clearsSides: true);
        for (final String part in <String>['header', 'body', 'footer']) {
          final Rect rect = _rect(tester, part);
          expect(rect.left, left, reason: part);
          expect(rect.right, right, reason: part);
          expect(padding[part]!.left, 0.0, reason: part);
          expect(padding[part]!.right, 0.0, reason: part);
        }
        // The surface still runs edge to edge.
        expect(_rect(tester, 'surface').left, 0.0);
        expect(_rect(tester, 'surface').right, landscape.size.width);
      });

      testWidgets('false, the default: content spans the sheet and is handed the side coast (draggable: $draggable)', (
        final tester,
      ) async {
        final Map<String, EdgeInsets> padding = await _open(tester, landscape, draggable: draggable);
        for (final String part in <String>['header', 'body', 'footer']) {
          final Rect rect = _rect(tester, part);
          expect(rect.left, 0.0, reason: part);
          expect(rect.right, landscape.size.width, reason: part);
          expect(padding[part]!.left, left, reason: part);
          expect(padding[part]!.right, landscape.coast.right, reason: part);
        }
        expect(_rect(tester, 'surface').left, 0.0);
        expect(_rect(tester, 'surface').right, landscape.size.width);
      });

      testWidgets('a moored body is not pushed in twice (draggable: $draggable)', (final tester) async {
        await _open(tester, landscape, draggable: draggable, clearsSides: true, mooredBody: true);
        expect(_rect(tester, 'body').left, left);
        expect(_rect(tester, 'body').right, right);
      });
    }

    testWidgets('it leaves a phone with no side coast as it was', (final tester) async {
      await _open(tester, phone, draggable: false);
      final Rect header = _rect(tester, 'header');
      final Rect body = _rect(tester, 'body');
      await tester.pumpWidget(const SizedBox());
      await _open(tester, phone, draggable: false, clearsSides: true);
      expect(_rect(tester, 'header'), header);
      expect(_rect(tester, 'body'), body);
    });
  });
}
