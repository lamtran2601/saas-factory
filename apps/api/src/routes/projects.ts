import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import type { Env } from '../index';

const projects = new Hono<{ Bindings: Env }>();

// Validation schemas
const createProjectSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  status: z.enum(['active', 'archived', 'completed']).default('active'),
  settings: z.record(z.any()).default({}),
});

const updateProjectSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().max(500).optional(),
  status: z.enum(['active', 'archived', 'completed']).optional(),
  settings: z.record(z.any()).optional(),
});

const querySchema = z.object({
  page: z.string().transform(Number).default('1'),
  limit: z.string().transform(Number).default('20'),
  search: z.string().optional(),
  status: z.string().optional(),
  sortBy: z.string().default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

// GET /projects - List projects for organization
projects.get('/', zValidator('query', querySchema), async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const tenantPrisma = c.get('tenantPrisma');
    const { page, limit, search, status, sortBy, sortOrder } = c.req.valid('query');

    const skip = (page - 1) * limit;
    const where: any = {};

    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status) {
      where.status = status;
    }

    const [projectsData, total] = await Promise.all([
      tenantPrisma.project.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          creator: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
          _count: {
            select: {
              tasks: true,
            },
          },
        },
      }),
      tenantPrisma.project.count({ where }),
    ]);

    return c.json({
      success: true,
      data: projectsData,
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
    console.error('List projects error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to list projects',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /projects - Create new project
projects.post('/', zValidator('json', createProjectSchema), async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const userProfile = c.get('userProfile');
    const tenantPrisma = c.get('tenantPrisma');
    const projectData = c.req.valid('json');

    const project = await tenantPrisma.project.create({
      data: {
        ...projectData,
        createdBy: userProfile.id,
      },
      include: {
        creator: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return c.json({
      success: true,
      data: project,
      timestamp: new Date().toISOString()
    }, 201);

  } catch (error) {
    console.error('Create project error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to create project',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /projects/:id - Get project details
projects.get('/:id', async (c) => {
  try {
    const projectId = c.req.param('id');
    const tenantPrisma = c.get('tenantPrisma');

    const project = await tenantPrisma.project.findUnique({
      where: { id: projectId },
      include: {
        creator: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        tasks: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: {
            assignee: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
              },
            },
          },
        },
        _count: {
          select: {
            tasks: true,
          },
        },
      },
    });

    if (!project) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Project not found',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    return c.json({
      success: true,
      data: project,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get project error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get project',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// PUT /projects/:id - Update project
projects.put('/:id', zValidator('json', updateProjectSchema), async (c) => {
  try {
    const projectId = c.req.param('id');
    const tenantPrisma = c.get('tenantPrisma');
    const updateData = c.req.valid('json');

    const project = await tenantPrisma.project.update({
      where: { id: projectId },
      data: updateData,
      include: {
        creator: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
      },
    });

    return c.json({
      success: true,
      data: project,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update project error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to update project',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// DELETE /projects/:id - Delete project
projects.delete('/:id', async (c) => {
  try {
    const projectId = c.req.param('id');
    const tenantPrisma = c.get('tenantPrisma');

    await tenantPrisma.project.delete({
      where: { id: projectId },
    });

    return c.json({
      success: true,
      data: { id: projectId },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete project error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to delete project',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default projects;
