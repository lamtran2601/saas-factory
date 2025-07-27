# SaaS Factory Deployment Quick Start

## 🚀 One-Command Deployment Setup

This guide gets you from zero to deployed in under 30 minutes using our CLI-first deployment approach.

## Prerequisites

- GitHub repository with admin access
- Cloudflare account
- Supabase account
- Local development environment

## Quick Setup

### 1. Run the Setup Script

```bash
# From your project root
./scripts/setup-deployment.sh
```

This script will:
- ✅ Check and install required tools
- ✅ Authenticate with Cloudflare and Supabase
- ✅ Test your build process
- ✅ Verify project configuration

### 2. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

**Required Secrets:**
```bash
# Cloudflare
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
CLOUDFLARE_ACCOUNT_ID=your_account_id

# Supabase
SUPABASE_ACCESS_TOKEN=your_supabase_access_token
STAGING_SUPABASE_PROJECT_ID=your_staging_project_id
STAGING_SUPABASE_URL=https://your-staging-project.supabase.co
STAGING_SUPABASE_ANON_KEY=your_staging_anon_key
STAGING_SUPABASE_SERVICE_ROLE_KEY=your_staging_service_key
STAGING_DATABASE_URL=postgresql://postgres:password@host:port/db

PRODUCTION_SUPABASE_PROJECT_ID=your_production_project_id
PRODUCTION_SUPABASE_URL=https://your-production-project.supabase.co
PRODUCTION_SUPABASE_ANON_KEY=your_production_anon_key
PRODUCTION_SUPABASE_SERVICE_ROLE_KEY=your_production_service_key
PRODUCTION_DATABASE_URL=postgresql://postgres:password@host:port/db

# Application Secrets
STAGING_JWT_SECRET=your_staging_jwt_secret
PRODUCTION_JWT_SECRET=your_production_jwt_secret
```

### 3. Test Deployment

```bash
# Test staging deployment
git checkout develop
git push origin develop

# Test production deployment
git checkout main
git merge develop
git push origin main
```

## Available Commands

### Deployment Commands
```bash
# Deploy to staging
bun run deploy:staging

# Deploy to production
bun run deploy:production

# Setup deployment pipeline
bun run setup:deployment
```

### Verification Commands
```bash
# Verify staging deployment
bun run verify:staging

# Verify production deployment
bun run verify:production
```

### Rollback Commands
```bash
# Rollback staging
bun run rollback:staging "reason for rollback"

# Rollback production
bun run rollback:production "reason for rollback"
```

### Build Commands
```bash
# Build API
bun run build:api

# Build frontend
bun run build:web

# Build everything
bun run build
```

## Deployment Flow

### Staging Deployment (Automatic)
1. Push to `develop` branch
2. GitHub Actions triggers automatically
3. Runs tests and builds
4. Deploys to staging environment
5. Runs verification tests

### Production Deployment (Manual Approval)
1. Create PR from `develop` to `main`
2. Merge PR after review
3. GitHub Actions triggers with manual approval step
4. Approve deployment in GitHub Actions
5. Deploys to production environment
6. Runs comprehensive verification

## Environment URLs

### Staging
- **Frontend**: https://saas-factory-staging.pages.dev
- **API**: https://saas-factory-api-staging.lamtran2601.workers.dev
- **Health Check**: https://saas-factory-api-staging.lamtran2601.workers.dev/health

### Production
- **Frontend**: https://saas-factory-production.pages.dev
- **API**: https://saas-factory-api-prod.lamtran2601.workers.dev
- **Health Check**: https://saas-factory-api-prod.lamtran2601.workers.dev/health

## Database Migrations

### Manual Migration
```bash
# Go to GitHub repository
# Actions → Database Migration → Run workflow
# Select environment and migration type
```

### Automatic Migration
Database migrations run automatically during deployment workflows.

## Monitoring

### Health Checks
```bash
# Check staging health
curl https://saas-factory-api-staging.lamtran2601.workers.dev/health

# Check production health
curl https://saas-factory-api-prod.lamtran2601.workers.dev/health
```

### Logs
```bash
# View Worker logs
wrangler tail --name saas-factory-api-staging
wrangler tail --name saas-factory-api-prod

# View deployment logs
# Go to GitHub Actions tab in your repository
```

## Troubleshooting

### Common Issues

**1. Authentication Failures**
```bash
# Re-authenticate with Cloudflare
wrangler login

# Re-authenticate with Supabase
supabase login
```

**2. Build Failures**
```bash
# Check environment variables
echo $VITE_API_URL
echo $VITE_SUPABASE_URL

# Test local build
bun run build:api
bun run build:web
```

**3. Deployment Failures**
```bash
# Check Cloudflare account limits
wrangler whoami

# Verify project configuration
cat wrangler.toml
```

**4. Database Issues**
```bash
# Check Supabase connection
supabase projects list

# Test database connectivity
supabase db ping --project-ref your-project-id
```

### Debug Commands
```bash
# Test deployment verification
./scripts/deploy/verify-deployment.sh staging

# Check deployment status
curl -s https://saas-factory-api-staging.lamtran2601.workers.dev/api | jq

# View recent deployments
wrangler deployments list --name saas-factory-api-staging
```

## Security Best Practices

1. **Secrets Management**
   - Never commit secrets to git
   - Use different secrets for staging/production
   - Rotate secrets regularly

2. **Access Control**
   - Enable branch protection rules
   - Require code reviews
   - Use manual approval for production

3. **Monitoring**
   - Monitor deployment logs
   - Set up error tracking
   - Review access patterns

## Next Steps

1. **Custom Domains** (Optional)
   - Configure custom domains in Cloudflare
   - Update environment variables
   - Set up SSL certificates

2. **Monitoring & Alerting**
   - Set up Sentry for error tracking
   - Configure Slack notifications
   - Implement uptime monitoring

3. **Performance Optimization**
   - Enable Cloudflare caching
   - Optimize bundle sizes
   - Set up performance monitoring

## Support

### Documentation
- 📖 [Complete Setup Guide](./15-cli-deployment-setup.md)
- 🔄 [CLI-First Deployment Guide](./14-cli-first-deployment-guide.md)
- ⚖️ [Deployment Approach Comparison](./16-deployment-approach-comparison.md)

### Getting Help
- Check GitHub Actions logs for deployment issues
- Review Cloudflare Workers logs for runtime issues
- Check Supabase dashboard for database issues

### Emergency Procedures
```bash
# Emergency production rollback
bun run rollback:production "emergency rollback"

# Emergency staging rollback
bun run rollback:staging "emergency rollback"
```

---

**🎉 Congratulations!** You now have a fully automated, production-ready deployment pipeline for your SaaS Factory application!
