// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/home_page.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. DEFINIÇÃO DE CORES E TEMA ---

class AppColors {
  static const Color background = Color(0xFF121212); // Preto fundo
  static const Color cardBackground = Color(0xFF1E1E1E); // Cinza escuro cards
  static const Color primaryYellow = Color(0xFFFFD700); // Amarelo Ouro
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.grey;
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryYellow,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryYellow,
    secondary: AppColors.primaryYellow,
    surface: AppColors.cardBackground,
    background: AppColors.background,
  ),
  fontFamily: 'Roboto',
  
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryYellow,
      foregroundColor: Colors.black,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryYellow,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2C2C2C),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryYellow, width: 1.5),
    ),
    hintStyle: const TextStyle(color: Colors.grey),
    prefixIconColor: Colors.grey,
    labelStyle: const TextStyle(color: Colors.white70),
  ),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ritmistas B10',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

// --- TELA DE LOGIN / REGISTRO ---

enum AuthMode { login, registerUser, registerAdminMaster }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final token = await _apiService.login(email, password);
      final userData = await _apiService.getUsersMe(token);
      final String userRole = userData['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_role', userRole);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    bool loginCalled = false;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        throw Exception("Preencha todos os campos.");
      }

      if (_authMode == AuthMode.registerAdminMaster) {
        await _apiService.registerAdminMaster(
          email: email,
          password: password,
          username: username,
        );
      } else {
        final inviteCode = _inviteCodeController.text.trim();
        if (inviteCode.isEmpty) throw Exception("Código de convite obrigatório.");
        
        await _apiService.registerUser(
          email: email,
          password: password,
          username: username,
          inviteCode: inviteCode,
        );
      }

      if (mounted) {
        _showSuccess('Registro ok! Entrando...');
        loginCalled = true;
        setState(() => _isLoading = false);
        await _handleLogin();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted && !loginCalled) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll("Exception: ", "")),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _switchAuthMode(AuthMode newMode) {
    setState(() {
      _authMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    String btnText;
    List<Widget> fields;
    Widget footer;

    switch (_authMode) {
      case AuthMode.login:
        title = "BEM-VINDO";
        subtitle = "Faça login para acessar sua conta.";
        btnText = "ENTRAR";
        fields = [
          _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, 'Senha', Icons.lock_outline, obscureText: true),
        ];
        footer = Column(
          children: [
            TextButton(
              onPressed: () => _switchAuthMode(AuthMode.registerUser),
              child: const Text("Não tem conta? Cadastre-se"),
            ),
            TextButton(
              onPressed: () => _switchAuthMode(AuthMode.registerAdminMaster),
              child: const Text("Sou Admin Master"),
            ),
          ],
        );
        break;

      case AuthMode.registerUser:
        title = "CRIAR CONTA";
        subtitle = "Junte-se à bateria.";
        btnText = "REGISTRAR";
        fields = [
          _buildTextField(_usernameController, 'Seu Nome', Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, 'Senha', Icons.lock_outline, obscureText: true),
          const SizedBox(height: 16),
          _buildTextField(_inviteCodeController, 'Código de Convite', Icons.vpn_key_outlined),
        ];
        footer = TextButton(
          onPressed: () => _switchAuthMode(AuthMode.login),
          child: const Text("Já tem conta? Faça Login"),
        );
        break;

      case AuthMode.registerAdminMaster:
        title = "ADMIN MASTER";
        subtitle = "Registro administrativo.";
        btnText = "CRIAR ADMIN";
        fields = [
          _buildTextField(_usernameController, 'Seu Nome', Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField(_emailController, 'Email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, 'Senha', Icons.lock_outline, obscureText: true),
        ];
        footer = TextButton(
          onPressed: () => _switchAuthMode(AuthMode.login),
          child: const Text("Cancelar"),
        );
        break;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Imagem de Fundo (Genérica da internet)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1514525253440-b393452e3383?q=80&w=1000&auto=format&fit=crop', 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black), 
            ),
          ),
          // Gradiente
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Conteúdo
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // --- LOGO PELA INTERNET (Link do GitHub) ---
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryYellow, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryYellow.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://raw.githubusercontent.com/lovinsuarez/ritmistas_b10/main/ritmistas_app/assets/images/logob10.png',
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(height: 120, width: 120, child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 120, width: 120, color: Colors.grey[900],
                              child: const Icon(Icons.music_note, size: 50, color: AppColors.primaryYellow),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ...fields,
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : (_authMode == AuthMode.login ? _handleLogin : _handleRegister),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black))
                        : Text(btnText),
                  ),
                  const SizedBox(height: 24),
                  footer,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}