// lib/pages/editar_perfil_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importante para a galeria
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

  // Variável para guardar a imagem em Base64 se escolhida da galeria
  String? _imageBase64;

  DateTime? _selectedDate;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  
  // Instância do ImagePicker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.currentNickname != null) _nicknameController.text = widget.currentNickname!;
    
    // Se a imagem atual for URL, põe no controller. Se for base64 (antiga), põe na variável.
    if (widget.currentPhotoUrl != null) {
      if (widget.currentPhotoUrl!.startsWith('http')) {
        _photoUrlController.text = widget.currentPhotoUrl!;
      } else {
        _imageBase64 = widget.currentPhotoUrl;
      }
    }

    if (widget.currentBirthDate != null) {
      try { _selectedDate = DateTime.parse(widget.currentBirthDate!); } catch (e) {}
    }
  }

  // --- FUNÇÃO PARA ABRIR GALERIA ---
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Reduz qualidade para não ficar gigante
        maxWidth: 800,
      );
      
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        // Converte para Base64 para poder enviar e salvar
        final String base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
        
        setState(() {
          _imageBase64 = base64String;
          // Limpa o campo de URL se o usuário escolheu uma imagem da galeria
          _photoUrlController.clear();
        });
      }
    } catch (e) {
      print("Erro ao abrir galeria: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao abrir galeria. Verifique as permissões."), backgroundColor: Colors.red));
      }
    }
  }

  // Função para selecionar data
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

      // Decide qual imagem enviar: a Base64 da galeria OU a URL do campo de texto
      String? finalProfilePic = _imageBase64;
      if (_photoUrlController.text.isNotEmpty) {
        finalProfilePic = _photoUrlController.text;
      }

      await _apiService.updateProfile(
        token,
        nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
        profilePic: finalProfilePic,
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

  // Helper para mostrar a imagem no topo da tela de edição
  ImageProvider? _getPreviewImage() {
    if (_imageBase64 != null) {
       try { return MemoryImage(base64Decode(_imageBase64!.split(',')[1])); } catch(e) { return null; }
    }
    if (_photoUrlController.text.isNotEmpty) {
      return NetworkImage(_photoUrlController.text);
    }
    return null;
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
              // Preview da imagem (também clicável)
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _getPreviewImage(),
                      child: (_imageBase64 == null && _photoUrlController.text.isEmpty) 
                          ? const Icon(Icons.person, size: 60, color: Colors.white) 
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: _pickImage, child: const Text("Toque para escolher da Galeria")),
              
              const SizedBox(height: 20),

              // --- AQUI ESTÁ A MUDANÇA: CAMPO URL + BOTÃO GALERIA ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _photoUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Ou cole a URL da Foto", 
                        prefixIcon: Icon(Icons.link),
                        hintText: "https://..."
                      ),
                      onChanged: (val) {
                        // Se o usuário digitar uma URL, limpamos a imagem da galeria
                        if (val.isNotEmpty) setState(() => _imageBase64 = null);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botão da Galeria ao lado do campo
                  Ink(
                    decoration: const ShapeDecoration(
                      color: AppColors.primaryYellow,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.black),
                      tooltip: "Abrir Galeria",
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
              // -------------------------------------------------------
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Apelido", prefixIcon: Icon(Icons.badge)),
              ),
              
              const SizedBox(height: 16),
              
              InkWell(
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