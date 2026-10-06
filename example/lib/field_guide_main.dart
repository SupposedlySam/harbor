import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import 'art/palette.dart';
import 'field_guide/field_guide.dart';

/// The Harbor Field Guide on its own: `fvm flutter run -t lib/field_guide_main.dart`.
void main() => runApp(
  MaterialApp(
    title: 'Harbor Field Guide',
    debugShowCheckedModeBanner: false,
    theme: Palette.theme(),
    builder: (final BuildContext context, final Widget? child) =>
        HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
    home: const FieldGuidePage(),
  ),
);
