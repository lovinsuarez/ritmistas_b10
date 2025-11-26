// lib/pages/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/sector_ranking_detail_page.dart';
import 'package:ritmistas_app/pages/editar_perfil_page.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // Para formatar a data da conquista

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

  Future<void> _refresh() async {
    setState(() {
      _userDataFuture = _loadUserData();
    });
    await _userDataFuture;
  }

  String _getRoleName(String role) {
    switch (role) {
      case '0': return 'Admin Master';
      case '1': return 'Líder de Setor';
      case '2': return 'Ritmista';
      default: return 'Usuário';
    }
  }

  void _showJoinSectorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text("Entrar em Novo Setor", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _codeController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Código de Convite", border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key, color: AppColors.primaryYellow)),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sucesso!"), backgroundColor: Colors.green));
        _codeController.clear();
        _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    }
  }

  ImageProvider? _getImageProvider(String? profilePic) {
    if (profilePic == null || profilePic.isEmpty) return null;
    if (profilePic.startsWith('http')) {
      return NetworkImage(profilePic);
    } else if (profilePic.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(profilePic.split(',')[1]));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // --- NOVO: MOSTRAR DETALHES DA INSÍGNIA ---
  void _showBadgeDetails(dynamic badgeData) {
    final badge = badgeData['badge']; // Dados da insígnia
    final String dateStr = badgeData['awarded_at']; // Data que ganhou
    final DateTime date = DateTime.parse(dateStr);
    final String formattedDate = DateFormat('dd/MM/yyyy').format(date);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[900]!, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryYellow, width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.primaryYellow.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone Grande
              Container(
                height: 100, width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: AppColors.primaryYellow, width: 2),
                ),
                child: ClipOval(
                  child: (badge['icon_url'] != null && badge['icon_url'].toString().isNotEmpty)
                      ? Image.network(badge['icon_url'], fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.emoji_events, size: 50, color: AppColors.primaryYellow))
                      : const Icon(Icons.emoji_events, size: 50, color: AppColors.primaryYellow),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge['name'].toString().toUpperCase(),
                style: const TextStyle(color: AppColors.primaryYellow, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                badge['description'] ?? "Sem descrição",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Divider(color: Colors.grey, height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text("Conquistado em: $formattedDate", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("FECHAR"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryYellow,
        backgroundColor: Colors.grey[900],
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return ListView(children: [SizedBox(height: 300), Center(child: Text('Erro: ${snapshot.error}', style: TextStyle(color: Colors.white)))]);
            if (!snapshot.hasData) return const Center(child: Text('Nenhum dado.'));

            final data = snapshot.data!;
            final username = data['username'] ?? 'Nome';
            final email = data['email'] ?? 'email@teste.com';
            final role = data['role'] ?? '2';
            final inviteCode = data['invite_code'];
            final int totalPoints = data['total_global_points'] ?? 0;
            final List<dynamic> sectorsPoints = data['points_by_sector'] ?? [];
            final String? nickname = data['nickname'];
            final String? profilePic = data['profile_pic'];
            final String? birthDate = data['birth_date'];
            final List<dynamic> badges = data['badges'] ?? []; // Lista de Insígnias
            final int pointsBudget = data['points_budget'] ?? 0;

            final String displayName = (nickname != null && nickname.isNotEmpty) ? nickname : username;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD PERFIL
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
                              GestureDetector(
                                onTap: () async {
                                  final bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditarPerfilPage(currentNickname: nickname, currentPhotoUrl: profilePic, currentBirthDate: birthDate)));
                                  if (updated == true) _refresh();
                                },
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryYellow, width: 2)),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[800],
                                        backgroundImage: _getImageProvider(profilePic),
                                        child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                                      ),
                                    ),
                                    Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 16, color: Colors.black))
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(displayName.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                              if (nickname != null && nickname.isNotEmpty) Text(username, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Chip(label: Text(_getRoleName(role), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primaryYellow),
                            ],
                          ),
                        ),
                        Positioned(right: 8, top: 8, child: IconButton(icon: const Icon(Icons.edit, color: AppColors.primaryYellow), onPressed: () async {
                           final bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditarPerfilPage(currentNickname: nickname, currentPhotoUrl: profilePic, currentBirthDate: birthDate)));
                           if (updated == true) _refresh();
                        })),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // --- INSÍGNIAS (VISUAL MELHORADO) ---
                  if (badges.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.military_tech, color: AppColors.primaryYellow),
                        const SizedBox(width: 8),
                        Text("CONQUISTAS (${badges.length})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110, // Altura aumentada para caber o card bonito
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: badges.length,
                        itemBuilder: (context, index) {
                          final b = badges[index]['badge'];
                          return GestureDetector(
                            onTap: () => _showBadgeDetails(badges[index]), // Abre o detalhe
                            child: Container(
                              width: 90, 
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground, 
                                borderRadius: BorderRadius.circular(16), 
                                border: Border.all(color: Colors.grey[800]!),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 4))]
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Ícone Circular
                                  Container(
                                    height: 50, width: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primaryYellow, width: 1),
                                      image: (b['icon_url'] != null && b['icon_url'].toString().isNotEmpty) 
                                          ? DecorationImage(image: NetworkImage(b['icon_url']), fit: BoxFit.cover)
                                          : null
                                    ),
                                    child: (b['icon_url'] == null || b['icon_url'].toString().isEmpty) 
                                        ? const Icon(Icons.emoji_events, color: AppColors.primaryYellow) : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    b['name'], 
                                    textAlign: TextAlign.center, 
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold), 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // ---------------------------------------

                  // ORÇAMENTO
                  if (role == '1') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green[900]!.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
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

                  // PONTUAÇÃO GERAL
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryYellow.withOpacity(0.8), AppColors.primaryYellow]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primaryYellow.withOpacity(0.2), blurRadius: 15)]
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

                  const Text("MEUS SETORES", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  if (sectorsPoints.isEmpty) const Center(child: Text("Sem setores.", style: TextStyle(color: Colors.grey)))
                  else ...sectorsPoints.map((sector) {
                    return Card(
                      color: AppColors.cardBackground,
                      child: ListTile(
                        leading: const Icon(Icons.pie_chart, color: AppColors.primaryYellow),
                        title: Text(sector['sector_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

                  const SizedBox(height: 24),

                  if (inviteCode != null) ...[
                    Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.primaryYellow, width: 1)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CONVITE DO SETOR (LÍDER)", style: TextStyle(color: AppColors.primaryYellow, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Text(inviteCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1))),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.white),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: inviteCode));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado!'), backgroundColor: Colors.green));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), 
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}