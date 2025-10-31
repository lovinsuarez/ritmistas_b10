// lib/pages/resgate_page.dart
import 'package:flutter/material.dart';
import 'package:ritmistas_app/pages/digitar_codigo_page.dart';
import 'package:ritmistas_app/pages/scan_qr_page.dart';

class ResgatePage extends StatelessWidget {
  const ResgatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Botão 1: Escanear QRCode ---
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner, size: 40),
            label: const Text(
              'Escanear QRCode',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              // Usa a cor primária (Amarelo) e texto (Preto) do nosso Tema
              foregroundColor: Theme.of(
                context,
              ).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
              backgroundColor: Theme.of(
                context,
              ).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // Navega para a tela do scanner
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanQrPage()),
              );
            },
          ),

          const SizedBox(height: 24),

          // --- Divisor "OU" ---
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OU',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 24),

          // --- Botão 2: Digitar Código ---
          OutlinedButton.icon(
            icon: const Icon(Icons.pin, size: 40),
            label: const Text(
              'Digitar Código Manual',
              style: TextStyle(fontSize: 18),
            ),
            style: OutlinedButton.styleFrom(
              // Usa a cor primária (Amarelo) para o texto e borda
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              // Navega para a tela de digitar o código
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DigitarCodigoPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
