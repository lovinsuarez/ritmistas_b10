import 'package:flutter/material.dart' hide Badge;
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart' hide Badge; // <--- AGORA O IMPORT ESTÁ AQUI
import 'package:shared_preferences/shared_preferences.dart';

class AdminMasterBadgesPage extends StatefulWidget {
  const AdminMasterBadgesPage({super.key});

  @override
  State<AdminMasterBadgesPage> createState() => _AdminMasterBadgesPageState();
}

class _AdminMasterBadgesPageState extends State<AdminMasterBadgesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Badge>> _badgesFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _badgesFuture = _loadBadges();
  }

  Future<List<Badge>> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado.");
    return _apiService.getAllBadges(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _badgesFuture = _loadBadges();
    });
    await _badgesFuture;
  }
  
  // ... (Resto do código igual, métodos de criar badge e build)
  // Se você precisar do código do build de novo, me avise, 
  // mas a correção principal é o import acima.
  
  // PARA GARANTIR QUE NADA QUEBRE, VOU INCLUIR O BUILD AQUI:
  void _showCreateBadgeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final iconCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Nova Insígnia", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nome")),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Descrição")),
              const SizedBox(height: 10),
              TextField(controller: iconCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "URL Ícone")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _apiService.createBadge(_token!, nameCtrl.text, descCtrl.text, iconCtrl.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Criado!"), backgroundColor: Colors.green));
                _refresh();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Criar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Badge>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          final badges = snapshot.data ?? [];
          if (badges.isEmpty) return const Center(child: Text("Nenhuma insígnia.", style: TextStyle(color: Colors.grey)));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Card(
                color: AppColors.cardBackground,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty)
                      Image.network(badge.iconUrl!, height: 50, width: 50, errorBuilder: (c,e,s) => const Icon(Icons.emoji_events, color: Colors.amber, size: 50))
                    else
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                    const SizedBox(height: 8),
                    Text(badge.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBadgeDialog,
        label: const Text("Nova Insígnia"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: Colors.black,
      ),
    );
  }
}