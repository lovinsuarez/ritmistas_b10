import 'dart:convert'; // Para decodificar o JSON do QR Code
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // O pacote da câmera
import 'package:ritmistas_app/services/api_service.dart'; // Nosso ApiService
import 'package:shared_preferences/shared_preferences.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final ApiService _apiService = ApiService();
  // Este controlador nos dá acesso à câmera
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false; // Evita escanear o mesmo código várias vezes

  // Função para processar o check-in
  Future<void> _handleCheckIn(String activityId) async {
    if (_isProcessing) return; // Se já estamos processando, ignora

    setState(() => _isProcessing = true);

    try {
      // 1. Pega o token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        throw Exception("Usuário não autenticado.");
      }

      // 2. Chama a nova função da API (que criaremos a seguir)
      final message = await _apiService.checkIn(activityId, token);

      // 3. Mostra sucesso e fecha a tela
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        // Volta para a tela anterior (Aba Resgate)
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 4. Mostra o erro e permite escanear novamente
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Permite que o usuário tente escanear de novo após um erro
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    // Desliga a câmera quando a tela for fechada
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QRCode'),
        actions: [
          // Adiciona botões para ligar/desligar a lanterna e trocar de câmera
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController, // <-- 1. Escute o CONTROLLER
              builder: (context, state, child) {
                // 2. Acesse o estado da lanterna via ".value.torchState"
                final torchState = state.torchState;

                // 3. Verifique o estado
                return Icon(
                  torchState == TorchState.on
                      ? Icons.flash_off
                      : Icons.flash_on,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // O Widget da Câmera
          MobileScanner(
            controller: _scannerController,
            // Esta função é chamada QUANDO um QR Code é detectado
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? rawValue = barcodes.first.rawValue;

                if (rawValue != null) {
                  try {
                    // Tenta decodificar o texto do QR Code como JSON
                    final data = jsonDecode(rawValue) as Map<String, dynamic>;

                    // Verifica se é um QR Code do nosso app
                    if (data.containsKey('type') &&
                        data['type'] == 'checkin' &&
                        data.containsKey('activity_id')) {
                      // Se for, chama a função de check-in
                      _handleCheckIn(data['activity_id'].toString());
                    } else {
                      // Não é um QR Code válido
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QRCode inválido.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    // O QR Code não é um JSON (ex: um link de site)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QRCode não reconhecido.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              }
            },
          ),
          // Um overlay visual para guiar o usuário
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
