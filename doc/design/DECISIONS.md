# API decisions for #120

Decided by the owner agent on 2026-10-14. Jonah delegated these: "make the decisions you believe are
right for the product ... Breaking changes are okay. Add dart fixes if you can." The proposals they
settle are the other files in this directory. Where a proposal and this file disagree, this file
wins.

## How every change ships

- **Deprecate first, then remove.** Each reshaped API ships in a minor release that keeps the old
  spelling as `@Deprecated` and forwards it to the new one, with a `fix_data` transform so that
  `dart fix --apply` rewrites call sites. The old spellings are removed together in one breaking
  release before 1.0. A data-driven fix only works reliably while the old element still exists, so
  this order is what lets the fixes carry the migration.
- **Fixes live in `lib/fix_data/`**, one YAML file per area (`placement.yaml`, `flares.yaml`, ...),
  so that parallel work does not collide in one file.
- **Every transform has a golden test** in `test_fixes/`, checked by
  `dart fix --compare-to-golden` in `tool/check.sh`. A fix that is not tested is a fix that rots.
  `test_fixes/` is excluded from analysis and pubignored.
- **A deprecation message names the replacement and says `dart fix` handles it**, where it does.
- **The CHANGELOG has a "Migrating" note** for anything a fix cannot express, such as a behaviour
  change or a default that moved.
- New public names are plain where the concept is plain (placement, aligned, anchored, barrier,
  timing, defaults). Nautical names stay on harbor's own ideas (buoy, flare, dock, clear water).
  Whether harbor's own ideas get renamed (#120) is decided last, once the surface is smaller.

## Naming (#120): adopt the rename

Harbor's capabilities are worth learning; the harbour words are a tax on top of them. The README
needs a 27-row table to translate them back into layout ideas, and a consumer that wrapped harbor
in its own adapters reached for plain words (root, bar, padding, scroll view, keep in sight,
anchor, toast) without being steered. So the API is renamed after the model it implements: **every
edge of the screen is claimed once, by the layer that owns it, and everything inside gets what is
left.** The `Harbor` prefix stays as the brand.

The RFC's table is adopted, with these choices on its open questions and one correction:

- **`room`** for what is left (clear water, waters).
- **`HarborBar`**, not `HarborEdgeBar`: `HarborBar.solid` (quay), `.overlay` (pier),
  `.attached` (pontoon).
- **`HarborClear`** for content that keeps clear of what is in the way (moored). It does more than
  `SafeArea`, so it should not borrow that name.
- **`HarborToast`** / **`HarborToasts.show`**, not `HarborNotice`. Toast is what developers search
  for, and harbor's flare is a transient message whatever it carries.
- **`HarborFrame`** with a **`HarborFrame.page`** constructor for a route boundary, and the
  boundary is inferred where the route changes, so `.page` is rarely written.
- **Correction:** the portal buoy becomes **`HarborPopover`**, not `HarborAnchored`.
  `HarborAnchored` is the anchored placement value from the placement work. The three overlays
  then read by their lifetime, in words developers know: `HarborFloat` (declared in the tree,
  formerly buoy), `HarborPopover` (opened on demand by an anchor, formerly portal buoy) and
  `HarborToast` (transient, formerly flare).

The complete old-to-new table is `naming.md`, reviewed and accepted on 2026-10-14 with its six
recommendations:

1. A small release before the rename adds `bars: bool` and deprecates the `HarborClear` enum, so the
   widget can take the name.
2. Pontoon and make way become the widgets `HarborAttachedBar` and `HarborHideBar`.
3. The keyboard reader is `HarborKeyboard`, and the stance is `HarborKeyboardStance`
   (`rides`, `stays`, `reserves`).
4. The wake becomes `HarborEdgeEffect` (`.fade`, `.hairline`, `.none`).
5. The harbour stays as illustration and brand in the field guide and the videos, but no longer as
   the meaning.
6. `room` serves for both clear water and waters.

Order of work:

1. The placement change, already in progress. Its new types are plain names already.
2. **One rename release**: new names, every old name kept as a deprecated typedef or forwarding
   member, `lib/fix_data/rename.yaml` covering every rename, and the README and field guide on the
   new names, with a short "Renamed in 0.x" table. Before it is applied, a complete old-to-new
   table for every public symbol is drafted in `doc/design/naming.md` and reviewed. The rename
   runs alone, because it touches every file.
3. The flares, sheets, defaults and smaller structural steps, written in the new vocabulary. So
   it is `HarborToastTiming`, not `HarborFlareTiming`.
4. One release before 1.0 removes every deprecated name.

## Placement (`placement.md`)

- Ship the sealed `HarborPlacement` with two variants, `HarborAligned` and `HarborAnchored`, and
  one internal placement engine used by the buoy layer, the portal buoy and the overlay flare.
- **Q1 `slot:` on `raise`:** keep it as a first-class shorthand, exclusive with `placement:`.
- **Q2 `HarborBuoy.anchored`:** deprecate it. `HarborBuoy(placement: HarborAnchored(...))`
  replaces it.
- **Q3 nullable anchor:** yes. `HarborAnchored.anchor` may be null only for `HarborPortalBuoy`,
  where it means "anchor to my child". `HarborBuoy` and `raise` assert it is non-null.
- **Q4 default side:** `HarborAnchored.side` defaults to `HarborAnchorSide.below`, the menu and
  toast case. It is a new type, so this breaks no existing call. The deprecated spellings keep the
  defaults they had (`above` for `HarborBuoy.anchored` and `HarborPortalBuoy`), and their fixes
  write `side: HarborAnchorSide.above` explicitly when the old call left it out, so a migrated call
  sits exactly where it did. `flips` stays nullable, and null keeps each host's behaviour.
- `HarborBuoySide` is renamed to `HarborAnchorSide` and `HarborBuoyCrossAlignment` to
  `HarborCrossAlignment`, with deprecated typedefs and `rename` fixes.
- An anchored placement asserts that `reachesCoast` is false, now that 0.6.3 made it a no-op.

## Flares (`flares.md`)

- Ship the `HarborFlareTiming` value, and fold `persist` into a null duration.
- **Q11 `duration:` shorthand:** no. `timing:` alone, so that "until lowered" has one spelling.
  The deprecated `duration:` and `persist:` forward to it, with fixes.
- **Q12 handle type:** split it. The public `HarborFlareEntry` becomes an `abstract final class`
  that says exactly what a caller may do, and the configuration lives in an internal subclass.
- **Q13 subtree timing:** not now. `HarborFlarePolicy`, or `HarborDefaults` once that lands, can
  gain it later.
- **Q14 nullable `side`:** keep it non-null until 1.0.

## Sheets, dialogs and modal buoys (`sheets.md`)

- Ship the shared `HarborBarrier` value (`.dimmed`, `.clear`, `.none`), replacing the
  `HarborSheetBarrier` enum and the loose barrier parameters on the sheet, the dialog and the modal
  buoy.
- **Q15 `none` on a dialog:** accept an assert. One shared type is worth it.
- **Q16 `modal:` on `HarborBuoy`:** deprecate it in favour of `barrier:`, and keep a read-only
  `bool get modal`.
- **Q17 header and footer defaults:** keep the sheet's own look, and publish it as
  `HarborSheet.defaultHeaderDock` / `defaultFooterDock` so a move to `headerDock:` starts from it.
- **Q18 `reachesTop` with `fillsScreenAtHinge`:** keep them separate, and document how one
  implies the other.

## Defaults (`defaults.md`)

- Ship `HarborDefaults` on `HarborSea` and `Harbor`, plus a standalone `HarborDefaultsScope`. The
  nearest scope wins, field by field.
- **Q19 standalone scope:** yes. `HarborFlarePolicy` deprecates into it.
- **Q20 `flareMargin`:** it applies only to flares whose placement `raise` builds itself (`slot:`
  or nothing).
- **Q21 shape:** flat, prefixed fields (`sheet…`, `flare…`). Revisit past about fifteen fields.
- **Q22 look and feel:** stays out of it. No widget-valued fields, ever.

## The audit's smaller steps (`../../` issue #120 audit, steps 5–10)

All of these land after the four areas above, each with fixes:

- `HarborYield` merges into `HarborDockState`.
- `withdrawsAtHighTide` becomes a `HarborTideStance` value.
- `duration`/`curve` are dropped wherever `animationStyle` already covers them.
- `HarborSizing` becomes a class: `.fill` and `.hug(maxFraction:)`.
- Clearance naming:
  - `extra` becomes `padding`;
  - one spelling for "coast only";
  - one `mooringLine` default;
  - `HarborMooringLine` becomes a `HarborMoored` constructor;
  - `HarborOpenWater` is retired.
- Trim the surface:
  - `HarborController`'s internals go `@internal`;
  - `HarborTitleSafe` folds into `HarborCoast`;
  - fix the stale `HarborCoastFeature.hinge` and `isPort` docs.
- `HarborBeacon` splits into three widgets, one per job.
- One internal page-overlay host for flares and non-modal sheets.
- **`newPort`:** infer it at route boundaries, and keep the parameter for the rare nested case.

## Product work outside the API

- **Android landscape trial devices**, gesture and 3-button: yes, in `harbor_test` and the
  field guide stage.
- **A "dock goes to the side" option:** not now. Panes plus side docks already cover it. Revisit if
  a consumer asks.
- **iPhone Duo poses:** when Xcode 27.1 is on this machine. That is not a blocker for anything above.
- **Field guide pages for hinge, panes, posture, reserve and the dual-screen device:** yes, once
  the Android landscape devices are on the stage.
- **The GitHub watcher checks when something changes**, not only 30 minutes after a turn: yes. It is
  owner tooling, outside the repo.
- **Not decided here, on purpose:**
  - **The watchdog's waiting probe** stays the human's call. showrunner leaves it to a human by
    design, because a probe the watched agent can set is an off switch.
  - **Who may start crawlers** (`roles.json`) is user-level permission and stays as it is.
