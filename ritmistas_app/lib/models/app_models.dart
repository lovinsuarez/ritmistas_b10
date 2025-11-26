// lib/models/app_models.dart

// Este arquivo guarda APENAS a estrutura dos dados.
// Assim, qualquer página pode usá-los sem dar erro.

import 'package:intl/intl.dart'; // Para datas

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
  
  // CAMPO NOVO QUE FALTAVA:
  final String? checkinCode; 

  Activity({
    required this.activityId,
    required this.title,
    required this.activityDate,
    required this.pointsValue,
    required this.type,
    this.address,
    required this.isGeneral,
    this.checkinCode, // Adicionado ao construtor
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
      
      // Mapeia do JSON que vem do backend
      checkinCode: json['checkin_code'], 
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

class CheckInDetail {
  final String title;
  final int points;
  final DateTime date;
  CheckInDetail({required this.title, required this.points, required this.date});
  factory CheckInDetail.fromJson(Map<String, dynamic> json) => CheckInDetail(
    title: json['title'], points: json['points'], date: DateTime.parse(json['date']));
}

class CodeDetail {
  final String codeString;
  final int points;
  final DateTime date;

  CodeDetail({required this.codeString, required this.points, required this.date});

  factory CodeDetail.fromJson(Map<String, dynamic> json) {
    return CodeDetail(
      codeString: json['code_string'],
      // O Backend agora manda 'points_value', nós mapeamos para 'points'
      points: json['points_value'], 
      // O Backend agora manda 'created_at', nós mapeamos para 'date'
      date: DateTime.parse(json['created_at']), 
    );
  }
}

class UserDashboard {
  final int userId;
  final String username;
  final int totalPoints;
  final List<CheckInDetail> checkins;
  final List<CodeDetail> redeemedCodes;
  UserDashboard({required this.userId, required this.username, required this.totalPoints, required this.checkins, required this.redeemedCodes});
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