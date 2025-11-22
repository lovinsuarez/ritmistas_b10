// lib/pages/resgate_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; 
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/pages/scan_page.dart'; // Importar a página de scan
import 'package:shared_preferences/shared_preferences.dart';

class ResgatePage extends StatefulWidget {
  const ResgatePage({super.key});

  @override
  State<ResgatePage> createState() => _ResgatePageState();
}

class _ResgatePageState extends State<ResgatePage> {
  final TextEditingController _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _handleRedeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado.");

      String message = "";
      try {
        message = await _apiService.redeemCode(code, token);
      } catch (e) {
        if (int.tryParse(code) != null) {
            try {
              message = await _apiService.checkIn(code, token);
            } catch (e2) {
              throw Exception("Código inválido.");
            }
        } else {
          rethrow;
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        );
        _codeController.clear();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BOTÃO GRANDE DE SCAN
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanPage()));
                  },
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      border: Border.all(color: AppColors.primaryYellow, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 60, color: AppColors.primaryYellow),
                        SizedBox(height: 10),
                        Text("ESCANEAR QR CODE", style: TextStyle(color: AppColors.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                const Row(children: [Expanded(child: Divider(color: Colors.grey)), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OU", style: TextStyle(color: Colors.grey))), Expanded(child: Divider(color: Colors.grey))]),
                const SizedBox(height: 40),

                const Text("DIGITE O CÓDIGO", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 10),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.white, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: "CÓDIGO AQUI",
                    hintStyle: TextStyle(color: Colors.grey[700], letterSpacing: 2),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRedeem,
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black))
                    : const Text("RESGATAR"),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}