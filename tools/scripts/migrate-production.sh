#!/bin/bash

# Production Database Migration Script
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
    print_error "Environment not specified. Usage: ./migrate-production.sh [staging|production]"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

print_warning "🚨 You are about to run database migrations on $ENVIRONMENT environment"
print_warning "This operation is irreversible and may cause downtime"

# Confirmation prompt
read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    print_status "Migration cancelled"
    exit 0
fi

# Set database URL based on environment
if [ "$ENVIRONMENT" = "staging" ]; then
    if [ -z "$STAGING_DATABASE_URL" ]; then
        print_error "STAGING_DATABASE_URL environment variable is not set"
        print_status "Please set it with: export STAGING_DATABASE_URL='your-staging-db-url'"
        exit 1
    fi
    export DATABASE_URL="$STAGING_DATABASE_URL"
elif [ "$ENVIRONMENT" = "production" ]; then
    if [ -z "$PRODUCTION_DATABASE_URL" ]; then
        print_error "PRODUCTION_DATABASE_URL environment variable is not set"
        print_status "Please set it with: export PRODUCTION_DATABASE_URL='your-production-db-url'"
        exit 1
    fi
    export DATABASE_URL="$PRODUCTION_DATABASE_URL"
fi

print_status "🗄️ Starting database migration for $ENVIRONMENT..."

# Navigate to API directory
cd apps/api

# Check database connection
print_status "🔍 Testing database connection..."
if ! bunx prisma db execute --stdin <<< "SELECT 1;" > /dev/null 2>&1; then
    print_error "Failed to connect to database. Please check your DATABASE_URL"
    exit 1
fi
print_success "Database connection successful"

# Generate Prisma client
print_status "🔧 Generating Prisma client..."
bunx prisma generate

# Check migration status
print_status "📋 Checking current migration status..."
bunx prisma migrate status

# Create backup (if in production)
if [ "$ENVIRONMENT" = "production" ]; then
    print_status "💾 Creating database backup..."
    BACKUP_FILE="backup-$(date +%Y%m%d-%H%M%S).sql"
    print_warning "Manual backup recommended before proceeding"
    print_status "You can create a backup with:"
    print_status "pg_dump \$DATABASE_URL > $BACKUP_FILE"
    
    read -p "Have you created a backup? (yes/no): " backup_confirm
    if [ "$backup_confirm" != "yes" ]; then
        print_warning "Please create a backup before proceeding"
        exit 1
    fi
fi

# Deploy migrations
print_status "🚀 Deploying migrations..."
bunx prisma migrate deploy

# Verify migration
print_status "✅ Verifying migration status..."
bunx prisma migrate status

# Generate updated client
print_status "🔄 Regenerating Prisma client..."
bunx prisma generate

print_success "🎉 Database migration completed successfully!"

# Optional: Run data seeding for staging
if [ "$ENVIRONMENT" = "staging" ]; then
    read -p "Do you want to seed the database with demo data? (yes/no): " seed_confirm
    if [ "$seed_confirm" = "yes" ]; then
        print_status "🌱 Seeding database..."
        bun run db:seed
        print_success "Database seeded successfully"
    fi
fi

print_status "📋 Migration Summary:"
print_status "   Environment: $ENVIRONMENT"
print_status "   Database: Connected and migrated"
print_status "   Prisma Client: Generated"

print_status "📝 Next steps:"
print_status "   1. Deploy your application"
print_status "   2. Test the application thoroughly"
print_status "   3. Monitor for any issues"

cd ../..
