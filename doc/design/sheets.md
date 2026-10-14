# Sheets: one barrier, docks for the header and footer

Status: implemented on 2026-10-14, as decided in `DECISIONS.md` (Q15-Q18) and in the 0.9 names:
`headerDock:` is `headerBar:`, the buoy is `HarborFloat`, and the breakwater is `coversPage:`.
[As shipped](#as-shipped) at the end lists where the code departs from this proposal. The proposal
below is kept as written. Its line numbers are against `987db9c`.

## The problem, measured

`showHarborSheet` takes 21 parameters (sheet.dart:736-757), `HarborSheet` 17 (:99-118) and
`HarborSheet.draggable` 18 (:132-150), not counting `key`. Two groups make up most of the
confusion.

**The barrier is five parameters that disagree with each other.**

- `barrier: HarborSheetBarrier` (:576-590) has the values `dismissible`, `clear` and `none`.
  `dismissible` means *dimmed*. Dismissal is a separate flag, `isDismissible` (:740), which
  also applies to `clear` (:799). So `barrier: HarborSheetBarrier.dismissible, isDismissible: false`
  compiles, and it gives a barrier that cannot be dismissed.
- `barrierColor` (:741) is read only for `dismissible` (:798). With `clear` it is replaced by
  transparent, and with `none` it is dropped, along with `isDismissible`, `barrierLabel` and
  `barrierOnTapHint`. The `none` branch (:778-791) passes none of them on, and nothing warns.
- The same idea has three spellings. A sheet uses `isDismissible`, a dialog uses
  `barrierDismissible` (dialog.dart:47, :113), and a modal buoy has no switch, only a required
  `onDismiss` (buoy.dart:308, :336).
- `barrierOnTapHint` exists on sheets only. The sheet route builds its own barrier to carry it
  (sheet.dart:1232-1250). The dialog and the buoy's `ModalBarrier` (buoy.dart:533) never get one.
- The defaults are copied by hand. Half-black `0x80000000` appears at sheet.dart:741 and at
  dialog.dart:46 and :112. Clear appears at buoy.dart:303 and :332 and at sheet.dart:798.

**The header and footer are docks with four of their options copied onto the sheet.**
`_harbor` (sheet.dart:307-328) wraps `header` in `HarborDock.pier(wake: headerWake)` and `footer`
in `HarborDock.quay(tide: footerTide, wake: footerWake, minimum: footerMinimum)`. Those four
fields (:174-177) are declared on both constructors. Every other dock option (`state`,
`withdrawsAtHighTide`, `backdrop`, `coast`, `animationStyle`, `hitTestBehavior`) cannot be set
at all, so a sheet's footer cannot withdraw while the keyboard is up, as a page's tool strip
can. In the repo, `shipyard.dart:713-731` sets four of these copied parameters on one sheet.

**Two top-coast switches whose names don't say how they differ.** `showHarborSheet(keepsTopCoast:)`
(:747) decides how tall the sheet may be: with it set, the sheet reaches the top of the screen
and keeps the status bar in its padding (:1025-1043). `HarborSheet(clearsTopCoast:)` (:233)
decides whether the content pads for that status bar. "Keeps" reads as "keeps clear", which
is the opposite of what it does. `fillsScreenAtHinge` also turns `keepsTopCoast` on silently
(:1025).

**`breakwater: bool` and `HarborBreakwater`.** The flag (:739) makes the sheet call
`HarborController.addBreakwaterEdge` (controller.dart:796) when it is attached (sheet.dart:958).
`HarborBreakwater` (controller.dart:46-66) is the handle that call returns. It is exported, but
outside the controller nothing reads its `coverage`, `topInGlobal` or `measuresTop`. The only
user is `render_harbor.dart:388`, and it goes through the controller.

**Reach.** All of this is public and used: `barrier: HarborSheetBarrier.none` at
open_sea.dart:145, shipyard.dart:318 and demos.dart:1108; the field guide's barrier picker
(entries_floating.dart:1294-1358); and the footer options in shipyard.dart and
entries_floating.dart:1074.

## 1. `HarborBarrier`

```dart
/// What an overlay puts between itself and the page: how it looks, whether a tap on it
/// dismisses, and what a screen reader says about it. Shared by sheets, dialogs and modal buoys.
@immutable
sealed class HarborBarrier with Diagnosticable {
  /// showGeneralDialog's half-black.
  static const Color defaultColor = Color(0x80000000);

  /// A tinted barrier (the default for sheets and dialogs).
  const factory HarborBarrier.dimmed({Color color, bool dismissible, String? label, String? onTapHint}) = _Barrier.dimmed;

  /// A barrier you can see through: the page shows as it is, but takes no taps
  /// (the default for a modal buoy).
  const factory HarborBarrier.clear({bool dismissible, String? label, String? onTapHint}) = _Barrier.clear;

  /// No barrier. On a sheet, the sheet is not a route and the page stays live (showBottomSheet).
  /// A dialog cannot take it (asserted). On a buoy, the buoy is not modal.
  static const HarborBarrier none = _Barrier.none();

  /// Its colour; transparent for clear and none.
  Color get color;
  /// Whether a tap on it closes the overlay. Back closes the overlay either way. Defaults to true.
  bool get dismissible;
  /// What a screen reader announces for it; null announces harborBarrierDismissLabel ('Dismiss').
  String? get label;
  /// What tapping it does, read as 'Double tap to …'.
  String? get onTapHint;
  /// False only for [none].
  bool get blocks;
}
```

Its subclasses get `==` and `hashCode`. It replaces these parameters:

| Host | Today | Proposed |
|---|---|---|
| `showHarborSheet` | `barrier`, `isDismissible`, `barrierColor`, `barrierLabel`, `barrierOnTapHint` | `HarborBarrier barrier = const HarborBarrier.dimmed()` |
| `showHarborDialog`, `HarborDialogRoute` | `barrierColor`, `barrierDismissible`, `barrierLabel` | `HarborBarrier barrier = const HarborBarrier.dimmed()` |
| `HarborBuoy` | `modal`, `barrierColor`, `barrierLabel` | `HarborBarrier barrier = HarborBarrier.none`; `bool get modal => barrier.blocks` |

The buoy loses a separate `modal` flag because a modal buoy is a buoy with a barrier. "Modal"
also covers the focus trap and hiding the buoys listed before it, and `barrier.blocks` turns
both on, so nothing changes in behaviour. On a buoy, `dismissible: false` is new: a tap does
nothing, and back and Escape still call `onDismiss`. That matches what `isDismissible: false`
already means on a sheet. Its `onTapHint` goes to `ModalBarrier.semanticsOnTapHint`. The dialog
route needs the `buildModalBarrier` override the sheet route already has (sheet.dart:1232) to
pass its hint on.

"Barrier", "dimmed" and "clear" are plain words, so the type has no nautical name.

## 2. Header and footer as docks

```dart
const HarborSheet({
  Widget? header,          // unchanged shorthand: wrapped in the sheet's default header dock
  Widget? footer,          // unchanged shorthand: wrapped in the sheet's default footer dock
  HarborDock? headerDock,  // the whole dock; excludes header (asserted). A top dock, any kind.
  HarborDock? footerDock,  // the whole dock; excludes footer (asserted).
  required Widget body,
  // ... surface, maxExtentFraction, debugLabel, contentBuilder, clip, dragToClose,
  //     closeFlingVelocity, clearsTopCoast, clearsSides, bodyClearsTide: unchanged
});

/// The dock a plain `header:` gets: a pier with a 12-long fade.
static HarborDock defaultHeaderDock(Widget child) =>
    HarborDock.pier(wake: const HarborWake.fade(length: 12), debugLabel: 'sheet header', child: child);

/// The dock a plain `footer:` gets: a quay that floats on the tide, with a hairline and 16 off the edge.
static HarborDock defaultFooterDock(Widget child) => HarborDock.quay(tide: HarborTideStance.float,
    wake: const HarborWake.hairline(), minimum: 16, debugLabel: 'sheet footer', child: child);
```

`HarborSheet.draggable` changes the same way. Its drag handle wraps the dock's child through
`HarborDock.copyWith(child:)` (dock.dart:241), so any header dock still drags the sheet.
`headerWake`, `footerWake`, `footerMinimum` and `footerTide` are deprecated. The sheet goes from
17 parameters to 15, and every dock option is now open to the header and footer.

The `slot:`/`placement:` pairing in placement.md keeps a short form beside the full one, and
this does the same. The plain-widget form is how most sheets are written (README:667).
`header` cannot simply change type to `HarborDock?`: a parameter that keeps its name and changes
type cannot be deprecated first.

## 3. The frame options: renamed, not grouped

`maxWidth`, `keepsTopCoast`, `anchorPoint`, `hinge` and `fillsScreenAtHinge` all decide the
rectangle the sheet may use. They still don't belong in one value. `maxWidth` and `anchorPoint`
have the same names and meanings on `showModalBottomSheet` and `showDialog`, and that is how
README:913-920 can show a Material app passing its pieces straight in. `hinge` is the shared
inherited policy (hinge.dart). A group would be a harbor-only container around options that
don't depend on each other. What the group needs is clearer names:

```dart
Future<T?> showHarborSheet<T>(BuildContext context, {
  required WidgetBuilder builder,
  HarborBarrier barrier = const HarborBarrier.dimmed(),
  bool breakwater = false,
  bool reachesTop = false,          // was keepsTopCoast
  double? maxWidth, Offset? anchorPoint, HarborHinge? hinge, bool fillsScreenAtHinge = false,
  bool useRootNavigator = false, bool? requestFocus, RouteSettings? routeSettings,
  String? semanticLabel, AnimationStyle? sheetAnimationStyle,
  HarborSheetController? controller, AnimationController? transitionAnimationController,
});
```

That is 16 parameters, down from 21. The doc for `reachesTop` would read: "The sheet may reach
the top of the screen, and its content is handed the status bar to clear. Implied by
`fillsScreenAtHinge` on a split screen." On the widget, `clearsTopCoast` stays. It is the one
switch about content padding for the coast, and it matches `clearsSides` and
`HarborClear.coast`. So the opener decides how high the sheet reaches, and the sheet decides
whether its content pads for the status bar.

## 4. The breakwater

Keep `breakwater: bool`. It is a glossary word for a real harbor idea, and the flag says
"this sheet is one". `HarborBreakwater` stays the handle that `addBreakwater` and
`addBreakwaterEdge` return, documented as "remove() it when the cover leaves".
`coverage`, `topInGlobal` and `measuresTop` become private. Nothing outside the controller
reads them, and nothing outside it can construct the type (its constructor is private), so the
only public surface that matters is `remove()`.

## Before and after

```dart
// README:673 and demos.dart:1108
showHarborSheet(context, breakwater: true, barrier: HarborSheetBarrier.none, builder: ...);
showHarborSheet(context, breakwater: true, barrier: HarborBarrier.none, builder: ...);

// README:913-917: a Material app's labels
showHarborSheet(context,
  barrierLabel: l.modalBarrierDismissLabel,
  barrierOnTapHint: l.scrimOnTapHint(l.bottomSheetLabel), ...);
showHarborSheet(context,
  barrier: HarborBarrier.dimmed(label: l.modalBarrierDismissLabel, onTapHint: l.scrimOnTapHint(l.bottomSheetLabel)), ...);

// shipyard.dart:713-731: the paint shop's dry-dock footer
HarborSheet(headerWake: HarborWake.none, header: tabs,
  footerTide: HarborTideStance.dryDock, footerMinimum: 0, footerWake: HarborWake.none,
  footer: HarborDryDock(child: tray), body: deck);
HarborSheet(headerDock: HarborDock.pier(child: tabs),
  footerDock: HarborDock.quay(tide: HarborTideStance.dryDock, child: HarborDryDock(child: tray)),
  body: deck);

// README:480: quick actions
HarborBuoy(modal: true, onDismiss: closeQuickActions, child: quickActions);
HarborBuoy(barrier: const HarborBarrier.clear(), onDismiss: closeQuickActions, child: quickActions);
```

In the shipyard call, the "after" version uses the dock defaults (no wake, minimum 0) instead of
writing out three overrides.

## Migration

**0.x release with deprecations (non-breaking):**

- `HarborSheetBarrier` moves to `barrier.dart`, is deprecated, and becomes an enum that
  **implements** the sealed `HarborBarrier` in the same library: `dismissible` → dimmed,
  `clear` → clear, `none` → none. Because of that, `barrier: HarborSheetBarrier.none` still
  compiles against the new `HarborBarrier barrier` parameter with nothing else changed.
- `isDismissible`, `barrierColor`, `barrierLabel` and `barrierOnTapHint` on `showHarborSheet`, and
  `barrierColor`, `barrierDismissible` and `barrierLabel` on the dialog, are deprecated. When given,
  they override the matching field of `barrier` in the body. With `none`, giving them asserts,
  where today they are silently dropped.
- `HarborBuoy(modal:, barrierColor:, barrierLabel:)` are deprecated. `barrier` becomes a getter
  that falls back to `HarborBarrier.clear(color: barrierColor, label: barrierLabel)` when
  `modal` is set, since a const constructor cannot build it in the initializer list, as in
  placement.md. Giving both forms asserts.
- `headerWake`, `footerWake`, `footerMinimum` and `footerTide` are deprecated and still honoured
  for the plain `header:`/`footer:`. With `headerDock:`/`footerDock:`, giving them asserts.
- `keepsTopCoast` is deprecated in favour of `reachesTop`, and giving both asserts.
- The public getters on `HarborBreakwater` are deprecated.

**`lib/fix_data/sheets.yaml` can automate:**

- `keepsTopCoast:` → `reachesTop:` (`renameParameter`).
- One-argument barrier calls, using `changeParameters` with an `argumentValue` template over
  `arguments[...]`: sheet `barrierLabel: L` → `barrier: HarborBarrier.dimmed(label: L)`, sheet
  `isDismissible: false` → `barrier: HarborBarrier.dimmed(dismissible: false)`, and dialog
  `barrierDismissible: X` / `barrierColor: C` the same way.
- `HarborSheetBarrier.none` → `HarborBarrier.none`.
- Each transform gets a `test_fixes/` case, as placement.md proposes for the gate.

**Manual:**

- Calls that set two or more barrier arguments. Each combination is its own template, so
  README:913-917 is a hand edit.
- `HarborBuoy(modal: true)`. fix_data matches on whether an argument is present, not on its
  value, so it cannot tell `modal: true` from `modal: someBool`.
- Header and footer knobs to docks. Folding three arguments into a dock with the right
  defaults has too many shapes to template. There are three call sites in example/ (office.dart:754,
  shipyard.dart:713-731, entries_floating.dart:1074).
- The field guide's barrier picker (entries_floating.dart:1294-1358) uses
  `HarborSheetBarrier.values` and `.name`. It needs a hand-written list.

**1.0:** remove the deprecated parameters, the enum and the `HarborBreakwater` getters.

## Open questions

1. **Does `HarborBarrier.none` belong on a dialog?** A dialog is always a route with a barrier,
   so a shared type gives it one value it cannot take.
   *Recommendation: accept the assert. A separate `HarborDialogBarrier` without `none` would
   bring back the duplication this proposal removes.*
2. **Should `HarborBuoy` keep `modal: bool` as sugar for `barrier: HarborBarrier.clear()`?**
   `modal: true` is short, and it is the README's own example.
   *Recommendation: no. Two switches for one thing is how the sheet ended up with
   `barrier` + `isDismissible`. Keep `bool get modal`.*
3. **Should the plain `header:`/`footer:` keep the special defaults (12-long fade; float,
   hairline, 16)?** They differ from `HarborDock`'s, which surprises anyone moving from the
   shorthand to `headerDock:`.
   *Recommendation: keep them. They are what a sheet should look like. Expose them as
   `HarborSheet.defaultHeaderDock`/`defaultFooterDock` so the move can start from them.*
4. **Should `reachesTop` and `fillsScreenAtHinge` be one enum** (`HarborSheetReach.belowStatusBar`
   / `.top` / `.screenAtHinge`)? Today one silently implies the other.
   *Recommendation: not yet. They can both be set (reach the top and fill a split screen), so an
   enum would need a fourth value. Document the implication instead.*

## As shipped

Where the implementation (after 0.9.0) departs from the proposal, and why:

- **The getter is `isDismissible`, not `dismissible`.** The deprecated `HarborSheetBarrier`
  implements `HarborBarrier`, so `barrier: HarborSheetBarrier.none` keeps compiling. Its value
  `dismissible` would collide with an instance getter of that name. The constructors still take
  `dismissible:`, as decided.
- **A modal float with a `barrierColor` reads as `HarborBarrier.dimmed(color:)`.** The proposal's
  fallback, `HarborBarrier.clear(color: barrierColor, ...)`, does not exist, since a clear barrier
  has no colour. A transparent `barrierColor`, the old default, reads as `HarborBarrier.clear()`.
- **`HarborDialogRoute(barrierColor:)` keeps its old default.** It takes a `Color?`, and null meant
  a barrier with no colour, so null still gives a clear barrier.
- **`dart fix` covers more of the barrier than the proposal planned, and less of the bars**
  (`tool/fix_data/sheets.dart`, `test_fixes/sheets.dart`):
  - Every combination of a call's loose barrier arguments is a generated branch, not only one
    argument at a time, beside the literal `HarborSheetBarrier` values or none. An argument that
    did nothing (a colour with a clear barrier, anything with no barrier) is dropped rather than
    carried into a value where it would assert.
  - `HarborFloat(modal: true)` and `modal: false` are fixed. fix_data compares an argument's text,
    so the literals are told apart from a variable, which is left alone.
  - `HarborSheetBarrier.none` on its own is **not** fixed. A `replacedBy` rewrites it wherever it is
    written, and a variable typed `HarborSheetBarrier` then fails to compile. Found by running it on
    the example's field guide. Inside a call that a loose argument already rewrites, it is.
  - The header and footer knobs are **not** fixed, as the proposal said. The specific reason: the
    template puts the header in a bar's non-nullable `child:`, and `footer: done ? actions : null`
    is nullable. The first version of the fix broke the field guide this way.
  - `HarborDialogRoute(barrierColor:)` is not fixed (above).
- **`HarborPageCover`'s getters are deprecated, not removed.** Making them private at once would
  break a caller before 1.0. The breakwater and the two top switches were settled by the rename
  release: `coversPage:`, `reachesTop:`, `clearsTopSystemEdge:` and `HarborPageCover`.
- **`HarborFloat`'s diagnostics** show `barrier:` beside `modal`. A sheet's show `headerBar` and
  `footerBar`.
