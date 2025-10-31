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

        // --- Decisão: Admin ou Usuário? ---
        final String role = snapshot.data!;

        if (role == 'admin') {
          return AdminScaffold(onLogout: _handleLogout);
        } else {
          return UserScaffold(onLogout: _handleLogout);
        }
      },
    );
  }
}

// --- LAYOUT DO USUÁRIO ---
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ritmistas B10'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
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
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- LAYOUT DO ADMIN ---
class AdminScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminScaffold({super.key, required this.onLogout});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0; // Começa em Cad. Atividades

  // As 4 telas do Admin (mais a de Perfil)
  static const List<Widget> _widgetOptions = <Widget>[
    AdminCadastroPage(),
    AdminAtividadesPage(),
    AdminUsuariosPage(),
    AdminRankingPage(),
    PerfilPage(), // Reutiliza a página de Perfil
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN - Ritmistas B10'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Força 5 itens a aparecerem
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Cadastrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Atividades',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Usuários'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
