// Temas claro/oscuro con variantes de alto contraste.
// Tipografía y tamaños pensados para lectura fácil (seniors).
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData claro({bool altoContraste = false}) =>
      _base(brillo: Brightness.light, altoContraste: altoContraste);

  static ThemeData oscuro({bool altoContraste = false}) =>
      _base(brillo: Brightness.dark, altoContraste: altoContraste);

  static ThemeData _base({required Brightness brillo, required bool altoContraste}) {
    final esOscuro = brillo == Brightness.dark;
    final ColorScheme esquema;

    if (altoContraste) {
      // Alto contraste: negro/blanco puros + acentos saturados.
      esquema = esOscuro
          ? const ColorScheme.dark(
              surface: Colors.black,
              primary: Colors.yellow,
              onSurface: Colors.white)
          : const ColorScheme.light(
              surface: Colors.white,
              primary: Color(0xFF000B8C),
              onSurface: Colors.black);
    } else {
      esquema = esOscuro
          ? ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.dark)
          : ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.light);
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      // Botones y toques generosos: dedos de adultos mayores.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
