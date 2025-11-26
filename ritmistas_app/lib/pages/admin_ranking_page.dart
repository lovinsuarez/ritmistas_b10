// lib/pages/admin_ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart'; // Importa os modelos
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Necessário para decodificar a foto

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
    // O Líder vê o ranking do seu setor
    return _apiService.getSectorRanking(token);
  }

  Future<void> _refresh() async {
    setState(() {
      _rankingFuture = _loadRanking();
    });
    await _rankingFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          
          if (!snapshot.hasData) return const Center(child: Text("Sem dados.", style: TextStyle(color: Colors.grey)));

          final List<RankingEntry> ranking = (snapshot.data!['ranking'] as List)
              .map((item) => RankingEntry.fromJson(item))
              .toList();

          if (ranking.isEmpty) {
            return const Center(child: Text("Ranking vazio.", style: TextStyle(color: Colors.grey)));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primaryYellow,
            backgroundColor: Colors.grey[900],
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: ranking.length,
              itemBuilder: (context, index) {
                final entry = ranking[index];
                final position = index + 1;

                // Cores para o Top 3
                Color posColor = Colors.white;
                if (position == 1) posColor = const Color(0xFFFFD700);
                if (position == 2) posColor = const Color(0xFFC0C0C0);
                if (position == 3) posColor = const Color(0xFFCD7F32);

                // Lógica da Imagem (URL ou Base64)
                ImageProvider? imageProvider;
                if (entry.profilePic != null && entry.profilePic!.isNotEmpty) {
                  if (entry.profilePic!.startsWith('http')) {
                    imageProvider = NetworkImage(entry.profilePic!);
                  } else if (entry.profilePic!.startsWith('data:image')) {
                    try {
                      imageProvider = MemoryImage(base64Decode(entry.profilePic!.split(',')[1]));
                    } catch(e) {}
                  }
                }

                return Card(
                  color: AppColors.cardBackground,
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            "#$position", 
                            style: TextStyle(color: posColor, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // FOTO DE PERFIL
                        Container(
                           height: 40, width: 40,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.grey[800],
                             image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null
                           ),
                           child: imageProvider == null ? const Icon(Icons.person, color: Colors.white54) : null,
                        ),
                      ],
                    ),
                    title: Text(
                      // Mostra Apelido se tiver, senão Nome
                      (entry.nickname != null && entry.nickname!.isNotEmpty) ? entry.nickname! : entry.username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      "${entry.totalPoints} pts", 
                      style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold, fontSize: 15)
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}