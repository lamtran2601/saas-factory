import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import type { Env } from '../index';

const subscriptions = new Hono<{ Bindings: Env }>();
const prisma = new PrismaClient();

// Validation schemas
const createSubscriptionSchema = z.object({
  planId: z.string().uuid(),
  paymentMethodId: z.string().optional(),
});

const updateSubscriptionSchema = z.object({
  planId: z.string().uuid().optional(),
  status: z.enum(['active', 'cancelled', 'past_due', 'trialing']).optional(),
});

// GET /subscriptions - Get organization subscription
subscriptions.get('/', async (c) => {
  try {
    const organizationId = c.get('organizationId');

    const subscription = await prisma.subscription.findFirst({
      where: { organizationId },
      include: {
        plan: true,
        organization: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!subscription) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'No subscription found for this organization',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    return c.json({
      success: true,
      data: subscription,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Get subscription error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to get subscription',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// POST /subscriptions - Create or update subscription
subscriptions.post('/', zValidator('json', createSubscriptionSchema), async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const userRole = c.get('userRole');
    const { planId, paymentMethodId } = c.req.valid('json');

    // Check permissions
    if (userRole !== 'admin') {
      return c.json({
        success: false,
        error: {
          code: 'AUTHORIZATION_ERROR',
          message: 'Admin role required to manage subscriptions',
        },
        timestamp: new Date().toISOString()
      }, 403);
    }

    // Get the plan
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { id: planId },
    });

    if (!plan) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'Subscription plan not found',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    // Check if organization already has a subscription
    const existingSubscription = await prisma.subscription.findFirst({
      where: { organizationId },
    });

    if (existingSubscription) {
      // Update existing subscription
      const updatedSubscription = await prisma.subscription.update({
        where: { id: existingSubscription.id },
        data: {
          planId,
          status: 'active',
          currentPeriodStart: new Date(),
          currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        },
        include: {
          plan: true,
        },
      });

      return c.json({
        success: true,
        data: updatedSubscription,
        timestamp: new Date().toISOString()
      });
    } else {
      // Create new subscription
      const subscription = await prisma.subscription.create({
        data: {
          organizationId,
          planId,
          status: 'active',
          currentPeriodStart: new Date(),
          currentPeriodEnd: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        },
        include: {
          plan: true,
        },
      });

      // Update organization plan
      await prisma.organization.update({
        where: { id: organizationId },
        data: { planId },
      });

      return c.json({
        success: true,
        data: subscription,
        timestamp: new Date().toISOString()
      }, 201);
    }

  } catch (error) {
    console.error('Create subscription error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to create subscription',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// PUT /subscriptions - Update subscription
subscriptions.put('/', zValidator('json', updateSubscriptionSchema), async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const userRole = c.get('userRole');
    const updateData = c.req.valid('json');

    // Check permissions
    if (userRole !== 'admin') {
      return c.json({
        success: false,
        error: {
          code: 'AUTHORIZATION_ERROR',
          message: 'Admin role required to manage subscriptions',
        },
        timestamp: new Date().toISOString()
      }, 403);
    }

    const subscription = await prisma.subscription.findFirst({
      where: { organizationId },
    });

    if (!subscription) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'No subscription found for this organization',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    const updatedSubscription = await prisma.subscription.update({
      where: { id: subscription.id },
      data: updateData,
      include: {
        plan: true,
      },
    });

    return c.json({
      success: true,
      data: updatedSubscription,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Update subscription error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to update subscription',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// DELETE /subscriptions - Cancel subscription
subscriptions.delete('/', async (c) => {
  try {
    const organizationId = c.get('organizationId');
    const userRole = c.get('userRole');

    // Check permissions
    if (userRole !== 'admin') {
      return c.json({
        success: false,
        error: {
          code: 'AUTHORIZATION_ERROR',
          message: 'Admin role required to manage subscriptions',
        },
        timestamp: new Date().toISOString()
      }, 403);
    }

    const subscription = await prisma.subscription.findFirst({
      where: { organizationId },
    });

    if (!subscription) {
      return c.json({
        success: false,
        error: {
          code: 'NOT_FOUND',
          message: 'No subscription found for this organization',
        },
        timestamp: new Date().toISOString()
      }, 404);
    }

    const cancelledSubscription = await prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: 'cancelled',
        canceledAt: new Date(),
      },
    });

    return c.json({
      success: true,
      data: cancelledSubscription,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Cancel subscription error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to cancel subscription',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

// GET /subscriptions/plans - List available subscription plans
subscriptions.get('/plans', async (c) => {
  try {
    const plans = await prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { priceMonthly: 'asc' },
    });

    return c.json({
      success: true,
      data: plans,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('List plans error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to list subscription plans',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
});

export default subscriptions;
