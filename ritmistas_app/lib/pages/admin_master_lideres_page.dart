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

  // NOVO: Criamos uma chave para o 'AllLidersListView'
  // Isso permite que a 'AllUsersListView' mande ele recarregar
  final GlobalKey<_AllLidersListViewState> _lidersListKey = GlobalKey();

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
    super.build(context);
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
            children: [
              // --- Aba 1: Lista de Usuários para Promover ---
              AllUsersListView(
                // NOVO: Passa a chave para a outra aba
                onUserPromoted: () {
                  // Manda a aba 'Gerenciar Líderes' recarregar
                  _lidersListKey.currentState?._refresh();
                  // Muda para a aba de líderes
                  _tabController.animateTo(1);
                },
              ),
              // --- Aba 2: Lista de Líderes para Rebaixar ---
              AllLidersListView(
                key: _lidersListKey, // NOVO: Atribui a chave
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// --- WIDGET DA ABA 1: PROMOVER USUÁRIOS ---
class AllUsersListView extends StatefulWidget {
  // NOVO: Função de callback
  final VoidCallback onUserPromoted;

  const AllUsersListView({super.key, required this.onUserPromoted});
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
    return _apiService.getAllUsers(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
    await _usersFuture;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $message'), backgroundColor: Colors.red),
    );
  }

  // --- ALTERADO: Esta função agora abre um diálogo ---
  Future<void> _handlePromote(UserAdminView user) async {
    if (_token == null) return;

    // 1. Busca todos os setores
    List<Sector> allSectors;
    try {
      allSectors = await _apiService.getAllSectors(_token!);
    } catch (e) {
      _showError("Falha ao buscar setores.");
      return;
    }

    // 2. Filtra por setores que AINDA NÃO TÊM LÍDER
    final availableSectors =
        allSectors.where((s) => s.liderId == null).toList();

    if (availableSectors.isEmpty) {
      _showError(
          "Não há setores disponíveis sem líder. Crie um setor primeiro.");
      return;
    }

    // 3. Mostra o diálogo para escolher o setor
    final selectedSector = await showDialog<Sector>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Promover ${user.username}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableSectors.length,
              itemBuilder: (context, index) {
                final sector = availableSectors[index];
                return ListTile(
                  leading: const Icon(Icons.apartment),
                  title: Text(sector.name),
                  onTap: () => Navigator.of(ctx).pop(sector),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    // 4. Se um setor foi selecionado, executa as duas chamadas
    if (selectedSector != null) {
      try {
        // Ação 1: Promove o usuário para Líder
        await _apiService.promoteUserToLider(_token!, user.userId);

        // Ação 2: Designa o novo líder ao setor escolhido
        await _apiService.assignLiderToSector(
          _token!,
          selectedSector.sectorId,
          user.userId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${user.username} foi promovido e agora lidera ${selectedSector.name}!'),
                backgroundColor: Colors.green),
          );
        }

        // Manda a lista de "promover" recarregar (usuário sumirá)
        _refresh();
        // Manda a lista de "líderes" recarregar (usuário aparecerá lá)
        widget.onUserPromoted();
      } catch (e) {
        _showError(e.toString());
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
          return Center(
              child: Text(
                  'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
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

// ALTERADO: Adicionado 'GlobalKey'
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

  // ALTERADO: Esta função agora é PÚBLICA (para a outra aba chamar)
  Future<void> _refresh() async {
    setState(() {
      _lidersFuture = _loadLiders();
    });
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
          return Center(
              child: Text(
                  'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
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
