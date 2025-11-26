// lib/pages/editar_perfil_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditarPerfilPage extends StatefulWidget {
  final String? currentNickname;
  final String? currentPhotoUrl;
  final String? currentBirthDate;

  const EditarPerfilPage({
    super.key,
    this.currentNickname,
    this.currentPhotoUrl,
    this.currentBirthDate,
  });

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.currentNickname != null) _nicknameController.text = widget.currentNickname!;
    if (widget.currentPhotoUrl != null) _photoUrlController.text = widget.currentPhotoUrl!;
    if (widget.currentBirthDate != null) {
      try { _selectedDate = DateTime.parse(widget.currentBirthDate!); } catch (e) {}
    }
  }

  // --- FUNÇÃO DE SELECIONAR DATA ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryYellow,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado");

      await _apiService.updateProfile(
        token,
        nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
        profilePic: _photoUrlController.text.isEmpty ? null : _photoUrlController.text,
        birthDate: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil atualizado!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[800],
                backgroundImage: _photoUrlController.text.isNotEmpty ? NetworkImage(_photoUrlController.text) : null,
                child: _photoUrlController.text.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _photoUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "URL da Foto (Link)", prefixIcon: Icon(Icons.link)),
                onChanged: (val) => setState(() {}),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Apelido", prefixIcon: Icon(Icons.badge)),
              ),
              
              const SizedBox(height: 16),
              
              // --- AQUI ESTAVA O ERRO ---
              InkWell(
                // Correção: Usamos () => _pickDate() para evitar erro de tipagem
                onTap: () => _pickDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Data de Nascimento", 
                    prefixIcon: Icon(Icons.calendar_today), 
                    border: OutlineInputBorder()
                  ),
                  child: Text(
                    _selectedDate == null ? "Selecione" : DateFormat('dd/MM/yyyy').format(_selectedDate!), 
                    style: const TextStyle(color: Colors.white)
                  ),
                ),
              ),
              // --------------------------

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("SALVAR ALTERAÇÕES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}