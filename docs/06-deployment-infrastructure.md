# SaaS Factory - Deployment & Infrastructure

## Overview

The deployment strategy leverages Cloudflare's edge computing platform for global performance, scalability, and cost efficiency. The infrastructure is designed for zero-downtime deployments with automatic scaling and comprehensive monitoring.

## Infrastructure Architecture

### Cloudflare Services

#### Cloudflare Pages (Frontend)
- **Static site hosting** for React application
- **Global CDN** with 200+ edge locations
- **Automatic HTTPS** with SSL certificates
- **Preview deployments** for pull requests
- **Custom domains** with DNS management

#### Cloudflare Workers (Backend API)
- **Serverless compute** for Hono.js API
- **Edge computing** with sub-50ms response times
- **Automatic scaling** based on demand
- **Zero cold starts** with V8 isolates
- **Global deployment** across all edge locations

#### Cloudflare D1 (Database Option 1)
- **SQLite at the edge** for low-latency access
- **Global replication** with eventual consistency
- **Automatic backups** and point-in-time recovery
- **Cost-effective** for read-heavy workloads

#### External PostgreSQL (Database Option 2)
- **Dedicated PostgreSQL** for complex queries
- **Connection pooling** via PgBouncer
- **Read replicas** for scaling reads
- **Automated backups** and monitoring

#### Additional Cloudflare Services
- **KV Store**: Session storage and caching
- **R2 Storage**: File uploads and media storage
- **Analytics**: Performance and usage metrics
- **Security**: DDoS protection and WAF

## Environment Strategy

### Development Environment
```yaml
Environment: development
Frontend: http://localhost:3000 (Vite dev server)
API: http://localhost:8787 (Wrangler dev)
Database: Local PostgreSQL (Docker)
Storage: Local filesystem
```

### Staging Environment
```yaml
Environment: staging
Frontend: https://staging.saas-factory.com (Cloudflare Pages)
API: https://api-staging.saas-factory.com (Cloudflare Workers)
Database: Staging PostgreSQL (Neon/Supabase)
Storage: Cloudflare R2 (staging bucket)
```

### Production Environment
```yaml
Environment: production
Frontend: https://app.saas-factory.com (Cloudflare Pages)
API: https://api.saas-factory.com (Cloudflare Workers)
Database: Production PostgreSQL (Neon/Supabase)
Storage: Cloudflare R2 (production bucket)
```

## Deployment Configuration

### Frontend Deployment (Cloudflare Pages)

#### `wrangler.toml` (Pages)
```toml
name = "saas-factory-frontend"
compatibility_date = "2024-01-15"

[env.production]
account_id = "your-account-id"
zone_id = "your-zone-id"

[env.staging]
account_id = "your-account-id"
zone_id = "your-zone-id"

[[env.production.routes]]
pattern = "app.saas-factory.com/*"
zone_name = "saas-factory.com"

[[env.staging.routes]]
pattern = "staging.saas-factory.com/*"
zone_name = "saas-factory.com"
```

#### Build Configuration
```json
{
  "build": {
    "command": "npm run build",
    "publish": "dist",
    "environment": {
      "NODE_VERSION": "18",
      "NPM_VERSION": "9"
    }
  },
  "functions": {
    "directory": "functions",
    "node_compat": true
  }
}
```

### Backend Deployment (Cloudflare Workers)

#### `wrangler.toml` (Workers)
```toml
name = "saas-factory-api"
main = "src/index.ts"
compatibility_date = "2024-01-15"
node_compat = true

[env.production]
name = "saas-factory-api-prod"
vars = { ENVIRONMENT = "production" }

[[env.production.kv_namespaces]]
binding = "CACHE"
id = "your-kv-namespace-id"

[[env.production.d1_databases]]
binding = "DB"
database_name = "saas-factory-prod"
database_id = "your-d1-database-id"

[env.staging]
name = "saas-factory-api-staging"
vars = { ENVIRONMENT = "staging" }

[[env.staging.kv_namespaces]]
binding = "CACHE"
id = "your-staging-kv-namespace-id"

[[env.staging.d1_databases]]
binding = "DB"
database_name = "saas-factory-staging"
database_id = "your-staging-d1-database-id"
```

#### Environment Variables
```bash
# Production secrets (via Wrangler)
wrangler secret put DATABASE_URL --env production
wrangler secret put JWT_SECRET --env production
wrangler secret put STRIPE_SECRET_KEY --env production
wrangler secret put EMAIL_API_KEY --env production

# Staging secrets
wrangler secret put DATABASE_URL --env staging
wrangler secret put JWT_SECRET --env staging
wrangler secret put STRIPE_SECRET_KEY --env staging
wrangler secret put EMAIL_API_KEY --env staging
```

## CI/CD Pipeline

### GitHub Actions Workflow

#### `.github/workflows/deploy.yml`
```yaml
name: Deploy SaaS Factory

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linting
        run: npm run lint
      
      - name: Run type checking
        run: npm run type-check
      
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run integration tests
        run: npm run test:integration

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build frontend
        run: npm run build:frontend
        env:
          VITE_API_URL: https://api-staging.saas-factory.com
          VITE_ENVIRONMENT: staging
      
      - name: Deploy frontend to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: saas-factory-frontend
          directory: frontend/dist
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Deploy API to Cloudflare Workers
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          workingDirectory: backend
          command: deploy --env staging

  deploy-production:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build frontend
        run: npm run build:frontend
        env:
          VITE_API_URL: https://api.saas-factory.com
          VITE_ENVIRONMENT: production
      
      - name: Deploy frontend to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: saas-factory-frontend
          directory: frontend/dist
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Deploy API to Cloudflare Workers
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          workingDirectory: backend
          command: deploy --env production
      
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          E2E_BASE_URL: https://app.saas-factory.com

  database-migration:
    needs: [deploy-staging, deploy-production]
    runs-on: ubuntu-latest
    if: always() && (needs.deploy-staging.result == 'success' || needs.deploy-production.result == 'success')
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run database migrations (staging)
        if: needs.deploy-staging.result == 'success'
        run: npm run db:migrate
        env:
          DATABASE_URL: ${{ secrets.STAGING_DATABASE_URL }}
      
      - name: Run database migrations (production)
        if: needs.deploy-production.result == 'success'
        run: npm run db:migrate
        env:
          DATABASE_URL: ${{ secrets.PRODUCTION_DATABASE_URL }}
```

## Database Deployment

### Migration Strategy
```typescript
// Prisma migration workflow
export const migrationWorkflow = {
  development: [
    'npx prisma db push',           // Push schema changes
    'npx prisma generate',          // Generate client
    'npx prisma db seed'            // Seed development data
  ],
  
  staging: [
    'npx prisma migrate deploy',    // Apply migrations
    'npx prisma generate',          // Generate client
    'npm run db:seed:staging'       // Seed staging data
  ],
  
  production: [
    'npx prisma migrate deploy',    // Apply migrations
    'npx prisma generate'           // Generate client
    // No seeding in production
  ]
}
```

### Backup Strategy
```bash
# Automated daily backups
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump $DATABASE_URL > backup_$DATE.sql
aws s3 cp backup_$DATE.sql s3://saas-factory-backups/
```

## Monitoring & Observability

### Application Monitoring
```typescript
// Cloudflare Analytics integration
export const analytics = {
  pageViews: 'cf-analytics',
  apiRequests: 'cf-workers-analytics',
  errors: 'cf-error-tracking',
  performance: 'cf-web-vitals'
}

// Custom metrics
export const customMetrics = {
  userRegistrations: 'user_registrations_total',
  subscriptionChanges: 'subscription_changes_total',
  apiKeyUsage: 'api_key_requests_total',
  organizationCreated: 'organizations_created_total'
}
```

### Health Checks
```typescript
// API health check endpoint
app.get('/health', async (c) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkKVStore(),
    external: await checkExternalServices()
  }
  
  const isHealthy = Object.values(checks).every(check => check.status === 'ok')
  
  return c.json({
    status: isHealthy ? 'healthy' : 'unhealthy',
    timestamp: new Date().toISOString(),
    checks
  }, isHealthy ? 200 : 503)
})
```

### Alerting
```yaml
# Cloudflare alerting rules
alerts:
  - name: High Error Rate
    condition: error_rate > 5%
    duration: 5m
    notification: slack, email
  
  - name: High Response Time
    condition: p95_response_time > 1000ms
    duration: 10m
    notification: slack
  
  - name: Database Connection Issues
    condition: db_connection_errors > 0
    duration: 1m
    notification: slack, pagerduty
```

## Security Configuration

### Content Security Policy
```typescript
// CSP headers for frontend
const cspHeader = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' https://js.stripe.com",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com",
  "img-src 'self' data: https:",
  "connect-src 'self' https://api.saas-factory.com",
  "frame-src https://js.stripe.com"
].join('; ')
```

### CORS Configuration
```typescript
// CORS settings for API
const corsConfig = {
  origin: [
    'https://app.saas-factory.com',
    'https://staging.saas-factory.com',
    ...(process.env.NODE_ENV === 'development' ? ['http://localhost:3000'] : [])
  ],
  credentials: true,
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'X-API-Key']
}
```

## Cost Optimization

### Cloudflare Pricing Tiers
- **Free Tier**: Development and small projects
- **Pro Plan**: $20/month for enhanced performance
- **Business Plan**: $200/month for advanced security
- **Enterprise**: Custom pricing for large scale

### Resource Optimization
```typescript
// Caching strategy
const cacheConfig = {
  static: '1y',           // Static assets
  api: '5m',              // API responses
  user: '1h',             // User data
  organization: '30m'     // Organization data
}

// Bundle optimization
const bundleConfig = {
  splitting: true,        // Code splitting
  treeshaking: true,      // Remove unused code
  minification: true,     // Minify output
  compression: 'gzip'     // Compress assets
}
```

This deployment strategy provides a robust, scalable infrastructure foundation for the SaaS Factory platform with global performance and enterprise-grade reliability.
