// lib/pages/admin_master_badges_page.dart

import 'dart:typed_data'; // Para Web
import 'package:flutter/material.dart' hide Badge;
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart' hide Badge;
import 'package:ritmistas_app/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; 

class AdminMasterBadgesPage extends StatefulWidget {
  const AdminMasterBadgesPage({super.key});
  @override
  State<AdminMasterBadgesPage> createState() => _AdminMasterBadgesPageState();
}

class _AdminMasterBadgesPageState extends State<AdminMasterBadgesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Badge>> _badgesFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _badgesFuture = _loadBadges();
  }

  Future<List<Badge>> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado.");
    return _apiService.getAllBadges(_token!);
  }

  Future<void> _refresh() async {
    setState(() { _badgesFuture = _loadBadges(); });
    await _badgesFuture;
  }

  // CORREÇÃO: Upload via Bytes
  Future<String> _uploadBadgeImage(Uint8List data) async {
    try {
      String fileName = 'badge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('badges').child(fileName);
      UploadTask uploadTask = ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Falha no upload: $e");
    }
  }

  Future<void> _createBadgeAction(String name, String desc, String iconUrl) async {
    try {
      await _apiService.createBadge(_token!, name, desc, iconUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Criado com sucesso!"), backgroundColor: Colors.green));
        _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  void _showCreateBadgeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    Uint8List? selectedImageBytes; // Mudou para bytes
    bool isUploading = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            
            Future<void> pickImage() async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 60,
                  maxWidth: 300,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setStateDialog(() { selectedImageBytes = bytes; });
                }
              } catch (e) { print(e); }
            }

            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text("Nova Insígnia", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 100, width: 100,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryYellow, width: 2),
                          image: selectedImageBytes != null 
                              ? DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.cover)
                              : null
                        ),
                        child: selectedImageBytes == null 
                            ? const Icon(Icons.add_a_photo, color: Colors.white24, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: pickImage, child: const Text("Escolher Imagem")),
                    
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nome")),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Descrição")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isUploading ? null : () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (nameCtrl.text.isEmpty) return;
                    setStateDialog(() => isUploading = true);

                    try {
                      String finalUrl = "";
                      if (selectedImageBytes != null) {
                         finalUrl = await _uploadBadgeImage(selectedImageBytes!);
                      }
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        _createBadgeAction(nameCtrl.text, descCtrl.text, finalUrl);
                      }
                    } catch (e) {
                      setStateDialog(() => isUploading = false);
                      // Aviso de erro...
                    }
                  },
                  child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text("Criar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Badge>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          final badges = snapshot.data ?? [];
          if (badges.isEmpty) return const Center(child: Text("Sem insígnias.", style: TextStyle(color: Colors.grey)));

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Card(
                color: AppColors.cardBackground,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty)
                      Image.network(badge.iconUrl!, height: 60, width: 60, fit: BoxFit.cover)
                    else
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                    const SizedBox(height: 12),
                    Text(badge.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBadgeDialog,
        label: const Text("Nova Insígnia"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: Colors.black,
      ),
    );
  }
}