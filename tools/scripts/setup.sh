#!/bin/bash

# SaaS Factory Development Setup Script
set -e

echo "🚀 Setting up SaaS Factory development environment..."

# Check if Bun is installed
if ! command -v bun &> /dev/null; then
    echo "❌ Bun is not installed. Please install Bun first:"
    echo "   curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

echo "✅ Bun is installed"

# Install dependencies
echo "📦 Installing dependencies..."
bun install

# Check if PostgreSQL is available
if ! command -v psql &> /dev/null; then
    echo "⚠️  PostgreSQL is not installed locally."
    echo "   You can use a cloud provider like Neon, Railway, or Supabase."
    echo "   Make sure to set DATABASE_URL in your .env files."
else
    echo "✅ PostgreSQL is available"
fi

# Copy environment files if they don't exist
if [ ! -f "apps/api/.env" ]; then
    echo "📝 Creating API environment file..."
    cp apps/api/.env.example apps/api/.env
    echo "   Please edit apps/api/.env with your configuration"
fi

if [ ! -f "apps/web/.env" ]; then
    echo "📝 Creating Web environment file..."
    cp apps/web/.env.example apps/web/.env
    echo "   Please edit apps/web/.env with your configuration"
fi

# Generate Prisma client
echo "🔧 Generating Prisma client..."
cd apps/api
bun run db:generate
cd ../..

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit your .env files with your database and Supabase configuration"
echo "2. Run database migrations: bun run db:migrate"
echo "3. Seed the database: bun run db:seed"
echo "4. Start development servers: bun run dev"
echo ""
echo "For more information, see the README.md file."
