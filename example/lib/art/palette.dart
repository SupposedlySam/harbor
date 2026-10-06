import 'package:flutter/material.dart';

/// The harbor's colors.
abstract final class Palette {
  static const Color deepSea = Color(0xFF0B2A4A);
  static const Color sea = Color(0xFF14507A);
  static const Color shallows = Color(0xFF2A86B5);
  static const Color foam = Color(0xFFE8F4FA);
  static const Color plank = Color(0xFF8A5A33);
  static const Color plankDark = Color(0xFF5E3B1F);
  static const Color plankLight = Color(0xFFB07A4B);
  static const Color stone = Color(0xFF6E7378);
  static const Color stoneDark = Color(0xFF4A4E52);
  static const Color rope = Color(0xFFD8B47A);
  static const Color buoyRed = Color(0xFFE2463A);
  static const Color brass = Color(0xFFE9B949);
  static const Color sail = Color(0xFFF7F2E6);
  static const Color night = Color(0xFF07182B);

  static const List<Color> hulls = <Color>[
    Color(0xFFE2463A),
    Color(0xFF2E7D5B),
    Color(0xFFF2C14E),
    Color(0xFF3D5A98),
    Color(0xFFEFEFEF),
    Color(0xFF8E44AD),
    Color(0xFF16A085),
    Color(0xFFD35400),
  ];

  static ThemeData theme() {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: shallows, brightness: Brightness.dark).copyWith(
      surface: deepSea,
      primary: brass,
      onPrimary: night,
      secondary: shallows,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: deepSea,
      useMaterial3: true,
      fontFamily: 'Georgia',
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
