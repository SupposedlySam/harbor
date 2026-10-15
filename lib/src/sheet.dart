import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'barrier_label.dart';
import 'controller.dart';
import 'dock.dart';
import 'edge.dart';
import 'harbor.dart';
import 'hinge.dart';
import 'moored.dart';
import 'render_harbor.dart';
import 'tide.dart';
import 'wake.dart';
import 'waters.dart';
import 'renamed.dart';

/// A sheet's heights, for a draggable sheet: fractions of the space above the keyboard.
@immutable
class HarborSheetExtent with Diagnosticable {
  const HarborSheetExtent({
    this.rest = 0.5,
    this.max = 0.88,
    this.min = 0.25,
    this.snap = true,
    this.snapSizes,
    this.shouldCloseOnMinExtent = true,
  });

  /// Where the sheet opens and rests. Rebuilt with a new rest before it is
  /// dragged, the sheet moves there, as [DraggableScrollableSheet.initialChildSize]
  /// does; to move it after, use the sheet's [DraggableScrollableController].
  final double rest;

  /// The taller snap and the ceiling.
  final double max;

  /// The drag floor; dragged to it, or flung down past the lowest snap faster
  /// than [HarborSheet.closeFlingVelocity], the sheet closes.
  final double min;

  final bool snap;

  /// The heights a released sheet snaps to, in increasing order, between [min]
  /// and [max]; [max] is always one. Defaults to [rest] and [max].
  final List<double>? snapSizes;

  /// Whether reaching [min] closes the sheet. Off, the sheet rests at its floor.
  final bool shouldCloseOnMinExtent;

  List<double> get _snaps => <double>{
    ...(snapSizes ?? <double>[rest]),
    max,
  }.toList()..sort();

  @override
  bool operator ==(final Object other) =>
      other is HarborSheetExtent &&
      other.rest == rest &&
      other.max == max &&
      other.min == min &&
      other.snap == snap &&
      listEquals(other.snapSizes, snapSizes) &&
      other.shouldCloseOnMinExtent == shouldCloseOnMinExtent;

  @override
  int get hashCode =>
      Object.hash(rest, max, min, snap, snapSizes == null ? null : Object.hashAll(snapSizes!), shouldCloseOnMinExtent);

  @override
  String toStringShort() => objectRuntimeType(this, 'HarborSheetExtent');

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(PercentProperty('rest', rest, level: rest == 0.5 ? DiagnosticLevel.fine : DiagnosticLevel.info));
    properties.add(PercentProperty('max', max, level: max == 0.88 ? DiagnosticLevel.fine : DiagnosticLevel.info));
    properties.add(PercentProperty('min', min, level: min == 0.25 ? DiagnosticLevel.fine : DiagnosticLevel.info));
    properties.add(FlagProperty('snap', value: snap, ifFalse: 'no snapping'));
    properties.add(IterableProperty<double>('snapSizes', snapSizes, defaultValue: null));
    properties.add(
      FlagProperty('shouldCloseOnMinExtent', value: shouldCloseOnMinExtent, ifFalse: 'stays open at its floor'),
    );
  }
}

/// A sheet's surface: a new page frame with its own bars. Its header is an overlay bar the
/// body scrolls under, with an edge effect; its footer is a solid bar that rides the
/// keyboard and keeps 16 above the screen's edge on a phone with no home indicator.
/// Neither is given a height: both are measured.
///
/// A plain [header] or [footer] is a widget, put in the sheet's own bar:
/// [defaultHeaderBar] and [defaultFooterBar]. To set anything else about either bar (no
/// fade, a footer that withdraws while the keyboard is up, a backdrop), give the whole bar
/// as [headerBar] or [footerBar] instead, starting from those two if you want the sheet's
/// look:
///
/// ```dart
/// HarborSheet(
///   headerBar: HarborBar.overlay(child: tabs), // no fade
///   footerBar: HarborBar.solid(keyboard: HarborKeyboardStance.reserves, child: HarborKeyboardSpace(child: tray)),
///   body: deck,
/// )
/// ```
///
/// The sheet keeps the system edge at the bottom (the home indicator), so its footer
/// clears it once and nothing else in it has to.
///
/// See also:
///
///  * [DraggableScrollableSheet], which [HarborSheet.draggable] is built on.
class HarborSheet extends StatelessWidget {
  /// A sheet as tall as its content, up to [maxExtentFraction] of the space
  /// above the keyboard, past which its body scrolls.
  const HarborSheet({
    super.key,
    this.header,
    this.footer,
    this.headerBar,
    this.footerBar,
    required Widget this.body,
    this.surface,
    @Deprecated(
      'Give headerBar: HarborSheet.defaultHeaderBar(header) or a HarborBar of your own, with its edgeEffect. '
      '`dart fix` applies it, but not where the header can be null. Deprecated after 0.9.1.',
    )
    final HarborEdgeEffect? headerEdgeEffect,
    @Deprecated(
      'Renamed headerEdgeEffect, itself deprecated: give headerBar: a HarborBar with its edgeEffect. `dart fix` applies it.',
    )
    final HarborEdgeEffect? headerWake,
    @Deprecated(
      'Give footerBar: HarborSheet.defaultFooterBar(footer) or a HarborBar of your own, with its edgeEffect. '
      '`dart fix` applies it, but not where the footer can be null. Deprecated after 0.9.1.',
    )
    final HarborEdgeEffect? footerEdgeEffect,
    @Deprecated(
      'Renamed footerEdgeEffect, itself deprecated: give footerBar: a HarborBar with its edgeEffect. `dart fix` applies it.',
    )
    final HarborEdgeEffect? footerWake,
    @Deprecated(
      'Give footerBar: HarborSheet.defaultFooterBar(footer) or a HarborBar of your own, with its minimum. '
      '`dart fix` applies it, but not where the footer can be null. Deprecated after 0.9.1.',
    )
    final double? footerMinimum,
    @Deprecated(
      'Give footerBar: HarborSheet.defaultFooterBar(footer) or a HarborBar of your own, with its keyboard. '
      '`dart fix` applies it, but not where the footer can be null. Deprecated after 0.9.1.',
    )
    final HarborKeyboardStance? footerKeyboard,
    @Deprecated(
      'Renamed footerKeyboard, itself deprecated: give footerBar: a HarborBar with its keyboard. `dart fix` applies it.',
    )
    final HarborKeyboardStance? footerTide,
    this.maxExtentFraction = 0.9,
    this.debugLabel,
    this.contentBuilder,
    this.clip,
    this.dragToClose = false,
    this.closeFlingVelocity = 700.0,
    final bool clearsTopSystemEdge = true,
    @Deprecated('Renamed clearsTopSystemEdge. `dart fix` applies it.') final bool? clearsTopCoast,
    this.clearsSides = false,
    final bool bodyClearsKeyboard = true,
    @Deprecated('Renamed bodyClearsKeyboard. `dart fix` applies it.') final bool? bodyClearsTide,
  }) : assert(header == null || headerBar == null, 'Give a sheet header or headerBar, not both.'),
       assert(footer == null || footerBar == null, 'Give a sheet footer or footerBar, not both.'),
       assert(
         headerBar == null || (headerEdgeEffect == null && headerWake == null),
         'headerEdgeEffect is for a plain header. Give a headerBar its own edgeEffect.',
       ),
       assert(
         footerBar == null ||
             (footerEdgeEffect == null &&
                 footerWake == null &&
                 footerMinimum == null &&
                 footerKeyboard == null &&
                 footerTide == null),
         'footerEdgeEffect, footerMinimum and footerKeyboard are for a plain footer. Give a footerBar its own.',
       ),
       assert(
         headerWake == null || headerEdgeEffect == null || identical(headerWake, headerEdgeEffect),
         'headerEdgeEffect and the deprecated headerWake disagree. Give headerBar alone.',
       ),
       assert(
         footerWake == null || footerEdgeEffect == null || identical(footerWake, footerEdgeEffect),
         'footerEdgeEffect and the deprecated footerWake disagree. Give footerBar alone.',
       ),
       assert(
         footerTide == null || footerKeyboard == null || footerTide == footerKeyboard,
         'footerKeyboard and the deprecated footerTide disagree. Give footerBar alone.',
       ),
       assert(
         clearsTopCoast == null || clearsTopSystemEdge || clearsTopCoast == clearsTopSystemEdge,
         'clearsTopSystemEdge and the deprecated clearsTopCoast disagree. Give clearsTopSystemEdge alone.',
       ),
       assert(
         bodyClearsTide == null || bodyClearsKeyboard || bodyClearsTide == bodyClearsKeyboard,
         'bodyClearsKeyboard and the deprecated bodyClearsTide disagree. Give bodyClearsKeyboard alone.',
       ),
       _headerEdgeEffect = headerEdgeEffect ?? headerWake ?? _defaultHeaderEdgeEffect,
       _footerEdgeEffect = footerEdgeEffect ?? footerWake ?? _defaultFooterEdgeEffect,
       _footerMinimum = footerMinimum ?? _defaultFooterMinimum,
       _footerKeyboard = footerKeyboard ?? footerTide ?? _defaultFooterKeyboard,
       clearsTopSystemEdge = clearsTopCoast ?? clearsTopSystemEdge,
       bodyClearsKeyboard = bodyClearsTide ?? bodyClearsKeyboard,
       assert(closeFlingVelocity >= 0.0),
       builder = null,
       extent = null,
       controller = null,
       expand = true;

  /// A sheet whose content is a list: it rests at [extent]'s rest height, drags
  /// to its ceiling, and closes when dragged below its floor. [builder] must
  /// give its scroll view the controller it is handed, so dragging the list drags
  /// the sheet. Its header, a plain [header] or a [headerBar] of any kind, is a handle:
  /// dragging it drags the sheet.
  ///
  /// A [controller] reads and moves the sheet from outside it: a share sheet
  /// that fits its height to content measured after layout, a comments sheet
  /// that rises to its ceiling when its field takes focus.
  const HarborSheet.draggable({
    super.key,
    this.header,
    this.footer,
    this.headerBar,
    this.footerBar,
    required ScrollableWidgetBuilder this.builder,
    this.extent = const HarborSheetExtent(),
    this.controller,
    this.expand = true,
    this.surface,
    @Deprecated(
      'Give headerBar: HarborSheet.defaultHeaderBar(header) or a HarborBar of your own, with its edgeEffect. '
      '`dart fix` applies it, but not where the header can be null. Deprecated after 0.9.1.',
    )
    final HarborEdgeEffect? headerEdgeEffect,
    @Deprecated(
      'Renamed headerEdgeEffect, itself deprecated: give headerBar: a HarborBar with its edgeEffect. `dart fix` applies it.',
    )
    final HarborEdgeEffect? headerWake,
    @Deprecated(
      'Give footerBar: HarborSheet.defaultFooterBar(footer) or a HarborBar of your own, with its edgeEffect. '
      '`dart fix` applies it, but not where the footer can be null. Deprecated after 0.9.1.',
    )
    final HarborEdgeEffect? footerEdgeEffect,
    @Deprecated(
      'Renamed footerEdgeEffect, itself deprecated: give footerBar: a HarborBar with its edgeEffect. `dart fix` applies it.',
    )
    final HarborEdgeEffect? footerWake,
    @Deprecated(
      'Give footerBar: HarborSheet.defaultFooterBar(footer) or a HarborBar of your own, with its minimum. '
      '`dart fix` applies it, but not where the footer can be null. Deprecated after 0.9.1.',
    )
    final double? footerMinimum,
    @Deprecated(
      'Give footerBar: HarborSheet.defaultFooterBar(footer) or a HarborBar of your own, with its keyboard. '
      '`dart fix` applies it, but not where the footer can be null. Deprecated after 0.9.1.',
    )
    final HarborKeyboardStance? footerKeyboard,
    @Deprecated(
      'Renamed footerKeyboard, itself deprecated: give footerBar: a HarborBar with its keyboard. `dart fix` applies it.',
    )
    final HarborKeyboardStance? footerTide,
    this.debugLabel,
    this.contentBuilder,
    this.clip,
    this.closeFlingVelocity = 700.0,
    final bool clearsTopSystemEdge = true,
    @Deprecated('Renamed clearsTopSystemEdge. `dart fix` applies it.') final bool? clearsTopCoast,
    this.clearsSides = false,
    final bool bodyClearsKeyboard = true,
    @Deprecated('Renamed bodyClearsKeyboard. `dart fix` applies it.') final bool? bodyClearsTide,
  }) : assert(header == null || headerBar == null, 'Give a sheet header or headerBar, not both.'),
       assert(footer == null || footerBar == null, 'Give a sheet footer or footerBar, not both.'),
       assert(
         headerBar == null || (headerEdgeEffect == null && headerWake == null),
         'headerEdgeEffect is for a plain header. Give a headerBar its own edgeEffect.',
       ),
       assert(
         footerBar == null ||
             (footerEdgeEffect == null &&
                 footerWake == null &&
                 footerMinimum == null &&
                 footerKeyboard == null &&
                 footerTide == null),
         'footerEdgeEffect, footerMinimum and footerKeyboard are for a plain footer. Give a footerBar its own.',
       ),
       assert(
         headerWake == null || headerEdgeEffect == null || identical(headerWake, headerEdgeEffect),
         'headerEdgeEffect and the deprecated headerWake disagree. Give headerBar alone.',
       ),
       assert(
         footerWake == null || footerEdgeEffect == null || identical(footerWake, footerEdgeEffect),
         'footerEdgeEffect and the deprecated footerWake disagree. Give footerBar alone.',
       ),
       assert(
         footerTide == null || footerKeyboard == null || footerTide == footerKeyboard,
         'footerKeyboard and the deprecated footerTide disagree. Give footerBar alone.',
       ),
       assert(
         clearsTopCoast == null || clearsTopSystemEdge || clearsTopCoast == clearsTopSystemEdge,
         'clearsTopSystemEdge and the deprecated clearsTopCoast disagree. Give clearsTopSystemEdge alone.',
       ),
       assert(
         bodyClearsTide == null || bodyClearsKeyboard || bodyClearsTide == bodyClearsKeyboard,
         'bodyClearsKeyboard and the deprecated bodyClearsTide disagree. Give bodyClearsKeyboard alone.',
       ),
       _headerEdgeEffect = headerEdgeEffect ?? headerWake ?? _defaultHeaderEdgeEffect,
       _footerEdgeEffect = footerEdgeEffect ?? footerWake ?? _defaultFooterEdgeEffect,
       _footerMinimum = footerMinimum ?? _defaultFooterMinimum,
       _footerKeyboard = footerKeyboard ?? footerTide ?? _defaultFooterKeyboard,
       clearsTopSystemEdge = clearsTopCoast ?? clearsTopSystemEdge,
       bodyClearsKeyboard = bodyClearsTide ?? bodyClearsKeyboard,
       assert(closeFlingVelocity >= 0.0),
       body = null,
       maxExtentFraction = null,
       dragToClose = false;

  static const HarborEdgeEffect _defaultHeaderEdgeEffect = HarborEdgeEffect.fade(length: 12.0);
  static const HarborEdgeEffect _defaultFooterEdgeEffect = HarborEdgeEffect.hairline();
  static const double _defaultFooterMinimum = 16.0;
  static const HarborKeyboardStance _defaultFooterKeyboard = HarborKeyboardStance.rides;

  /// The bar a plain [header] is put in: an overlay bar the body scrolls under, with a 12-long
  /// fade. Start a [headerBar] from it to keep the sheet's look and change one thing:
  /// `HarborSheet.defaultHeaderBar(title).copyWith(state: HarborBarState.withdrawn)`.
  static HarborBar defaultHeaderBar(final Widget child) =>
      HarborBar.overlay(edgeEffect: _defaultHeaderEdgeEffect, debugLabel: 'sheet header', child: child);

  /// The bar a plain [footer] is put in: a solid bar that rides the keyboard, with a hairline, and
  /// keeps 16 above the screen's edge on a phone with no home indicator. Start a [footerBar] from
  /// it to keep the sheet's look.
  static HarborBar defaultFooterBar(final Widget child) => HarborBar.solid(
    keyboard: _defaultFooterKeyboard,
    edgeEffect: _defaultFooterEdgeEffect,
    minimum: _defaultFooterMinimum,
    debugLabel: 'sheet footer',
    child: child,
  );

  /// A widget for the top of the sheet, put in [defaultHeaderBar]. Give [headerBar] instead to
  /// choose the bar.
  final Widget? header;

  /// A widget for the bottom of the sheet, put in [defaultFooterBar]. Give [footerBar] instead to
  /// choose the bar.
  final Widget? footer;

  /// The sheet's header, as a whole bar of any kind, in place of a plain [header]. On a
  /// [HarborSheet.draggable], dragging it drags the sheet.
  final HarborBar? headerBar;

  /// The sheet's footer, as a whole bar of any kind, in place of a plain [footer]: a footer that
  /// withdraws while the keyboard is up, one that reserves the keyboard's space, one with no
  /// hairline.
  final HarborBar? footerBar;

  final Widget? body;
  final ScrollableWidgetBuilder? builder;
  final HarborSheetExtent? extent;

  /// Drives a draggable sheet from outside it, as it drives a [DraggableScrollableSheet].
  final DraggableScrollableController? controller;

  /// Whether a draggable sheet fills the space it is given, as
  /// [DraggableScrollableSheet.expand] does. Turn it off where the route sizes
  /// the sheet to its content, as `showModalBottomSheet` does, so taps above
  /// the visible sheet reach the barrier.
  final bool expand;

  /// Painted under the whole sheet: its color and corners.
  final Widget? surface;

  final HarborEdgeEffect _headerEdgeEffect;
  final HarborEdgeEffect _footerEdgeEffect;
  final double _footerMinimum;
  final HarborKeyboardStance _footerKeyboard;

  /// The edge effect of a plain [header]'s bar.
  @Deprecated('Read headerBar, or HarborSheet.defaultHeaderBar. Deprecated after 0.9.1.')
  HarborEdgeEffect get headerEdgeEffect => _headerEdgeEffect;

  /// The old name of [headerEdgeEffect].
  @Deprecated('Read headerBar, or HarborSheet.defaultHeaderBar.')
  HarborEdgeEffect get headerWake => _headerEdgeEffect;

  /// The edge effect of a plain [footer]'s bar.
  @Deprecated('Read footerBar, or HarborSheet.defaultFooterBar. Deprecated after 0.9.1.')
  HarborEdgeEffect get footerEdgeEffect => _footerEdgeEffect;

  /// The old name of [footerEdgeEffect].
  @Deprecated('Read footerBar, or HarborSheet.defaultFooterBar.')
  HarborEdgeEffect get footerWake => _footerEdgeEffect;

  /// The minimum of a plain [footer]'s bar.
  @Deprecated('Read footerBar, or HarborSheet.defaultFooterBar. Deprecated after 0.9.1.')
  double get footerMinimum => _footerMinimum;

  /// How a plain [footer]'s bar meets the keyboard.
  @Deprecated('Read footerBar, or HarborSheet.defaultFooterBar. Deprecated after 0.9.1.')
  HarborKeyboardStance get footerKeyboard => _footerKeyboard;

  /// The old name of [footerKeyboard].
  @Deprecated('Read footerBar, or HarborSheet.defaultFooterBar.')
  HarborKeyboardStance get footerTide => _footerKeyboard;

  /// The header's bar: [headerBar], or a plain [header] in the sheet's own bar (with the
  /// deprecated knobs, where a call gives them).
  HarborBar? get _header =>
      headerBar ??
      switch (header) {
        final Widget header => HarborBar.overlay(
          edgeEffect: _headerEdgeEffect,
          debugLabel: 'sheet header',
          child: header,
        ),
        null => null,
      };

  /// The footer's bar: [footerBar], or a plain [footer] in the sheet's own bar.
  HarborBar? get _footer =>
      footerBar ??
      switch (footer) {
        final Widget footer => HarborBar.solid(
          keyboard: _footerKeyboard,
          edgeEffect: _footerEdgeEffect,
          minimum: _footerMinimum,
          debugLabel: 'sheet footer',
          child: footer,
        ),
        null => null,
      };

  final double? maxExtentFraction;
  final String? debugLabel;

  /// Wraps everything over the [surface] (header, body and footer), above the surface so ink
  /// shows. For a Material app, so text fields and ink work in the sheet:
  ///
  /// ```dart
  /// contentBuilder: (context, content) => Material(
  ///   type: MaterialType.transparency,
  ///   textStyle: DefaultTextStyle.of(context).style, // keep the opener's text style
  ///   child: content,
  /// ),
  /// ```
  ///
  /// harbor's core imports no design library: Flutter 3.47 moved Material and Cupertino into
  /// packages of their own (`material_ui`, `cupertino_ui`), and a layout package should not choose
  /// one for every app that uses it.
  final TransitionBuilder? contentBuilder;

  /// Clips the sheet to this shape, so a body that runs edge to edge (a photo)
  /// follows the surface's rounded top.
  final ShapeBorder? clip;

  /// Lets a content-sized sheet be dragged down to close, by any part of it
  /// that doesn't scroll, when [showHarborSheet] opened it. A draggable sheet
  /// always closes when dragged below its floor.
  final bool dragToClose;

  /// How fast a fling down, in logical pixels per second, closes the sheet:
  /// 700 by default, the speed at which a Material `BottomSheet` closes. A
  /// slower fling settles the sheet instead.
  ///
  /// A content-sized sheet with [dragToClose] closes on a faster fling from
  /// any height, and when let go under half shown, as a modal bottom sheet
  /// does. A draggable sheet closes on a faster fling on its header from its
  /// lowest snap; a slower one goes back to that snap. A fling on its header
  /// faster than 1200, or than this if it is higher, closes it from any height.
  /// [double.infinity] leaves only the floor to close it.
  ///
  /// A fling on a draggable sheet's list is [DraggableScrollableSheet]'s own,
  /// as it is in a modal bottom sheet: it goes to the next snap size its way,
  /// and from the lowest to the floor, which closes the sheet, at any speed.
  final double closeFlingVelocity;

  /// Whether the header and body clear the top system edge (the status bar) the
  /// sheet is handed. False leaves the sheet where it is and marks the top
  /// system edge handled for its content, which reads zero there: a header that paints
  /// under the status bar and pads its own title, or a body that runs to the
  /// top of a sheet capped at a fraction of the screen.
  ///
  /// It only matters for a sheet opened with `showHarborSheet(reachesTop: true)`.
  /// Otherwise the sheet stops short of the status bar and is handed no top
  /// system edge, so there is nothing to clear. `reachesTop` decides how far up
  /// the sheet may reach; this decides whether its content pads for what is
  /// up there.
  final bool clearsTopSystemEdge;

  /// The old name of [clearsTopSystemEdge].
  @Deprecated('Renamed clearsTopSystemEdge. `dart fix` applies it.')
  bool get clearsTopCoast => clearsTopSystemEdge;

  /// Whether the header, body and footer clear the system edges on the left and right
  /// (a phone's notch in landscape, a cutout on a side edge) and mark them handled,
  /// so content beneath does not clear it again. The [surface] still runs edge
  /// to edge.
  ///
  /// Off by default, as `showModalBottomSheet`'s `useSafeArea` is: the header
  /// and footer then run the sheet's full width and are handed the side system edges
  /// in `MediaQuery.padding`, as is the body, which clears them where it uses a [HarborClear].
  /// Material's `useSafeArea` (`ModalBottomSheetRoute.useSafeArea`, in the
  /// Flutter SDK's `packages/flutter/lib/src/material/bottom_sheet.dart`) wraps
  /// the whole sheet in a `SafeArea(bottom: false)`, surface and top included;
  /// this insets only what is over the surface, and only the sides.
  final bool clearsSides;

  /// Whether the sheet keeps its body above the keyboard, as [HarborFrame.bodyClearsKeyboard] does a
  /// page's. True by default: the body ends at the keyboard and the sheet's height is capped by
  /// the space above it.
  ///
  /// False leaves the keyboard to the body, for a sheet that manages it itself: a toolbar that
  /// holds a keyboard-sized space so nothing jumps when a field takes focus, or an inspector the
  /// keyboard may cover while something above it is edited. The body then runs under the
  /// keyboard and reads it in `MediaQuery.viewInsets`, a [HarborKeyboardStance.rides] footer still
  /// rides up on it, and [maxExtentFraction] (or a draggable sheet's extents) is a share of the
  /// whole height, the keyboard included.
  final bool bodyClearsKeyboard;

  /// The old name of [bodyClearsKeyboard].
  @Deprecated('Renamed bodyClearsKeyboard. `dart fix` applies it.')
  bool get bodyClearsTide => bodyClearsKeyboard;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborSheetExtent>('extent', extent, defaultValue: null));
    properties.add(DiagnosticsProperty<HarborBar>('headerBar', headerBar, defaultValue: null));
    properties.add(DiagnosticsProperty<HarborBar>('footerBar', footerBar, defaultValue: null));
    properties.add(
      DiagnosticsProperty<HarborEdgeEffect>(
        'headerEdgeEffect',
        _headerEdgeEffect,
        defaultValue: _defaultHeaderEdgeEffect,
      ),
    );
    properties.add(
      DiagnosticsProperty<HarborEdgeEffect>(
        'footerEdgeEffect',
        _footerEdgeEffect,
        defaultValue: _defaultFooterEdgeEffect,
      ),
    );
    properties.add(DoubleProperty('footerMinimum', _footerMinimum, defaultValue: _defaultFooterMinimum));
    properties.add(
      EnumProperty<HarborKeyboardStance>('footerKeyboard', _footerKeyboard, defaultValue: _defaultFooterKeyboard),
    );
    properties.add(
      PercentProperty(
        'maxExtentFraction',
        maxExtentFraction,
        level: maxExtentFraction == null || maxExtentFraction == 0.9 ? DiagnosticLevel.fine : DiagnosticLevel.info,
      ),
    );
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(ObjectFlagProperty<TransitionBuilder>.has('contentBuilder', contentBuilder));
    properties.add(DiagnosticsProperty<ShapeBorder>('clip', clip, defaultValue: null));
    properties.add(FlagProperty('dragToClose', value: dragToClose, ifTrue: 'drag to close'));
    properties.add(DoubleProperty('closeFlingVelocity', closeFlingVelocity, defaultValue: 700.0, unit: 'px/s'));
    properties.add(
      FlagProperty('clearsTopSystemEdge', value: clearsTopSystemEdge, ifFalse: 'casts off the top systemEdges'),
    );
    properties.add(FlagProperty('clearsSides', value: clearsSides, ifTrue: 'clears the sides'));
    properties.add(FlagProperty('bodyClearsKeyboard', value: bodyClearsKeyboard, ifFalse: 'body under the keyboard'));
  }

  /// Closes the sheet [context] is in, whichever way it was opened, and
  /// completes the future that opened it with [result], as [Navigator.pop]
  /// does for a route.
  ///
  /// A sheet with [HarborBarrier.none] is not a route, so this is the only
  /// way it returns a value: closed by back or by [Navigator.pop], it completes
  /// with null.
  @optionalTypeArgs
  static void close<T extends Object?>(final BuildContext context, [final T? result]) {
    final _SheetHostScope? scope = _SheetHostScope.maybeOf(context);
    if (scope != null && scope.host.close != null) {
      scope.close(result);
      return;
    }
    Navigator.maybePop<T>(context, result);
  }

  Widget _harbor(final Widget body, {required final bool hug, final HarborBar? header}) {
    final HarborBar? top = header ?? _header;
    final HarborBar? bottom = _footer;
    Widget port = HarborFrame(
      isPage: true,
      bodyClearsKeyboard: bodyClearsKeyboard,
      sizing: hug ? HarborSizing.hug(maxFraction: maxExtentFraction) : HarborSizing.fill,
      debugLabel: debugLabel ?? 'sheet',
      top: <HarborBar>[?top],
      bottom: <HarborBar>[?bottom],
      body: body,
    );
    if (!clearsTopSystemEdge) {
      // The system edges alone: the sheet keeps the height reachesTop gave it, and its new page frame
      // is handed no status bar to clear. The margin stays. The sheet still reaches under the
      // status bar, so its page frame keeps it out of its room, where toasts and floats go.
      final Widget content = port;
      port = Builder(
        builder: (final BuildContext context) => HarborClearWaterFloor(
          floor: EdgeInsetsDirectional.only(top: MediaQuery.paddingOf(context).top),
          child: HarborHandled(edges: const <HarborEdge>{HarborEdge.top}, margin: false, child: content),
        ),
      );
    }
    if (clearsSides) {
      // Clear of the side system edges alone, inside the surface, so the surface still runs edge to
      // edge and the new page frame beneath is handed no side system edges. The margin stays.
      port = HarborClear(edges: HarborEdge.horizontal, clearsBars: false, clearsKeyboard: false, child: port);
    }
    return port;
  }

  @override
  Widget build(final BuildContext context) {
    final HarborSheetExtent? extent = this.extent;
    if (extent != null) {
      // The surface goes inside the draggable sheet, so it is as tall as the
      // sheet is dragged, not as tall as the space the sheet can be dragged in.
      return _DraggableSheetBody(sheet: this, extent: extent);
    }
    final Widget sheet = _surfaced(context, _harbor(body!, hug: true));
    if (!dragToClose) {
      return sheet;
    }
    final _SheetHostScope? host = _SheetHostScope.maybeOf(context);
    assert(() {
      if (host != null) {
        return true;
      }
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('HarborSheet(dragToClose: true) was built outside a sheet that showHarborSheet opened.'),
        ErrorDescription(
          'Dragging to close needs the sheet showHarborSheet opened to close, and none is above this HarborSheet.',
        ),
        ErrorHint(
          'Open the sheet with showHarborSheet, or pass dragToClose: false where the HarborSheet is shown some other way, '
          'such as inside a page or a dialog.',
        ),
        context.describeElement('The HarborSheet was'),
      ]);
    }());
    return GestureDetector(
      onVerticalDragStart: (final DragStartDetails _) => host?.host.dragStart(),
      onVerticalDragUpdate: (final DragUpdateDetails details) => host?.host.dragBy(details.primaryDelta ?? 0.0),
      onVerticalDragEnd: (final DragEndDetails details) =>
          host?.host.dragEnd(details.primaryVelocity ?? 0.0, closeFlingVelocity),
      child: sheet,
    );
  }

  Widget _surfaced(final BuildContext context, final Widget content) {
    Widget sheet = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(child: surface ?? const SizedBox.shrink()),
        // Over the surface, not around it: ink paints under a Material's child.
        if (contentBuilder case final TransitionBuilder wrap) wrap(context, content) else content,
      ],
    );
    final ShapeBorder? clip = this.clip;
    if (clip != null) {
      sheet = ClipPath(
        clipper: ShapeBorderClipper(shape: clip, textDirection: Directionality.maybeOf(context)),
        clipBehavior: Clip.antiAlias,
        child: sheet,
      );
    }
    return sheet;
  }
}

// A fling on a draggable sheet's header faster than this goes to the next snap its way.
const double _snapFlingVelocity = 400.0;

// A fling down on a draggable sheet's header faster than this closes it from any height.
const double _closeFromAnyHeightVelocity = 1200.0;

class _DraggableSheetBody extends StatefulWidget {
  const _DraggableSheetBody({required this.sheet, required this.extent});

  final HarborSheet sheet;
  final HarborSheetExtent extent;

  @override
  State<_DraggableSheetBody> createState() => _DraggableSheetBodyState();
}

class _DraggableSheetBodyState extends State<_DraggableSheetBody> {
  DraggableScrollableController? _ownController;
  double _available = 0.0;

  DraggableScrollableController get _controller =>
      widget.sheet.controller ?? (_ownController ??= DraggableScrollableController());

  HarborSheetExtent get _extent => widget.extent;

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  // The header is a handle: dragging it drags the sheet.
  void _drag(final DragUpdateDetails details) {
    if (!_controller.isAttached || _available <= 0) {
      return;
    }
    final double size = (_controller.size - (details.primaryDelta ?? 0.0) / _available).clamp(0.0, _extent.max);
    _controller.jumpTo(size);
  }

  void _release(final DragEndDetails details) {
    if (!_controller.isAttached) {
      return;
    }
    final double velocity = details.primaryVelocity ?? 0.0;
    final double size = _controller.size;
    final bool closes = _extent.shouldCloseOnMinExtent;
    final double closeFling = widget.sheet.closeFlingVelocity;
    if (closes && (size <= _extent.min + 0.001 || velocity > math.max(_closeFromAnyHeightVelocity, closeFling))) {
      _close();
      return;
    }
    double target = size;
    if (_extent.snap) {
      // As a dragged list snaps: a fling goes to the next size its way, and a
      // slow release to the nearest. Past the lowest, a fling goes to the
      // floor, and so closes the sheet only when faster than closeFlingVelocity.
      final List<double> snaps = _extent._snaps;
      final Iterable<double> lower = snaps.where((final double snap) => snap < size - 0.001);
      if (velocity < -_snapFlingVelocity) {
        target = snaps.firstWhere((final double snap) => snap > size + 0.001, orElse: () => snaps.last);
      } else if (velocity > _snapFlingVelocity && lower.isNotEmpty) {
        target = lower.last;
      } else if (lower.isEmpty && velocity > (closes ? closeFling : _snapFlingVelocity)) {
        target = _extent.min;
      } else {
        target = snaps.reduce((final double a, final double b) => (size - a).abs() <= (size - b).abs() ? a : b);
      }
    }
    if (closes && target <= _extent.min + 0.001) {
      _close();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
      return;
    }
    unawaited(_controller.animateTo(target, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic));
  }

  void _close() {
    final _SheetHostScope? host = _SheetHostScope.maybeOf(context);
    if (host != null) {
      host.close();
      return;
    }
    // Opened some other way (showModalBottomSheet, showGeneralDialog): the
    // sheet is the popup route's content, so closing it closes the route. In
    // a page, a sheet rests at its floor.
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    if (route is PopupRoute<Object?> && route.isCurrent) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final _SheetHostScope? host = _SheetHostScope.maybeOf(context);
    final Widget sheet = LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        _available = constraints.maxHeight;
        return _draggable(host);
      },
    );
    if (!widget.sheet.bodyClearsKeyboard) {
      // The body manages the keyboard: the extents are of the whole height, and the keyboard
      // stays in the body's view insets.
      return sheet;
    }
    // Fractions are of the space above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: MediaQuery.removeViewInsets(context: context, removeBottom: true, child: sheet),
    );
  }

  Widget _draggable(final _SheetHostScope? host) {
    host?.host._draggable = true;
    // Its measured box is the whole screen, so report the resting height
    // until the first drag reports the real one.
    if (host != null && !host.host.hasDragExtent) {
      WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
        if (!host.host.hasDragExtent) {
          host.reportExtent(_extent.rest, _available);
        }
      });
    }
    final HarborSheet sheet = widget.sheet;
    // The header is a handle, whatever bar it is in: dragging it drags the sheet.
    final HarborBar? bar = sheet._header;
    final HarborBar? header = bar?.copyWith(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _drag,
        onVerticalDragEnd: _release,
        child: bar.child,
      ),
    );
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (final DraggableScrollableNotification n) {
        host?.reportExtent(n.extent, _available);
        if (n.shouldCloseOnMinExtent && n.extent <= n.minExtent + 0.001) {
          _close();
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        expand: sheet.expand,
        initialChildSize: _extent.rest,
        minChildSize: _extent.min,
        maxChildSize: _extent.max,
        snap: _extent.snap,
        snapSizes: _extent.snap ? _extent._snaps : null,
        shouldCloseOnMinExtent: _extent.shouldCloseOnMinExtent,
        builder: (final BuildContext context, final ScrollController controller) => _MeasureHeight(
          onTop: (final double top) => host?.host.reportTop(top, fromSheet: true),
          child: sheet._surfaced(
            context,
            sheet._harbor(
              Builder(builder: (final BuildContext context) => sheet.builder!(context, controller)),
              hug: false,
              header: header,
            ),
          ),
        ),
      ),
    );
  }
}

/// Closes and rebuilds a sheet [showHarborSheet] opened, from outside it: a
/// now-playing drawer that a button on the page opens and closes, an editor's
/// tool panel the page puts away when a tool is picked.
///
/// Give it to [showHarborSheet]; it is attached while that sheet is up, and
/// tells its listeners when a sheet attaches and when it has left. It holds one
/// sheet at a time and can be given to the next once the last has left.
/// [close], [remove] and [closed] may be called whether or not a sheet is
/// attached; [animation] and [setState] need one, as a
/// [DraggableScrollableController] does.
class HarborSheetController extends ChangeNotifier {
  _SheetHost? _host;

  /// Whether a sheet is attached: from when it opens until it has left, its
  /// closing slide included.
  bool get isAttached => _host != null;

  /// The sheet's slide, from 0 (out of sight) to 1 (open).
  Animation<double> get animation {
    _assertAttached();
    return _host!.slide!;
  }

  /// Completes when the sheet has left, however it closed; complete already when no sheet is
  /// attached.
  Future<void> get closed => _host?.gone ?? Future<void>.value();

  /// Slides the sheet out, as back or a tap on its barrier would. Nothing once it has left,
  /// however it went (closed here, its page popped, or torn down with its overlay, #118), so a
  /// widget can close the sheet it opened from its own dispose without asking first; and nothing
  /// more while it is already sliding out.
  void close() => _host?.close?.call();

  /// Takes the sheet away at once, with no slide; nothing once it has left.
  void remove() => _host?.remove?.call();

  /// Calls [fn] and rebuilds the sheet, for a builder that reads state the page holds.
  void setState(final VoidCallback fn) {
    _assertAttached();
    fn();
    _host!.rebuild?.call();
  }

  void _assertAttached() {
    assert(
      isAttached,
      'HarborSheetController is not attached to a sheet. Give it to showHarborSheet, and use it '
      'only while that sheet is up.',
    );
  }

  void _attach(final _SheetHost host) {
    assert(_host == null, 'HarborSheetController is already attached to a sheet.');
    _host = host;
    notifyListeners();
  }

  void _detach(final _SheetHost host) {
    if (_host == host) {
      _host = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _host?.controller = null;
    _host = null;
    super.dispose();
  }
}

/// Opens [builder]'s sheet (usually a [HarborSheet]) over [context]'s frame.
///
/// With [coversPage] set, the sheet reports how far it covers the bottom of
/// the frame that opened it, animated as it slides in and out and as it is
/// dragged, and that frame's content keeps clear of it: a scroll view's last row
/// stays reachable, a lifted canvas element stays in sight.
///
/// [barrier] is what the sheet puts over the page: [HarborBarrier.dimmed] by default, with
/// `showGeneralDialog`'s half-black, as a dialog's is; [HarborBarrier.clear], which leaves the page
/// in view but out of reach; or [HarborBarrier.none]. A tap on the barrier closes the sheet unless
/// it is not `dismissible`, which makes a sheet the user has to answer; back still closes it, as it
/// closes a modal bottom sheet.
///
/// A sheet with a barrier is a route, as a modal bottom sheet is: [routeSettings]
/// reach navigator observers and route-name analytics, and the barrier is
/// announced with its `label` ('Dismiss' when none is given, the English
/// Material and Cupertino fall back to; a Material app passes
/// `MaterialLocalizations.of(context).modalBarrierDismissLabel` for the
/// localized one). Its `onTapHint` says what tapping the barrier does, read
/// as 'Double tap to …' ('Double tap to activate' when none is given), as
/// `ModalBottomSheetRoute.barrierOnTapHint` does.
///
/// Like a modal bottom sheet, a sheet that is a route is a semantics scope of its
/// own: it scopes and names its route, and screen readers announce
/// [semanticLabel] as it opens and closes. See
/// [SemanticsConfiguration.namesRoute].
///
/// A sheet with [HarborBarrier.none] is not a route, so it has none of
/// these. It is not modal either, as a persistent bottom sheet is not: focus moves
/// freely between it and the page. It is a [FocusScope] of its own, as a route
/// is, so Tab goes through the sheet in order and then on to the page, and Escape
/// (a [DismissIntent]) closes it, as back does, from focus in the sheet or in a
/// frame on the page that opened it.
///
/// [requestFocus] is whether the sheet takes focus when it opens, as
/// [Route.requestFocus]. Left null, a sheet that is a route follows
/// [Navigator.requestFocus], and a sheet with no barrier leaves focus where it
/// was, as a persistent bottom sheet does.
///
/// The future completes with the result given to [HarborSheet.close], or with
/// null when the sheet is closed some other way.
///
/// [anchorPoint] picks the screen a sheet opens on, on a device with a hinge:
/// the one nearest it, as for [DisplayFeatureSubScreen]. [hinge] is which hinges
/// and folds it keeps off.
///
/// Three options decide how tall the sheet may be, and one on the sheet decides what its
/// content does up there:
///
/// * Without [reachesTop], the sheet stops short of the status bar and its content is handed no
///   top system edge.
/// * With [reachesTop], the sheet may reach the top of the screen, and its content is handed the
///   status bar to clear, as a page's is.
/// * With [fillsScreenAtHinge], a sheet a hinge keeps to one screen fills that screen top to
///   bottom, as Microsoft suggests for a partial overlay on a dual-screen device. Filling it
///   reaches the top, so on a split screen it implies [reachesTop]; with no hinge it changes
///   nothing, and [reachesTop] alone decides. The two can both be set: a sheet that reaches the
///   top, and fills its screen on a dual-screen device.
/// * [HarborSheet.clearsTopSystemEdge] false keeps whatever height these gave the sheet and
///   casts the status bar off for content that pads for it itself. It changes nothing on a sheet
///   that stops short of the status bar.
///
/// [maxWidth] caps a sheet on a wide screen. A Material app that wants the
/// bottom sheet theme's cap passes
/// `Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640`.
///
/// [sheetAnimationStyle] sets how the sheet slides in and out, as it does for
/// `showModalBottomSheet`: by default it opens over 280 ms and closes over 220 ms
/// (280 ms both ways with [HarborBarrier.none]), along [Curves.easeOutCubic]
/// both ways. [AnimationStyle.noAnimation] opens and closes it at once. Whatever
/// the style leaves out keeps its default; as on a modal bottom sheet, `curve`
/// alone does not set the reverse curve. Reduced motion
/// (`MediaQuery.disableAnimations`) still wins: the sheet is simply there.
///
/// A [controller] closes and rebuilds the sheet from outside it. A
/// [transitionAnimationController] slides the sheet in place of its own 280 ms
/// slide, as it does a modal bottom sheet: the sheet runs it forward to open
/// and back to close, and the caller disposes it.
///
/// `isDismissible`, `barrierColor`, `barrierLabel` and `barrierOnTapHint` are the spellings of the
/// barrier through 0.9, deprecated: given, each overrides the matching field of [barrier]
/// (`barrierColor` only tints a dimmed barrier, as it only ever did). With [HarborBarrier.none]
/// they do nothing, and are ignored, as they always were.
///
/// See also:
///
///  * `showModalBottomSheet` and `ModalBottomSheetRoute`, the Material equivalent of a sheet with a
///    barrier, and `ScaffoldState.showBottomSheet`, of one with [HarborBarrier.none].
Future<T?> showHarborSheet<T>(
  final BuildContext context, {
  required final WidgetBuilder builder,
  final bool coversPage = false,
  @Deprecated('Renamed coversPage. `dart fix` applies it.') final bool? breakwater,
  final HarborBarrier barrier = const HarborBarrier.dimmed(),
  @Deprecated('Use barrier: HarborBarrier.dimmed(dismissible: ...). `dart fix` applies it. Deprecated after 0.9.1.')
  final bool? isDismissible,
  @Deprecated('Use barrier: HarborBarrier.dimmed(color: ...). `dart fix` applies it. Deprecated after 0.9.1.')
  final Color? barrierColor,
  final double? maxWidth,
  final bool useRootNavigator = false,
  final Offset? anchorPoint,
  final bool? requestFocus,
  final bool reachesTop = false,
  @Deprecated('Renamed reachesTop. `dart fix` applies it.') final bool? keepsTopCoast,
  final RouteSettings? routeSettings,
  @Deprecated('Use barrier: HarborBarrier.dimmed(label: ...). `dart fix` applies it. Deprecated after 0.9.1.')
  final String? barrierLabel,
  final AnimationStyle? sheetAnimationStyle,
  final HarborSheetController? controller,
  final AnimationController? transitionAnimationController,
  @Deprecated('Use barrier: HarborBarrier.dimmed(onTapHint: ...). `dart fix` applies it. Deprecated after 0.9.1.')
  final String? barrierOnTapHint,
  final String? semanticLabel,
  final HarborHinge? hinge,
  final bool fillsScreenAtHinge = false,
}) {
  // With HarborBarrier.none the deprecated loose arguments do nothing, and are ignored, as they were
  // through 0.9.1: whether the barrier is none can turn on a variable `dart fix` leaves alone, so an
  // assert here would break calls that worked. When they are removed at 1.0 there is nothing to
  // assert on.
  final HarborBarrier effective = harborBarrierWith(
    barrier,
    color: barrierColor,
    dismissible: isDismissible,
    label: barrierLabel,
    onTapHint: barrierOnTapHint,
  );
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final HarborController? presenter = HarborController.maybeOf(context);
  // The sheet is built in the navigator's overlay, so it takes the themes and
  // text style of the page that opened it, as a modal bottom sheet does.
  final CapturedThemes themes = InheritedTheme.capture(from: context, to: navigator.context);
  final _SheetHost host = _SheetHost(
    // A Builder, so the builder's own context sees the captured themes, not only what it returns:
    // `Theme.of(context)` in a sheet's builder read the navigator's theme, not the page's.
    builder: (final BuildContext _) => themes.wrap(Builder(builder: builder)),
    maxWidth: maxWidth,
    reachesTop: renamed(keepsTopCoast, reachesTop, false, 'reachesTop', 'keepsTopCoast'),
    anchorPoint: anchorPoint,
    presenter: renamed(breakwater, coversPage, false, 'coversPage', 'breakwater') ? presenter : null,
    animationStyle: sheetAnimationStyle,
    controller: controller,
    scopesRoute: effective.blocks,
    semanticLabel: semanticLabel,
    hinge: hinge ?? HarborHinge.of(context),
    fillsScreenAtHinge: fillsScreenAtHinge,
  );
  if (!effective.blocks) {
    final OverlayState overlay = navigator.overlay!;
    // A non-modal sheet lives in the navigator's overlay, not in a route of its own, so it is tied
    // to the page's route by hand: back closes it first, it hides while another page is on top,
    // and it leaves when its page does. It also leaves with the frame that opened it.
    final _NonModalSheet<T> sheet = _NonModalSheet<T>(
      host: host,
      navigator: navigator,
      overlay: overlay,
      route: ModalRoute.of(context),
      requestFocus: requestFocus ?? false,
      transition: transitionAnimationController,
    );
    void presenterLeft() => sheet.closeNow();
    presenter?.addLeaveListener(presenterLeft);
    return sheet.open().whenComplete(() => presenter?.removeLeaveListener(presenterLeft));
  }
  return navigator.push<T>(
    _HarborSheetRoute<T>(
      host: host,
      barrierColor: effective.color,
      barrierDismissible: effective.isDismissible,
      barrierLabel: effective.label ?? harborBarrierDismissLabel,
      barrierOnTapHint: effective.onTapHint,
      settings: routeSettings,
      animationStyle: sheetAnimationStyle,
      transitionAnimationController: transitionAnimationController,
      requestFocus: requestFocus,
    ),
  );
}

class _SheetHost {
  _SheetHost({
    required this.builder,
    required this.maxWidth,
    required this.reachesTop,
    required this.anchorPoint,
    required this.presenter,
    required this.animationStyle,
    required this.controller,
    required this.scopesRoute,
    required this.semanticLabel,
    required this.hinge,
    this.fillsScreenAtHinge = false,
  }) {
    _shown.addListener(_moveTop);
  }

  /// Which hinges and folds the sheet keeps off; [anchorPoint] picks the side.
  final HarborHinge hinge;

  /// Whether a sheet kept to one screen by a hinge fills that screen, top to bottom.
  final bool fillsScreenAtHinge;

  /// Whether a hinge the sheet keeps off splits the screen, so the sheet is on one side of it.
  bool _split = false;

  final WidgetBuilder builder;
  final double? maxWidth;
  final bool reachesTop;
  final Offset? anchorPoint;
  final HarborController? presenter;
  final AnimationStyle? animationStyle;

  /// Whether the sheet is a route of its own; one with no barrier is not.
  final bool scopesRoute;
  final String? semanticLabel;

  HarborPageCover? _breakwater;
  double _height = 0.0;
  double? _dragExtent;
  double _available = 0.0;
  void Function([Object? result])? close;
  VoidCallback? remove;
  VoidCallback? rebuild;
  HarborSheetController? controller;
  final Completer<void> _gone = Completer<void>();

  Future<void> get gone => _gone.future;

  static const Curve _defaultCurve = Curves.easeOutCubic;

  Curve get _curve => animationStyle?.curve ?? _defaultCurve;
  Curve get _reverseCurve => animationStyle?.reverseCurve ?? _defaultCurve;

  AnimationController? _slide;

  /// How much of the sheet shows: [slide] along the curve, or [slide] itself while it is dragged.
  final ProxyAnimation _shown = ProxyAnimation(kAlwaysDismissedAnimation);
  CurvedAnimation? _curved;

  /// What slides the sheet in and out, for dragging it down by hand.
  AnimationController? get slide => _slide;
  set slide(final AnimationController? slide) {
    _slide = slide;
    _follow(_curve, _reverseCurve);
  }

  /// What the sheet is painted with: [_shown], or all of it under reduced motion.
  late Animation<double> _painted = _shown;

  /// How much of the sheet is drawn this frame, as a fraction of its height. A curve may start
  /// below zero, as Curves.easeInBack does.
  double get _drawn => math.max(0.0, _painted.value);

  void _follow(final Curve curve, final Curve reverseCurve) {
    _curved?.dispose();
    final AnimationController? slide = _slide;
    _curved = slide == null ? null : CurvedAnimation(parent: slide, curve: curve, reverseCurve: reverseCurve);
    _shown.parent = _curved ?? kAlwaysDismissedAnimation;
  }

  // As a modal bottom sheet does, a dragged sheet follows its controller with no curve, so it stays
  // under the finger whatever the curve is (one that overshoots has no inverse). Caught while it
  // moves, the controller first takes what is shown, so nothing jumps.
  void dragStart() {
    final AnimationController? slide = this.slide;
    if (slide == null) {
      return;
    }
    slide.value = _shown.value;
    _shown.parent = slide;
  }

  void dragBy(final double delta) {
    final AnimationController? slide = this.slide;
    if (slide == null || _height <= 0) {
      return;
    }
    slide.value -= delta / _height;
  }

  void dragEnd(final double velocity, final double closeFlingVelocity) {
    final AnimationController? slide = this.slide;
    if (slide == null) {
      return;
    }
    // On from where the finger let go, along the curve for what is left of the way.
    _follow(Split(slide.value, endCurve: _curve), Split(slide.value, endCurve: _reverseCurve));
    // As a modal bottom sheet has it: a fling down, or let go under half shown.
    if (velocity > closeFlingVelocity || slide.value < 0.5) {
      close?.call();
    } else {
      unawaited(slide.forward());
    }
  }

  void dispose() {
    _shown.parent = kAlwaysDismissedAnimation;
    _curved?.dispose();
    _curved = null;
  }

  /// Where the sheet's visible top is, in global coordinates.
  final ValueNotifier<double> topInGlobal = ValueNotifier<double>(double.infinity);

  /// Told where the sheet's visible top is as it is painted, a frame before [topInGlobal].
  ValueChanged<double>? onTopPainted;

  // The top as last painted, and how far the sheet showed and was dragged then.
  double? _paintedTop;
  double _paintedShown = 0.0;
  double? _paintedExtent;

  // A painted top reaches the page under the sheet a frame late, so as the sheet slides or is
  // dragged its new top is worked out from the last painted one, before this frame lays out.
  void _moveTop() {
    final double? top = _paintedTop;
    // In build or layout the pages under the sheet may already be laid out; paint measures it then.
    if (top == null || SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      return;
    }
    final double? extent = _dragExtent;
    final double? paintedExtent = _paintedExtent;
    final double dragged = extent == null || paintedExtent == null ? 0.0 : (extent - paintedExtent) * _available;
    topInGlobal.value = top - (_drawn - _paintedShown) * _height - dragged;
  }

  void attach() {
    _breakwater ??= presenter?.addPageCoverEdge(topInGlobal);
    controller?._attach(this);
  }

  /// The sheet is gone, by whichever way it closed.
  void left() {
    if (!_gone.isCompleted) {
      _gone.complete();
    }
    final HarborSheetController? controller = this.controller;
    this.controller = null;
    controller?._detach(this);
  }

  void reportTop(final double top, {required final bool fromSheet}) {
    // A draggable sheet's outer box is the whole drag area; only the sheet
    // inside it knows where its top is.
    if (_draggable && !fromSheet) {
      return;
    }
    _paintedTop = top;
    _paintedShown = _drawn;
    _paintedExtent = _dragExtent;
    onTopPainted?.call(top);
    // Reported during paint now, and page cover listeners lay out other routes, so they hear of it
    // after this frame; between paints, _moveTop keeps topInGlobal moving with the slide.
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) => topInGlobal.value = top);
  }

  void detach() {
    _breakwater?.remove();
    _breakwater = null;
  }

  bool get hasDragExtent => _dragExtent != null;
  bool _draggable = false;

  void measured(final double height) => _height = height;

  void reportExtent(final double extent, final double available) {
    _dragExtent = extent;
    _available = available;
    _moveTop();
  }

  // Kept to one screen of a foldable, never across its hinge, as a Material bottom sheet is.
  Widget build(final BuildContext context) {
    final MediaQueryData whole = MediaQuery.of(context);
    _split = hinge.keptOff(whole.displayFeatures).isNotEmpty;
    return MediaQuery(
      data: hinge.splitting(whole),
      child: DisplayFeatureSubScreen(
        anchorPoint: anchorPoint,
        child: Builder(builder: _build),
      ),
    );
  }

  Widget _build(final BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    // With reduced motion the sheet is simply there: its route still takes its time, but nothing slides.
    final Animation<double> animation = mediaQuery.disableAnimations ? kAlwaysCompleteAnimation : _shown;
    _painted = animation;
    // Built inside the sheet, so its context can close the sheet.
    Widget sheet = Builder(builder: builder);
    // Kept to one screen by a hinge, it may take that screen whole, as Microsoft suggests for a
    // partial overlay on a dual-screen device: top to bottom, keeping the status bar as its system
    // edge.
    // DisplayFeatureSubScreen places the sheet on one side with padding and leaves the size in
    // MediaQuery the whole screen's, so the split is known from the hinge, not from the size.
    final bool fills = fillsScreenAtHinge && _split;
    final bool keepsTop = reachesTop || fills;
    // A sheet stops short of the status bar unless it keeps the top system edge.
    final double top = keepsTop ? 0.0 : mediaQuery.padding.top;
    final double height = math.max(0.0, mediaQuery.size.height - top);
    sheet = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity, maxHeight: height),
      // Filling, it takes all the height its side of the hinge gives it.
      child: fills ? SizedBox(height: double.infinity, child: sheet) : sheet,
    );
    if (scopesRoute) {
      // As a modal bottom sheet's: the route is the sheet, so the scope is the sheet's box, not the
      // screen the barrier covers.
      sheet = Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: sheet,
      );
    }
    return _SheetHostScope(
      host: this,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: !keepsTop,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: animation,
            builder: (final BuildContext context, final Widget? child) => ClipRect(
              child: Align(alignment: Alignment.topCenter, heightFactor: _drawn, child: child),
            ),
            child: _MeasureHeight(
              onHeight: measured,
              onTop: (final double top) => reportTop(top, fromSheet: false),
              child: sheet,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHostScope extends InheritedWidget {
  const _SheetHostScope({required this.host, required super.child});

  final _SheetHost host;

  static _SheetHostScope? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SheetHostScope>();

  /// [extent] is a share of [available], the height the draggable sheet lays out in: the space
  /// above the keyboard, or the whole height when its body manages the keyboard.
  void reportExtent(final double extent, final double available) => host.reportExtent(extent, available);

  void close([final Object? result]) => host.close?.call(result);

  @override
  bool updateShouldNotify(final _SheetHostScope oldWidget) => false;
}

class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({this.onHeight, required this.onTop, super.child});

  final ValueChanged<double>? onHeight;

  /// Told where this box's top is in global coordinates, as it is painted.
  final ValueChanged<double> onTop;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderMeasureHeight(onHeight, onTop);

  @override
  void updateRenderObject(final BuildContext context, final _RenderMeasureHeight renderObject) {
    renderObject
      ..onHeight = onHeight
      ..onTop = onTop;
  }
}

class _RenderMeasureHeight extends RenderProxyBox {
  _RenderMeasureHeight(this.onHeight, this.onTop);

  ValueChanged<double>? onHeight;
  ValueChanged<double> onTop;
  double? _lastTop;

  @override
  void performLayout() {
    super.performLayout();
    final double height = size.height;
    // Page cover listeners lay out other routes, so tell them after this pass.
    final ValueChanged<double>? onHeight = this.onHeight;
    if (onHeight != null) {
      WidgetsBinding.instance.addPostFrameCallback((final Duration _) => onHeight(height));
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    super.paint(context, offset);
    final double top = localToGlobal(Offset.zero).dy;
    if (top != _lastTop) {
      _lastTop = top;
      onTop(top);
    }
  }
}

class _HarborSheetRoute<T> extends PopupRoute<T> {
  _HarborSheetRoute({
    required this.host,
    required this.barrierColor,
    required this.barrierDismissible,
    required this.barrierLabel,
    required this.transitionAnimationController,
    required this.barrierOnTapHint,
    required this.animationStyle,
    super.settings,
    super.requestFocus,
  });

  final _SheetHost host;
  final AnimationStyle? animationStyle;
  final AnimationController? transitionAnimationController;

  @override
  final Color barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String barrierLabel;

  final String? barrierOnTapHint;

  @override
  Duration get transitionDuration => animationStyle?.duration ?? const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => animationStyle?.reverseDuration ?? const Duration(milliseconds: 220);

  // The caller's controller, as ModalBottomSheetRoute takes it: driven here, disposed by the caller.
  @override
  AnimationController createAnimationController() {
    final AnimationController? transition = transitionAnimationController;
    if (transition == null) {
      return super.createAnimationController();
    }
    willDisposeAnimationController = false;
    return transition;
  }

  @override
  void install() {
    super.install();
    host
      ..close = ([final Object? result]) {
        if (isActive && isCurrent) {
          navigator?.pop<T>(result as T?);
        }
      }
      ..remove = () {
        if (isActive) {
          navigator?.removeRoute(this);
        }
      }
      ..rebuild = changedExternalState
      ..slide = controller
      ..onTopPainted = _clipBarrierSemantics
      ..attach();
  }

  /// How much of the barrier's semantics the sheet covers, as on ModalBottomSheetRoute, so a
  /// screen reader exploring the sheet finds its content, not the barrier.
  final ValueNotifier<EdgeInsets> _clipDetailsNotifier = ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  // From the sheet's visible top, where ModalBottomSheetRoute uses its laid-out height, so the
  // clip follows a slide or a drag and stops at a draggable sheet rather than its drag area.
  void _clipBarrierSemantics(final double top) {
    final RenderObject? overlay = navigator?.overlay?.context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize || !top.isFinite) {
      return;
    }
    final double height = overlay.size.height;
    final double covered = height - overlay.globalToLocal(Offset(0.0, top)).dy;
    _clipDetailsNotifier.value = EdgeInsets.only(bottom: covered.clamp(0.0, height));
  }

  @override
  void dispose() {
    host
      ..onTopPainted = null
      ..detach()
      ..left()
      ..dispose();
    _clipDetailsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
  ) => host.build(context);

  // ModalRoute's barrier, with the tap hint and semantics clip ModalBottomSheetRoute gives its own:
  // ModalRoute has no field for either.
  @override
  Widget buildModalBarrier() {
    if (barrierColor.a != 0 && !offstage) {
      return AnimatedModalBarrier(
        color: animation!.drive(
          ColorTween(
            begin: barrierColor.withValues(alpha: 0.0),
            end: barrierColor,
          ).chain(CurveTween(curve: barrierCurve)),
        ),
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        clipDetailsNotifier: _clipDetailsNotifier,
        semanticsOnTapHint: barrierOnTapHint,
      );
    }
    return ModalBarrier(
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      clipDetailsNotifier: _clipDetailsNotifier,
      semanticsOnTapHint: barrierOnTapHint,
    );
  }
}

class _NonModalSheet<T> {
  _NonModalSheet({
    required this.host,
    required this.navigator,
    required this.overlay,
    required this.route,
    required this.requestFocus,
    final AnimationController? transition,
  }) : _animation =
           transition ??
           AnimationController(
             vsync: overlay,
             duration: host.animationStyle?.duration ?? const Duration(milliseconds: 280),
             reverseDuration: host.animationStyle?.reverseDuration ?? const Duration(milliseconds: 280),
           ),
       _ownsAnimation = transition == null;

  final _SheetHost host;
  final NavigatorState navigator;
  final OverlayState overlay;
  final bool requestFocus;

  /// The page that opened the sheet. Tied to it with a local history entry, so back (and a
  /// pop) closes the sheet before the page, and the iOS back swipe stands aside while it is up.
  ///
  /// NOT COVERED: a `PopScope` inside the sheet. It registers with the nearest ModalRoute, and
  /// a sheet with no barrier deliberately is not one; wrap the PAGE in the PopScope instead.
  final ModalRoute<Object?>? route;
  LocalHistoryEntry? _history;
  final AnimationController _animation;

  /// False for a caller's controller, which outlives the sheet.
  final bool _ownsAnimation;
  OverlayEntry? _entry;
  final Completer<T?> _done = Completer<T?>();

  /// The page hosting the sheet, when it is drawn by its page rather than by an entry of its own.
  _HarborPageSheetHostState? _pageHost;

  /// From [open] until the sheet is taken out of the tree.
  bool _live = false;

  // A scope of its own beside the page's, with its navigator's edge behaviour, as a route's
  // scope is: at the sheet's last control, Tab does what it does at a route's. Without it the
  // sheet's controls sat in the navigator's own scope, and under a navigator that keeps Tab inside
  // each route, Tab left the sheet for the page and never came back.
  late final FocusScopeNode _focus = FocusScopeNode(debugLabel: 'HarborSheet (no barrier)')
    ..traversalEdgeBehavior = navigator.widget.routeTraversalEdgeBehavior
    ..directionalTraversalEdgeBehavior = navigator.widget.routeDirectionalTraversalEdgeBehavior;

  Future<T?> open() {
    host
      ..close = ([final Object? result]) {
        unawaited(_close(result as T?));
      }
      ..remove = closeNow
      ..rebuild = _markNeedsBuild
      ..slide = _animation
      ..attach();
    final ModalRoute<Object?>? route = this.route;
    // In a page with a frame, the page hosts the sheet through an OverlayPortal, which paints it
    // just above the page and below every route pushed after it: a dialog, a modal sheet or a menu
    // over the page sits over the sheet too, as over a Scaffold's persistent bottom sheet. A free
    // overlay entry could not: the navigator rearranges its overlay on every history change and
    // keeps entries that are not its routes' on top of all of them, dialogs included (#104).
    _live = true;
    _pageHost = route == null ? null : _HarborPageSheets.of(route).host;
    if (_pageHost case final _HarborPageSheetHostState pageHost) {
      pageHost.draw(this);
    } else {
      _entry = OverlayEntry(builder: (final BuildContext context) => build(context, hosted: false));
      overlay.insert(_entry!);
    }
    if (route != null) {
      _HarborPageSheets.of(route).add(this);
      _history = LocalHistoryEntry(
        onRemove: () {
          _history = null;
          unawaited(_close());
        },
      );
      route.addLocalHistoryEntry(_history!);
      // Popped or replaced: the sheet goes with it.
      unawaited(route.completed.whenComplete(closeNow));
    }
    _animation.forward();
    return _done.future;
  }

  /// The sheet as it is drawn, by its page ([hosted]) or by an overlay entry of its own.
  Widget build(final BuildContext context, {required final bool hosted}) => _SheetLifeline(
    onGone: _gone,
    child: _build(context, hosted: hosted),
  );

  // Torn down with the sheet still open (the navigator's whole subtree replaced, as an app does on
  // sign-out, or a test swapping the tree): nothing closed it first, so its transition, made on the
  // overlay, was never stopped. The overlay then failed its own dispose with an active ticker in
  // debug and leaked it in release, and the sheet's future never completed (#118).
  void _gone() {
    if (_live) {
      closeNow();
    }
  }

  Widget _build(final BuildContext context, {required final bool hosted}) {
    final Widget sheet = Actions(
      actions: <Type, Action<Intent>>{
        // Only while open, so a closing sheet leaves Escape to the widgets above.
        if (!_closing) DismissIntent: _CloseSheetAction(_close),
      },
      child: _NonModalSheetFocus(scope: _focus, requestFocus: requestFocus, child: host.build(context)),
    );
    final ModalRoute<Object?>? route = this.route;
    if (route == null) {
      return sheet;
    }
    // Hidden, and out of reach, while another page is on top of the one that opened it. Drawn by
    // an entry of its own, which the navigator keeps above every page, it cannot sit under a
    // leaving page as a persistent bottom sheet does; it waits for that page to finish leaving
    // instead, where isCurrent alone shows it as soon as the pop starts. That entry is above any
    // dialog too, so it also hides while the page is not current. Drawn by its page, a popup
    // route is painted over it, so only a page on top hides it.
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[route.animation, route.secondaryAnimation]),
      builder: (final BuildContext context, final Widget? child) {
        if (!route.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((final Duration _) => closeNow());
        }
        final bool uncovered =
            (hosted ? route.isActive : route.isCurrent) && (route.secondaryAnimation?.isDismissed ?? true);
        return Visibility(visible: uncovered, maintainState: true, child: child!);
      },
      child: sheet,
    );
  }

  void _markNeedsBuild() {
    _entry?.markNeedsBuild();
    _pageHost?.rebuild();
  }

  /// Takes the sheet out of the tree, from its entry or its page.
  void _takeOut() {
    _live = false;
    final OverlayEntry? entry = _entry;
    _entry = null;
    if (entry != null) {
      try {
        entry.remove();
      } on Object {
        // The overlay is already going.
      }
    }
    _pageHost?.erase(this);
    _pageHost = null;
  }

  /// Takes the sheet's entry out of its page's history, when it closes some other way.
  void _leaveHistory() {
    final LocalHistoryEntry? history = _history;
    _history = null;
    final ModalRoute<Object?>? route = this.route;
    if (route != null) {
      _HarborPageSheets.of(route).remove(this);
    }
    if (history != null && route != null && route.isActive) {
      route.removeLocalHistoryEntry(history);
    }
  }

  bool _closing = false;

  void _leave() {
    if (_ownsAnimation) {
      _animation.dispose();
    }
    if (!_done.isCompleted) {
      _done.complete(null);
    }
    host.left();
  }

  /// Removes the sheet at once, with no animation: its page is leaving.
  void closeNow() {
    if (!_live) {
      return;
    }
    _closing = true;
    _leaveHistory();
    host.detach();
    _animation.stop();
    _takeOut();
    host.dispose();
    _disposeFocus();
    _leave();
  }

  // The sheet's scope may hold primary focus as its entry is removed. Disposed at once, while its
  // FocusScope is still mounted, focus stayed on the disposed node and keys reached nothing: with a
  // modal float under the sheet, Escape could no longer close the float. So focus is handed back
  // first, to the scope that had it before, as a route's leaving does, and the node is disposed
  // after the frame, once its widget has left the tree. Either alone passes the test in
  // modal_buoy_test.dart; both are kept, since a FocusNode must not be disposed while still
  // attached, focused or not.
  void _disposeFocus() {
    if (_focus.hasFocus) {
      _focus.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) => _focus.dispose());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _close([final T? result]) async {
    if (!_live || _closing) {
      return;
    }
    _closing = true;
    _markNeedsBuild();
    _leaveHistory();
    if (overlay.mounted) {
      await _animation.reverse();
    }
    // The page keeps clear of the sheet until it has slid away, as it does under a sheet that is a route.
    host.detach();
    _takeOut();
    host.dispose();
    _disposeFocus();
    // The result first: _leave completes with null when nothing has.
    if (!_done.isCompleted) {
      _done.complete(result);
    }
    _leave();
  }
}

/// Takes focus for a sheet with no barrier when it opens, if asked, as a drawer does: its scope
/// becomes the first focus of the navigator's, so a child with `autofocus: true` takes it from
/// there. When the sheet goes, the navigator's scope falls back to the page, and the page to what
/// it had focused.
class _NonModalSheetFocus extends StatefulWidget {
  const _NonModalSheetFocus({required this.scope, required this.requestFocus, required this.child});

  final FocusScopeNode scope;
  final bool requestFocus;
  final Widget child;

  @override
  State<_NonModalSheetFocus> createState() => _NonModalSheetFocusState();
}

class _NonModalSheetFocusState extends State<_NonModalSheetFocus> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened && widget.requestFocus) {
      FocusScope.of(context).setFirstFocus(widget.scope);
    }
    _opened = true;
  }

  @override
  Widget build(final BuildContext context) =>
      FocusScope.withExternalFocusNode(focusScopeNode: widget.scope, child: widget.child);
}

/// The sheets with no barrier open over a page, in the order they opened.
class _HarborPageSheets extends ChangeNotifier {
  static final Expando<_HarborPageSheets> _pages = Expando<_HarborPageSheets>('HarborPageSheets');

  static _HarborPageSheets of(final ModalRoute<Object?> route) => _pages[route] ??= _HarborPageSheets();

  final List<_NonModalSheet<Object?>> _open = <_NonModalSheet<Object?>>[];

  /// The page's route-level frame, which draws its sheets; null in a page with no frame.
  _HarborPageSheetHostState? host;

  _NonModalSheet<Object?>? get top => _open.isEmpty ? null : _open.last;

  void add(final _NonModalSheet<Object?> sheet) {
    _open.add(sheet);
    notifyListeners();
  }

  void remove(final _NonModalSheet<Object?> sheet) {
    if (!_open.remove(sheet)) {
      return;
    }
    // A sheet that leaves with its frame goes while the tree is being torn down, when the
    // frames listening cannot rebuild yet.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) => notifyListeners());
    } else {
      notifyListeners();
    }
  }
}

/// Escape (a [DismissIntent]) from anywhere in a frame closes the top sheet with no barrier
/// over its page, as back does. With none open it is left to the widgets above, as
/// `RawMenuAnchor` leaves it while its menu is closed: a page route answers Escape with an action
/// that is disabled, which would stop the search there.
class HarborNonModalSheetActions extends StatelessWidget {
  const HarborNonModalSheetActions({super.key, required this.route, required this.child});

  /// The page whose sheets this closes; with none, Escape passes through.
  final ModalRoute<Object?>? route;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final ModalRoute<Object?>? route = this.route;
    if (route == null) {
      return child;
    }
    final _HarborPageSheets sheets = _HarborPageSheets.of(route);
    return ListenableBuilder(
      listenable: sheets,
      builder: (final BuildContext context, final Widget? child) {
        final _NonModalSheet<Object?>? top = sheets.top;
        return Actions(
          actions: <Type, Action<Intent>>{if (top != null) DismissIntent: _CloseSheetAction(top._close)},
          child: child!,
        );
      },
      child: child,
    );
  }
}

class _CloseSheetAction extends DismissAction {
  _CloseSheetAction(this._close);

  final Future<void> Function() _close;

  @override
  void invoke(final DismissIntent intent) => unawaited(_close());
}

/// Closes the sheet [context] is in, whichever way it was opened.
@Deprecated('Use HarborSheet.close instead, which also takes a result. Deprecated after 0.2.0.')
void closeHarborSheet(final BuildContext context) => HarborSheet.close<Object?>(context);

/// Draws the sheets with no barrier that its page opened, through an [OverlayPortal], so they
/// paint just above the page and below every route pushed after it. Mounted by each page's
/// route-level frame, outermost, so a sheet sees what that frame sees: the root, and the
/// screen's `MediaQuery`, as it did from an overlay entry of its own.
@internal
class HarborPageSheetHost extends StatefulWidget {
  const HarborPageSheetHost({super.key, required this.route, required this.child});

  final ModalRoute<Object?> route;
  final Widget child;

  @override
  State<HarborPageSheetHost> createState() => _HarborPageSheetHostState();
}

class _HarborPageSheetHostState extends State<HarborPageSheetHost> {
  final OverlayPortalController _portal = OverlayPortalController(debugLabel: 'HarborSheet (no barrier)');
  final List<_NonModalSheet<Object?>> _drawn = <_NonModalSheet<Object?>>[];

  @override
  void initState() {
    super.initState();
    _HarborPageSheets.of(widget.route).host ??= this;
  }

  @override
  void didUpdateWidget(final HarborPageSheetHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.route, widget.route)) {
      _leave(oldWidget.route);
      _HarborPageSheets.of(widget.route).host ??= this;
    }
  }

  void _leave(final ModalRoute<Object?> route) {
    final _HarborPageSheets sheets = _HarborPageSheets.of(route);
    if (identical(sheets.host, this)) {
      sheets.host = null;
    }
  }

  @override
  void dispose() {
    _leave(widget.route);
    super.dispose();
  }

  void draw(final _NonModalSheet<Object?> sheet) {
    _drawn.add(sheet);
    _portal.show();
    rebuild();
  }

  void erase(final _NonModalSheet<Object?> sheet) {
    if (_drawn.remove(sheet)) {
      rebuild();
    }
  }

  void rebuild() {
    if (!mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) => rebuild());
      return;
    }
    setState(() {
      if (_drawn.isEmpty) {
        _portal.hide();
      }
    });
  }

  // The portal sits beside the page, not around it: wrapped around the page, it hid every
  // popover in the page from screen readers (measured: the popover's node left the semantics tree).
  // Where it sits in the page does not matter to its paint order, only which overlay entry it is
  // in. StackFit.passthrough hands the page its constraints unchanged.
  @override
  Widget build(final BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: <Widget>[
      widget.child,
      // Filling the page, though empty and passing every tap through: a portal's semantics are its
      // overlay child's, and Flutter drops them for a portal of no size, which hid the sheet from
      // screen readers.
      Positioned.fill(
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (final BuildContext context) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              for (final _NonModalSheet<Object?> sheet in _drawn)
                KeyedSubtree(key: ObjectKey(sheet), child: sheet.build(context, hosted: true)),
            ],
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ],
  );
}

/// Tells [onGone] when the sheet it wraps leaves the tree, whatever took it out.
class _SheetLifeline extends StatefulWidget {
  const _SheetLifeline({required this.onGone, required this.child});

  final VoidCallback onGone;
  final Widget child;

  @override
  State<_SheetLifeline> createState() => _SheetLifelineState();
}

class _SheetLifelineState extends State<_SheetLifeline> {
  @override
  void dispose() {
    widget.onGone();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}
