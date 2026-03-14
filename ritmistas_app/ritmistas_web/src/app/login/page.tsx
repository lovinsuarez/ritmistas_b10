'use client';

import styles from './login.module.css';

export default function LoginPage() {
  return (
    <div className={styles.container}>
      <div className={styles.loginCard}>
        {/* Logo */}
        <div className={styles.logoSection}>
          <img
            src="https://raw.githubusercontent.com/lovinsuarez/ritmistas_b10/main/ritmistas_app/assets/images/logoB10.png"
            alt="B10 Logo"
            className={styles.logo}
            onError={(e) => {
              (e.target as HTMLImageElement).style.display = 'none';
            }}
          />
          <h1 className={styles.title}>Ritmistas B10</h1>
          <p className={styles.subtitle}>Plataforma de Engajamento</p>
        </div>

        <div style={{ textAlign: 'center', marginTop: '2rem' }}>
          <p style={{ color: 'var(--text-secondary)' }}>
            O acesso local foi desativado. 
            Todas as operações de autenticação agora são realizadas através do Launchpad.
          </p>
          <button 
            className="btn btn-primary" 
            style={{ marginTop: '1.5rem', width: '100%' }}
            onClick={() => window.location.href = 'http://localhost.com/api/redirect-to-service?service=points'}
          >
            Acessar via Launchpad
          </button>
        </div>
      </div>
    </div>
  );
}
