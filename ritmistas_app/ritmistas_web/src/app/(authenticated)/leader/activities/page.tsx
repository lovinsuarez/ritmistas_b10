'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getActivities, createActivity } from '@/lib/api';
import { formatDate } from '@/lib/utils';
import type { Activity } from '@/lib/types';

export default function LeaderActivitiesPage() {
  const { token } = useAuth();
  const [activities, setActivities] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [form, setForm] = useState({ title: '', type: 'presencial', address: '', activity_date: '', points_value: 10 });

  const loadActivities = () => {
    if (!token) return;
    setLoading(true);
    getActivities(token).then(setActivities).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { loadActivities(); }, [token]); // eslint-disable-line

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token) return;
    setSaving(true);
    try {
      await createActivity(token, { ...form, activity_date: new Date(form.activity_date).toISOString(), points_value: Number(form.points_value) });
      setShowForm(false);
      setMessage('Atividade criada!');
      loadActivities();
      setTimeout(() => setMessage(''), 3000);
    } catch (err) { setMessage(err instanceof Error ? err.message : 'Erro'); }
    finally { setSaving(false); }
  };

  return (
    <div style={{ maxWidth: 900, margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-lg)' }}>
        <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800 }}>📋 Atividades</h1>
        <button className="btn btn-primary btn-sm" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancelar' : '+ Nova Atividade'}
        </button>
      </div>

      {message && <div className="alert alert-success" style={{ marginBottom: 'var(--space-md)' }}>{message}</div>}

      {showForm && (
        <form className="card" style={{ marginBottom: 'var(--space-lg)' }} onSubmit={handleCreate}>
          <h3 style={{ marginBottom: 'var(--space-md)', fontWeight: 700 }}>Nova Atividade</h3>
          <div className="form-row">
            <div className="form-group"><label className="label">Título</label><input className="input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} required /></div>
            <div className="form-group"><label className="label">Tipo</label><select className="input" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}><option value="presencial">Presencial</option><option value="online">Online</option></select></div>
          </div>
          <div className="form-row" style={{ marginTop: 'var(--space-md)' }}>
            <div className="form-group"><label className="label">Data</label><input className="input" type="datetime-local" value={form.activity_date} onChange={(e) => setForm({ ...form, activity_date: e.target.value })} required /></div>
            <div className="form-group"><label className="label">Pontos</label><input className="input" type="number" min="1" value={form.points_value} onChange={(e) => setForm({ ...form, points_value: Number(e.target.value) })} required /></div>
          </div>
          <div className="form-group" style={{ marginTop: 'var(--space-md)' }}><label className="label">Endereço (opcional)</label><input className="input" value={form.address} onChange={(e) => setForm({ ...form, address: e.target.value })} /></div>
          <div className="form-actions"><button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Criando...' : 'Criar Atividade'}</button></div>
        </form>
      )}

      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : activities.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">📋</div><p>Nenhuma atividade criada</p></div>
      ) : (
        <div style={{ display: 'grid', gap: 'var(--space-md)' }}>
          {activities.map((a) => (
            <div key={a.activity_id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 'var(--space-sm)' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: 'var(--font-md)' }}>{a.title}</div>
                <div style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)' }}>{formatDate(a.activity_date)} · {a.type} {a.address ? `· ${a.address}` : ''}</div>
                {a.checkin_code && <div style={{ fontSize: 'var(--font-xs)', color: 'var(--text-muted)', marginTop: 4 }}>Código: <code style={{ color: 'var(--accent)' }}>{a.checkin_code}</code></div>}
              </div>
              <span className="badge badge-gold">{a.points_value} pts</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
