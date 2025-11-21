import 'package:flutter/material.dart';

// Cores baseadas na sua imagem
class AppColors {
  static const Color background = Color(0xFF121212); // Preto suave
  static const Color cardBackground = Color(0xFF1E1E1E); // Cinza escuro para cartões
  static const Color primaryYellow = Color(0xFFFFD700); // Amarelo Ouro
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}

// Tema Global
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryYellow,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryYellow,
    secondary: AppColors.primaryYellow,
    surface: AppColors.cardBackground,
  ),
  fontFamily: 'Roboto', // Ou outra fonte moderna
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryYellow,
      foregroundColor: Colors.black, // Texto preto no botão amarelo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryYellow,
      side: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Colors.grey),
    prefixIconColor: AppColors.primaryYellow,
  ),
);