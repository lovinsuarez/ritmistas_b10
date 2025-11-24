// lib/pages/admin_usuarios_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/pages/admin_criar_codigo_page.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart'; // Importa os modelos separados
import 'package:shared_preferences/shared_preferences.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  final ApiService _apiService = ApiService();
  late Future<List<UserAdminView>> _usersFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<UserAdminView>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Líder não autenticado.");
    return _apiService.getSectorUsers(_token!);
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
    await _usersFuture;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: ${message.replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
    );
  }

  // --- NOVO: Função para Distribuir Pontos (Orçamento) ---
  void _handleDistributePoints(UserAdminView user) {
    final pointsCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text("Premiar ${user.username}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Estes pontos saem do seu ORÇAMENTO e contam para o Ranking GERAL.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Pontos (ex: 50)", prefixIcon: Icon(Icons.star, color: AppColors.primaryYellow)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Motivo (ex: Bom desempenho)", prefixIcon: Icon(Icons.edit)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (pointsCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              
              try {
                await _apiService.distributePoints(
                  _token!, 
                  user.userId, 
                  int.parse(pointsCtrl.text), 
                  descCtrl.text
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enviado ${pointsCtrl.text} pts para ${user.username}!"), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text("Enviar Pontos"),
          ),
        ],
      ),
    );
  }

  void _handleDelete(UserAdminView user) async {
    if (_token == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
        content: Text('Excluir ${user.username}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('EXCLUIR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteUser(_token!, user.userId);
        _refreshUsers();
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: FutureBuilder<List<UserAdminView>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                  ElevatedButton(onPressed: _refreshUsers, child: const Text('Tentar Novamente')),
                ],
              ),
            );
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshUsers,
              child: ListView(children: const [SizedBox(height: 100), Center(child: Text('Nenhum usuário encontrado.', style: TextStyle(color: Colors.grey)))]),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 80), 
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isLider = user.role == '1';
                final bool isUser = user.role == '2';

                return Card(
                  color: AppColors.cardBackground,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isLider ? const BorderSide(color: AppColors.primaryYellow, width: 1) : BorderSide.none),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLider ? AppColors.primaryYellow : Colors.grey[800],
                            child: Icon(isLider ? Icons.security : Icons.person, color: isLider ? Colors.black : Colors.white),
                          ),
                          title: Text(user.username, style: TextStyle(color: Colors.white, fontWeight: isLider ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text(user.email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          // Menu de exclusão (apenas para usuários)
                          trailing: isUser ? PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            color: AppColors.cardBackground,
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: Colors.red))])),
                            ],
                            onSelected: (v) { if (v == 'delete') _handleDelete(user); },
                          ) : null,
                        ),
                        
                        // --- NOVO: Botão de Premiar (Só aparece se for usuário comum) ---
                        if (isUser) 
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.emoji_events, size: 18),
                                label: const Text("PREMIAR (PONTO GERAL)"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryYellow,
                                  side: const BorderSide(color: AppColors.primaryYellow, width: 1),
                                ),
                                onPressed: () => _handleDistributePoints(user),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminCriarCodigoPage())),
          label: const Text('Criar Código'),
          icon: const Icon(Icons.qr_code_2),
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}