import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { slugify } from '@saas-factory/utils';
import type { Env } from '../index';

const organizations = new Hono<{ Bindings: Env }>();
const prisma = new PrismaClient();

// Validation schemas
const createOrganizationSchema = z.object({
  name: z.string().min(1).max(100),
  slug: z.string().min(1).max(50).optional(),
  domain: z.string().optional(),
});

const updateOrganizationSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  domain: z.string().optional(),
  logoUrl: z.string().url().optional(),
  settings: z.record(z.any()).optional(),
});

const inviteMemberSchema = z.object({
  email: z.string().email(),
  role: z.enum(['admin', 'member', 'viewer']).default('member'),
  permissions: z.array(z.string()).default([]),
});

// GET /organizations - List user's organizations
organizations.get('/', async (c) => {
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

    const userOrganizations = userProfile.organizationMembers.map((member: any) => ({
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
      data: userOrganizations,
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

// POST /organizations - Create new organization
organizations.post('/', zValidator('json', createOrganizationSchema), async (c) => {
  try {
    const userProfile = c.get('userProfile');
    const { name, slug, domain } = c.req.valid('json');

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

    // Generate slug if not provided
    const organizationSlug = slug || slugify(name);

    // Check if slug is already taken
    const existingOrg = await prisma.organization.findUnique({
      where: { slug: organizationSlug },
    });

    if (existingOrg) {
      return c.json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Organization slug already exists',
        },
        timestamp: new Date().toISOString()
      }, 400);
    }

    // Create organization
    const organization = await prisma.organization.create({
      data: {
        name,
        slug: organizationSlug,
        domain,
        createdBy: userProfile.id,
        settings: {},
      },
    });

    // Add creator as admin member
    await prisma.organizationMember.create({
      data: {
        organizationId: organization.id,
        userId: userProfile.id,
        role: 'admin',
        permissions: ['read', 'write', 'admin'],
        joinedAt: new Date(),
        status: 'active',
      },
    });

    return c.json({
      success: true,
      data: organization,
      timestamp: new Date().toISOString()
    }, 201);

  } catch (error) {
    console.error('Create organization error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to create organization',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /organizations/:id - Get organization details
organizations.get('/:id', async (c) => {
  try {
    const organizationId = c.req.param('id');
    const userRole = c.get('userRole');

    const organization = await prisma.organization.findUnique({
      where: { id: organizationId },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
              },
            },
          },
        },
        _count: {
          select: {
            projects: true,
            tasks: true,
          },
        },
      },
    });

    if (!organization) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Organization not found',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    return c.json({
      success: true,
      data: {
        ...organization,
        userRole,
        stats: {
          projectCount: organization._count.projects,
          taskCount: organization._count.tasks,
          memberCount: organization.members.length,
        },
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get organization error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get organization',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// PUT /organizations/:id - Update organization
organizations.put('/:id', zValidator('json', updateOrganizationSchema), async (c) => {
  try {
    const organizationId = c.req.param('id');
    const userRole = c.get('userRole');
    const updateData = c.req.valid('json');

    // Check permissions
    if (userRole !== 'admin') {
      return c.json({
        success: false,
        error: {
          code: 'AUTHORIZATION_ERROR',
          message: 'Admin role required to update organization',
        },
        timestamp: new Date().toISOString()
      }, 403);
    }

    const organization = await prisma.organization.update({
      where: { id: organizationId },
      data: updateData,
    });

    return c.json({
      success: true,
      data: organization,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update organization error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to update organization',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /organizations/:id/invite - Invite member to organization
organizations.post('/:id/invite', zValidator('json', inviteMemberSchema), async (c) => {
  try {
    const organizationId = c.req.param('id');
    const userRole = c.get('userRole');
    const userProfile = c.get('userProfile');
    const { email, role, permissions } = c.req.valid('json');

    // Check permissions
    if (userRole !== 'admin') {
      return c.json({
        success: false,
        error: {
          code: 'AUTHORIZATION_ERROR',
          message: 'Admin role required to invite members',
        },
        timestamp: new Date().toISOString()
      }, 403);
    }

    // Check if user exists
    const invitedUser = await prisma.user.findUnique({
      where: { email },
    });

    if (!invitedUser) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'User with this email not found',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    // Check if user is already a member
    const existingMember = await prisma.organizationMember.findUnique({
      where: {
        organizationId_userId: {
          organizationId,
          userId: invitedUser.id,
        },
      },
    });

    if (existingMember) {
      return c.json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'User is already a member of this organization',
        },
        timestamp: new Date().toISOString()
      }, 400);
    }

    // Create membership
    const membership = await prisma.organizationMember.create({
      data: {
        organizationId,
        userId: invitedUser.id,
        role,
        permissions,
        invitedBy: userProfile.id,
        invitedAt: new Date(),
        joinedAt: new Date(),
        status: 'active',
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return c.json({
      success: true,
      data: membership,
      timestamp: new Date().toISOString()
    }, 201);

  } catch (error) {
    console.error('Invite member error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to invite member',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default organizations;
