// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/pages/admin_atividades_page.dart';
import 'package:ritmistas_app/pages/admin_cadastro_page.dart';
import 'package:ritmistas_app/pages/admin_ranking_page.dart';
import 'package:ritmistas_app/pages/admin_usuarios_page.dart';
import 'package:ritmistas_app/pages/perfil_page.dart';
import 'package:ritmistas_app/pages/ranking_page.dart';
import 'package:ritmistas_app/pages/resgate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/main.dart' show LoginPage;
import 'package:ritmistas_app/pages/admin_master_setores_page.dart';
import 'package:ritmistas_app/pages/admin_master_lideres_page.dart';
import 'package:ritmistas_app/pages/admin_aprovacoes_page.dart';
import 'package:ritmistas_app/pages/admin_master_relatorios_page.dart'; 
// IMPORTANTE: Importa a página de ranking do admin master que criamos
import 'package:ritmistas_app/pages/admin_master_ranking_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    await prefs.remove('user_role');

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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleLogout());
          return const Scaffold(body: Center(child: Text("Erro de autenticação.")));
        }

        final String role = snapshot.data!;

        switch (role) {
          case "2": return UserScaffold(onLogout: _handleLogout);
          case "1": return LiderScaffold(onLogout: _handleLogout);
          case "0": return AdminMasterScaffold(onLogout: _handleLogout);
          default:
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleLogout());
            return const Scaffold(body: Center(child: Text("Erro: Role desconhecida.")));
        }
      },
    );
  }
}

// --- WIDGET DA BARRA SUPERIOR COM LOGO ONLINE ---
Widget _buildAppBarTitle(String title) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipOval(
        child: Image.network(
          'https://raw.githubusercontent.com/lovinsuarez/ritmistas_b10/main/ritmistas_app/assets/images/logob10.png',
          height: 30,
          width: 30,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.yellow),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// --- LAYOUT DO USUÁRIO ---
class UserScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const UserScaffold({super.key, required this.onLogout});

  @override
  State<UserScaffold> createState() => _UserScaffoldState();
}

class _UserScaffoldState extends State<UserScaffold> {
  int _selectedIndex = 0; 

  static const List<Widget> _widgetOptions = <Widget>[
    PerfilPage(),
    ResgatePage(),
    RankingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: _buildAppBarTitle('Ritmistas B10'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.person, size: 30, color: Colors.black), 
          Icon(Icons.qr_code_scanner, size: 30, color: Colors.black),
          Icon(Icons.emoji_events, size: 30, color: Colors.black),
        ],
        color: AppColors.primaryYellow,
        buttonBackgroundColor: AppColors.primaryYellow,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// --- LAYOUT DO LÍDER ---
class LiderScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const LiderScaffold({super.key, required this.onLogout});

  @override
  State<LiderScaffold> createState() => _LiderScaffoldState();
}

class _LiderScaffoldState extends State<LiderScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    PerfilPage(),
    AdminCadastroPage(),
    AdminAtividadesPage(),
    AdminAprovacoesPage(),
    AdminUsuariosPage(),
    AdminRankingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: _buildAppBarTitle('LÍDER - B10'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.person, size: 30, color: Colors.black),
          Icon(Icons.add_circle, size: 30, color: Colors.black),
          Icon(Icons.list_alt, size: 30, color: Colors.black),
          Icon(Icons.notification_important, size: 30, color: Colors.black),
          Icon(Icons.group, size: 30, color: Colors.black),
          Icon(Icons.emoji_events, size: 30, color: Colors.black),
        ],
        color: AppColors.primaryYellow,
        buttonBackgroundColor: AppColors.primaryYellow,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// --- LAYOUT DO ADMIN MASTER ---
class AdminMasterScaffold extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminMasterScaffold({super.key, required this.onLogout});

  @override
  State<AdminMasterScaffold> createState() => _AdminMasterScaffoldState();
}

class _AdminMasterScaffoldState extends State<AdminMasterScaffold> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const PerfilPage(),
    const AdminMasterSetoresPage(),
    const AdminMasterLideresPage(),
    const AdminMasterRankingPage(), // Página de ranking do Master
    const AdminMasterRelatoriosPage(), // Relatórios
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: _buildAppBarTitle('MASTER - B10'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.person, size: 30, color: Colors.black),
          Icon(Icons.apartment, size: 30, color: Colors.black),
          Icon(Icons.admin_panel_settings, size: 30, color: Colors.black),
          Icon(Icons.emoji_events, size: 30, color: Colors.black), // Ícone Ranking
          Icon(Icons.assessment, size: 30, color: Colors.black),
        ],
        color: AppColors.primaryYellow,
        buttonBackgroundColor: AppColors.primaryYellow,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}