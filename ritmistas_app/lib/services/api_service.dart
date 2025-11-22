// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// --- MODELOS ---
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
  Activity({required this.activityId, required this.title, required this.activityDate, required this.pointsValue, required this.type, this.address, required this.isGeneral});
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
  UserAdminView({required this.userId, required this.username, required this.email, required this.role, required this.status});
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

class UserDashboard {
  final int userId;
  final String username;
  final int totalPoints;
  final List<dynamic> checkins;
  final List<dynamic> redeemedCodes;
  UserDashboard({required this.userId, required this.username, required this.totalPoints, required this.checkins, required this.redeemedCodes});
  factory UserDashboard.fromJson(Map<String, dynamic> json) {
    return UserDashboard(
      userId: json['user_id'],
      username: json['username'],
      totalPoints: json['total_points'],
      checkins: json['checkins'] ?? [],
      redeemedCodes: json['redeemed_codes'] ?? [],
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

// --- SERVICE ---
class ApiService {
  static const String _baseUrl = "https://ritmistas-api.onrender.com";

  Future<String> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/token');
    final response = await http.post(url, headers: {"Content-Type": "application/x-www-form-urlencoded"}, body: {"username": email, "password": password});
    if (response.statusCode == 200) return jsonDecode(response.body)['access_token'];
    throw Exception(jsonDecode(response.body)['detail'] ?? 'Erro login');
  }

  Future<void> registerAdminMaster({required String email, required String password, required String username}) async {
    final url = Uri.parse('$_baseUrl/auth/register/admin-master');
    final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": email, "username": username, "password": password}));
    if (response.statusCode != 200) throw Exception('Erro registrar admin');
  }

  Future<void> registerUser({required String email, required String password, required String username, required String inviteCode}) async {
    final url = Uri.parse('$_baseUrl/auth/register/user');
    final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode({"email": email, "username": username, "password": password, "invite_code": inviteCode}));
    if (response.statusCode != 201) throw Exception('Erro registrar user');
  }

  Future<Map<String, dynamic>> getUsersMe(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/me'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro buscar dados');
  }

  Future<void> joinSector(String token, String inviteCode) async {
    final response = await http.post(Uri.parse('$_baseUrl/user/join-sector'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"invite_code": inviteCode}));
    if (response.statusCode != 200) throw Exception('Erro entrar setor');
  }

  Future<String> redeemCode(String code, String token) async {
    final response = await http.post(Uri.parse('$_baseUrl/user/redeem'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"code_string": code}));
    if (response.statusCode == 200) return jsonDecode(response.body)['detail'];
    throw Exception('Erro resgatar');
  }

  Future<String> checkIn(String activityId, String token) async {
    final response = await http.post(Uri.parse('$_baseUrl/user/checkin'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"activity_id": int.parse(activityId)}));
    if (response.statusCode == 200) return jsonDecode(response.body)['detail'];
    throw Exception('Erro checkin');
  }

  // --- RANKINGS ---
  Future<Map<String, dynamic>> getGeralRanking(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/ranking/geral'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro ranking geral');
  }

  Future<Map<String, dynamic>> getSpecificSectorRanking(String token, int sectorId) async {
    final response = await http.get(Uri.parse('$_baseUrl/ranking/sector/$sectorId'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro ranking setor');
  }
  
  Future<Map<String, dynamic>> getRankingForSector(String token, int sectorId) async {
    return getSpecificSectorRanking(token, sectorId);
  }
  
  // Alias para compatibilidade antiga
  Future<Map<String, dynamic>> getSectorRanking(String token) async {
    return getGeralRanking(token); 
  }

  // --- LIDER ---
  Future<void> createActivity(String token, {required String title, String? description, required String type, String? address, required DateTime activityDate, required int pointsValue}) async {
    final response = await http.post(Uri.parse('$_baseUrl/lider/activities'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"title": title, "description": description, "type": type, "address": address, "activity_date": activityDate.toIso8601String(), "points_value": pointsValue}));
    if (response.statusCode != 201) throw Exception('Erro criar atividade');
  }

  Future<List<Activity>> getActivities(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/lider/activities'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((json) => Activity.fromJson(json)).toList();
    }
    throw Exception('Erro buscar atividades');
  }

  Future<List<UserAdminView>> getSectorUsers(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/lider/users'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Erro buscar usuarios');
  }
  
  Future<List<UserAdminView>> getPendingUsers(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/lider/pending-users'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Erro buscar pendentes');
  }

  Future<void> approveUser(String token, int userId) async {
    final response = await http.put(Uri.parse('$_baseUrl/lider/approve-user/$userId'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Erro aprovar');
  }

  Future<void> rejectUser(String token, int userId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/lider/reject-user/$userId'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Erro rejeitar');
  }

  Future<void> deleteUser(String token, int userId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/lider/users/$userId'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200 && response.statusCode != 204) throw Exception('Erro deletar');
  }
  
  Future<void> distributePoints(String token, int userId, int points, String description) async {
    final response = await http.post(Uri.parse('$_baseUrl/lider/distribute-points'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"user_id": userId, "points": points, "description": description}));
    if (response.statusCode != 200) throw Exception('Erro distribuir');
  }

  Future<void> addBudget(String token, int liderId, int points) async {
    final response = await http.post(Uri.parse('$_baseUrl/admin-master/budget'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"lider_id": liderId, "points": points}));
    if (response.statusCode != 200) throw Exception('Erro add budget');
  }

  // --- FUNÇÃO QUE FALTAVA PARA A PÁGINA DE CRIAR CÓDIGO ---
  Future<void> createGeneralCode(String token, {required String codeString, required int pointsValue}) async {
    final url = Uri.parse('$_baseUrl/lider/codes/general');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({"code_string": codeString, "points_value": pointsValue}),
    );
    if (response.statusCode != 201) throw Exception('Falha ao criar código');
  }

  // --- FUNÇÃO QUE FALTAVA PARA O DASHBOARD ---
  Future<Map<String, dynamic>> getUserDashboard(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/users/$userId/dashboard');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar dashboard');
  }

  // --- ADMIN MASTER ---
  Future<Sector> createSector(String token, String sectorName) async {
    final response = await http.post(Uri.parse('$_baseUrl/admin-master/sectors'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"sector_name": sectorName}));
    if (response.statusCode == 200) return Sector.fromJson(jsonDecode(response.body));
    throw Exception('Erro criar setor');
  }

  Future<List<Sector>> getAllSectors(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/admin-master/sectors'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => Sector.fromJson(json)).toList();
    throw Exception('Erro buscar setores');
  }

  Future<List<UserAdminView>> getAllLiders(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/admin-master/liders'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    throw Exception('Erro buscar lideres');
  }

  Future<List<UserAdminView>> getAllUsers(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/admin-master/users'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    throw Exception('Erro buscar todos usuarios');
  }

  Future<void> promoteUserToLider(String token, int userId) async {
    final response = await http.put(Uri.parse('$_baseUrl/admin-master/users/$userId/promote-to-lider'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Erro promover');
  }

  Future<void> demoteLiderToUser(String token, int liderId) async {
    final response = await http.put(Uri.parse('$_baseUrl/admin-master/liders/$liderId/demote-to-user'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Erro rebaixar');
  }

  Future<void> assignLiderToSector(String token, int sectorId, int liderId) async {
    final response = await http.put(Uri.parse('$_baseUrl/admin-master/sectors/$sectorId/assign-lider'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"lider_id": liderId}));
    if (response.statusCode != 200) throw Exception('Erro designar');
  }

  Future<List<dynamic>> getAuditLogs(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/admin-master/audit/json'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro audit');
  }

  Future<List<UserAdminView>> getUsersForSector(String token, int sectorId) async {
     final url = Uri.parse('$_baseUrl/admin-master/sectors/$sectorId/users');
     final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
     if (response.statusCode == 200) {
       return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
     }
     throw Exception('Erro users setor');
  }
}