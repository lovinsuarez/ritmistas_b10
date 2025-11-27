import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ApiService _apiService = ApiService();
  // Na versão 5.2.3, o controller funciona assim:
  final MobileScannerController controller = MobileScannerController();
  // Estado local da lanterna (compatível com várias versões do pacote)
  final ValueNotifier<bool> _torchOn = ValueNotifier<bool>(false);
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    _torchOn.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isProcessing = true);
        await _processCheckIn(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processCheckIn(String activityId) async {
    try {
      showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
      );
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Não autenticado.");

      // Tenta checkin direto (String)
      final message = await _apiService.checkIn(activityId, token);
      
      if (mounted) {
        Navigator.pop(context);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text("Sucesso!", style: TextStyle(color: Colors.green)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
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
          // BOTÃO DA LANTERNA (compatível)
          IconButton(
            icon: ValueListenableBuilder<bool>(
              valueListenable: _torchOn,
              builder: (context, isOn, child) {
                return isOn
                    ? const Icon(Icons.flash_on, color: AppColors.primaryYellow)
                    : const Icon(Icons.flash_off, color: Colors.grey);
              },
            ),
            onPressed: () async {
              try {
                await controller.toggleTorch();
                _torchOn.value = !_torchOn.value;
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao alternar lanterna: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250, height: 250,
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