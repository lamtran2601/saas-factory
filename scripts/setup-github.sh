#!/bin/bash

# SaaS Factory GitHub Configuration Script
# This script automates the setup of GitHub repository settings, secrets, and environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_header() {
    echo ""
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
    echo ""
}

# Check if running from environment variables
FROM_ENV=false
if [ "$1" = "--from-env" ]; then
    FROM_ENV=true
fi

print_header "SaaS Factory GitHub Configuration"

print_status "This script will configure your GitHub repository with:"
print_status "- Repository secrets for Cloudflare, Supabase, and application"
print_status "- Branch protection rules for main and develop branches"
print_status "- Deployment environments with protection rules"
print_status "- Repository variables for non-sensitive configuration"
print_status ""

# Check prerequisites
print_status "🔍 Checking prerequisites..."

if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed"
    print_status "Please install GitHub CLI first:"
    print_status "  macOS: brew install gh"
    print_status "  Windows: choco install gh"
    print_status "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    exit 1
fi

# Check GitHub authentication
if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub"
    print_status "Please authenticate first: gh auth login"
    exit 1
fi

# Get repository information
REPO_OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO_NAME=$(gh repo view --json name --jq '.name')
USER_ID=$(gh api user --jq '.id')

print_success "Authenticated as $(gh api user --jq '.login')"
print_success "Repository: $REPO_OWNER/$REPO_NAME"

# Function to prompt for secret or get from environment
get_secret() {
    local var_name="$1"
    local prompt="$2"
    local is_sensitive="${3:-true}"
    
    if [ "$FROM_ENV" = "true" ]; then
        local value="${!var_name}"
        if [ -z "$value" ]; then
            print_error "Environment variable $var_name is not set"
            exit 1
        fi
        echo "$value"
    else
        if [ "$is_sensitive" = "true" ]; then
            read -s -p "$prompt: " value
            echo ""
        else
            read -p "$prompt: " value
        fi
        echo "$value"
    fi
}

# Function to generate random secret
generate_secret() {
    openssl rand -base64 32 2>/dev/null || node -e "console.log(require('crypto').randomBytes(32).toString('base64'))" 2>/dev/null || echo "CHANGE_THIS_$(date +%s)"
}

print_header "Step 1: Cloudflare Configuration"

if [ "$FROM_ENV" = "false" ]; then
    print_status "You'll need your Cloudflare API token and Account ID"
    print_status "Get these from: https://dash.cloudflare.com/profile/api-tokens"
    print_status ""
fi

CLOUDFLARE_API_TOKEN=$(get_secret "CLOUDFLARE_API_TOKEN" "Cloudflare API Token")
CLOUDFLARE_ACCOUNT_ID=$(get_secret "CLOUDFLARE_ACCOUNT_ID" "Cloudflare Account ID")

print_header "Step 2: Supabase Configuration"

if [ "$FROM_ENV" = "false" ]; then
    print_status "You'll need Supabase project details for staging and production"
    print_status "Get these from: https://supabase.com/dashboard"
    print_status ""
fi

# Supabase Access Token
SUPABASE_ACCESS_TOKEN=$(get_secret "SUPABASE_ACCESS_TOKEN" "Supabase Access Token")

# Staging Supabase Configuration
print_status "📋 Staging Supabase Configuration:"
STAGING_SUPABASE_PROJECT_ID=$(get_secret "STAGING_SUPABASE_PROJECT_ID" "Staging Project ID" false)
STAGING_SUPABASE_URL=$(get_secret "STAGING_SUPABASE_URL" "Staging Project URL (https://xxx.supabase.co)" false)
STAGING_SUPABASE_ANON_KEY=$(get_secret "STAGING_SUPABASE_ANON_KEY" "Staging Anon Key")
STAGING_SUPABASE_SERVICE_ROLE_KEY=$(get_secret "STAGING_SUPABASE_SERVICE_ROLE_KEY" "Staging Service Role Key")
STAGING_DATABASE_URL=$(get_secret "STAGING_DATABASE_URL" "Staging Database URL")

# Production Supabase Configuration
print_status "📋 Production Supabase Configuration:"
PRODUCTION_SUPABASE_PROJECT_ID=$(get_secret "PRODUCTION_SUPABASE_PROJECT_ID" "Production Project ID" false)
PRODUCTION_SUPABASE_URL=$(get_secret "PRODUCTION_SUPABASE_URL" "Production Project URL (https://xxx.supabase.co)" false)
PRODUCTION_SUPABASE_ANON_KEY=$(get_secret "PRODUCTION_SUPABASE_ANON_KEY" "Production Anon Key")
PRODUCTION_SUPABASE_SERVICE_ROLE_KEY=$(get_secret "PRODUCTION_SUPABASE_SERVICE_ROLE_KEY" "Production Service Role Key")
PRODUCTION_DATABASE_URL=$(get_secret "PRODUCTION_DATABASE_URL" "Production Database URL")

print_header "Step 3: Application Secrets"

# Generate JWT secrets if not provided
if [ "$FROM_ENV" = "true" ] && [ -n "$STAGING_JWT_SECRET" ]; then
    STAGING_JWT_SECRET="$STAGING_JWT_SECRET"
else
    if [ "$FROM_ENV" = "false" ]; then
        read -p "Generate random JWT secrets? (y/n): " generate_jwt
        if [ "$generate_jwt" = "y" ] || [ "$generate_jwt" = "Y" ]; then
            STAGING_JWT_SECRET=$(generate_secret)
            PRODUCTION_JWT_SECRET=$(generate_secret)
        else
            STAGING_JWT_SECRET=$(get_secret "STAGING_JWT_SECRET" "Staging JWT Secret")
            PRODUCTION_JWT_SECRET=$(get_secret "PRODUCTION_JWT_SECRET" "Production JWT Secret")
        fi
    else
        STAGING_JWT_SECRET=$(generate_secret)
        PRODUCTION_JWT_SECRET=$(generate_secret)
    fi
fi

# Stripe Configuration (optional)
if [ "$FROM_ENV" = "false" ]; then
    read -p "Configure Stripe integration? (y/n): " setup_stripe
else
    setup_stripe="y"
fi

if [ "$setup_stripe" = "y" ] || [ "$setup_stripe" = "Y" ]; then
    STAGING_STRIPE_SECRET_KEY=$(get_secret "STAGING_STRIPE_SECRET_KEY" "Staging Stripe Secret Key (sk_test_...)" true)
    STAGING_STRIPE_PUBLISHABLE_KEY=$(get_secret "STAGING_STRIPE_PUBLISHABLE_KEY" "Staging Stripe Publishable Key (pk_test_...)" false)
    STAGING_STRIPE_WEBHOOK_SECRET=$(get_secret "STAGING_STRIPE_WEBHOOK_SECRET" "Staging Stripe Webhook Secret" true)
    
    PRODUCTION_STRIPE_SECRET_KEY=$(get_secret "PRODUCTION_STRIPE_SECRET_KEY" "Production Stripe Secret Key (sk_live_...)" true)
    PRODUCTION_STRIPE_PUBLISHABLE_KEY=$(get_secret "PRODUCTION_STRIPE_PUBLISHABLE_KEY" "Production Stripe Publishable Key (pk_live_...)" false)
    PRODUCTION_STRIPE_WEBHOOK_SECRET=$(get_secret "PRODUCTION_STRIPE_WEBHOOK_SECRET" "Production Stripe Webhook Secret" true)
fi

print_header "Step 4: Setting GitHub Secrets"

print_status "🔐 Setting repository secrets..."

# Cloudflare secrets
gh secret set CLOUDFLARE_API_TOKEN --body "$CLOUDFLARE_API_TOKEN"
gh secret set CLOUDFLARE_ACCOUNT_ID --body "$CLOUDFLARE_ACCOUNT_ID"

# Supabase secrets
gh secret set SUPABASE_ACCESS_TOKEN --body "$SUPABASE_ACCESS_TOKEN"

# Staging secrets
gh secret set STAGING_SUPABASE_PROJECT_ID --body "$STAGING_SUPABASE_PROJECT_ID"
gh secret set STAGING_SUPABASE_URL --body "$STAGING_SUPABASE_URL"
gh secret set STAGING_SUPABASE_ANON_KEY --body "$STAGING_SUPABASE_ANON_KEY"
gh secret set STAGING_SUPABASE_SERVICE_ROLE_KEY --body "$STAGING_SUPABASE_SERVICE_ROLE_KEY"
gh secret set STAGING_DATABASE_URL --body "$STAGING_DATABASE_URL"
gh secret set STAGING_JWT_SECRET --body "$STAGING_JWT_SECRET"

# Production secrets
gh secret set PRODUCTION_SUPABASE_PROJECT_ID --body "$PRODUCTION_SUPABASE_PROJECT_ID"
gh secret set PRODUCTION_SUPABASE_URL --body "$PRODUCTION_SUPABASE_URL"
gh secret set PRODUCTION_SUPABASE_ANON_KEY --body "$PRODUCTION_SUPABASE_ANON_KEY"
gh secret set PRODUCTION_SUPABASE_SERVICE_ROLE_KEY --body "$PRODUCTION_SUPABASE_SERVICE_ROLE_KEY"
gh secret set PRODUCTION_DATABASE_URL --body "$PRODUCTION_DATABASE_URL"
gh secret set PRODUCTION_JWT_SECRET --body "$PRODUCTION_JWT_SECRET"

# Stripe secrets (if configured)
if [ -n "$STAGING_STRIPE_SECRET_KEY" ]; then
    gh secret set STAGING_STRIPE_SECRET_KEY --body "$STAGING_STRIPE_SECRET_KEY"
    gh secret set STAGING_STRIPE_PUBLISHABLE_KEY --body "$STAGING_STRIPE_PUBLISHABLE_KEY"
    gh secret set STAGING_STRIPE_WEBHOOK_SECRET --body "$STAGING_STRIPE_WEBHOOK_SECRET"
    
    gh secret set PRODUCTION_STRIPE_SECRET_KEY --body "$PRODUCTION_STRIPE_SECRET_KEY"
    gh secret set PRODUCTION_STRIPE_PUBLISHABLE_KEY --body "$PRODUCTION_STRIPE_PUBLISHABLE_KEY"
    gh secret set PRODUCTION_STRIPE_WEBHOOK_SECRET --body "$PRODUCTION_STRIPE_WEBHOOK_SECRET"
fi

print_success "All secrets configured successfully"

print_header "Step 5: Setting Repository Variables"

print_status "📝 Setting repository variables..."

# Set non-sensitive repository variables
gh variable set STAGING_API_URL --body "https://saas-factory-api-staging.lamtran2601.workers.dev"
gh variable set PRODUCTION_API_URL --body "https://saas-factory-api-prod.lamtran2601.workers.dev"
gh variable set STAGING_FRONTEND_URL --body "https://saas-factory-staging.pages.dev"
gh variable set PRODUCTION_FRONTEND_URL --body "https://saas-factory-production.pages.dev"

print_success "Repository variables configured"

print_header "Step 6: Configuring Branch Protection"

print_status "🛡️ Setting up branch protection rules..."

# Check if branches exist
if gh api repos/:owner/:repo/branches/main &> /dev/null; then
    print_status "Setting up protection for main branch..."
    gh api repos/:owner/:repo/branches/main/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["test","build-test"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false > /dev/null
    print_success "Main branch protection configured"
else
    print_warning "Main branch not found, skipping protection setup"
fi

if gh api repos/:owner/:repo/branches/develop &> /dev/null; then
    print_status "Setting up protection for develop branch..."
    gh api repos/:owner/:repo/branches/develop/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["test"]}' \
        --field enforce_admins=false \
        --field required_pull_request_reviews=null \
        --field restrictions=null \
        --field allow_force_pushes=false \
        --field allow_deletions=false > /dev/null
    print_success "Develop branch protection configured"
else
    print_warning "Develop branch not found, skipping protection setup"
fi

print_header "Step 7: Configuring Deployment Environments"

print_status "🌍 Setting up deployment environments..."

# Create staging environment
gh api repos/:owner/:repo/environments/staging --method PUT > /dev/null
print_success "Staging environment created"

# Create production-approval environment with reviewers
gh api repos/:owner/:repo/environments/production-approval \
    --method PUT \
    --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
    --field reviewers="[{\"type\":\"User\",\"id\":$USER_ID}]" > /dev/null
print_success "Production-approval environment created with manual approval"

print_header "Step 8: Validation"

print_status "🔍 Validating configuration..."

# Check secrets
SECRET_COUNT=$(gh secret list --json name | jq length)
print_status "Configured $SECRET_COUNT secrets"

# Check variables
VARIABLE_COUNT=$(gh variable list --json name | jq length)
print_status "Configured $VARIABLE_COUNT variables"

# Check environments
ENV_COUNT=$(gh api repos/:owner/:repo/environments | jq '.environments | length')
print_status "Configured $ENV_COUNT environments"

print_success "✅ GitHub repository configuration completed successfully!"

print_status ""
print_status "📋 Configuration Summary:"
print_status "   Repository: $REPO_OWNER/$REPO_NAME"
print_status "   Secrets: $SECRET_COUNT configured"
print_status "   Variables: $VARIABLE_COUNT configured"
print_status "   Environments: $ENV_COUNT configured"
print_status "   Branch Protection: main and develop (if they exist)"
print_status ""
print_status "🚀 Next Steps:"
print_status "   1. Push to develop branch to test staging deployment"
print_status "   2. Create PR to main branch to test production deployment"
print_status "   3. Monitor GitHub Actions for deployment status"
print_status ""
print_success "GitHub configuration script completed!"
