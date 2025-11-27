import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AdminCriarCodigoPage extends StatefulWidget {
  const AdminCriarCodigoPage({super.key});

  @override
  State<AdminCriarCodigoPage> createState() => _AdminCriarCodigoPageState();
}

class _AdminCriarCodigoPageState extends State<AdminCriarCodigoPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  final _codeStringController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado.");

      await _apiService.createGeneralCode(
        token,
        codeString: _codeStringController.text,
        pointsValue: int.parse(_pointsController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código criado com sucesso!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _codeStringController.clear();
        _pointsController.text = '10';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Código')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeStringController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Código (Ex: BATERIA50)'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pontos'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
}