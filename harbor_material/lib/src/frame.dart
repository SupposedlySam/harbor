import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import 'app_bar.dart';

/// A [HarborFrame] on a Material page: the frame a Material app builds a page from in place of a
/// `Scaffold`.
///
/// It is the frame, with what a `Scaffold` puts around a page and a frame does not: a `Material`
/// in the theme's `scaffoldBackgroundColor`, so text has Material's default style and ink
/// splashes have a surface to paint on, and a `ScrollNotificationObserver`, so an `AppBar` hears
/// content scroll under it. [appBar] goes first in [top], in [HarborMaterialBar.appBar]: a solid
/// bar, as `Scaffold.appBar` is, its colour run up behind the status bar.
///
/// Every other argument is [HarborFrame]'s and means what it means there. There is no
/// `resizeToAvoidBottomInset`: the frame keeps clear of the keyboard itself
/// ([bodyClearsKeyboard]), bar by bar.
///
/// It is not a `Scaffold`, so `ScaffoldMessenger.showSnackBar` and `showMaterialBanner` have nothing
/// to present into: with no `Scaffold` on screen they assert in debug and show nothing in release.
/// Show snack bars on a page built from this frame with
/// [HarborSnackToasts.showSnackToast] instead.
///
/// ```dart
/// HarborMaterialFrame(
///   appBar: AppBar(title: const Text('Inbox')),
///   bottom: [HarborBar.solid(child: NavigationBar(destinations: destinations))],
///   floats: [HarborFloat(placement: const HarborAligned(alignment: AlignmentDirectional.bottomEnd), child: fab)],
///   body: HarborScrollView(slivers: [messages]),
/// )
/// ```
class HarborMaterialFrame extends StatelessWidget {
  const HarborMaterialFrame({
    super.key,
    this.appBar,
    this.top = const <HarborBar>[],
    this.bottom = const <HarborBar>[],
    this.start = const <HarborBar>[],
    this.end = const <HarborBar>[],
    required this.body,
    this.floats = const <HarborFloat>[],
    this.backgroundColor,
    this.systemEdges,
    this.isPage = false,
    this.bodyClearsKeyboard = true,
    this.margin,
    this.minimum = EdgeInsetsDirectional.zero,
    this.sizing = HarborSizing.fill,
    this.edgeEffectPainter,
    this.debugLabel,
    this.defaults,
  });

  /// The page's app bar, an `AppBar` most often, put first in [top] by [HarborMaterialBar.appBar].
  /// To choose anything about its bar (an overlay bar, an edge effect), leave this null and list
  /// `HarborMaterialBar.appBar(...)` in [top] yourself.
  final PreferredSizeWidget? appBar;

  /// See [HarborFrame.top]. Below [appBar], when there is one.
  final List<HarborBar> top;

  /// See [HarborFrame.bottom].
  final List<HarborBar> bottom;

  /// See [HarborFrame.start].
  final List<HarborBar> start;

  /// See [HarborFrame.end].
  final List<HarborBar> end;

  /// See [HarborFrame.body].
  final Widget body;

  /// See [HarborFrame.floats].
  final List<HarborFloat> floats;

  /// The page's colour, as `Scaffold.backgroundColor`: the theme's `scaffoldBackgroundColor` when
  /// null.
  final Color? backgroundColor;

  /// See [HarborFrame.systemEdges].
  final HarborSystemEdges? systemEdges;

  /// See [HarborFrame.isPage].
  final bool isPage;

  /// See [HarborFrame.bodyClearsKeyboard].
  final bool bodyClearsKeyboard;

  /// See [HarborFrame.margin].
  final EdgeInsetsGeometry? margin;

  /// See [HarborFrame.minimum].
  final EdgeInsetsGeometry minimum;

  /// See [HarborFrame.sizing].
  final HarborSizing sizing;

  /// See [HarborFrame.edgeEffectPainter].
  final HarborEdgeEffectPainter? edgeEffectPainter;

  /// See [HarborFrame.debugLabel].
  final String? debugLabel;

  /// See [HarborFrame.defaults].
  final HarborDefaults? defaults;

  @override
  Widget build(final BuildContext context) => ScrollNotificationObserver(
    child: Material(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: HarborFrame(
        top: <HarborBar>[if (appBar case final PreferredSizeWidget appBar) HarborMaterialBar.appBar(appBar), ...top],
        bottom: bottom,
        start: start,
        end: end,
        floats: floats,
        systemEdges: systemEdges,
        isPage: isPage,
        bodyClearsKeyboard: bodyClearsKeyboard,
        margin: margin,
        minimum: minimum,
        sizing: sizing,
        edgeEffectPainter: edgeEffectPainter,
        debugLabel: debugLabel,
        defaults: defaults,
        body: body,
      ),
    ),
  );
}
