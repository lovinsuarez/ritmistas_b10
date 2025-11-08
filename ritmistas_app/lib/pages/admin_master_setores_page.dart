// lib/pages/admin_master_setores_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/services/api_service.dart'; // Importa nosso serviço de API
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:ritmistas_app/pages/admin_master_setor_detalhe_page.dart';

class AdminMasterSetoresPage extends StatefulWidget {
  const AdminMasterSetoresPage({super.key});

  @override
  State<AdminMasterSetoresPage> createState() => _AdminMasterSetoresPageState();
}

class _AdminMasterSetoresPageState extends State<AdminMasterSetoresPage>
    with AutomaticKeepAliveClientMixin {
  // AutomaticKeepAliveClientMixin mantém o estado da aba
  final ApiService _apiService = ApiService();
  final _sectorNameController = TextEditingController();
  late Future<List<Sector>> _sectorsFuture;
  String? _token;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Carrega o token e busca os setores
    _sectorsFuture = _loadSectors();
  }

  Future<List<Sector>> _loadSectors() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) {
      throw Exception("Admin Master não autenticado.");
    }
    return _apiService.getAllSectors(_token!);
  }

  Future<void> _refreshSectors() async {
    setState(() {
      _sectorsFuture = _loadSectors();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro: ${message.replaceAll("Exception: ", "")}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleCreateSector() async {
    if (_sectorNameController.text.isEmpty || _isCreating || _token == null) {
      return;
    }
    setState(() => _isCreating = true);

    try {
      await _apiService.createSector(_token!, _sectorNameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setor criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _sectorNameController.clear();
      _refreshSectors(); // Atualiza a lista de setores
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Obrigatório para AutomaticKeepAliveClientMixin
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Formulário de Criação ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Criar Novo Setor',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sectorNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Setor (Ex: Bateria, Passistas)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _handleCreateSector,
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar Setor'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Lista de Setores Existentes ---
            Text(
              'Setores Existentes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            FutureBuilder<List<Sector>>(
              future: _sectorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar setores: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum setor criado ainda.'));
                }

                final sectors = snapshot.data!;
                return ListView.builder(
                  shrinkWrap:
                      true, // Para o ListView funcionar dentro do Column
                  physics:
                      const NeverScrollableScrollPhysics(), // Desabilita scroll
                  itemCount: sectors.length,
                  itemBuilder: (context, index) {
                    final sector = sectors[index];
                    return Card(
                      child: ListTile(
                        title: Text(sector.name),
                        subtitle: Text(
                          'Código: ${sector.inviteCode}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copiar Código',
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: sector.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Código de convite copiado!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                        ),
                        // ADICIONADO: Ação de clique no item
                        onTap: () async {
                          // <-- Torna a função 'async'
                          // 'await' espera a página de detalhes ser fechada
                          final bool? mudancaFeita =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => AdminMasterSetorDetalhePage(
                                sector:
                                    sector, // Passa o objeto 'sector' para a nova página
                              ),
                            ),
                          );

                          // Se a página de detalhes retornou 'true', recarrega a lista
                          if (mudancaFeita == true) {
                            _refreshSectors();
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Mantém o estado da aba
}
