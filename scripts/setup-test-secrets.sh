#!/bin/bash

# Test secrets setup for SaaS Factory deployment pipeline testing
# This script sets up minimal secrets for testing the deployment pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "🧪 Setting up test secrets for deployment pipeline testing..."

# Check if GitHub CLI is available and authenticated
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI is not installed"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub"
    exit 1
fi

print_status "🔐 Setting test secrets..."

# Generate test JWT secrets
STAGING_JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "test-staging-jwt-secret-$(date +%s)")
PRODUCTION_JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "test-production-jwt-secret-$(date +%s)")

# Set minimal required secrets for testing
gh secret set CLOUDFLARE_API_TOKEN --body "test-cloudflare-token" || print_warning "Failed to set CLOUDFLARE_API_TOKEN"
gh secret set CLOUDFLARE_ACCOUNT_ID --body "test-account-id" || print_warning "Failed to set CLOUDFLARE_ACCOUNT_ID"

# Supabase test secrets
gh secret set SUPABASE_ACCESS_TOKEN --body "test-supabase-token" || print_warning "Failed to set SUPABASE_ACCESS_TOKEN"
gh secret set STAGING_SUPABASE_PROJECT_ID --body "test-staging-project-id" || print_warning "Failed to set STAGING_SUPABASE_PROJECT_ID"
gh secret set STAGING_SUPABASE_URL --body "https://test-staging.supabase.co" || print_warning "Failed to set STAGING_SUPABASE_URL"
gh secret set STAGING_SUPABASE_ANON_KEY --body "test-staging-anon-key" || print_warning "Failed to set STAGING_SUPABASE_ANON_KEY"
gh secret set STAGING_SUPABASE_SERVICE_ROLE_KEY --body "test-staging-service-key" || print_warning "Failed to set STAGING_SUPABASE_SERVICE_ROLE_KEY"
gh secret set STAGING_DATABASE_URL --body "postgresql://test:test@localhost:5432/test_staging" || print_warning "Failed to set STAGING_DATABASE_URL"

# Production test secrets
gh secret set PRODUCTION_SUPABASE_PROJECT_ID --body "test-production-project-id" || print_warning "Failed to set PRODUCTION_SUPABASE_PROJECT_ID"
gh secret set PRODUCTION_SUPABASE_URL --body "https://test-production.supabase.co" || print_warning "Failed to set PRODUCTION_SUPABASE_URL"
gh secret set PRODUCTION_SUPABASE_ANON_KEY --body "test-production-anon-key" || print_warning "Failed to set PRODUCTION_SUPABASE_ANON_KEY"
gh secret set PRODUCTION_SUPABASE_SERVICE_ROLE_KEY --body "test-production-service-key" || print_warning "Failed to set PRODUCTION_SUPABASE_SERVICE_ROLE_KEY"
gh secret set PRODUCTION_DATABASE_URL --body "postgresql://test:test@localhost:5432/test_production" || print_warning "Failed to set PRODUCTION_DATABASE_URL"

# JWT secrets
gh secret set STAGING_JWT_SECRET --body "$STAGING_JWT_SECRET" || print_warning "Failed to set STAGING_JWT_SECRET"
gh secret set PRODUCTION_JWT_SECRET --body "$PRODUCTION_JWT_SECRET" || print_warning "Failed to set PRODUCTION_JWT_SECRET"

# Optional Stripe test secrets
gh secret set STAGING_STRIPE_SECRET_KEY --body "sk_test_test_key" || print_warning "Failed to set STAGING_STRIPE_SECRET_KEY"
gh secret set STAGING_STRIPE_PUBLISHABLE_KEY --body "pk_test_test_key" || print_warning "Failed to set STAGING_STRIPE_PUBLISHABLE_KEY"
gh secret set STAGING_STRIPE_WEBHOOK_SECRET --body "whsec_test_webhook" || print_warning "Failed to set STAGING_STRIPE_WEBHOOK_SECRET"

gh secret set PRODUCTION_STRIPE_SECRET_KEY --body "sk_live_test_key" || print_warning "Failed to set PRODUCTION_STRIPE_SECRET_KEY"
gh secret set PRODUCTION_STRIPE_PUBLISHABLE_KEY --body "pk_live_test_key" || print_warning "Failed to set PRODUCTION_STRIPE_PUBLISHABLE_KEY"
gh secret set PRODUCTION_STRIPE_WEBHOOK_SECRET --body "whsec_live_webhook" || print_warning "Failed to set PRODUCTION_STRIPE_WEBHOOK_SECRET"

print_success "✅ Test secrets configured"

# Set repository variables
print_status "📝 Setting repository variables..."
gh variable set STAGING_API_URL --body "https://saas-factory-api-staging.lamtran2601.workers.dev" || print_warning "Failed to set STAGING_API_URL"
gh variable set PRODUCTION_API_URL --body "https://saas-factory-api-prod.lamtran2601.workers.dev" || print_warning "Failed to set PRODUCTION_API_URL"
gh variable set STAGING_FRONTEND_URL --body "https://saas-factory-staging.pages.dev" || print_warning "Failed to set STAGING_FRONTEND_URL"
gh variable set PRODUCTION_FRONTEND_URL --body "https://saas-factory-production.pages.dev" || print_warning "Failed to set PRODUCTION_FRONTEND_URL"

print_success "✅ Repository variables configured"

print_status "🌍 Setting up deployment environments..."

# Create staging environment
gh api repos/:owner/:repo/environments/staging --method PUT > /dev/null 2>&1 || print_warning "Failed to create staging environment"

# Get user ID for production environment
USER_ID=$(gh api user --jq '.id' 2>/dev/null || echo "12345")

# Create production-approval environment
gh api repos/:owner/:repo/environments/production-approval \
    --method PUT \
    --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
    --field reviewers="[{\"type\":\"User\",\"id\":$USER_ID}]" > /dev/null 2>&1 || print_warning "Failed to create production-approval environment"

print_success "✅ Deployment environments configured"

# Verify configuration
print_status "🔍 Verifying configuration..."
SECRET_COUNT=$(gh secret list --json name | jq length 2>/dev/null || echo "0")
VARIABLE_COUNT=$(gh variable list --json name | jq length 2>/dev/null || echo "0")

print_success "✅ Configuration complete!"
print_status "   Secrets: $SECRET_COUNT configured"
print_status "   Variables: $VARIABLE_COUNT configured"
print_status ""
print_warning "⚠️  Note: These are test secrets for pipeline testing only"
print_warning "⚠️  Replace with real secrets for actual deployment"
print_status ""
print_success "🚀 Ready to test deployment pipeline!"
