'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getUsersMe, updateProfile } from '@/lib/api';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { storage } from '@/lib/firebase';
import { formatDate, getInitials } from '@/lib/utils';
import type { UserProfile } from '@/lib/types';

export default function ProfilePage() {
  const { token, user, refreshUser } = useAuth();
  const [profile, setProfile] = useState<UserProfile | null>(user);
  const [loading, setLoading] = useState(!user);
  const [editing, setEditing] = useState(false);
  const [nickname, setNickname] = useState('');
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    if (!token) return;
    if (user) { setProfile(user); setLoading(false); return; }
    getUsersMe(token).then(setProfile).catch(() => {}).finally(() => setLoading(false));
  }, [token, user]);

  useEffect(() => {
    if (profile) setNickname(profile.nickname || '');
  }, [profile]);

  const handleSave = async () => {
    if (!token) return;
    setSaving(true);
    try {
      await updateProfile(token, { nickname: nickname || undefined });
      await refreshUser();
      setEditing(false);
      setMessage('Perfil atualizado!');
      setTimeout(() => setMessage(''), 3000);
    } catch {
      setMessage('Erro ao salvar');
    } finally {
      setSaving(false);
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !token || !profile) return;
    setSaving(true);
    try {
      const storageRef = ref(storage, `profile_pics/${profile.user_id}_${Date.now()}`);
      await uploadBytes(storageRef, file);
      const url = await getDownloadURL(storageRef);
      await updateProfile(token, { profile_pic: url });
      await refreshUser();
      setProfile((prev) => prev ? { ...prev, profile_pic: url } : prev);
      setMessage('Foto atualizada!');
      setTimeout(() => setMessage(''), 3000);
    } catch {
      setMessage('Erro ao enviar foto');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 'var(--space-3xl)' }}>
        <div className="spinner spinner-lg" />
      </div>
    );
  }

  if (!profile) return <div className="empty-state">Erro ao carregar perfil</div>;

  const roleName = profile.role === '0' ? 'Admin Master' : profile.role === '1' ? 'Líder' : 'Usuário';

  return (
    <div style={{ maxWidth: 700, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>
        Meu Perfil
      </h1>

      {message && <div className={`alert ${message.includes('Erro') ? 'alert-error' : 'alert-success'}`} style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      {/* Profile Card */}
      <div className="card" style={{ display: 'flex', gap: 'var(--space-lg)', alignItems: 'center', marginBottom: 'var(--space-lg)', flexWrap: 'wrap' }}>
        <div style={{ position: 'relative' }}>
          {profile.profile_pic ? (
            <img src={profile.profile_pic} alt="Avatar" className="avatar avatar-xl" />
          ) : (
            <div className="avatar avatar-xl" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 'var(--font-2xl)', fontWeight: 800, color: 'var(--accent)' }}>
              {getInitials(profile.nickname || profile.username)}
            </div>
          )}
          <label style={{ position: 'absolute', bottom: 4, right: 4, background: 'var(--accent)', borderRadius: '50%', width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', fontSize: '0.9rem' }}>
            📷
            <input type="file" accept="image/*" onChange={handleImageUpload} style={{ display: 'none' }} />
          </label>
        </div>

        <div style={{ flex: 1, minWidth: 200 }}>
          <h2 style={{ fontSize: 'var(--font-lg)', fontWeight: 700, margin: 0 }}>
            {profile.nickname || profile.username}
          </h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)', margin: '4px 0' }}>{profile.email}</p>
          <span className="badge badge-gold">{roleName}</span>
        </div>
      </div>

      {/* Stats */}
      <div className="stats-grid" style={{ marginBottom: 'var(--space-lg)' }}>
        <div className="stat-card">
          <div className="stat-value">{profile.total_points ?? 0}</div>
          <div className="stat-label">Pontos Totais</div>
        </div>
        {profile.sector_name && (
          <div className="stat-card">
            <div className="stat-value" style={{ fontSize: 'var(--font-lg)' }}>{profile.sector_name}</div>
            <div className="stat-label">Setor</div>
          </div>
        )}
        {profile.badges && (
          <div className="stat-card">
            <div className="stat-value">{profile.badges.length}</div>
            <div className="stat-label">Insígnias</div>
          </div>
        )}
      </div>

      {/* Edit section */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-md)' }}>
          <h3 style={{ fontSize: 'var(--font-md)', fontWeight: 700, margin: 0 }}>Informações</h3>
          {!editing && (
            <button className="btn btn-ghost btn-sm" onClick={() => setEditing(true)}>Editar</button>
          )}
        </div>

        {editing ? (
          <div>
            <div className="form-group" style={{ marginBottom: 'var(--space-md)' }}>
              <label className="label">Apelido</label>
              <input className="input" value={nickname} onChange={(e) => setNickname(e.target.value)} placeholder="Seu apelido" />
            </div>
            <div className="form-actions">
              <button className="btn btn-ghost btn-sm" onClick={() => setEditing(false)}>Cancelar</button>
              <button className="btn btn-primary btn-sm" onClick={handleSave} disabled={saving}>
                {saving ? 'Salvando...' : 'Salvar'}
              </button>
            </div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-sm)' }}>
            <div><span style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)' }}>Nome: </span>{profile.first_name ? `${profile.first_name} ${profile.last_name || ''}` : profile.username}</div>
            <div><span style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)' }}>Apelido: </span>{profile.nickname || '—'}</div>
            <div><span style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)' }}>Email: </span>{profile.email}</div>
            {profile.birth_date && <div><span style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)' }}>Nascimento: </span>{formatDate(profile.birth_date)}</div>}
          </div>
        )}
      </div>

      {/* Badges */}
      {profile.badges && profile.badges.length > 0 && (
        <div className="card" style={{ marginTop: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-md)', fontWeight: 700, marginBottom: 'var(--space-md)' }}>Insígnias</h3>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-sm)' }}>
            {profile.badges.map((ub, i) => (
              <div key={i} className="badge badge-gold" title={ub.badge.description || ''}>
                {ub.badge.icon_url ? <img src={ub.badge.icon_url} alt="" style={{ width: 16, height: 16 }} /> : '🏅'}
                {ub.badge.name}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Sector Points Breakdown */}
      {profile.sector_points && profile.sector_points.length > 0 && (
        <div className="card" style={{ marginTop: 'var(--space-lg)' }}>
          <h3 style={{ fontSize: 'var(--font-md)', fontWeight: 700, marginBottom: 'var(--space-md)' }}>Pontos por Setor</h3>
          <div className="table-container">
            <table className="table">
              <thead><tr><th>Setor</th><th>Pontos</th></tr></thead>
              <tbody>
                {profile.sector_points.map((sp) => (
                  <tr key={sp.sector_id}>
                    <td>{sp.sector_name}</td>
                    <td style={{ color: 'var(--accent)', fontWeight: 700 }}>{sp.points}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
