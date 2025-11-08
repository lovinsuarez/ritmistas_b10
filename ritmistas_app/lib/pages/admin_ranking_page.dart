// lib/pages/admin_ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/admin_user_dashboard_page.dart'; // Importa a tela de dashboard
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Modelo de dados para o ranking ---
// (Sem alterações, está correto)
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

// --- Definição da Tela ---
class AdminRankingPage extends StatefulWidget {
  const AdminRankingPage({super.key});

  @override
  State<AdminRankingPage> createState() => _AdminRankingPageState();
}

class _AdminRankingPageState extends State<AdminRankingPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _loadRanking();
  }

  Future<Map<String, dynamic>> _loadRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception("Usuário não autenticado.");
      }

      // ALTERADO: Chamando a função correta para o ranking do SETOR
      return await _apiService.getSectorRanking(token);
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
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ALTERADO: Limpa a mensagem de erro
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
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final List<RankingEntry> ranking = (data['ranking'] as List)
                .map((item) => RankingEntry.fromJson(item))
                .toList();

            if (ranking.isEmpty) {
              return const Center(
                child: Text('Nenhum usuário no ranking ainda.'),
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

                  return Card(
                    elevation: 2.0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      onTap: () {
                        // Navega para a nova tela de dashboard
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AdminUserDashboardPage(
                              userId: entry.userId,
                              username: entry.username,
                            ),
                          ),
                        );
                      },
                      leading: Text(
                        '$positionº',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      title: Text(entry.username),
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
          return const Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }
}
