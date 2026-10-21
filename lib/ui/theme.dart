import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

class CL {
  static const ink = Color(0xFF2B1B12);
  static const paper = Color(0xFFFFFDF7);
  static const primary = Color(0xFFFF7A59);
  static const sky = Color(0xFFDDF3FF);
  static const blush = Color(0xFFFFE8F0);

  static const palette = <Color>[
    Color(0xFFE53935), Color(0xFFFF7043), Color(0xFFFF9F1C), Color(0xFFFFD23F),
    Color(0xFFFFF3B0), Color(0xFF9BE15D), Color(0xFF43A047), Color(0xFF2EC4B6),
    Color(0xFF4FC3F7), Color(0xFF1E88E5), Color(0xFF5E35B1), Color(0xFFA66CFF),
    Color(0xFFFF8FB1), Color(0xFFF06292), Color(0xFFD9822B), Color(0xFF8D6E63),
    Color(0xFF9E9E9E), Color(0xFF37474F), Color(0xFFFFFFFF),
  ];

  /// Brush diameters in document units (page is 1000 wide).
  static const brushSizes = <double>[14, 28, 48, 80];

  static TextStyle text(double size, {Color color = ink, double weight = 700}) =>
      TextStyle(
        fontFamily: 'Baloo',
        fontSize: size,
        color: color,
        fontVariations: [FontVariation('wght', weight)],
        height: 1.1,
      );

  static Color darker(Color c, [double amount = 0.22]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color lighter(Color c, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
