'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getAllLiders, getAllUsers, promoteUserToLider, demoteLiderToUser, addBudget } from '@/lib/api';
import type { UserAdminView } from '@/lib/types';

export default function AdminLeadersPage() {
  const { token } = useAuth();
  const [liders, setLiders] = useState<UserAdminView[]>([]);
  const [allUsers, setAllUsers] = useState<UserAdminView[]>([]);
  const [loading, setLoading] = useState(true);
  const [budgetId, setBudgetId] = useState<number | null>(null);
  const [budgetPts, setBudgetPts] = useState('');
  const [message, setMessage] = useState('');

  const load = () => { if (!token) return; setLoading(true); Promise.all([getAllLiders(token), getAllUsers(token)]).then(([l, u]) => { setLiders(l); setAllUsers(u); }).catch(() => {}).finally(() => setLoading(false)); };
  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handlePromote = async (userId: number) => { if (!token) return; try { await promoteUserToLider(token, userId); setMessage('Promovido!'); load(); setTimeout(() => setMessage(''), 3000); } catch {} };
  const handleDemote = async (liderId: number) => { if (!token || !confirm('Rebaixar este líder?')) return; try { await demoteLiderToUser(token, liderId); setMessage('Rebaixado!'); load(); setTimeout(() => setMessage(''), 3000); } catch {} };
  const handleBudget = async (liderId: number) => { if (!token || !budgetPts) return; try { await addBudget(token, liderId, Number(budgetPts)); setBudgetId(null); setBudgetPts(''); setMessage('Budget adicionado!'); setTimeout(() => setMessage(''), 3000); } catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); } };

  const regularUsers = allUsers.filter((u) => u.role === '2' || u.role === 'user');

  return (
    <div style={{ maxWidth: 900, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>⚙️ Líderes</h1>
      {message && <div className="alert alert-success" style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      <h2 style={{ fontSize: 'var(--font-lg)', fontWeight: 700, marginBottom: 'var(--space-md)' }}>Líderes Atuais</h2>
      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-2xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : liders.length === 0 ? <p style={{ color: 'var(--text-muted)' }}>Nenhum líder</p> : (
        <div className="table-container" style={{ marginBottom: 'var(--space-xl)' }}>
          <table className="table"><thead><tr><th>Nome</th><th>Email</th><th>Ações</th></tr></thead><tbody>
            {liders.map((l) => (
              <tr key={l.user_id}><td style={{ fontWeight: 600 }}>{l.username}</td><td style={{ color: 'var(--text-secondary)' }}>{l.email}</td><td>
                <div style={{ display: 'flex', gap: 'var(--space-xs)', flexWrap: 'wrap' }}>
                  <button className="btn btn-primary btn-sm" onClick={() => setBudgetId(budgetId === l.user_id ? null : l.user_id)}>💰 Budget</button>
                  <button className="btn btn-danger btn-sm" onClick={() => handleDemote(l.user_id)}>↓ Rebaixar</button>
                </div>
                {budgetId === l.user_id && (
                  <div style={{ marginTop: 'var(--space-sm)', display: 'flex', gap: 'var(--space-xs)' }}>
                    <input className="input" type="number" placeholder="Pontos" value={budgetPts} onChange={(e) => setBudgetPts(e.target.value)} style={{ width: 100 }} />
                    <button className="btn btn-primary btn-sm" onClick={() => handleBudget(l.user_id)}>Enviar</button>
                  </div>
                )}
              </td></tr>
            ))}
          </tbody></table>
        </div>
      )}

      <h2 style={{ fontSize: 'var(--font-lg)', fontWeight: 700, marginBottom: 'var(--space-md)' }}>Promover Usuário</h2>
      {regularUsers.length === 0 ? <p style={{ color: 'var(--text-muted)' }}>Nenhum usuário disponível</p> : (
        <div className="table-container">
          <table className="table"><thead><tr><th>Nome</th><th>Email</th><th>Ação</th></tr></thead><tbody>
            {regularUsers.map((u) => (
              <tr key={u.user_id}><td>{u.username}</td><td style={{ color: 'var(--text-secondary)' }}>{u.email}</td>
                <td><button className="btn btn-outline btn-sm" onClick={() => handlePromote(u.user_id)}>↑ Promover</button></td>
              </tr>
            ))}
          </tbody></table>
        </div>
      )}
    </div>
  );
}
