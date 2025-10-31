// lib/pages/admin_cadastro_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminCadastroPage extends StatefulWidget {
  const AdminCadastroPage({super.key});

  @override
  State<AdminCadastroPage> createState() => _AdminCadastroPageState();
}

class _AdminCadastroPageState extends State<AdminCadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  // Controladores
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _pointsController = TextEditingController(text: '10'); // Valor padrão

  // Variáveis de estado
  String _type = 'presencial'; // 'presencial' ou 'online'
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Função para mostrar o Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Função para mostrar o Time Picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Função de Submit
  Future<void> _handleSubmit() async {
    // 1. Valida o formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // 2. Trava o botão
    setState(() => _isLoading = true);

    try {
      // 3. Pega o token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception("Admin não autenticado.");
      }

      // 4. Combina Data e Hora
      final DateTime activityDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 5. Chama a API
      await _apiService.createActivity(
        token,
        title: _titleController.text,
        description: _descController.text.isNotEmpty
            ? _descController.text
            : null,
        type: _type,
        address: _type == 'presencial' ? _addressController.text : null,
        activityDate: activityDateTime,
        pointsValue: int.parse(_pointsController.text),
      );

      // 6. Sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atividade criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Limpa o formulário
        _formKey.currentState!.reset();
        _titleController.clear();
        _descController.clear();
        _addressController.clear();
        _pointsController.text = '10';
        setState(() {}); // Atualiza a UI
      }
    } catch (e) {
      // 7. Erro
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nova Atividade',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título da Atividade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Campo obrigatório'
                    : null,
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Pontos
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: 'Pontos por Presença',
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
              const SizedBox(height: 16),

              // Tipo (Presencial / Online)
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'presencial',
                    child: Text('Presencial'),
                  ),
                  DropdownMenuItem(value: 'online', child: Text('Online')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 16),

              // Endereço (Condicional)
              if (_type == 'presencial')
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (_type == 'presencial' &&
                          (value == null || value.isEmpty))
                      ? 'Endereço obrigatório'
                      : null,
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Seleção de Data e Hora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Data: ${"${_selectedDate.toLocal()}".split(' ')[0]}',
                      ), // Formata a data
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Selecionar Data'),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Hora: ${_selectedTime.format(context)}',
                      ), // Formata a hora
                      TextButton(
                        onPressed: () => _selectTime(context),
                        child: const Text('Selecionar Hora'),
                      ),
                    ],
                  ),
                ],
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
                    : const Text('Criar Atividade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
