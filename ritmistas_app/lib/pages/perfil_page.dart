// lib/pages/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar para a área de transferência
import 'package:ritmistas_app/services/api_service.dart'; // Para pegar o modelo UserResponse
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Não autenticado.");
    return _apiService.getUsersMe(token);
  }

  String _getRoleName(String role) {
    switch (role) {
      case '0':
        return 'Admin Master';
      case '1':
        return 'Líder de Setor';
      case '2':
        return 'Usuário';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A AppBar já é fornecida pelo Scaffold principal (Home), mas se esta for uma tab,
      // o conteúdo rolável funciona bem.
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final data = snapshot.data!;
          final username = data['username'] ?? 'Nome';
          final email = data['email'] ?? 'email@teste.com';
          final role = data['role'] ?? '2';
          // O backend envia 'invite_code' se for Líder ou Admin
          final inviteCode = data['invite_code']; 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Cartão de Informações Pessoais ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Ícone ou Avatar
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            _getRoleName(role),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.black87,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // --- Cartão de Código de Convite (SÓ PARA LÍDERES/ADMINS) ---
                if (inviteCode != null) ...[
                  Card(
                    color: Colors.amber[50], // Um fundo levemente amarelo para destacar
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CÓDIGO DE CONVITE DO SETOR",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  inviteCode,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: "Copiar Código",
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Código copiado!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Envie este código para novos membros entrarem no seu setor.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- Botão de Ver Extrato (Padrão) ---
                // (Opcional: você pode manter ou remover se já tiver isso em outro lugar)
                // ElevatedButton.icon( ... ) 
              ],
            ),
          );
        },
      ),
    );
  }
}