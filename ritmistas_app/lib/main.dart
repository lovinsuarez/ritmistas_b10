import 'package:flutter/material.dart';
import 'package:ritmistas_app/theme.dart';
export 'package:ritmistas_app/theme.dart' show AppColors, appTheme, AppSpacing, AppRadius, AppShadows, AppGradients, AppAnimations, AppTypography;
import 'package:ritmistas_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'package:ritmistas_app/auth_check.dart';
import 'package:ritmistas_app/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    firebaseInitError = e.toString();
    debugPrint('Firebase.initializeApp error: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(MyApp(firebaseInitError: firebaseInitError));
}
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