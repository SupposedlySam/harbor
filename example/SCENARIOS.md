# Harbor Master: scenarios

The game's scenes show the patterns working together. The **Harbor Field Guide**
(book button on the first page; `lib/field_guide/`) shows them one class at a
time, by name, on an interactive pretend phone.

Every pattern harbor supports has a scene here. Each scene shows a logbook note
saying which pattern it demonstrates and what to try. Turn on the chart in the
Harbor Office to see every dock's ground, each harbor's clear water and the tide.

| # | Scene | Pattern | Where |
|---|---|---|---|
| 1 | Harbor Town tab bar | Quay on pilings: the keyboard covers it, the tab's body ends at the waterline | `shell.dart` |
| 2 | Tide bonus bubble | Buoy anchored to a button inside a dock, overlapping it | `shell.dart` |
| 3 | Quick actions | Modal buoy that hides the buoys before it | `shell.dart` |
| 4 | Open Sea header | Pier with a fade wake over full-bleed open water | `scenes/open_sea.dart` |
| 5 | Sea mood chips | Horizontal fairway inside a dock: bleeds past side cutouts, pads both ends | `scenes/open_sea.dart` |
| 6 | Voyage cards | Moored content in clear water; frame size that ignores the keyboard | `scenes/open_sea.dart` |
| 7 | Sea shanty drawer | Non-modal breakwater sheet over the tab bar; header withdraws (tab) or goes dark (pushed page) | `scenes/open_sea.dart` |
| 8 | Fog horn | Buoy at the bottom of the clear water | `scenes/open_sea.dart` |
| 9 | Fleet registry | Frosted pier header with a search field; fairway of rows on the mooring line | `scenes/fleet.dart` |
| 10 | Boat detail hero | Open water hero under the header; title clears the coast only | `scenes/fleet.dart` |
| 11 | Title handoff | Beacon reports how much of the hero title the header covers | `scenes/fleet.dart` |
| 12 | Logbook tabs | Sliver dock pinned under the header, stacking | `scenes/fleet.dart` |
| 13 | Crew carousel | Horizontal fairway, both ends, edge to edge | `scenes/fleet.dart` |
| 14 | Charter pill | Pontoon moored from deep in the tree | `scenes/fleet.dart` |
| 15 | Radio channel | Pier header, reversed fairway thread, composer that floats on the tide | `scenes/radio.dart` |
| 16 | Crew mentions | Buoy anchored above the composer, clamped below the header | `scenes/radio.dart` |
| 17 | Call actions | Dialog that inherits the page's clear water | `scenes/radio.dart` |
| 18 | Photo locker | Draggable breakwater sheet; the thread keeps clear of it | `scenes/radio.dart` |
| 19 | Harbor registration | Footer on pilings behind the keyboard; switches to floating for one field; fields kept in sight | `scenes/registration.dart` |
| 20 | Shrinking crest | Reading the tide's height for information | `scenes/registration.dart` |
| 21 | Shipyard canvas | Body under the keyboard; boats lift clear of the paint sheet | `scenes/shipyard.dart` |
| 22 | Paint shop | Dry dock: the color tabs fill the keyboard's ground, nothing moves | `scenes/shipyard.dart` |
| 23 | Tool strip | Withdraws at high tide, holding its ground until gone | `scenes/shipyard.dart` |
| 24 | Unsaved changes | Pontoon above the tool strip | `scenes/shipyard.dart` |
| 25 | Cargo manifest | Content-sized sheet: header pier, footer floats and clears the home indicator once | `scenes/office.dart` |
| 26 | Charter board | Draggable sheet, heights above the keyboard | `scenes/office.dart` |
| 27 | Harbor rules | Column-style quay header; moored text; a minimum off a bare edge | `scenes/office.dart` |
| 28 | Signal flags | Signals by slot; a signal moves to the page on top when its page leaves | `scenes/office.dart` |
| 29 | Postcard | A fixed frame with no coast or tide | `scenes/office.dart` |
| 30 | Chandlery | A component harbor nested in a sheet | `scenes/office.dart` |
| 31 | Switches | Chart overlay, right-to-left, TV mode | `scenes/office.dart` |
| 32 | Lighthouse TV | Scale model, title-safe coast, rail that opens on focus (live vs resting), D-pad reveal, rail goes dark for a long voyage | `scenes/tv.dart` |
