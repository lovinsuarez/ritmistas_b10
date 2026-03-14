'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/lib/auth';

export default function AuthCallbackClient() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const code = searchParams.get('code');
  const [error, setError] = useState<string | null>(null);
  const exchanged = useRef(false);
  
  const { saveSessionWithToken } = useAuth();

  useEffect(() => {
    if (!code) {
      setError('Código de autenticação não encontrado na URL.');
      return;
    }

    if (exchanged.current) return;
    exchanged.current = true;

    async function exchangeToken(code: string) {
      try {
        const launchpadUrl = (process.env.NEXT_PUBLIC_LAUNCHPAD_URL || 'http://localhost').replace(/\/$/, '');
        const res = await fetch(`${launchpadUrl}/api/exchange-code?code=${code}`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (!res.ok) {
          throw new Error('Falha ao trocar o código por token no Launchpad.');
        }

        const data = await res.json();
        const token = data.token;
        
        if (!token) {
          throw new Error('Token não recebido do Launchpad.');
        }

        await saveSessionWithToken(token);
        
        router.replace('/profile');
      } catch (err: unknown) {
        console.error('Launchpad exchance error:', err);
        const message = err instanceof Error ? err.message : 'Ocorreu um erro na autenticação.';
        setError(message);
      }
    }

    exchangeToken(code);
  }, [code, router, saveSessionWithToken]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
      {error ? (
        <div style={{ textAlign: 'center' }}>
          <h2 style={{ color: 'var(--error-500, #EF4444)' }}>Erro de Autenticação</h2>
          <p>{error}</p>
          <button 
            className="btn btn-primary" 
            onClick={() => {
              const launchpadUrl = (process.env.NEXT_PUBLIC_LAUNCHPAD_URL || 'http://localhost').replace(/\/$/, '');
              window.location.href = `${launchpadUrl}/api/redirect-to-service?service=points`;
            }}
            style={{ marginTop: '1rem' }}
          >
            Tentar Novamente no Launchpad
          </button>
        </div>
      ) : (
        <>
          <div className="spinner spinner-lg" />
          <p style={{ marginTop: '1rem', color: 'var(--text-secondary)' }}>
            Autenticando via Launchpad...
          </p>
        </>
      )}
    </div>
  );
}
