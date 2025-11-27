// lib/pages/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/sector_ranking_detail_page.dart';
import 'package:ritmistas_app/pages/editar_perfil_page.dart';
import 'dart:convert'; // Para decodificar Base64

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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Entrar em Novo Setor", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _codeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Código", border: OutlineInputBorder()),
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
      ),
    );
  }

  Future<void> _handleJoinSector(String code) async {
    if (_token == null) return;
    try {
      await _apiService.joinSector(_token!, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entrou no setor!"), backgroundColor: Colors.green));
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

  // --- DIÁLOGO DE INSÍGNIA ---
  void _showBadgeDetails(dynamic badgeData) {
    final b = badgeData['badge'];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.grey[900]!, Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryYellow, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (b['icon_url'] != null && b['icon_url'].toString().isNotEmpty)
                Image.network(b['icon_url'], height: 80, errorBuilder: (c,e,s)=>const Icon(Icons.emoji_events, size: 60, color: AppColors.primaryYellow))
              else
                const Icon(Icons.emoji_events, size: 60, color: AppColors.primaryYellow),
              const SizedBox(height: 16),
              Text(b['name'], style: const TextStyle(color: AppColors.primaryYellow, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(b['description'] ?? "", style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("FECHAR"))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryYellow,
        backgroundColor: Colors.grey[900],
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return ListView(children: [SizedBox(height: 300), Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)))]);
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -------------------------------------------------------
                  // --- NOVO CARD DE PERFIL (DESIGN PREMIUM) ---
                  // -------------------------------------------------------
                  Container(
                    // MUDANÇA 1: Margem reduzida para ficar mais próximo das bordas
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Column(
                      children: [
                        // 1. Capa com Imagem e Avatar Sobreposto
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            // MUDANÇA 2: Capa com a Imagem da URL
                            Container(
                              height: 100,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                image: DecorationImage(
                                  image: NetworkImage("https://media.licdn.com/dms/image/v2/D4D3DAQF8JU9AAHtuBg/image-scale_191_1128/B4DZcimRpxHMAg-/0/1748632149311/bateria_dezorganizada_b10_cover?e=1764835200&v=beta&t=DIb8w0Sh_474p-l-z8y1i4qQ7YlwIItbrasF6alCJAA"),
                                  fit: BoxFit.cover, // Cobre todo o espaço
                                ),
                              ),
                            ),
                            // Avatar
                            Positioned(
                              bottom: -50, 
                              child: Container(
                                padding: const EdgeInsets.all(4), 
                                decoration: const BoxDecoration(
                                  color: AppColors.cardBackground, 
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _getImageProvider(profilePic),
                                  child: (profilePic == null || profilePic.isEmpty)
                                      ? const Icon(Icons.person, size: 50, color: Colors.white54)
                                      : null,
                                ),
                              ),
                            ),
                            // Botão de Editar
                            Positioned(
                              top: 10,
                              right: 10,
                              child: InkWell(
                                onTap: () async {
                                  final bool? updated = await Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => EditarPerfilPage(currentNickname: nickname, currentPhotoUrl: profilePic, currentBirthDate: birthDate))
                                  );
                                  if (updated == true) _refresh();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5), // Fundo um pouco mais escuro para destacar na foto
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        const SizedBox(height: 60), // Espaço para o avatar que desceu

                        // 2. Informações do Usuário
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              if (nickname != null && nickname.isNotEmpty)
                                Text(username, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                              
                              const SizedBox(height: 12),
                              
                              // Chips de Info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryYellow.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.primaryYellow.withOpacity(0.5))
                                    ),
                                    child: Text(
                                      _getRoleName(role).toUpperCase(),
                                      style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  if (birthDate != null) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text("🎈 $birthDate", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ),
                                  ]
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -------------------------------------------------------
                  // RESTO DO CONTEÚDO
                  // -------------------------------------------------------

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // INSÍGNIAS
                        if (badges.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text("CONQUISTAS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: badges.length,
                              itemBuilder: (context, index) {
                                final b = badges[index]['badge'];
                                return GestureDetector(
                                  onTap: () => _showBadgeDetails(badges[index]),
                                  child: Container(
                                    width: 80, 
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground, 
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (b['icon_url'] != null && b['icon_url'].toString().isNotEmpty)
                                           Image.network(b['icon_url'], width: 40, height: 40, errorBuilder: (c,e,s)=>const Icon(Icons.emoji_events, color: AppColors.primaryYellow))
                                        else
                                           const Icon(Icons.emoji_events, color: AppColors.primaryYellow, size: 40),
                                        const SizedBox(height: 6),
                                        Text(b['name'], style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // CARD PONTUAÇÃO GERAL (Estilo Moderno)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.white10, Colors.black]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("RANKING GERAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("Pontos Acumulados", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Text("$totalPoints", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primaryYellow)),
                            ],
                          ),
                        ),

                        // Orçamento (Líder)
                        if (role == '1') ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.5))
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("MEU ORÇAMENTO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text("$pointsBudget pts", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // SETORES
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text("MEUS SETORES", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        
                        if (sectorsPoints.isEmpty) 
                          const Center(child: Text("Nenhum setor vinculado.", style: TextStyle(color: Colors.grey)))
                        else 
                          ...sectorsPoints.map((sector) => Card(
                            color: AppColors.cardBackground,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.circle, size: 12, color: Color.fromRGBO(255, 215, 0, 1)),
                              title: Text(sector['sector_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              trailing: Text("${sector['points']} pts", style: const TextStyle(color: Color.fromRGBO(255, 215, 0, 1), fontSize: 16)),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SectorRankingDetailPage(sectorId: sector['sector_id'], sectorName: sector['sector_name']))),
                            ),
                          )),

                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _showJoinSectorDialog,
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                          child: const Text("Entrar em outro Setor", style: TextStyle(color: Colors.white)),
                        ),
                        
                        // CÓDIGO DE CONVITE (LÍDER)
                        if (inviteCode != null) ...[
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryYellow.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "CÓDIGO DE CONVITE DO SETOR",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Container interno para o código + botão
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          inviteCode,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18, // Fonte um pouco menor para caber códigos longos
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis, // Reticências se for muito grande
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Botão de Copiar Redondo e Bonito
                                      Material(
                                        color: Colors.black, // Botão preto
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: inviteCode));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Código copiado para a área de transferência!'),
                                                backgroundColor: Colors.green,
                                                duration: Duration(seconds: 2),
                                              )
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(Icons.copy, color: AppColors.primaryYellow, size: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                const Text(
                                  "Envie para novos membros entrarem no seu time.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54, fontSize: 11),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}