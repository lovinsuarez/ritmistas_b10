'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getAdminGeneralCodes, createAdminGeneralCode } from '@/lib/api';
import { formatDate } from '@/lib/utils';
import type { CodeDetail } from '@/lib/types';

export default function AdminPointsPage() {
  const { token } = useAuth();
  const [codes, setCodes] = useState<CodeDetail[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [form, setForm] = useState({ code_string: '', points_value: 10, title: '', description: '' });

  const load = () => { if (!token) return; setLoading(true); getAdminGeneralCodes(token).then(setCodes).catch(() => {}).finally(() => setLoading(false)); };
  useEffect(() => { load(); }, [token]); // eslint-disable-line

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setSaving(true);
    try {
      await createAdminGeneralCode(token, { points_value: Number(form.points_value), code_string: form.code_string || undefined, title: form.title || undefined, description: form.description || undefined });
      setShowForm(false); setForm({ code_string: '', points_value: 10, title: '', description: '' }); setMessage('Código criado!'); load(); setTimeout(() => setMessage(''), 3000);
    } catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
    finally { setSaving(false); }
  };

  return (
    <div style={{ maxWidth: 800, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800 }}>⭐ Códigos de Pontos</h1>
        <button className="btn btn-primary btn-sm" onClick={() => setShowForm(!showForm)}>{showForm ? 'Cancelar' : '+ Novo Código'}</button>
      </div>
      {message && <div className="alert alert-success" style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      {showForm && (
        <form className="card" style={{ marginBottom: 'var(--space-lg)' }} onSubmit={handleCreate}>
          <div className="form-row">
            <div className="form-group"><label className="label">Código (opcional, auto-gerado)</label><input className="input" value={form.code_string} onChange={(e) => setForm({ ...form, code_string: e.target.value })} placeholder="Ex: BONUS2024" /></div>
            <div className="form-group"><label className="label">Pontos</label><input className="input" type="number" min="1" value={form.points_value} onChange={(e) => setForm({ ...form, points_value: Number(e.target.value) })} required /></div>
          </div>
          <div className="form-row" style={{ marginTop: 'var(--space-md)' }}>
            <div className="form-group"><label className="label">Título (opcional)</label><input className="input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} /></div>
            <div className="form-group"><label className="label">Descrição (opcional)</label><input className="input" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
          </div>
          <div className="form-actions"><button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Criando...' : 'Criar Código'}</button></div>
        </form>
      )}

      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : codes.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">⭐</div><p>Nenhum código criado</p></div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-md)' }}>
          {codes.map((c, i) => (
            <div key={i} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--space-sm)' }}>
              <div>
                <code style={{ color: 'var(--accent)', fontSize: 'var(--font-md)', fontWeight: 700 }}>{c.code_string}</code>
                {c.title && <div style={{ fontWeight: 600, marginTop: 4 }}>{c.title}</div>}
                <div style={{ fontSize: 'var(--font-xs)', color: 'var(--text-muted)' }}>{formatDate(c.created_at)}</div>
              </div>
              <span className="badge badge-gold">{c.points_value} pts</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
