import { Context, Next } from 'hono';
import { createClient } from '@supabase/supabase-js';
import { PrismaClient } from '@prisma/client';
import type { Env } from '../index';

// Initialize Prisma client
const prisma = new PrismaClient();

export async function authMiddleware(c: Context<{ Bindings: Env }>, next: Next) {
  try {
    const authHeader = c.req.header('Authorization');
    const apiKey = c.req.header('X-API-Key');

    if (!authHeader && !apiKey) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'No authentication provided',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

    if (authHeader) {
      // JWT token authentication (Supabase)
      const token = authHeader.replace('Bearer ', '');
      
      const supabase = createClient(
        c.env.SUPABASE_URL,
        c.env.SUPABASE_ANON_KEY
      );

      const { data: { user }, error } = await supabase.auth.getUser(token);

      if (error || !user) {
        return c.json({
          success: false,
          error: {
            code: 'AUTHENTICATION_ERROR',
            message: 'Invalid or expired token',
          },
          timestamp: new Date().toISOString()
        }, 401);
      }

      // Get user profile from our database
      const userProfile = await prisma.user.findUnique({
        where: { id: user.id },
        include: {
          organizationMembers: {
            include: {
              organization: true,
            },
          },
        },
      });

      if (!userProfile) {
        return c.json({
          success: false,
          error: {
            code: 'AUTHENTICATION_ERROR',
            message: 'User profile not found',
          },
          timestamp: new Date().toISOString()
        }, 401);
      }

      // Set user context
      c.set('user', user);
      c.set('userProfile', userProfile);
      c.set('authType', 'jwt');

    } else if (apiKey) {
      // API key authentication
      const keyPrefix = apiKey.split('_')[0] + '_' + apiKey.split('_')[1] + '_';
      
      const apiKeyRecord = await prisma.apiKey.findFirst({
        where: {
          keyPrefix,
          isActive: true,
          OR: [
            { expiresAt: null },
            { expiresAt: { gt: new Date() } }
          ]
        },
        include: {
          organization: true,
        },
      });

      if (!apiKeyRecord) {
        return c.json({
          success: false,
          error: {
            code: 'AUTHENTICATION_ERROR',
            message: 'Invalid API key',
          },
          timestamp: new Date().toISOString()
        }, 401);
      }

      // Update last used timestamp
      await prisma.apiKey.update({
        where: { id: apiKeyRecord.id },
        data: { lastUsedAt: new Date() },
      });

      // Set API key context
      c.set('apiKey', apiKeyRecord);
      c.set('organizationId', apiKeyRecord.organizationId);
      c.set('authType', 'apikey');
    }

    await next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Authentication error',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
}
