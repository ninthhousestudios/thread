import 'package:flutter/material.dart';

const cardBg = Color(0xF0151015);
const cardBorderColor = Colors.white;
const cardBorderRadius = 16.0;

ThemeData threadTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    iconTheme: const IconThemeData(color: Colors.white70),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xDD1A1520),
      textStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      elevation: 8,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4E9B),
      brightness: Brightness.dark,
    ),
  );
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    border: Border.all(color: cardBorderColor.withValues(alpha: 0.3)),
  );
}
