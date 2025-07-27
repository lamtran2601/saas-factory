import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { createClient } from '@supabase/supabase-js';
import type { User } from '@supabase/supabase-js';
import type { AuthSession } from '@saas-factory/types';

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

interface AuthState {
  // State
  user: User | null;
  session: AuthSession | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;

  // Actions
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  signInWithProvider: (provider: 'google' | 'github' | 'microsoft') => Promise<void>;
  initializeAuth: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      // Initial state
      user: null,
      session: null,
      isAuthenticated: false,
      isLoading: true,
      error: null,

      // Actions
      signIn: async (email: string, password: string) => {
        try {
          set({ isLoading: true, error: null });

          const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password,
          });

          if (error) {
            throw error;
          }

          if (data.user && data.session) {
            // Get user session from our API
            const response = await fetch(`${import.meta.env.VITE_API_URL}/api/auth/session`, {
              headers: {
                'Authorization': `Bearer ${data.session.access_token}`,
              },
            });

            if (response.ok) {
              const sessionData = await response.json();
              set({
                user: data.user,
                session: sessionData.data,
                isAuthenticated: true,
                isLoading: false,
              });
            } else {
              throw new Error('Failed to get user session');
            }
          }
        } catch (error: any) {
          set({
            error: error.message || 'Sign in failed',
            isLoading: false,
          });
          throw error;
        }
      },

      signUp: async (email: string, password: string) => {
        try {
          set({ isLoading: true, error: null });

          const { data, error } = await supabase.auth.signUp({
            email,
            password,
          });

          if (error) {
            throw error;
          }

          // For sign up, we don't automatically sign in
          // User needs to verify email first
          set({ isLoading: false });
        } catch (error: any) {
          set({
            error: error.message || 'Sign up failed',
            isLoading: false,
          });
          throw error;
        }
      },

      signOut: async () => {
        try {
          set({ isLoading: true, error: null });

          const { error } = await supabase.auth.signOut();

          if (error) {
            throw error;
          }

          set({
            user: null,
            session: null,
            isAuthenticated: false,
            isLoading: false,
          });
        } catch (error: any) {
          set({
            error: error.message || 'Sign out failed',
            isLoading: false,
          });
          throw error;
        }
      },

      signInWithProvider: async (provider: 'google' | 'github' | 'microsoft') => {
        try {
          set({ isLoading: true, error: null });

          const { error } = await supabase.auth.signInWithOAuth({
            provider,
            options: {
              redirectTo: `${window.location.origin}/auth/callback`,
            },
          });

          if (error) {
            throw error;
          }

          // OAuth will redirect, so we don't need to update state here
        } catch (error: any) {
          set({
            error: error.message || 'OAuth sign in failed',
            isLoading: false,
          });
          throw error;
        }
      },

      initializeAuth: async () => {
        try {
          set({ isLoading: true, error: null });

          // Get current session from Supabase
          const { data: { session }, error } = await supabase.auth.getSession();

          if (error) {
            throw error;
          }

          if (session?.user) {
            // Get user session from our API
            const response = await fetch(`${import.meta.env.VITE_API_URL}/api/auth/session`, {
              headers: {
                'Authorization': `Bearer ${session.access_token}`,
              },
            });

            if (response.ok) {
              const sessionData = await response.json();
              set({
                user: session.user,
                session: sessionData.data,
                isAuthenticated: true,
                isLoading: false,
              });
            } else {
              // If API call fails, clear the session
              await supabase.auth.signOut();
              set({
                user: null,
                session: null,
                isAuthenticated: false,
                isLoading: false,
              });
            }
          } else {
            set({
              user: null,
              session: null,
              isAuthenticated: false,
              isLoading: false,
            });
          }

          // Listen for auth changes
          supabase.auth.onAuthStateChange(async (event, session) => {
            if (event === 'SIGNED_IN' && session?.user) {
              // Get user session from our API
              const response = await fetch(`${import.meta.env.VITE_API_URL}/api/auth/session`, {
                headers: {
                  'Authorization': `Bearer ${session.access_token}`,
                },
              });

              if (response.ok) {
                const sessionData = await response.json();
                set({
                  user: session.user,
                  session: sessionData.data,
                  isAuthenticated: true,
                  isLoading: false,
                });
              }
            } else if (event === 'SIGNED_OUT') {
              set({
                user: null,
                session: null,
                isAuthenticated: false,
                isLoading: false,
              });
            }
          });

        } catch (error: any) {
          set({
            error: error.message || 'Auth initialization failed',
            user: null,
            session: null,
            isAuthenticated: false,
            isLoading: false,
          });
        }
      },

      clearError: () => {
        set({ error: null });
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        // Only persist user and session, not loading states
        user: state.user,
        session: state.session,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
