/// Sea trials moved to their own package, `harbor_test`.
///
/// They need `flutter_test`, and harbor no longer depends on it, so this
/// library is empty: an app that imports it sees the message below at the
/// import and errors where it uses `pumpSeaTrial` or `HarborTrialDevice`. Add
/// `harbor_test` as a `dev_dependency` and import
/// `package:harbor_test/harbor_test.dart` instead. This library goes in the
/// next release.
@Deprecated(
  'Sea trials moved to package:harbor_test. Run `flutter pub add dev:harbor_test` and import '
  'package:harbor_test/harbor_test.dart instead.',
)
library;
