# CLI-First Deployment Setup Guide

## Overview

This guide walks you through setting up the CLI-first deployment solution for SaaS Factory using
GitHub Actions, Supabase CLI, and Wrangler CLI.

## Prerequisites

Before starting, ensure you have:

- GitHub repository with admin access
- Cloudflare account with Workers and Pages access
- Supabase account
- Local development environment set up
- GitHub CLI (gh) installed and authenticated (recommended for automated setup)

## Step 1: GitHub CLI Setup (Recommended)

### 1.1 Install GitHub CLI

```bash
# macOS (using Homebrew)
brew install gh

# Windows (using Chocolatey)
choco install gh

# Linux (Ubuntu/Debian)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Or download from https://github.com/cli/cli/releases
```

### 1.2 Authenticate with GitHub

```bash
# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status

# Set git protocol to HTTPS (recommended)
gh config set git_protocol https
```

### 1.3 Automated Repository Setup

Use our automated setup script (recommended):

```bash
# Run the GitHub configuration script
./scripts/setup-github.sh
```

Or follow the manual steps below.

## Step 2: Manual GitHub Repository Setup (Alternative)

### 2.1 Enable GitHub Actions

**Automated (GitHub CLI):**

```bash
# Enable GitHub Actions (if not already enabled)
gh api repos/:owner/:repo --method PATCH --field has_actions=true
```

**Manual:**

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **General**
3. Ensure "Allow all actions and reusable workflows" is selected
4. Save the settings

### 2.2 Set Up Branch Protection

**Automated (GitHub CLI):**

```bash
# Set up branch protection for main
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test","build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null

# Set up branch protection for develop
gh api repos/:owner/:repo/branches/develop/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews=null \
  --field restrictions=null
```

**Manual:**

1. Go to **Settings** → **Branches**
2. Add branch protection rule for `main`:
   - Require pull request reviews before merging
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Include administrators
3. Add branch protection rule for `develop`:
   - Require status checks to pass before merging

### 2.3 Create Environment Protection Rules

**Automated (GitHub CLI):**

```bash
# Create production-approval environment
gh api repos/:owner/:repo/environments/production-approval \
  --method PUT \
  --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
  --field reviewers='[{"type":"User","id":YOUR_USER_ID}]'

# Create staging environment
gh api repos/:owner/:repo/environments/staging --method PUT
```

**Manual:**

1. Go to **Settings** → **Environments**
2. Create `production-approval` environment:
   - Add required reviewers (team leads/admins)
   - Set deployment branch rule to `main` only
3. Create `staging` environment:
   - No protection rules needed

## Step 2: Cloudflare Setup

### 2.1 Get Cloudflare API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Custom token" template
4. Set permissions:
   - **Account**: `Cloudflare Workers:Edit`
   - **Zone**: `Zone:Read` (if using custom domain)
   - **Zone**: `Page Rules:Edit` (if using custom domain)
5. Set account resources: Include your account
6. Set zone resources: Include your domain (if applicable)
7. Copy the token securely

### 2.2 Get Account ID

1. Go to Cloudflare Dashboard
2. Select your account
3. Copy the Account ID from the right sidebar

## Step 3: Supabase Setup

### 3.1 Install Supabase CLI

```bash
# Using Bun (recommended)
bun add -g supabase

# Or using npm
npm install -g supabase

# Verify installation
supabase --version
```

### 3.2 Create Supabase Projects

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create staging project:
   - Name: `saas-factory-staging`
   - Region: Choose closest to your users
   - Database password: Generate strong password
3. Create production project:
   - Name: `saas-factory-production`
   - Region: Same as staging
   - Database password: Generate strong password

### 3.3 Get Supabase Credentials

For each project, collect:

1. **Project URL**: `https://your-project-id.supabase.co`
2. **Anon Key**: From Settings → API
3. **Service Role Key**: From Settings → API (keep secret!)
4. **Database URL**: From Settings → Database
5. **Project ID**: From project URL or settings

### 3.4 Get Supabase Access Token

1. Go to [Supabase Access Tokens](https://supabase.com/dashboard/account/tokens)
2. Generate new token with appropriate permissions
3. Copy the token securely

## Step 5: Configure GitHub Secrets

### 5.1 Automated Setup (Recommended)

Use the GitHub configuration script to set all secrets automatically:

```bash
# Run the interactive GitHub setup script
./scripts/setup-github.sh

# Or set secrets from environment variables
CLOUDFLARE_API_TOKEN=your_token \
CLOUDFLARE_ACCOUNT_ID=your_account_id \
STAGING_SUPABASE_URL=your_staging_url \
./scripts/setup-github.sh --from-env
```

### 5.2 Manual Setup (Alternative)

**Using GitHub CLI:**

```bash
# Cloudflare secrets
gh secret set CLOUDFLARE_API_TOKEN --body "your_cloudflare_api_token"
gh secret set CLOUDFLARE_ACCOUNT_ID --body "your_cloudflare_account_id"

# Supabase secrets
gh secret set SUPABASE_ACCESS_TOKEN --body "your_supabase_access_token"
gh secret set STAGING_SUPABASE_PROJECT_ID --body "your_staging_project_id"
gh secret set STAGING_SUPABASE_URL --body "https://your-staging-project.supabase.co"
gh secret set STAGING_SUPABASE_ANON_KEY --body "your_staging_anon_key"
gh secret set STAGING_SUPABASE_SERVICE_ROLE_KEY --body "your_staging_service_key"
gh secret set STAGING_DATABASE_URL --body "postgresql://postgres:password@host:port/db"

# Production secrets
gh secret set PRODUCTION_SUPABASE_PROJECT_ID --body "your_production_project_id"
gh secret set PRODUCTION_SUPABASE_URL --body "https://your-production-project.supabase.co"
gh secret set PRODUCTION_SUPABASE_ANON_KEY --body "your_production_anon_key"
gh secret set PRODUCTION_SUPABASE_SERVICE_ROLE_KEY --body "your_production_service_key"
gh secret set PRODUCTION_DATABASE_URL --body "postgresql://postgres:password@host:port/db"

# Application secrets
gh secret set STAGING_JWT_SECRET --body "$(openssl rand -base64 32)"
gh secret set PRODUCTION_JWT_SECRET --body "$(openssl rand -base64 32)"
gh secret set STAGING_STRIPE_SECRET_KEY --body "sk_test_your_stripe_test_key"
gh secret set PRODUCTION_STRIPE_SECRET_KEY --body "sk_live_your_stripe_live_key"
```

**Using Web Interface:**

Go to **Settings** → **Secrets and variables** → **Actions** and add:

### 5.3 Required Secrets

#### Cloudflare Secrets

```
CLOUDFLARE_API_TOKEN          # Your Cloudflare API token
CLOUDFLARE_ACCOUNT_ID         # Your Cloudflare account ID
```

#### Supabase Secrets

```
SUPABASE_ACCESS_TOKEN         # Supabase CLI access token

# Staging Environment
STAGING_SUPABASE_PROJECT_ID   # Staging project ID
STAGING_SUPABASE_URL          # https://staging-project-id.supabase.co
STAGING_SUPABASE_ANON_KEY     # Staging anon key
STAGING_SUPABASE_SERVICE_ROLE_KEY # Staging service role key (secret!)
STAGING_DATABASE_URL          # Full staging database connection string

# Production Environment
PRODUCTION_SUPABASE_PROJECT_ID # Production project ID
PRODUCTION_SUPABASE_URL        # https://production-project-id.supabase.co
PRODUCTION_SUPABASE_ANON_KEY   # Production anon key
PRODUCTION_SUPABASE_SERVICE_ROLE_KEY # Production service role key (secret!)
PRODUCTION_DATABASE_URL        # Full production database connection string
```

#### Application Secrets

```
# Staging Secrets
STAGING_JWT_SECRET            # Random 32+ character string
STAGING_STRIPE_SECRET_KEY     # Stripe test secret key (sk_test_...)
STAGING_STRIPE_PUBLISHABLE_KEY # Stripe test publishable key (pk_test_...)
STAGING_STRIPE_WEBHOOK_SECRET # Stripe test webhook secret

# Production Secrets
PRODUCTION_JWT_SECRET         # Random 32+ character string (different from staging)
PRODUCTION_STRIPE_SECRET_KEY  # Stripe live secret key (sk_live_...)
PRODUCTION_STRIPE_PUBLISHABLE_KEY # Stripe live publishable key (pk_live_...)
PRODUCTION_STRIPE_WEBHOOK_SECRET # Stripe live webhook secret
```

#### Optional Secrets

```
SLACK_WEBHOOK_URL            # For deployment notifications
CODECOV_TOKEN               # For code coverage reports
SNYK_TOKEN                  # For security scanning
```

### 4.2 Secret Generation Commands

Use these commands to generate secure secrets:

```bash
# Generate JWT secrets
openssl rand -base64 32

# Generate random strings
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Or using Bun
bun -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Step 5: Local Development Setup

### 5.1 Install Required Tools

```bash
# Install Bun (if not already installed)
curl -fsSL https://bun.sh/install | bash

# Install Wrangler CLI
bun add -g wrangler

# Install Supabase CLI
bun add -g supabase

# Verify installations
bun --version
wrangler --version
supabase --version
```

### 5.2 Authenticate with Services

```bash
# Authenticate with Cloudflare
wrangler login

# Authenticate with Supabase
supabase login

# Verify authentication
wrangler whoami
supabase projects list
```

### 5.3 Link Local Project to Supabase

```bash
# Initialize Supabase in your project (if not already done)
supabase init

# Link to staging project
supabase link --project-ref your-staging-project-id

# Or link to production project
supabase link --project-ref your-production-project-id
```

## Step 6: Test the Deployment Pipeline

### 6.1 Test Staging Deployment

1. Create a feature branch:

   ```bash
   git checkout -b test-deployment
   ```

2. Make a small change and commit:

   ```bash
   echo "# Test" >> README.md
   git add README.md
   git commit -m "test: deployment pipeline"
   ```

3. Push to develop branch:

   ```bash
   git checkout develop
   git merge test-deployment
   git push origin develop
   ```

4. Check GitHub Actions tab for deployment progress

### 6.2 Test Production Deployment

1. Create a pull request from `develop` to `main`
2. Merge the pull request
3. Check GitHub Actions for production deployment
4. Approve the deployment when prompted

### 6.3 Verify Deployments

```bash
# Test staging
curl https://saas-factory-api-staging.lamtran2601.workers.dev/health
curl https://saas-factory-staging.pages.dev

# Test production
curl https://saas-factory-api-prod.lamtran2601.workers.dev/health
curl https://saas-factory-production.pages.dev
```

## Step 7: Database Migration Setup

### 7.1 Create Initial Migration

```bash
cd apps/api
supabase migration new initial_schema
```

### 7.2 Test Migration Workflow

1. Go to GitHub repository
2. Navigate to **Actions** tab
3. Click "Database Migration" workflow
4. Click "Run workflow"
5. Select environment and migration type
6. Run the workflow

## Step 8: Monitoring and Maintenance

### 8.1 Set Up Monitoring

1. **Cloudflare Analytics**: Enable in Workers and Pages dashboards
2. **Supabase Monitoring**: Monitor database performance
3. **GitHub Actions**: Set up notification preferences

### 8.2 Regular Maintenance Tasks

- Review and rotate secrets quarterly
- Update dependencies monthly
- Monitor deployment success rates
- Review and update branch protection rules

## Troubleshooting

### Common Issues

1. **Authentication Failures**:
   - Verify API tokens are correct and not expired
   - Check token permissions

2. **Build Failures**:
   - Check environment variables are set correctly
   - Verify dependencies are up to date

3. **Deployment Failures**:
   - Check Cloudflare account limits
   - Verify project names and configurations

4. **Database Migration Failures**:
   - Check database connectivity
   - Verify migration syntax

### Debug Commands

```bash
# Check Wrangler configuration
wrangler whoami

# Test Supabase connection
supabase projects list

# View deployment logs
wrangler tail --name saas-factory-api-staging

# Test local build
cd apps/web && bun run build
cd apps/api && bun run build
```

## Security Best Practices

1. **Secrets Management**:
   - Never commit secrets to version control
   - Rotate secrets regularly
   - Use different secrets for each environment

2. **Access Control**:
   - Limit GitHub repository access
   - Use branch protection rules
   - Require code reviews

3. **Monitoring**:
   - Monitor deployment logs
   - Set up error tracking
   - Review access logs regularly

## Related Documentation

- **[GitHub CLI Automation Guide](./18-github-cli-automation.md)** - Detailed GitHub CLI usage and
  automation
- **[Deployment Quick Reference](./19-deployment-quick-reference.md)** - Commands and
  troubleshooting cheat sheet
- **[CLI-First Deployment Guide](./14-cli-first-deployment-guide.md)** - Architecture and approach
  overview
- **[Deployment Approach Comparison](./16-deployment-approach-comparison.md)** - CLI-first vs
  Terraform comparison

## Next Steps

1. ✅ **Run automated setup**: `./scripts/setup-deployment.sh`
2. ✅ **Configure GitHub**: `./scripts/setup-github.sh` (recommended)
3. 🔄 **Test deployment pipeline** with staging environment
4. 📊 **Monitor deployments** and verify functionality
5. 📚 **Document team procedures** and runbooks
6. 🔔 **Set up monitoring and alerting**
7. 👥 **Train team** on deployment procedures

## Quick Start Summary

```bash
# 1. Complete setup (5 minutes)
./scripts/setup-deployment.sh

# 2. Test staging deployment
git checkout develop
git push origin develop

# 3. Test production deployment
git checkout main
git merge develop
git push origin main
```

This completes the CLI-first deployment setup for your SaaS Factory application with full GitHub CLI
automation!
