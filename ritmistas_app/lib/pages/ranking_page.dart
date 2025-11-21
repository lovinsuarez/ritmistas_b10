// lib/pages/ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/theme.dart';

// --- Modelo de Dados (Sem Alterações) ---
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

// --- Página Principal do Ranking (com Abas) ---
// ALTERADO: Esta página agora é um DefaultTabController
class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos um DefaultTabController com Scaffold e AppBar para posicionar a TabBar
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Meu Setor"),
              Tab(text: "Geral B10"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RankingListView(isGeral: false),
            RankingListView(isGeral: true),
          ],
        ),
      ),
    );
  }
}

// --- NOVO WIDGET: Lista de Ranking (com o FutureBuilder) ---
// Este widget contém a lógica que você já tinha, mas agora é reutilizável
class RankingListView extends StatefulWidget {
  final bool isGeral; // true = busca ranking geral, false = busca do setor
  const RankingListView({super.key, required this.isGeral});

  @override
  State<RankingListView> createState() => _RankingListViewState();
}

class _RankingListViewState extends State<RankingListView>
    with AutomaticKeepAliveClientMixin {
  // O AutomaticKeepAliveClientMixin mantém o estado da aba
  // (não recarrega a lista toda vez que você troca de aba)

  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _loadRanking();
  }

  // ALTERADO: A lógica de carregar dados agora usa a flag 'isGeral'
  Future<Map<String, dynamic>> _loadRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception("Usuário não autenticado.");
      }

      // Se 'isGeral' for true, chama a API do ranking geral
      if (widget.isGeral) {
        return await _apiService.getGeralRanking(token);
      }
      // Se não, chama a API do ranking do setor
      else {
        return await _apiService.getSectorRanking(token);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshRanking() async {
    setState(() {
      _rankingFuture = _loadRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para o AutomaticKeepAliveClientMixin

    return FutureBuilder<Map<String, dynamic>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        // --- 1. Estado de Carregamento ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- 2. Estado de Erro ---
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Erro ao carregar ranking: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshRanking,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        // --- 3. Estado de Sucesso ---
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final int myUserId = data['my_user_id'] ?? 0;
          final List<RankingEntry> ranking = (data['ranking'] as List)
              .map((item) => RankingEntry.fromJson(item))
              .toList();

          if (ranking.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshRanking,
              child: const Center(
                child: Text('Nenhum usuário no ranking ainda.'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshRanking,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              itemCount: ranking.length,
              itemBuilder: (context, index) {
                final entry = ranking[index];
                final position = index + 1;
                final bool isMe = (entry.userId == myUserId);

                return Card(
                  color: AppColors.cardBackground,
                  elevation: isMe ? 6.0 : 2.0,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: isMe
                        ? const BorderSide(color: AppColors.primaryYellow, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$positionº',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        ],
                      ),
                      title: Text(
                        entry.username,
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                      trailing: Text(
                        '${entry.totalPoints} pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Se algo der errado (ex: sem dados)
        return const Center(child: Text('Nenhum dado encontrado.'));
      },
    );
  }

  // Necessário para o AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;
}
