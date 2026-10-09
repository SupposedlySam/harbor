// The names harbor used before 1.0, kept so code written against them still compiles. Each
// goes at 1.0.

import 'buoy.dart';
import 'controller.dart';

/// The old name of [HarborFlares].
@Deprecated(
  'Use HarborFlares. Signals were renamed flares before 1.0, so they are not mistaken for the signals package.',
)
typedef HarborSignals = HarborFlares;

/// The old name of [HarborFlareSlot].
@Deprecated(
  'Use HarborFlareSlot. Signals were renamed flares before 1.0, so they are not mistaken for the signals package.',
)
typedef HarborSignalSlot = HarborFlareSlot;

/// The old name of [HarborFlareTarget].
@Deprecated(
  'Use HarborFlareTarget. Signals were renamed flares before 1.0, so they are not mistaken for the signals package.',
)
typedef HarborSignalTarget = HarborFlareTarget;

/// The old name of [HarborFlareEntry].
@Deprecated(
  'Use HarborFlareEntry. Signals were renamed flares before 1.0, so they are not mistaken for the signals package.',
)
typedef HarborSignalEntry = HarborFlareEntry;

/// The old name of [HarborFlareTransitionBuilder].
@Deprecated(
  'Use HarborFlareTransitionBuilder. Signals were renamed flares before 1.0, so they are not mistaken for the signals package.',
)
typedef HarborSignalTransitionBuilder = HarborFlareTransitionBuilder;

/// The old name of [HarborFlareClosedReason].
@Deprecated(
  'Use HarborFlareClosedReason. Signals were renamed flares before 1.0, so they are not mistaken for the signals package.',
)
typedef HarborSignalClosedReason = HarborFlareClosedReason;
