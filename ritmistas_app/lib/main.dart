import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/home_page.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/auth_check.dart';
import 'package:ritmistas_app/pages/login.dart';
// --- 1. DEFINIÇÃO DE CORES E TEMA ---

class AppColors {
  static const Color background = Color(0xFF121212); // Preto fundo
  static const Color cardBackground = Color(0xFF1E1E1E); // Cinza escuro cards
  static const Color primaryYellow = Color(0xFFFFD700); // Amarelo Ouro
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryYellow,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryYellow,
    secondary: AppColors.primaryYellow,
    surface: AppColors.cardBackground,
    background: AppColors.background,
  ),
  fontFamily: 'Roboto',
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryYellow,
      foregroundColor: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryYellow,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
    ),
    hintStyle: const TextStyle(color: Colors.grey),
    prefixIconColor: Colors.grey,
    labelStyle: const TextStyle(color: Colors.white70),
  ),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ritmistas B10',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      // ROTA INICIAL
      home: const AuthCheck(),
      // DEFINIÇÃO DAS ROTAS
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}