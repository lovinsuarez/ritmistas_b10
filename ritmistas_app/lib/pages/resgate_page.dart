import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/pages/scan_page.dart'; // CONFIRMADO
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

      String msg;
      try {
        msg = await _apiService.redeemCode(code, token);
      } catch (e) {
        // Se falhar código, tenta checkin se for número
        if (int.tryParse(code) != null) {
           msg = await _apiService.checkIn(code, token);
        } else {
           rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage())),
              child: Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.primaryYellow),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 40, color: AppColors.primaryYellow),
                    Text("ESCANEAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Digite o Código"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRedeem,
              child: _isLoading ? const CircularProgressIndicator() : const Text("RESGATAR"),
            ),
          ],
        ),
      ),
    );
  }
}