import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

/// Material's bottom sheet drag handle, ready to be a sheet's header: a rounded bar, 32 by 4 unless
/// the theme says otherwise, centred in a 48-high band that is as wide as the sheet.
///
/// As Material's, it is a button for screen readers, announced with `modalBarrierDismissLabel`,
/// that closes the sheet it is in ([HarborSheet.close]). In a draggable sheet, a header is the
/// sheet's handle, so dragging it drags the sheet.
class HarborMaterialDragHandle extends StatelessWidget {
  const HarborMaterialDragHandle({super.key, this.color, this.size});

  /// The handle's colour: the theme's `bottomSheetTheme.dragHandleColor` when null, then Material
  /// 3's `onSurfaceVariant`.
  final Color? color;

  /// The handle's size: the theme's `bottomSheetTheme.dragHandleSize` when null, then 32 by 4.
  final Size? size;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BottomSheetThemeData sheets = theme.bottomSheetTheme;
    final Size size = this.size ?? sheets.dragHandleSize ?? const Size(32, 4);
    final Color color =
        this.color ??
        WidgetStateProperty.resolveAs<Color?>(sheets.dragHandleColor, <WidgetState>{}) ??
        theme.colorScheme.onSurfaceVariant;
    return SizedBox(
      height: math.max(size.height, kMinInteractiveDimension),
      child: Center(
        child: Semantics(
          label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          container: true,
          button: true,
          onTap: () => HarborSheet.close(context),
          child: SizedBox(
            width: math.max(size.width, kMinInteractiveDimension),
            height: math.max(size.height, kMinInteractiveDimension),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size.height / 2)),
                child: SizedBox.fromSize(size: size),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A modal bottom sheet's surface, for [HarborSheet.surface]: a `Material` in the sheet's colour,
/// elevation and shape.
///
/// Each comes from its argument, then the theme's `bottomSheetTheme` (its `modal…` value first, as
/// a modal bottom sheet reads it), then Material's defaults: in Material 3 `surfaceContainerLow`,
/// elevation 1 and a top rounded by 28; in Material 2 the canvas colour, elevation 0 and no shape.
/// [HarborMaterialSheet] puts it under a sheet with the same shape clipping the content.
class HarborMaterialSheetSurface extends StatelessWidget {
  const HarborMaterialSheetSurface({super.key, this.color, this.elevation, this.shape});

  /// As `showModalBottomSheet(backgroundColor:)`.
  final Color? color;

  /// As `showModalBottomSheet(elevation:)`.
  final double? elevation;

  /// As `showModalBottomSheet(shape:)`.
  final ShapeBorder? shape;

  /// The shape a sheet's surface takes in `context`: [shape] if given, then the theme's, then
  /// Material 3's rounded top. Null in Material 2 with no theme shape.
  static ShapeBorder? shapeOf(final BuildContext context, [final ShapeBorder? shape]) {
    final ThemeData theme = Theme.of(context);
    return shape ??
        theme.bottomSheetTheme.shape ??
        (theme.useMaterial3
            ? const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))
            : null);
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BottomSheetThemeData sheets = theme.bottomSheetTheme;
    final bool m3 = theme.useMaterial3;
    return Material(
      color:
          color ??
          sheets.modalBackgroundColor ??
          sheets.backgroundColor ??
          (m3 ? theme.colorScheme.surfaceContainerLow : theme.canvasColor),
      elevation: elevation ?? sheets.modalElevation ?? sheets.elevation ?? (m3 ? 1.0 : 0.0),
      surfaceTintColor: sheets.surfaceTintColor ?? (m3 ? Colors.transparent : null),
      shadowColor: sheets.shadowColor ?? (m3 ? Colors.transparent : null),
      shape: shapeOf(context, shape),
    );
  }
}

/// A [HarborSheet] in a Material bottom sheet's look: the sheet `showModalBottomSheet` would have
/// drawn, for `showHarborSheet`'s builder.
///
/// It gives the sheet a [HarborMaterialSheetSurface], clips the content to the surface's shape (so a
/// photo at the top keeps the corners, and the surface's shadow is not clipped with it), puts the
/// content in a transparent `Material` so text fields and ink work, and, with [showDragHandle],
/// puts a [HarborMaterialDragHandle] at the top: alone, in a solid bar the body starts below, as
/// Material pads a sheet's content below its handle; with a [header] or [headerBar], above it in
/// that bar. [enableDrag] closes it on a drag down, as
/// `showModalBottomSheet(enableDrag:)` does. Every other argument is [HarborSheet]'s.
///
/// ```dart
/// showHarborSheet(
///   context,
///   semanticLabel: HarborMaterialSheet.semanticLabelOf(context),
///   builder: (_) => HarborMaterialSheet(showDragHandle: true, footer: actions, body: form),
/// );
/// ```
class HarborMaterialSheet extends StatelessWidget {
  /// A sheet as tall as its content, up to [maxExtentFraction]: [HarborSheet.new].
  const HarborMaterialSheet({
    super.key,
    this.header,
    this.footer,
    this.headerBar,
    this.footerBar,
    required Widget this.body,
    this.showDragHandle,
    this.enableDrag = true,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.maxExtentFraction = 0.9,
    this.closeFlingVelocity = 700.0,
    this.clearsTopSystemEdge = true,
    this.clearsSides = false,
    this.bodyClearsKeyboard = true,
    this.debugLabel,
  }) : builder = null,
       extent = null,
       controller = null;

  /// A sheet whose content is a list: [HarborSheet.draggable]. It closes at its floor, so it has no
  /// [enableDrag]; its header, the drag handle included, drags it.
  const HarborMaterialSheet.draggable({
    super.key,
    this.header,
    this.footer,
    this.headerBar,
    this.footerBar,
    required ScrollableWidgetBuilder this.builder,
    this.extent = const HarborSheetExtent(),
    this.controller,
    this.showDragHandle,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.closeFlingVelocity = 700.0,
    this.clearsTopSystemEdge = true,
    this.clearsSides = false,
    this.bodyClearsKeyboard = true,
    this.debugLabel,
  }) : body = null,
       enableDrag = false,
       maxExtentFraction = 0.9;

  /// The label `showModalBottomSheet` gives its sheet, for `showHarborSheet(semanticLabel:)`:
  /// `MaterialLocalizations.dialogLabel`, except on iOS and macOS, where Material leaves a sheet
  /// unnamed. Read from `defaultTargetPlatform`, as Material reads it.
  static String? semanticLabelOf(final BuildContext context) => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => null,
    _ => MaterialLocalizations.of(context).dialogLabel,
  };

  /// See [HarborSheet.header]. Below the drag handle, when there is one.
  final Widget? header;

  /// See [HarborSheet.footer].
  final Widget? footer;

  /// See [HarborSheet.headerBar]. The drag handle goes above its child.
  final HarborBar? headerBar;

  /// See [HarborSheet.footerBar].
  final HarborBar? footerBar;

  /// See [HarborSheet.body].
  final Widget? body;

  /// See [HarborSheet.builder].
  final ScrollableWidgetBuilder? builder;

  /// See [HarborSheet.extent].
  final HarborSheetExtent? extent;

  /// See [HarborSheet.controller].
  final DraggableScrollableController? controller;

  /// Whether a [HarborMaterialDragHandle] tops the sheet. Null follows the theme's
  /// `bottomSheetTheme.showDragHandle` where the sheet can be dragged, as Material does.
  final bool? showDragHandle;

  /// Whether a drag down closes the sheet: [HarborSheet.dragToClose]. On by default, as
  /// `showModalBottomSheet(enableDrag:)` is.
  final bool enableDrag;

  /// See [HarborMaterialSheetSurface.color].
  final Color? backgroundColor;

  /// See [HarborMaterialSheetSurface.elevation].
  final double? elevation;

  /// See [HarborMaterialSheetSurface.shape]. The content is clipped to it too.
  final ShapeBorder? shape;

  /// See [HarborSheet.maxExtentFraction].
  final double maxExtentFraction;

  /// See [HarborSheet.closeFlingVelocity].
  final double closeFlingVelocity;

  /// See [HarborSheet.clearsTopSystemEdge].
  final bool clearsTopSystemEdge;

  /// See [HarborSheet.clearsSides].
  final bool clearsSides;

  /// See [HarborSheet.bodyClearsKeyboard].
  final bool bodyClearsKeyboard;

  /// See [HarborSheet.debugLabel].
  final String? debugLabel;

  @override
  Widget build(final BuildContext context) {
    final bool draggable = builder != null;
    final bool handle =
        showDragHandle ?? ((draggable || enableDrag) && (Theme.of(context).bottomSheetTheme.showDragHandle ?? false));
    final ShapeBorder? clip = HarborMaterialSheetSurface.shapeOf(context, shape);

    Widget? header = this.header;
    HarborBar? headerBar = this.headerBar;
    if (handle) {
      if (headerBar != null) {
        headerBar = headerBar.copyWith(child: _withHandle(headerBar.child));
      } else if (header != null) {
        header = _withHandle(header);
      } else {
        // A handle alone stops the body, as Material pads a sheet's content below its handle; a
        // header's bar, which the body runs under, would leave a plain body under the handle.
        headerBar = const HarborBar.solid(debugLabel: 'drag handle', child: HarborMaterialDragHandle());
      }
    }

    final Widget surface = HarborMaterialSheetSurface(color: backgroundColor, elevation: elevation, shape: shape);
    // Over the surface: ink paints on this transparent Material, and the content is clipped to the
    // surface's shape here rather than by HarborSheet.clip, which would clip the surface's shadow too.
    Widget content(final BuildContext context, final Widget? content) => Material(
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      shape: clip,
      clipBehavior: clip == null ? Clip.none : Clip.antiAlias,
      child: content,
    );

    return draggable
        ? HarborSheet.draggable(
            header: header,
            footer: footer,
            headerBar: headerBar,
            footerBar: footerBar,
            builder: builder!,
            extent: extent!,
            controller: controller,
            surface: surface,
            contentBuilder: content,
            closeFlingVelocity: closeFlingVelocity,
            clearsTopSystemEdge: clearsTopSystemEdge,
            clearsSides: clearsSides,
            bodyClearsKeyboard: bodyClearsKeyboard,
            debugLabel: debugLabel,
          )
        : HarborSheet(
            header: header,
            footer: footer,
            headerBar: headerBar,
            footerBar: footerBar,
            body: body!,
            surface: surface,
            contentBuilder: content,
            dragToClose: enableDrag,
            maxExtentFraction: maxExtentFraction,
            closeFlingVelocity: closeFlingVelocity,
            clearsTopSystemEdge: clearsTopSystemEdge,
            clearsSides: clearsSides,
            bodyClearsKeyboard: bodyClearsKeyboard,
            debugLabel: debugLabel,
          );
  }

  static Widget _withHandle(final Widget child) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[const HarborMaterialDragHandle(), child],
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('draggable', value: builder != null, ifTrue: 'draggable'));
    properties.add(DiagnosticsProperty<bool>('showDragHandle', showDragHandle, defaultValue: null));
    properties.add(FlagProperty('enableDrag', value: enableDrag, ifFalse: 'no drag to close'));
    properties.add(ColorProperty('backgroundColor', backgroundColor, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}
