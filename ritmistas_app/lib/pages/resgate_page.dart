// lib/pages/scan_qr_page.dart

import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:ritmistas_app/main.dart'; // AppColors
import 'package:shared_preferences/shared_preferences.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final ApiService _apiService = ApiService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  // Função para processar o check-in
  Future<void> _handleCheckIn(String activityId) async {
    // Se estiver vazio ou já processando, sai
    if (activityId.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Usuário não autenticado.");

      // Chama a API
      final message = await _apiService.checkIn(activityId, token);

      if (mounted) {
        // Mostra sucesso
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Fecha alerta
                  Navigator.of(context).pop(); // Fecha scanner
                }, 
                child: const Text("OK")
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
        // Destrava para tentar de novo após erro
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QRCode'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                if (state == TorchState.on) {
                   return const Icon(Icons.flash_on, color: AppColors.primaryYellow);
                } else {
                   return const Icon(Icons.flash_off, color: Colors.grey);
                }
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? rawValue = barcodes.first.rawValue;

                if (rawValue != null) {
                  // Tenta ler como JSON (Seu código antigo)
                  try {
                    final data = jsonDecode(rawValue) as Map<String, dynamic>;
                    if (data.containsKey('activity_id')) {
                      _handleCheckIn(data['activity_id'].toString());
                    }
                  } catch (e) {
                    // Se falhar o JSON, tenta ler como ID direto (Para compatibilidade)
                    // Isso garante que funcione com o gerador atual
                    _handleCheckIn(rawValue);
                  }
                }
              }
            },
          ),
          // Overlay visual
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryYellow, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}