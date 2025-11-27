// lib/pages/scan_page.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ApiService _apiService = ApiService();
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await _processCode(barcode.rawValue!); // Nome da função atualizado
        break;
      }
    }
  }

  // --- CORREÇÃO: LÓGICA HÍBRIDA (Igual ao Resgate Manual) ---
  Future<void> _processCode(String code) async {
    try {
      // 1. Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado.");

      String message = "";

      // 2. TENTATIVA DUPLA
      try {
        // A) Tenta como Código Geral / Bônus (Admin Master ou Orçamento)
        message = await _apiService.redeemCode(code, token);
      } catch (e) {
        // B) Se falhar, tenta como Check-in de Atividade (Líder)
        try {
           message = await _apiService.checkIn(code, token);
        } catch (e2) {
           // C) Se falhar nos dois, é inválido mesmo
           throw Exception("Código inválido ou não encontrado.");
        }
      }

      if (mounted) {
        Navigator.pop(context); // Fecha loading
        
        // 3. Sucesso
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Fecha alerta
                  Navigator.pop(context); // Fecha câmera
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha loading
        
        // 4. Erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Destrava para tentar de novo
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Escanear QR Code"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller, 
              builder: (context, state, child) {
                if (state.torchState == TorchState.on) {
                  return const Icon(Icons.flash_on, color: AppColors.primaryYellow);
                } else {
                  return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryYellow, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}