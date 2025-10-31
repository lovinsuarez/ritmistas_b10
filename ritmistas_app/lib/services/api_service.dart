// lib/services/api_service.dart

import 'dart:convert'; // PARA jsonEncode e jsonDecode
import 'package:http/http.dart' as http; // PARA http.post e http.get

// ====================================================================
// --- Modelos de Dados ---
// ====================================================================

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
  final String role; // 'admin' ou 'user'

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

// ====================================================================
// --- Classe do Serviço de API ---
// ====================================================================

class ApiService {
  static const String _baseUrl = "https://ritmistas-b10.onrender.com";

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

  Future<void> registerAdmin({
    required String email,
    required String password,
    required String username,
    required String sectorName,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register/admin');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "password": password,
        "sector_name": sectorName,
      }),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao registrar');
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

  // --- Funções de Usuário ---

  Future<String> redeemCode(String code, String token) async {
    final url = Uri.parse('$_baseUrl/redeem');
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
    final url = Uri.parse('$_baseUrl/checkin');
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

  Future<Map<String, dynamic>> getRanking(String token) async {
    final url = Uri.parse('$_baseUrl/ranking');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['detail'] ?? 'Falha ao buscar ranking');
    }
  }

  // --- Funções de Admin ---

  Future<void> createActivity(
    String token, {
    required String title,
    String? description,
    required String type,
    String? address,
    required DateTime activityDate,
    required int pointsValue,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/activities');
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

  Future<List<Activity>> getActivities(String token) async {
    final url = Uri.parse('$_baseUrl/admin/activities');
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

  Future<List<UserAdminView>> getAdminUsers(String token) async {
    final url = Uri.parse('$_baseUrl/admin/users');
    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao buscar usuários');
    }
  }

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

  Future<void> deleteUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId');
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

  Future<Map<String, dynamic>> getUserDashboard(
    String token,
    int userId,
  ) async {
    final url = Uri.parse('$_baseUrl/admin/users/$userId/dashboard');
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

  // --- NOVA FUNÇÃO DA ETAPA 21 ---
  Future<void> createGeneralCode(
    String token, {
    required String codeString,
    required int pointsValue,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/codes/general');

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
}
