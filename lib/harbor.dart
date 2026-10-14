/// Every edge of the screen, claimed once.
///
/// Each edge is claimed once, by the layer that owns it, and everything inside
/// gets what is left. Bars claim the edges. Content keeps clear of them, runs
/// under them, or reads the room itself, and the keyboard rises over whatever
/// does not ride it.
library;

export 'src/buoy.dart'
    show
        HarborAnchor,
        HarborAnchorClip,
        HarborAnchorPoint,
        HarborBuoy,
        HarborFloat,
        HarborPopover,
        HarborPortalBuoy,
        HarborFlarePolicy,
        HarborToastSlot,
        HarborToastTarget,
        HarborToasts;
export 'src/chart.dart';
export 'src/coast.dart';
export 'src/controller.dart'
    show
        HarborPageCover,
        HarborClaim,
        HarborController,
        HarborBarRecord,
        HarborDockRecord,
        HarborFrameRegistry,
        HarborFrameObserver,
        HarborLayoutRecord,
        HarborAttachedBarHandle,
        HarborToastClosedReason,
        HarborToastEntry,
        HarborToastHold,
        HarborToastPhase,
        HarborToastQueue,
        HarborToastTransitionBuilder,
        HarborYield;
export 'src/deprecated.dart';
export 'src/dialog.dart';
export 'src/dock.dart';
export 'src/dock_slot.dart' show HarborDockSlot;
export 'src/edge.dart';
export 'src/fairway.dart';
export 'src/harbor.dart';
export 'src/hinge.dart' show HarborHinge, HarborPosture;
export 'src/panes.dart';
export 'src/placement.dart' show HarborAligned, HarborAnchorSide, HarborAnchored, HarborCrossAlignment, HarborPlacement;
export 'src/lighthouse.dart';
export 'src/make_way.dart';
export 'src/moored.dart';
export 'src/render_harbor.dart' show HarborSizing;
export 'src/scale_model.dart';
export 'src/sheet.dart' hide HarborNonModalSheetActions, HarborPageSheetHost;
export 'src/sticky.dart';
export 'src/tide.dart'
    show
        HarborKeyboardSpace,
        HarborKeyboard,
        HarborKeyboardPhase,
        HarborKeyboardSource,
        HarborKeyboardStance,
        HarborKeyboardState,
        HarborTideState;
export 'src/wake.dart'
    show
        HarborRest,
        HarborEdgeEffect,
        HarborWake,
        HarborEdgeEffectKind,
        HarborFadeMask,
        HarborWakeMask,
        HarborEdgeEffectPainter,
        harborAlphaWake;
export 'src/waters.dart'
    show HarborHandled, HarborFadeBand, HarborRoom, HarborRoomAspect, HarborRoomData, HarborWakeBand;
