// lib/pages/admin_master_badges_page.dart

import 'package:flutter/material.dart' hide Badge;
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

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

  // --- LÓGICA SEGURA DE CRIAÇÃO ---
  Future<void> _handleCreateBadge(String name, String desc, String? base64Img) async {
    // Mostra um aviso rápido que começou
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Criando insígnia..."), duration: Duration(seconds: 1)),
    );

    try {
      await _apiService.createBadge(
        _token!, 
        name, 
        desc, 
        base64Img ?? "" 
      );
      
      // Se chegou aqui, deu certo. Atualiza a lista.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sucesso! Insígnia criada."), backgroundColor: Colors.green)
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showCreateBadgeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? imageBase64;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            Future<void> pickImage() async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  // --- OTIMIZAÇÃO PARA NÃO CRASHAR ---
                  maxWidth: 150,    // Ícone pequeno
                  maxHeight: 150,   
                  imageQuality: 30, // Baixa qualidade (suficiente para ícone)
                );
                
                if (image != null) {
                  final bytes = await File(image.path).readAsBytes();
                  setStateDialog(() {
                    imageBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
                  });
                }
              } catch (e) {
                print("Erro imagem: $e");
              }
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
                        height: 80, width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryYellow, width: 2),
                          image: imageBase64 != null 
                              ? DecorationImage(image: MemoryImage(base64Decode(imageBase64!.split(',')[1])), fit: BoxFit.cover)
                              : null
                        ),
                        child: imageBase64 == null 
                            ? const Icon(Icons.add_a_photo, color: Colors.white, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: pickImage, 
                      child: const Text("Escolher Imagem", style: TextStyle(color: AppColors.primaryYellow))
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Nome (ex: MVP)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Descrição"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    
                    // 1. Salva os dados em variáveis locais
                    final n = nameCtrl.text;
                    final d = descCtrl.text;
                    final i = imageBase64;

                    // 2. FECHA O DIÁLOGO IMEDIATAMENTE
                    Navigator.pop(ctx);

                    // 3. Chama a função de criar usando o contexto da PÁGINA (seguro)
                    _handleCreateBadge(n, d, i);
                  },
                  child: const Text("Criar"),
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
                  Icon(Icons.military_tech_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhuma insígnia criada.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Espaço bottom
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              
              ImageProvider? imageProvider;
              if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
                if (badge.iconUrl!.startsWith("http")) {
                  imageProvider = NetworkImage(badge.iconUrl!);
                } else if (badge.iconUrl!.startsWith("data:image")) {
                  try {
                    imageProvider = MemoryImage(base64Decode(badge.iconUrl!.split(',')[1]));
                  } catch(e) {}
                }
              }

              return Card(
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                         height: 60, width: 60,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null
                         ),
                         child: imageProvider == null ? const Icon(Icons.emoji_events, color: Colors.amber, size: 40) : null,
                      ),
                      const SizedBox(height: 12),
                      Text(badge.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(badge.description ?? "", style: const TextStyle(color: Colors.grey, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: _showCreateBadgeDialog,
          label: const Text("Nova Insígnia"),
          icon: const Icon(Icons.add),
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}