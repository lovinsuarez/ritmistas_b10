// lib/pages/perfil_page.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/admin_user_dashboard_page.dart'; // Reutiliza a tela
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo para os dados do /users/me
class UserData {
  final int userId;
  final String username;
  final String email;
  final String role;
  final int sectorId;
  final String? inviteCode; // <-- ADICIONE ESTA LINHA

  UserData.fromJson(Map<String, dynamic> json)
    : userId = json['user_id'],
      username = json['username'],
      email = json['email'],
      role = json['role'],
      sectorId = json['sector_id'],
      inviteCode = json['invite_code']; // <-- ADICIONE ESTA LINHA
}

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final ApiService _apiService = ApiService();
  late Future<UserData> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserData();
  }

  Future<UserData> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Usuário não autenticado.");

    final data = await _apiService.getUsersMe(token);
    return UserData.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserData>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado de usuário.'));
          }

          final user = snapshot.data!;
          final bool isAdmin = user.role == 'admin';

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Card de Informações (EXISTENTE)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAdmin ? 'Administrador' : 'Usuário',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão para o Extrato (EXISTENTE)
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('Ver meu extrato de pontos'),
                onPressed: () {
                  // ... (código de navegação existente) ...
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdminUserDashboardPage(
                        userId: user.userId,
                        username: user.username,
                      ),
                    ),
                  );
                },
              ),

              // --- NOVO CARD DE CÓDIGO DE CONVITE (SÓ PARA ADMINS) ---
              if (isAdmin && user.inviteCode != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Código de Convite do Setor',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      user.inviteCode!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Copiar código',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: user.inviteCode!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código de convite copiado!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
