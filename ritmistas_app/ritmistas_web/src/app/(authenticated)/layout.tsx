'use client';

import { useAuth } from '@/lib/auth';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import type { UserRole } from '@/lib/types';
import styles from './layout.module.css';

interface NavItem {
  label: string;
  href: string;
  icon: string;
  roles: UserRole[];
}

const navItems: NavItem[] = [
  // User (role 2) items
  { label: 'Perfil', href: '/profile', icon: '👤', roles: ['0', '1', '2'] },
  { label: 'Resgatar', href: '/redeem', icon: '🎁', roles: ['2'] },
  { label: 'Ranking', href: '/ranking', icon: '🏆', roles: ['0', '1', '2'] },

  // Leader (role 1) items
  { label: 'Atividades', href: '/leader/activities', icon: '📋', roles: ['1'] },
  { label: 'Aprovações', href: '/leader/approvals', icon: '🔔', roles: ['1'] },
  { label: 'Usuários', href: '/leader/users', icon: '👥', roles: ['1'] },
  { label: 'Ranking Setor', href: '/leader/ranking', icon: '📊', roles: ['1'] },

  // Admin Master (role 0) items
  { label: 'Setores', href: '/admin/sectors', icon: '🏢', roles: ['0'] },
  { label: 'Líderes', href: '/admin/leaders', icon: '⚙️', roles: ['0'] },
  { label: 'Pontos', href: '/admin/points', icon: '⭐', roles: ['0'] },
  { label: 'Insígnias', href: '/admin/badges', icon: '🎖️', roles: ['0'] },
  { label: 'Convites', href: '/admin/invites', icon: '🔑', roles: ['0'] },
  { label: 'Relatórios', href: '/admin/reports', icon: '📈', roles: ['0'] },
];

export default function AuthenticatedLayout({ children }: { children: React.ReactNode }) {
  const { token, role, user, isLoading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [prevPathname, setPrevPathname] = useState(pathname);

  useEffect(() => {
    if (!isLoading && !token) {
      window.location.href = 'http://localhost.com/api/redirect-to-service?service=points';
    }
  }, [isLoading, token]);

  // Close sidebar on route change (mobile)
  if (pathname !== prevPathname) {
    setPrevPathname(pathname);
    setSidebarOpen(false);
  }

  if (isLoading) {
    return (
      <div className={styles.loadingPage}>
        <div className="spinner spinner-lg" />
      </div>
    );
  }

  if (!token || !role) return null;

  const filteredItems = navItems.filter((item) => item.roles.includes(role));

  const roleName =
    role === '0' ? 'MASTER' : role === '1' ? 'LÍDER' : 'USUÁRIO';

  const handleLogout = () => {
    logout();
    window.location.href = 'http://localhost.com/api/redirect-to-service?service=points';
  };

  return (
    <div className={styles.shell}>
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div className={styles.overlay} onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`${styles.sidebar} ${sidebarOpen ? styles.sidebarOpen : ''}`}>
        <div className={styles.sidebarHeader}>
          <img
            src="https://raw.githubusercontent.com/lovinsuarez/ritmistas_b10/main/ritmistas_app/assets/images/logoB10.png"
            alt="B10"
            className={styles.sidebarLogo}
            onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
          />
          <div>
            <div className={styles.sidebarTitle}>Ritmistas</div>
            <div className={styles.sidebarRole}>{roleName}</div>
          </div>
        </div>

        <nav className={styles.nav}>
          {filteredItems.map((item) => (
            <button
              key={item.href}
              className={`${styles.navItem} ${pathname === item.href ? styles.navItemActive : ''}`}
              onClick={() => router.push(item.href)}
            >
              <span className={styles.navIcon}>{item.icon}</span>
              <span className={styles.navLabel}>{item.label}</span>
            </button>
          ))}
        </nav>

        <div className={styles.sidebarFooter}>
          <div className={styles.userInfo}>
            <span className={styles.userName}>{user?.nickname || user?.username || 'Usuário'}</span>
            <span className={styles.userEmail}>{user?.email || ''}</span>
          </div>
          <button className={`btn btn-ghost btn-sm ${styles.logoutBtn}`} onClick={handleLogout}>
            Sair
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className={styles.main}>
        {/* Topbar (mobile) */}
        <header className={styles.topbar}>
          <button className={styles.menuBtn} onClick={() => setSidebarOpen(true)}>
            ☰
          </button>
          <span className={styles.topbarTitle}>Ritmistas B10</span>
          <div style={{ width: 40 }} />
        </header>

        <main className={styles.content}>
          <div className="page-enter">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
