// lib/pages/admin_usuarios_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/pages/admin_criar_codigo_page.dart';
import 'package:ritmistas_app/services/api_service.dart';
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
      SnackBar(
        content: Text('Erro: ${message.replaceAll("Exception: ", "")}'),
        backgroundColor: Colors.red,
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
        content: Text(
          'Tem certeza que deseja EXCLUIR ${user.username}? Todos os seus dados (check-ins, pontos) serão perdidos.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteUser(_token!, user.userId);
        _refreshUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Usuário removido."), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo transparente para ver o fundo do app principal
      backgroundColor: Colors.transparent, 
      body: FutureBuilder<List<UserAdminView>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshUsers,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshUsers,
              child: ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('Nenhum usuário encontrado.', style: TextStyle(color: Colors.grey))),
                ],
              ),
            );
          }

          final users = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView.builder(
              // Adicionei padding embaixo para a lista não ficar escondida atrás da barra
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isLider 
                        ? const BorderSide(color: AppColors.primaryYellow, width: 1) 
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isLider ? AppColors.primaryYellow : Colors.grey[800],
                      child: Icon(
                        isLider ? Icons.security : Icons.person,
                        color: isLider ? Colors.black : Colors.white,
                      ),
                    ),
                    title: Text(
                      user.username,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isLider ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      user.email,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    trailing: isUser ? PopupMenuButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: AppColors.cardBackground,
                      itemBuilder: (context) {
                        return <PopupMenuEntry<String>>[
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Excluir Usuário', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ];
                      },
                      onSelected: (value) {
                        if (value == 'delete') _handleDelete(user);
                      },
                    ) : null,
                  ),
                );
              },
            ),
          );
        },
      ),

      // --- AQUI ESTÁ A MUDANÇA DO BOTÃO ---
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Levanta o botão 80px
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdminCriarCodigoPage(),
              ),
            );
          },
          label: const Text('Criar Código'),
          icon: const Icon(Icons.qr_code_2),
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}