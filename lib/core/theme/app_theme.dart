import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Colores - Museo Padre Suárez
  static const Color gold = Color(0xFFCBA35C);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color lightBg = Color(0xFFF8F5F2);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Tema Oscuro (Basado fielmente en Figma)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: Colors.black,
        secondary: gold,
        onSecondary: Colors.white,
        surface: darkCard,
        onSurface: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: gold,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Color(0xFFBDBDBD),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Tema Claro (Extrapolado para mantener coherencia)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: gold,
        onPrimary: Colors.white,
        secondary: gold,
        onSecondary: Colors.black,
        surface: lightCard,
        onSurface: Colors.black,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: gold,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.black,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: Color(0xFF757575),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
