// lib/pages/admin_atividades_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // Importa AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Certifique-se de ter esse pacote

class AdminAtividadesPage extends StatefulWidget {
  const AdminAtividadesPage({super.key});

  @override
  State<AdminAtividadesPage> createState() => _AdminAtividadesPageState();
}

class _AdminAtividadesPageState extends State<AdminAtividadesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Activity>> _activitiesFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _loadActivities();
  }

  Future<List<Activity>> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Líder não autenticado.");
    return _apiService.getActivities(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _activitiesFuture = _loadActivities();
    });
    await _activitiesFuture;
  }

  // Função para mostrar o QR Code em um modal
  void _showQRCode(Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // QR Code precisa de contraste
        title: Text(
          activity.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: QrImageView(
                  data: activity.activityId.toString(), // O dado é o ID da atividade
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Peça para os membros escanearem",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("FECHAR", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formato da data (Ex: 21/11/2025 - 09:09)
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

    return Scaffold(
      // Fundo transparente pois o Scaffold principal já tem cor
      backgroundColor: Colors.transparent,
      
      body: FutureBuilder<List<Activity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erro: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma atividade criada.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final activities = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 80), // Padding em baixo p/ nav bar
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isOnline = activity.type == 'online';

                return Card(
                  color: AppColors.cardBackground, // Fundo Cinza Escuro
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          activity.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Tipo / Endereço
                        Row(
                          children: [
                            Icon(
                              isOnline ? Icons.laptop : Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isOnline ? "Online" : (activity.address ?? "Sem endereço"),
                                style: const TextStyle(color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Data
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              dateFormat.format(activity.activityDate.toLocal()),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(color: Colors.white24),
                        ),

                        // Rodapé: Pontos e Botão
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Pontos
                            Text(
                              "${activity.pointsValue} PONTOS",
                              style: const TextStyle(
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            // Botão com espaçamento corrigido
                            ElevatedButton.icon(
                              onPressed: () => _showQRCode(activity),
                              icon: const Icon(Icons.qr_code_2, size: 20),
                              label: const Text("Gerar QR Code"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryYellow,
                                foregroundColor: Colors.black,
                                // AQUI ESTÁ A CORREÇÃO DO ESPAÇAMENTO:
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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