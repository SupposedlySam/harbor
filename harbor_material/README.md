# harbor_material

Material for [harbor](https://pub.dev/packages/harbor): the pieces a Material app writes by hand
around harbor's widgets, written once.

harbor sits on Flutter's widgets layer and imports no design library, so a Material app passes
Material's pieces in: a page colour, an app bar's colour behind the status bar, the words a screen
reader says for a barrier, a sheet's surface and drag handle, a snack bar's look. Every app that
adopted harbor wrote the same lines for them. This package is those lines.

```sh
flutter pub add harbor harbor_material
```

It builds on Flutter's own Material library, `package:flutter/material.dart`, and adds no
dependency beyond harbor.

## Before and after

A page in plain Material:

```dart
MaterialApp(
  home: Scaffold(
    appBar: AppBar(title: const Text('Inbox')),
    body: ListView(children: messages),
    bottomNavigationBar: NavigationBar(destinations: destinations),
    floatingActionButton: FloatingActionButton(onPressed: compose, child: const Icon(Icons.edit)),
  ),
);

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: const Text('Archived'), action: SnackBarAction(label: 'Undo', onPressed: restore)),
);
showModalBottomSheet(context: context, showDragHandle: true, elevation: 2, builder: (_) => const ReplyForm());
```

The same page on harbor, with harbor_material:

```dart
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';

MaterialApp(
  builder: (context, child) => HarborRoot(defaults: HarborMaterialDefaults.of(context), child: child!),
  home: HarborMaterialFrame(
    appBar: AppBar(title: const Text('Inbox')),
    bottom: [HarborBar.solid(child: NavigationBar(destinations: destinations))],
    floats: [
      HarborFloat(
        placement: const HarborAligned(alignment: AlignmentDirectional.bottomEnd),
        child: FloatingActionButton(onPressed: compose, child: const Icon(Icons.edit)),
      ),
    ],
    body: HarborScrollView(slivers: [SliverList.list(children: messages)]),
  ),
);

context.showSnackToast(const Text('Archived'), actionLabel: 'Undo', onAction: restore);
showHarborSheet(
  context,
  semanticLabel: HarborMaterialSheet.semanticLabelOf(context),
  builder: (_) => const HarborMaterialSheet(showDragHandle: true, elevation: 2, body: ReplyForm()),
);
```

A snack toast's content spans the toast's width, so it aligns itself: give a `Text` its own `textAlign`, as a
`SnackBar`'s content does.

It looks the same. What harbor changes is where things sit: the list rests clear of the app bar and
the navigation bar, a form in the sheet keeps above the keyboard and the home indicator, the toast
keeps clear of the navigation bar and the keyboard, and nothing pads by hand. The
[harbor README](https://pub.dev/packages/harbor) is the whole model.

## What is in it

| harbor_material | Stands in for | What it does |
|---|---|---|
| `HarborMaterialFrame` | `Scaffold` | A `HarborFrame` on a `Material` in the theme's `scaffoldBackgroundColor`, with a `ScrollNotificationObserver` so an `AppBar` hears content scroll under it. `appBar:` goes first in `top`, as a solid bar. Every other argument is `HarborFrame`'s |
| `HarborMaterialBar.appBar(appBar)` | `Scaffold.appBar` | A `HarborBar` holding the app bar, with a backdrop that is the `AppBar`'s own surface run up behind the status bar: its colour, elevation tint and shape, from the `AppBar`, its theme and Material's defaults (Material 2's primary, Material 3's surface), changing with it when content scrolls under (Material 3's `scrolledUnderElevation`). `kind: HarborBarKind.overlay` runs the body under it, as `extendBodyBehindAppBar` does |
| `HarborMaterialDefaults.of(context)` | What `showModalBottomSheet` fills in for itself | `HarborDefaults` from Material: the barrier label (`modalBarrierDismissLabel`), the sheet barrier's tap hint (`scrimOnTapHint(bottomSheetLabel)`) and the sheet's widest (the theme's, or Material 3's 640). `.merge(...)` adds your own |
| `HarborSnackToast`, `context.showSnackToast(...)` | `SnackBar`, `ScaffoldMessenger.showSnackBar` | A harbor toast in a snack bar's look: its colours, text style, shape and elevation, from `SnackBarThemeData` and Material's defaults, with an optional action that hides it. With an action it stays until hidden, as a `SnackBar` with an action does |
| `HarborMaterialSheet`, `.draggable` | `showModalBottomSheet`'s sheet | A `HarborSheet` with Material's surface, its content clipped to the surface's shape, a transparent `Material` for text fields and ink, `showDragHandle:` and `enableDrag:`. `HarborMaterialSheet.semanticLabelOf(context)` is the label Material gives a sheet |
| `HarborMaterialSheetSurface` | `showModalBottomSheet(backgroundColor:, elevation:, shape:)` | The surface alone, for a `HarborSheet` of your own: `bottomSheetTheme`'s modal values, then Material's |
| `HarborMaterialDragHandle` | `showModalBottomSheet(showDragHandle: true)` | Material's 32 by 4 handle in a 48-high band, a button for screen readers that closes the sheet |

## Notes

- **A `SnackBar` left behind stops appearing.** `ScaffoldMessenger.showSnackBar` and
  `showMaterialBanner` present into a `Scaffold`. Once a page is a `HarborMaterialFrame` and no
  `Scaffold` is on screen, they assert in debug ("no descendant Scaffolds to present to") and show
  nothing in release. Move every snack bar on that page to `context.showSnackToast(...)` in the
  same change, or keep the `Scaffold` there until you do.
- **The status bar's icons.** An `AppBar`'s `systemOverlayStyle` sets the status bar from a harbor
  bar as it does from a `Scaffold`: harbor carries a bar's child's style over the system edge the
  bar pads (harbor's CHANGELOG has the measurement).
- **A translucent `AppBar`** is painted twice over its toolbar, by the backdrop and by the
  `AppBar`. For a frosted header, give a `HarborBar` a `backdrop:` of your own.
- **The sheet's barrier.** `HarborMaterialDefaults.of` gives the barrier Material's words; its
  colour stays harbor's, `showGeneralDialog`'s half-black, where `showModalBottomSheet`'s is
  `Colors.black54` or the theme's `bottomSheetTheme.modalBarrierColor`. Pass `barrier: HarborBarrier.dimmed(color:)` to
  `showHarborSheet` for another.
- **A snack toast's action** sits beside the message; a long one does not wrap below it as a
  `SnackBar`'s does.
- **`material_ui`.** Flutter 3.47 publishes Material as a package of its own too, `material_ui`.
  Its `Theme` and `ThemeData` are not the SDK's, so an app built on it reads no theme through this
  package. harbor_material follows the SDK's `package:flutter/material.dart`, which harbor's
  consumers use today, and will move to `material_ui` with them.

## Testing

The package's tests run on `harbor_test`'s trial devices. To test your own pages the same way,
`flutter pub add dev:harbor_test`.
