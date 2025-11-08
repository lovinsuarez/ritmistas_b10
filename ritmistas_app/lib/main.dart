// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/home_page.dart';
import 'package:ritmistas_app/theme.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ALTERADO: O modo 'registerAdmin' agora é 'registerAdminMaster'
enum AuthMode { login, registerUser, registerAdminMaster }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Estado da tela
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;

  // Serviços e Controladores
  final ApiService _apiService = ApiService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  // ALTERADO: Removido o controller do nome do setor
  // final _sectorNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  // --- FUNÇÕES DE LÓGICA ---

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      // 1. Faz o login e pega o token
      final token = await _apiService.login(email, password);

      // 2. Com o token, busca os dados do usuário (para saber o ROLE)
      final userData = await _apiService.getUsersMe(token);

      // ALTERADO: O backend agora retorna '0' (admin), '1' (lider), '2' (user)
      final String userRole = userData['role'];

      // 3. Salva o token E o role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_role', userRole); // <-- SALVA O ROLE

      // 4. Navega para a HomePage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    bool loginCalled = false;

    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      final username = _usernameController.text;

      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        throw Exception("Email, Senha e Nome são obrigatórios.");
      }
      if (password.length < 8 || password.length > 72) {
        throw Exception("A senha deve ter entre 8 e 72 caracteres.");
      }

      // --- Lógica de Registro (Admin Master ou Usuário) ---
      // ALTERADO: Lógica para o Admin Master
      if (_authMode == AuthMode.registerAdminMaster) {
        // Removemos a verificação do nome do setor
        // final sectorName = _sectorNameController.text;
        // if (sectorName.isEmpty) {
        //   throw Exception("Nome do Setor é obrigatório.");
        // }

        // Chama a nova função de 'registerAdminMaster'
        await _apiService.registerAdminMaster(
          email: email,
          password: password,
          username: username,
          // sectorName: sectorName, <-- Não é mais necessário
        );
      } else {
        // registerUser (Esta lógica permanece a mesma)
        final inviteCode = _inviteCodeController.text;
        if (inviteCode.isEmpty) {
          throw Exception("Código de Convite é obrigatório.");
        }
        await _apiService.registerUser(
          email: email,
          password: password,
          username: username,
          inviteCode: inviteCode,
        );
      }

      // Se o registro funcionou, tenta fazer o login
      if (mounted) {
        _showSuccess('Registro bem-sucedido! Fazendo login...');
        loginCalled = true;
        setState(() => _isLoading = false); // Libera o lock
        await _handleLogin(); // Tenta logar
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted && !loginCalled && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${message.replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  void _switchAuthMode(AuthMode newMode) {
    setState(() {
      _authMode = newMode;
    });
  }

  // --- MÉTODO BUILD (A TELA) ---
  @override
  Widget build(BuildContext context) {
    String title;
    Widget primaryButton;
    List<Widget> formFields;
    Widget secondaryButton;

    switch (_authMode) {
      // --- MODO LOGIN ---
      case AuthMode.login:
        title = 'Login';
        formFields = [
          _buildTextField(
            _emailController,
            'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(_passwordController, 'Senha', obscureText: true),
        ];
        primaryButton = _buildPrimaryButton('Entrar', _handleLogin);
        secondaryButton = Column(
          children: [
            _buildTextButton(
              'Não tem uma conta? Registrar Usuário',
              () => _switchAuthMode(AuthMode.registerUser),
            ),
            // ALTERADO: Texto do botão
            _buildTextButton(
              'Registrar como Admin Master',
              () => _switchAuthMode(AuthMode.registerAdminMaster),
            ),
          ],
        );
        break;

      // --- MODO REGISTRO DE USUÁRIO ---
      case AuthMode.registerUser:
        title = 'Registrar Usuário';
        formFields = [
          _buildTextField(
            _emailController,
            'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(_usernameController, 'Seu Nome'),
          const SizedBox(height: 16),
          _buildTextField(_inviteCodeController, 'Código de Convite'),
          const SizedBox(height: 16),
          _buildTextField(
            _passwordController,
            'Senha',
            obscureText: true,
            helperText: 'Mín 8, máx 72 caracteres',
          ),
        ];
        primaryButton = _buildPrimaryButton(
          'Registrar e Entrar',
          _handleRegister,
        );
        secondaryButton = _buildTextButton(
          'Já tem uma conta? Fazer Login',
          () => _switchAuthMode(AuthMode.login),
        );
        break;

      // --- MODO REGISTRO DE ADMIN MASTER ---
      // ALTERADO: Lógica do formulário de Admin
      case AuthMode.registerAdminMaster:
        title = 'Registrar Admin Master';
        formFields = [
          _buildTextField(
            _emailController,
            'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(_usernameController, 'Seu Nome'),
          const SizedBox(height: 16),
          // REMOVIDO: Campo 'Nome do Setor'
          // _buildTextField(
          //   _sectorNameController,
          //   'Nome do Setor (Ex: Bateria B10)',
          // ),
          // const SizedBox(height: 16),
          _buildTextField(
            _passwordController,
            'Senha',
            obscureText: true,
            helperText: 'Mín 8, máx 72 caracteres',
          ),
        ];
        primaryButton = _buildPrimaryButton(
          'Registrar e Entrar',
          _handleRegister,
        );
        secondaryButton = _buildTextButton(
          'Já tem uma conta? Fazer Login',
          () => _switchAuthMode(AuthMode.login),
        );
        break;
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              // Permite rolar se o teclado abrir
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ...formFields,
                  const SizedBox(height: 24),
                  primaryButton,
                  const SizedBox(height: 16),
                  secondaryButton,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets Helpers ---
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? helperText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        helperText: helperText,
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : onPressed, // Desabilita se estiver carregando
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.black, // Corrigido para o tema
                strokeWidth: 2,
              ),
            )
          : Text(text),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: _isLoading
          ? null
          : onPressed, // Desabilita se estiver carregando
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
