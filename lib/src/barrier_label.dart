/// What a screen reader announces for a dismissible barrier given no label.
///
/// `WidgetsLocalizations` has no string for it, and harbor imports no design
/// library, so this is the English that `DefaultMaterialLocalizations` and
/// `DefaultCupertinoLocalizations` give `modalBarrierDismissLabel`. A barrier
/// with no label at all would lose its tap and dismiss actions for screen
/// readers, which is why `showGeneralDialog` asserts that it has one. Every
/// harbor barrier takes the label it is given first, and this otherwise.
const String harborBarrierDismissLabel = 'Dismiss';
