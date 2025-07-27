# SaaS Factory Deployment Quick Reference

## 🚀 One-Command Setup

```bash
# Complete setup (recommended)
./scripts/setup-deployment.sh

# GitHub configuration only
./scripts/setup-github.sh

# From environment variables
CLOUDFLARE_API_TOKEN=xxx ./scripts/setup-github.sh --from-env
```

## 📋 Required Tools

```bash
# Install required tools
brew install gh bun git curl  # macOS
choco install gh bun git curl # Windows

# Authenticate
gh auth login
wrangler login
supabase login
```

## 🔐 GitHub Secrets (Automated)

### Quick Setup
```bash
# Interactive setup
./scripts/setup-github.sh

# Batch setup from environment
export CLOUDFLARE_API_TOKEN="your_token"
export STAGING_SUPABASE_URL="https://xxx.supabase.co"
./scripts/setup-github.sh --from-env
```

### Manual Commands
```bash
# Cloudflare
gh secret set CLOUDFLARE_API_TOKEN --body "your_token"
gh secret set CLOUDFLARE_ACCOUNT_ID --body "your_account_id"

# Generate JWT secrets
gh secret set STAGING_JWT_SECRET --body "$(openssl rand -base64 32)"
gh secret set PRODUCTION_JWT_SECRET --body "$(openssl rand -base64 32)"

# Supabase
gh secret set STAGING_SUPABASE_URL --body "https://xxx.supabase.co"
gh secret set STAGING_SUPABASE_ANON_KEY --body "your_anon_key"
gh secret set STAGING_DATABASE_URL --body "postgresql://..."
```

## 🌿 Branch Protection

```bash
# Main branch (production)
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test","build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}'

# Develop branch (staging)
gh api repos/:owner/:repo/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test"]}'
```

## 🌍 Deployment Environments

```bash
# Create staging environment
gh api repos/:owner/:repo/environments/staging --method PUT

# Create production environment with approval
gh api repos/:owner/:repo/environments/production-approval \
  --method PUT \
  --field reviewers='[{"type":"User","id":YOUR_USER_ID}]'
```

## 🚀 Deployment Commands

```bash
# Local deployment
bun run deploy:staging
bun run deploy:production

# Verification
bun run verify:staging
bun run verify:production

# Rollback
bun run rollback:staging "reason"
bun run rollback:production "reason"
```

## 🔍 Health Checks

```bash
# API health
curl https://saas-factory-api-staging.lamtran2601.workers.dev/health
curl https://saas-factory-api-prod.lamtran2601.workers.dev/health

# Frontend
curl https://saas-factory-staging.pages.dev
curl https://saas-factory-production.pages.dev
```

## 📊 Monitoring

```bash
# Worker logs
wrangler tail --name saas-factory-api-staging
wrangler tail --name saas-factory-api-prod

# Deployment status
gh run list --workflow=deploy-staging.yml
gh run list --workflow=deploy-production.yml
```

## 🗄️ Database Operations

```bash
# Manual migration
gh workflow run database-migration.yml \
  -f environment=staging \
  -f migration_type=apply

# Link to Supabase project
supabase link --project-ref your-project-id

# Apply migrations
supabase db push

# Generate types
supabase gen types typescript > types/supabase.ts
```

## 🛠️ Troubleshooting

### Authentication Issues
```bash
# Re-authenticate
gh auth logout && gh auth login
wrangler logout && wrangler login
supabase logout && supabase login
```

### Build Issues
```bash
# Clean and rebuild
bun install --frozen-lockfile
bun run build:api
bun run build:web
```

### Deployment Issues
```bash
# Check configuration
wrangler whoami
gh auth status
supabase projects list

# Verify secrets
gh secret list
```

### Environment Issues
```bash
# Check environment variables
echo $VITE_API_URL
echo $VITE_SUPABASE_URL

# Test local build
VITE_API_URL=http://localhost:8787 bun run build:web
```

## 📚 Documentation Links

- [Complete Setup Guide](./15-cli-deployment-setup.md)
- [GitHub CLI Automation](./18-github-cli-automation.md)
- [CLI-First Deployment Guide](./14-cli-first-deployment-guide.md)
- [Deployment Comparison](./16-deployment-approach-comparison.md)

## 🆘 Emergency Procedures

### Production Rollback
```bash
# Immediate rollback
bun run rollback:production "emergency rollback"

# Manual rollback
git checkout main
git reset --hard HEAD~1
git push --force-with-lease origin main
```

### Service Recovery
```bash
# Redeploy current version
cd apps/api && wrangler deploy --env production
cd apps/web && wrangler pages deploy dist --project-name saas-factory-production

# Check service status
curl -f https://saas-factory-api-prod.lamtran2601.workers.dev/health
```

## 🔄 Workflow Triggers

### Automatic Deployments
- **Staging**: Push to `develop` branch
- **Production**: Push to `main` branch (with approval)

### Manual Deployments
```bash
# Trigger via GitHub CLI
gh workflow run deploy-staging.yml
gh workflow run deploy-production.yml

# Trigger via web interface
# Go to Actions tab → Select workflow → Run workflow
```

## 📈 Performance Optimization

### Build Optimization
```bash
# Analyze bundle size
cd apps/web && bunx vite-bundle-analyzer

# Optimize images
cd apps/web && bunx imagemin src/assets/* --out-dir=dist/assets
```

### Caching
```bash
# Clear Cloudflare cache
curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

## 🔒 Security Checklist

- [ ] All secrets are set in GitHub
- [ ] Branch protection rules are enabled
- [ ] Production environment requires approval
- [ ] JWT secrets are unique per environment
- [ ] Database URLs use strong passwords
- [ ] Stripe keys match environment (test/live)
- [ ] CORS origins are properly configured

## 📊 Success Metrics

### Deployment Success
- ✅ Health checks pass
- ✅ Frontend loads correctly
- ✅ API endpoints respond
- ✅ Database connectivity works
- ✅ Authentication flow functions

### Performance Targets
- API response time: < 500ms
- Frontend load time: < 3s
- Build time: < 2 minutes
- Deployment time: < 5 minutes

---

**💡 Pro Tip**: Bookmark this page for quick access to common commands and procedures!
