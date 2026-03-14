'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getAuditLogs } from '@/lib/api';
import { formatDateTime } from '@/lib/utils';
import type { AuditLogItem } from '@/lib/types';

export default function AdminReportsPage() {
  const { token } = useAuth();
  const [logs, setLogs] = useState<AuditLogItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

  useEffect(() => { if (!token) return; getAuditLogs(token).then(setLogs).catch(() => {}).finally(() => setLoading(false)); }, [token]);

  const filtered = filter ? logs.filter((l) => l.type.toLowerCase().includes(filter.toLowerCase()) || l.user_name.toLowerCase().includes(filter.toLowerCase()) || l.description.toLowerCase().includes(filter.toLowerCase())) : logs;

  return (
    <div style={{ maxWidth: 1000, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>📈 Relatórios / Auditoria</h1>

      <div style={{ display: 'flex', gap: 'var(--space-sm)', marginBottom: 'var(--space-lg)', alignItems: 'center' }}>
        <input className="input" placeholder="Filtrar por tipo, usuário ou descrição..." value={filter} onChange={(e) => setFilter(e.target.value)} style={{ maxWidth: 400 }} />
        <span style={{ color: 'var(--text-muted)', fontSize: 'var(--font-sm)' }}>{filtered.length} registros</span>
      </div>

      {loading ? <div style={{ textAlign: 'center', padding: 'var(--space-3xl)' }}><div className="spinner spinner-lg" style={{ margin: '0 auto' }} /></div> : filtered.length === 0 ? (
        <div className="empty-state"><div className="empty-state-icon">📈</div><p>Nenhum registro encontrado</p></div>
      ) : (
        <div className="table-container">
          <table className="table"><thead><tr><th>Data</th><th>Tipo</th><th>Usuário</th><th>Líder</th><th>Setor</th><th>Descrição</th><th>Pts</th></tr></thead><tbody>
            {filtered.slice(0, 100).map((log, i) => (
              <tr key={i}>
                <td style={{ whiteSpace: 'nowrap', fontSize: 'var(--font-xs)' }}>{formatDateTime(log.timestamp)}</td>
                <td><span className="badge badge-info">{log.type}</span></td>
                <td>{log.user_name}</td>
                <td style={{ color: 'var(--text-secondary)' }}>{log.lider_name}</td>
                <td style={{ color: 'var(--text-secondary)' }}>{log.sector_name}</td>
                <td style={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={log.description}>{log.description}</td>
                <td style={{ color: 'var(--accent)', fontWeight: 600 }}>{log.points}</td>
              </tr>
            ))}
          </tbody></table>
        </div>
      )}
    </div>
  );
}
