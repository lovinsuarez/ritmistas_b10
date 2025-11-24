import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/sector_ranking_detail_page.dart';
import 'package:ritmistas_app/pages/editar_perfil_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _userDataFuture;
  final TextEditingController _codeController = TextEditingController();
  String? _token;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Não autenticado.");
    _token = token;
    return _apiService.getUsersMe(token);
  }

  String _getRoleName(String role) {
    switch (role) {
      case '0': return 'Admin Master';
      case '1': return 'Líder de Setor';
      case '2': return 'Usuário';
      default: return 'Desconhecido';
    }
  }

  void _showJoinSectorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text("Entrar em Novo Setor", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Insira o código de convite.", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Código", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (_codeController.text.isEmpty) return;
                Navigator.pop(context);
                await _handleJoinSector(_codeController.text);
              },
              child: const Text("Entrar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleJoinSector(String code) async {
    if (_token == null) return;
    try {
      await _apiService.joinSector(_token!, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entrou no setor!"), backgroundColor: Colors.green));
        _codeController.clear();
        setState(() { _userDataFuture = _loadUserData(); });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: Text('Nenhum dado.'));

          final data = snapshot.data!;
          final username = data['username'] ?? 'Nome';
          final email = data['email'] ?? 'email@teste.com';
          final role = data['role'] ?? '2';
          final inviteCode = data['invite_code'];
          final int totalPoints = data['total_global_points'] ?? 0;
          final List<dynamic> sectorsPoints = data['points_by_sector'] ?? [];
          
          // Dados V3.0
          final String? nickname = data['nickname'];
          final String? profilePic = data['profile_pic'];
          final String? birthDate = data['birth_date'];
          final List<dynamic> badges = data['badges'] ?? [];
          final int pointsBudget = data['points_budget'] ?? 0;

          final String displayName = (nickname != null && nickname.isNotEmpty) ? nickname : username;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- CARD PERFIL ---
                Card(
                  color: AppColors.cardBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryYellow,
                              backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                              child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.black) : null,
                            ),
                            const SizedBox(height: 16),
                            Text(displayName.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                            if (nickname != null && nickname.isNotEmpty) Text(username, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                Chip(label: Text(_getRoleName(role), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primaryYellow),
                                if (birthDate != null) Chip(label: Text("🎂 $birthDate", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.grey[800]),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(email, style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8, top: 8,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primaryYellow),
                          onPressed: () async {
                            final bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditarPerfilPage(currentNickname: nickname, currentPhotoUrl: profilePic, currentBirthDate: birthDate)));
                            if (updated == true) setState(() { _userDataFuture = _loadUserData(); });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- INSÍGNIAS (BADGES) ---
                if (badges.isNotEmpty) ...[
                  const Text("INSÍGNIAS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final b = badges[index]['badge'];
                        return Container(
                          width: 70, margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                              Text(b['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- ORÇAMENTO (Se for Líder) ---
                if (role == '1') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[900]!.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("MEU ORÇAMENTO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("$pointsBudget pts", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // --- PONTUAÇÃO GERAL ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryYellow.withOpacity(0.8), AppColors.primaryYellow]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("GERAL B10", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        Text("Pontos Totais", style: TextStyle(color: Colors.black54)),
                      ]),
                      Text("$totalPoints pts", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- SETORES ---
                const Text("MEUS SETORES", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (sectorsPoints.isEmpty) const Center(child: Text("Sem setores.", style: TextStyle(color: Colors.grey)))
                else ...sectorsPoints.map((sector) {
                  return Card(
                    color: AppColors.cardBackground,
                    child: ListTile(
                      leading: const Icon(Icons.pie_chart, color: AppColors.primaryYellow),
                      title: Text(sector['sector_name'], style: const TextStyle(color: Colors.white)),
                      trailing: Text("${sector['points']} pts", style: const TextStyle(color: AppColors.primaryYellow, fontSize: 16, fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SectorRankingDetailPage(sectorId: sector['sector_id'], sectorName: sector['sector_name']))),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showJoinSectorDialog,
                  icon: const Icon(Icons.add_link),
                  label: const Text("Entrar em outro Setor"),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}