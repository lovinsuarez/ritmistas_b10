'use client';

import { useAuth } from '@/lib/auth';
import { useState } from 'react';
import { redeemCode, checkIn } from '@/lib/api';

export default function RedeemPage() {
  const { token } = useAuth();
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [isError, setIsError] = useState(false);
  const [mode, setMode] = useState<'redeem' | 'checkin'>('redeem');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!token || !code.trim()) return;
    setLoading(true);
    setMessage('');
    try {
      let result: string;
      if (mode === 'redeem') {
        result = await redeemCode(token, code.trim());
      } else {
        result = await checkIn(token, code.trim());
      }
      setMessage(result || 'Código resgatado com sucesso!');
      setIsError(false);
      setCode('');
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Erro ao resgatar código');
      setIsError(true);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 500, margin: '0 auto' }}>
      <h1 style={{ fontSize: 'var(--font-xl)', fontWeight: 800, marginBottom: 'var(--space-lg)' }}>
        🎁 Resgatar Código
      </h1>

      {/* Mode toggle */}
      <div style={{ display: 'flex', gap: 'var(--space-sm)', marginBottom: 'var(--space-lg)' }}>
        <button
          className={`btn btn-sm ${mode === 'redeem' ? 'btn-primary' : 'btn-ghost'}`}
          onClick={() => setMode('redeem')}
        >
          Código de Pontos
        </button>
        <button
          className={`btn btn-sm ${mode === 'checkin' ? 'btn-primary' : 'btn-ghost'}`}
          onClick={() => setMode('checkin')}
        >
          Check-in Atividade
        </button>
      </div>

      <div className="card">
        <p style={{ color: 'var(--text-secondary)', fontSize: 'var(--font-sm)', marginBottom: 'var(--space-lg)' }}>
          {mode === 'redeem'
            ? 'Digite o código recebido para resgatar seus pontos.'
            : 'Digite o código da atividade para fazer check-in.'}
        </p>

        {message && (
          <div className={`alert ${isError ? 'alert-error' : 'alert-success'}`} style={{ marginBottom: 'var(--space-md)' }}>
            {message}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group" style={{ marginBottom: 'var(--space-md)' }}>
            <label className="label">{mode === 'redeem' ? 'Código de pontos' : 'Código da atividade'}</label>
            <input
              className="input"
              placeholder="Digite o código aqui"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              required
              style={{ fontSize: 'var(--font-lg)', textAlign: 'center', letterSpacing: '0.1em', textTransform: 'uppercase' }}
            />
          </div>
          <button className="btn btn-primary" type="submit" disabled={loading || !code.trim()} style={{ width: '100%' }}>
            {loading ? 'Processando...' : mode === 'redeem' ? '🎁 Resgatar' : '✅ Check-in'}
          </button>
        </form>
      </div>
    </div>
  );
}
