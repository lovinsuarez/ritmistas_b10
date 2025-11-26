// lib/pages/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/sector_ranking_detail_page.dart';
import 'package:ritmistas_app/pages/editar_perfil_page.dart';
import 'dart:convert';

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

  // --- FUNÇÃO DE RECARREGAR (PUXAR TELA) ---
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
        _refresh(); // Recarrega automaticamente após entrar
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator( // <--- ADICIONADO: Permite puxar para atualizar
        onRefresh: _refresh,
        color: AppColors.primaryYellow,
        backgroundColor: Colors.grey[900],
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            // Se estiver carregando ou com erro, usamos um ListView vazio para permitir o 'Puxar'
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            // Se tiver erro, mostramos o erro mas dentro de um scrollview para poder puxar e tentar de novo
            if (snapshot.hasError) {
               return ListView(
                 physics: const AlwaysScrollableScrollPhysics(),
                 children: [
                   SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                   Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                 ],
               );
            }

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
            final List<dynamic> badges = data['badges'] ?? [];
            final int pointsBudget = data['points_budget'] ?? 0;

            final String displayName = (nickname != null && nickname.isNotEmpty) ? nickname : username;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // <--- IMPORTANTE: Permite scroll mesmo se a tela for pequena
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. Cartão de Perfil ---
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
                              // Lógica para decidir se é URL ou Base64
                              backgroundImage: (profilePic != null && profilePic.isNotEmpty) 
                                  ? (profilePic.startsWith('http') 
                                      ? NetworkImage(profilePic) 
                                      : MemoryImage(base64Decode(profilePic.split(',')[1])) as ImageProvider)
                                  : null,
                              child: (profilePic == null || profilePic.isEmpty) 
                                  ? const Icon(Icons.person, size: 50, color: Colors.black) 
                                  : null,
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
                              if (updated == true) _refresh();
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

                  const SizedBox(height: 24),

                  // --- CÓDIGO DE CONVITE ---
                  if (inviteCode != null) ...[
                    Card(
                      color: AppColors.primaryYellow,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CÓDIGO DE CONVITE DO SETOR", style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Text(inviteCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1))),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.black),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: inviteCode));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado!'), backgroundColor: Colors.green));
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text("Envie para novos membros.", style: TextStyle(color: Colors.black45, fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80), 
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}