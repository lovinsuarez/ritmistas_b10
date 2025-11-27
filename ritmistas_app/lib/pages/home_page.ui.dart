import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/admin_atividades_page.dart';
import 'package:ritmistas_app/pages/admin_cadastro_page.dart';
import 'package:ritmistas_app/pages/admin_ranking_page.dart';
import 'package:ritmistas_app/pages/admin_usuarios_page.dart';
import 'package:ritmistas_app/pages/perfil_page.dart';
import 'package:ritmistas_app/pages/ranking_page.dart';
import 'package:ritmistas_app/pages/resgate_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/admin_master_setores_page.dart';
import 'package:ritmistas_app/pages/admin_master_lideres_page.dart';
import 'package:ritmistas_app/pages/admin_aprovacoes_page.dart'; 
import 'package:ritmistas_app/pages/login.dart';

class AppColors {
  static const Color background = Color(0xFF121212); // Preto fundo
  static const Color cardBackground = Color(0xFF1E1E1E); // Cinza escuro cards
  static const Color primaryYellow = Color(0xFFFFD700); // Amarelo Ouro
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}
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

// --- WIDGET AUXILIAR: BARRA DE NAVEGAÇÃO ESTILIZADA ---
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 1)), // Linha sutil no topo
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.background, // Fundo preto
        selectedItemColor: AppColors.primaryYellow, // Ícone ativo amarelo
        unselectedItemColor: Colors.grey, // Ícone inativo cinza
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false, // Esconde texto dos não selecionados (clean)
        elevation: 0,
        items: items,
      ),
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
  int _selectedIndex = 1;

  static const List<Widget> _widgetOptions = <Widget>[
    PerfilPage(),
    ResgatePage(),
    RankingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Usando Scaffold padrão para aplicar o tema escuro global
      appBar: AppBar(
        title: const Text('Ritmistas B10'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Resgate'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Ranking'),
        ],
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
    AdminCadastroPage(),
    AdminAtividadesPage(),
    AdminAprovacoesPage(),
    AdminUsuariosPage(),
    AdminRankingPage(),
    PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LÍDER - B10'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Criar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Atividades'),
          BottomNavigationBarItem(icon: Icon(Icons.notification_important_outlined), activeIcon: Icon(Icons.notification_important), label: 'Aprovar'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Usuários'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Ranking'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
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
    const AdminMasterSetoresPage(),
    const AdminMasterLideresPage(),
    const PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MASTER - B10'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Setores'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Líderes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}