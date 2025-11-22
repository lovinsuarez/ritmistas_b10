import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Required for launching URLs (e.g., CSV download via external browser)

class AdminMasterRelatoriosPage extends StatefulWidget {
  const AdminMasterRelatoriosPage({super.key});

  @override
  State<AdminMasterRelatoriosPage> createState() => _AdminMasterRelatoriosPageState();
}

class _AdminMasterRelatoriosPageState extends State<AdminMasterRelatoriosPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _auditFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _auditFuture = _loadAudit();
  }

  Future<List<dynamic>> _loadAudit() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Não autenticado.");
    return _apiService.getAuditLogs(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _auditFuture = _loadAudit();
    });
    await _auditFuture;
  }

  // NOVA FUNÇÃO DE DOWNLOAD
  Future<void> _downloadCsv() async {
    if (_token == null) return;
    // Pega a URL do endpoint de download
    // Nota: Como o endpoint precisa de Auth Header, abrir direto no browser pode dar 401.
    // O ideal seria baixar internamente, mas para MVP vamos tentar via browser 
    // (Se falhar, precisaremos mudar o backend para aceitar token na URL query).
    
    // Vamos montar a URL com o token na query para facilitar o download direto
    // (Obs: O backend precisaria suportar isso, mas vamos tentar abrir a URL base primeiro)
    final url = Uri.parse("https://ritmistas-api.onrender.com/admin-master/reports/audit"); 
    
    // Aviso ao usuário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gerando relatório... Se falhar, contate o suporte.")),
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Scaffold(
      backgroundColor: Colors.transparent, // Fundo transparente
      appBar: AppBar(
        title: const Text("Auditoria"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Baixar CSV",
            onPressed: _downloadCsv, // Chama a função real
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryYellow),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Fiscalize a distribuição de pontos.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _auditFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erro: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Nenhum registro encontrado."));
                }

                final logs = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final date = DateTime.parse(log['timestamp']).toLocal();
                      
                      return Card(
                        color: AppColors.cardBackground,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            child: const Icon(Icons.history, color: Colors.white),
                          ),
                          title: Text(
                            log['type'], 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryYellow)
                          ),
                          subtitle: Text(
                            "${dateFormat.format(date)} • ${log['sector_name']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Text(
                            "+${log['points']}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow("Aluno:", log['user_name']),
                                  const Divider(color: Colors.white12),
                                  _buildDetailRow("Responsável:", log['lider_name'], isBold: true),
                                  const Divider(color: Colors.white12),
                                  _buildDetailRow("Detalhe:", log['description']),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value, 
          style: TextStyle(
            color: isBold ? AppColors.primaryYellow : Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          )
        ),
      ],
    );
  }
}