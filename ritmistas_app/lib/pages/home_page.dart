// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/admin_atividades_page.dart';
import 'package:ritmistas_app/pages/admin_cadastro_page.dart';
import 'package:ritmistas_app/pages/admin_ranking_page.dart';
import 'package:ritmistas_app/pages/admin_usuarios_page.dart';
import 'package:ritmistas_app/pages/perfil_page.dart';
import 'package:ritmistas_app/pages/ranking_page.dart';
import 'package:ritmistas_app/pages/resgate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/main.dart'; // Para o LoginPage
import 'package:ritmistas_app/widgets/shared_widgets.dart';
import 'package:ritmistas_app/pages/admin_master_setores_page.dart';
import 'package:ritmistas_app/pages/admin_master_lideres_page.dart';
// NOVO IMPORT: A página de aprovações
import 'package:ritmistas_app/pages/admin_aprovacoes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Guarda o 'role' que buscamos
  late Future<String?> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _getUserRole();
  }

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    // O 'user_role' salvo é "0" (Admin), "1" (Líder), or "2" (Usuário)
    return prefs.getString('user_role');
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role'); // Limpa o role também

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userRoleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Se der erro, desloga o usuário
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogout();
          });
          return const Scaffold(
            body: Center(child: Text("Erro de autenticação.")),
          );
        }

        // --- Decisão com 3 Níveis ---
        final String role = snapshot.data!;

        switch (role) {
          // --- Caso 2: USUÁRIO ---
          case "2":
            return UserScaffold(onLogout: _handleLogout);

          // --- Caso 1: LÍDER ---
          case "1":
            return LiderScaffold(onLogout: _handleLogout);

          // --- Caso 0: ADMIN MASTER ---
          case "0":
            return AdminMasterScaffold(onLogout: _handleLogout);

          // --- Padrão: Desconhecido ---
          default:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleLogout();
            });
            return const Scaffold(
              body: Center(child: Text("Função de usuário desconhecida.")),
            );
        }
      },
    );
  }
}

// --- LAYOUT DO USUÁRIO (role: "2") ---
class UserScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const UserScaffold({super.key, required this.onLogout});

  @override
  State<UserScaffold> createState() => _UserScaffoldState();
}

class _UserScaffoldState extends State<UserScaffold> {
  int _selectedIndex = 1; // Começa em Resgate

  static const List<Widget> _widgetOptions = <Widget>[
    PerfilPage(),
    ResgatePage(),
    RankingPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ritmistas B10',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: widget.onLogout,
        ),
      ],
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Resgate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- LAYOUT DO LÍDER (role: "1") ---
class LiderScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const LiderScaffold({super.key, required this.onLogout});

  @override
  State<LiderScaffold> createState() => _LiderScaffoldState();
}

class _LiderScaffoldState extends State<LiderScaffold> {
  int _selectedIndex = 0; // Começa em Cadastrar

  // ADICIONADA A PÁGINA DE APROVAÇÕES (Índice 2)
  static const List<Widget> _widgetOptions = <Widget>[
    AdminCadastroPage(),
    AdminAtividadesPage(),
    AdminAprovacoesPage(), // <-- NOVA PÁGINA
    AdminUsuariosPage(),
    AdminRankingPage(),
    PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'LÍDER - Ritmistas B10',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: widget.onLogout,
        ),
      ],
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Cadastrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Atividades',
          ),
          // --- NOVO ÍCONE DE APROVAÇÃO ---
          BottomNavigationBarItem(
            icon: Icon(Icons.notification_important),
            label: 'Aprovar',
          ),
          // -------------------------------
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Usuários'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- LAYOUT DO ADMIN MASTER (role: "0") ---
class AdminMasterScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminMasterScaffold({super.key, required this.onLogout});

  @override
  State<AdminMasterScaffold> createState() => _AdminMasterScaffoldState();
}

class _AdminMasterScaffoldState extends State<AdminMasterScaffold> {
  int _selectedIndex = 0; // Começa em Setores

  static final List<Widget> _widgetOptions = <Widget>[
    const AdminMasterSetoresPage(),
    const AdminMasterLideresPage(),
    const PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ADMIN MASTER - Ritmistas B10',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sair',
          onPressed: widget.onLogout,
        ),
      ],
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment), // Ícone para Setores
            label: 'Setores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings), // Ícone para Líderes
            label: 'Líderes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
      ),
    );
  }
}