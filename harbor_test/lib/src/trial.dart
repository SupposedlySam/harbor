import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

import 'trial_device.dart';

/// Pumps a frame on a [HarborTrialDevice] and moves its keyboard.
extension HarborTrials on WidgetTester {
  /// Puts [widget] on trial on [device]: the device's size, pixel ratio and system edges go on
  /// the test view itself, so everything that reads the view or `MediaQuery` sees the same device.
  /// [keyboardShown] starts it with the keyboard up. [textScaleFactor] is the text size the
  /// platform reports, as the system font-size setting does, so bars are measured at the size
  /// their text grows to. The view and the text scale are reset when the test ends.
  ///
  /// [widget] is pumped as is: give it a `MaterialApp` with a `HarborRoot` in its builder for an
  /// app, or a bare `HarborFrame` inside a `Directionality`.
  Future<HarborTrial> pumpHarborTrial(
    final Widget widget, {
    final HarborTrialDevice device = HarborTrialDevice.iPhone17,
    final bool keyboardShown = false,
    final TextDirection textDirection = TextDirection.ltr,
    final double textScaleFactor = 1.0,
    final bool wrapInView = true,
  }) async {
    final HarborTrial trial = HarborTrial._(this, device);
    view
      ..devicePixelRatio = device.devicePixelRatio
      ..physicalSize = device.size * device.devicePixelRatio;
    addTearDown(view.reset);
    platformDispatcher.textScaleFactorTestValue = textScaleFactor;
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);
    trial._apply(shown: keyboardShown);
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

/// A frame on trial, whose keyboard can be shown and hidden.
class HarborTrial {
  HarborTrial._(this._tester, this.device);

  final WidgetTester _tester;
  final HarborTrialDevice device;
  bool _keyboardShown = false;

  /// Whether the keyboard is up.
  bool get keyboardShown => _keyboardShown;

  /// Brings the keyboard in.
  Future<void> showKeyboard({final bool settle = false, final Duration? pumpFor}) =>
      setKeyboard(shown: true, settle: settle, pumpFor: pumpFor);

  /// Takes the keyboard out.
  Future<void> hideKeyboard({final bool settle = false, final Duration? pumpFor}) =>
      setKeyboard(shown: false, settle: settle, pumpFor: pumpFor);

  static const Duration _followTime = Duration(milliseconds: 600);
  static const Duration _pumpStep = Duration(milliseconds: 50);

  /// Moves the keyboard, pumps a frame, then lets [pumpFor] pass: by default
  /// 600 ms, long enough for the frame to follow (its bars to slide, its keyboard
  /// reading to settle). A [pumpFor] of [Duration.zero] stops at that first
  /// frame, as a `tester.pump()` after setting `tester.view.viewInsets` would,
  /// so a test can see the moment the keyboard arrives. With [settle], it pumps
  /// until nothing is animating instead, as `pumpAndSettle` does, which never
  /// ends on a screen with an endless animation (a looping background).
  Future<void> setKeyboard({required final bool shown, final bool settle = false, final Duration? pumpFor}) async {
    assert(!settle || pumpFor == null, 'Give settle or pumpFor, not both.');
    assert(pumpFor == null || pumpFor >= Duration.zero, 'pumpFor cannot be negative.');
    _apply(shown: shown);
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

  /// Where the keyboard's top is, in global coordinates: the device's height while the keyboard
  /// is hidden.
  double get keyboardTop => device.size.height - (_keyboardShown ? device.keyboardHeight : 0.0);

  void _apply({required final bool shown}) {
    _keyboardShown = shown;
    final double ratio = device.devicePixelRatio;
    _tester.view
      ..padding = _physical(device.systemEdgesWhen(keyboardShown: shown), ratio)
      ..viewPadding = _physical(device.systemEdges, ratio)
      ..viewInsets = FakeViewPadding(bottom: (shown ? device.keyboardHeight : 0.0) * ratio)
      ..displayFeatures = device.displayFeatures;
  }

  static FakeViewPadding _physical(final EdgeInsets insets, final double ratio) => FakeViewPadding(
    left: insets.left * ratio,
    top: insets.top * ratio,
    right: insets.right * ratio,
    bottom: insets.bottom * ratio,
  );

  /// The room of the frame nearest [finder]'s widget, in global coordinates: the rectangle no
  /// system edge, bar or keyboard covers.
  Rect roomAround(final Finder finder) {
    final HarborInspectorEntry? frame = HarborInspector.nearest(finder.evaluate().single);
    if (frame == null) {
      throw TestFailure('No frame has been laid out around ${finder.describeMatch(Plurality.one)}.');
    }
    return frame.room;
  }

  /// Every bar of the frame nearest [finder], in global coordinates.
  List<HarborBarRecord> barsAround(final Finder finder) =>
      HarborInspector.nearest(finder.evaluate().single)?.bars ?? const <HarborBarRecord>[];
}

/// Matches a [Finder] whose widget lies wholly in [room], within [tolerance]: read the room with
/// [HarborTrial.roomAround].
Matcher isInRoom(final Rect room, {final double tolerance = 0.5}) => _InRoom(room, tolerance);

class _InRoom extends Matcher {
  const _InRoom(this.room, this.tolerance);

  final Rect room;
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
    return rect.left >= room.left - tolerance &&
        rect.top >= room.top - tolerance &&
        rect.right <= room.right + tolerance &&
        rect.bottom <= room.bottom + tolerance;
  }

  @override
  Description describe(final Description description) => description.add('lies within the room $room');

  @override
  Description describeMismatch(
    final Object? item,
    final Description mismatchDescription,
    final Map<dynamic, dynamic> matchState,
    final bool verbose,
  ) => mismatchDescription.add('was at ${matchState['rect']}');
}
