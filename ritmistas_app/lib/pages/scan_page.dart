// lib/pages/scan_page.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Pacote da câmera
import 'package:ritmistas_app/main.dart'; // Para usar AppColors
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
  bool _isProcessing = false; // Trava para não ler o mesmo código 10x seguidas

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Função chamada quando a câmera detecta algo
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return; // Se já está processando, ignora

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isProcessing = true; // Trava a leitura
        });

        final String code = barcode.rawValue!;
        await _processCheckIn(code);
        break; // Processa apenas o primeiro código encontrado
      }
    }
  }

  Future<void> _processCheckIn(String activityId) async {
    try {
      // 1. Mostra Dialog de Carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryYellow),
        ),
      );

      // 2. Pega o Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado.");

      // 3. Chama a API
      final message = await _apiService.checkIn(activityId, token);

      if (mounted) {
        Navigator.pop(context); // Fecha o Loading

        // 4. Mostra Sucesso
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Fecha o Alerta
                  Navigator.pop(context); // Fecha a Câmera e volta pra Home
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha o Loading

        // 5. Mostra Erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Destrava para tentar ler de novo após 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
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
          // Botão de Lanterna
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: AppColors.primaryYellow);
                  default:
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
          // A Câmera
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Overlay Escuro com buraco no meio (Visual)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), 
              BlendMode.srcOut
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Borda Amarela no Centro
          Center(
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryYellow, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Texto de Instrução
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              "Aponte a câmera para o código",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}