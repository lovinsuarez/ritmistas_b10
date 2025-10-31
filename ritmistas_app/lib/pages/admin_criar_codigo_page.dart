// lib/pages/admin_criar_codigo_page.dart

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

  // Controladores
  final _codeStringController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception("Admin não autenticado.");
      }

      // Por enquanto, apenas 'Geral'
      await _apiService.createGeneralCode(
        token,
        codeString: _codeStringController.text,
        pointsValue: int.parse(_pointsController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código geral criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpa o formulário
        _formKey.currentState!.reset();
        _codeStringController.clear();
        _pointsController.text = '10';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Código de Pontos')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Criar novo código de resgate',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Este formulário cria um código GERAL, que qualquer usuário do seu setor pode resgatar uma vez.',
              ),
              const SizedBox(height: 24),

              // Código
              TextFormField(
                controller: _codeStringController,
                decoration: const InputDecoration(
                  labelText: 'Código (Ex: BATERA-NOVEMBRO)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Campo obrigatório'
                    : null,
              ),
              const SizedBox(height: 16),

              // Pontos
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Pontos',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  if (int.tryParse(value) == null || int.parse(value) <= 0)
                    return 'Deve ser um número positivo';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão de Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Criar Código Geral'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
