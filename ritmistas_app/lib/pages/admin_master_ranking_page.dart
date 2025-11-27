// lib/pages/admin_master_ranking_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMasterRankingPage extends StatefulWidget {
  const AdminMasterRankingPage({super.key});

  @override
  State<AdminMasterRankingPage> createState() => _AdminMasterRankingPageState();
}

class _AdminMasterRankingPageState extends State<AdminMasterRankingPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Sector>> _sectorsFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _sectorsFuture = _loadSectors();
  }

  Future<List<Sector>> _loadSectors() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado.");
    return _apiService.getAllSectors(_token!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fundo transparente para integrar com o tema
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Sector>>(
        future: _sectorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }

          final sectors = snapshot.data ?? [];

          // Monta as abas: Geral + 1 para cada setor
          List<Widget> myTabs = [const Tab(text: "GERAL B10")];
          List<Widget> myViews = [const _AdminRankingList(isGeral: true)];

          for (var sector in sectors) {
            myTabs.add(Tab(text: sector.name.toUpperCase()));
            myViews.add(_AdminRankingList(isGeral: false, sectorId: sector.sectorId));
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
                    tabs: myTabs,
                  ),
                ),
                Expanded(
                  child: TabBarView(children: myViews),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget interno para listar o ranking (Específico para Admin)
class _AdminRankingList extends StatefulWidget {
  final bool isGeral;
  final int? sectorId;
  const _AdminRankingList({required this.isGeral, this.sectorId});

  @override
  State<_AdminRankingList> createState() => _AdminRankingListState();
}

class _AdminRankingListState extends State<_AdminRankingList> with AutomaticKeepAliveClientMixin {
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
    if (token == null) throw Exception("Erro auth");

    if (widget.isGeral) {
      return _apiService.getGeralRanking(token);
    } else {
      return _apiService.getRankingForSector(token, widget.sectorId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final List<RankingEntry> ranking = (snapshot.data!['ranking'] as List)
            .map((item) => RankingEntry.fromJson(item))
            .toList();

        if (ranking.isEmpty) return const Center(child: Text("Sem pontos."));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: ranking.length,
          itemBuilder: (context, index) {
            final entry = ranking[index];
            return Card(
              color: AppColors.cardBackground,
              child: ListTile(
                leading: Text("#${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                title: Text(entry.username, style: const TextStyle(color: Colors.white)),
                trailing: Text("${entry.totalPoints} pts", style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}