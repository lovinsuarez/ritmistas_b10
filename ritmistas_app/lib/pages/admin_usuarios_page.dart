// lib/pages/admin_usuarios_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/admin_criar_codigo_page.dart'; // Importa a tela de criar código
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
  String? _token; // Guarda o token para as ações

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<UserAdminView>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Admin não autenticado.");
    return _apiService.getAdminUsers(_token!);
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
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

  // --- Ações do Admin ---

  void _handlePromote(UserAdminView user) async {
    if (_token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Promoção'),
        content: Text(
          'Tem certeza que deseja promover ${user.username} para Administrador? Esta ação é irreversível.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Promover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.promoteUser(_token!, user.userId);
        _refreshUsers(); // Atualiza a lista
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _handleDemote(UserAdminView user) async {
    if (_token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Rebaixamento'),
        content: Text(
          'Tem certeza que deseja rebaixar ${user.username} para Usuário?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rebaixar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.demoteUser(_token!, user.userId);
        _refreshUsers(); // Atualiza a lista
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _handleDelete(UserAdminView user) async {
    if (_token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja EXCLUIR ${user.username}? Todos os seus dados (check-ins, pontos) serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteUser(_token!, user.userId);
        _refreshUsers(); // Atualiza a lista
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Text('Erro: ${snapshot.error}'),
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
              child: const Center(child: Text('Nenhum usuário encontrado.')),
            );
          }

          final users = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isAdmin = user.role == 'admin';

                return ListTile(
                  title: Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(user.email),
                  leading: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                  ),
                  trailing: PopupMenuButton(
                    // Botão de "3 pontinhos"
                    itemBuilder: (context) {
                      // Lista de opções
                      final options = <PopupMenuEntry<String>>[];

                      // Lógica de Promover / Rebaixar
                      if (isAdmin) {
                        options.add(
                          const PopupMenuItem(
                            value: 'demote',
                            child: Text('Rebaixar para Usuário'),
                          ),
                        );
                      } else {
                        options.add(
                          const PopupMenuItem(
                            value: 'promote',
                            child: Text('Promover a Admin'),
                          ),
                        );
                      }

                      // Opção de Deletar (sempre aparece)
                      options.add(const PopupMenuDivider());
                      options.add(
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Excluir Usuário',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      );

                      return options;
                    },
                    onSelected: (value) {
                      if (value == 'promote') {
                        _handlePromote(user);
                      } else if (value == 'demote') {
                        _handleDemote(user);
                      } else if (value == 'delete') {
                        _handleDelete(user);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),

      // BOTÃO FLUTUANTE (FAB) PARA CRIAR CÓDIGOS
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navega para a nova tela de criação de código
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminCriarCodigoPage(),
            ),
          );
        },
        label: const Text('Criar Código'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary, // Amarelo
        foregroundColor: Colors.black, // Texto preto
      ),
    );
  }
}
