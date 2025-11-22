import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart'; // UserDashboard vem daqui
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminUserDashboardPage extends StatefulWidget {
  final int userId;
  final String username;
  const AdminUserDashboardPage({super.key, required this.userId, required this.username});

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
    if (token == null) throw Exception("Não autenticado.");
    
    final data = await _apiService.getUserDashboard(token, widget.userId);
    return UserDashboard.fromJson(data);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard: ${widget.username}")),
      body: FutureBuilder<UserDashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: Text("Sem dados."));

          final dash = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text("TOTAL DE PONTOS", style: TextStyle(color: Colors.grey)),
                      Text("${dash.totalPoints}", style: const TextStyle(fontSize: 40, color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Histórico de Check-ins", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ...dash.checkins.map((c) => ListTile(
                title: Text(c.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(dateFormat.format(c.date), style: const TextStyle(color: Colors.grey)),
                trailing: Text("+${c.points}", style: const TextStyle(color: Colors.green)),
              )),
            ],
          );
        },
      ),
    );
  }
}