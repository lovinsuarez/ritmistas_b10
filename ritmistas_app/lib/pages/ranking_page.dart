// lib/pages/ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart'; // <--- IMPORTANTE: Traz os modelos
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Para decodificar a foto

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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          final userData = snapshot.data!;
          // Lista de setores onde o usuário tem pontos
          final List<dynamic> userSectors = userData['points_by_sector'] ?? [];

          // --- CONSTRUÇÃO DAS ABAS ---
          List<Widget> myTabs = [const Tab(text: "GERAL B10")];
          List<Widget> myViews = [const RankingListView(type: RankingType.geral)];

          for (var sector in userSectors) {
            myTabs.add(Tab(text: sector['sector_name'].toString().toUpperCase()));
            myViews.add(RankingListView(
              type: RankingType.sector, 
              sectorId: sector['sector_id']
            ));
          }

          return DefaultTabController(
            length: myTabs.length,
            child: Column(
              children: [
                Container(
                  color: AppColors.background,
                  child: TabBar(
                    isScrollable: true,
                    indicatorColor: AppColors.primaryYellow,
                    labelColor: AppColors.primaryYellow,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: myTabs,
                  ),
                ),
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
  final int? sectorId;

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
    super.build(context);

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final entry = ranking[index];
              final position = index + 1;
              final bool isMe = (entry.userId == myUserId);

              Color posColor = Colors.white;
              if (position == 1) posColor = const Color(0xFFFFD700);
              if (position == 2) posColor = const Color(0xFFC0C0C0);
              if (position == 3) posColor = const Color(0xFFCD7F32);
              
              // Helper para imagem
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
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: posColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // FOTO DO USUÁRIO NO RANKING
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Text(
                      "${entry.totalPoints} pts",
                      style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold, fontSize: 15),
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