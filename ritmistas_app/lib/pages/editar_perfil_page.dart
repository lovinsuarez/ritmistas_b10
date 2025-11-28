// lib/pages/editar_perfil_page.dart

import 'dart:typed_data'; // Importante para Web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';


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
  
  // Mudança: Usamos bytes para compatibilidade Web
  Uint8List? _imageBytes;
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.currentNickname != null) _nicknameController.text = widget.currentNickname!;
    if (widget.currentBirthDate != null) {
      try { _selectedDate = DateTime.parse(widget.currentBirthDate!); } catch (e) {}
    }
  }

  // 1. Escolher Imagem (Compatível com Web)
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
        maxWidth: 800,
      );
      
      if (image != null) {
        // Lê os bytes imediatamente
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print("Erro galeria: $e");
    }
  }

  // 2. Upload usando Bytes (Funciona na Web)
  Future<String> _uploadImageToFirebase(Uint8List data) async {
    try {
      String fileName = 'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('avatars').child(fileName);
      
      // CORREÇÃO: putData em vez de putFile
      UploadTask uploadTask = ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
      
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Falha no upload da imagem: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado");

      String? finalPhotoUrl;

      // Se escolheu imagem nova, faz upload
      if (_imageBytes != null) {
        finalPhotoUrl = await _uploadImageToFirebase(_imageBytes!);
      } else {
        // Mantém a antiga se não mudou
        finalPhotoUrl = widget.currentPhotoUrl;
      }

      await _apiService.updateProfile(
        token,
        nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
        profilePic: finalPhotoUrl, 
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
    ImageProvider? getPreview() {
      if (_imageBytes != null) {
        return MemoryImage(_imageBytes!); // Mostra bytes locais
      }
      if (widget.currentPhotoUrl != null) {
        return NetworkImage(widget.currentPhotoUrl!); // Mostra URL antiga
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: getPreview(),
                      child: getPreview() == null 
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
              TextButton(onPressed: _pickImage, child: const Text("Alterar Foto")),
              
              const SizedBox(height: 30),

              TextFormField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Apelido", prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                      context: context, 
                      initialDate: _selectedDate ?? DateTime(2000), 
                      firstDate: DateTime(1950), 
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primaryYellow, onPrimary: Colors.black, surface: AppColors.cardBackground)), child: child!);
                      }
                  );
                  if (d != null) setState(() => _selectedDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "Data de Nascimento", prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                  child: Text(_selectedDate == null ? "Selecione" : DateFormat('dd/MM/yyyy').format(_selectedDate!), style: const TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("SALVAR ALTERAÇÕES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}