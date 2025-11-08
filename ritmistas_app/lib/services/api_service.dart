// lib/services/api_service.dart

import 'dart:convert'; // PARA jsonEncode e jsonDecode
import 'package:http/http.dart' as http; // PARA http.post e http.get

// ====================================================================
// --- Modelos de Dados ---
// ====================================================================

// (Os modelos Activity e UserAdminView permanecem os mesmos, estão ótimos)

class Activity {
  final int activityId;
  final String title;
  final DateTime activityDate;
  final int pointsValue;
  final String type;
  final String? address;

  Activity({
    required this.activityId,
    required this.title,
    required this.activityDate,
    required this.pointsValue,
    required this.type,
    this.address,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'],
      title: json['title'],
      activityDate: DateTime.parse(json['activity_date']),
      pointsValue: json['points_value'],
      type: json['type'],
      address: json['address'],
    );
  }
}

class UserAdminView {
  final int userId;
  final String username;
  final String email;
  final String role; // '0' (admin), '1' (lider), '2' (user)

  UserAdminView({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  factory UserAdminView.fromJson(Map<String, dynamic> json) {
    return UserAdminView(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
    );
  }
}

// NOVO: Modelo para o Setor (para o Admin Master)
class Sector {
  final int sectorId;
  final String name;
  final String
      inviteCode; // O backend manda como UUID, mas o http trata como String
  final int? liderId;

  Sector({
    required this.sectorId,
    required this.name,
    required this.inviteCode,
    this.liderId,
  });

  factory Sector.fromJson(Map<String, dynamic> json) {
    return Sector(
      sectorId: json['sector_id'],
      name: json['name'],
      inviteCode: json['invite_code'],
      liderId: json['lider_id'],
    );
  }
}

// ====================================================================
// --- Classe do Serviço de API ---
// ====================================================================

class ApiService {
  // Esta URL está CORRETA, conforme sua confirmação anterior
  static const String _baseUrl = "https://ritmistas-api.onrender.com";

  // --- Funções de Auth ---

  Future<String> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/token');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": email, "password": password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao fazer login');
    }
  }

  // ALTERADO: Esta função agora é para o ADMIN MASTER
  Future<void> registerAdminMaster({
    required String email,
    required String password,
    required String username,
  }) async {
    // ALTERADO: Novo endpoint
    final url = Uri.parse('$_baseUrl/auth/register/admin-master');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        // "sector_name": sectorName, // <-- Removido
      }),
    );
    if (response.statusCode != 200) {
      // Endpoint retorna 200 OK
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao registrar Admin Master');
    }
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String username,
    required String inviteCode,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register/user');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "invite_code": inviteCode,
      }),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao registrar');
    }
  }

  Future<Map<String, dynamic>> getUsersMe(String token) async {
    final url = Uri.parse('$_baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Falha ao buscar dados do usuário');
    }
  }

  // --- Funções de Usuário (role: '2') ---

  Future<String> redeemCode(String code, String token) async {
    // ALTERADO: Novo endpoint
    final url = Uri.parse('$_baseUrl/user/redeem');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"code_string": code}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['detail'];
    } else {
      throw Exception(data['detail'] ?? 'Falha ao resgatar código');
    }
  }

  Future<String> checkIn(String activityId, String token) async {
    // ALTERADO: Novo endpoint
    final url = Uri.parse('$_baseUrl/user/checkin');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"activity_id": int.parse(activityId)}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['detail'];
    } else {
      throw Exception(data['detail'] ?? 'Falha ao fazer check-in');
    }
  }

  // --- Funções de Ranking (Todos os papéis) ---

  // ALTERADO: Renomeado de getRanking para getSectorRanking
  Future<Map<String, dynamic>> getSectorRanking(String token) async {
    // ALTERADO: Novo endpoint
    final url = Uri.parse('$_baseUrl/ranking/sector');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Falha ao buscar ranking do setor');
    }
  }

  // NOVO: Endpoint para o ranking geral
  Future<Map<String, dynamic>> getGeralRanking(String token) async {
    final url = Uri.parse('$_baseUrl/ranking/geral');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Falha ao buscar ranking geral');
    }
  }

  // --- Funções de Líder (role: '1') ---

  // ALTERADO: Endpoint
  Future<void> createActivity(
    String token, {
    required String title,
    String? description,
    required String type,
    String? address,
    required DateTime activityDate,
    required int pointsValue,
  }) async {
    final url = Uri.parse('$_baseUrl/lider/activities'); // <-- MUDOU
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "type": type,
        "address": address,
        "activity_date": activityDate.toIso8601String(),
        "points_value": pointsValue,
      }),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao criar atividade');
    }
  }

  // ALTERADO: Endpoint
  Future<List<Activity>> getActivities(String token) async {
    final url = Uri.parse('$_baseUrl/lider/activities'); // <-- MUDOU
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao buscar atividades');
    }
  }

  // ALTERADO: Renomeado e novo endpoint
  Future<List<UserAdminView>> getSectorUsers(String token) async {
    final url = Uri.parse('$_baseUrl/lider/users'); // <-- MUDOU
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['detail'] ?? 'Falha ao buscar usuários do setor',
      );
    }
  }

  // ALTERADO: Endpoint
  Future<void> deleteUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/users/$userId'); // <-- MUDOU
    final response = await http.delete(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 204) {
      // 204 No Content
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao deletar usuário');
    }
  }

  // ALTERADO: Endpoint
  Future<Map<String, dynamic>> getUserDashboard(
    String token,
    int userId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/lider/users/$userId/dashboard',
    ); // <-- MUDOU
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Falha ao buscar dashboard');
    }
  }

  // ALTERADO: Endpoint
  Future<void> createGeneralCode(
    String token, {
    required String codeString,
    required int pointsValue,
  }) async {
    final url = Uri.parse('$_baseUrl/lider/codes/general'); // <-- MUDOU

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "code_string": codeString,
        "points_value": pointsValue,
      }),
    );

    if (response.statusCode != 201) {
      // 201 Created
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao criar código');
    }
  }

  // --- Funções de Admin Master (role: '0') ---

  // NOVO: Criar Setor
  Future<Sector> createSector(String token, String sectorName) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "sector_name": sectorName,
      }), // Envia como {"sector_name": "Nome"}
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Sector.fromJson(data);
    } else {
      throw Exception(data['detail'] ?? 'Falha ao criar setor');
    }
  }

  // NOVO: Listar Setores
  Future<List<Sector>> getAllSectors(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Sector.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao buscar setores');
    }
  }

  // NOVO: Listar Líderes
  Future<List<UserAdminView>> getAllLiders(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/liders');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao buscar líderes');
    }
  }

  // NOVO: Promover usuário para Líder
  Future<void> promoteUserToLider(String token, int userId) async {
    final url = Uri.parse(
      '$_baseUrl/admin-master/users/$userId/promote-to-lider',
    );
    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao promover usuário');
    }
  }

  // NOVO: Rebaixar Líder para Usuário
  Future<void> demoteLiderToUser(String token, int liderId) async {
    final url = Uri.parse(
      '$_baseUrl/admin-master/liders/$liderId/demote-to-user',
    );
    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao rebaixar líder');
    }
  }

  // NOVO: Designar Líder a um Setor
  Future<void> assignLiderToSector(
    String token,
    int sectorId,
    int liderId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/admin-master/sectors/$sectorId/assign-lider',
    );
    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"lider_id": liderId}), // Envia como {"lider_id": 123}
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao designar líder');
    }
  }

  // --- Funções antigas de Admin (agora do Admin Master) ---
  // (Estas são as funções que o Líder NÃO pode fazer)

  // (Movido para Admin Master)
  Future<void> promoteUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId/promote');
    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao promover usuário');
    }
  }

  // (Movido para Admin Master)
  Future<void> demoteUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId/demote');
    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao rebaixar usuário');
    }
  }
}
