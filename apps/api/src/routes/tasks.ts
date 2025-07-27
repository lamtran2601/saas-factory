import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import type { Env } from '../index';

const tasks = new Hono<{ Bindings: Env }>();

// Validation schemas
const createTaskSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  projectId: z.string().uuid().optional(),
  status: z.enum(['todo', 'in_progress', 'completed', 'cancelled']).default('todo'),
  priority: z.enum(['low', 'medium', 'high', 'urgent']).default('medium'),
  assignedTo: z.string().uuid().optional(),
  dueDate: z.string().datetime().optional(),
});

const updateTaskSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(1000).optional(),
  projectId: z.string().uuid().optional(),
  status: z.enum(['todo', 'in_progress', 'completed', 'cancelled']).optional(),
  priority: z.enum(['low', 'medium', 'high', 'urgent']).optional(),
  assignedTo: z.string().uuid().optional(),
  dueDate: z.string().datetime().optional(),
});

const querySchema = z.object({
  page: z.string().transform(Number).default('1'),
  limit: z.string().transform(Number).default('20'),
  search: z.string().optional(),
  status: z.string().optional(),
  priority: z.string().optional(),
  assignedTo: z.string().optional(),
  projectId: z.string().optional(),
  sortBy: z.string().default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

// GET /tasks - List tasks for organization
tasks.get('/', zValidator('query', querySchema), async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const tenantPrisma = c.get('tenantPrisma');
    const { page, limit, search, status, priority, assignedTo, projectId, sortBy, sortOrder } = c.req.valid('query');

    const skip = (page - 1) * limit;
    const where: any = {};

    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (status) {
      where.status = status;
    }

    if (priority) {
      where.priority = priority;
    }

    if (assignedTo) {
      where.assignedTo = assignedTo;
    }

    if (projectId) {
      where.projectId = projectId;
    }

    const [tasksData, total] = await Promise.all([
      tenantPrisma.task.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder },
        include: {
          project: {
            select: {
              id: true,
              name: true,
            },
          },
          assignee: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
          creator: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
        },
      }),
      tenantPrisma.task.count({ where }),
    ]);

    return c.json({
      success: true,
      data: tasksData,
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
    console.error('List tasks error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to list tasks',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /tasks - Create new task
tasks.post('/', zValidator('json', createTaskSchema), async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const userProfile = c.get('userProfile');
    const tenantPrisma = c.get('tenantPrisma');
    const taskData = c.req.valid('json');

    // Convert dueDate string to Date if provided
    const processedData = {
      ...taskData,
      dueDate: taskData.dueDate ? new Date(taskData.dueDate) : undefined,
      createdBy: userProfile.id,
    };

    const task = await tenantPrisma.task.create({
      data: processedData,
      include: {
        project: {
          select: {
            id: true,
            name: true,
          },
        },
        assignee: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
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
      data: task,
      timestamp: new Date().toISOString()
    }, 201);

  } catch (error) {
    console.error('Create task error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to create task',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /tasks/:id - Get task details
tasks.get('/:id', async (c) => {
  try {
    const taskId = c.req.param('id');
    const tenantPrisma = c.get('tenantPrisma');

    const task = await tenantPrisma.task.findUnique({
      where: { id: taskId },
      include: {
        project: {
          select: {
            id: true,
            name: true,
          },
        },
        assignee: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
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

    if (!task) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Task not found',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    return c.json({
      success: true,
      data: task,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get task error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get task',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// PUT /tasks/:id - Update task
tasks.put('/:id', zValidator('json', updateTaskSchema), async (c) => {
  try {
    const taskId = c.req.param('id');
    const tenantPrisma = c.get('tenantPrisma');
    const updateData = c.req.valid('json');

    // Convert dueDate string to Date if provided
    const processedData = {
      ...updateData,
      dueDate: updateData.dueDate ? new Date(updateData.dueDate) : undefined,
      completedAt: updateData.status === 'completed' ? new Date() : undefined,
    };

    const task = await tenantPrisma.task.update({
      where: { id: taskId },
      data: processedData,
      include: {
        project: {
          select: {
            id: true,
            name: true,
          },
        },
        assignee: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
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
      data: task,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update task error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to update task',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// DELETE /tasks/:id - Delete task
tasks.delete('/:id', async (c) => {
  try {
    const taskId = c.req.param('id');
    const tenantPrisma = c.get('tenantPrisma');

    await tenantPrisma.task.delete({
      where: { id: taskId },
    });

    return c.json({
      success: true,
      data: { id: taskId },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Delete task error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to delete task',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default tasks;
