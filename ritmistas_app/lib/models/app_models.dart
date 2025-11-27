// lib/models/app_models.dart

// import 'package:intl/intl.dart'; // removido pois não está em uso

// --- RANKING ---
class RankingEntry {
  final int userId;
  final String username;
  final String? nickname;   
  final String? profilePic; 
  final int totalPoints;

  RankingEntry({
    required this.userId,
    required this.username,
    this.nickname,
    this.profilePic,
    required this.totalPoints,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      userId: json['user_id'],
      username: json['username'],
      nickname: json['nickname'],
      profilePic: json['profile_pic'],
      totalPoints: json['total_points'],
    );
  }
}

// --- INSÍGNIAS ---
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

// --- USUÁRIO E PERFIL ---
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

// --- ESTRUTURA ---
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

// --- ATIVIDADES ---
class Activity {
  final int activityId;
  final String title;
  final DateTime activityDate;
  final int pointsValue;
  final String type;
  final String? address;
  final bool isGeneral;
  final String? checkinCode; 

  Activity({
    required this.activityId,
    required this.title,
    required this.activityDate,
    required this.pointsValue,
    required this.type,
    this.address,
    required this.isGeneral,
    this.checkinCode,
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
      checkinCode: json['checkin_code'],
    );
  }
}

// --- DASHBOARD E CÓDIGOS (CORREÇÃO AQUI) ---

class CheckInDetail {
  final String title;
  final int points;
  final DateTime date;

  CheckInDetail({required this.title, required this.points, required this.date});

  factory CheckInDetail.fromJson(Map<String, dynamic> json) => CheckInDetail(
    title: json['title'],
    points: json['points'],
    date: DateTime.parse(json['date']),
  );
}

// AQUI ESTÁ A CLASSE ATUALIZADA COM OS NOVOS CAMPOS:
class CodeDetail {
  final String codeString;
  final int points;
  final DateTime date;
  
  // Campos novos V4.0
  final String? title;       
  final String? description; 
  final DateTime? eventDate; 

  CodeDetail({
    required this.codeString, 
    required this.points, 
    required this.date,
    this.title,
    this.description,
    this.eventDate
  });

  factory CodeDetail.fromJson(Map<String, dynamic> json) => CodeDetail(
    codeString: json['code_string'],
    // MAPEAMENTO CORRIGIDO:
    points: json['points_value'], // Lê 'points_value' do JSON e põe em 'points'
    date: DateTime.parse(json['created_at']), // Lê 'created_at' e põe em 'date'
    
    // Novos campos
    title: json['title'],
    description: json['description'],
    eventDate: json['event_date'] != null ? DateTime.parse(json['event_date']) : null,
  );
}

class UserDashboard {
  final int userId;
  final String username;
  final int totalPoints;
  final List<CheckInDetail> checkins;
  final List<CodeDetail> redeemedCodes;

  UserDashboard({
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.checkins,
    required this.redeemedCodes,
  });

  factory UserDashboard.fromJson(Map<String, dynamic> json) {
    return UserDashboard(
      userId: json['user_id'],
      username: json['username'],
      totalPoints: json['total_points'],
      checkins: (json['checkins'] as List).map((i) => CheckInDetail.fromJson(i)).toList(),
      redeemedCodes: (json['redeemed_codes'] as List).map((i) => CodeDetail.fromJson(i)).toList(),
    );
  }
}

// --- AUDITORIA ---
class AuditLogItem {
  final DateTime timestamp;
  final String type;
  final String userName;
  final String liderName;
  final String sectorName;
  final String description;
  final int points;
  final bool isGeneral;

  AuditLogItem({
    required this.timestamp,
    required this.type,
    required this.userName,
    required this.liderName,
    required this.sectorName,
    required this.description,
    required this.points,
    required this.isGeneral,
  });

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    return AuditLogItem(
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      userName: json['user_name'],
      liderName: json['lider_name'],
      sectorName: json['sector_name'],
      description: json['description'],
      points: json['points'],
      isGeneral: json['is_general'],
    );
  }
}