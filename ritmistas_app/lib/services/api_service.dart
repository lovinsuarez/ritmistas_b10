// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// 1. Importa os modelos (que estão em app_models.dart)
import 'package:ritmistas_app/models/app_models.dart';

// 2. Exporta os modelos para que o resto do app os enxergue
export 'package:ritmistas_app/models/app_models.dart';

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
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email, 
        "username": username, 
        "password": password, 
        "invite_code": inviteCode 
      }),
    );

    if (response.statusCode != 201) {
      try {
        final errorData = jsonDecode(response.body);
        if (response.statusCode == 422) {
            print("Erro 422: ${response.body}");
            throw Exception("Verifique os dados enviados."); 
        }
        throw Exception(errorData['detail'] ?? 'Falha ao registrar');
      } catch (e) {
         throw Exception("Erro ${response.statusCode}: ${response.body}");
      }
    }
  }

  // --- USER ---
  Future<Map<String, dynamic>> getUsersMe(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/me'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro buscar dados');
  }

  Future<void> updateProfile(String token, {String? nickname, String? profilePic, DateTime? birthDate}) async {
    final url = Uri.parse('$_baseUrl/users/me/profile');
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (profilePic != null) body['profile_pic'] = profilePic;
    if (birthDate != null) body['birth_date'] = DateFormat('yyyy-MM-dd').format(birthDate);

    final response = await http.put(url, headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}, body: jsonEncode(body));
    if (response.statusCode != 200) throw Exception('Erro atualizar perfil');
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

  Future<String> checkIn(String activityCode, String token) async {
    final url = Uri.parse('$_baseUrl/user/checkin');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      // ENVIA COMO STRING AGORA
      body: jsonEncode({"activity_code": activityCode}), 
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['detail'];
    throw Exception(data['detail'] ?? 'Falha ao fazer check-in');
  }

  // --- RANKING ---
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

  Future<Map<String, dynamic>> getSectorRanking(String token) async => getGeralRanking(token);
  Future<Map<String, dynamic>> getRankingForSector(String token, int sectorId) async => getSpecificSectorRanking(token, sectorId);

  // --- LIDER ---
  Future<void> createActivity(String token, {required String title, String? description, required String type, String? address, required DateTime activityDate, required int pointsValue}) async {
    final url = Uri.parse('$_baseUrl/lider/activities');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({
        "title": title, 
        "description": description, 
        "type": type, 
        "address": address,
        "activity_date": activityDate.toIso8601String(), 
        "points_value": pointsValue
      }),
    );
    // Aceita 200 ou 201
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Falha ao criar atividade');
  }

  Future<List<Activity>> getActivities(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/lider/activities'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => Activity.fromJson(json)).toList();
    throw Exception('Erro buscar atividades');
  }

  Future<List<UserAdminView>> getSectorUsers(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/lider/users'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    throw Exception('Erro buscar usuarios');
  }
  
  Future<List<UserAdminView>> getPendingUsers(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/lider/pending-users'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
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

  Future<Map<String, dynamic>> getUserDashboard(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/lider/users/$userId/dashboard');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar dashboard');
  }

  Future<void> distributePoints(String token, int userId, int points, String description) async {
    final response = await http.post(Uri.parse('$_baseUrl/lider/distribute-points'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"user_id": userId, "points": points, "description": description}));
    if (response.statusCode != 200) throw Exception('Erro distribuir');
  }
  
  Future<void> createGeneralCode(String token, {required String codeString, required int pointsValue}) async {
    final response = await http.post(Uri.parse('$_baseUrl/lider/codes/general'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"code_string": codeString, "points_value": pointsValue}));
    if (response.statusCode != 201) throw Exception('Falha ao criar código');
  }

  // --- ADMIN MASTER ---
  Future<void> addBudget(String token, int liderId, int points) async {
    final response = await http.post(Uri.parse('$_baseUrl/admin-master/budget'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"lider_id": liderId, "points": points}));
    if (response.statusCode != 200) throw Exception('Erro add budget');
  }

  Future<void> createBadge(String token, String name, String description, String iconUrl) async {
    final response = await http.post(Uri.parse('$_baseUrl/admin-master/badges'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"name": name, "description": description, "icon_url": iconUrl}));
    if (response.statusCode != 200) throw Exception('Falha ao criar insígnia');
  }
  
  Future<List<Badge>> getAllBadges(String token) async {
    final response = await http.get(Uri.parse('$_baseUrl/admin-master/badges'), headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => Badge.fromJson(json)).toList();
    throw Exception('Erro buscar insignias');
  }

  Future<void> awardBadge(String token, int userId, int badgeId) async {
    final response = await http.post(Uri.parse('$_baseUrl/admin-master/award-badge'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"user_id": userId, "badge_id": badgeId}));
    if (response.statusCode != 200) throw Exception('Falha ao dar insígnia');
  }

  Future<Sector> createSector(String token, String sectorName) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      // CORREÇÃO: Envia "name" conforme esperado pelo backend
      body: jsonEncode({"name": sectorName}), 
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Sector.fromJson(data);
    throw Exception(data['detail'] ?? 'Falha ao criar setor');
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
     final response = await http.get(Uri.parse('$_baseUrl/admin-master/sectors/$sectorId/users'), headers: {"Authorization": "Bearer $token"});
     if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
     throw Exception('Erro buscar users setor');
  }

  Future<void> createAdminGeneralCode(String token, {String? codeString, required int pointsValue, String? title, String? description}) async {
    final url = Uri.parse('$_baseUrl/admin-master/codes/general');
    final Map<String, dynamic> body = {
      "points_value": pointsValue,
      "is_general": true,
    };

    if (codeString != null && codeString.isNotEmpty) body["code_string"] = codeString;
    if (title != null && title.isNotEmpty) body["title"] = title;
    if (description != null && description.isNotEmpty) body["description"] = description;

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode(body),
    );

    // Aceita 201 ou 200
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Falha ao criar código geral');
    }
  }

  Future<String> createSystemInvite(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/system-invite');
    final response = await http.post(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['code'];
    throw Exception('Falha ao gerar convite');
  }

  Future<List<dynamic>> getSystemInvites(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/system-invites');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar convites');
  }

  Future<List<UserAdminView>> getPendingGlobalUsers(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/pending-global');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    throw Exception('Falha ao buscar pendentes globais');
  }

  Future<void> approveGlobalUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/admin-master/approve-global/$userId');
    final response = await http.put(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Falha ao aprovar usuário');
  }

  Future<List<CodeDetail>> getAdminGeneralCodes(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/codes/general');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return (jsonDecode(response.body) as List).map((json) => CodeDetail.fromJson(json)).toList();
    throw Exception('Falha ao buscar códigos');
  }
}