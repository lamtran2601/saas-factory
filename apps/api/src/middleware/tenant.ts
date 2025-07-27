import { Context, Next } from 'hono';
import { PrismaClient } from '@prisma/client';
import type { Env } from '../index';

const prisma = new PrismaClient();

export async function tenantMiddleware(c: Context<{ Bindings: Env }>, next: Next) {
  try {
    const organizationId = c.req.param('id');
    const authType = c.get('authType');

    if (!organizationId) {
      return c.json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Organization ID is required',
        },
        timestamp: new Date().toISOString()
      }, 400);
    }

    if (authType === 'jwt') {
      // For JWT authentication, verify user belongs to organization
      const userProfile = c.get('userProfile');
      
      const membership = userProfile?.organizationMembers.find(
        (member: any) => member.organizationId === organizationId
      );

      if (!membership) {
        return c.json({
          success: false,
          error: {
            code: 'AUTHORIZATION_ERROR',
            message: 'Access denied to this organization',
          },
          timestamp: new Date().toISOString()
        }, 403);
      }

      // Set organization context
      c.set('organizationId', organizationId);
      c.set('userRole', membership.role);
      c.set('userPermissions', membership.permissions);
      c.set('membership', membership);

    } else if (authType === 'apikey') {
      // For API key authentication, verify key belongs to organization
      const apiKey = c.get('apiKey');
      
      if (apiKey.organizationId !== organizationId) {
        return c.json({
          success: false,
          error: {
            code: 'AUTHORIZATION_ERROR',
            message: 'API key does not have access to this organization',
          },
          timestamp: new Date().toISOString()
        }, 403);
      }

      // Set organization context
      c.set('organizationId', organizationId);
      c.set('apiKeyPermissions', apiKey.permissions);
    }

    // Create tenant-aware Prisma client
    const tenantPrisma = prisma.$extends({
      query: {
        project: {
          async findMany({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async findFirst({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async findUnique({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async create({ args, query }) {
            args.data = { ...args.data, organizationId };
            return query(args);
          },
          async update({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async delete({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
        },
        task: {
          async findMany({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async findFirst({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async findUnique({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async create({ args, query }) {
            args.data = { ...args.data, organizationId };
            return query(args);
          },
          async update({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
          async delete({ args, query }) {
            args.where = { ...args.where, organizationId };
            return query(args);
          },
        },
      },
    });

    c.set('tenantPrisma', tenantPrisma);

    await next();
  } catch (error) {
    console.error('Tenant middleware error:', error);
    return c.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Tenant authorization error',
      },
      timestamp: new Date().toISOString()
    }, 500);
  }
}
