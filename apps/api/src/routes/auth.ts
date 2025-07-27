import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { createClient } from '@supabase/supabase-js';
import { PrismaClient } from '@prisma/client';
import type { Env } from '../index';

const auth = new Hono<{ Bindings: Env }>();
const prisma = new PrismaClient();

// Validation schemas
const sessionSchema = z.object({
  supabaseSession: z.object({
    access_token: z.string(),
    user: z.object({
      id: z.string(),
      email: z.string(),
      email_confirmed_at: z.string().nullable(),
      user_metadata: z.record(z.any()).optional(),
    }),
  }),
});

const profileSchema = z.object({
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  avatarUrl: z.string().url().optional(),
});

// GET /auth/session - Validate current session and return user context
auth.get('/session', async (c) => {
  try {
    const authHeader = c.req.header('Authorization');
    
    if (!authHeader) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'No authorization header provided',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

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
            organization: {
              select: {
                id: true,
                name: true,
                slug: true,
                logoUrl: true,
              },
            },
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

    // Format organizations for response
    const organizations = userProfile.organizationMembers.map(member => ({
      id: member.organization.id,
      name: member.organization.name,
      slug: member.organization.slug,
      logoUrl: member.organization.logoUrl,
      role: member.role,
      permissions: member.permissions,
    }));

    return c.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          emailVerified: user.email_confirmed_at != null,
        },
        profile: {
          firstName: userProfile.firstName,
          lastName: userProfile.lastName,
          avatarUrl: userProfile.avatarUrl,
        },
        organizations,
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Session validation error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Session validation failed',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /auth/callback - Handle OAuth callbacks and create user profiles
auth.post('/callback', zValidator('json', sessionSchema), async (c) => {
  try {
    const { supabaseSession } = c.req.valid('json');
    const { user } = supabaseSession;

    // Create or update user profile in our database
    const userProfile = await prisma.user.upsert({
      where: { id: user.id },
      update: {
        email: user.email,
        emailVerified: user.email_confirmed_at != null,
        lastLoginAt: new Date(),
      },
      create: {
        id: user.id,
        email: user.email,
        emailVerified: user.email_confirmed_at != null,
        firstName: user.user_metadata?.first_name,
        lastName: user.user_metadata?.last_name,
        avatarUrl: user.user_metadata?.avatar_url,
        lastLoginAt: new Date(),
      },
    });

    return c.json({
      success: true,
      data: {
        user: userProfile,
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Auth callback error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Authentication callback failed',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /auth/profile - Create or update user profile
auth.post('/profile', zValidator('json', profileSchema), async (c) => {
  try {
    const authHeader = c.req.header('Authorization');
    
    if (!authHeader) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'No authorization header provided',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

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

    const profileData = c.req.valid('json');

    // Update user profile
    const updatedProfile = await prisma.user.update({
      where: { id: user.id },
      data: profileData,
    });

    return c.json({
      success: true,
      data: {
        profile: updatedProfile,
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Profile update error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Profile update failed',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default auth;
