import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';
import { secureHeaders } from 'hono/secure-headers';

import { authMiddleware } from './middleware/auth';
import { errorHandler } from './middleware/error';
import { rateLimiter } from './middleware/rateLimit';
import { tenantMiddleware } from './middleware/tenant';

import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import organizationRoutes from './routes/organizations';
import projectRoutes from './routes/projects';
import taskRoutes from './routes/tasks';
import subscriptionRoutes from './routes/subscriptions';
import adminRoutes from './routes/admin';

// Types for Cloudflare Workers environment
export interface Env {
  DATABASE_URL: string;
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  JWT_SECRET: string;
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  NODE_ENV: string;
  FRONTEND_URL: string;
}

const app = new Hono<{ Bindings: Env }>();

// Global middleware
app.use('*', logger());
app.use('*', prettyJSON());
app.use('*', secureHeaders());

// CORS configuration
app.use(
  '*',
  cors({
    origin: (origin, c) => {
      // Get frontend URL from environment
      const frontendUrl = c.env?.FRONTEND_URL || 'http://localhost:3000';

      // Allow requests from frontend and development
      const allowedOrigins = [
        'http://localhost:3000',
        'https://app.saas-factory.com',
        'https://staging.saas-factory.com',
        'https://your-domain.com',
        'https://staging.your-domain.com',
        frontendUrl,
      ];

      // Allow any subdomain of your domain in production
      const isAllowedDomain =
        origin?.endsWith('.saas-factory.com') ||
        origin?.endsWith('.your-domain.com') ||
        origin?.endsWith('.pages.dev'); // Cloudflare Pages preview URLs

      return allowedOrigins.includes(origin) || isAllowedDomain;
    },
    credentials: true,
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowHeaders: [
      'Content-Type',
      'Authorization',
      'X-API-Key',
      'X-Requested-With',
    ],
  })
);

// Rate limiting
app.use('/api/*', rateLimiter);

// Error handling
app.onError(errorHandler);

// Health check endpoint
app.get('/health', c => {
  return c.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: c.env.NODE_ENV || 'development',
  });
});

// API routes
app.route('/api/auth', authRoutes);

// Protected routes with authentication
app.use('/api/*', authMiddleware);
app.route('/api/users', userRoutes);

// Organization-scoped routes with tenant middleware
app.use('/api/organizations/:id/*', tenantMiddleware);
app.route('/api/organizations', organizationRoutes);
app.route('/api/projects', projectRoutes);
app.route('/api/tasks', taskRoutes);
app.route('/api/subscriptions', subscriptionRoutes);

// Admin routes (requires admin role)
app.route('/api/admin', adminRoutes);

// 404 handler
app.notFound(c => {
  return c.json(
    {
      success: false,
      error: {
        code: 'NOT_FOUND',
        message: 'Endpoint not found',
      },
      timestamp: new Date().toISOString(),
    },
    404
  );
});

// Export for Cloudflare Workers
export default {
  async fetch(
    request: Request,
    env: Env,
    ctx: ExecutionContext
  ): Promise<Response> {
    return app.fetch(request, env, ctx);
  },
};

// Export app for testing
export { app };
