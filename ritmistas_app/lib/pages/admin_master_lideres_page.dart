// lib/pages/admin_master_lideres_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMasterLideresPage extends StatefulWidget {
  const AdminMasterLideresPage({super.key});

  @override
  State<AdminMasterLideresPage> createState() => _AdminMasterLideresPageState();
}

class _AdminMasterLideresPageState extends State<AdminMasterLideresPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Obrigatório para AutomaticKeepAliveClientMixin
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Promover Usuários'),
            Tab(text: 'Gerenciar Líderes'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              // --- Aba 1: Lista de Usuários para Promover ---
              AllUsersListView(),
              // --- Aba 2: Lista de Líderes para Rebaixar ---
              AllLidersListView(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true; // Mantém o estado das abas
}

// --- WIDGET DA ABA 1: PROMOVER USUÁRIOS ---
class AllUsersListView extends StatefulWidget {
  const AllUsersListView({super.key});
  @override
  State<AllUsersListView> createState() => _AllUsersListViewState();
}

class _AllUsersListViewState extends State<AllUsersListView>
    with AutomaticKeepAliveClientMixin {
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
    if (_token == null) throw Exception("Admin não autenticado.");
    // Chama a nova função que criamos
    return _apiService.getAllUsers(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
    // Espera o futuro terminar para o RefreshIndicator parar de girar
    await _usersFuture;
  }

  Future<void> _handlePromote(UserAdminView user) async {
    if (_token == null) return;
    try {
      await _apiService.promoteUserToLider(_token!, user.userId);
      _refresh(); // Atualiza a lista
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
    super.build(context);
    return FutureBuilder<List<UserAdminView>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum usuário comum encontrado.'));
        }
        final users = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(user.username),
                subtitle: Text(user.email),
                trailing: ElevatedButton(
                  child: const Text('Promover'),
                  onPressed: () => _handlePromote(user),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// --- WIDGET DA ABA 2: GERENCIAR LÍDERES ---
class AllLidersListView extends StatefulWidget {
  const AllLidersListView({super.key});
  @override
  State<AllLidersListView> createState() => _AllLidersListViewState();
}

class _AllLidersListViewState extends State<AllLidersListView>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  late Future<List<UserAdminView>> _lidersFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _lidersFuture = _loadLiders();
  }

  Future<List<UserAdminView>> _loadLiders() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Admin não autenticado.");
    return _apiService.getAllLiders(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _lidersFuture = _loadLiders();
    });
    // Espera o futuro terminar para o RefreshIndicator parar de girar
    await _lidersFuture;
  }

  Future<void> _handleDemote(UserAdminView lider) async {
    if (_token == null) return;
    try {
      await _apiService.demoteLiderToUser(_token!, lider.userId);
      _refresh(); // Atualiza a lista
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
    super.build(context);
    return FutureBuilder<List<UserAdminView>>(
      future: _lidersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhum líder encontrado.'));
        }
        final liders = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: liders.length,
            itemBuilder: (context, index) {
              final lider = liders[index];
              return ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(lider.username),
                subtitle: Text(lider.email),
                trailing: TextButton(
                  child: const Text('Rebaixar',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () => _handleDemote(lider),
                ),
                // TODO: Adicionar lógica de 'Designar Setor' aqui
              );
            },
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
