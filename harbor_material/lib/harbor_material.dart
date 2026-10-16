/// Material for harbor: the pieces a Material app writes by hand around harbor's widgets.
///
/// * [HarborMaterialFrame], a `HarborFrame` on a Material page, in place of a `Scaffold`.
/// * [HarborMaterialBar.appBar], an `AppBar` in a bar, its colour run up behind the status bar.
/// * [HarborMaterialDefaults.of], harbor's defaults from `MaterialLocalizations` and the theme.
/// * [HarborSnackToast] and `context.showSnackToast`, a toast in a `SnackBar`'s look.
/// * [HarborMaterialSheet], [HarborMaterialSheetSurface] and [HarborMaterialDragHandle], a
///   `HarborSheet` in a modal bottom sheet's look.
library;

export 'src/app_bar.dart';
export 'src/defaults.dart';
export 'src/frame.dart';
export 'src/sheet.dart';
export 'src/toast.dart';
