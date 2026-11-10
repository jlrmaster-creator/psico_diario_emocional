import 'package:flutter/material.dart';

/// Utilidades visuales para los grupos emocionales.
class EmotionStyle {
  EmotionStyle._();

  static Color colorFromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? const Color(0xFF7A8B99) : Color(parsed);
  }

  /// Fondo suave para tarjetas y chips.
  static Color softBackground(Color color) =>
      Color.alphaBlend(color.withValues(alpha: 0.12), Colors.white);

  /// Color de texto legible sobre el color indicado.
  static Color foregroundOn(Color color) {
    return color.computeLuminance() > 0.55
        ? const Color(0xFF2B2B2B)
        : Colors.white;
  }

  static IconData iconFor(String name) {
    switch (name) {
      case 'sentiment_very_dissatisfied':
        return Icons.sentiment_very_dissatisfied_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'nights_stay':
        return Icons.nights_stay_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.mood_rounded;
    }
  }
}
