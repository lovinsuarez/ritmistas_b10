// lib/pages/ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo para os dados do ranking
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
  late Future<Map<String, dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    // Inicia a chamada da API assim que a tela for construída
    _rankingFuture = _loadRanking();
  }

  Future<Map<String, dynamic>> _loadRanking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception("Usuário não autenticado.");
      }
      return await _apiService.getRanking(token);
    } catch (e) {
      // Retorna o erro para o FutureBuilder
      rethrow;
    }
  }

  // Função para recarregar os dados (ex: pull-to-refresh)
  Future<void> _refreshRanking() async {
    setState(() {
      _rankingFuture = _loadRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Adiciona um Scaffold para estrutura
      body: FutureBuilder<Map<String, dynamic>>(
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
                  Text('Erro ao carregar ranking: ${snapshot.error}'),
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
              return const Center(
                child: Text('Nenhum usuário no ranking ainda.'),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshRanking, // Permite "puxar para atualizar"
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 8.0,
                ), // Adiciona espaço
                itemCount: ranking.length,
                itemBuilder: (context, index) {
                  final entry = ranking[index];
                  final position = index + 1;

                  // Destaca o usuário logado
                  final bool isMe = (entry.userId == myUserId);

                  // --- NOVO DESIGN COM CARD ---
                  return Card(
                    elevation: isMe ? 6.0 : 2.0, // Mais sombra se for 'eu'
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      // Borda amarela se for 'eu'
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
                      // Posição (1º, 2º, 3º...)
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
                      // Nome
                      title: Text(
                        entry.username,
                        style: TextStyle(
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      // Pontos
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
      ),
    );
  }
}
