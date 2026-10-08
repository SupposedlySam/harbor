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
  Future<void> raiseTide({final bool settle = false, final Duration? pumpFor}) =>
      setTide(tideIn: true, settle: settle, pumpFor: pumpFor);

  /// Takes the keyboard out.
  Future<void> lowerTide({final bool settle = false, final Duration? pumpFor}) =>
      setTide(tideIn: false, settle: settle, pumpFor: pumpFor);

  static const Duration _followTime = Duration(milliseconds: 600);
  static const Duration _pumpStep = Duration(milliseconds: 50);

  /// Moves the keyboard, pumps a frame, then lets [pumpFor] pass: by default
  /// 600 ms, long enough for the harbor to follow (its docks to slide, its tide
  /// gauge to settle). A [pumpFor] of [Duration.zero] stops at that first
  /// frame, as a `tester.pump()` after setting `tester.view.viewInsets` would,
  /// so a test can see the moment the keyboard arrives. With [settle], it pumps
  /// until nothing is animating instead, as `pumpAndSettle` does, which never
  /// ends on a screen with an endless animation (a rolling sea).
  Future<void> setTide({required final bool tideIn, final bool settle = false, final Duration? pumpFor}) async {
    assert(!settle || pumpFor == null, 'Give settle or pumpFor, not both.');
    assert(pumpFor == null || pumpFor >= Duration.zero, 'pumpFor cannot be negative.');
    _apply(tideIn: tideIn);
    if (settle) {
      await _tester.pumpAndSettle();
      return;
    }
    await _tester.pump();
    Duration remaining = pumpFor ?? _followTime;
    while (remaining > Duration.zero) {
      final Duration step = remaining < _pumpStep ? remaining : _pumpStep;
      await _tester.pump(step);
      remaining -= step;
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
    final HarborChartEntry? harbor = HarborChart.nearest(finder.evaluate().single);
    if (harbor == null) {
      throw StateError('No harbor has been laid out around ${finder.describeMatch(Plurality.one)}.');
    }
    return harbor.clearWater;
  }

  /// Every dock of the harbor nearest [finder], in global coordinates.
  List<HarborDockRecord> docksAround(final Finder finder) =>
      HarborChart.nearest(finder.evaluate().single)?.docks ?? const <HarborDockRecord>[];
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
