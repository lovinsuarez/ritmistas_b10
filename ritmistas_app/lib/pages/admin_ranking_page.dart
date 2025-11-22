// lib/pages/admin_ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:shared_preferences/shared_preferences.dart';

// DEFINIÇÃO LOCAL PARA EVITAR ERRO DE IMPORTAÇÃO
class RankingEntryLocal {
  final int userId;
  final String username;
  final int totalPoints;

  RankingEntryLocal({required this.userId, required this.username, required this.totalPoints});

  factory RankingEntryLocal.fromJson(Map<String, dynamic> json) {
    return RankingEntryLocal(
      userId: json['user_id'],
      username: json['username'],
      totalPoints: json['total_points'],
    );
  }
}

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Não autenticado.");
    return _apiService.getSectorRanking(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          
          if (!snapshot.hasData) return const Center(child: Text("Sem dados.", style: TextStyle(color: Colors.grey)));

          // Usando a classe local
          final List<RankingEntryLocal> ranking = (snapshot.data!['ranking'] as List)
              .map((item) => RankingEntryLocal.fromJson(item))
              .toList();

          if (ranking.isEmpty) return const Center(child: Text("Ranking vazio.", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final entry = ranking[index];
              return Card(
                color: AppColors.cardBackground,
                child: ListTile(
                  leading: Text("#${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  title: Text(entry.username, style: const TextStyle(color: Colors.white)),
                  trailing: Text("${entry.totalPoints} pts", style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}