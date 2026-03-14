'use client';

import { useAuth } from '@/lib/auth';
import { useEffect, useState } from 'react';
import { getGeralRanking, getSpecificSectorRanking } from '@/lib/api';
import { getInitials } from '@/lib/utils';
import type { RankingEntry, Sector } from '@/lib/types';

export default function RankingPage() {
  const { token } = useAuth();
  const [ranking, setRanking] = useState<RankingEntry[]>([]);
  const [sectors, setSectors] = useState<Sector[]>([]);
  const [selectedSector, setSelectedSector] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!token) return;
    if (selectedSector === null) {
      getGeralRanking(token)
        .then((data) => {
          setRanking(data.ranking || []);
          setSectors(data.sectors || []);
        })
        .catch(() => {})
        .finally(() => setLoading(false));
    } else {
      getSpecificSectorRanking(token, selectedSector)
        .then((data) => setRanking(data.ranking || []))
        .catch(() => {})
        .finally(() => setLoading(false));
    }
  }, [token, selectedSector]);

  const getRankClass = (i: number) => {
    if (i === 0) return 'rank-1';
    if (i === 1) return 'rank-2';
    if (i === 2) return 'rank-3';
    return '';
  };

  const getRankEmoji = (i: number) => {
    if (i === 0) return '🥇';
    if (i === 1) return '🥈';
    if (i === 2) return '🥉';
    return `${i + 1}`;
  };

  return (
    <div style={{ maxWidth: 800, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>
        🏆 Ranking
      </h1>

      {/* Sector tabs */}
      <div style={{ display: 'flex', gap: 'var(--space-sm)', marginBottom: 'var(--space-lg)', flexWrap: 'wrap' }}>
        <button
          className={`btn btn-sm ${selectedSector === null ? 'btn-primary' : 'btn-ghost'}`}
          onClick={() => { setLoading(true); setSelectedSector(null); }}
        >
          Geral
        </button>
        {sectors.map((s) => (
          <button
            key={s.sector_id}
            className={`btn btn-sm ${selectedSector === s.sector_id ? 'btn-primary' : 'btn-ghost'}`}
            onClick={() => { setLoading(true); setSelectedSector(s.sector_id); }}
          >
            {s.name}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: 'var(--space-3xl)' }}>
          <div className="spinner spinner-lg" />
        </div>
      ) : ranking.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">🏆</div>
          <p>Nenhum resultado encontrado</p>
        </div>
      ) : (
        <>
          {/* Top 3 podium */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 'var(--space-md)', marginBottom: 'var(--space-lg)' }}>
            {ranking.slice(0, 3).map((entry, i) => (
              <div key={entry.user_id} className="card" style={{ textAlign: 'center', borderColor: i === 0 ? 'var(--accent)' : 'var(--border-subtle)' }}>
                <div style={{ fontSize: '2rem', marginBottom: 'var(--space-sm)' }}>{getRankEmoji(i)}</div>
                {entry.profile_pic ? (
                  <img src={entry.profile_pic} alt="" className="avatar avatar-lg" style={{ margin: '0 auto var(--space-sm)' }} />
                ) : (
                  <div className="avatar avatar-lg" style={{ margin: '0 auto var(--space-sm)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 'var(--font-lg)', fontWeight: 700, color: 'var(--accent)' }}>
                    {getInitials(entry.nickname || entry.username)}
                  </div>
                )}
                <div style={{ fontWeight: 700, fontSize: 'var(--font-md)' }}>{entry.nickname || entry.username}</div>
                <div className={getRankClass(i)} style={{ fontSize: 'var(--font-xl)', fontWeight: 800 }}>
                  {entry.total_points} pts
                </div>
              </div>
            ))}
          </div>

          {/* Full table */}
          {ranking.length > 3 && (
            <div className="table-container">
              <table className="table">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Usuário</th>
                    <th style={{ textAlign: 'right' }}>Pontos</th>
                  </tr>
                </thead>
                <tbody>
                  {ranking.slice(3).map((entry, i) => (
                    <tr key={entry.user_id}>
                      <td style={{ fontWeight: 600, color: 'var(--text-secondary)' }}>{i + 4}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-sm)' }}>
                          {entry.profile_pic ? (
                            <img src={entry.profile_pic} alt="" className="avatar" style={{ width: 32, height: 32 }} />
                          ) : (
                            <div className="avatar" style={{ width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 'var(--font-xs)', fontWeight: 700, color: 'var(--accent)' }}>
                              {getInitials(entry.nickname || entry.username)}
                            </div>
                          )}
                          {entry.nickname || entry.username}
                        </div>
                      </td>
                      <td style={{ textAlign: 'right', fontWeight: 600, color: 'var(--accent)' }}>{entry.total_points}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}
