import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:ritmistas_app/main.dart' hide LoginPage; // Esconde para não conflitar
import 'package:ritmistas_app/pages/login_page.dart'; // Importa a página de Login explicitamente

// IMPORTS DAS PÁGINAS
import 'package:ritmistas_app/pages/admin_atividades_page.dart';
import 'package:ritmistas_app/pages/admin_cadastro_page.dart';
import 'package:ritmistas_app/pages/admin_ranking_page.dart';
import 'package:ritmistas_app/pages/admin_usuarios_page.dart';
import 'package:ritmistas_app/pages/perfil_page.dart';
import 'package:ritmistas_app/pages/ranking_page.dart';
import 'package:ritmistas_app/pages/resgate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTS ADMIN MASTER
import 'package:ritmistas_app/pages/admin_master_setores_page.dart';
import 'package:ritmistas_app/pages/admin_master_lideres_page.dart';
import 'package:ritmistas_app/pages/admin_aprovacoes_page.dart';
import 'package:ritmistas_app/pages/admin_master_relatorios_page.dart';
import 'package:ritmistas_app/pages/admin_master_ranking_page.dart';
import 'package:ritmistas_app/pages/admin_master_pontos_page.dart';
import 'package:ritmistas_app/pages/admin_master_badges_page.dart';
import 'package:ritmistas_app/pages/admin_master_convites_page.dart';

// IMPORT SCANNER
import 'package:ritmistas_app/pages/scan_page.dart';

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

  // --- CORREÇÃO DEFINITIVA DO CRASH AO SAIR ---
  Future<void> _handleLogout() async {

    final navigator = Navigator.of(context, rootNavigator: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpa token e role
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
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
          // Se der erro, força o logout seguro
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

Widget _buildAppBarTitle(String title) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipOval(
        child: Image.network(
          'https://raw.githubusercontent.com/lovinsuarez/ritmistas_b10/main/ritmistas_app/assets/images/logoB10.png',
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
          // CORREÇÃO: Removemos a lógica especial do índice 1.
          // Agora ele apenas muda a aba para a ResgatePage, como qualquer outra aba.
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
  int _selectedIndex = 0; // Começa no Perfil

  static const List<Widget> _widgetOptions = <Widget>[
    PerfilPage(),
    // REMOVIDO: AdminCadastroPage(),  <-- Não precisamos mais dessa aba
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
        // REMOVIDO O ÍCONE 'add_circle'
        items: const <Widget>[
          Icon(Icons.person, size: 30, color: Colors.black), // Perfil (0)
          // REMOVIDO: Icon(Icons.add_circle, size: 30, color: Colors.black), // Cadastro
          Icon(Icons.list_alt, size: 30, color: Colors.black), // Atividades (1)
          Icon(Icons.notification_important, size: 30, color: Colors.black), // Aprovar (2)
          Icon(Icons.group, size: 30, color: Colors.black), // Usuários (3)
          Icon(Icons.emoji_events, size: 30, color: Colors.black), // Ranking (4)
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
    const AdminMasterPontosPage(), 
    const AdminMasterRankingPage(), 
    const AdminMasterBadgesPage(),
    const AdminMasterConvitesPage(),
    const AdminMasterRelatoriosPage(),
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
          Icon(Icons.person, size: 30, color: Colors.black), // Perfil
          Icon(Icons.apartment, size: 30, color: Colors.black), // Setores
          Icon(Icons.admin_panel_settings, size: 30, color: Colors.black), // Líderes
          Icon(Icons.stars, size: 30, color: Colors.black), // Pontos
          Icon(Icons.emoji_events, size: 30, color: Colors.black), // Ranking
          Icon(Icons.military_tech, size: 30, color: Colors.black), // Insígnias
          Icon(Icons.vpn_key, size: 30, color: Colors.black), // Convites
          Icon(Icons.assessment, size: 30, color: Colors.black), // Relatórios
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