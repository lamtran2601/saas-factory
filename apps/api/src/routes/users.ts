import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import type { Env } from '../index';

const users = new Hono<{ Bindings: Env }>();
const prisma = new PrismaClient();

// Validation schemas
const updateProfileSchema = z.object({
  firstName: z.string().min(1).max(100).optional(),
  lastName: z.string().min(1).max(100).optional(),
  avatarUrl: z.string().url().optional(),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(8),
  newPassword: z.string().min(8),
});

// GET /users/me - Get current user profile
users.get('/me', async (c) => {
  try {
    const userProfile = c.get('userProfile');

    if (!userProfile) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'User not authenticated',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

    // Format organizations for response
    const organizations = userProfile.organizationMembers.map((member: any) => ({
      id: member.organization.id,
      name: member.organization.name,
      slug: member.organization.slug,
      logoUrl: member.organization.logoUrl,
      role: member.role,
      permissions: member.permissions,
      joinedAt: member.joinedAt,
    }));

    return c.json({
      success: true,
      data: {
        id: userProfile.id,
        email: userProfile.email,
        firstName: userProfile.firstName,
        lastName: userProfile.lastName,
        avatarUrl: userProfile.avatarUrl,
        emailVerified: userProfile.emailVerified,
        lastLoginAt: userProfile.lastLoginAt,
        createdAt: userProfile.createdAt,
        updatedAt: userProfile.updatedAt,
        organizations,
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get user profile error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get user profile',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// PUT /users/me - Update current user profile
users.put('/me', zValidator('json', updateProfileSchema), async (c) => {
  try {
    const userProfile = c.get('userProfile');
    const updateData = c.req.valid('json');

    if (!userProfile) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'User not authenticated',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

    // Update user profile
    const updatedProfile = await prisma.user.update({
      where: { id: userProfile.id },
      data: updateData,
    });

    return c.json({
      success: true,
      data: updatedProfile,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update user profile error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to update user profile',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /users/me/avatar - Upload user avatar
users.post('/me/avatar', async (c) => {
  try {
    const userProfile = c.get('userProfile');

    if (!userProfile) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'User not authenticated',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

    // TODO: Implement file upload to storage provider
    // For now, return a placeholder response
    return c.json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: 'Avatar upload not yet implemented',
      },
      timestamp: new Date().toISOString()
    }, 501);

  } catch (error) {
    console.error('Avatar upload error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to upload avatar',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /users/me/change-password - Change user password
users.post('/me/change-password', zValidator('json', changePasswordSchema), async (c) => {
  try {
    const userProfile = c.get('userProfile');
    const { currentPassword, newPassword } = c.req.valid('json');

    if (!userProfile) {
      return c.json({
        success: false,
        error: {
          code: 'AUTHENTICATION_ERROR',
          message: 'User not authenticated',
        },
        timestamp: new Date().toISOString()
      }, 401);
    }

    // TODO: Implement password change via Supabase Auth
    // For now, return a placeholder response
    return c.json({
      success: false,
      error: {
        code: 'NOT_IMPLEMENTED',
        message: 'Password change not yet implemented',
      },
      timestamp: new Date().toISOString()
    }, 501);

  } catch (error) {
    console.error('Change password error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to change password',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default users;
