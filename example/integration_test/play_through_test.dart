import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/main.dart';
import 'package:integration_test/integration_test.dart';

/// Plays through every scene of Harbor Master on a real device or simulator:
/// real insets, the real software keyboard, real fonts. Each step takes a
/// screenshot and checks where things landed against what's in the way.
///
/// Run with `fvm flutter drive --driver=test_driver/integration_test.dart
/// --target=integration_test/play_through_test.dart -d DEVICE`.
void main() {
  final IntegrationTestWidgetsFlutterBinding binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late _Deck deck;

  setUp(() => deck = _Deck(binding));

  Future<void> launch(final WidgetTester tester) async {
    // A fresh app each time, so no route is left over from the last test.
    await tester.pumpWidget(HarborMasterApp(key: UniqueKey()));
    await deck.sail(tester, 1500);
  }

  testWidgets('1 · Harbor Town shell', (final tester) async {
    await launch(tester);
    await deck.shot(tester, '01_harbor_town');
    final Rect tabs = deck.rectOfKey(tester, 'town tab openSea').expandToInclude(deck.rectOfKey(tester, 'town tab office'));
    final Rect launchButton = tester.getRect(find.byKey(const ValueKey<String>('launch button')));
    deck.check('tab bar quay runs to the screen edge', deck.near(deck.tabBarRect(tester).bottom, deck.height));
    deck.check('tab items sit above the home indicator', tabs.bottom <= deck.height - deck.bottomCoast + 0.5);
    final Finder bubble = find.textContaining('to launch a boat');
    deck.check('tide bonus bubble is up', bubble.evaluate().isNotEmpty);
    if (bubble.evaluate().isNotEmpty) {
      final Rect b = tester.getRect(find.ancestor(of: bubble, matching: find.byType(Column)).first);
      deck.check('bubble overlaps the launch button by its caret', b.bottom > launchButton.top && b.bottom <= launchButton.top + 8);
    }
    await tester.longPress(find.byKey(const ValueKey<String>('launch button')));
    await deck.sail(tester, 600);
    await deck.shot(tester, '02_quick_actions');
    deck.check('quick actions open', find.text('Open the shipyard').evaluate().isNotEmpty);
    deck.check('modal buoy hides the bubble', find.textContaining('to launch a boat').hitTestable().evaluate().isEmpty);
    await tester.tap(find.text('Raise a flare'));
    await deck.sail(tester, 700);
    await deck.shot(tester, '03_flare_low');
    final Finder flare = find.text('All hands on deck!');
    deck.check('low flare raised', flare.evaluate().isNotEmpty);
    if (flare.evaluate().isNotEmpty) {
      deck.check('low flare clears the tab bar', tester.getRect(flare).bottom <= deck.tabBarRect(tester).top);
    }
    deck.report();
  });

  testWidgets('2 · Open Sea', (final tester) async {
    await launch(tester);
    final Rect title = tester.getRect(find.text('Open Sea').first);
    deck.check('header title below the status bar', title.top >= deck.topCoast);
    final Rect calm = deck.rectOfKey(tester, 'mood calm');
    deck.check('first chip on the mooring line (16)', deck.near(calm.left, 16, 1));
    final Finder card = find.byKey(const ValueKey<String>('voyage card 0'));
    deck.check('voyage card shown', card.evaluate().isNotEmpty);
    if (card.evaluate().isNotEmpty) {
      deck.check('card below the header', tester.getRect(card).top >= deck.rectOfKey(tester, 'mood calm').bottom);
      deck.check('card above the tab bar', tester.getRect(card).bottom <= deck.tabBarRect(tester).top + 0.5);
    }
    await tester.tap(find.byKey(const ValueKey<String>('mood stormy')));
    await deck.sail(tester, 500);
    await deck.shot(tester, '04_open_sea_stormy');
    await tester.drag(find.byKey(const ValueKey<String>('mood calm')), const Offset(-300, 0));
    await deck.sail(tester, 600);
    await deck.shot(tester, '05_chips_scrolled');
    await tester.tap(find.byTooltip('Sound the fog horn'));
    await deck.sail(tester, 300);
    await deck.shot(tester, '06_fog_horn');
    final Finder horn = find.byKey(const ValueKey<String>('fog horn buoy'));
    deck.check('fog horn buoy up', horn.evaluate().isNotEmpty);
    if (horn.evaluate().isNotEmpty) {
      final Rect h = tester.getRect(horn);
      deck.check('fog horn sits just above the tab bar', h.bottom <= deck.tabBarRect(tester).top && h.bottom >= deck.tabBarRect(tester).top - 40);
    }
    await deck.sail(tester, 2500);
    await tester.tap(find.text('Sing a shanty').first);
    await deck.sail(tester, 900);
    await deck.shot(tester, '07_shanty_drawer');
    final Finder drawer = find.byKey(const ValueKey<String>('shanty drawer'));
    deck.check('shanty drawer open', drawer.evaluate().isNotEmpty);
    if (drawer.evaluate().isNotEmpty && card.evaluate().isNotEmpty) {
      deck.check('drawer covers the tab bar', tester.getRect(drawer).bottom >= deck.tabBarRect(tester).bottom - 1);
      deck.check('header withdrew', find.text('Open Sea').hitTestable().evaluate().isEmpty);
      deck.check('card stays above the drawer', tester.getRect(card).bottom <= tester.getRect(drawer).top + 1);
      deck.check('card stays below the status bar', tester.getRect(card).top >= deck.topCoast - 1);
    }
    await deck.closeSheet(tester);
    await deck.shot(tester, '08_drawer_closed');
    deck.check('header back after the drawer', find.text('Open Sea').hitTestable().evaluate().isNotEmpty);
    await tester.tap(find.text('Follow this voyage').first);
    await deck.sail(tester, 900);
    await deck.shot(tester, '09_voyage_page');
    final Finder back = find.byTooltip('Back');
    deck.check('voyage page has a way back', back.evaluate().isNotEmpty);
    await tester.tap(find.text('Sing a shanty').first);
    await deck.sail(tester, 900);
    await deck.shot(tester, '10_voyage_shanty_dark_header');
    deck.check('pushed header keeps its back button ground (goes dark)', back.evaluate().isNotEmpty && tester.getRect(back.first).top >= deck.topCoast - 1);
    await deck.closeSheet(tester);
    await tester.tap(find.byTooltip('Back').first);
    await deck.sail(tester, 800);
    deck.report();
  });

  testWidgets('3 · Fleet registry and boat detail', (final tester) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey<String>('town tab fleet')));
    await deck.sail(tester, 800);
    await deck.shot(tester, '11_fleet');
    final Rect search = deck.rectOfKey(tester, 'registry search');
    final Rect row0 = deck.rectOfKey(tester, 'boat row 0');
    deck.check('first row rests below the header', row0.top >= search.bottom);
    final Rect tabBefore = deck.tabBarRect(tester);
    await tester.tap(find.byKey(const ValueKey<String>('registry search')));
    await deck.sail(tester, 1200);
    await deck.shot(tester, '12_fleet_search_keyboard');
    final double waterline = deck.waterline;
    deck.check('keyboard came in (${deck.tideHeight.toStringAsFixed(0)})', deck.tideHeight > 100);
    deck.check('tab bar stays on its pilings under the keyboard', deck.near(deck.tabBarRect(tester).top, tabBefore.top));
    // Scrolled programmatically: a drag would dismiss the keyboard.
    final ScrollPosition registry = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    registry.jumpTo(registry.maxScrollExtent);
    await deck.sail(tester, 600);
    registry.jumpTo(registry.maxScrollExtent);
    await deck.sail(tester, 600);
    final Finder last = find.byKey(const ValueKey<String>('boat row 23'));
    await deck.shot(tester, '13_fleet_last_row_above_keyboard');
    deck.check('keyboard still up', deck.tideHeight > 100);
    deck.check('last row reachable above the keyboard', last.evaluate().isNotEmpty && tester.getRect(last).bottom <= deck.waterline + 1);
    deck.check('waterline unchanged while scrolling', deck.near(deck.waterline, waterline, 1));
    await deck.type(tester, find.byKey(const ValueKey<String>('registry search')), 'Puff');
    await deck.sail(tester, 500);
    await deck.shot(tester, '14_fleet_filtered');
    deck.check('search filters the registry', find.text('Puffin').evaluate().isNotEmpty && find.text('Saltwind').evaluate().isEmpty);
    await deck.type(tester, find.byKey(const ValueKey<String>('registry search')), '');
    await deck.dismissKeyboard(tester);
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 3000), 3000);
    await deck.sail(tester, 1200);
    await tester.tap(find.byKey(const ValueKey<String>('boat row 0')));
    await deck.sail(tester, 1000);
    await deck.shot(tester, '15_boat_detail');
    final Rect hero = deck.rectOfKey(tester, 'boat hero');
    deck.check('hero runs under the header to the top', deck.near(hero.top, 0, 1));
    final Rect heroTitle = deck.rectOfKey(tester, 'hero title block');
    deck.check('hero title clears the status bar', heroTitle.top >= deck.topCoast - 0.5);
    final Rect header = deck.rectOfKey(tester, 'boat header');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await deck.sail(tester, 800);
    await deck.shot(tester, '16_boat_detail_scrolled');
    final Rect logbook = deck.rectOfKey(tester, 'logbook tabs');
    final Rect sort = deck.rectOfKey(tester, 'sort strip');
    deck.check('logbook tabs pin at the header', deck.near(logbook.top, header.bottom, 1));
    deck.check('sort strip stacks under them', deck.near(sort.top, logbook.bottom, 1));
    final Finder pill = find.byKey(const ValueKey<String>('voyage pill'));
    if (pill.evaluate().isNotEmpty) {
      final Rect p = tester.getRect(pill);
      deck.check('voyage pill rides at or below the pinned strips', p.top >= sort.bottom - 0.5);
    }
    final Finder charter = find.byKey(const ValueKey<String>('charter pill'));
    deck.check('charter pontoon is up', charter.evaluate().isNotEmpty);
    if (charter.evaluate().isNotEmpty) {
      deck.check('charter pontoon clears the home indicator', tester.getRect(charter).bottom <= deck.height - deck.bottomCoast + 0.5);
    }
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await deck.sail(tester, 800);
    await deck.shot(tester, '17_boat_detail_carousel');
    final Finder carousel = find.byKey(const ValueKey<String>('crew carousel'));
    if (carousel.evaluate().isNotEmpty) {
      final Finder firstCrew = find.byKey(const ValueKey<String>('crew Ada'));
      if (firstCrew.evaluate().isNotEmpty) {
        deck.check('crew carousel starts on the mooring line', deck.near(tester.getRect(firstCrew).left, 16, 1));
      }
      await tester.fling(find.descendant(of: carousel, matching: find.byType(Scrollable)).first, const Offset(-3000, 0), 3000);
      await deck.sail(tester, 1500);
      await deck.shot(tester, '18_carousel_end');
      final Finder lastCrew = find.byKey(const ValueKey<String>('crew Juno'));
      deck.check('carousel ends on the mooring line', lastCrew.evaluate().isNotEmpty && deck.near(tester.getRect(lastCrew).right, deck.width - 16, 1));
    }
    await tester.fling(find.byType(Scrollable).first, const Offset(0, -4000), 3000);
    await deck.sail(tester, 1500);
    await deck.shot(tester, '19_boat_detail_end');
    if (charter.evaluate().isNotEmpty) {
      final List<Element> tiles = find.byWidgetPredicate((final Widget w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('voyage tile')).evaluate().toList();
      if (tiles.isNotEmpty) {
        final double lowest = tiles.map((final Element e) => tester.getRect(find.byElementPredicate((final Element x) => identical(x, e))).bottom).reduce((final double a, final double b) => a > b ? a : b);
        deck.check('last voyage tile rests above the charter pontoon', lowest <= tester.getRect(charter).top + 1);
      }
    }
    deck.report();
  });

  testWidgets('4 · Radio channel and registration', (final tester) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey<String>('town tab radio')));
    await deck.sail(tester, 800);
    await deck.shot(tester, '20_radio_room');
    await tester.tap(find.text('Harbor Control').first);
    await deck.sail(tester, 1000);
    await deck.shot(tester, '21_channel');
    final Rect composer = deck.rectOfKey(tester, 'composer');
    deck.check('composer above the home indicator', deck.near(composer.bottom, deck.height - deck.bottomCoast, 1));
    final Rect header = deck.rectOfKey(tester, 'channel header');
    deck.check('channel header below the status bar', header.top >= 0);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey<String>('composer')), matching: find.byType(TextField)));
    await deck.sail(tester, 1300);
    await deck.shot(tester, '22_channel_keyboard');
    final Rect floated = deck.rectOfKey(tester, 'composer');
    deck.check('composer floats on the waterline', deck.near(floated.bottom, deck.waterline, 1));
    await deck.type(tester, find.descendant(of: find.byKey(const ValueKey<String>('composer')), matching: find.byType(TextField)), 'Ahoy @');
    await deck.sail(tester, 700);
    await deck.shot(tester, '23_mentions');
    final Finder mentions = find.byKey(const ValueKey<String>('crew mentions'));
    deck.check('crew mentions buoy up', mentions.evaluate().isNotEmpty);
    if (mentions.evaluate().isNotEmpty) {
      final Rect m = tester.getRect(mentions);
      deck.check('mentions sit above the composer', m.bottom <= deck.rectOfKey(tester, 'composer').top + 0.5);
      deck.check('mentions stay below the header', m.top >= deck.rectOfKey(tester, 'channel header').bottom - 0.5);
      await tester.tap(find.descendant(of: mentions, matching: find.text('Bo')).first);
      await deck.sail(tester, 500);
    }
    await deck.tapSend(tester);
    await deck.sail(tester, 700);
    await deck.shot(tester, '24_call_sent');
    deck.check('sent call shows', find.textContaining('Ahoy @Bo').evaluate().isNotEmpty);
    if (find.textContaining('Ahoy @Bo').evaluate().isNotEmpty) {
      deck.check('newest call rests above the composer', tester.getRect(find.textContaining('Ahoy @Bo').first).bottom <= deck.rectOfKey(tester, 'composer').top);
    }
    await deck.dismissKeyboard(tester);
    await deck.foldNote(tester);
    final Finder anyCall = find.byWidgetPredicate((final Widget w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('call '));
    if (anyCall.evaluate().isNotEmpty) {
      await tester.longPress(anyCall.first);
      await deck.sail(tester, 700);
      await deck.shot(tester, '25_call_actions');
      final Finder actions = find.byKey(const ValueKey<String>('call actions'));
      deck.check('call actions dialog open', actions.evaluate().isNotEmpty);
      if (actions.evaluate().isNotEmpty) {
        final Rect a = tester.getRect(actions);
        deck.check('actions stay below the header', a.top >= deck.rectOfKey(tester, 'channel header').bottom - 1);
        deck.check('actions stay above the composer', a.bottom <= deck.rectOfKey(tester, 'composer').top + 1);
        await tester.tap(find.text('Edit'));
        await deck.sail(tester, 1500);
        await deck.shot(tester, '26_editing_call');
        deck.check('editing banner shows', find.text('Amending a call on the log').evaluate().isNotEmpty);
        await tester.tap(find.text('Belay that'));
        await deck.sail(tester, 400);
      }
    }
    await deck.dismissKeyboard(tester);
    await tester.tap(find.byTooltip('Photo locker'));
    await deck.sail(tester, 1000);
    await deck.shot(tester, '27_photo_locker');
    deck.check('photo locker open', find.text('Photo locker').evaluate().isNotEmpty);
    deck.check('photo locker shows its photos', find.text('Breakwater sheet').evaluate().isNotEmpty);
    final Finder threadFairway = find.ancestor(of: anyCall.first, matching: find.byType(HarborFairway)).first;
    final double padded = MediaQuery.paddingOf(tester.element(threadFairway)).bottom;
    final Rect thread = tester.getRect(threadFairway);
    final Finder locker = find.byType(Sailcloth);
    deck.check(
      'thread keeps clear of the breakwater (thread ${thread.bottom.toStringAsFixed(1)} − padding ${padded.toStringAsFixed(1)} vs sheet top ${locker.evaluate().isEmpty ? '-' : tester.getRect(locker.first).top.toStringAsFixed(1)})',
      locker.evaluate().isNotEmpty && deck.near(thread.bottom - padded, tester.getRect(locker.first).top, 2),
    );
    await deck.closeSheet(tester);
    await tester.tap(find.byTooltip('Back').first);
    await deck.sail(tester, 800);
    await tester.tap(find.text('Register a new boat'));
    await deck.sail(tester, 1000);
    await deck.shot(tester, '28_registration');
    final Rect footer = deck.rectOfKey(tester, 'registration footer');
    final Rect crest = deck.rectOfKey(tester, 'registration crest');
    await tester.tap(find.byKey(const ValueKey<String>('boat name')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '29_registration_keyboard');
    deck.check('footer stays on its pilings under the keyboard', deck.near(deck.rectOfKey(tester, 'registration footer').top, footer.top));
    deck.check('crest shrinks while the tide is in', deck.rectOfKey(tester, 'registration crest').height < crest.height);
    await deck.reveal(tester, find.byKey(const ValueKey<String>('harbor master email')));
    await tester.tap(find.byKey(const ValueKey<String>('harbor master email')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '30_registration_email');
    deck.check('focused email field kept in sight', deck.rectOfKey(tester, 'harbor master email').bottom <= deck.waterline + 0.5);
    await deck.reveal(tester, find.byKey(const ValueKey<String>('berth password')));
    await tester.tap(find.byKey(const ValueKey<String>('berth password')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '31_registration_password');
    deck.check('footer floats on the waterline for the password', deck.near(deck.rectOfKey(tester, 'registration footer').bottom, deck.waterline, 1));
    deck.check('password rules shown', find.textContaining('8 knots').evaluate().isNotEmpty);
    deck.check('password field kept in sight above the footer', deck.rectOfKey(tester, 'berth password').bottom <= deck.rectOfKey(tester, 'registration footer').top + 0.5);
    await deck.dismissKeyboard(tester);
    deck.report();
  });

  testWidgets('5 · Shipyard', (final tester) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey<String>('launch button')));
    await deck.sail(tester, 1000);
    await deck.shot(tester, '32_shipyard');
    final Rect strip = deck.rectOfKey(tester, 'tool strip');
    deck.check('tool strip above the home indicator', deck.near(strip.bottom, deck.height - deck.bottomCoast, 1));
    await deck.foldNote(tester);
    await tester.tap(find.byKey(const ValueKey<String>('boat-3')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '33_paint_shop');
    final Finder panel = find.byKey(const ValueKey<String>('paint panel'));
    deck.check('paint shop open', panel.evaluate().isNotEmpty);
    if (panel.evaluate().isNotEmpty) {
      final Rect p = tester.getRect(panel);
      deck.check('selected boat lifted 80 clear of the paint shop', deck.rectOfKey(tester, 'boat-3').bottom <= p.top - 80 + 1);
      await tester.tap(find.byKey(const ValueKey<String>('tab hull')));
      await deck.sail(tester, 600);
      await deck.shot(tester, '34_paint_hull');
      await tester.tap(find.byKey(const ValueKey<String>('tab name')));
      await deck.sail(tester, 400);
      await tester.tap(find.byKey(const ValueKey<String>('name field')));
      await deck.sail(tester, 1500);
      await deck.shot(tester, '35_paint_name_keyboard');
      deck.check('keyboard in for the name', deck.tideHeight > 100);
      deck.check('tool strip withdrew at high tide', find.byKey(const ValueKey<String>('add boat')).hitTestable().evaluate().isEmpty);
      final Rect dry = deck.rectOfKey(tester, 'dry dock');
      deck.check('dry dock top meets the waterline', deck.near(dry.top, deck.waterline, 2));
      // Measured once the keyboard has settled, so the high-water mark is real.
      final double hullHeight = tester.getRect(panel).height;
      await deck.dismissKeyboard(tester);
      await tester.tap(find.byKey(const ValueKey<String>('tab hull')));
      await deck.sail(tester, 800);
      deck.check('paint shop holds one height (${hullHeight.toStringAsFixed(0)} → ${tester.getRect(panel).height.toStringAsFixed(0)})', deck.near(tester.getRect(panel).height, hullHeight, 1));
      final Finder pot = find.byWidgetPredicate((final Widget w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('hull '));
      if (pot.evaluate().length > 2) {
        await tester.tap(pot.at(2));
        await deck.sail(tester, 500);
        await deck.shot(tester, '36_painted');
      }
      await tester.tap(find.byKey(const ValueKey<String>('boat-3')));
      await deck.sail(tester, 1200);
      await deck.shot(tester, '37_paint_closed');
      deck.check('paint shop closed on deselect', panel.evaluate().isEmpty);
    }
    await tester.tap(find.byKey(const ValueKey<String>('add crate')));
    await deck.sail(tester, 800);
    await deck.shot(tester, '38_unsaved');
    final Finder unsaved = find.byKey(const ValueKey<String>('unsaved bar'));
    deck.check('unsaved pontoon up', unsaved.evaluate().isNotEmpty);
    if (unsaved.evaluate().isNotEmpty) {
      deck.check('unsaved bar stacks on the tool strip', deck.near(tester.getRect(unsaved).bottom, deck.rectOfKey(tester, 'tool strip').top, 1.5));
      await tester.tap(find.descendant(of: unsaved, matching: find.text('Save')));
      await deck.sail(tester, 800);
      await deck.shot(tester, '39_saved_flare');
      deck.check('saved flare raised', find.text('Shipyard saved!').evaluate().isNotEmpty);
    }
    await tester.tap(find.byKey(const ValueKey<String>('ceremony toggle')));
    await deck.sail(tester, 800);
    await deck.shot(tester, '40_ceremony');
    final Finder ceremony = find.byKey(const ValueKey<String>('ceremony card'));
    deck.check('ceremony card in the middle', ceremony.evaluate().isNotEmpty);
    await tester.tap(find.byTooltip('Back').first);
    await deck.sail(tester, 800);
    deck.report();
  });

  testWidgets('6 · Harbor Office', (final tester) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey<String>('town tab office')));
    await deck.sail(tester, 800);
    await deck.shot(tester, '41_office');
    await tester.tap(find.byKey(const ValueKey<String>('chart switch')));
    await deck.sail(tester, 800);
    await deck.shot(tester, '42_chart_on');
    deck.check('chart sees the tab bar', HarborChart.snapshot(tester.element(find.byType(HarborSea))).any((final HarborChartEntry e) => e.docks.any((final HarborDockRecord d) => d.label == 'tab bar')));
    await tester.tap(find.byKey(const ValueKey<String>('chart switch')));
    await deck.sail(tester, 400);
    await tester.tap(find.byKey(const ValueKey<String>('rtl switch')));
    await deck.sail(tester, 900);
    await deck.shot(tester, '43_right_to_left');
    deck.check('right-to-left mirrors the tab bar', deck.rectOfKey(tester, 'town tab openSea').left > deck.rectOfKey(tester, 'town tab office').left);
    await tester.tap(find.byKey(const ValueKey<String>('rtl switch')));
    await deck.sail(tester, 900);

    await deck.reveal(tester, find.text('Cargo manifest'));
    await tester.tap(find.text('Cargo manifest'));
    await deck.sail(tester, 900);
    await deck.shot(tester, '44_cargo_manifest');
    final Rect cargoFooter = deck.rectOfKey(tester, 'cargo footer');
    deck.check('cargo footer clears the home indicator once', deck.near(cargoFooter.bottom, deck.height - deck.bottomCoast, 1));
    await tester.tap(find.byKey(const ValueKey<String>('cargo field')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '45_cargo_keyboard');
    deck.check('cargo sheet stays below the status bar', tester.getRect(find.text('Cargo manifest').last).top >= deck.topCoast);
    deck.check('cargo footer floats on the keyboard', deck.rectOfKey(tester, 'cargo footer').bottom <= deck.waterline + 0.5 && deck.rectOfKey(tester, 'cargo footer').bottom >= deck.waterline - 20);
    await deck.dismissKeyboard(tester);
    await deck.closeSheet(tester);

    await deck.reveal(tester, find.text('Charter board'));
    await tester.tap(find.text('Charter board'));
    await deck.sail(tester, 900);
    await deck.shot(tester, '46_charter_board');
    final double rest = deck.rectOfKey(tester, 'charter header').top;
    deck.check('charter board rests at half the water below the status bar', deck.near(rest, deck.height - (deck.height - deck.topCoast) * 0.5, 2));
    await tester.drag(find.byKey(const ValueKey<String>('charter header')), const Offset(0, -300));
    await deck.sail(tester, 900);
    await deck.shot(tester, '47_charter_hauled');
    deck.check('charter board hauls up by its header', deck.rectOfKey(tester, 'charter header').top < rest - 150);
    await deck.closeSheet(tester);

    await deck.reveal(tester, find.text('Harbor rules'));
    await tester.tap(find.text('Harbor rules'));
    await deck.sail(tester, 900);
    await deck.shot(tester, '48_harbor_rules');
    deck.check('"I agree" clears the bottom', deck.rectOfKey(tester, 'i agree').bottom <= deck.height - deck.bottomCoast + 0.5);
    deck.check('rules header below the status bar', deck.rectOfKey(tester, 'rules header').top >= deck.topCoast - 0.5);
    await tester.tap(find.byTooltip('Back').first);
    await deck.sail(tester, 800);

    await deck.reveal(tester, find.text('Chandlery'));
    await tester.tap(find.text('Chandlery'));
    await deck.sail(tester, 900);
    await deck.shot(tester, '49_chandlery');
    final Finder shelves = find.byKey(const ValueKey<String>('chandlery shelves'));
    deck.check('chandlery open', shelves.evaluate().isNotEmpty);
    await deck.closeSheet(tester);

    await tester.scrollUntilVisible(find.byKey(const ValueKey<String>('raise and leave')), 200, scrollable: find.descendant(of: find.byKey(const ValueKey<String>('office fairway')), matching: find.byType(Scrollable)).first);
    await deck.sail(tester, 500);
    for (final String slot in <String>['Top', 'High', 'Middle', 'Low']) {
      await tester.tap(find.text(slot).last);
      await deck.sail(tester, 300);
    }
    await deck.shot(tester, '50_flares');
    final Finder topFlare = find.text('Fog on the top deck');
    deck.check('top flare clears the office header', topFlare.evaluate().isEmpty || tester.getRect(topFlare).top >= tester.getRect(find.text('Harbor Office')).bottom);
    await tester.tap(find.byKey(const ValueKey<String>('raise and leave')));
    await deck.sail(tester, 2000);
    await deck.shot(tester, '51_raise_and_leave');
    deck.check('raised flare survives its page leaving', find.byKey(const ValueKey<String>('tower signal')).evaluate().isNotEmpty || find.textContaining('tower').evaluate().isNotEmpty);
    await tester.scrollUntilVisible(find.byKey(const ValueKey<String>('postcard frame')), 200, scrollable: find.descendant(of: find.byKey(const ValueKey<String>('office fairway')), matching: find.byType(Scrollable)).first);
    await deck.sail(tester, 600);
    await deck.shot(tester, '52_postcard');
    deck.report();
  });

  testWidgets('7 · Lighthouse TV', (final tester) async {
    await launch(tester);
    await tester.tap(find.byKey(const ValueKey<String>('town tab office')));
    await deck.sail(tester, 800);
    await tester.tap(find.byKey(const ValueKey<String>('tv switch')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '53_tv');
    final Finder rail = find.byKey(const ValueKey<String>('rail'));
    deck.check('TV rail up', rail.evaluate().isNotEmpty);
    final Finder wall = find.byKey(const ValueKey<String>('fleet wall'));
    final double wallStart = wall.evaluate().isEmpty ? 0 : tester.getRect(wall).left;
    for (int i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await deck.sail(tester, 400);
    }
    await deck.sail(tester, 900);
    await deck.shot(tester, '54_tv_rail_open');
    for (int i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await deck.sail(tester, 350);
    }
    await deck.sail(tester, 900);
    await deck.shot(tester, '55_tv_dpad_cards');
    deck.check('fleet wall shown', wallStart >= 0);
    await tester.tap(find.byKey(const ValueKey<String>('rail openSea')));
    await deck.sail(tester, 1200);
    await deck.shot(tester, '56_tv_open_sea');
    await tester.tap(find.byKey(const ValueKey<String>('rail longVoyage')));
    await deck.sail(tester, 900);
    final Finder toggle = find.byKey(const ValueKey<String>('voyage toggle'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle);
      await deck.sail(tester, 1200);
      await deck.shot(tester, '57_tv_long_voyage_dark_rail');
      await tester.tap(toggle);
      await deck.sail(tester, 900);
    }
    await tester.tap(find.byKey(const ValueKey<String>('rail phone')));
    await deck.sail(tester, 1500);
    await deck.shot(tester, '58_back_to_phone');
    deck.check('back on the phone', find.byKey(const ValueKey<String>('town tab office')).evaluate().isNotEmpty);
    deck.report();
  });
}

/// The deck the play-through works from: screenshots, soft checks, the
/// screen's real geometry, and helpers for the keyboard and sheets.
class _Deck {
  _Deck(this.binding);

  final IntegrationTestWidgetsFlutterBinding binding;
  final List<String> _failures = <String>[];
  final List<String> _passes = <String>[];

  FlutterView get view => binding.platformDispatcher.implicitView!;
  double get dpr => view.devicePixelRatio;
  double get width => view.physicalSize.width / dpr;
  double get height => view.physicalSize.height / dpr;
  double get topCoast => view.viewPadding.top / dpr;
  double get bottomCoast => view.viewPadding.bottom / dpr;
  double get tideHeight => view.viewInsets.bottom / dpr;
  double get waterline => height - tideHeight;

  bool near(final double a, final double b, [final double tolerance = 0.5]) => (a - b).abs() <= tolerance;

  void check(final String what, final bool ok) {
    (ok ? _passes : _failures).add(what);
    // ignore: avoid_print
    print('${ok ? 'PASS' : 'FAIL'} · $what');
  }

  void report() {
    // ignore: avoid_print
    print('SUMMARY · ${_passes.length} passed, ${_failures.length} failed${_failures.isEmpty ? '' : ': ${_failures.join(' | ')}'}');
    expect(_failures, isEmpty);
  }

  Future<void> sail(final WidgetTester tester, final int ms) async {
    final DateTime end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> shot(final WidgetTester tester, final String name) async {
    await binding.takeScreenshot(name);
    await sail(tester, 50);
  }

  Rect rectOfKey(final WidgetTester tester, final String key) {
    final Finder f = find.byKey(ValueKey<String>(key));
    if (f.evaluate().isEmpty) {
      check('found "$key"', false);
      return Rect.zero;
    }
    return tester.getRect(f.first);
  }

  Rect tabBarRect(final WidgetTester tester) {
    final BuildContext context = tester.element(find.byType(Harbor).last); // inside the sea, so on its chart
    for (final HarborChartEntry entry in HarborChart.snapshot(context)) {
      for (final HarborDockRecord dock in entry.docks) {
        if (dock.label == 'tab bar') {
          return dock.rect;
        }
      }
    }
    check('found the tab bar dock', false);
    return Rect.zero;
  }

  /// Types [text] into [field], using the test text input for the typing and
  /// then giving the real keyboard back.
  Future<void> type(final WidgetTester tester, final Finder field, final String text) async {
    tester.testTextInput.register();
    await tester.showKeyboard(field);
    tester.testTextInput.updateEditingValue(TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)));
    await sail(tester, 200);
    tester.testTextInput.unregister();
    await tester.tap(field);
    await sail(tester, 1000);
  }

  /// Scrolls [target] into clear water before it's tapped.
  Future<void> reveal(final WidgetTester tester, final Finder target) async {
    await Scrollable.ensureVisible(tester.element(target.first), alignment: 0.5);
    await sail(tester, 600);
  }

  /// Folds the scene's logbook note, as a sailor would before working under it.
  Future<void> foldNote(final WidgetTester tester) async {
    final Finder note = find.byKey(const ValueKey<String>('logbook note'));
    if (note.evaluate().isNotEmpty) {
      await tester.tap(note.first);
      await sail(tester, 400);
    }
  }

  Future<void> tapSend(final WidgetTester tester) async {
    await tester.tap(find.byTooltip('Send').first);
  }

  Future<void> dismissKeyboard(final WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await sail(tester, 1200);
  }

  Future<void> closeSheet(final WidgetTester tester) async {
    final Finder close = find.byTooltip('Close');
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close.last);
    } else {
      await tester.tapAt(const Offset(20, 120));
    }
    await sail(tester, 900);
  }
}
