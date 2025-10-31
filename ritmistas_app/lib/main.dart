// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/home_page.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.amber,
          brightness: Brightness.light,
          background: Colors.grey[100],
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.grey,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

// --- TELA DE LOGIN / REGISTRO ---

// Define os 3 modos da tela
enum AuthMode { login, registerUser, registerAdmin }

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
  final _sectorNameController = TextEditingController();
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
      final String userRole = userData['role']; // 'admin' ou 'user'

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

      // --- Lógica de Registro (Admin ou Usuário) ---
      if (_authMode == AuthMode.registerAdmin) {
        final sectorName = _sectorNameController.text;
        if (sectorName.isEmpty) {
          throw Exception("Nome do Setor é obrigatório.");
        }
        await _apiService.registerAdmin(
          email: email,
          password: password,
          username: username,
          sectorName: sectorName,
        );
      } else {
        // registerUser
        final inviteCode = _inviteCodeController.text;
        if (inviteCode.isEmpty) {
          throw Exception("Código de Convite é obrigatório.");
        }
        // Chama a nova função
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
          ), // <-- CORRIGIDO
          const SizedBox(height: 16),
          _buildTextField(
            _passwordController,
            'Senha',
            obscureText: true,
          ), // <-- CORRIGIDO
        ];
        primaryButton = _buildPrimaryButton('Entrar', _handleLogin);
        secondaryButton = Column(
          children: [
            _buildTextButton(
              'Não tem uma conta? Registrar Usuário',
              () => _switchAuthMode(AuthMode.registerUser),
            ),
            _buildTextButton(
              'Registrar como Admin',
              () => _switchAuthMode(AuthMode.registerAdmin),
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
          ), // <-- CORRIGIDO
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
          ), // <-- CORRIGIDO
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

      // --- MODO REGISTRO DE ADMIN ---
      case AuthMode.registerAdmin:
        title = 'Registrar Admin';
        formFields = [
          _buildTextField(
            _emailController,
            'Email',
            keyboardType: TextInputType.emailAddress,
          ), // <-- CORRIGIDO
          const SizedBox(height: 16),
          _buildTextField(_usernameController, 'Seu Nome'),
          const SizedBox(height: 16),
          _buildTextField(
            _sectorNameController,
            'Nome do Setor (Ex: Bateria B10)',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _passwordController,
            'Senha',
            obscureText: true,
            helperText: 'Mín 8, máx 72 caracteres',
          ), // <-- CORRIGIDO
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

  // AQUI ESTÁ A DEFINIÇÃO CORRIGIDA (com chaves {}):
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
      onPressed: onPressed,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : Text(text),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
} // <-- Este é o '}' final da classe _LoginPageState
