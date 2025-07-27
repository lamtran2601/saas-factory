import { Context, Next } from 'hono';
import type { Env } from '../index';

// Simple in-memory rate limiter (for production, use Redis or KV store)
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  keyGenerator?: (c: Context) => string;
}

const defaultConfig: RateLimitConfig = {
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100, // 100 requests per window
  keyGenerator: (c) => {
    // Use IP address as default key
    const forwarded = c.req.header('x-forwarded-for');
    const ip = forwarded ? forwarded.split(',')[0] : c.req.header('cf-connecting-ip') || 'unknown';
    return ip;
  },
};

export async function rateLimiter(c: Context<{ Bindings: Env }>, next: Next) {
  const config = defaultConfig;
  const key = config.keyGenerator!(c);
  const now = Date.now();
  
  // Clean up expired entries
  for (const [k, v] of rateLimitStore.entries()) {
    if (now > v.resetTime) {
      rateLimitStore.delete(k);
    }
  }
  
  // Get or create rate limit entry
  let entry = rateLimitStore.get(key);
  if (!entry || now > entry.resetTime) {
    entry = {
      count: 0,
      resetTime: now + config.windowMs,
    };
    rateLimitStore.set(key, entry);
  }
  
  // Check if limit exceeded
  if (entry.count >= config.maxRequests) {
    const resetIn = Math.ceil((entry.resetTime - now) / 1000);
    
    // Set rate limit headers
    c.header('X-RateLimit-Limit', config.maxRequests.toString());
    c.header('X-RateLimit-Remaining', '0');
    c.header('X-RateLimit-Reset', entry.resetTime.toString());
    c.header('Retry-After', resetIn.toString());
    
    return c.json({
      success: false,
      error: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests',
        details: {
          limit: config.maxRequests,
          windowMs: config.windowMs,
          resetIn,
        },
      },
      timestamp: new Date().toISOString()
    }, 429);
  }
  
  // Increment counter
  entry.count++;
  
  // Set rate limit headers
  c.header('X-RateLimit-Limit', config.maxRequests.toString());
  c.header('X-RateLimit-Remaining', (config.maxRequests - entry.count).toString());
  c.header('X-RateLimit-Reset', entry.resetTime.toString());
  
  await next();
}

// Enhanced rate limiter for API keys
export function createApiKeyRateLimiter(config: Partial<RateLimitConfig> = {}) {
  const finalConfig = {
    ...defaultConfig,
    ...config,
    keyGenerator: (c: Context) => {
      const apiKey = c.req.header('X-API-Key');
      if (apiKey) {
        return `apikey:${apiKey}`;
      }
      // Fallback to IP-based limiting
      const forwarded = c.req.header('x-forwarded-for');
      const ip = forwarded ? forwarded.split(',')[0] : c.req.header('cf-connecting-ip') || 'unknown';
      return `ip:${ip}`;
    },
  };

  return async (c: Context<{ Bindings: Env }>, next: Next) => {
    const key = finalConfig.keyGenerator!(c);
    const now = Date.now();
    
    // Clean up expired entries
    for (const [k, v] of rateLimitStore.entries()) {
      if (now > v.resetTime) {
        rateLimitStore.delete(k);
      }
    }
    
    // Get or create rate limit entry
    let entry = rateLimitStore.get(key);
    if (!entry || now > entry.resetTime) {
      entry = {
        count: 0,
        resetTime: now + finalConfig.windowMs,
      };
      rateLimitStore.set(key, entry);
    }
    
    // Check if limit exceeded
    if (entry.count >= finalConfig.maxRequests) {
      const resetIn = Math.ceil((entry.resetTime - now) / 1000);
      
      // Set rate limit headers
      c.header('X-RateLimit-Limit', finalConfig.maxRequests.toString());
      c.header('X-RateLimit-Remaining', '0');
      c.header('X-RateLimit-Reset', entry.resetTime.toString());
      c.header('Retry-After', resetIn.toString());
      
      return c.json({
        success: false,
        error: {
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'Too many requests',
          details: {
            limit: finalConfig.maxRequests,
            windowMs: finalConfig.windowMs,
            resetIn,
          },
        },
        timestamp: new Date().toISOString()
      }, 429);
    }
    
    // Increment counter
    entry.count++;
    
    // Set rate limit headers
    c.header('X-RateLimit-Limit', finalConfig.maxRequests.toString());
    c.header('X-RateLimit-Remaining', (finalConfig.maxRequests - entry.count).toString());
    c.header('X-RateLimit-Reset', entry.resetTime.toString());
    
    await next();
  };
}
