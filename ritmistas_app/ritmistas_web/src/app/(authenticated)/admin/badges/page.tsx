'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getAllBadges, createBadge } from '@/lib/api';
import type { Badge } from '@/lib/types';

export default function AdminBadgesPage() {
  const { token } = useAuth();
  const [badges, setBadges] = useState<Badge[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [form, setForm] = useState({ name: '', description: '', icon_url: '' });

  const load = () => { if (!token) return; setLoading(true); getAllBadges(token).then(setBadges).catch(() => {}).finally(() => setLoading(false)); };
  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setSaving(true);
    try { await createBadge(token, form.name, form.description, form.icon_url); setShowForm(false); setForm({ name: '', description: '', icon_url: '' }); setMessage('Insígnia criada!'); load(); setTimeout(() => setMessage(''), 3000); }
    catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
    finally { setSaving(false); }
  };

  return (
    <div style={{ maxWidth: 700, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800 }}>🎖️ Insígnias</h1>
        <button className="btn btn-primary btn-sm" onClick={() => setShowForm(!showForm)}>{showForm ? 'Cancelar' : '+ Nova Insígnia'}</button>
      </div>
      {message && <div className="alert alert-success" style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      {showForm && (
        <form className="card" style={{ marginBottom: 'var(--space-lg)' }} onSubmit={handleCreate}>
          <div className="form-group" style={{ marginBottom: 'var(--space-md)' }}><label className="label">Nome</label><input className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required /></div>
          <div className="form-group" style={{ marginBottom: 'var(--space-md)' }}><label className="label">Descrição</label><input className="input" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
          <div className="form-group" style={{ marginBottom: 'var(--space-md)' }}><label className="label">URL do Ícone</label><input className="input" value={form.icon_url} onChange={(e) => setForm({ ...form, icon_url: e.target.value })} placeholder="https://..." /></div>
          <div className="form-actions"><button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Criando...' : 'Criar'}</button></div>
        </form>
      )}

      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : badges.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">🎖️</div><p>Nenhuma insígnia</p></div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(180px, 1fr))', gap: 'var(--space-md)' }}>
          {badges.map((b) => (
            <div key={b.badge_id} className="card" style={{ textAlign: 'center' }}>
              {b.icon_url ? <img src={b.icon_url} alt="" style={{ width: 48, height: 48, borderRadius: 8, margin: '0 auto var(--space-sm)' }} /> : <div style={{ fontSize: '2rem', marginBottom: 'var(--space-sm)' }}>🏅</div>}
              <div style={{ fontWeight: 700 }}>{b.name}</div>
              {b.description && <div style={{ fontSize: 'var(--font-xs)', color: 'var(--text-secondary)', marginTop: 4 }}>{b.description}</div>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
