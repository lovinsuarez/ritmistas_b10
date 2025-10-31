// lib/pages/admin_atividades_page.dart

import 'dart:convert'; // Para o jsonEncode do QRCode
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'package:qr_flutter/qr_flutter.dart'; // Para gerar QR Code
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAtividadesPage extends StatefulWidget {
  const AdminAtividadesPage({super.key});

  @override
  State<AdminAtividadesPage> createState() => _AdminAtividadesPageState();
}

class _AdminAtividadesPageState extends State<AdminAtividadesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Activity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _loadActivities();
  }

  Future<List<Activity>> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Admin não autenticado.");
    return _apiService.getActivities(token);
  }

  Future<void> _refreshActivities() async {
    setState(() {
      _activitiesFuture = _loadActivities();
    });
  }

  // Função que MOSTRA O QR CODE
  void _showQrCode(BuildContext context, Activity activity) {
    // O JSON que o app do usuário vai ler
    final qrData = jsonEncode({
      "type": "checkin",
      "activity_id": activity.activityId,
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(activity.title),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              // O Widget que renderiza o QR Code
              data: qrData,
              version: QrVersions.auto,
              size: 280,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Adiciona um Scaffold
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
                  Text('Erro: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refreshActivities,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshActivities,
              child: const Center(child: Text('Nenhuma atividade cadastrada.')),
            );
          }

          final activities = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshActivities,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: 8.0,
                bottom: 8.0,
              ), // Adiciona espaço
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                // Formata a data para "31/10/2025 - 19:30"
                final formattedDate = DateFormat(
                  'dd/MM/yyyy - HH:mm',
                ).format(activity.activityDate.toLocal());

                // --- NOVO DESIGN COM CARD ---
                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              activity.type == 'presencial'
                                  ? Icons.location_on
                                  : Icons.laptop_chromebook,
                              color: Colors.grey[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activity.type == 'presencial'
                                  ? activity.address ?? 'Sem endereço'
                                  : 'Online',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${activity.pointsValue} PONTOS',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary, // Amarelo
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Gerar QR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary, // Amarelo
                                foregroundColor: Colors.black, // Texto preto
                              ),
                              onPressed: () {
                                _showQrCode(context, activity);
                              },
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
