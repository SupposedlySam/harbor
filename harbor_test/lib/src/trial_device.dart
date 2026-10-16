import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// A device a frame is put on trial on: its screen, its system edges and how high its keyboard
/// comes in.
///
/// Sizes are logical pixels; [devicePixelRatio] turns them into the physical
/// pixels the view is given. [systemEdges] is physical (`left` and `right`), as a
/// platform reports it, so a side inset lands on the start or end depending on
/// the text direction under trial.
@immutable
class HarborTrialDevice {
  const HarborTrialDevice({
    required this.name,
    required this.size,
    required this.systemEdges,
    required this.keyboardHeight,
    this.devicePixelRatio = 1.0,
    this.reportsSystemEdgesUnderKeyboard = false,
    this.displayFeatures = const <DisplayFeature>[],
  });

  final String name;
  final Size size;

  /// The system insets with the keyboard down.
  final EdgeInsets systemEdges;

  /// How far the software keyboard reaches up when it's in.
  final double keyboardHeight;

  /// Physical pixels per logical pixel, as `MediaQuery.devicePixelRatio`
  /// reports it under trial.
  final double devicePixelRatio;

  /// Whether the platform keeps reporting the bottom inset while the keyboard
  /// covers it. iOS and Android both report zero.
  final bool reportsSystemEdgesUnderKeyboard;

  /// Folds and hinges, as the platform reports them in `MediaQuery.displayFeatures`. A hinge
  /// has width and content should not cross it; a flat fold has none and content may span it.
  final List<DisplayFeature> displayFeatures;

  /// An iPhone with a Dynamic Island and a home indicator.
  static const HarborTrialDevice iPhone17 = HarborTrialDevice(
    name: 'iPhone 17',
    size: Size(402.0, 874.0),
    systemEdges: EdgeInsets.only(top: 62.0, bottom: 34.0),
    keyboardHeight: 336.0,
    devicePixelRatio: 3.0,
  );

  /// An iPhone with a home button: a status bar and nothing at the bottom.
  static const HarborTrialDevice iPhoneSE = HarborTrialDevice(
    name: 'iPhone SE',
    size: Size(375.0, 667.0),
    systemEdges: EdgeInsets.only(top: 20.0),
    keyboardHeight: 260.0,
    devicePixelRatio: 2.0,
  );

  /// An Android phone with three-button navigation.
  static const HarborTrialDevice androidThreeButton = HarborTrialDevice(
    name: 'Android 3-button',
    size: Size(412.0, 915.0),
    systemEdges: EdgeInsets.only(top: 24.0, bottom: 48.0),
    keyboardHeight: 300.0,
    devicePixelRatio: 2.625,
  );

  /// An Android phone with gesture navigation.
  static const HarborTrialDevice androidGesture = HarborTrialDevice(
    name: 'Android gesture',
    size: Size(412.0, 915.0),
    systemEdges: EdgeInsets.only(top: 24.0, bottom: 24.0),
    keyboardHeight: 300.0,
    devicePixelRatio: 2.625,
  );

  /// An iPhone on its side, the island on the left.
  static const HarborTrialDevice iPhone17Landscape = HarborTrialDevice(
    name: 'iPhone 17 landscape',
    size: Size(874.0, 402.0),
    systemEdges: EdgeInsets.only(left: 62.0, right: 62.0, bottom: 21.0),
    keyboardHeight: 200.0,
    devicePixelRatio: 3.0,
  );

  /// [androidThreeButton] on its side, turned the usual way (`Surface.ROTATION_90`, its top to the
  /// left): the navigation bar moves to the right side and the status bar stays on top.
  ///
  /// From AOSP's `frameworks/base`: `DisplayLayout.navigationBarPosition` puts a bar that can move
  /// on the right at `ROTATION_90` (on the left at `ROTATION_270`, the seascape turn), and
  /// `config_navBarCanMove` is true by default for a phone; the bar is `navigation_bar_width`
  /// (48dp) wide there; and the status bar is `status_bar_height_landscape`, the same 24dp as in
  /// portrait. Like the portrait preset, it has no cutout. The 200-point keyboard is an estimate.
  static const HarborTrialDevice androidThreeButtonLandscape = HarborTrialDevice(
    name: 'Android 3-button landscape',
    size: Size(915.0, 412.0),
    systemEdges: EdgeInsets.only(top: 24.0, right: 48.0),
    keyboardHeight: 200.0,
    devicePixelRatio: 2.625,
  );

  /// [androidGesture] on its side, turned the usual way (`Surface.ROTATION_90`, its top to the
  /// left): the punch-hole camera moves to the left side, the status bar stays on top, and the
  /// gesture bar stays at the bottom.
  ///
  /// From AOSP's `frameworks/base`: the gesture navigation overlay sets `config_navBarCanMove` to
  /// false, so the bar stays at the bottom in landscape, `navigation_bar_height_landscape` 24dp;
  /// and the status bar is `status_bar_height_landscape`, the same 24dp as in portrait. The 24-point
  /// cutout on the left is an estimate (the portrait camera's depth, turned), as is the 200-point
  /// keyboard.
  static const HarborTrialDevice androidGestureLandscape = HarborTrialDevice(
    name: 'Android gesture landscape',
    size: Size(915.0, 412.0),
    systemEdges: EdgeInsets.only(top: 24.0, left: 24.0, bottom: 24.0),
    keyboardHeight: 200.0,
    devicePixelRatio: 2.625,
  );

  /// A book-style foldable, open flat: a fold down the middle with no width, which content may span.
  static const HarborTrialDevice foldableOpen = HarborTrialDevice(
    name: 'foldable open',
    size: Size(750.0, 832.0),
    systemEdges: EdgeInsets.only(top: 24.0, bottom: 24.0),
    keyboardHeight: 330.0,
    devicePixelRatio: 2.625,
    displayFeatures: <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.fromLTRB(375.0, 0.0, 375.0, 832.0),
        type: DisplayFeatureType.fold,
        state: DisplayFeatureState.postureFlat,
      ),
    ],
  );

  /// A dual-screen device spanned across both screens: two 540-wide screens either side of a
  /// 34-wide hinge, which nothing should be placed across.
  static const HarborTrialDevice dualScreenOpen = HarborTrialDevice(
    name: 'dual screen open',
    size: Size(1114.0, 720.0),
    systemEdges: EdgeInsets.only(top: 24.0, bottom: 24.0),
    keyboardHeight: 300.0,
    devicePixelRatio: 2.5,
    displayFeatures: <DisplayFeature>[
      DisplayFeature(
        bounds: Rect.fromLTRB(540.0, 0.0, 574.0, 720.0),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      ),
    ],
  );

  /// A dual-screen device on its cover screen: an inset down the right side.
  static const HarborTrialDevice dualScreenCover = HarborTrialDevice(
    name: 'dual screen cover',
    size: Size(466.0, 678.0),
    systemEdges: EdgeInsets.only(right: 84.0, bottom: 34.0),
    keyboardHeight: 300.0,
    devicePixelRatio: 2.625,
  );

  /// A 1080p television, which reports no insets at all.
  static const HarborTrialDevice television = HarborTrialDevice(
    name: 'television',
    size: Size(1920.0, 1080.0),
    systemEdges: EdgeInsets.zero,
    keyboardHeight: 0.0,
  );

  /// The phones every inset is checked on.
  static const List<HarborTrialDevice> phones = <HarborTrialDevice>[
    iPhone17,
    iPhoneSE,
    androidThreeButton,
    androidGesture,
  ];

  /// Every preset.
  static const List<HarborTrialDevice> all = <HarborTrialDevice>[
    iPhone17,
    iPhoneSE,
    androidThreeButton,
    androidGesture,
    iPhone17Landscape,
    androidThreeButtonLandscape,
    androidGestureLandscape,
    foldableOpen,
    dualScreenOpen,
    dualScreenCover,
    television,
  ];

  /// A copy of this device with the given fields replaced: a preset at
  /// another pixel ratio, say.
  HarborTrialDevice copyWith({
    final String? name,
    final Size? size,
    final EdgeInsets? systemEdges,
    final double? keyboardHeight,
    final double? devicePixelRatio,
    final bool? reportsSystemEdgesUnderKeyboard,
    final List<DisplayFeature>? displayFeatures,
  }) => HarborTrialDevice(
    name: name ?? this.name,
    size: size ?? this.size,
    systemEdges: systemEdges ?? this.systemEdges,
    keyboardHeight: keyboardHeight ?? this.keyboardHeight,
    devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    reportsSystemEdgesUnderKeyboard: reportsSystemEdgesUnderKeyboard ?? this.reportsSystemEdgesUnderKeyboard,
    displayFeatures: displayFeatures ?? this.displayFeatures,
  );

  /// The system edges the platform reports with the keyboard shown or hidden.
  EdgeInsets systemEdgesWhen({required final bool keyboardShown}) =>
      keyboardShown && !reportsSystemEdgesUnderKeyboard ? systemEdges.copyWith(bottom: 0.0) : systemEdges;

  @override
  String toString() => name;
}
