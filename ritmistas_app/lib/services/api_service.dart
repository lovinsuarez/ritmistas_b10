import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// 1. Importa os modelos para o ApiService usar
import 'package:ritmistas_app/models/app_models.dart';

// 2. A MÁGICA: Exporta os modelos para QUEM importar o ApiService
// Isso faz com que todas as suas páginas voltem a funcionar instantaneamente!
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
        "invite_code": inviteCode // O campo chave
      }),
    );

    if (response.statusCode != 201) {
      // Tenta decodificar o erro detalhado
      try {
        final errorData = jsonDecode(response.body);
        // Se for erro de validação (422), o 'detail' é uma lista/mapa complexo
        if (response.statusCode == 422) {
            print("Erro 422 Detalhado: ${response.body}"); // Mostra no console
            throw Exception("Erro de validação: Verifique os dados."); 
        }
        throw Exception(errorData['detail'] ?? 'Falha ao registrar');
      } catch (e) {
         // Se não for JSON ou der erro ao ler
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

  Future<String> checkIn(String activityId, String token) async {
    final response = await http.post(Uri.parse('$_baseUrl/user/checkin'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode({"activity_id": int.parse(activityId)}));
    if (response.statusCode == 200) return jsonDecode(response.body)['detail'];
    throw Exception('Erro checkin');
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
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      // AQUI ESTÁ A MELHORIA: Tenta ler a mensagem do servidor
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Falha ao criar atividade');
      } catch (e) {
        throw Exception('Erro ${response.statusCode}: Falha ao criar atividade');
      }
    }
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

  // --- ADMIN MASTER ---
  Future<Sector> createSector(String token, String sectorName) async {
    final url = Uri.parse('$_baseUrl/admin-master/sectors');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      // AQUI A MUDANÇA: O backend espera "name", não "sector_name"
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
     throw Exception('Erro users setor');
  }
  Future<void> createAdminGeneralCode(String token, {required String codeString, required int pointsValue}) async {
    final url = Uri.parse('$_baseUrl/admin-master/codes/general');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode({
        "code_string": codeString, 
        "points_value": pointsValue,
        "is_general": true // Garante que é geral
      }),
    );
    if (response.statusCode != 201) throw Exception('Falha ao criar código geral');
  }

  Future<String> createSystemInvite(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/system-invite');
    final response = await http.post(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body)['code'];
    throw Exception('Falha ao gerar convite');
  }

  // Lista convites ativos
  Future<List<dynamic>> getSystemInvites(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/system-invites');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Falha ao buscar convites');
  }

  // Lista usuários pendentes de aprovação global
  Future<List<UserAdminView>> getPendingGlobalUsers(String token) async {
    final url = Uri.parse('$_baseUrl/admin-master/pending-global');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((json) => UserAdminView.fromJson(json)).toList();
    }
    throw Exception('Falha ao buscar pendentes globais');
  }

  // Aprova usuário global
  Future<void> approveGlobalUser(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/admin-master/approve-global/$userId');
    final response = await http.put(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) throw Exception('Falha ao aprovar usuário');
  }

  Future<List<CodeDetail>> getAdminGeneralCodes(String token) async {
      final url = Uri.parse('${ApiService._baseUrl}/admin-master/codes/general');
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CodeDetail.fromJson(json)).toList();
      }
      throw Exception('Falha ao buscar códigos');
    }
}
