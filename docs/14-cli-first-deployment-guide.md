# CLI-First Deployment Guide for SaaS Factory

## Overview

This guide implements a deployment solution using official CLI tools and GitHub Actions, eliminating the complexity of Infrastructure as Code while maintaining automation and reliability.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │    │  GitHub Actions │    │   Supabase CLI  │
│                 │───►│                 │───►│                 │
│ - Source Code   │    │ - Build & Test  │    │ - DB Migrations │
│ - Workflows     │    │ - Deploy        │    │ - Type Gen      │
│ - Secrets       │    │ - Verify        │    │ - Project Mgmt  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Wrangler CLI   │    │   Cloudflare    │
                       │                 │───►│                 │
                       │ - Workers Deploy│    │ - Workers       │
                       │ - Pages Deploy  │    │ - Pages         │
                       │ - Secrets Mgmt  │    │ - DNS & CDN     │
                       └─────────────────┘    └─────────────────┘
```

## Benefits of CLI-First Approach

### ✅ Advantages

1. **Simplicity**: Uses official tools with native features
2. **No State Management**: No Terraform state files to manage
3. **Official Support**: Direct support from Cloudflare and Supabase teams
4. **Rapid Development**: Faster iteration and debugging
5. **Lower Learning Curve**: Familiar tools for most developers
6. **Built-in Features**: Leverages platform-native capabilities
7. **Cost Effective**: No additional infrastructure or tooling costs

### ⚠️ Considerations

1. **Limited Infrastructure Drift Detection**: Manual verification needed
2. **Less Declarative**: More imperative deployment scripts
3. **Platform Lock-in**: Tied to specific CLI tools and platforms
4. **Manual Coordination**: Requires careful orchestration in workflows

## Deployment Strategy

### Environment Management

- **Development**: Local development with Docker Compose
- **Staging**: Automated deployment on `develop` branch push
- **Production**: Automated deployment on `main` branch push with manual approval

### Branch Strategy

```
main (production)     ←── Pull Request ←── develop (staging)
  │                                           │
  ├── Auto-deploy to production               ├── Auto-deploy to staging
  ├── Manual approval required                ├── Automatic on push
  └── Full test suite                         └── Full test suite
```

### Deployment Flow

1. **Code Push** → Trigger GitHub Actions
2. **Build & Test** → Run linting, type checking, unit tests
3. **Database Migration** → Apply schema changes via Supabase CLI
4. **API Deployment** → Deploy Workers via Wrangler CLI
5. **Frontend Deployment** → Deploy Pages via Wrangler CLI
6. **Verification** → Health checks and smoke tests
7. **Notification** → Slack/Discord deployment status

## Required GitHub Secrets

### Cloudflare Secrets
```
CLOUDFLARE_API_TOKEN          # Cloudflare API token with Workers and Pages permissions
CLOUDFLARE_ACCOUNT_ID         # Cloudflare account ID
```

### Supabase Secrets
```
# Staging Environment
SUPABASE_ACCESS_TOKEN         # Supabase CLI access token
STAGING_SUPABASE_PROJECT_ID   # Staging project ID
STAGING_SUPABASE_DB_PASSWORD  # Staging database password
STAGING_DATABASE_URL          # Full staging database connection string

# Production Environment
PRODUCTION_SUPABASE_PROJECT_ID # Production project ID
PRODUCTION_SUPABASE_DB_PASSWORD # Production database password
PRODUCTION_DATABASE_URL        # Full production database connection string
```

### Application Secrets
```
# Staging Secrets
STAGING_JWT_SECRET            # JWT signing secret for staging
STAGING_STRIPE_SECRET_KEY     # Stripe test secret key
STAGING_STRIPE_WEBHOOK_SECRET # Stripe test webhook secret

# Production Secrets
PRODUCTION_JWT_SECRET         # JWT signing secret for production
PRODUCTION_STRIPE_SECRET_KEY  # Stripe live secret key
PRODUCTION_STRIPE_WEBHOOK_SECRET # Stripe live webhook secret
```

### Optional Secrets
```
SLACK_WEBHOOK_URL            # For deployment notifications
SENTRY_AUTH_TOKEN           # For error tracking setup
DISCORD_WEBHOOK_URL         # Alternative notification channel
```

## File Structure

```
.github/
├── workflows/
│   ├── deploy-staging.yml      # Staging deployment workflow
│   ├── deploy-production.yml   # Production deployment workflow
│   ├── test.yml               # Test and validation workflow
│   └── database-migration.yml # Database migration workflow
├── actions/
│   ├── setup-node/           # Custom action for Node.js setup
│   ├── setup-supabase/       # Custom action for Supabase CLI
│   └── setup-wrangler/       # Custom action for Wrangler CLI
└── templates/
    ├── deployment-summary.md  # Deployment summary template
    └── rollback-guide.md     # Rollback procedure template

scripts/
├── deploy/
│   ├── deploy-staging.sh     # Staging deployment script
│   ├── deploy-production.sh  # Production deployment script
│   ├── verify-deployment.sh  # Deployment verification
│   └── rollback.sh          # Rollback script
├── database/
│   ├── migrate.sh           # Database migration script
│   ├── seed-staging.sh      # Staging data seeding
│   └── backup.sh           # Database backup script
└── utils/
    ├── health-check.sh      # Health check utilities
    ├── notify.sh           # Notification utilities
    └── cleanup.sh          # Cleanup utilities

supabase/
├── config.toml             # Supabase CLI configuration
├── migrations/             # Database migrations
├── seed.sql               # Seed data
└── functions/             # Edge functions (if used)

wrangler.toml              # Wrangler configuration
```

## Deployment Verification

### Automated Checks

1. **Health Endpoints**: Verify API health endpoints respond correctly
2. **Database Connectivity**: Test database connections and basic queries
3. **Authentication Flow**: Verify Supabase Auth integration
4. **Frontend Loading**: Check frontend loads and connects to API
5. **Environment Variables**: Validate all required environment variables

### Manual Verification Steps

1. **User Registration**: Test new user signup flow
2. **Login Process**: Verify existing user login
3. **API Endpoints**: Test key API functionality
4. **File Uploads**: Verify file upload functionality (if enabled)
5. **Payment Flow**: Test Stripe integration (if enabled)

## Rollback Procedures

### Automatic Rollback Triggers

- Health check failures after deployment
- Critical error rate increase
- Database migration failures
- Frontend build failures

### Manual Rollback Process

1. **Identify Issue**: Determine the scope and impact
2. **Rollback Workers**: Use Wrangler to deploy previous version
3. **Rollback Pages**: Deploy previous frontend build
4. **Database Rollback**: Use Supabase migration rollback (if needed)
5. **Verify Rollback**: Run health checks and verification
6. **Notify Team**: Send rollback notification

### Rollback Commands

```bash
# Rollback API Worker
wrangler rollback --name saas-factory-api-prod

# Rollback Frontend (redeploy previous commit)
git checkout <previous-commit>
wrangler pages deploy apps/web/dist --project-name saas-factory-production

# Rollback Database Migration
supabase db reset --project-ref <project-id>
```

## Monitoring and Alerting

### Built-in Monitoring

1. **Cloudflare Analytics**: Worker and Pages performance metrics
2. **Supabase Dashboard**: Database performance and usage
3. **GitHub Actions**: Deployment success/failure notifications
4. **Wrangler Tail**: Real-time log streaming for debugging

### Custom Monitoring Setup

1. **Health Check Endpoints**: Implement comprehensive health checks
2. **Error Tracking**: Integrate Sentry or similar service
3. **Performance Monitoring**: Set up APM for critical paths
4. **Uptime Monitoring**: External uptime monitoring service

## Comparison: CLI-First vs Terraform

| Aspect | CLI-First | Terraform |
|--------|-----------|-----------|
| **Setup Complexity** | Low | Medium-High |
| **Learning Curve** | Low | Medium |
| **State Management** | None | Required |
| **Drift Detection** | Manual | Automatic |
| **Platform Features** | Full Access | Limited by Provider |
| **Debugging** | Easy | Complex |
| **Team Onboarding** | Fast | Slow |
| **Infrastructure Scale** | Small-Medium | Large |
| **Maintenance** | Low | Medium |
| **Cost** | Free | Terraform Cloud costs |

## When to Use Each Approach

### Use CLI-First When:
- Small to medium-sized applications
- Team prefers simplicity over sophistication
- Rapid development and iteration needed
- Limited infrastructure complexity
- Strong platform-specific features required

### Use Terraform When:
- Large, complex infrastructure
- Multi-cloud deployments
- Strict compliance requirements
- Large teams with dedicated DevOps
- Infrastructure drift detection critical

## Next Steps

1. Set up GitHub repository secrets
2. Configure Supabase CLI and create projects
3. Set up Wrangler CLI with Cloudflare account
4. Implement GitHub Actions workflows
5. Test deployment pipeline with staging environment
6. Document team procedures and runbooks
7. Set up monitoring and alerting
8. Train team on deployment procedures
