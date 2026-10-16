## 0.1.0

The first release: the Material pieces apps wrote by hand around harbor, in a package of their own so
harbor's core stays free of a design library. Needs harbor 1.0.1, whose AppBar status-bar fix the bar helper relies on.

* `HarborMaterialFrame`: a `HarborFrame` on a `Material` in the theme's `scaffoldBackgroundColor`, with
  a `ScrollNotificationObserver`, and an `appBar:` that goes first in `top` as a solid bar. A one-for-one
  stand-in for `Scaffold`.
* `HarborMaterialBar.appBar`: an `AppBar` (or any `PreferredSizeWidget`) in a bar, with the
  `AppBar`'s own surface run up behind the status bar by `HarborMaterialAppBarSurface`, resolved by the
  `AppBar`'s rules in Material 2 and 3 and following it when content scrolls under.
* `HarborMaterialDefaults.of`: `HarborDefaults` from `MaterialLocalizations` and the theme, for
  `HarborRoot(defaults:)` in `MaterialApp.builder`.
* `HarborSnackToast` and `context.showSnackToast`: a toast in a `SnackBar`'s look, with an optional
  action.
* `HarborMaterialSheet` (and `.draggable`), `HarborMaterialSheetSurface` and `HarborMaterialDragHandle`:
  a `HarborSheet` in a modal bottom sheet's look, with `showDragHandle:`, `enableDrag:`,
  `backgroundColor:`, `elevation:` and `shape:`.
