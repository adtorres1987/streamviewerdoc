'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User } from '@/types';

interface AuthState {
  user: User | null;
  token: string | null;
  setAuth: (user: User, token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      setAuth: (user, token) => {
        // Also set cookies for middleware to read
        document.cookie = `token=${token}; path=/; max-age=${7 * 24 * 60 * 60}`;
        document.cookie = `role=${user.role}; path=/; max-age=${7 * 24 * 60 * 60}`;
        set({ user, token });
      },
      logout: () => {
        document.cookie = 'token=; path=/; max-age=0';
        document.cookie = 'role=; path=/; max-age=0';
        set({ user: null, token: null });
      },
    }),
    {
      name: 'syncpdf-auth',
    }
  )
);
