import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

  // --- NOVO: Variáveis de estado ---
  final ApiService _apiService = ApiService();
  String? _token;
  bool _leaderChanged =
      false; // Controla se a página anterior precisa recarregar

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadToken();
  }

  // NOVO: Função para carregar o token
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- NOVO: Lógica para designar o líder ---
  Future<void> _showAssignLeaderDialog() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro: Não autenticado.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // 1. Busca todos os líderes disponíveis
    List<UserAdminView> allLiders = [];
    try {
      allLiders = await _apiService.getAllLiders(_token!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao buscar líderes: $e'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    // 2. Mostra o diálogo
    final selectedLider = await showDialog<UserAdminView>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Designar Líder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allLiders.length,
              itemBuilder: (context, index) {
                final lider = allLiders[index];
                return ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: Text(lider.username),
                  subtitle: Text(lider.email),
                  onTap: () {
                    // Retorna o líder selecionado
                    Navigator.of(ctx).pop(lider);
                  },
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

    // 3. Se um líder foi selecionado, chama a API
    if (selectedLider != null) {
      try {
        await _apiService.assignLiderToSector(
          _token!,
          widget.sector.sectorId,
          selectedLider.userId,
        );

        setState(() {
          _leaderChanged = true; // Marca que uma mudança foi feita
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${selectedLider.username} agora é o líder de ${widget.sector.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao designar líder: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // NOVO: Adiciona o WillPopScope para 'avisar' a página anterior
    // quando ela precisar recarregar.
    return WillPopScope(
      onWillPop: () async {
        // Ao clicar em 'Voltar', retorna 'true' se o líder mudou
        Navigator.of(context).pop(_leaderChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          // Mostra o nome do setor no título
          title: Text(widget.sector.name),
          // NOVO: Botão de Ação
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Designar Líder',
              onPressed: _showAssignLeaderDialog,
            ),
          ],
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
          return Center(
              child: Text(
                  'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
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
                title: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: isLider ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
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
          return Center(
              child: Text(
                  'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
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
