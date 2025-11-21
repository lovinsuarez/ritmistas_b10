// lib/pages/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/main.dart'; // Importa AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _userDataFuture;
  
  // Controlador para o campo de código
  final TextEditingController _codeController = TextEditingController();
  String? _token;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Não autenticado.");
    _token = token; // Guarda o token para usar no joinSector
    return _apiService.getUsersMe(token);
  }

  String _getRoleName(String role) {
    switch (role) {
      case '0': return 'Admin Master';
      case '1': return 'Líder de Setor';
      case '2': return 'Usuário';
      default: return 'Desconhecido';
    }
  }

  // --- FUNÇÃO PARA ENTRAR EM NOVO SETOR ---
  void _showJoinSectorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text("Entrar em Novo Setor", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Insira o código de convite fornecido pelo líder do outro setor.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Código de Convite",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_codeController.text.isEmpty) return;
                Navigator.of(context).pop(); // Fecha o diálogo
                await _handleJoinSector(_codeController.text);
              },
              child: const Text("Entrar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleJoinSector(String code) async {
    if (_token == null) return;
    try {
      await _apiService.joinSector(_token!, code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você entrou no novo setor!"), backgroundColor: Colors.green),
        );
        _codeController.clear();
        // Recarrega a tela para mostrar o novo setor na lista
        setState(() {
          _userDataFuture = _loadUserData();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado encontrado.'));
          }

          final data = snapshot.data!;
          final username = data['username'] ?? 'Nome';
          final email = data['email'] ?? 'email@teste.com';
          final role = data['role'] ?? '2';
          final inviteCode = data['invite_code'];
          
          final int totalPoints = data['total_global_points'] ?? 0;
          final List<dynamic> sectorsPoints = data['points_by_sector'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. Cartão de Perfil ---
                Card(
                  color: AppColors.cardBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primaryYellow,
                          child: const Icon(Icons.person, size: 48, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(_getRoleName(role), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          backgroundColor: AppColors.primaryYellow,
                        ),
                        const SizedBox(height: 8),
                        Text(email, style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // --- 2. Pontuação Geral ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryYellow.withOpacity(0.8), AppColors.primaryYellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryYellow.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PONTUAÇÃO GERAL", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("Total Acumulado", style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                      Text(
                        "$totalPoints pts",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- 3. Detalhamento por Setor ---
                const Text(
                  "MEUS SETORES",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                
                if (sectorsPoints.isNotEmpty) 
                  ...sectorsPoints.map((sector) {
                    return Card(
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.pie_chart, color: AppColors.primaryYellow),
                        ),
                        title: Text(sector['sector_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: Text(
                          "${sector['points']} pts",
                          style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  }).toList()
                else 
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text("Você ainda não pontuou em nenhum setor.", style: TextStyle(color: Colors.grey))),
                  ),

                // --- BOTÃO: ENTRAR EM OUTRO SETOR ---
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showJoinSectorDialog,
                  icon: const Icon(Icons.add_link),
                  label: const Text("Entrar em outro Setor"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // --- 4. Código de Convite (Apenas Líder/Admin) ---
                if (inviteCode != null) ...[
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("CONVITE DO SEU SETOR (LÍDER)", style: TextStyle(color: AppColors.primaryYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  inviteCode,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado!'), backgroundColor: Colors.green));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 80), 
              ],
            ),
          );
        },
      ),
    );
  }
}