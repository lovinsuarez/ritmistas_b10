// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; 
import 'package:ritmistas_app/pages/home_page.dart' hide AppColors;
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; 

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

  // --- LÓGICA DO GOOGLE ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      String token;
      try {
        token = await _apiService.loginWithGoogle();
      } catch (e) {
        if (e.toString().contains("NEED_INVITE_CODE")) {
          if (!mounted) return;
          final code = await _showInviteCodeDialog();
          if (code == null || code.isEmpty) {
            setState(() => _isLoading = false);
            return;
          }
          token = await _apiService.loginWithGoogle(inviteCode: code);
        } else {
          rethrow;
        }
      }
      
      final userData = await _apiService.getUsersMe(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_role', userData['role']);

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Registro via Google (usa invite code se necessário)
  Future<void> _handleGoogleRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      String? token;
      String invite = _inviteCodeController.text.trim();

      if (invite.isEmpty) {
        final code = await _showInviteCodeDialog();
        if (code == null || code.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }
        invite = code;
      }

      try {
        token = await _apiService.loginWithGoogle(inviteCode: invite);
      } catch (e) {
        final err = e.toString();
        if (err.contains("Cadastro recebido") || err.contains("Pendente")) {
          // Cadastro criado e pendente
          if (mounted) _showSuccess('Cadastro recebido! Aguarde aprovação do Admin Master.');
          setState(() => _authMode = AuthMode.login);
          return;
        } else if (err.contains("NEED_INVITE_CODE")) {
          // Re-pede código
          final code2 = await _showInviteCodeDialog();
          if (code2 == null || code2.isEmpty) return;
          token = await _apiService.loginWithGoogle(inviteCode: code2);
        } else {
          rethrow;
        }
      }

      if (token != null) {
        final userData = await _apiService.getUsersMe(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('user_role', userData['role']);
        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showInviteCodeDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Código de Convite", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Insira o código do sistema (B10-XXXX).", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Código", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text("Confirmar"))
        ],
      ),
    );
  }

  // --- LÓGICA NORMAL ---
  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final token = await _apiService.login(email, password);
      final userData = await _apiService.getUsersMe(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_role', userData['role']);

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();

      if (email.isEmpty || password.isEmpty || username.isEmpty) throw Exception("Preencha tudo.");

      if (_authMode == AuthMode.registerAdminMaster) {
        await _apiService.registerAdminMaster(email: email, password: password, username: username);
      } else {
        final inviteCode = _inviteCodeController.text.trim();
        if (inviteCode.isEmpty) throw Exception("Código obrigatório.");
        await _apiService.registerUser(email: email, password: password, username: username, inviteCode: inviteCode);
      }

      if (mounted) {
        _showSuccess('Registro ok! Aguardando aprovação.');
        setState(() => _authMode = AuthMode.login); // Volta pro login
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceAll("Exception: ", "")), backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
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
            TextButton(onPressed: () => _switchAuthMode(AuthMode.registerUser), child: const Text("Não tem conta? Cadastre-se")),
            TextButton(onPressed: () => _switchAuthMode(AuthMode.registerAdminMaster), child: const Text("Sou Admin Master")),
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
          _buildTextField(_inviteCodeController, 'Código de Convite (B10-...)', Icons.vpn_key_outlined),
        ];
        footer = TextButton(onPressed: () => _switchAuthMode(AuthMode.login), child: const Text("Já tem conta? Faça Login"));
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
        footer = TextButton(onPressed: () => _switchAuthMode(AuthMode.login), child: const Text("Cancelar"));
        break;
    }

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Desenvolvido por ", style: TextStyle(color: Colors.grey, fontSize: 12)),
            InkWell(
              onTap: () => launchUrl(Uri.parse("https://www.instagram.com/dualforge/")), 
              child: Text("DUALFORGE", style: TextStyle(color: AppColors.primaryYellow.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline, decorationColor: AppColors.primaryYellow)),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // IMAGEM DE FUNDO
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=2070&auto=format&fit=crop', 
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.black), 
            ),
          ),
          // GRADIENTE
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.9), Colors.black],
                ),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LOGO
                  Center(
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryYellow, width: 2), boxShadow: [BoxShadow(color: AppColors.primaryYellow.withOpacity(0.2), blurRadius: 20)]),
                      child: ClipOval(
                        child: Image.network(
                          'https://raw.githubusercontent.com/lovinsuarez/ritmistas_b10/main/ritmistas_app/assets/images/logob10.png',
                          height: 120, width: 120, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.music_note, size: 80, color: AppColors.primaryYellow),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryYellow, letterSpacing: 1.5), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  
                  ...fields,
                  
                  const SizedBox(height: 32),
                  
                  // BOTÃO DE AÇÃO PRINCIPAL
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (_authMode == AuthMode.login ? _handleLogin : _handleRegister),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : Text(btnText),
                    ),
                  ),
                  
                  // BOTÃO GOOGLE: disponível no Login e no Registro (usa flows distintos)
                  if (_authMode == AuthMode.login || _authMode == AuthMode.registerUser) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        icon: Image.network('https://cdn-icons-png.flaticon.com/512/2991/2991148.png', height: 24),
                        label: Text(_authMode == AuthMode.login ? "Entrar com Google" : "Cadastrar com Google", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onPressed: _isLoading ? null : (_authMode == AuthMode.login ? _handleGoogleLogin : _handleGoogleRegister),
                      ),
                    )
                  ],
                  
                  const SizedBox(height: 24),
                  footer,
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF2C2C2C), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryYellow)),
      ),
    );
  }
}