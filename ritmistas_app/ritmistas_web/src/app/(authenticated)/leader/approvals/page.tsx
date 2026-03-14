'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getPendingUsers, approveUser, rejectUser } from '@/lib/api';
import type { UserAdminView } from '@/lib/types';

export default function LeaderApprovalsPage() {
  const { token } = useAuth();
  const [pending, setPending] = useState<UserAdminView[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<number | null>(null);

  const load = () => {
    if (!token) return;
    setLoading(true);
    getPendingUsers(token).then(setPending).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handleApprove = async (userId: number) => {
    if (!token) return;
    setActionLoading(userId);
    try { await approveUser(token, userId); load(); }
    catch {} finally { setActionLoading(null); }
  };

  const handleReject = async (userId: number) => {
    if (!token) return;
    setActionLoading(userId);
    try { await rejectUser(token, userId); load(); }
    catch {} finally { setActionLoading(null); }
  };

  return (
    <div style={{ maxWidth: 700, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>🔔 Aprovações Pendentes</h1>
      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : pending.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">✅</div><p>Nenhum pendente</p></div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-md)' }}>
          {pending.map((u) => (
            <div key={u.user_id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--space-sm)' }}>
              <div><div style={{ fontWeight: 600 }}>{u.username}</div><div style={{ fontSize: 'var(--font-sm)', color: 'var(--text-secondary)' }}>{u.email}</div></div>
              <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                <button className="btn btn-primary btn-sm" onClick={() => handleApprove(u.user_id)} disabled={actionLoading === u.user_id}>✓ Aprovar</button>
                <button className="btn btn-danger btn-sm" onClick={() => handleReject(u.user_id)} disabled={actionLoading === u.user_id}>✗ Rejeitar</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
