# SaaS Factory - Deployment Setup Guide

## Overview

This guide walks you through setting up automated deployment infrastructure for the SaaS Factory
application using Supabase and Cloudflare services.

## Prerequisites

Before starting, ensure you have:

- Cloudflare account with Workers and Pages access
- Supabase account
- Git repository hosted on GitHub/GitLab
- Domain name (optional, for custom domains)

## Step 1: Supabase Configuration

### 1.1 Create Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Choose your organization
4. Set project details:
   - **Name**: `saas-factory-production`
   - **Database Password**: Generate a strong password
   - **Region**: Choose closest to your users
5. Wait for project creation (2-3 minutes)

### 1.2 Configure Database Schema

1. In your Supabase project dashboard, go to "SQL Editor"
2. Run the following to prepare for Prisma migrations:

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a user for Prisma (optional, for better security)
CREATE USER prisma_user WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE postgres TO prisma_user;
GRANT ALL ON SCHEMA public TO prisma_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO prisma_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO prisma_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO prisma_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO prisma_user;
```

### 1.3 Get Supabase Credentials

From your Supabase project dashboard:

1. Go to "Settings" → "API"
2. Copy the following values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon Key**: `eyJ...` (public key)
   - **Service Role Key**: `eyJ...` (secret key)

3. Go to "Settings" → "Database"
4. Copy the **Connection String** (URI format)

### 1.4 Configure Supabase Auth

1. Go to "Authentication" → "Settings"
2. Configure the following:
   - **Site URL**: `https://your-domain.com` (production frontend URL)
   - **Redirect URLs**: Add your frontend URLs:
     - `http://localhost:3000/**` (development)
     - `https://staging.your-domain.com/**` (staging)
     - `https://your-domain.com/**` (production)

3. Enable desired auth providers (Email, Google, GitHub, etc.)

## Step 2: Cloudflare Configuration

### 2.1 Install Wrangler CLI

```bash
npm install -g wrangler
# or
bun add -g wrangler
```

### 2.2 Authenticate with Cloudflare

```bash
wrangler login
```

### 2.3 Get Cloudflare Account Details

```bash
# Get your account ID
wrangler whoami

# List your zones (if you have a custom domain)
wrangler zone list
```

## Step 3: Environment Configuration

### 3.1 Update API Environment Files

Create production environment file:

```bash
cp apps/api/.env.example apps/api/.env.production
```

Edit `apps/api/.env.production`:

```env
# Database Configuration (Supabase PostgreSQL)
DATABASE_URL="postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres"

# Supabase Auth Configuration
SUPABASE_URL="https://your-project-id.supabase.co"
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# JWT Configuration
JWT_SECRET="your-production-jwt-secret-min-32-chars"

# Application Configuration
NODE_ENV="production"
API_URL="https://api.your-domain.com"
FRONTEND_URL="https://your-domain.com"

# Stripe Configuration (if using)
STRIPE_SECRET_KEY="sk_live_your_stripe_secret_key"
STRIPE_WEBHOOK_SECRET="whsec_your_webhook_secret"

# Email Service Configuration
EMAIL_API_KEY="your-email-service-api-key"
EMAIL_FROM="noreply@your-domain.com"
```

### 3.2 Update Web Environment Files

Create production environment file:

```bash
cp apps/web/.env.example apps/web/.env.production
```

Edit `apps/web/.env.production`:

```env
# API Configuration
VITE_API_URL="https://api.your-domain.com"

# Supabase Auth Configuration
VITE_SUPABASE_URL="https://your-project-id.supabase.co"
VITE_SUPABASE_ANON_KEY="your-anon-key"

# Stripe Configuration
VITE_STRIPE_PUBLISHABLE_KEY="pk_live_your_stripe_publishable_key"

# Application Configuration
VITE_APP_NAME="SaaS Factory"
VITE_APP_URL="https://your-domain.com"
VITE_ENVIRONMENT="production"
```

## Step 4: Cloudflare Workers Deployment (API)

### 4.1 Update wrangler.toml

The `apps/api/wrangler.toml` file needs to be updated with your Cloudflare account details and
environment variables.

### 4.2 Set Cloudflare Secrets

```bash
cd apps/api

# Set production secrets
wrangler secret put DATABASE_URL --env production
wrangler secret put SUPABASE_SERVICE_ROLE_KEY --env production
wrangler secret put JWT_SECRET --env production
wrangler secret put STRIPE_SECRET_KEY --env production

# Set staging secrets
wrangler secret put DATABASE_URL --env staging
wrangler secret put SUPABASE_SERVICE_ROLE_KEY --env staging
wrangler secret put JWT_SECRET --env staging
```

### 4.3 Deploy API to Cloudflare Workers

```bash
cd apps/api

# Deploy to staging
wrangler deploy --env staging

# Deploy to production
wrangler deploy --env production
```

## Step 5: Cloudflare Pages Deployment (Frontend)

### 5.1 Create Pages Project

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to "Pages"
3. Click "Create a project"
4. Connect your Git repository
5. Configure build settings:
   - **Framework preset**: Vite
   - **Build command**: `cd apps/web && bun run build`
   - **Build output directory**: `apps/web/dist`
   - **Root directory**: `/`

### 5.2 Configure Environment Variables

In your Cloudflare Pages project settings:

1. Go to "Settings" → "Environment variables"
2. Add production variables:
   - `VITE_API_URL`: `https://api.your-domain.com`
   - `VITE_SUPABASE_URL`: `https://your-project-id.supabase.co`
   - `VITE_SUPABASE_ANON_KEY`: `your-anon-key`
   - `VITE_STRIPE_PUBLISHABLE_KEY`: `pk_live_...`
   - `VITE_APP_URL`: `https://your-domain.com`
   - `VITE_ENVIRONMENT`: `production`

## Step 6: Database Migration

### 6.1 Run Production Migrations

```bash
cd apps/api

# Set the production database URL
export DATABASE_URL="postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres"

# Generate Prisma client
bunx prisma generate

# Deploy migrations to production
bunx prisma migrate deploy

# Verify migration status
bunx prisma migrate status
```

## Step 7: Custom Domain Setup (Optional)

### 7.1 Configure Custom Domain for API

1. In Cloudflare Dashboard, go to "Workers & Pages"
2. Select your API worker
3. Go to "Settings" → "Triggers"
4. Add custom domain: `api.your-domain.com`

### 7.2 Configure Custom Domain for Frontend

1. In your Pages project, go to "Custom domains"
2. Add domain: `your-domain.com`
3. Follow DNS configuration instructions

## Step 8: Testing Deployment

### 8.1 Test API Endpoints

```bash
# Test health endpoint
curl https://api.your-domain.com/health

# Test authentication endpoint
curl https://api.your-domain.com/api/auth/me
```

### 8.2 Test Frontend

1. Visit your frontend URL
2. Test user registration/login
3. Verify API communication
4. Check browser console for errors

## Step 9: Monitoring and Logging

### 9.1 Cloudflare Analytics

1. Enable analytics in your Workers and Pages projects
2. Set up alerts for errors and performance issues

### 9.2 Supabase Monitoring

1. Monitor database performance in Supabase dashboard
2. Set up log retention and alerts

## Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure frontend URL is added to API CORS configuration
2. **Database Connection**: Verify DATABASE_URL format and credentials
3. **Environment Variables**: Check all required variables are set in Cloudflare
4. **Build Failures**: Verify build commands and dependencies

### Debug Commands

```bash
# Check Wrangler configuration
wrangler whoami

# View worker logs
wrangler tail --env production

# Test local build
cd apps/web && bun run build
cd apps/api && bun run build
```

## Next Steps

1. Set up automated deployments with GitHub Actions
2. Configure monitoring and alerting
3. Set up backup strategies
4. Implement blue-green deployments
5. Configure CDN caching strategies

## Security Checklist

- [ ] All secrets stored in Cloudflare secrets (not environment variables)
- [ ] JWT secrets are strong and unique per environment
- [ ] Database credentials are secure
- [ ] CORS is properly configured
- [ ] HTTPS is enforced
- [ ] Supabase RLS policies are disabled (using application-level security)
- [ ] API rate limiting is configured

## Quick Start Commands

Once you have completed the setup above, you can use these commands:

```bash
# Setup Supabase (run once)
bun run setup:supabase

# Deploy to staging
bun run deploy:staging

# Deploy to production
bun run deploy:production

# Deploy only API to staging
bun run deploy:api:staging

# Deploy only API to production
bun run deploy:api:production

# Run database migrations
bun run migrate:staging
bun run migrate:production
```

## Environment Variables Summary

### Required Secrets (set in Cloudflare Workers)

- `DATABASE_URL` - PostgreSQL connection string
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key
- `JWT_SECRET` - JWT signing secret
- `STRIPE_SECRET_KEY` - Stripe secret key (if using payments)

### Public Variables (set in wrangler.toml)

- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `API_URL` - API base URL
- `FRONTEND_URL` - Frontend base URL
- `ENVIRONMENT` - Environment name
- `NODE_ENV` - Node environment

### Frontend Variables (set in Cloudflare Pages)

- `VITE_API_URL` - API base URL
- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Supabase anonymous key
- `VITE_STRIPE_PUBLISHABLE_KEY` - Stripe publishable key
- `VITE_APP_URL` - Application base URL
- `VITE_ENVIRONMENT` - Environment name

## Deployment Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   Cloudflare    │    │    Supabase     │
│     Pages       │    │    Workers      │    │   PostgreSQL    │
│   (Frontend)    │◄──►│     (API)       │◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    React App              Hono.js API              Prisma ORM
    Vite Build             TypeScript               Migrations
    Static Assets          Edge Runtime             Auth Tables
```

## Support and Troubleshooting

If you encounter issues during deployment:

1. Check the deployment logs in Cloudflare Dashboard
2. Verify all environment variables are set correctly
3. Test database connectivity
4. Check CORS configuration
5. Verify Supabase project settings
6. Review the troubleshooting section above

For additional help, refer to:

- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Supabase Documentation](https://supabase.com/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
