import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import type { Env } from '../index';

const admin = new Hono<{ Bindings: Env }>();
const prisma = new PrismaClient();

// Admin middleware to check if user has admin role in any organization
async function adminMiddleware(c: any, next: any) {
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

  const hasAdminRole = userProfile.organizationMembers.some(
    (member: any) => member.role === 'admin'
  );

  if (!hasAdminRole) {
    return c.json({
      success: false,
      error: {
        code: 'AUTHORIZATION_ERROR',
        message: 'Admin role required',
      },
      timestamp: new Date().toISOString()
    }, 403);
  }

  await next();
}

// Apply admin middleware to all routes
admin.use('*', adminMiddleware);

// GET /admin/stats - Get platform statistics
admin.get('/stats', async (c) => {
  try {
    const [
      totalUsers,
      totalOrganizations,
      totalProjects,
      totalTasks,
      activeSubscriptions,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.organization.count(),
      prisma.project.count(),
      prisma.task.count(),
      prisma.subscription.count({ where: { status: 'active' } }),
    ]);

    // Get recent activity
    const recentUsers = await prisma.user.findMany({
      take: 5,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        createdAt: true,
      },
    });

    const recentOrganizations = await prisma.organization.findMany({
      take: 5,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        name: true,
        slug: true,
        createdAt: true,
      },
    });

    return c.json({
      success: true,
      data: {
        stats: {
          totalUsers,
          totalOrganizations,
          totalProjects,
          totalTasks,
          activeSubscriptions,
        },
        recent: {
          users: recentUsers,
          organizations: recentOrganizations,
        },
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get admin stats error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get admin statistics',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /admin/users - List all users
admin.get('/users', async (c) => {
  try {
    const page = parseInt(c.req.query('page') || '1');
    const limit = parseInt(c.req.query('limit') || '20');
    const search = c.req.query('search');

    const skip = (page - 1) * limit;
    const where: any = {};

    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          organizationMembers: {
            include: {
              organization: {
                select: {
                  id: true,
                  name: true,
                  slug: true,
                },
              },
            },
          },
        },
      }),
      prisma.user.count({ where }),
    ]);

    return c.json({
      success: true,
      data: users,
      meta: {
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('List users error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to list users',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /admin/organizations - List all organizations
admin.get('/organizations', async (c) => {
  try {
    const page = parseInt(c.req.query('page') || '1');
    const limit = parseInt(c.req.query('limit') || '20');
    const search = c.req.query('search');

    const skip = (page - 1) * limit;
    const where: any = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { slug: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [organizations, total] = await Promise.all([
      prisma.organization.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          creator: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
            },
          },
          _count: {
            select: {
              members: true,
              projects: true,
              tasks: true,
            },
          },
        },
      }),
      prisma.organization.count({ where }),
    ]);

    return c.json({
      success: true,
      data: organizations,
      meta: {
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('List organizations error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to list organizations',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /admin/audit-logs - Get audit logs
admin.get('/audit-logs', async (c) => {
  try {
    const page = parseInt(c.req.query('page') || '1');
    const limit = parseInt(c.req.query('limit') || '50');
    const action = c.req.query('action');
    const userId = c.req.query('userId');
    const organizationId = c.req.query('organizationId');

    const skip = (page - 1) * limit;
    const where: any = {};

    if (action) {
      where.action = action;
    }

    if (userId) {
      where.userId = userId;
    }

    if (organizationId) {
      where.organizationId = organizationId;
    }

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
            },
          },
          organization: {
            select: {
              id: true,
              name: true,
              slug: true,
            },
          },
        },
      }),
      prisma.auditLog.count({ where }),
    ]);

    return c.json({
      success: true,
      data: logs,
      meta: {
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get audit logs error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get audit logs',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default admin;
