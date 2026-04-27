import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  rustic,
  highContrast,
}

class AppTheme {
  // Configuración de texto común (grande y legible)
  static const TextTheme _commonTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 18),
    bodyMedium: TextStyle(fontSize: 16),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Para botones
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      textTheme: _commonTextTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF121212), // Fondo oscuro no deslumbrante
      ),
      textTheme: _commonTextTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
  }

  static ThemeData get rusticTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513), // Café rústico
        primary: const Color(0xFF8B4513),
        secondary: const Color(0xFFD2691E), // Terracota
        tertiary: const Color(0xFFCD5C5C), // Rojo colonial
        surface: const Color(0xFFF5DEB3), // Trigo/Madera clara
        brightness: Brightness.light,
      ),
      textTheme: _commonTextTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
    );
  }

  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Colors.yellow,
        onPrimary: Colors.black,
        secondary: Colors.cyan,
        onSecondary: Colors.black,
        error: Colors.redAccent,
        onError: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: _commonTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.yellow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56), // Botones grandes
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Colors.white, width: 2), // Borde grueso
          ),
        ),
      ),
    );
  }

  // Estilo base para botones grandes
  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 56), // 56 de alto para touch target accesible
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
  );

  static ThemeData getThemeData(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return lightTheme;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.rustic:
        return rusticTheme;
      case AppThemeMode.highContrast:
        return highContrastTheme;
    }
  }
}
