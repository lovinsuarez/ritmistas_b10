import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMasterPontosPage extends StatefulWidget {
  const AdminMasterPontosPage({super.key});

  @override
  State<AdminMasterPontosPage> createState() => _AdminMasterPontosPageState();
}

class _AdminMasterPontosPageState extends State<AdminMasterPontosPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _pointsController = TextEditingController(text: "50");
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _createCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado");

      await _apiService.createAdminGeneralCode(
        token,
        codeString: _codeController.text.trim(),
        pointsValue: int.parse(_pointsController.text),
      );

      if (mounted) {
        _showQRCodeDialog(_codeController.text.trim(), _pointsController.text);
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQRCodeDialog(String code, String points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Código Gerado!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Este código vale $points pontos no Ranking Geral.", style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR", style: TextStyle(color: Colors.black)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CARD DE CRIAÇÃO DE PONTOS ---
            Card(
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars, color: AppColors.primaryYellow),
                          SizedBox(width: 10),
                          Text("Gerar Pontos Gerais", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text("Crie códigos que valem para o Ranking Geral da B10 (independente do setor).", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _codeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Código (Ex: FESTA-B10)", prefixIcon: Icon(Icons.vpn_key)),
                        validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pointsController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Valor em Pontos", prefixIcon: Icon(Icons.exposure_plus_1)),
                        validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createCode,
                          icon: _isLoading ? const SizedBox() : const Icon(Icons.qr_code_2),
                          label: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("GERAR CÓDIGO & QR"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- CARD DE DISTRIBUIÇÃO DE ORÇAMENTO (EXPLICAÇÃO) ---
            Card(
              color: Colors.green[900]!.withOpacity(0.3),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.green), borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.monetization_on, color: Colors.green), SizedBox(width: 8), Text("Distribuir Orçamento aos Líderes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                    SizedBox(height: 8),
                    Text(
                      "Para dar pontos aos líderes distribuírem:\n1. Vá na aba 'Líderes'.\n2. Clique no botão 'Dar Orçamento' no cartão do líder desejado.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}