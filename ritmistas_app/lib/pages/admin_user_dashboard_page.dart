// lib/pages/admin_user_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Para formatar datas

// Modelos de dados para o dashboard
class CheckInDetail {
  final String title;
  final int points;
  final DateTime date;
  CheckInDetail.fromJson(Map<String, dynamic> json)
    : title = json['title'],
      points = json['points'],
      date = DateTime.parse(json['date']);
}

class CodeDetail {
  final String codeString;
  final int points;
  final DateTime date;
  CodeDetail.fromJson(Map<String, dynamic> json)
    : codeString = json['code_string'],
      points = json['points'],
      date = DateTime.parse(json['date']);
}

class UserDashboard {
  final int userId;
  final String username;
  final int totalPoints;
  final List<CheckInDetail> checkins;
  final List<CodeDetail> redeemedCodes;

  UserDashboard.fromJson(Map<String, dynamic> json)
    : userId = json['user_id'],
      username = json['username'],
      totalPoints = json['total_points'],
      checkins = (json['checkins'] as List)
          .map((i) => CheckInDetail.fromJson(i))
          .toList(),
      redeemedCodes = (json['redeemed_codes'] as List)
          .map((i) => CodeDetail.fromJson(i))
          .toList();
}

// --- A Tela ---
class AdminUserDashboardPage extends StatefulWidget {
  final int userId;
  final String username;

  const AdminUserDashboardPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<AdminUserDashboardPage> createState() => _AdminUserDashboardPageState();
}

class _AdminUserDashboardPageState extends State<AdminUserDashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<UserDashboard> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<UserDashboard> _loadDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) throw Exception("Admin não autenticado.");

    final data = await _apiService.getUserDashboard(token, widget.userId);
    return UserDashboard.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard de ${widget.username}')),
      body: FutureBuilder<UserDashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Nenhum dado.'));
          }

          final dashboard = snapshot.data!;
          final dateFormat = DateFormat('dd/MM/yy - HH:mm');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card de Total
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'PONTUAÇÃO TOTAL',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '${dashboard.totalPoints} pts',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lista de Check-ins
              Text(
                'Check-ins (${dashboard.checkins.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              if (dashboard.checkins.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum check-in realizado.'),
                ),
              ...dashboard.checkins.map(
                (checkin) => ListTile(
                  leading: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.green,
                  ),
                  title: Text(checkin.title),
                  subtitle: Text(dateFormat.format(checkin.date.toLocal())),
                  trailing: Text(
                    '+${checkin.points} pts',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Lista de Códigos Resgatados
              Text(
                'Códigos Resgatados (${dashboard.redeemedCodes.length})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              if (dashboard.redeemedCodes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum código resgatado.'),
                ),
              ...dashboard.redeemedCodes.map(
                (code) => ListTile(
                  leading: const Icon(Icons.pin, color: Colors.blue),
                  title: Text(code.codeString),
                  subtitle: Text(dateFormat.format(code.date.toLocal())),
                  trailing: Text(
                    '+${code.points} pts',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
