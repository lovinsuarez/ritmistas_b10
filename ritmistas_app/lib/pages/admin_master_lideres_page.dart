// lib/pages/admin_master_lideres_page.dart

import 'package:flutter/material.dart' hide Badge;
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart'; // <--- ESTE IMPORT RESOLVE O ERRO
import 'package:shared_preferences/shared_preferences.dart';

class AdminMasterLideresPage extends StatefulWidget {
  const AdminMasterLideresPage({super.key});

  @override
  State<AdminMasterLideresPage> createState() => _AdminMasterLideresPageState();
}

class _AdminMasterLideresPageState extends State<AdminMasterLideresPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
      
  late TabController _tabController;
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
        Container(
          color: AppColors.cardBackground,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryYellow,
            labelColor: AppColors.primaryYellow,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Usuários / Insígnias'),
              Tab(text: 'Líderes / Orçamento'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AllUsersListView(
                onUserPromoted: () {
                  _lidersListKey.currentState?._refresh();
                  _tabController.animateTo(1);
                },
              ),
              AllLidersListView(key: _lidersListKey),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true; 
}

// --- ABA 1: LISTA DE USUÁRIOS (Promover + Dar Insígnia) ---
class AllUsersListView extends StatefulWidget {
  final VoidCallback onUserPromoted;
  const AllUsersListView({super.key, required this.onUserPromoted});
  @override
  State<AllUsersListView> createState() => _AllUsersListViewState();
}

class _AllUsersListViewState extends State<AllUsersListView> with AutomaticKeepAliveClientMixin {
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

  // --- DIÁLOGO: DAR INSÍGNIA ---
  Future<void> _showAwardBadgeDialog(UserAdminView user) async {
    // 1. Busca as insígnias disponíveis
    List<Badge> allBadges = [];
    try {
      allBadges = await _apiService.getAllBadges(_token!);
    } catch (e) {
      _showError("Erro ao carregar insígnias: $e");
      return;
    }

    // 2. Validação: Se não tiver insígnias, avisa e para.
    if (allBadges.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Sem Insígnias", style: TextStyle(color: Colors.white)),
            content: const Text("Você precisa criar insígnias primeiro na aba de 'Insígnias'.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendi"))
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // 3. Se tiver insígnias, mostra a lista
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text("Dar Insígnia para ${user.username}", style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              return ListTile(
                leading: (badge.iconUrl != null && badge.iconUrl!.isNotEmpty)
                    ? Image.network(badge.iconUrl!, width: 30, height: 30, errorBuilder: (c,e,s)=>const Icon(Icons.error))
                    : const Icon(Icons.military_tech, color: AppColors.primaryYellow),
                title: Text(badge.name, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx); // Fecha o diálogo
                  try {
                    await _apiService.awardBadge(_token!, user.userId, badge.badgeId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${badge.name} concedida!"), backgroundColor: Colors.green)
                      );
                    }
                  } catch (e) {
                    _showError(e.toString());
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar"))
        ],
      ),
    );
  }

  Future<void> _handlePromote(UserAdminView user) async {
    if (_token == null) return;

    List<Sector> allSectors;
    try {
      allSectors = await _apiService.getAllSectors(_token!);
    } catch (e) {
      _showError("Falha ao buscar setores.");
      return;
    }

    final availableSectors = allSectors.where((s) => s.liderId == null).toList();

    if (availableSectors.isEmpty) {
      _showError("Não há setores sem líder.");
      return;
    }

    final selectedSector = await showDialog<Sector>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Promover ${user.username}', style: const TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableSectors.length,
              itemBuilder: (context, index) {
                final sector = availableSectors[index];
                return ListTile(
                  leading: const Icon(Icons.apartment, color: AppColors.primaryYellow),
                  title: Text(sector.name, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(ctx).pop(sector),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          ],
        );
      },
    );

    if (selectedSector != null) {
      try {
        await _apiService.promoteUserToLider(_token!, user.userId);
        await _apiService.assignLiderToSector(_token!, selectedSector.sectorId, user.userId);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promovido com sucesso!'), backgroundColor: Colors.green));
        }
        _refresh(); 
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        
        final users = snapshot.data ?? [];
        if (users.isEmpty) return const Center(child: Text('Nenhum usuário comum.', style: TextStyle(color: Colors.grey)));

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: AppColors.cardBackground,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                      title: Text(user.username, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(user.email, style: const TextStyle(color: Colors.grey)),
                    ),
                    // BOTÕES DE AÇÃO
                    Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Botão INSÍGNIA
                          TextButton.icon(
                            icon: const Icon(Icons.military_tech, size: 18, color: AppColors.primaryYellow),
                            label: const Text("Insígnia", style: TextStyle(color: AppColors.primaryYellow)),
                            onPressed: () => _showAwardBadgeDialog(user),
                          ),
                          const SizedBox(width: 8),
                          // Botão PROMOVER
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                            onPressed: () => _handlePromote(user),
                            child: const Text('Promover'),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  @override bool get wantKeepAlive => true;
}

// --- ABA 2: LÍDERES (Gerenciar + Dar Orçamento) ---
class AllLidersListView extends StatefulWidget {
  const AllLidersListView({super.key});
  @override
  State<AllLidersListView> createState() => _AllLidersListViewState();
}

class _AllLidersListViewState extends State<AllLidersListView> with AutomaticKeepAliveClientMixin {
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
    await _lidersFuture;
  }

  void _showAddBudgetDialog(UserAdminView lider) {
    final TextEditingController pointsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text("Orçamento para ${lider.username}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Adicionar pontos para o líder distribuir.", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Quantidade", prefixIcon: Icon(Icons.add_circle, color: AppColors.primaryYellow)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final int? points = int.tryParse(pointsCtrl.text);
              if (points == null || points <= 0) return;
              Navigator.pop(ctx);
              try {
                await _apiService.addBudget(_token!, lider.userId, points);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Orçamento adicionado!"), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDemote(UserAdminView lider) async {
    if (_token == null) return;
    try {
      await _apiService.demoteLiderToUser(_token!, lider.userId);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<UserAdminView>>(
      future: _lidersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        
        final liders = snapshot.data ?? [];
        if (liders.isEmpty) return const Center(child: Text('Nenhum líder encontrado.', style: TextStyle(color: Colors.grey)));

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: liders.length,
            itemBuilder: (context, index) {
              final lider = liders[index];
              return Card(
                color: AppColors.cardBackground,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.primaryYellow, child: Icon(Icons.star, color: Colors.black)),
                        title: Text(lider.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(lider.email, style: const TextStyle(color: Colors.grey)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _handleDemote(lider),
                              child: const Text("Rebaixar", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.attach_money, size: 18),
                              label: const Text("Dar Orçamento"),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _showAddBudgetDialog(lider),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  @override bool get wantKeepAlive => true;
}