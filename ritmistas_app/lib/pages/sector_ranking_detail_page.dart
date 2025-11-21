// lib/pages/sector_ranking_detail_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/ranking_page.dart'; // Para usar o RankingEntry e o card estilizado

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
    // Chama o endpoint que já existe (agora precisamos garantir que ele aceite sector_id ou criar um novo)
    // Nota: O endpoint '/ranking/sector' original pegava o primeiro setor.
    // O AdminMaster já tem um endpoint '/admin-master/sectors/{id}/ranking'.
    // Vamos precisar de um endpoint público para o usuário ver o ranking de um setor específico.
    // Por enquanto, vamos assumir que você vai criar esse endpoint ou usar um existente.
    
    // ATENÇÃO: Como o endpoint '/ranking/sector' atual é limitado, 
    // vou sugerir usarmos o endpoint do Admin Master adaptado ou criar um novo.
    // Para não mexer no backend agora, vou usar uma lógica simulada ou 
    // precisaremos adicionar 'getSectorRankingById' no api_service.
    
    return _apiService.getRankingForSector(token, widget.sectorId); 
    // (Essa função 'getRankingForSector' já existe no api_service para o Admin,
    // mas se o backend bloquear usuário comum, teremos que ajustar. Vamos testar.)
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
          }
          
          final data = snapshot.data!;
          final int myUserId = data['my_user_id'] ?? 0;
          final List<RankingEntry> ranking = (data['ranking'] as List)
              .map((item) => RankingEntry.fromJson(item))
              .toList();

          if (ranking.isEmpty) {
            return const Center(child: Text('Nenhum dado de ranking neste setor.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
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
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$positionº',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryYellow),
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