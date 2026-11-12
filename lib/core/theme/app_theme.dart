import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color brandOrange = Color(0xFFFF7A1A);
  static const Color ink = Color(0xFF18212F);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: brightness,
    ).copyWith(
      primary: brandOrange,
      secondary: const Color(0xFFFFA45C),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F8FA)
          : const Color(0xFF10141B),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1B222D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: brightness == Brightness.light
                ? const Color(0xFFE9ECF1)
                : const Color(0xFF2B3543),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF2F4F7)
            : const Color(0xFF242D39),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
