import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { prettyJSON } from 'hono/pretty-json';
import { secureHeaders } from 'hono/secure-headers';

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
  API_URL: string;
  ENVIRONMENT: string;
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
        'https://saas-factory-staging.pages.dev',
        'https://saas-factory-production.pages.dev',
        frontendUrl
      ];
      
      // Allow any subdomain of your domain in production
      const isAllowedDomain = origin?.endsWith('.saas-factory.com') || 
                             origin?.endsWith('.pages.dev'); // Cloudflare Pages preview URLs
      
      return allowedOrigins.includes(origin) || isAllowedDomain;
    },
    credentials: true,
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowHeaders: ['Content-Type', 'Authorization', 'X-API-Key', 'X-Requested-With'],
  })
);

// Health check endpoint
app.get('/health', (c) => {
  return c.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: c.env?.ENVIRONMENT || 'unknown',
    version: '1.0.0'
  });
});

// API info endpoint
app.get('/api', (c) => {
  return c.json({
    name: 'SaaS Factory API',
    version: '1.0.0',
    environment: c.env?.ENVIRONMENT || 'unknown',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      users: '/api/users',
      organizations: '/api/organizations',
      projects: '/api/projects',
      tasks: '/api/tasks',
      subscriptions: '/api/subscriptions'
    }
  });
});

// Auth endpoints
app.post('/api/auth/login', async (c) => {
  return c.json({
    message: 'Login endpoint - implementation coming soon',
    supabaseUrl: c.env?.SUPABASE_URL,
    environment: c.env?.ENVIRONMENT
  });
});

app.post('/api/auth/register', async (c) => {
  return c.json({
    message: 'Register endpoint - implementation coming soon',
    supabaseUrl: c.env?.SUPABASE_URL,
    environment: c.env?.ENVIRONMENT
  });
});

app.get('/api/auth/me', async (c) => {
  return c.json({
    message: 'User profile endpoint - implementation coming soon',
    environment: c.env?.ENVIRONMENT
  });
});

// Users endpoints
app.get('/api/users', async (c) => {
  return c.json({
    message: 'Users list endpoint - implementation coming soon',
    environment: c.env?.ENVIRONMENT
  });
});

// Organizations endpoints
app.get('/api/organizations', async (c) => {
  return c.json({
    message: 'Organizations list endpoint - implementation coming soon',
    environment: c.env?.ENVIRONMENT
  });
});

// Projects endpoints
app.get('/api/projects', async (c) => {
  return c.json({
    message: 'Projects list endpoint - implementation coming soon',
    environment: c.env?.ENVIRONMENT
  });
});

// Tasks endpoints
app.get('/api/tasks', async (c) => {
  return c.json({
    message: 'Tasks list endpoint - implementation coming soon',
    environment: c.env?.ENVIRONMENT
  });
});

// Subscriptions endpoints
app.get('/api/subscriptions', async (c) => {
  return c.json({
    message: 'Subscriptions endpoint - implementation coming soon',
    environment: c.env?.ENVIRONMENT
  });
});

// Error handling
app.onError((err, c) => {
  console.error('API Error:', err);
  return c.json({
    error: 'Internal Server Error',
    message: err.message,
    environment: c.env?.ENVIRONMENT
  }, 500);
});

// 404 handler
app.notFound((c) => {
  return c.json({
    error: 'Not Found',
    message: 'The requested endpoint does not exist',
    environment: c.env?.ENVIRONMENT
  }, 404);
});

export default app;
