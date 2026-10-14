# Harbor Master: scenarios

The game's scenes show the patterns working together. The **Harbor Field Guide**
(book button on the first page; `lib/field_guide/`) shows them one class at a
time, by name, on an interactive pretend phone.

Every pattern harbor supports has a scene here. Each scene shows a logbook note
saying which pattern it demonstrates and what to try. Turn on the inspector in the
Harbor Office to see every bar's ground, each frame's room and the keyboard.

| # | Scene | Pattern | Where |
|---|---|---|---|
| 1 | Harbor Town tab bar | Solid bar that stays: the keyboard covers it, the tab's body ends at the keyboard's top | `shell.dart` |
| 2 | Tide bonus bubble | Float anchored to a button inside a bar, overlapping it | `shell.dart` |
| 3 | Quick actions | Modal float that hides the floats before it | `shell.dart` |
| 4 | Open Sea header | Overlay bar with a fade edge effect over a full-bleed background | `scenes/open_sea.dart` |
| 5 | Sea mood chips | Horizontal scroll view inside a bar: bleeds past side cutouts, pads both ends | `scenes/open_sea.dart` |
| 6 | Voyage cards | HarborClear content in the room; frame size that ignores the keyboard | `scenes/open_sea.dart` |
| 7 | Sea shanty drawer | Non-modal sheet that covers the page, over the tab bar; header withdraws (tab) or goes dark (pushed page) | `scenes/open_sea.dart` |
| 8 | Fog horn | Float at the bottom of the room | `scenes/open_sea.dart` |
| 9 | Fleet registry | Frosted overlay header with a search field; scroll view of rows on the row insets | `scenes/fleet.dart` |
| 10 | Boat detail hero | Hero under the header; title clears the system edges only | `scenes/fleet.dart` |
| 11 | Title handoff | HarborKeepInSight reports how much of the hero title the header covers | `scenes/fleet.dart` |
| 12 | Logbook tabs | Sliver bar pinned under the header, stacking | `scenes/fleet.dart` |
| 13 | Crew carousel | Horizontal scroll view, both ends, edge to edge | `scenes/fleet.dart` |
| 14 | Charter pill | Attached bar, attached from deep in the tree | `scenes/fleet.dart` |
| 15 | Radio channel | Overlay header, reversed scroll view thread, composer that rides the keyboard | `scenes/radio.dart` |
| 16 | Crew mentions | Float anchored above the composer, clamped below the header | `scenes/radio.dart` |
| 17 | Call actions | Dialog that inherits the page's room | `scenes/radio.dart` |
| 18 | Photo locker | Draggable sheet that covers the page; the thread keeps clear of it | `scenes/radio.dart` |
| 19 | Harbor registration | Footer that stays behind the keyboard; switches to riding it for one field; fields kept in sight | `scenes/registration.dart` |
| 20 | Shrinking crest | Reading the keyboard's height for information | `scenes/registration.dart` |
| 21 | Shipyard canvas | Body under the keyboard; boats lift clear of the paint sheet | `scenes/shipyard.dart` |
| 22 | Paint shop | Keyboard space: the color tabs fill the keyboard's ground, nothing moves | `scenes/shipyard.dart` |
| 23 | Tool strip | Withdraws while the keyboard is shown, holding its ground until gone | `scenes/shipyard.dart` |
| 24 | Unsaved changes | Attached bar above the tool strip | `scenes/shipyard.dart` |
| 25 | Cargo manifest | Content-sized sheet: overlay header, footer rides the keyboard and clears the home indicator once | `scenes/office.dart` |
| 26 | Charter board | Draggable sheet, heights above the keyboard | `scenes/office.dart` |
| 27 | Harbor rules | Column-style solid header; HarborClear text; a minimum off a bare edge | `scenes/office.dart` |
| 28 | Signal flags | Toasts by slot; a toast moves to the page on top when its page leaves | `scenes/office.dart` |
| 29 | Postcard | A fixed frame with no system edges or keyboard | `scenes/office.dart` |
| 30 | Chandlery | A component frame nested in a sheet | `scenes/office.dart` |
| 31 | Switches | Inspector overlay, right-to-left, TV mode | `scenes/office.dart` |
| 32 | Lighthouse TV | Scaled screen, title-safe band, rail that opens on focus (live vs resting), D-pad reveal, rail goes dark for a long voyage | `scenes/tv.dart` |
