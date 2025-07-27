#!/bin/bash

# SaaS Factory Deployment Script
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
    print_error "Environment not specified. Usage: ./deploy.sh [staging|production]"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

print_status "🚀 Starting deployment to $ENVIRONMENT environment..."

# Check prerequisites
print_status "🔍 Checking prerequisites..."

# Check if Bun is installed
if ! command -v bun &> /dev/null; then
    print_error "Bun is not installed. Please install Bun first."
    exit 1
fi

# Check if Wrangler is installed
if ! command -v wrangler &> /dev/null; then
    print_error "Wrangler is not installed. Please install with: bun add -g wrangler"
    exit 1
fi

# Check if user is logged in to Wrangler
if ! wrangler whoami &> /dev/null; then
    print_error "Not logged in to Wrangler. Please run: wrangler login"
    exit 1
fi

print_success "Prerequisites check passed"

# Install dependencies
print_status "📦 Installing dependencies..."
bun install

# Run tests
print_status "🧪 Running tests..."
bun run lint
bun run type-check
bun run test:unit

print_success "All tests passed"

# Generate Prisma client
print_status "🔧 Generating Prisma client..."
cd apps/api
bunx prisma generate
cd ../..

# Deploy database migrations
print_status "🗄️ Deploying database migrations..."
cd apps/api

if [ "$ENVIRONMENT" = "staging" ]; then
    if [ -z "$STAGING_DATABASE_URL" ]; then
        print_error "STAGING_DATABASE_URL environment variable is not set"
        exit 1
    fi
    export DATABASE_URL="$STAGING_DATABASE_URL"
elif [ "$ENVIRONMENT" = "production" ]; then
    if [ -z "$PRODUCTION_DATABASE_URL" ]; then
        print_error "PRODUCTION_DATABASE_URL environment variable is not set"
        exit 1
    fi
    export DATABASE_URL="$PRODUCTION_DATABASE_URL"
fi

bunx prisma migrate deploy
print_success "Database migrations deployed"

# Deploy API to Cloudflare Workers
print_status "☁️ Deploying API to Cloudflare Workers..."
bunx wrangler deploy --env $ENVIRONMENT
print_success "API deployed to Cloudflare Workers"

cd ../..

# Build and deploy frontend
print_status "🌐 Building frontend..."
cd apps/web

# Set environment variables for build
if [ "$ENVIRONMENT" = "staging" ]; then
    export VITE_API_URL="https://api-staging.your-domain.com"
    export VITE_APP_URL="https://staging.your-domain.com"
    export VITE_ENVIRONMENT="staging"
elif [ "$ENVIRONMENT" = "production" ]; then
    export VITE_API_URL="https://api.your-domain.com"
    export VITE_APP_URL="https://your-domain.com"
    export VITE_ENVIRONMENT="production"
fi

# Build the frontend
bun run build
print_success "Frontend built successfully"

cd ../..

# Deploy frontend to Cloudflare Pages (manual step)
print_warning "Frontend deployment to Cloudflare Pages should be done through the dashboard or GitHub Actions"
print_status "Built files are available in: apps/web/dist"

# Verify deployment
print_status "🔍 Verifying deployment..."

if [ "$ENVIRONMENT" = "staging" ]; then
    API_URL="https://api-staging.your-domain.com"
    FRONTEND_URL="https://staging.your-domain.com"
elif [ "$ENVIRONMENT" = "production" ]; then
    API_URL="https://api.your-domain.com"
    FRONTEND_URL="https://your-domain.com"
fi

# Test API health endpoint
print_status "Testing API health endpoint..."
if curl -f -s "$API_URL/health" > /dev/null; then
    print_success "API is responding"
else
    print_warning "API health check failed or endpoint not available yet"
fi

print_success "🎉 Deployment to $ENVIRONMENT completed!"
print_status "📋 Deployment Summary:"
print_status "   Environment: $ENVIRONMENT"
print_status "   API URL: $API_URL"
print_status "   Frontend URL: $FRONTEND_URL"
print_status "   Frontend build: apps/web/dist"

print_status "📝 Next steps:"
print_status "   1. Deploy frontend to Cloudflare Pages"
print_status "   2. Configure custom domains (if needed)"
print_status "   3. Test the complete application"
print_status "   4. Monitor logs and performance"
