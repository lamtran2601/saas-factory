import { describe, it, expect, beforeEach } from 'vitest';
import { app } from '../index';

describe('Auth Routes', () => {
  beforeEach(() => {
    // Reset any mocks or state before each test
  });

  describe('GET /api/auth/session', () => {
    it('returns 401 without authorization header', async () => {
      const res = await app.request('/api/auth/session');
      expect(res.status).toBe(401);
      
      const body = await res.json();
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('AUTHENTICATION_ERROR');
    });

    it('returns 401 with invalid token', async () => {
      const res = await app.request('/api/auth/session', {
        headers: {
          'Authorization': 'Bearer invalid-token',
        },
      });
      expect(res.status).toBe(401);
    });
  });

  describe('POST /api/auth/callback', () => {
    it('returns 400 with invalid request body', async () => {
      const res = await app.request('/api/auth/callback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      });
      expect(res.status).toBe(400);
    });
  });
});
