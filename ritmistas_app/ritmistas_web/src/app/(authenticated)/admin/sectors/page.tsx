'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getAllSectors, createSector, getAllLiders, assignLiderToSector, getUsersForSector, syncEcosystemData } from '@/lib/api';
import type { Sector, UserAdminView } from '@/lib/types';

export default function AdminSectorsPage() {
  const { token } = useAuth();
  const [sectors, setSectors] = useState<Sector[]>([]);
  const [liders, setLiders] = useState<UserAdminView[]>([]);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState('');
  const [message, setMessage] = useState('');
  const [syncing, setSyncing] = useState(false);
  const [expandedSector, setExpandedSector] = useState<number | null>(null);
  const [sectorUsers, setSectorUsers] = useState<UserAdminView[]>([]);
  const [sectorUsersLoading, setSectorUsersLoading] = useState(false);

  const load = () => { if (!token) return; setLoading(true); Promise.all([getAllSectors(token), getAllLiders(token)]).then(([s, l]) => { setSectors(s); setLiders(l); }).catch(() => {}).finally(() => setLoading(false)); };
  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handleSync = async () => {
    if (!token) return;
    setSyncing(true);
    try {
      const stats = await syncEcosystemData(token);
      setMessage(`Sincronização concluída! Setores: ${stats.sectors_created}, Membros: ${stats.members_synced}`);
      load();
      setTimeout(() => setMessage(''), 5000);
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Erro na sincronização');
    } finally {
      setSyncing(false);
    }
  };

  const handleCreate = async () => {
    if (!token || !newName.trim()) return;
    try { await createSector(token, newName.trim()); setNewName(''); setMessage('Setor criado!'); load(); setTimeout(() => setMessage(''), 3000); }
    catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
  };

  const handleAssign = async (sectorId: number, liderId: number) => {
    if (!token) return;
    try { await assignLiderToSector(token, sectorId, liderId); setMessage('Líder designado!'); load(); setTimeout(() => setMessage(''), 3000); }
    catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
  };

  const toggleSectorUsers = async (sectorId: number) => {
    if (expandedSector === sectorId) { setExpandedSector(null); return; }
    if (!token) return;
    setExpandedSector(sectorId);
    setSectorUsersLoading(true);
    try { const users = await getUsersForSector(token, sectorId); setSectorUsers(users); }
    catch { setSectorUsers([]); }
    finally { setSectorUsersLoading(false); }
  };

  return (
    <div style={{ maxWidth: 900, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, margin: 0 }}>🏢 Setores</h1>
        <button className="btn btn-ghost btn-sm" onClick={handleSync} disabled={syncing}>
          {syncing ? 'Sincronizando...' : '🔄 Sincronizar com Ecossistema'}
        </button>
      </div>

      {message && <div className={`alert ${message.includes('Erro') ? 'alert-error' : 'alert-success'}`} style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      {/* Create */}
      <div className="card" style={{ display: 'flex', gap: 'var(--space-sm)', marginBottom: 'var(--space-lg)', alignItems: 'end' }}>
        <div className="form-group" style={{ flex: 1 }}><label className="label">Novo Setor</label><input className="input" placeholder="Nome do setor" value={newName} onChange={(e) => setNewName(e.target.value)} /></div>
        <button className="btn btn-primary" onClick={handleCreate} disabled={!newName.trim()}>Criar</button>
      </div>

      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : sectors.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">🏢</div><p>Nenhum setor</p></div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-md)' }}>
          {sectors.map((s) => (
            <div key={s.sector_id} className="card">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--space-sm)' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 'var(--font-md)' }}>{s.name}</div>
                  <div style={{ fontSize: 'var(--font-xs)', color: 'var(--text-muted)' }}>Código: <code style={{ color: 'var(--accent)' }}>{s.invite_code}</code></div>
                </div>
                <div style={{ display: 'flex', gap: 'var(--space-sm)', alignItems: 'center' }}>
                  <select className="input" style={{ width: 'auto', padding: '8px 12px' }} value={s.lider_id || ''} onChange={(e) => handleAssign(s.sector_id, Number(e.target.value))}>
                    <option value="">Sem líder</option>
                    {liders.map((l) => <option key={l.user_id} value={l.user_id}>{l.username}</option>)}
                  </select>
                  <button className="btn btn-ghost btn-sm" onClick={() => toggleSectorUsers(s.sector_id)}>
                    {expandedSector === s.sector_id ? '▲' : '▼'} Usuários
                  </button>
                </div>
              </div>
              {expandedSector === s.sector_id && (
                <div style={{ marginTop: 'var(--space-md)', borderTop: '1px solid var(--border-subtle)', paddingTop: 'var(--space-md)' }}>
                  {sectorUsersLoading ? <div className="spinner" style={{ margin: '0 auto' }} /> : sectorUsers.length === 0 ? <p style={{ color: 'var(--text-muted)', fontSize: 'var(--font-sm)' }}>Nenhum usuário</p> : (
                    <div style={{ display: 'grid', gap: 'var(--space-xs)' }}>
                      {sectorUsers.map((u) => <div key={u.user_id} style={{ fontSize: 'var(--font-sm)', display: 'flex', justifyContent: 'space-between' }}><span>{u.username}</span><span style={{ color: 'var(--text-muted)' }}>{u.email}</span></div>)}
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
