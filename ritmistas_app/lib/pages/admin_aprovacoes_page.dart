// lib/pages/admin_aprovacoes_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAprovacoesPage extends StatefulWidget {
  const AdminAprovacoesPage({super.key});

  @override
  State<AdminAprovacoesPage> createState() => _AdminAprovacoesPageState();
}

class _AdminAprovacoesPageState extends State<AdminAprovacoesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<UserAdminView>> _pendingUsersFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _pendingUsersFuture = _loadPendingUsers();
  }

  Future<List<UserAdminView>> _loadPendingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Líder não autenticado.");
    return _apiService.getPendingUsers(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _pendingUsersFuture = _loadPendingUsers();
    });
    await _pendingUsersFuture;
  }

  Future<void> _handleAction(UserAdminView user, bool approve) async {
    if (_token == null) return;
    try {
      if (approve) {
        await _apiService.approveUser(_token!, user.userId);
      } else {
        await _apiService.rejectUser(_token!, user.userId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve 
              ? '${user.username} aprovado com sucesso!' 
              : '${user.username} foi rejeitado.'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
      _refresh(); // Recarrega a lista
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aprovações Pendentes")),
      body: FutureBuilder<List<UserAdminView>>(
        future: _pendingUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhuma solicitação pendente.'),
                ],
              ),
            );
          }

          final users = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão Rejeitar
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleAction(user, false),
                          tooltip: "Rejeitar",
                        ),
                        // Botão Aprovar
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleAction(user, true),
                          tooltip: "Aprovar",
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
    );
  }
}