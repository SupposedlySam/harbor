/// Every edge of the screen, claimed once.
///
/// Each edge is claimed once, by the layer that owns it, and everything inside
/// gets what is left. Bars claim the edges. Content keeps clear of them, runs
/// under them, or reads the room itself, and the keyboard rises over whatever
/// does not ride it.
library;

export 'src/attached_bar.dart';
export 'src/bar.dart';
export 'src/barrier.dart' show HarborBarrier, HarborSheetBarrier;
export 'src/clear.dart';
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
        HarborToastTiming,
        HarborToastTransitionBuilder,
        HarborYield;
export 'src/defaults.dart' show HarborDefaults, HarborDefaultsScope;
export 'src/deprecated.dart';
export 'src/dialog.dart';
export 'src/dock_slot.dart' show HarborDockSlot;
export 'src/edge.dart';
export 'src/edge_effect.dart'
    show
        HarborRest,
        HarborEdgeEffect,
        HarborWake,
        HarborEdgeEffectKind,
        HarborFadeMask,
        HarborWakeMask,
        HarborEdgeEffectPainter,
        harborAlphaWake;
export 'src/float.dart'
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
export 'src/frame.dart';
export 'src/hide_bar.dart';
export 'src/hinge.dart' show HarborHinge, HarborPosture;
export 'src/inspector.dart';
export 'src/keep_in_sight.dart';
export 'src/keyboard.dart'
    show
        HarborKeyboardSpace,
        HarborKeyboard,
        HarborKeyboardPhase,
        HarborKeyboardSource,
        HarborKeyboardStance,
        HarborKeyboardState,
        HarborTideState;
export 'src/panes.dart';
export 'src/placement.dart' show HarborAligned, HarborAnchorSide, HarborAnchored, HarborCrossAlignment, HarborPlacement;
export 'src/render_frame.dart' show HarborSizing;
export 'src/room.dart' show HarborHandled, HarborFadeBand, HarborRoom, HarborRoomAspect, HarborRoomData, HarborWakeBand;
export 'src/scaled_screen.dart';
export 'src/scroll_view.dart';
export 'src/sheet.dart' hide HarborNonModalSheetActions, HarborPageSheetHost;
export 'src/sticky.dart';
export 'src/system_edges.dart';
