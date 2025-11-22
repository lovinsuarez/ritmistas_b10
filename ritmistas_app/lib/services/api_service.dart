// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Para formatar datas

// ====================================================================
// --- Modelos de Dados ---
// ====================================================================

class Badge {
  final int badgeId;
  final String name;
  final String? description;
  final String? iconUrl;

  Badge({required this.badgeId, required this.name, this.description, this.iconUrl});

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      badgeId: json['badge_id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
    );
  }
}

class UserBadge {
  final Badge badge;
  final DateTime awardedAt;

  UserBadge({required this.badge, required this.awardedAt});

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      badge: Badge.fromJson(json['badge']),
      awardedAt: DateTime.parse(json['awarded_at']),
    );
  }
}

class UserSectorPoints {
  final int sectorId;
  final String sectorName;
  final int points;

  UserSectorPoints({required this.sectorId, required this.sectorName, required this.points});

  factory UserSectorPoints.fromJson(Map<String, dynamic> json) {
    return UserSectorPoints(
      sectorId: json['sector_id'],
      sectorName: json['sector_name'],
      points: json['points'],
    );
  }
}

class Activity {
  final int activityId;
  final String title;
  final DateTime activityDate;
  final int pointsValue;
  final String type;
  final String? address;
  final bool isGeneral;

  Activity({
    required this.activityId,
    required this.title,
    required this.activityDate,
    required this.pointsValue,
    required this.type,
    this.address,
    required this.isGeneral,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'],
      title: json['title'],
      activityDate: DateTime.parse(json['activity_date']),
      pointsValue: json['points_value'],
      type: json['type'],
      address: json['address'],
      isGeneral: json['is_general'] ?? false,
    );
  }
}

class UserAdminView {
  final int userId;
  final String username;
  final String email;
  final String role;
  final String status;

  UserAdminView({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
  });

  factory UserAdminView.fromJson(Map<String, dynamic> json) {
    return UserAdminView(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
    );
  }
}

class Sector {
  final int sectorId;
  final String name;
  final String inviteCode;
  final int? liderId;

  Sector({required this.sectorId, required this.name, required this.inviteCode, this.liderId});

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
  static const String _baseUrl = "https://ritmistas-api.onrender.com";

  // --- AUTH ---
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

  Future<void> registerAdminMaster({required String email, required String password, required String username}) async {
    final url = Uri.parse('$_baseUrl/auth/register/admin-master');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "username": username, "password": password}),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao registrar');
    }
  }

  Future<void> registerUser({required String email, required String password, required String username, required String inviteCode}) async {
    final url = Uri.parse('$_baseUrl/auth/register/user');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "username": username, "password": password, "invite_code": inviteCode}),
    );
    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao registrar');
    }
  }

  // --- USER PROFILE ---
  Future<Map<String, dynamic>> getUsersMe(String token) async {
    final url = Uri.parse('$_baseUrl/users/me');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao buscar dados do usuário');
    }
  }

  // NOVO: Atualizar Perfil
  Future<void> updateProfile(String token, {String? nickname, String? profilePic, DateTime? birthDate}) async {
    final url = Uri.parse('$_baseUrl/users/me/profile');
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (profilePic != null) body['profile_pic'] = profilePic;
    if (birthDate != null) body['birth_date'] = DateFormat('yyyy-MM-dd').format(birthDate);

    final response = await http.put(
      url,
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar perfil');
    }
  }

  // --- AÇÕES DE USUÁRIO ---
  Future<void> joinSector(String token, String inviteCode) async {
    final url = Uri.parse('$_baseUrl/user/join-sector');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"invite_code": inviteCode}),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Falha ao entrar no setor');
    }
  }

  Future<String> redeemCode(String code, String token) async {
    final url = Uri.parse('$_baseUrl/user/redeem');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"code_string": code}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['detail'];
    throw Exception(data['detail'] ?? 'Falha ao resgatar código');
  }

  Future<String> checkIn(String activityId, String token) async {
    final url = Uri.parse('$_baseUrl/user/checkin');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"activity_id": int.parse(activityId)}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['detail'];
    throw Exception(data['detail'] ?? 'Falha ao fazer check-in');
  }

  // --- RANKING (Com Filtros de Data) ---
  Future<Map<String, dynamic>> getSectorRanking(String token) async {
     // Mantido para compatibilidade, mas redireciona para o específico se possível
     return getGeralRanking(token); 
  }

  Future<Map<String, dynamic>> getSpecificSectorRanking(String token, int sectorId, {int? month, int? year}) async {
    String query = "";
    if (month != null && year != null) query = "?month=$month&year=$year";
    
    final url = Uri.parse('$_baseUrl/ranking/sector/$sectorId$query');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar ranking do setor');
  }

  Future<Map<String, dynamic>> getGeralRanking(String token, {int? month, int? year}) async {
    String query = "";
    if (month != null && year != null) query = "?month=$month&year=$year";

    final url = Uri.parse('$_baseUrl/ranking/geral$query');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar ranking geral');
  }

  // --- LÍDER ---
  Future<void> createActivity(String token, {required String title, String? description, required String type, String? address, required DateTime activityDate, required int pointsValue}) async {
    final url = Uri.parse('$_baseUrl/lider/activities');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({
        "title": title, "description": description, "type": type, "address": address,
        "activity_date": activityDate.toIso8601String(), "points_value": pointsValue
      }),
    );
    if (response.statusCode != 201) throw Exception('Falha ao criar atividade');
  }

  Future<List<Activity>> getActivities(String token) async {
    final url = Uri.parse('$_baseUrl/lider/activities');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar atividades');
  }

  Future<List<UserAdminView>> getSectorUsers(String token) async {
    final url = Uri.parse('$_baseUrl/lider/users');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar usuários');
  }

  Future<void> createGeneralCode(String token, {required String codeString, required int pointsValue}) async {
    final url = Uri.parse('$_baseUrl/lider/codes/general');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"code_string": codeString, "points_value": pointsValue}),
    );
    if (response.statusCode != 201) throw Exception('Falha ao criar código');
  }

  Future<List<UserAdminView>> getPendingUsers(String token) async {
    final url = Uri.parse('$_baseUrl/lider/pending-users');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar aprovações');
  }

  Future<void> approveUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/approve-user/$userId');
    final response = await http.put(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Falha ao aprovar');
  }

  Future<void> rejectUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/reject-user/$userId');
    final response = await http.delete(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Falha ao rejeitar');
  }
  
  Future<void> deleteUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/users/$userId');
    final response = await http.delete(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Falha ao deletar');
  }

  Future<Map<String, dynamic>> getUserDashboard(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/users/$userId/dashboard');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar dashboard');
  }

  // NOVO: Distribuir Pontos do Orçamento
  Future<void> distributePoints(String token, int userId, int points, String description) async {
    final url = Uri.parse('$_baseUrl/lider/distribute-points');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"user_id": userId, "points": points, "description": description}),
    );
    if (response.statusCode != 200) {
       final errorData = jsonDecode(response.body);
       throw Exception(errorData['detail'] ?? 'Falha ao distribuir pontos');
    }
  }

  // --- ADMIN MASTER ---
  Future<Sector> createSector(String token, String sectorName) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"sector_name": sectorName}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Sector.fromJson(data);
    throw Exception(data['detail'] ?? 'Falha ao criar setor');
  }

  Future<List<Sector>> getAllSectors(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Sector.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar setores');
  }

  Future<List<UserAdminView>> getAllLiders(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/liders');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar líderes');
  }

  Future<List<UserAdminView>> getAllUsers(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/users');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar usuários');
  }
  
  Future<void> promoteUserToLider(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/admin-master/users/$userId/promote-to-lider');
    final response = await http.put(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Falha ao promover');
  }

  Future<void> demoteLiderToUser(String token, int liderId) async {
    final url = Uri.parse('$_baseUrl/admin-master/liders/$liderId/demote-to-user');
    final response = await http.put(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Falha ao rebaixar');
  }

  Future<void> assignLiderToSector(String token, int sectorId, int liderId) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors/$sectorId/assign-lider');
    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"lider_id": liderId}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao designar líder');
  }

  Future<List<dynamic>> getAuditLogs(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/audit/json');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao carregar auditoria');
  }

  // NOVO: Admin adiciona orçamento para líder
  Future<void> addBudget(String token, int liderId, int points) async {
    final url = Uri.parse('$_baseUrl/admin-master/budget');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"lider_id": liderId, "points": points}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao adicionar orçamento');
  }
  
  // NOVO: Admin cria insígnia
  Future<void> createBadge(String token, String name, String description, String iconUrl) async {
    final url = Uri.parse('$_baseUrl/admin-master/badges');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"name": name, "description": description, "icon_url": iconUrl}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao criar insígnia');
  }

  // NOVO: Admin dá insígnia
  Future<void> awardBadge(String token, int userId, int badgeId) async {
    final url = Uri.parse('$_baseUrl/admin-master/award-badge');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"user_id": userId, "badge_id": badgeId}),
    );
    if (response.statusCode != 200) throw Exception('Falha ao dar insígnia');
  }
}