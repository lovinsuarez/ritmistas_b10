import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'package:ritmistas_app/auth_check.dart';
import 'package:ritmistas_app/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necessário para inicializar plugins antes do app

  String? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // Guarda a mensagem de erro para exibir na UI e para diagnóstico
    firebaseInitError = e.toString();
    debugPrint('Firebase.initializeApp error: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(MyApp(firebaseInitError: firebaseInitError));
}
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
class MyApp extends StatelessWidget {
  final String? firebaseInitError;

  const MyApp({super.key, this.firebaseInitError});

  @override
  Widget build(BuildContext context) {
    // Se houve erro na inicialização do Firebase, mostra uma tela de erro
    if (firebaseInitError != null) {
      return MaterialApp(
        title: 'Ritmistas B10 - Erro',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Erro ao iniciar o app')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Falha ao inicializar o Firebase:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Text(firebaseInitError!, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => debugPrint('Reinicie o app para tentar novamente.'),
                  child: const Text('Reiniciar (manualmente)'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Ritmistas B10',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      // ROTA INICIAL
      home: const AuthCheck(),
      // DEFINIÇÃO DAS ROTAS
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}