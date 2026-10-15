// The names harbor used before 1.0, kept so code written against them still compiles. Each
// goes at 1.0.

import 'buoy.dart';
import 'chart.dart';
import 'coast.dart';
import 'controller.dart';
import 'dock.dart';
import 'fairway.dart';
import 'harbor.dart';
import 'lighthouse.dart';
import 'make_way.dart';
import 'moored.dart';
import 'placement.dart';
import 'scale_model.dart';
import 'tide.dart';
import 'wake.dart';
import 'waters.dart';

/// The old name of [HarborToasts].
@Deprecated(
  'Use HarborToasts. Signals were renamed flares in 0.3.1, and flares toasts in 0.9.0. `dart fix` applies it.',
)
typedef HarborSignals = HarborToasts;

/// The old name of [HarborToastSlot].
@Deprecated(
  'Use HarborToastSlot. Signals were renamed flares in 0.3.1, and flares toasts in 0.9.0. `dart fix` applies it.',
)
typedef HarborSignalSlot = HarborToastSlot;

/// The old name of [HarborToastTarget].
@Deprecated(
  'Use HarborToastTarget. Signals were renamed flares in 0.3.1, and flares toasts in 0.9.0. `dart fix` applies it.',
)
typedef HarborSignalTarget = HarborToastTarget;

/// The old name of [HarborToastEntry].
@Deprecated(
  'Use HarborToastEntry. Signals were renamed flares in 0.3.1, and flares toasts in 0.9.0. `dart fix` applies it.',
)
typedef HarborSignalEntry = HarborToastEntry;

/// The old name of [HarborToastTransitionBuilder].
@Deprecated(
  'Use HarborToastTransitionBuilder. Signals were renamed flares in 0.3.1, and flares toasts in 0.9.0. `dart fix` applies it.',
)
typedef HarborSignalTransitionBuilder = HarborToastTransitionBuilder;

/// The old name of [HarborToastClosedReason].
@Deprecated(
  'Use HarborToastClosedReason. Signals were renamed flares in 0.3.1, and flares toasts in 0.9.0. `dart fix` applies it.',
)
typedef HarborSignalClosedReason = HarborToastClosedReason;

/// The old name of [HarborAnchorSide].
@Deprecated(
  'Use HarborAnchorSide. Flares and HarborAnchorClip take it too, so it is not a buoy\'s alone. '
  '`dart fix` applies it. Deprecated after 0.7.0.',
)
typedef HarborBuoySide = HarborAnchorSide;

/// The old name of [HarborCrossAlignment].
@Deprecated(
  'Use HarborCrossAlignment. Flares take it too, so it is not a buoy\'s alone. '
  '`dart fix` applies it. Deprecated after 0.7.0.',
)
typedef HarborBuoyCrossAlignment = HarborCrossAlignment;

// The rename (0.9.0, #120): the harbour words became the layout model's. Each old name is a
// deprecated typedef of the new one, which `dart fix` renames (lib/fix_data/rename.yaml).
// Five old names are deprecated subclasses instead, beside their new classes: HarborDock,
// HarborBuoy, HarborCoast, HarborWake and HarborFairway. Each has a named constructor that dart fix
// rewrites (a rename, or a deprecated argument), and a typedef cannot carry a fix on a named
// constructor's call: the typedef's rename lands on the constructor (doc/design/naming.md, §2).
// HarborMooringLine is a widget in moored.dart, since it became a constructor of HarborClear.

/// The old name of [HarborRoot].
@Deprecated('Renamed HarborRoot. `dart fix` applies it.')
typedef HarborSea = HarborRoot;

/// The old name of [HarborFrame].
@Deprecated('Renamed HarborFrame. `dart fix` applies it.')
typedef Harbor = HarborFrame;

/// The old name of [HarborBarKind].
@Deprecated('Renamed HarborBarKind. `dart fix` applies it.')
typedef HarborDockKind = HarborBarKind;

/// The old name of [HarborBarState].
@Deprecated('Renamed HarborBarState. `dart fix` applies it.')
typedef HarborDockState = HarborBarState;

/// The old name of [HarborSystemEdgeStance].
@Deprecated('Renamed HarborSystemEdgeStance. `dart fix` applies it.')
typedef HarborCoastStance = HarborSystemEdgeStance;

/// The old name of [HarborSliverBar].
@Deprecated('Renamed HarborSliverBar. `dart fix` applies it.')
typedef HarborSliverDock = HarborSliverBar;

/// The old name of [HarborAttachedBarHandle].
@Deprecated('Renamed HarborAttachedBarHandle. `dart fix` applies it.')
typedef HarborPontoonHandle = HarborAttachedBarHandle;

/// The old name of [HarborHideBar].
@Deprecated('Renamed HarborHideBar. `dart fix` applies it.')
typedef HarborMakeWay = HarborHideBar;

/// The old name of [HarborSystemEdgeFeature].
@Deprecated('Renamed HarborSystemEdgeFeature. `dart fix` applies it.')
typedef HarborCoastFeature = HarborSystemEdgeFeature;

/// The old name of [HarborKeyboard].
@Deprecated('Renamed HarborKeyboard. `dart fix` applies it.')
typedef HarborTide = HarborKeyboard;

/// The old name of [HarborKeyboardPhase].
@Deprecated('Renamed HarborKeyboardPhase. `dart fix` applies it.')
typedef HarborTidePhase = HarborKeyboardPhase;

/// The old name of [HarborKeyboardStance].
@Deprecated('Renamed HarborKeyboardStance. `dart fix` applies it.')
typedef HarborTideStance = HarborKeyboardStance;

/// The old name of [HarborKeyboardSpace].
@Deprecated('Renamed HarborKeyboardSpace. `dart fix` applies it.')
typedef HarborDryDock = HarborKeyboardSpace;

/// The old name of [HarborKeyboardSource].
@Deprecated('Renamed HarborKeyboardSource. `dart fix` applies it.')
typedef HarborTideSource = HarborKeyboardSource;

/// The old name of [HarborRoom].
@Deprecated('Renamed HarborRoom. `dart fix` applies it.')
typedef HarborWaters = HarborRoom;

/// The old name of [HarborRoomData].
@Deprecated('Renamed HarborRoomData. `dart fix` applies it.')
typedef HarborWatersData = HarborRoomData;

/// The old name of [HarborRoomAspect].
@Deprecated('Renamed HarborRoomAspect. `dart fix` applies it.')
typedef HarborWatersAspect = HarborRoomAspect;

/// The old name of [HarborHandled].
@Deprecated('Renamed HarborHandled. `dart fix` applies it.')
typedef HarborCastOff = HarborHandled;

/// The old name of [HarborClear].
@Deprecated('Renamed HarborClear. `dart fix` applies it.')
typedef HarborMoored = HarborClear;

/// The old name of [HarborSliverClear].
@Deprecated('Renamed HarborSliverClear. `dart fix` applies it.')
typedef HarborFairwaySliver = HarborSliverClear;

/// The old name of [HarborEdgeEffectKind].
@Deprecated('Renamed HarborEdgeEffectKind. `dart fix` applies it.')
typedef HarborWakeKind = HarborEdgeEffectKind;

/// The old name of [HarborEdgeEffectPainter].
@Deprecated('Renamed HarborEdgeEffectPainter. `dart fix` applies it.')
typedef HarborWakePainter = HarborEdgeEffectPainter;

/// The old name of [HarborToasts].
@Deprecated('Renamed HarborToasts. `dart fix` applies it.')
typedef HarborFlares = HarborToasts;

/// The old name of [HarborToastSlot].
@Deprecated('Renamed HarborToastSlot. `dart fix` applies it.')
typedef HarborFlareSlot = HarborToastSlot;

/// The old name of [HarborToastTarget].
@Deprecated('Renamed HarborToastTarget. `dart fix` applies it.')
typedef HarborFlareTarget = HarborToastTarget;

/// The old name of [HarborToastEntry].
@Deprecated('Renamed HarborToastEntry. `dart fix` applies it.')
typedef HarborFlareEntry = HarborToastEntry;

/// The old name of [HarborToastClosedReason].
@Deprecated('Renamed HarborToastClosedReason. `dart fix` applies it.')
typedef HarborFlareClosedReason = HarborToastClosedReason;

/// The old name of [HarborToastPhase].
@Deprecated('Renamed HarborToastPhase. `dart fix` applies it.')
typedef HarborFlarePhase = HarborToastPhase;

/// The old name of [HarborToastQueue].
@Deprecated('Renamed HarborToastQueue. `dart fix` applies it.')
typedef HarborFlareQueue = HarborToastQueue;

/// The old name of [HarborToastHold].
@Deprecated('Renamed HarborToastHold. `dart fix` applies it.')
typedef HarborFlareHold = HarborToastHold;

/// The old name of [HarborToastTransitionBuilder].
@Deprecated('Renamed HarborToastTransitionBuilder. `dart fix` applies it.')
typedef HarborFlareTransitionBuilder = HarborToastTransitionBuilder;

/// The old name of [HarborPageCover].
@Deprecated('Renamed HarborPageCover. `dart fix` applies it.')
typedef HarborBreakwater = HarborPageCover;

/// The 0.8 name of [HarborKeepInSight], which is split into [HarborCoverageListener],
/// [HarborKeepVisible] and [HarborLift].
@Deprecated(
  'Split into HarborCoverageListener, HarborKeepVisible and HarborLift. `dart fix` applies it to a call that '
  'does one job.'
  ' A file that imports harbor with `show` needs HarborKeepVisible, HarborLift and HarborCoverageListener added after `dart fix`, or the import widened.',
)
typedef HarborBeacon = HarborKeepInSight;

/// The 0.8 name of [HarborKeepInSight], whose statics are [HarborKeepVisible.reveal] and
/// [HarborKeepVisible.coverageOf] now.
@Deprecated(
  'Its statics moved to HarborKeepVisible. `dart fix` applies it.'
  ' A file that imports harbor with `show` needs HarborKeepVisible added after `dart fix`, or the import widened.',
)
typedef HarborLighthouse = HarborKeepInSight;

/// The 0.8 name of [HarborKeepVisibleRegion].
@Deprecated('Renamed HarborKeepVisibleRegion. `dart fix` applies it.')
typedef HarborLighthouseRegion = HarborKeepVisibleRegion;

/// The old name of [HarborInspector].
@Deprecated('Renamed HarborInspector. `dart fix` applies it.')
typedef HarborChart = HarborInspector;

/// The old name of [HarborInspectorOverlay].
@Deprecated('Renamed HarborInspectorOverlay. `dart fix` applies it.')
typedef HarborChartOverlay = HarborInspectorOverlay;

/// The old name of [HarborFrameRegistry].
@Deprecated('Renamed HarborFrameRegistry. `dart fix` applies it.')
typedef HarborFleet = HarborFrameRegistry;

/// The old name of [HarborFrameObserver].
@Deprecated('Renamed HarborFrameObserver. `dart fix` applies it.')
typedef HarborFleetObserver = HarborFrameObserver;

/// The old name of [HarborScaledScreen].
@Deprecated('Renamed HarborScaledScreen. `dart fix` applies it.')
typedef HarborScaleModel = HarborScaledScreen;
