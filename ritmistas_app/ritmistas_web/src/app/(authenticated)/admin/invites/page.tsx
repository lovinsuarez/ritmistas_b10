'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getSystemInvites, createSystemInvite } from '@/lib/api';
import { formatDateTime } from '@/lib/utils';

interface Invite { code: string; used: boolean; created_at: string; }

export default function AdminInvitesPage() {
  const { token } = useAuth();
  const [invites, setInvites] = useState<Invite[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [newCode, setNewCode] = useState('');
  const [message, setMessage] = useState('');

  const load = () => { if (!token) return; setLoading(true); getSystemInvites(token).then(setInvites).catch(() => {}).finally(() => setLoading(false)); };
  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handleCreate = async () => {
    if (!token) return;
    setCreating(true);
    try { const code = await createSystemInvite(token); setNewCode(code); setMessage('Convite criado!'); load(); setTimeout(() => setMessage(''), 5000); }
    catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
    finally { setCreating(false); }
  };

  const copyCode = (code: string) => { navigator.clipboard.writeText(code); setMessage('Código copiado!'); setTimeout(() => setMessage(''), 2000); };

  return (
    <div style={{ maxWidth: 700, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800 }}>🔑 Convites</h1>
        <button className="btn btn-primary btn-sm" onClick={handleCreate} disabled={creating}>{creating ? '...' : '+ Gerar Convite'}</button>
      </div>
      {message && <div className="alert alert-success" style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      {newCode && (
        <div className="card" style={{ marginBottom: 'var(--space-lg)', textAlign: 'center', borderColor: 'var(--accent)' }}>
          <p style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)', marginBottom: 'var(--space-sm)' }}>Novo código de convite:</p>
          <code style={{ fontSize: 'var(--font-xl)', color: 'var(--accent)', fontWeight: 700 }}>{newCode}</code>
          <button className="btn btn-outline btn-sm" style={{ marginTop: 'var(--space-sm)', display: 'block', margin: 'var(--space-sm) auto 0' }} onClick={() => copyCode(newCode)}>📋 Copiar</button>
        </div>
      )}

      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : invites.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">🔑</div><p>Nenhum convite gerado</p></div>
      ) : (
        <div className="table-container">
          <table className="table"><thead><tr><th>Código</th><th>Status</th><th>Criado</th><th></th></tr></thead><tbody>
            {invites.map((inv, i) => (
              <tr key={i}><td><code style={{ color: 'var(--accent)' }}>{inv.code}</code></td>
                <td><span className={`badge ${inv.used ? 'badge-error' : 'badge-success'}`}>{inv.used ? 'Usado' : 'Disponível'}</span></td>
                <td style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-xs)' }}>{formatDateTime(inv.created_at)}</td>
                <td>{!inv.used && <button className="btn btn-ghost btn-sm" onClick={() => copyCode(inv.code)}>📋</button>}</td>
              </tr>
            ))}
          </tbody></table>
        </div>
      )}
    </div>
  );
}
