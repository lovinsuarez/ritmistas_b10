import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminMasterPontosPage extends StatefulWidget {
  const AdminMasterPontosPage({super.key});

  @override
  State<AdminMasterPontosPage> createState() => _AdminMasterPontosPageState();
}

class _AdminMasterPontosPageState extends State<AdminMasterPontosPage> {
  final _formKey = GlobalKey<FormState>();
  
  // NOVOS CONTROLADORES
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController(text: "50");
  
  final ApiService _apiService = ApiService();
  late Future<List<CodeDetail>> _codesFuture;
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codesFuture = _loadCodes();
  }

  Future<List<CodeDetail>> _loadCodes() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado");
    return _apiService.getAdminGeneralCodes(_token!);
  }

  Future<void> _refreshList() async {
    setState(() {
      _codesFuture = _loadCodes();
    });
  }

  Future<void> _createCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _apiService.createAdminGeneralCode(
        _token!,
        pointsValue: int.parse(_pointsController.text),
        title: _titleController.text,       // Envia Título
        description: _descController.text,  // Envia Descrição
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Código criado com sucesso!"), backgroundColor: Colors.green),
        );
        
        // Limpa tudo
        _titleController.clear();
        _descController.clear();
        _pointsController.text = "50";
        
        _refreshList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQRCodeDialog(String code, String points, String? title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mostra o Título no topo do Dialog
            Text(
              title?.toUpperCase() ?? "CÓDIGO GERAL", 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 8),
            Text("Vale $points pontos", style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200, width: 200,
              child: QrImageView(data: code, version: QrVersions.auto),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.black),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiado!"), backgroundColor: Colors.green));
                    },
                  )
                ],
              ),
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR", style: TextStyle(color: Colors.black)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // --- ÁREA DE CRIAÇÃO ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Gerar Pontos Gerais", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // CAMPO DE TÍTULO (NOVO)
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Título (Ex: Ensaio Técnico)", 
                      prefixIcon: Icon(Icons.title, color: AppColors.primaryYellow)
                    ),
                    validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                  ),
                  
                  const SizedBox(height: 10),

                  // CAMPO DE DESCRIÇÃO (NOVO)
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Descrição (Opcional)", 
                      prefixIcon: Icon(Icons.description, color: Colors.grey)
                    ),
                  ),

                  const SizedBox(height: 10),
                  
                  // CAMPO DE PONTOS
                  TextFormField(
                    controller: _pointsController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Valor em Pontos", 
                      prefixIcon: Icon(Icons.star, color: AppColors.primaryYellow)
                    ),
                    validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createCode,
                    icon: _isLoading ? const SizedBox() : const Icon(Icons.auto_fix_high, color: Colors.black),
                    label: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : const Text("GERAR CÓDIGO"),
                  ),
                ],
              ),
            ),
          ),

          // --- LISTA DE CÓDIGOS ---
          Expanded(
            child: FutureBuilder<List<CodeDetail>>(
              future: _codesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                        ElevatedButton(onPressed: _refreshList, child: const Text("Tentar Novamente"))
                      ],
                    ),
                  );
                }
                
                final codes = snapshot.data ?? [];
                
                if (codes.isEmpty) {
                  return const Center(child: Text("Nenhum código criado.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    // Formata a data (usa a data de criação)
                    final dateToShow = code.date;
                    final dateStr = DateFormat('dd/MM - HH:mm').format(dateToShow.toLocal());
                    
                    // Decide o título principal: Usa o título do evento, se não tiver, usa o código
                    final displayTitle = (code.title != null && code.title!.isNotEmpty) 
                        ? code.title! 
                        : code.codeString;

                    return Card(
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryYellow,
                          child: Icon(Icons.qr_code, color: Colors.black),
                        ),
                        // TÍTULO DO EVENTO
                        title: Text(
                          displayTitle, 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        // SUBTITULO COM DATA E DESCRIÇÃO
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (code.description != null && code.description!.isNotEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(top: 2),
                                 child: Text(code.description!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                               ),
                            // Mostra o código pequeno se o título for diferente
                            if (displayTitle != code.codeString)
                               Padding(
                                 padding: const EdgeInsets.only(top: 2),
                                 child: Text("Cód: ${code.codeString}", style: const TextStyle(color: Colors.amber, fontSize: 10)),
                               ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${code.points} pts", style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2, color: Colors.white),
                              // Passa o título para o diálogo do QR Code também
                              onPressed: () => _showQRCodeDialog(code.codeString, code.points.toString(), displayTitle),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}