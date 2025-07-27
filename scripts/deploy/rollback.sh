#!/bin/bash

# SaaS Factory Rollback Script
# This script rolls back a deployment to the previous version

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

# Check if environment is provided
if [ -z "$1" ]; then
    print_error "Environment not specified. Usage: ./rollback.sh [staging|production] [reason]"
    exit 1
fi

ENVIRONMENT=$1
ROLLBACK_REASON="${2:-Manual rollback requested}"

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Set configuration based on environment
if [ "$ENVIRONMENT" = "staging" ]; then
    API_WORKER_NAME="saas-factory-api-staging"
    PAGES_PROJECT_NAME="saas-factory-staging"
    HEALTH_CHECK_URL="https://saas-factory-api-staging.lamtran2601.workers.dev/health"
    FRONTEND_URL="https://saas-factory-staging.pages.dev"
else
    API_WORKER_NAME="saas-factory-api-prod"
    PAGES_PROJECT_NAME="saas-factory-production"
    HEALTH_CHECK_URL="https://saas-factory-api-prod.lamtran2601.workers.dev/health"
    FRONTEND_URL="https://saas-factory-production.pages.dev"
fi

print_warning "🚨 ROLLBACK OPERATION"
print_warning "Environment: $ENVIRONMENT"
print_warning "Reason: $ROLLBACK_REASON"
print_warning ""
print_warning "This will rollback the current deployment to the previous version!"

# Confirmation prompt for production
if [ "$ENVIRONMENT" = "production" ]; then
    print_error "⚠️  PRODUCTION ROLLBACK DETECTED"
    read -p "Are you absolutely sure you want to rollback production? (type 'ROLLBACK' to confirm): " confirm
    if [ "$confirm" != "ROLLBACK" ]; then
        print_status "Rollback cancelled"
        exit 0
    fi
fi

print_status "🔄 Starting rollback process for $ENVIRONMENT environment..."

# Check prerequisites
print_status "🔍 Checking prerequisites..."

if ! command -v wrangler &> /dev/null; then
    print_error "Wrangler is not installed. Please install with: bun add -g wrangler"
    exit 1
fi

if ! command -v git &> /dev/null; then
    print_error "Git is not installed."
    exit 1
fi

if ! wrangler whoami &> /dev/null; then
    print_error "Not authenticated with Cloudflare. Please run: wrangler login"
    exit 1
fi

print_success "Prerequisites check passed"

# Get current deployment info
print_status "📊 Getting current deployment information..."

# Get current git commit
CURRENT_COMMIT=$(git rev-parse HEAD)
CURRENT_BRANCH=$(git branch --show-current)

print_status "Current commit: $CURRENT_COMMIT"
print_status "Current branch: $CURRENT_BRANCH"

# Get previous commit
PREVIOUS_COMMIT=$(git rev-parse HEAD~1)
print_status "Previous commit: $PREVIOUS_COMMIT"

# Show what we're rolling back from and to
print_status "📋 Rollback details:"
echo "  From: $(git log --oneline -1 $CURRENT_COMMIT)"
echo "  To:   $(git log --oneline -1 $PREVIOUS_COMMIT)"

# Create rollback branch
ROLLBACK_BRANCH="rollback-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S)"
print_status "🌿 Creating rollback branch: $ROLLBACK_BRANCH"

git checkout -b $ROLLBACK_BRANCH
git reset --hard $PREVIOUS_COMMIT

# Rollback API Worker
print_status "🔄 Rolling back API Worker..."

# Check if we have a previous deployment to rollback to
if wrangler deployments list --name $API_WORKER_NAME --limit 2 | grep -q "deployment"; then
    # Use Wrangler's rollback feature if available
    print_status "Using Wrangler rollback feature..."
    wrangler rollback --name $API_WORKER_NAME
    print_success "API Worker rolled back using Wrangler"
else
    # Manual rollback by redeploying previous version
    print_status "Manual rollback: rebuilding and deploying previous version..."
    
    cd apps/api
    
    # Install dependencies for the previous version
    bun install --frozen-lockfile
    
    # Build the previous version
    bun run build
    
    # Deploy the previous version
    if [ "$ENVIRONMENT" = "staging" ]; then
        wrangler deploy --env staging
    else
        wrangler deploy --env production
    fi
    
    cd ../..
    print_success "API Worker manually rolled back"
fi

# Rollback Frontend Pages
print_status "🔄 Rolling back Frontend Pages..."

cd apps/web

# Install dependencies for the previous version
bun install --frozen-lockfile

# Build the previous version with correct environment variables
if [ "$ENVIRONMENT" = "staging" ]; then
    export VITE_API_URL="https://saas-factory-api-staging.lamtran2601.workers.dev"
    export VITE_SUPABASE_URL="${STAGING_SUPABASE_URL:-https://staging.supabase.co}"
    export VITE_SUPABASE_ANON_KEY="${STAGING_SUPABASE_ANON_KEY:-staging-anon-key}"
    export VITE_ENVIRONMENT="staging"
    export VITE_APP_NAME="SaaS Factory (Staging)"
    export VITE_APP_URL="https://saas-factory-staging.pages.dev"
else
    export VITE_API_URL="https://saas-factory-api-prod.lamtran2601.workers.dev"
    export VITE_SUPABASE_URL="${PRODUCTION_SUPABASE_URL:-https://production.supabase.co}"
    export VITE_SUPABASE_ANON_KEY="${PRODUCTION_SUPABASE_ANON_KEY:-production-anon-key}"
    export VITE_STRIPE_PUBLISHABLE_KEY="${PRODUCTION_STRIPE_PUBLISHABLE_KEY:-pk_live_...}"
    export VITE_ENVIRONMENT="production"
    export VITE_APP_NAME="SaaS Factory"
    export VITE_APP_URL="https://saas-factory-production.pages.dev"
fi

# Build the previous version
bun run build

# Deploy the previous version
wrangler pages deploy dist --project-name $PAGES_PROJECT_NAME

cd ../..
print_success "Frontend Pages rolled back"

# Database rollback (if needed)
print_status "🗄️ Checking database rollback requirements..."

# Note: Database rollbacks are more complex and should be handled carefully
# This is a placeholder for database rollback logic
print_warning "Database rollback not implemented in this script"
print_warning "If database changes were made, manual intervention may be required"

# Wait for rollback to take effect
print_status "⏳ Waiting for rollback to take effect..."
sleep 30

# Verify rollback
print_status "🔍 Verifying rollback..."

# Health check API
print_status "Testing API health endpoint..."
if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
    print_success "API health check passed"
else
    print_error "API health check failed after rollback"
    exit 1
fi

# Check frontend
print_status "Testing frontend..."
if curl -f -s "$FRONTEND_URL" > /dev/null; then
    print_success "Frontend check passed"
else
    print_error "Frontend check failed after rollback"
    exit 1
fi

# Run verification script if available
if [ -f "scripts/deploy/verify-deployment.sh" ]; then
    print_status "Running deployment verification..."
    bash scripts/deploy/verify-deployment.sh $ENVIRONMENT
fi

# Log rollback
print_status "📝 Logging rollback..."

ROLLBACK_LOG="rollback-$ENVIRONMENT-$(date +%Y%m%d-%H%M%S).log"
cat > $ROLLBACK_LOG << EOF
Rollback Log
============
Environment: $ENVIRONMENT
Timestamp: $(date)
Reason: $ROLLBACK_REASON
Triggered by: $(whoami)

Previous Deployment:
  Commit: $CURRENT_COMMIT
  Branch: $CURRENT_BRANCH
  Message: $(git log --oneline -1 $CURRENT_COMMIT)

Rolled back to:
  Commit: $PREVIOUS_COMMIT
  Message: $(git log --oneline -1 $PREVIOUS_COMMIT)

Rollback Branch: $ROLLBACK_BRANCH

URLs:
  API: $HEALTH_CHECK_URL
  Frontend: $FRONTEND_URL

Status: SUCCESS
EOF

print_success "Rollback logged to: $ROLLBACK_LOG"

# Generate rollback summary
print_success "🎉 Rollback completed successfully!"
print_status "📋 Rollback Summary:"
print_status "   Environment: $ENVIRONMENT"
print_status "   Reason: $ROLLBACK_REASON"
print_status "   Rolled back from: $(git log --oneline -1 $CURRENT_COMMIT)"
print_status "   Rolled back to: $(git log --oneline -1 $PREVIOUS_COMMIT)"
print_status "   API URL: ${HEALTH_CHECK_URL%/health}"
print_status "   Frontend URL: $FRONTEND_URL"
print_status "   Rollback branch: $ROLLBACK_BRANCH"

print_status "📝 Next steps:"
print_status "   1. Monitor the application closely"
print_status "   2. Verify all functionality is working"
print_status "   3. Investigate the original issue"
print_status "   4. Plan a fix for the next deployment"
print_status "   5. Clean up rollback branch when no longer needed"

# Send notification
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🔄 Rollback completed for $ENVIRONMENT\nReason: $ROLLBACK_REASON\nFrontend: $FRONTEND_URL\nAPI: ${HEALTH_CHECK_URL%/health}\"}" \
        "$SLACK_WEBHOOK_URL"
fi

print_warning "🔍 Please monitor the application closely for the next 30 minutes"
print_success "Rollback script completed!"
