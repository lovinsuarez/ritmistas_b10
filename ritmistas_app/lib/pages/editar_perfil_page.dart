import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// IMPORTANTE: Importa o Storage
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
  final _photoUrlController = TextEditingController();
  
  // Agora guardamos o ARQUIVO, não a string base64
  File? _selectedImageFile;
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.currentNickname != null) _nicknameController.text = widget.currentNickname!;
    // Se já tem URL, põe no campo (mas o usuário pode não ver se escolher arquivo)
    if (widget.currentPhotoUrl != null && widget.currentPhotoUrl!.startsWith('http')) {
      _photoUrlController.text = widget.currentPhotoUrl!;
    }
    if (widget.currentBirthDate != null) {
      try { _selectedDate = DateTime.parse(widget.currentBirthDate!); } catch (e) {}
    }
  }

  // 1. Escolher Imagem (Apenas guarda o arquivo local)
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Boa qualidade
        maxWidth: 1000,
      );
      
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          // Limpa o campo de texto para dar prioridade à imagem nova
          _photoUrlController.clear();
        });
      }
    } catch (e) {
      print("Erro galeria: $e");
    }
  }

  // 2. Upload para o Firebase (Retorna a URL)
  Future<String> _uploadImageToFirebase(File file) async {
    try {
      // Cria um nome único: perfil_TIMESTAMP.jpg
      String fileName = 'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Referência no Storage (Pasta 'avatars')
      Reference ref = FirebaseStorage.instance.ref().child('avatars').child(fileName);
      
      // Faz o Upload
      UploadTask uploadTask = ref.putFile(file);
      
      // Espera terminar
      TaskSnapshot snapshot = await uploadTask;
      
      // Pega a URL pública
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
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

      // SE O USUÁRIO ESCOLHEU UMA FOTO NOVA DO CELULAR:
      if (_selectedImageFile != null) {
        // Faz o upload primeiro
        finalPhotoUrl = await _uploadImageToFirebase(_selectedImageFile!);
      } 
      // SE NÃO, USA O QUE ESTÁ NO CAMPO DE TEXTO (URL ANTIGA OU NOVA COLADA)
      else if (_photoUrlController.text.isNotEmpty) {
        finalPhotoUrl = _photoUrlController.text;
      }

      // Atualiza no Backend com a URL final
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
    // Helper para mostrar o preview
    ImageProvider? getPreview() {
      if (_selectedImageFile != null) {
        return FileImage(_selectedImageFile!); // Mostra o arquivo local
      }
      if (_photoUrlController.text.isNotEmpty) {
        return NetworkImage(_photoUrlController.text); // Mostra a URL antiga
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
              TextButton(onPressed: _pickImage, child: const Text("Escolher da Galeria")),
              
              const SizedBox(height: 20),

              TextFormField(
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Apelido", prefixIcon: Icon(Icons.badge)),
              ),
              const SizedBox(height: 16),
              
              // Campo URL (Opcional, caso queira esconder pode usar Visibility)
              TextFormField(
                controller: _photoUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Ou cole uma URL (Link)", prefixIcon: Icon(Icons.link)),
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
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("ENVIANDO... "), SizedBox(width: 10, height: 10, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))])
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