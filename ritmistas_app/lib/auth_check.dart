// lib/auth_check.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/home_page.dart';
import 'package:ritmistas_app/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const Color background = Color(0xFF121212); // Preto fundo
  static const Color cardBackground = Color(0xFF1E1E1E); // Cinza escuro cards
  static const Color primaryYellow = Color(0xFFFFD700); // Amarelo Ouro
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    // Se tiver token, retorna true (está logado)
    // Se for nulo, retorna false (não está logado)
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        // 1. Enquanto verifica, mostra uma tela de carregamento (Splash)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryYellow),
            ),
          );
        }

        // 2. Se tem token, vai pra Home
        if (snapshot.data == true) {
          return const HomePage();
        }

        // 3. Se não tem token, vai pro Login
        return const LoginPage();
      },
    );
  }
}