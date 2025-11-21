// lib/pages/ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo de Dados
class RankingEntry {
  final int userId;
  final String username;
  final int totalPoints;

  RankingEntry({
    required this.userId,
    required this.username,
    required this.totalPoints,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      userId: json['user_id'],
      username: json['username'],
      totalPoints: json['total_points'],
    );
  }
}

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  final ApiService _apiService = ApiService();
  
  // Futuro para carregar QUAIS setores o usuário tem
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Não autenticado.");
    return _apiService.getUsersMe(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removemos a AppBar daqui pois ela já existe na HomePage, 
      // mas precisamos de um espaço para a TabBar.
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          // 1. Carregando dados do usuário
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
          }
          
          // 2. Erro ao carregar usuário
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          final userData = snapshot.data!;
          // Lista de setores onde o usuário tem pontos/presença
          final List<dynamic> userSectors = userData['points_by_sector'] ?? [];

          // --- CONSTRUÇÃO DAS ABAS ---
          // Aba 1 sempre fixa: GERAL B10
          List<Widget> myTabs = [const Tab(text: "Geral B10")];
          List<Widget> myViews = [const RankingListView(type: RankingType.geral)];

          // Abas dinâmicas: Uma para cada setor do usuário
          for (var sector in userSectors) {
            myTabs.add(Tab(text: sector['sector_name'].toString().toUpperCase()));
            myViews.add(RankingListView(
              type: RankingType.sector, 
              sectorId: sector['sector_id']
            ));
          }

          // Controlador das Abas
          return DefaultTabController(
            length: myTabs.length,
            child: Column(
              children: [
                // A Barra de Abas (Amarela e Preta)
                Container(
                  color: AppColors.background,
                  child: TabBar(
                    isScrollable: true, // Permite rolar se tiver muitos setores
                    indicatorColor: AppColors.primaryYellow,
                    labelColor: AppColors.primaryYellow,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: myTabs,
                  ),
                ),
                // O Conteúdo das Listas
                Expanded(
                  child: TabBarView(
                    children: myViews,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGET REUTILIZÁVEL PARA A LISTA ---
enum RankingType { geral, sector }

class RankingListView extends StatefulWidget {
  final RankingType type;
  final int? sectorId; // Só usado se type == sector

  const RankingListView({super.key, required this.type, this.sectorId});

  @override
  State<RankingListView> createState() => _RankingListViewState();
}

class _RankingListViewState extends State<RankingListView> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _loadRanking();
  }

  Future<Map<String, dynamic>> _loadRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Efetue login.");

    if (widget.type == RankingType.geral) {
      return _apiService.getGeralRanking(token);
    } else {
      return _apiService.getSpecificSectorRanking(token, widget.sectorId!);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _rankingFuture = _loadRanking();
    });
    await _rankingFuture;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mantém a aba viva ao trocar

    return FutureBuilder<Map<String, dynamic>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text("Erro ao carregar ranking", style: TextStyle(color: Colors.grey[400])),
                TextButton(onPressed: _refresh, child: const Text("Tentar Novamente"))
              ],
            ),
          );
        }

        if (!snapshot.hasData) return const Center(child: Text("Sem dados", style: TextStyle(color: Colors.white)));

        final data = snapshot.data!;
        final int myUserId = data['my_user_id'] ?? 0;
        final List<RankingEntry> ranking = (data['ranking'] as List)
            .map((item) => RankingEntry.fromJson(item))
            .toList();

        if (ranking.isEmpty) {
          return const Center(child: Text("Ninguém pontuou ainda.", style: TextStyle(color: Colors.grey)));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryYellow,
          backgroundColor: Colors.grey[900],
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Espaço em baixo
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final entry = ranking[index];
              final position = index + 1;
              final bool isMe = (entry.userId == myUserId);

              // Cores especiais para o Top 3
              Color posColor = Colors.white;
              if (position == 1) posColor = const Color(0xFFFFD700); // Ouro
              if (position == 2) posColor = const Color(0xFFC0C0C0); // Prata
              if (position == 3) posColor = const Color(0xFFCD7F32); // Bronze

              return Card(
                color: AppColors.cardBackground,
                elevation: isMe ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isMe ? const BorderSide(color: AppColors.primaryYellow, width: 1.5) : BorderSide.none
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            "$positionº",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: posColor
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white54),
                        ),
                      ],
                    ),
                    title: Text(
                      entry.username,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Text(
                      "${entry.totalPoints} pts",
                      style: const TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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