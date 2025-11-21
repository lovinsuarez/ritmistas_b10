// lib/pages/sector_ranking_detail_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/ranking_page.dart'; // Para usar RankingEntry

class SectorRankingDetailPage extends StatefulWidget {
  final int sectorId;
  final String sectorName;

  const SectorRankingDetailPage({
    super.key,
    required this.sectorId,
    required this.sectorName,
  });

  @override
  State<SectorRankingDetailPage> createState() => _SectorRankingDetailPageState();
}

class _SectorRankingDetailPageState extends State<SectorRankingDetailPage> {
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
    
    // CORREÇÃO: Usando a função nova que busca por ID (a mesma das abas)
    return _apiService.getSpecificSectorRanking(token, widget.sectorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectorName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
          }
          if (snapshot.hasError) {
            // Tratamento melhor de erro para mostrar na tela
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          
          if (!snapshot.hasData) return const Center(child: Text('Sem dados.', style: TextStyle(color: Colors.grey)));

          final data = snapshot.data!;
          final int myUserId = data['my_user_id'] ?? 0;
          final List<RankingEntry> ranking = (data['ranking'] as List)
              .map((item) => RankingEntry.fromJson(item))
              .toList();

          if (ranking.isEmpty) {
            return const Center(child: Text('Nenhum dado de ranking neste setor.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final entry = ranking[index];
              final position = index + 1;
              final bool isMe = (entry.userId == myUserId);

              // Cores para o Top 3
              Color posColor = Colors.white;
              if (position == 1) posColor = const Color(0xFFFFD700);
              if (position == 2) posColor = const Color(0xFFC0C0C0);
              if (position == 3) posColor = const Color(0xFFCD7F32);

              return Card(
                color: AppColors.cardBackground,
                elevation: isMe ? 4.0 : 1.0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: isMe
                      ? const BorderSide(color: AppColors.primaryYellow, width: 1.5)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$positionº',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: posColor,
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
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Text(
                      '${entry.totalPoints} pts',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}