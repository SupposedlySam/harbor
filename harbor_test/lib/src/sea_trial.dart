import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

import 'trial_device.dart';

/// Pumps a harbor on a [HarborTrialDevice] and moves its tide.
extension HarborSeaTrials on WidgetTester {
  /// Puts [widget] through its sea trials on [device]: the device's size and
  /// coast go on the test view itself, so everything that reads the view or
  /// `MediaQuery` sees the same device. The view is reset when the test ends.
  ///
  /// [widget] is pumped as is: give it a `MaterialApp` with a `HarborSea` in its
  /// builder for an app, or a bare `Harbor` inside a `Directionality`.
  Future<HarborSeaTrial> pumpSeaTrial(
    final Widget widget, {
    final HarborTrialDevice device = HarborTrialDevice.iPhone17,
    final bool tideIn = false,
    final TextDirection textDirection = TextDirection.ltr,
    final bool wrapInView = true,
  }) async {
    final HarborSeaTrial trial = HarborSeaTrial._(this, device);
    view
      ..devicePixelRatio = 1.0
      ..physicalSize = device.size;
    addTearDown(view.reset);
    trial._apply(tideIn: tideIn);
    await pumpWidget(
      wrapInView
          ? Directionality(
              textDirection: textDirection,
              child: MediaQuery.fromView(view: view, child: widget),
            )
          : widget,
    );
    return trial;
  }
}

/// A harbor under trial, whose tide can be raised and lowered.
class HarborSeaTrial {
  HarborSeaTrial._(this._tester, this.device);

  final WidgetTester _tester;
  final HarborTrialDevice device;
  bool _tideIn = false;

  bool get tideIn => _tideIn;

  /// Brings the keyboard in.
  Future<void> raiseTide({final bool settle = false}) => setTide(tideIn: true, settle: settle);

  /// Takes the keyboard out.
  Future<void> lowerTide({final bool settle = false}) => setTide(tideIn: false, settle: settle);

  /// Moves the keyboard, then pumps long enough for the harbor to follow
  /// (its docks to slide, its tide gauge to settle). With [settle], it pumps
  /// until nothing is animating instead, which never ends on a screen with an
  /// endless animation (a rolling sea).
  Future<void> setTide({required final bool tideIn, final bool settle = false}) async {
    _apply(tideIn: tideIn);
    if (settle) {
      await _tester.pumpAndSettle();
      return;
    }
    await _tester.pump();
    for (int i = 0; i < 12; i++) {
      await _tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Where the keyboard's top is, in global coordinates.
  double get waterline => device.size.height - (_tideIn ? device.tideHeight : 0.0);

  void _apply({required final bool tideIn}) {
    _tideIn = tideIn;
    final EdgeInsets padding = device.coastWhen(tideIn: tideIn);
    _tester.view
      ..padding = FakeViewPadding(left: padding.left, top: padding.top, right: padding.right, bottom: padding.bottom)
      ..viewPadding = FakeViewPadding(
        left: device.coast.left,
        top: device.coast.top,
        right: device.coast.right,
        bottom: device.coast.bottom,
      )
      ..viewInsets = FakeViewPadding(bottom: tideIn ? device.tideHeight : 0.0)
      ..displayFeatures = device.displayFeatures;
  }

  /// The clear water of the harbor nearest [finder]'s widget, in global
  /// coordinates: the rectangle no coast, dock or tide covers.
  Rect clearWaterAround(final Finder finder) {
    final Element element = finder.evaluate().single;
    final HarborController? controller = HarborController.maybeOf(element);
    final Rect? rect = controller?.clearWaterInGlobal();
    if (rect == null) {
      throw StateError('No harbor has been laid out around ${finder.describeMatch(Plurality.one)}.');
    }
    return rect;
  }

  /// Every dock of the harbor nearest [finder], in global coordinates.
  List<HarborDockRecord> docksAround(final Finder finder) {
    final Element element = finder.evaluate().single;
    final HarborController? controller = HarborController.maybeOf(element);
    final RenderBox? box = controller?.renderBox;
    final HarborLayoutRecord? layout = controller?.lastLayout;
    if (box == null || layout == null) {
      return const <HarborDockRecord>[];
    }
    final Matrix4 toGlobal = box.getTransformTo(null);
    return <HarborDockRecord>[
      for (final HarborDockRecord d in layout.docks)
        HarborDockRecord(
          edge: d.edge,
          kind: d.kind,
          rect: MatrixUtils.transformRect(toGlobal, d.rect),
          extent: d.extent,
          restingExtent: d.restingExtent,
          state: d.state,
          tide: d.tide,
          label: d.label,
        ),
    ];
  }
}

/// Matches a [Finder] whose widget lies wholly in clear water: inside
/// [clearWater], within [tolerance].
Matcher isInClearWater(final Rect clearWater, {final double tolerance = 0.5}) => _InClearWater(clearWater, tolerance);

class _InClearWater extends Matcher {
  const _InClearWater(this.clearWater, this.tolerance);

  final Rect clearWater;
  final double tolerance;

  @override
  bool matches(final Object? item, final Map<dynamic, dynamic> matchState) {
    if (item is! Finder) {
      return false;
    }
    final Iterable<Element> elements = item.evaluate();
    if (elements.isEmpty) {
      return false;
    }
    final RenderObject? box = elements.first.renderObject;
    if (box is! RenderBox || !box.hasSize) {
      return false;
    }
    final Rect rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    matchState['rect'] = rect;
    return rect.left >= clearWater.left - tolerance &&
        rect.top >= clearWater.top - tolerance &&
        rect.right <= clearWater.right + tolerance &&
        rect.bottom <= clearWater.bottom + tolerance;
  }

  @override
  Description describe(final Description description) => description.add('lies within clear water $clearWater');

  @override
  Description describeMismatch(
    final Object? item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) => mismatchDescription.add('was at ${matchState['rect']}');
}
