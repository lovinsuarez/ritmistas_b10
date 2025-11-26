import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/models/app_models.dart'; // Importa CodeDetail
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminMasterPontosPage extends StatefulWidget {
  const AdminMasterPontosPage({super.key});

  @override
  State<AdminMasterPontosPage> createState() => _AdminMasterPontosPageState();
}

class _AdminMasterPontosPageState extends State<AdminMasterPontosPage> {
  final _formKey = GlobalKey<FormState>();
  
  // NÃO PRECISA MAIS DO CONTROLLER DE CÓDIGO, POIS É AUTOMÁTICO
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
      // CHAMADA ATUALIZADA: Só enviamos os pontos. O backend gera o código.
      await _apiService.createAdminGeneralCode(
        _token!,
        // codeString: ... (REMOVIDO)
        pointsValue: int.parse(_pointsController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Código gerado com sucesso!"), backgroundColor: Colors.green),
        );
        // Atualiza a lista para o novo código aparecer no topo
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

  void _showQRCodeDialog(String code, String points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Vale $points pontos (Geral)", style: const TextStyle(color: Colors.black54, fontSize: 14)),
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
          // --- ÁREA DE CRIAÇÃO (Formulário) ---
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
                  const SizedBox(height: 8),
                  const Text(
                    "O sistema criará um código aleatório seguro.", 
                    style: TextStyle(color: Colors.grey, fontSize: 12)
                  ),
                  const SizedBox(height: 20),
                  
                  // APENAS CAMPO DE PONTOS
                  TextFormField(
                    controller: _pointsController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Valor em Pontos", prefixIcon: Icon(Icons.star)),
                    validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // BOTÃO DE GERAR
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createCode,
                    icon: _isLoading ? const SizedBox() : const Icon(Icons.auto_fix_high, color: Colors.black),
                    label: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : const Text("GERAR CÓDIGO AUTOMÁTICO"),
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Nenhum código criado.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    final date = DateFormat('dd/MM/yy HH:mm').format(code.date.toLocal());
                    
                    return Card(
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryYellow,
                          child: Icon(Icons.qr_code, color: Colors.black),
                        ),
                        title: Text(code.codeString, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${code.points} pts", style: const TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2, color: Colors.white),
                              onPressed: () => _showQRCodeDialog(code.codeString, code.points.toString()),
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