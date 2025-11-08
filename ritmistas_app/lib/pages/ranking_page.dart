// lib/pages/ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // 1. Cria o controlador de Abas
    return DefaultTabController(
      length: 2, // Teremos 2 abas
      child: Column(
        children: [
          // 2. As Abas (Botões)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Cor de fundo
            child: const TabBar(
              tabs: [
                Tab(text: "Meu Setor"),
                Tab(text: "Geral B10"),
              ],
            ),
          ),
          // 3. O Conteúdo (Páginas)
          const Expanded(
            child: TabBarView(
              children: [
                // Aba 1: Ranking do Setor
                // (Chama o novo widget que busca os dados do setor)
                RankingListView(isGeral: false),

                // Aba 2: Ranking Geral
                // (Chama o novo widget que busca os dados gerais)
                RankingListView(isGeral: true),
              ],
            ),
          ),
        ],
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
          final int myUserId = data['my_user_id'];
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
                  elevation: isMe ? 6.0 : 2.0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
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
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
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
