#!/bin/bash

# Supabase Setup Script for SaaS Factory
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

print_status "🚀 Setting up Supabase for SaaS Factory..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    print_warning "Supabase CLI not found. Installing..."
    if command -v bun &> /dev/null; then
        bun add -g supabase
    elif command -v npm &> /dev/null; then
        npm install -g supabase
    else
        print_error "Neither Bun nor npm found. Please install one of them first."
        exit 1
    fi
fi

print_success "Supabase CLI is available"

# Login to Supabase
print_status "🔐 Logging in to Supabase..."
print_status "Please follow the browser login process..."
supabase login

# Initialize Supabase project (optional)
if [ ! -f "supabase/config.toml" ]; then
    print_status "📁 Initializing Supabase project..."
    supabase init
else
    print_status "Supabase project already initialized"
fi

# Create SQL script for database setup
print_status "📝 Creating database setup script..."
cat > supabase/setup.sql << 'EOF'
-- SaaS Factory Database Setup for Supabase
-- This script prepares the Supabase database for use with Prisma

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a dedicated user for Prisma (optional, for better security)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'prisma_user') THEN
        CREATE USER prisma_user WITH PASSWORD 'secure_prisma_password_change_this';
    END IF;
END
$$;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE postgres TO prisma_user;
GRANT ALL ON SCHEMA public TO prisma_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO prisma_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO prisma_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO prisma_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO prisma_user;

-- Create a function to handle user creation from auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, email_verified, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.email_confirmed_at IS NOT NULL,
    NEW.created_at,
    NEW.updated_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Note: Prisma will handle the rest of the schema creation
-- Run 'bunx prisma migrate deploy' after setting up your environment
EOF

print_success "Database setup script created at supabase/setup.sql"

# Create environment template
print_status "📋 Creating environment template..."
cat > .env.supabase.template << 'EOF'
# Supabase Configuration Template
# Copy this to your .env files and fill in the actual values

# Get these values from your Supabase project dashboard:
# https://supabase.com/dashboard/project/your-project-id/settings/api

# Project URL (from Settings > API)
SUPABASE_URL="https://your-project-id.supabase.co"

# Anonymous key (from Settings > API)
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Service role key (from Settings > API) - KEEP SECRET!
SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Database URL (from Settings > Database)
# Format: postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-ID].supabase.co:5432/postgres
DATABASE_URL="postgresql://postgres:your-password@db.your-project-id.supabase.co:5432/postgres"
EOF

print_success "Environment template created at .env.supabase.template"

print_status "📖 Next steps:"
print_status ""
print_status "1. Create a new Supabase project:"
print_status "   - Go to https://supabase.com/dashboard"
print_status "   - Click 'New Project'"
print_status "   - Choose your organization and set project details"
print_status "   - Wait for project creation (2-3 minutes)"
print_status ""
print_status "2. Configure your project:"
print_status "   - Go to Settings > API and copy your keys"
print_status "   - Go to Settings > Database and copy the connection string"
print_status "   - Update your .env files with the actual values"
print_status ""
print_status "3. Set up authentication:"
print_status "   - Go to Authentication > Settings"
print_status "   - Set Site URL to your frontend URL"
print_status "   - Add redirect URLs for all environments"
print_status "   - Enable desired auth providers"
print_status ""
print_status "4. Run the database setup:"
print_status "   - Execute the SQL in supabase/setup.sql in your Supabase SQL editor"
print_status "   - Or run: supabase db reset (if using local development)"
print_status ""
print_status "5. Deploy your schema:"
print_status "   - Set DATABASE_URL environment variable"
print_status "   - Run: cd apps/api && bunx prisma migrate deploy"
print_status ""
print_status "6. Test the connection:"
print_status "   - Run: cd apps/api && bunx prisma db execute --stdin <<< 'SELECT 1;'"
print_status ""

print_warning "🔒 Security reminders:"
print_status "- Never commit your .env files to version control"
print_status "- Use different projects for staging and production"
print_status "- Rotate your service role keys regularly"
print_status "- Enable Row Level Security (RLS) if needed"
print_status "- Monitor your database usage and set up alerts"

print_success "🎉 Supabase setup guide completed!"
print_status "Check the created files and follow the next steps above."
