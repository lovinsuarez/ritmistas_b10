// lib/pages/admin_master_setor_detalhe_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importamos a página de ranking para reutilizar o modelo 'RankingEntry'
import 'package:ritmistas_app/pages/ranking_page.dart';

class AdminMasterSetorDetalhePage extends StatefulWidget {
  // Recebe o setor que foi clicado
  final Sector sector;

  const AdminMasterSetorDetalhePage({super.key, required this.sector});

  @override
  State<AdminMasterSetorDetalhePage> createState() =>
      _AdminMasterSetorDetalhePageState();
}

class _AdminMasterSetorDetalhePageState
    extends State<AdminMasterSetorDetalhePage>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        // Mostra o nome do setor no título
        title: Text(widget.sector.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Usuários'),
            Tab(text: 'Ranking'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba 1: Lista de Usuários
          _UsuariosDoSetorView(sectorId: widget.sector.sectorId),
          // Aba 2: Ranking do Setor
          _RankingDoSetorView(sectorId: widget.sector.sectorId),
        ],
      ),
    );
  }
}

// --- WIDGET DA ABA 1: USUÁRIOS DO SETOR ---
class _UsuariosDoSetorView extends StatefulWidget {
  final int sectorId;
  const _UsuariosDoSetorView({required this.sectorId});

  @override
  State<_UsuariosDoSetorView> createState() => _UsuariosDoSetorViewState();
}

class _UsuariosDoSetorViewState extends State<_UsuariosDoSetorView>
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
    // Chama a nova função da API
    return _apiService.getUsersForSector(_token!, widget.sectorId);
  }

  Future<void> _refresh() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
    await _usersFuture;
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
          return const Center(child: Text('Nenhum usuário neste setor.'));
        }
        final users = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isLider = user.role == '1';
              return ListTile(
                leading: Icon(isLider ? Icons.security : Icons.person),
                title: Text(user.username),
                subtitle: Text(user.email),
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

// --- WIDGET DA ABA 2: RANKING DO SETOR ---
class _RankingDoSetorView extends StatefulWidget {
  final int sectorId;
  const _RankingDoSetorView({required this.sectorId});

  @override
  State<_RankingDoSetorView> createState() => _RankingDoSetorViewState();
}

class _RankingDoSetorViewState extends State<_RankingDoSetorView>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _rankingFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _loadRanking();
  }

  Future<Map<String, dynamic>> _loadRanking() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Admin não autenticado.");
    // Chama a nova função da API
    return _apiService.getRankingForSector(_token!, widget.sectorId);
  }

  Future<void> _refresh() async {
    setState(() {
      _rankingFuture = _loadRanking();
    });
    await _rankingFuture;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Nenhum dado de ranking.'));
        }

        final data = snapshot.data!;
        final int myUserId = data['my_user_id'];
        final List<RankingEntry> ranking = (data['ranking'] as List)
            .map((item) => RankingEntry.fromJson(item))
            .toList();

        if (ranking.isEmpty) {
          return const Center(
              child: Text('Nenhum usuário pontuou neste setor.'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final entry = ranking[index];
              final position = index + 1;
              final bool isMe = (entry.userId == myUserId);

              return Card(
                elevation: isMe ? 6.0 : 2.0,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: isMe
                      ? BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  leading: Text(
                    '$positionº',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black,
                    ),
                  ),
                  title: Text(
                    entry.username,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '${entry.totalPoints} pts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
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
