// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:ritmistas_app/theme.dart'; // Importe suas cores (definidas em theme.dart)

class LoginPage_backup extends StatelessWidget {
  const LoginPage_backup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagem de Fundo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // Troque por uma foto da sua bateria ou instrumentos
                image: NetworkImage('https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=2070&auto=format&fit=crop'), 
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Gradiente Escuro (para o texto aparecer)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
              ),
            ),
          ),
          // 3. Conteúdo
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "RITMISTAS B10",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Organize seus ensaios e domine o ritmo.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Botão Login
                ElevatedButton(
                  onPressed: () {
                    // Navegar para Home
                  },
                  child: const Text("ENTRAR"),
                ),
                const SizedBox(height: 16),
                
                // Botão Registrar
                OutlinedButton(
                  onPressed: () {},
                  child: const Text("CRIAR CONTA"),
                ),
                const SizedBox(height: 24),
                
                // Esqueci a senha / Social
                const Center(
                  child: Text(
                    "Esqueceu sua senha?",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}