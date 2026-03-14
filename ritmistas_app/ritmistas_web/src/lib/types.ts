// src/lib/types.ts — 1:1 mapping from app_models.dart

export interface RankingEntry {
  user_id: number;
  username: string;
  nickname?: string;
  profile_pic?: string;
  total_points: number;
}

export interface Badge {
  badge_id: number;
  name: string;
  description?: string;
  icon_url?: string;
}

export interface UserBadge {
  badge: Badge;
  awarded_at: string;
}

export interface UserSectorPoints {
  sector_id: number;
  sector_name: string;
  points: number;
}

export interface UserAdminView {
  user_id: number;
  username: string;
  email: string;
  role: string;
  status: string;
}

export interface Sector {
  sector_id: number;
  name: string;
  invite_code: string;
  lider_id?: number;
}

export interface Activity {
  activity_id: number;
  title: string;
  activity_date: string;
  points_value: number;
  type: string;
  address?: string;
  is_general: boolean;
  checkin_code?: string;
}

export interface CheckInDetail {
  title: string;
  points: number;
  date: string;
}

export interface CodeDetail {
  code_string: string;
  points_value: number;
  created_at: string;
  title?: string;
  description?: string;
  event_date?: string;
}

export interface UserDashboard {
  user_id: number;
  username: string;
  total_points: number;
  checkins: CheckInDetail[];
  redeemed_codes: CodeDetail[];
}

export interface AuditLogItem {
  timestamp: string;
  type: string;
  user_name: string;
  lider_name: string;
  sector_name: string;
  description: string;
  points: number;
  is_general: boolean;
}

export interface UserProfile {
  user_id: number;
  username: string;
  email: string;
  role: string;
  status: string;
  nickname?: string;
  first_name?: string;
  last_name?: string;
  profile_pic?: string;
  birth_date?: string;
  total_points?: number;
  sector_name?: string;
  sector_id?: number;
  badges?: UserBadge[];
  sector_points?: UserSectorPoints[];
}

export type UserRole = '0' | '1' | '2';

export function getRoleName(role: UserRole): string {
  switch (role) {
    case '0': return 'Admin Master';
    case '1': return 'Líder';
    case '2': return 'Usuário';
    default: return 'Desconhecido';
  }
}
