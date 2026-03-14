import { Suspense } from 'react';
import AuthCallbackClient from './AuthCallbackClient';

export default function AuthCallbackPage() {
  return (
    <Suspense
      fallback={
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100vh' }}>
          <div className="spinner spinner-lg" />
          <p style={{ marginTop: '1rem', color: 'var(--text-secondary)' }}>
            Carregando autenticação...
          </p>
        </div>
      }
    >
      <AuthCallbackClient />
    </Suspense>
  );
}
