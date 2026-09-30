import 'package:flutter/material.dart';

/// Verde-petróleo do Genoz (o mesmo da especificação).
const genozSeed = Color(0xFF1F6F5C);

ThemeData genozTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: genozSeed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
  );
}
