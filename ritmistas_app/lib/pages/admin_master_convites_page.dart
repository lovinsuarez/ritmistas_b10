// lib/pages/admin_master_convites_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart' show getSystemInvites;

class AdminMasterConvitesPage extends StatefulWidget {
  const AdminMasterConvitesPage({super.key});

  @override
  State<AdminMasterConvitesPage> createState() => _AdminMasterConvitesPageState();
}

class _AdminMasterConvitesPageState extends State<AdminMasterConvitesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Acesso ao Sistema"),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryYellow,
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Gerar Convites"),
            Tab(text: "Aprovar Contas"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GerarConvitesTab(),
          _AprovarContasTab(),
        ],
      ),
    );
  }
}

// --- ABA 1: GERAR CONVITES ---
class _GerarConvitesTab extends StatefulWidget {
  const _GerarConvitesTab();
  @override
  State<_GerarConvitesTab> createState() => _GerarConvitesTabState();
}

class _GerarConvitesTabState extends State<_GerarConvitesTab> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _invitesFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _invitesFuture = _loadInvites();
  }

  Future<List<dynamic>> _loadInvites() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado.");
    return _apiService.getSystemInvites(_token!);
  }

  Future<void> _generateNewCode() async {
    if (_token == null) return;
    try {
      await _apiService.createSystemInvite(_token!);
      setState(() { _invitesFuture = _loadInvites(); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código gerado!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateNewCode,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text("GERAR NOVO CÓDIGO"),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _invitesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
              
              final invites = snapshot.data ?? [];
              if (invites.isEmpty) return const Center(child: Text("Nenhum código ativo.", style: TextStyle(color: Colors.grey)));

              return ListView.builder(
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  return Card(
                    color: AppColors.cardBackground,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.vpn_key, color: AppColors.primaryYellow),
                      title: Text(invite['code'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      subtitle: const Text("Não utilizado", style: TextStyle(color: Colors.green)),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: invite['code']));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiado!"), backgroundColor: Colors.blue));
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- ABA 2: APROVAR CONTAS (Bloqueio Geral) ---
class _AprovarContasTab extends StatefulWidget {
  const _AprovarContasTab();
  @override
  State<_AprovarContasTab> createState() => _AprovarContasTabState();
}

class _AprovarContasTabState extends State<_AprovarContasTab> {
  final ApiService _apiService = ApiService();
  late Future<List<UserAdminView>> _usersFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<UserAdminView>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado.");
    return _apiService.getPendingGlobalUsers(_token!);
  }

  Future<void> _approve(int userId) async {
    try {
      await _apiService.approveGlobalUser(_token!, userId);
      setState(() { _usersFuture = _loadUsers(); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aprovado!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAdminView>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        
        final users = snapshot.data ?? [];
        if (users.isEmpty) return const Center(child: Text("Nenhum usuário pendente.", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              color: AppColors.cardBackground,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person_off, color: Colors.red),
                title: Text(user.username, style: const TextStyle(color: Colors.white)),
                subtitle: Text(user.email, style: const TextStyle(color: Colors.grey)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () => _approve(user.userId),
                  child: const Text("Liberar Acesso", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}