'use client';

import React, { createContext, useContext, useState, useEffect, useCallback, type ReactNode } from 'react';
import { signInWithPopup } from 'firebase/auth';
import { auth, googleProvider } from './firebase';
import { getUsersMe, login as apiLogin, loginWithGoogleToken } from './api';
import { jwtDecode } from 'jwt-decode';
import type { UserProfile, UserRole } from './types';

interface AuthContextType {
  token: string | null;
  user: UserProfile | null;
  role: UserRole | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  loginWithGoogle: (inviteCode?: string) => Promise<void>;
  saveSessionWithToken: (token: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function useAuth(): AuthContextType {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

function getStoredToken(): string | null {
  if (typeof window === 'undefined') return null;
  // Also check for cookie as requested
  const match = document.cookie.match(new RegExp('(^| )auth-token=([^;]+)'));
  if (match) return match[2];
  return localStorage.getItem('access_token');
}

function getStoredRole(): UserRole | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('user_role') as UserRole | null;
}

interface JwtPayload {
  sub: string;
  role: string;
  exp: number;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => getStoredToken());
  const [role, setRole] = useState<UserRole | null>(() => getStoredRole());
  const [user, setUser] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState(() => !!getStoredToken());

  const saveSession = useCallback((accessToken: string) => {
    localStorage.setItem('access_token', accessToken);
    // Also set the cookie for SSR and standard Launchpad conventions
    document.cookie = `auth-token=${accessToken}; path=/; max-age=86400; SameSite=Lax`;
    try {
      const decoded = jwtDecode<JwtPayload>(accessToken);
      const userRole = String(decoded.role) as UserRole;
      localStorage.setItem('user_role', userRole);
      setRole(userRole);
    } catch {
      // If we can't decode, try fetching user info
    }
    setToken(accessToken);
  }, []);

  const clearSession = useCallback(() => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('user_role');
    document.cookie = 'auth-token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    setToken(null);
    setUser(null);
    setRole(null);
  }, []);

  const refreshUser = useCallback(async () => {
    const currentToken = token || getStoredToken();
    if (!currentToken) return;
    try {
      const profile = await getUsersMe(currentToken);
      setUser(profile);
      const userRole = String(profile.role) as UserRole;
      setRole(userRole);
      localStorage.setItem('user_role', userRole);
    } catch {
      clearSession();
    }
  }, [token, clearSession]);

  // Check existing session on mount and validate token
  useEffect(() => {
    if (!token) return;

    let isMounted = true;

    // Validate token against server
    getUsersMe(token)
      .then((profile) => {
        if (!isMounted) return;
        setUser(profile);
        const nextRole = String(profile.role) as UserRole;
        setRole(nextRole);
        localStorage.setItem('user_role', nextRole);
      })
      .catch(() => {
        if (!isMounted) return;
        clearSession();
      })
      .finally(() => {
        if (!isMounted) return;
        setIsLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [token, clearSession]);

  const loginFn = useCallback(
    async (email: string, password: string) => {
      const accessToken = await apiLogin(email, password);
      saveSession(accessToken);
      const profile = await getUsersMe(accessToken);
      setUser(profile);
      setRole(String(profile.role) as UserRole);
      localStorage.setItem('user_role', String(profile.role));
    },
    [saveSession]
  );

  const loginWithGoogleFn = useCallback(
    async (inviteCode?: string) => {
      const result = await signInWithPopup(auth, googleProvider);
      const firebaseUser = result.user;
      if (!firebaseUser) throw new Error('Login cancelado.');

      const accessToken = await loginWithGoogleToken(
        firebaseUser.email || '',
        firebaseUser.displayName || 'Usuário Google',
        firebaseUser.uid,
        inviteCode
      );
      saveSession(accessToken);
      const profile = await getUsersMe(accessToken);
      setUser(profile);
      setRole(String(profile.role) as UserRole);
      localStorage.setItem('user_role', String(profile.role));
    },
    [saveSession]
  );

  const saveSessionWithTokenFn = useCallback(
    async (rawToken: string) => {
      saveSession(rawToken);
      const profile = await getUsersMe(rawToken);
      setUser(profile);
      setRole(String(profile.role) as UserRole);
      localStorage.setItem('user_role', String(profile.role));
    },
    [saveSession]
  );

  return (
    <AuthContext.Provider
      value={{
        token,
        user,
        role,
        isLoading,
        login: loginFn,
        loginWithGoogle: loginWithGoogleFn,
        saveSessionWithToken: saveSessionWithTokenFn,
        logout: clearSession,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
