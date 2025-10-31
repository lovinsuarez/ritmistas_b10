import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class DigitarCodigoPage extends StatefulWidget {
  const DigitarCodigoPage({super.key});

  @override
  State<DigitarCodigoPage> createState() => _DigitarCodigoPageState();
}

class _DigitarCodigoPageState extends State<DigitarCodigoPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  Future<void> _handleRedeem() async {
    final code = _codeController.text;
    if (code.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Pega o token salvo
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception("Usuário não autenticado. Faça login novamente.");
      }

      // 2. Chama a API
      final message = await _apiService.redeemCode(code, token);

      // 3. Mostra sucesso e limpa o campo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        _codeController.clear();
        // Opcional: fechar a tela após o sucesso
        // Navigator.of(context).pop();
      }
    } catch (e) {
      // 4. Mostra erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digitar Código')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Insira o código de atividade extra fornecido pelo administrador.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Código de Resgate',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleRedeem,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black, // Cor do spinner no botão amarelo
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Resgatar'),
            ),
          ],
        ),
      ),
    );
  }
}
