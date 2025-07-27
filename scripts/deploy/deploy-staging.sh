#!/bin/bash

# SaaS Factory Staging Deployment Script
# This script deploys the application to the staging environment

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

# Configuration
ENVIRONMENT="staging"
API_WORKER_NAME="saas-factory-api-staging"
PAGES_PROJECT_NAME="saas-factory-staging"
HEALTH_CHECK_URL="https://saas-factory-api-staging.lamtran2601.workers.dev/health"
FRONTEND_URL="https://saas-factory-staging.pages.dev"

print_status "🚀 Starting deployment to staging environment..."

# Check prerequisites
print_status "🔍 Checking prerequisites..."

# Check if required tools are installed
if ! command -v bun &> /dev/null; then
    print_error "Bun is not installed. Please install Bun first."
    exit 1
fi

if ! command -v wrangler &> /dev/null; then
    print_error "Wrangler is not installed. Please install with: bun add -g wrangler"
    exit 1
fi

if ! command -v supabase &> /dev/null; then
    print_error "Supabase CLI is not installed. Please install with: bun add -g supabase"
    exit 1
fi

# Check if user is authenticated
if ! wrangler whoami &> /dev/null; then
    print_error "Not authenticated with Cloudflare. Please run: wrangler login"
    exit 1
fi

print_success "Prerequisites check passed"

# Install dependencies
print_status "📦 Installing dependencies..."
bun install --frozen-lockfile
print_success "Dependencies installed"

# Run tests
print_status "🧪 Running tests..."
bun run lint
bun run type-check
bun run test:unit
print_success "All tests passed"

# Database migrations
print_status "🗄️ Applying database migrations..."
cd apps/api

# Link to staging Supabase project
if [ -n "$STAGING_SUPABASE_PROJECT_ID" ]; then
    supabase link --project-ref $STAGING_SUPABASE_PROJECT_ID
    supabase db push
    print_success "Database migrations applied"
else
    print_warning "STAGING_SUPABASE_PROJECT_ID not set, skipping database migrations"
fi

cd ../..

# Build API
print_status "🔧 Building API..."
cd apps/api
bun run build
print_success "API built successfully"

# Deploy API to Cloudflare Workers
print_status "☁️ Deploying API to Cloudflare Workers..."
wrangler deploy --env staging
print_success "API deployed to Cloudflare Workers"

# Set Worker secrets (if running locally with environment variables)
if [ -n "$STAGING_DATABASE_URL" ]; then
    print_status "🔐 Setting Worker secrets..."
    echo "$STAGING_DATABASE_URL" | wrangler secret put DATABASE_URL --env staging
    echo "$STAGING_SUPABASE_SERVICE_ROLE_KEY" | wrangler secret put SUPABASE_SERVICE_ROLE_KEY --env staging
    echo "$STAGING_JWT_SECRET" | wrangler secret put JWT_SECRET --env staging
    print_success "Worker secrets set"
fi

cd ../..

# Build frontend
print_status "🌐 Building frontend..."
cd apps/web

# Set environment variables for build
export VITE_API_URL="https://saas-factory-api-staging.lamtran2601.workers.dev"
export VITE_SUPABASE_URL="${STAGING_SUPABASE_URL:-https://staging.supabase.co}"
export VITE_SUPABASE_ANON_KEY="${STAGING_SUPABASE_ANON_KEY:-staging-anon-key}"
export VITE_ENVIRONMENT="staging"
export VITE_APP_NAME="SaaS Factory (Staging)"
export VITE_APP_URL="https://saas-factory-staging.pages.dev"

bun run build
print_success "Frontend built successfully"

# Deploy frontend to Cloudflare Pages
print_status "📄 Deploying frontend to Cloudflare Pages..."
wrangler pages deploy dist --project-name $PAGES_PROJECT_NAME
print_success "Frontend deployed to Cloudflare Pages"

cd ../..

# Wait for deployment to be ready
print_status "⏳ Waiting for deployment to be ready..."
sleep 30

# Verify deployment
print_status "🔍 Verifying deployment..."

# Health check API
print_status "Testing API health endpoint..."
if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
    print_success "API health check passed"
else
    print_error "API health check failed"
    exit 1
fi

# Test API endpoints
print_status "Testing API endpoints..."
if curl -f -s "${HEALTH_CHECK_URL%/health}/api" > /dev/null; then
    print_success "API endpoints test passed"
else
    print_warning "API endpoints test failed, but continuing..."
fi

# Check frontend deployment
print_status "Testing frontend deployment..."
if curl -f -s "$FRONTEND_URL" > /dev/null; then
    print_success "Frontend deployment check passed"
else
    print_error "Frontend deployment check failed"
    exit 1
fi

# Generate deployment summary
print_success "🎉 Staging deployment completed successfully!"
print_status "📋 Deployment Summary:"
print_status "   Environment: $ENVIRONMENT"
print_status "   API URL: https://saas-factory-api-staging.lamtran2601.workers.dev"
print_status "   Frontend URL: https://saas-factory-staging.pages.dev"
print_status "   Health Check: $HEALTH_CHECK_URL"

print_status "📝 Next steps:"
print_status "   1. Test the application thoroughly"
print_status "   2. Verify all features are working correctly"
print_status "   3. Check logs for any issues"
print_status "   4. Promote to production when ready"

# Optional: Send notification
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ Staging deployment completed successfully!\nFrontend: $FRONTEND_URL\nAPI: https://saas-factory-api-staging.lamtran2601.workers.dev\"}" \
        "$SLACK_WEBHOOK_URL"
fi

print_success "Staging deployment script completed!"
