// lib/pages/resgate_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart'; // Para usar AppColors e Theme
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/pages/scan_page.dart'; // Importa a página de Scanner
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
      
      // Tenta primeiro como Código de Resgate (Promoção/Bônus)
      try {
        message = await _apiService.redeemCode(code, token);
      } catch (e) {
        // Se falhar, tenta como Check-in de Atividade (Presença)
        try {
           message = await _apiService.checkIn(code, token);
        } catch (e2) {
           // Se falhar nos dois, lança erro genérico
           throw Exception("Código inválido ou atividade não encontrada.");
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Sucesso!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), 
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ],
          ),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
                // --- BOTÃO GRANDE DE SCANNER ---
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage())),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      border: Border.all(color: AppColors.primaryYellow, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryYellow.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 60, color: AppColors.primaryYellow),
                        SizedBox(height: 12),
                        Text(
                          "ESCANEAR QR CODE",
                          style: TextStyle(
                            color: AppColors.primaryYellow, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            letterSpacing: 1.2
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("OU", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Colors.grey))
                  ]
                ),
                
                const SizedBox(height: 40),

                const Text(
                  "CÓDIGO MANUAL",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                
                const SizedBox(height: 12),
                
                // --- CAMPO DE TEXTO ---
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: "DIGITE AQUI",
                    hintStyle: TextStyle(color: Colors.grey[700], letterSpacing: 1, fontSize: 16),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // --- BOTÃO RESGATAR ---
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRedeem,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                      : const Text("RESGATAR PONTOS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                
                const SizedBox(height: 80), // Espaço extra para a navegação
              ],
            ),
          ),
        ),
      ),
    );
  }
}