// lib/auth_check.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; 
import 'package:ritmistas_app/pages/home_page.dart' hide AppColors;
import 'package:ritmistas_app/pages/login.dart'; // Importa a página certa
import 'package:ritmistas_app/services/api_service.dart'; // Importa o serviço
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  
  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    // 1. Se não tem token salvo, vai pro login
    if (token == null) return false;

    // 2. AQUI ESTÁ A MUDANÇA:
    // Testamos se o token é válido no servidor atual
    try {
      final api = ApiService();
      await api.getUsersMe(token); // Tenta buscar o perfil
      
      // Se passou daqui, o usuário existe no banco atual. Pode entrar.
      return true; 
    } catch (e) {
      // Se deu erro (401, 404, etc), significa que o banco mudou ou o token expirou.
      // Limpamos a memória para obrigar um novo login.
      await prefs.clear();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        // Tela de carregamento enquanto verifica o servidor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryYellow),
            ),
          );
        }

        // Se retornou true, vai pra Home
        if (snapshot.data == true) {
          return const HomePage();
        }

        // Se retornou false, vai pro Login
        return const LoginPage();
      },
    );
  }
}