'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getSectorUsers, deleteUser, distributePoints } from '@/lib/api';
import type { UserAdminView } from '@/lib/types';

export default function LeaderUsersPage() {
  const { token } = useAuth();
  const [users, setUsers] = useState<UserAdminView[]>([]);
  const [loading, setLoading] = useState(true);
  const [distributing, setDistributing] = useState<number | null>(null);
  const [points, setPoints] = useState('');
  const [desc, setDesc] = useState('');
  const [message, setMessage] = useState('');

  const load = () => { if (!token) return; setLoading(true); getSectorUsers(token).then(setUsers).catch(() => {}).finally(() => setLoading(false)); };
  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handleDistribute = async (userId: number) => {
    if (!token || !points) return;
    try { await distributePoints(token, userId, Number(points), desc || 'Pontos distribuídos'); setDistributing(null); setPoints(''); setDesc(''); setMessage('Pontos distribuídos!'); load(); setTimeout(() => setMessage(''), 3000); }
    catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
  };

  const handleDelete = async (userId: number) => {
    if (!token || !confirm('Remover este usuário?')) return;
    try { await deleteUser(token, userId); load(); } catch {}
  };

  return (
    <div style={{ maxWidth: 800, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>👥 Usuários do Setor</h1>
      {message && <div className="alert alert-success" style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}
      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : users.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">👥</div><p>Nenhum usuário no setor</p></div>
      ) : (
        <div className="table-container">
          <table className="table">
            <thead><tr><th>Usuário</th><th>Email</th><th>Status</th><th>Ações</th></tr></thead>
            <tbody>{users.map((u) => (
              <tr key={u.user_id}>
                <td style={{ fontWeight: 600 }}>{u.username}</td>
                <td style={{ color: 'var(--text-secondary)' }}>{u.email}</td>
                <td><span className={`badge ${u.status === 'active' ? 'badge-success' : 'badge-error'}`}>{u.status}</span></td>
                <td>
                  <div style={{ display: 'flex', gap: 'var(--space-xs)' }}>
                    <button className="btn btn-primary btn-sm" onClick={() => setDistributing(distributing === u.user_id ? null : u.user_id)}>⭐ Pontos</button>
                    <button className="btn btn-danger btn-sm" onClick={() => handleDelete(u.user_id)}>🗑</button>
                  </div>
                  {distributing === u.user_id && (
                    <div style={{ marginTop: 'var(--space-sm)', display: 'flex', gap: 'var(--space-xs)', alignItems: 'center' }}>
                      <input className="input" type="number" placeholder="Pts" value={points} onChange={(e) => setPoints(e.target.value)} style={{ width: 80 }} />
                      <input className="input" placeholder="Descrição" value={desc} onChange={(e) => setDesc(e.target.value)} style={{ width: 150 }} />
                      <button className="btn btn-primary btn-sm" onClick={() => handleDistribute(u.user_id)}>Enviar</button>
                    </div>
                  )}
                </td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </div>
  );
}
