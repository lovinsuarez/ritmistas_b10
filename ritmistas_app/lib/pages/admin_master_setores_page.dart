// lib/pages/admin_master_setores_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para o Clipboard
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ritmistas_app/pages/admin_master_setor_detalhe_page.dart';

class AdminMasterSetoresPage extends StatefulWidget {
  const AdminMasterSetoresPage({super.key});

  @override
  State<AdminMasterSetoresPage> createState() => _AdminMasterSetoresPageState();
}

class _AdminMasterSetoresPageState extends State<AdminMasterSetoresPage>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final _sectorNameController = TextEditingController();

  // ALTERADO: Este 'Future' agora vai carregar DOIS conjuntos de dados
  late Future<Map<String, dynamic>> _dataFuture;

  String? _token;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  // ALTERADO: Esta função agora busca setores E líderes
   // Em lib/pages/admin_master_setores_page.dart

  Future<Map<String, dynamic>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) {
      throw Exception("Admin Master não autenticado.");
    }
    
    try {
      // Busca setores primeiro (essencial)
      final sectors = await _apiService.getAllSectors(_token!);
      
      // Tenta buscar líderes, mas se falhar, retorna lista vazia para não travar
      List<UserAdminView> liders = [];
      try {
        liders = await _apiService.getAllLiders(_token!);
      } catch (e) {
        print("Erro ao carregar líderes (ignorado para não travar): $e");
      }

      return {
        'sectors': sectors,
        'liders': liders,
      };
    } catch (e) {
      rethrow; // Se falhar setor, aí sim é erro
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataFuture = _loadData();
    });
    // Espera o futuro terminar para o RefreshIndicator
    await _dataFuture;
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
      _refreshData(); // Atualiza os dados
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // NOVO: Função helper para encontrar o nome do líder
  String _getLiderName(List<UserAdminView> liders, int? liderId) {
    if (liderId == null) return 'Nenhum';
    try {
      // Procura na lista de líderes o ID correspondente
      final lider = liders.firstWhere((l) => l.userId == liderId);
      return lider.username;
    } catch (e) {
      // Se não encontrar (ex: líder foi deletado), retorna 'Desconhecido'
      return 'Desconhecido (ID: $liderId)';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Formulário de Criação (Sem alteração) ---
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

            // ALTERADO: O FutureBuilder agora espera o Map
            FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar setores: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!['sectors'].isEmpty) {
                  return const Center(
                      child: Text('Nenhum setor criado ainda.'));
                }

                // Descompacta os dados
                final List<Sector> sectors = snapshot.data!['sectors'];
                final List<UserAdminView> liders = snapshot.data!['liders'];

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sectors.length,
                    itemBuilder: (context, index) {
                      final sector = sectors[index];
                      // Encontra o nome do líder usando a função helper
                      final String liderName =
                          _getLiderName(liders, sector.liderId);

                      // ALTERADO: O ListTile foi atualizado
                      return Card(
                        child: ListTile(
                          title: Text(sector.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mostra o NOME do Líder
                              Text(
                                'Líder: $liderName',
                                style: TextStyle(
                                    color: liderName == 'Nenhum'
                                        ? Colors.grey
                                        : Colors.black),
                              ),
                              // Mostra o Código de Convite
                              Text('Código: ${sector.inviteCode}'),
                            ],
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
                          onTap: () async {
                            final bool? mudancaFeita =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminMasterSetorDetalhePage(
                                  sector: sector,
                                ),
                              ),
                            );

                            if (mudancaFeita == true) {
                              _refreshData(); // Recarrega setores E líderes
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
