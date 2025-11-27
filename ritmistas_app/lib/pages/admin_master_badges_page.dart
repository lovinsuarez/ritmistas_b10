
import 'package:flutter/material.dart' hide Badge;
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart' hide Badge;
import 'package:ritmistas_app/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
    setState(() {
      _badgesFuture = _loadBadges();
    });
    await _badgesFuture;
  }

  // --- UPLOAD FIREBASE ---
  Future<String> _uploadBadgeImage(File file) async {
    try {
      String fileName = 'badge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('badges').child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Falha no upload: $e");
    }
  }

  // --- CRIAR NO BANCO ---
  Future<void> _createBadgeAction(String name, String desc, String iconUrl) async {
    try {
      await _apiService.createBadge(_token!, name, desc, iconUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Insígnia criada com sucesso!"), backgroundColor: Colors.green),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateBadgeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    File? selectedImageFile;
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
                  imageQuality: 80,
                  maxWidth: 500,
                );
                
                if (image != null) {
                  setStateDialog(() {
                    selectedImageFile = File(image.path);
                  });
                }
              } catch (e) {
                print("Erro imagem: $e");
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Nova Insígnia", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- ÁREA DA IMAGEM (Sem campo de texto, só visual) ---
                    GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 110, width: 110,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryYellow, width: 3),
                              image: selectedImageFile != null 
                                  ? DecorationImage(image: FileImage(selectedImageFile!), fit: BoxFit.cover)
                                  : null
                            ),
                            child: selectedImageFile == null 
                                ? const Icon(Icons.emoji_events, color: Colors.white24, size: 50)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
                            child: const Icon(Icons.add_a_photo, size: 20, color: Colors.black),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Toque para escolher o ícone", 
                      style: TextStyle(color: Colors.grey, fontSize: 12)
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Nome da Conquista",
                        hintText: "Ex: MVP, Pontualidade...",
                        filled: true,
                        fillColor: Colors.black12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.label, color: AppColors.primaryYellow)
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Descrição",
                        hintText: "Ex: O melhor desempenho do mês",
                        filled: true,
                        fillColor: Colors.black12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description, color: AppColors.primaryYellow)
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(dialogContext), 
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
                ),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: isUploading ? null : () async {
                    if (nameCtrl.text.isEmpty) return;
                    
                    setStateDialog(() => isUploading = true);

                    String finalUrl = "";
                    
                    try {
                      if (selectedImageFile != null) {
                         finalUrl = await _uploadBadgeImage(selectedImageFile!);
                      }

                      // Fecha e cria
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        _createBadgeAction(nameCtrl.text, descCtrl.text, finalUrl);
                      }

                    } catch (e) {
                      setStateDialog(() => isUploading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
                    }
                  },
                  child: isUploading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("Criar Insígnia"),
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
          
          if (badges.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.military_tech_outlined, size: 80, color: Colors.white12),
                  SizedBox(height: 16),
                  Text("Nenhuma insígnia criada.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            // Padding bottom 100 para não ficar atrás da NavigationBar
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 12, 
              mainAxisSpacing: 12, 
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              
              ImageProvider? imageProvider;
              if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
                imageProvider = NetworkImage(badge.iconUrl!);
              }

              return Card(
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.05))
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                       height: 70, width: 70,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: AppColors.primaryYellow, width: 2),
                         image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
                         color: Colors.black38
                       ),
                       child: imageProvider == null ? const Icon(Icons.emoji_events, color: Colors.amber, size: 40) : null,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        badge.name.toUpperCase(), 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), 
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      
      // --- CORREÇÃO DO BOTÃO (FLUTUANTE ACIMA DA BARRA) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Levanta o botão para não cobrir a nav bar
        child: FloatingActionButton.extended(
          onPressed: _showCreateBadgeDialog,
          label: const Text("Nova Insígnia"),
          icon: const Icon(Icons.add),
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: Colors.black,
          elevation: 4,
        ),
      ),
    );
  }
}