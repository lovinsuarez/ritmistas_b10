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
    if (_token == null) throw Exception("Líder não autenticado.");

    // ALTERADO: Chamando a nova função correta do ApiService
    return _apiService.getSectorUsers(_token!);
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

  // --- Ações do Líder ---

  // REMOVIDO: A função _handlePromote foi removida.
  // Apenas o Admin Master pode promover.

  // REMOVIDO: A função _handleDemote foi removida.
  // Apenas o Admin Master pode rebaixar.

  // Esta função está CORRETA. O Líder pode remover usuários.
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
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
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
                  Text(
                    'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                  ),
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

                // ALTERADO: A lógica agora checa 'Líder' (role "1")
                // O antigo 'admin' agora é 'lider'
                final bool isLider = user.role == '1';
                final bool isUser = user.role == '2';

                return ListTile(
                  title: Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: isLider ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(user.email),
                  leading: Icon(
                    // ALTERADO: Ícone para Líder
                    isLider ? Icons.security : Icons.person,
                  ),

                  // ALTERADO: O menu de "3 pontinhos"
                  // Só aparece para Usuários (role "2")
                  trailing: isUser
                      ? PopupMenuButton(
                          itemBuilder: (context) {
                            // A única opção para o Líder é 'Excluir'
                            return <PopupMenuEntry<String>>[
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Excluir Usuário',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ];
                          },
                          onSelected: (value) {
                            if (value == 'delete') {
                              _handleDelete(user);
                            }
                          },
                        )
                      : null, // Não mostra menu para outros Líderes
                );
              },
            ),
          );
        },
      ),

      // Este botão está CORRETO. O Líder pode criar códigos.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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
