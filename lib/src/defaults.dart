import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'barrier_label.dart';
import 'controller.dart';
import 'hinge.dart';
import 'placement.dart';

/// Choices an app or a page makes once for everything beneath it: which hinges overlays and bars
/// keep off, how toasts queue, time and sit, and what barriers are announced as.
///
/// Given to [HarborRoot.defaults] for the whole app, to [HarborFrame.defaults] for a page and
/// what it opens, or to a [HarborDefaultsScope] for any other subtree. Every field is nullable,
/// and null means "the next one out decides": the nearest that sets a field wins, field by field,
/// so a page that sets [toastQueue] under a root that sets [barrierLabel] keeps the root's label.
/// An argument given to the call itself (`showHarborSheet(maxWidth:)`, `HarborToasts.show(queue:)`)
/// wins over all of them, and [fallback] closes the chain.
///
/// A page's defaults reach into what it opens: sheets, dialogs and toasts carry them across the
/// route, as they carry the page's themes.
///
/// It holds policy, not look: no widget-valued field, ever. A sheet's surface or clip belongs in
/// the app's own wrapper around [showHarborSheet], and measured geometry (the margin, the system
/// edges) stays on [HarborRoot] and [HarborFrame], where readers rebuild only for what they read.
///
/// A Material app sets its barrier label and sheet width once, in `MaterialApp.builder`, which sits
/// inside `Localizations`, so it is built again when the locale changes:
///
/// ```dart
/// builder: (context, child) {
///   final MaterialLocalizations l = MaterialLocalizations.of(context);
///   return HarborRoot(
///     defaults: HarborDefaults(
///       barrierLabel: l.modalBarrierDismissLabel,
///       sheetBarrierOnTapHint: l.scrimOnTapHint(l.bottomSheetLabel),
///       sheetMaxWidth: Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640,
///     ),
///     child: child!,
///   );
/// },
/// ```
///
/// See also:
///
///  * `DefaultTextStyle.merge` and `IconTheme.merge`, the same shape: a value that fills in what
///    the one above leaves unsaid.
@immutable
class HarborDefaults with Diagnosticable {
  /// Defaults that set the fields given and leave the rest to the scope above.
  const HarborDefaults({
    this.hinge,
    this.barHinge,
    this.barrierLabel,
    this.sheetBarrierOnTapHint,
    this.sheetMaxWidth,
    this.toastQueue,
    this.toastTiming,
    this.toastAnimationStyle,
    this.toastMargin,
  });

  /// Which hinges and folds sheets, dialogs, toasts, floats and popovers keep off, and bars too
  /// unless [barHinge] says otherwise. See [HarborHinge].
  final HarborHinge? hinge;

  /// Which hinges and folds a frame's bars keep off, when that should differ from [hinge]:
  /// `barHinge: HarborHinge.never` lays a tab bar across the hinge while sheets, dialogs, toasts
  /// and menus still keep off it. Null follows [hinge]. A nearer scope's [hinge] replaces an
  /// inherited [barHinge] (see [merge]), so a nested frame's own policy always decides its bars.
  final HarborHinge? barHinge;

  /// What a screen reader announces for the barrier of a sheet, a dialog or a modal float whose
  /// [HarborBarrier.label] is null. 'Dismiss' at the top, the English that Material and Cupertino
  /// fall back to; a Material app passes `MaterialLocalizations.modalBarrierDismissLabel`.
  final String? barrierLabel;

  /// What a screen reader says tapping a sheet's barrier does, for a sheet whose
  /// [HarborBarrier.onTapHint] is null. None at the top; a Material app passes
  /// `MaterialLocalizations.scrimOnTapHint(MaterialLocalizations.bottomSheetLabel)`.
  final String? sheetBarrierOnTapHint;

  /// The widest a sheet is drawn, centred, on a wide screen, for a sheet opened without a
  /// `maxWidth:`. None at the top: a sheet spans the screen. A Material app passes
  /// `Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640`.
  final double? sheetMaxWidth;

  /// Whether a toast waits its turn at its place or replaces the one up, for a toast shown
  /// without a `queue:`. [HarborToastQueue.wait] at the top; [HarborToastQueue.replace] on a
  /// remote-driven screen, where a newer "Saved" should not arrive seconds late.
  final HarborToastQueue? toastQueue;

  /// How long a toast stays, for a toast shown without a `timing:`. 4 s at the top
  /// (`HarborToastTiming()`).
  final HarborToastTiming? toastTiming;

  /// How a toast comes in and leaves, for a toast shown without an `animationStyle:`. Null at the
  /// top: a fade and a scale over 220 ms each way.
  final AnimationStyle? toastAnimationStyle;

  /// How far a toast keeps in from the room's edges, for a toast whose placement
  /// [HarborToasts.show] builds itself: one shown at a `slot:`, or with neither a slot nor a
  /// placement. A toast given a `placement:` keeps that placement's margin, since a
  /// [HarborPlacement] always carries one. 16 at the top ([HarborAligned.defaultMargin]).
  final EdgeInsetsGeometry? toastMargin;

  /// harbor's own choices, written once: what every field resolves to when no scope sets it.
  /// [barHinge] is null (it follows [hinge]), and so are [sheetBarrierOnTapHint],
  /// [sheetMaxWidth] and [toastAnimationStyle], each of which means "none" or "harbor's own".
  static const HarborDefaults fallback = HarborDefaults(
    hinge: HarborHinge.avoidSeparating,
    barrierLabel: harborBarrierDismissLabel,
    toastQueue: HarborToastQueue.wait,
    toastTiming: HarborToastTiming(),
    toastMargin: HarborAligned.defaultMargin,
  );

  /// These defaults, with every field [nearer] sets taking its place.
  ///
  /// The bars' hinge follows the nearest scope that says anything about the hinge: [nearer]'s
  /// [barHinge], else [nearer]'s [hinge], and only then this [barHinge]. So a frame that sets its
  /// own [hinge] keeps its bars, and the frames beneath it, by that policy, whatever [barHinge] a
  /// frame around it set: `own.barHinge ?? own.hinge ?? inherited.barHinge ?? inherited.hinge`.
  HarborDefaults merge(final HarborDefaults? nearer) {
    if (nearer == null) {
      return this;
    }
    return HarborDefaults(
      hinge: nearer.hinge ?? hinge,
      barHinge: nearer.barHinge ?? nearer.hinge ?? barHinge,
      barrierLabel: nearer.barrierLabel ?? barrierLabel,
      sheetBarrierOnTapHint: nearer.sheetBarrierOnTapHint ?? sheetBarrierOnTapHint,
      sheetMaxWidth: nearer.sheetMaxWidth ?? sheetMaxWidth,
      toastQueue: nearer.toastQueue ?? toastQueue,
      toastTiming: nearer.toastTiming ?? toastTiming,
      toastAnimationStyle: nearer.toastAnimationStyle ?? toastAnimationStyle,
      toastMargin: nearer.toastMargin ?? toastMargin,
    );
  }

  /// The defaults at [context], every scope above it merged over [fallback], so that each field
  /// [fallback] sets is set. Makes [context] rebuild when they change: for a build method.
  static HarborDefaults of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarborDefaultsInherited>()?.defaults ?? fallback;

  /// The same, read once without making [context] depend on them: for [HarborToasts.show],
  /// [showHarborSheet] and the other calls made from a handler.
  static HarborDefaults read(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborDefaultsInherited>()?.defaults ?? fallback;

  @override
  bool operator ==(final Object other) =>
      other is HarborDefaults &&
      other.hinge == hinge &&
      other.barHinge == barHinge &&
      other.barrierLabel == barrierLabel &&
      other.sheetBarrierOnTapHint == sheetBarrierOnTapHint &&
      other.sheetMaxWidth == sheetMaxWidth &&
      other.toastQueue == toastQueue &&
      other.toastTiming == toastTiming &&
      other.toastAnimationStyle == toastAnimationStyle &&
      other.toastMargin == toastMargin;

  @override
  int get hashCode => Object.hash(
    hinge,
    barHinge,
    barrierLabel,
    sheetBarrierOnTapHint,
    sheetMaxWidth,
    toastQueue,
    toastTiming,
    toastAnimationStyle,
    toastMargin,
  );

  @override
  String toStringShort() => 'HarborDefaults';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<HarborHinge>('hinge', hinge, defaultValue: null))
      ..add(EnumProperty<HarborHinge>('barHinge', barHinge, defaultValue: null))
      ..add(StringProperty('barrierLabel', barrierLabel, defaultValue: null))
      ..add(StringProperty('sheetBarrierOnTapHint', sheetBarrierOnTapHint, defaultValue: null))
      ..add(DoubleProperty('sheetMaxWidth', sheetMaxWidth, defaultValue: null))
      ..add(EnumProperty<HarborToastQueue>('toastQueue', toastQueue, defaultValue: null))
      ..add(DiagnosticsProperty<HarborToastTiming>('toastTiming', toastTiming, defaultValue: null))
      ..add(DiagnosticsProperty<AnimationStyle>('toastAnimationStyle', toastAnimationStyle, defaultValue: null))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('toastMargin', toastMargin, defaultValue: null));
  }
}

/// Merges [defaults] over the defaults above it, for everything beneath: the shape of
/// `DefaultTextStyle.merge`, for a subtree that is not a [HarborFrame]. A frame takes the same
/// value as [HarborFrame.defaults].
///
/// ```dart
/// HarborDefaultsScope(
///   defaults: const HarborDefaults(toastQueue: HarborToastQueue.replace),
///   child: remoteDrivenScreen,
/// )
/// ```
class HarborDefaultsScope extends StatelessWidget {
  /// Merges [defaults] over the defaults above, for [child].
  const HarborDefaultsScope({super.key, required this.defaults, required this.child});

  /// The fields this scope sets; null fields are left to the scope above.
  final HarborDefaults defaults;

  final Widget child;

  @override
  Widget build(final BuildContext context) =>
      HarborDefaultsInherited(defaults: HarborDefaults.of(context).merge(defaults), child: child);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborDefaults>('defaults', defaults));
  }
}

/// Hands the resolved defaults to everything beneath, read with [HarborDefaults.of]. An
/// [InheritedTheme], so a sheet, a dialog or a toast that captures the opening page's themes
/// carries the page's defaults across the route with them.
@internal
class HarborDefaultsInherited extends InheritedTheme {
  const HarborDefaultsInherited({super.key, required this.defaults, required super.child});

  /// Every scope above, merged over [HarborDefaults.fallback].
  final HarborDefaults defaults;

  @override
  Widget wrap(final BuildContext context, final Widget child) =>
      HarborDefaultsInherited(defaults: defaults, child: child);

  @override
  bool updateShouldNotify(final HarborDefaultsInherited oldWidget) => defaults != oldWidget.defaults;
}
