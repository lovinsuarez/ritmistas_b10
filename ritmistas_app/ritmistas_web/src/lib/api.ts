// src/lib/api.ts — Full port of Dart ApiService (38 functions)
import type {
  Activity,
  AuditLogItem,
  Badge,
  CodeDetail,
  RankingEntry,
  Sector,
  UserAdminView,
  UserDashboard,
  UserProfile,
} from './types';

const BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'https://ritmistas-api.onrender.com';

function authHeaders(token: string): Record<string, string> {
  return { Authorization: `Bearer ${token}` };
}

function jsonAuthHeaders(token: string): Record<string, string> {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    let detail = `HTTP ${res.status}`;
    try {
      const data = await res.json();
      detail = data.detail || JSON.stringify(data);
    } catch {
      // ignore parse errors
    }
    throw new Error(detail);
  }
  return res.json();
}

async function handleVoidResponse(res: Response): Promise<void> {
  if (!res.ok) {
    let detail = `HTTP ${res.status}`;
    try {
      const data = await res.json();
      detail = data.detail || JSON.stringify(data);
    } catch {
      // ignore
    }
    throw new Error(detail);
  }
}

// ──────────────────────────── AUTH ────────────────────────────

export async function login(email: string, password: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/auth/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ username: email, password }),
  });
  const data = await handleResponse<{ access_token: string }>(res);
  return data.access_token;
}

export async function loginWithGoogleToken(
  email: string,
  username: string,
  googleId: string,
  inviteCode?: string
): Promise<string> {
  const res = await fetch(`${BASE_URL}/auth/google`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      username,
      google_id: googleId,
      invite_code: inviteCode || null,
    }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    if (data.detail === 'NEED_INVITE_CODE') throw new Error('NEED_INVITE_CODE');
    throw new Error(data.detail || `HTTP ${res.status}`);
  }
  const data = await res.json();
  return data.access_token;
}

export async function registerAdminMaster(email: string, password: string, username: string): Promise<void> {
  const res = await fetch(`${BASE_URL}/auth/register/admin-master`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, username, password }),
  });
  await handleVoidResponse(res);
}

export async function registerUser(
  email: string,
  password: string,
  username: string,
  inviteCode: string
): Promise<void> {
  const res = await fetch(`${BASE_URL}/auth/register/user`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, username, password, invite_code: inviteCode }),
  });
  if (res.status !== 201) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.detail || 'Falha ao registrar');
  }
}

export async function sendRecoveryEmail(email: string): Promise<void> {
  const res = await fetch(
    `${BASE_URL}/auth/send-recovery-password-email?to_address=${encodeURIComponent(email)}`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' } }
  );
  await handleVoidResponse(res);
}

export async function recoverPassword(email: string, code: string, newPassword: string): Promise<void> {
  const res = await fetch(`${BASE_URL}/auth/recover-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, code, new_password: newPassword }),
  });
  await handleVoidResponse(res);
}

// ──────────────────────────── USER ────────────────────────────

export async function getUsersMe(token: string): Promise<UserProfile> {
  const res = await fetch(`${BASE_URL}/users/me`, { headers: authHeaders(token) });
  return handleResponse<UserProfile>(res);
}

export async function updateProfile(
  token: string,
  data: { nickname?: string; profile_pic?: string; birth_date?: string }
): Promise<void> {
  const res = await fetch(`${BASE_URL}/users/me/profile`, {
    method: 'PUT',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify(data),
  });
  await handleVoidResponse(res);
}

export async function joinSector(token: string, inviteCode: string): Promise<void> {
  const res = await fetch(`${BASE_URL}/user/join-sector`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ invite_code: inviteCode }),
  });
  await handleVoidResponse(res);
}

export async function redeemCode(token: string, code: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/user/redeem`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ code_string: code }),
  });
  const data = await handleResponse<{ detail: string }>(res);
  return data.detail;
}

export async function checkIn(token: string, activityCode: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/user/checkin`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ activity_code: activityCode }),
  });
  const data = await handleResponse<{ detail: string }>(res);
  return data.detail;
}

// ──────────────────────────── RANKING ────────────────────────────

export async function getGeralRanking(token: string): Promise<{ ranking: RankingEntry[]; sectors: Sector[] }> {
  const res = await fetch(`${BASE_URL}/ranking/geral`, { headers: authHeaders(token) });
  return handleResponse(res);
}

export async function getSpecificSectorRanking(
  token: string,
  sectorId: number
): Promise<{ ranking: RankingEntry[] }> {
  const res = await fetch(`${BASE_URL}/ranking/sector/${sectorId}`, {
    headers: authHeaders(token),
  });
  return handleResponse(res);
}

// ──────────────────────────── LEADER ────────────────────────────

export async function createActivity(
  token: string,
  data: {
    title: string;
    description?: string;
    type: string;
    address?: string;
    activity_date: string;
    points_value: number;
  }
): Promise<void> {
  const res = await fetch(`${BASE_URL}/lider/activities`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify(data),
  });
  if (res.status !== 200 && res.status !== 201) {
    throw new Error('Falha ao criar atividade');
  }
}

export async function getActivities(token: string): Promise<Activity[]> {
  const res = await fetch(`${BASE_URL}/lider/activities`, { headers: authHeaders(token) });
  return handleResponse<Activity[]>(res);
}

export async function getSectorUsers(token: string): Promise<UserAdminView[]> {
  const res = await fetch(`${BASE_URL}/lider/users`, { headers: authHeaders(token) });
  return handleResponse<UserAdminView[]>(res);
}

export async function getPendingUsers(token: string): Promise<UserAdminView[]> {
  const res = await fetch(`${BASE_URL}/lider/pending-users`, { headers: authHeaders(token) });
  return handleResponse<UserAdminView[]>(res);
}

export async function approveUser(token: string, userId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/lider/approve-user/${userId}`, {
    method: 'PUT',
    headers: authHeaders(token),
  });
  await handleVoidResponse(res);
}

export async function rejectUser(token: string, userId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/lider/reject-user/${userId}`, {
    method: 'DELETE',
    headers: authHeaders(token),
  });
  if (res.status !== 200 && res.status !== 204) throw new Error('Erro rejeitar');
}

export async function deleteUser(token: string, userId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/lider/users/${userId}`, {
    method: 'DELETE',
    headers: authHeaders(token),
  });
  if (res.status !== 200 && res.status !== 204) throw new Error('Erro deletar');
}

export async function getUserDashboard(token: string, userId: number): Promise<UserDashboard> {
  const res = await fetch(`${BASE_URL}/lider/users/${userId}/dashboard`, {
    headers: authHeaders(token),
  });
  return handleResponse<UserDashboard>(res);
}

export async function distributePoints(
  token: string,
  userId: number,
  points: number,
  description: string
): Promise<void> {
  const res = await fetch(`${BASE_URL}/lider/distribute-points`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ user_id: userId, points, description }),
  });
  await handleVoidResponse(res);
}

export async function createGeneralCode(
  token: string,
  codeString: string,
  pointsValue: number
): Promise<void> {
  const res = await fetch(`${BASE_URL}/lider/codes/general`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ code_string: codeString, points_value: pointsValue }),
  });
  if (res.status !== 201) throw new Error('Falha ao criar código');
}

// ──────────────────────────── ADMIN MASTER ────────────────────────────

export async function addBudget(token: string, liderId: number, points: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/budget`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ lider_id: liderId, points }),
  });
  await handleVoidResponse(res);
}

export async function createBadge(
  token: string,
  name: string,
  description: string,
  iconUrl: string
): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/badges`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ name, description, icon_url: iconUrl }),
  });
  await handleVoidResponse(res);
}

export async function getAllBadges(token: string): Promise<Badge[]> {
  const res = await fetch(`${BASE_URL}/admin-master/badges`, { headers: authHeaders(token) });
  return handleResponse<Badge[]>(res);
}

export async function awardBadge(token: string, userId: number, badgeId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/award-badge`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ user_id: userId, badge_id: badgeId }),
  });
  await handleVoidResponse(res);
}

export async function createSector(token: string, sectorName: string): Promise<Sector> {
  const res = await fetch(`${BASE_URL}/admin-master/sectors`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ name: sectorName }),
  });
  return handleResponse<Sector>(res);
}

export async function getAllSectors(token: string): Promise<Sector[]> {
  const res = await fetch(`${BASE_URL}/admin-master/sectors`, { headers: authHeaders(token) });
  return handleResponse<Sector[]>(res);
}

export async function getAllLiders(token: string): Promise<UserAdminView[]> {
  const res = await fetch(`${BASE_URL}/admin-master/liders`, { headers: authHeaders(token) });
  return handleResponse<UserAdminView[]>(res);
}

export async function getAllUsers(token: string): Promise<UserAdminView[]> {
  const res = await fetch(`${BASE_URL}/admin-master/users`, { headers: authHeaders(token) });
  return handleResponse<UserAdminView[]>(res);
}

export async function promoteUserToLider(token: string, userId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/users/${userId}/promote-to-lider`, {
    method: 'PUT',
    headers: authHeaders(token),
  });
  await handleVoidResponse(res);
}

export async function demoteLiderToUser(token: string, liderId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/liders/${liderId}/demote-to-user`, {
    method: 'PUT',
    headers: authHeaders(token),
  });
  await handleVoidResponse(res);
}

export async function assignLiderToSector(
  token: string,
  sectorId: number,
  liderId: number
): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/sectors/${sectorId}/assign-lider`, {
    method: 'PUT',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ lider_id: liderId }),
  });
  await handleVoidResponse(res);
}

export async function getAuditLogs(token: string): Promise<AuditLogItem[]> {
  const res = await fetch(`${BASE_URL}/admin-master/audit/json`, {
    headers: authHeaders(token),
  });
  return handleResponse(res);
}

export async function getUsersForSector(token: string, sectorId: number): Promise<UserAdminView[]> {
  const res = await fetch(`${BASE_URL}/admin-master/sectors/${sectorId}/users`, {
    headers: authHeaders(token),
  });
  return handleResponse<UserAdminView[]>(res);
}

export async function createAdminGeneralCode(
  token: string,
  data: { points_value: number; code_string?: string; title?: string; description?: string }
): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/codes/general`, {
    method: 'POST',
    headers: jsonAuthHeaders(token),
    body: JSON.stringify({ ...data, is_general: true }),
  });
  if (res.status !== 201 && res.status !== 200) {
    throw new Error('Falha ao criar código geral');
  }
}

export async function createSystemInvite(token: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/admin-master/system-invite`, {
    method: 'POST',
    headers: authHeaders(token),
  });
  const data = await handleResponse<{ code: string }>(res);
  return data.code;
}

export async function getSystemInvites(token: string): Promise<Array<{ code: string; used: boolean; created_at: string }>> {
  const res = await fetch(`${BASE_URL}/admin-master/system-invites`, {
    headers: authHeaders(token),
  });
  return handleResponse(res);
}

export async function getPendingGlobalUsers(token: string): Promise<UserAdminView[]> {
  const res = await fetch(`${BASE_URL}/admin-master/pending-global`, {
    headers: authHeaders(token),
  });
  return handleResponse<UserAdminView[]>(res);
}

export async function approveGlobalUser(token: string, userId: number): Promise<void> {
  const res = await fetch(`${BASE_URL}/admin-master/approve-global/${userId}`, {
    method: 'PUT',
    headers: authHeaders(token),
  });
  await handleVoidResponse(res);
}

export async function getAdminGeneralCodes(token: string): Promise<CodeDetail[]> {
  const res = await fetch(`${BASE_URL}/admin-master/codes/general`, {
    headers: authHeaders(token),
  });
  return handleResponse<CodeDetail[]>(res);
}
