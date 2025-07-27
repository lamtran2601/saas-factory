import { Context } from 'hono';
import { HTTPException } from 'hono/http-exception';

export function errorHandler(err: Error, c: Context) {
  console.error('API Error:', err);

  // Handle HTTP exceptions from Hono
  if (err instanceof HTTPException) {
    return c.json({
      success: false,
      error: {
        code: 'HTTP_ERROR',
        message: err.message,
      },
      timestamp: new Date().toISOString()
    }, err.status);
  }

  // Handle Prisma errors
  if (err.name === 'PrismaClientKnownRequestError') {
    const prismaError = err as any;
    
    switch (prismaError.code) {
      case 'P2002':
        return c.json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'A record with this value already exists',
            details: {
              field: prismaError.meta?.target?.[0] || 'unknown',
            },
          },
          timestamp: new Date().toISOString()
        }, 400);
      
      case 'P2025':
        return c.json({
          success: false,
          error: {
            code: 'NOT_FOUND',
            message: 'Record not found',
          },
          timestamp: new Date().toISOString()
        }, 404);
      
      default:
        return c.json({
          success: false,
          error: {
            code: 'DATABASE_ERROR',
            message: 'Database operation failed',
          },
          timestamp: new Date().toISOString()
        }, 500);
    }
  }

  // Handle validation errors
  if (err.name === 'ZodError') {
    const zodError = err as any;
    return c.json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input data',
        details: zodError.errors,
      },
      timestamp: new Date().toISOString()
    }, 400);
  }

  // Handle authentication errors
  if (err.message.includes('authentication') || err.message.includes('unauthorized')) {
    return c.json({
      success: false,
      error: {
        code: 'AUTHENTICATION_ERROR',
        message: 'Authentication failed',
      },
      timestamp: new Date().toISOString()
    }, 401);
  }

  // Handle authorization errors
  if (err.message.includes('authorization') || err.message.includes('forbidden')) {
    return c.json({
      success: false,
      error: {
        code: 'AUTHORIZATION_ERROR',
        message: 'Access denied',
      },
      timestamp: new Date().toISOString()
    }, 403);
  }

  // Default error response
  return c.json({
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    },
    timestamp: new Date().toISOString()
  }, 500);
}
