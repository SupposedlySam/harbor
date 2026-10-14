import 'package:flutter/foundation.dart';

/// The value of a renamed parameter given under either name: [old], its deprecated spelling, or
/// else [current]. When both are given they must agree, so a call that says two things is an
/// assert rather than one of them winning quietly. [current] at [byDefault] counts as not given.
@internal
T renamed<T>(final T? old, final T current, final T byDefault, final String name, final String oldName) {
  assert(
    old == null || identical(current, byDefault) || identical(old, current),
    '$name and the deprecated $oldName disagree. Give $name alone.',
  );
  return old ?? current;
}
