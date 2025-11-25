// lib/pages/admin_atividades_page.dart

import 'package:flutter/material.dart';
import 'package:ritmistas_app/main.dart';
import 'package:ritmistas_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class AdminAtividadesPage extends StatefulWidget {
  const AdminAtividadesPage({super.key});

  @override
  State<AdminAtividadesPage> createState() => _AdminAtividadesPageState();
}

class _AdminAtividadesPageState extends State<AdminAtividadesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Activity>> _activitiesFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _loadActivities();
  }

  Future<List<Activity>> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token == null) throw Exception("Líder não autenticado.");
    return _apiService.getActivities(_token!);
  }

  Future<void> _refresh() async {
    setState(() {
      _activitiesFuture = _loadActivities();
    });
    await _activitiesFuture;
  }

  void _showCreateActivityDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _CreateActivityForm(),
      ),
    ).then((value) {
      if (value == true) _refresh();
    });
  }

  void _showQRCode(Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(activity.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              height: 200, width: 200,
              child: QrImageView(data: activity.activityId.toString(), version: QrVersions.auto, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("CÓDIGO MANUAL", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(activity.activityId.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.black),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: activity.activityId.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado!'), backgroundColor: Colors.green));
                    },
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR", style: TextStyle(color: Colors.black)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<List<Activity>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          final activities = snapshot.data ?? [];
          if (activities.isEmpty) return const Center(child: Text("Nenhuma atividade.", style: TextStyle(color: Colors.grey)));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  color: AppColors.cardBackground,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(activity.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(6)),
                              child: Text("${activity.pointsValue} PTS", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(dateFormat.format(activity.activityDate.toLocal()), style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showQRCode(activity),
                            icon: const Icon(Icons.qr_code),
                            label: const Text("VER QR CODE"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateActivityDialog,
        label: const Text("Nova Atividade"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: Colors.black,
      ),
    );
  }
}

// --- FORMULÁRIO DE CRIAÇÃO ---
class _CreateActivityForm extends StatefulWidget {
  const _CreateActivityForm();
  @override
  State<_CreateActivityForm> createState() => _CreateActivityFormState();
}

class _CreateActivityFormState extends State<_CreateActivityForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: "10");
  String _type = "presencial"; // padrao (lowercase para bater com backend)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione Data e Hora"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Erro de auth");

      // Combina Data e Hora
      final dt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute
      );

      await ApiService().createActivity(
        token,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        type: _type, // 'online' ou 'presencial'
        address: _type == 'presencial' ? "Local do Ensaio" : null,
        activityDate: dt,
        pointsValue: int.parse(_pointsCtrl.text),
      );

      if (mounted) {
        Navigator.pop(context, true); // Sucesso
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Atividade criada!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString().replaceAll("Exception: ", "")}"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Nova Atividade", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Título", prefixIcon: Icon(Icons.title)),
              validator: (v) => v!.isEmpty ? "Obrigatório" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Descrição (Opcional)", prefixIcon: Icon(Icons.description)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pointsCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Pontos", prefixIcon: Icon(Icons.star)),
                    validator: (v) => v!.isEmpty ? "*" : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    dropdownColor: AppColors.cardBackground,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "Tipo"),
                    items: const [
                      DropdownMenuItem(value: "presencial", child: Text("Presencial")),
                      DropdownMenuItem(value: "online", child: Text("Online")),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null ? "Data" : DateFormat('dd/MM').format(_selectedDate!)),
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (d != null) setState(() => _selectedDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null ? "Hora" : _selectedTime!.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (t != null) setState(() => _selectedTime = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("CRIAR ATIVIDADE"),
            ),
          ],
        ),
      ),
    );
  }
}