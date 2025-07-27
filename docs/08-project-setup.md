# SaaS Factory - Project Setup & Initialization

## Overview

This guide provides step-by-step instructions for setting up the SaaS Factory development environment using modern tools including Bun runtime and package manager, with vendor-agnostic database and authentication setup. Follow these instructions to get the project running locally.

## Prerequisites

### Required Software

- **Bun**: Version 1.0.x or higher (JavaScript runtime and package manager)
- **Node.js**: Version 18.x or higher (for Cloudflare Workers compatibility)
- **Git**: For version control
- **VS Code**: Recommended IDE with extensions

### Recommended VS Code Extensions

```json
{
  "recommendations": [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.vscode-typescript-next",
    "prisma.prisma",
    "cloudflare.vscode-wrangler"
  ]
}
```

### Installation Commands

```bash
# Install Bun (includes package manager)
curl -fsSL https://bun.sh/install | bash

# Verify installation
bun --version
node --version
```

## Project Structure

### Modern Monorepo Layout

```
saas-factory/
├── apps/
│   ├── web/                  # React frontend application
│   │   ├── src/
│   │   ├── public/
│   │   ├── package.json
│   │   ├── vite.config.ts
│   │   └── tailwind.config.js
│   ├── api/                  # Hono.js backend API
│   │   ├── src/
│   │   ├── prisma/
│   │   ├── package.json
│   │   ├── wrangler.toml
│   │   └── tsconfig.json
│   └── admin/                # Admin dashboard (future)
├── packages/
│   ├── ui/                   # Shared UI components
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── types/                # Shared TypeScript types
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── config/               # Shared configuration
│   │   ├── eslint/
│   │   ├── typescript/
│   │   └── tailwind/
│   ├── utils/                # Shared utilities
│   └── auth/                 # Portable auth utilities
├── tools/
│   ├── scripts/              # Development and build scripts
│   └── configs/              # Shared configurations
├── docs/                     # Documentation
├── .github/                  # GitHub Actions workflows
├── package.json              # Root package.json with Bun workspaces
├── bun.lockb                # Bun lockfile
└── bunfig.toml              # Bun configuration
```

## Initial Setup Commands

### 1. Clone and Initialize Repository

```bash
# Clone the repository (or initialize new one)
git clone <repository-url> saas-factory
cd saas-factory

# Initialize if starting from scratch
git init
git add .
git commit -m "Initial commit"
```

### 2. Install Dependencies with Bun

```bash
# Install all dependencies using Bun
bun install

# Alternative: Install specific workspace dependencies
bun install --filter web
bun install --filter api
```

### 3. Database Setup

```bash
# Option 1: Use any PostgreSQL provider (Neon, Railway, Supabase, etc.)
# Create a new PostgreSQL database with your preferred provider

# Option 2: Local PostgreSQL with Docker
docker run --name saas-factory-db \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=saas_factory_dev \
  -p 5432:5432 \
  -d postgres:15

# Option 3: Use Supabase for PostgreSQL only (not for RLS)
# Install Supabase CLI for database management
bun add -g supabase

# Initialize Supabase (for database only)
supabase init
supabase start
```

### 4. Environment Configuration

```bash
# Copy environment templates
cp apps/api/.env.example apps/api/.env
cp apps/web/.env.example apps/web/.env

# Edit environment variables
# apps/api/.env
DATABASE_URL="postgresql://postgres:password@localhost:5432/saas_factory_dev"
# Or use your PostgreSQL provider's connection string:
# DATABASE_URL="postgresql://user:password@host:5432/database"

# Supabase Auth configuration (authentication only)
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# Other services
STRIPE_SECRET_KEY="sk_test_..."
EMAIL_API_KEY="your-email-service-api-key"

# apps/web/.env
VITE_API_URL="http://localhost:8787"
VITE_SUPABASE_URL="https://your-project.supabase.co"
VITE_SUPABASE_ANON_KEY="your-anon-key"
VITE_STRIPE_PUBLISHABLE_KEY="pk_test_..."
```

### 5. Database Setup with Prisma

```bash
# Navigate to API directory
cd apps/api

# Run database migrations to Supabase
npx prisma migrate dev --name init

# Generate Prisma client
npx prisma generate

# Seed development data
bun run db:seed
```

### 6. Start Development Servers

```bash
# Using Bun workspaces (recommended)
bun run dev

# Or start individually:
# Terminal 1: Start backend API
cd apps/api
bun run dev

# Terminal 2: Start frontend app
cd apps/web
bun run dev

# Terminal 3: Start database (if using local PostgreSQL)
# PostgreSQL should be running on localhost:5432
```

## Configuration Files

### Root Package.json

```json
{
  "name": "saas-factory",
  "version": "1.0.0",
  "private": true,
  "workspaces": ["apps/*", "packages/*", "tools/*"],
  "scripts": {
    "dev": "bun run --filter='*' dev",
    "build": "bun run --filter='*' build",
    "test": "bun test",
    "lint": "bun run --filter='*' lint",
    "type-check": "bun run --filter='*' type-check",
    "clean": "bun run --filter='*' clean && rm -rf node_modules",
    "db:migrate": "bun run --filter=api db:migrate",
    "db:generate": "bun run --filter=api db:generate",
    "db:seed": "bun run --filter=api db:seed"
  },
  "devDependencies": {
    "@types/node": "^20.8.0",
    "typescript": "^5.3.3"
  }
}
```

### Bun Configuration

```toml
# bunfig.toml
[install]
# Configure package installation
cache = true
exact = true

[install.scopes]
# Configure scoped packages if needed

[run]
# Configure script execution
shell = "bash"
```

### Frontend Package.json (apps/web)

```json
{
  "name": "@saas-factory/web",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "type-check": "tsc --noEmit",
    "test": "bun test",
    "clean": "rm -rf dist node_modules"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.1",
    "@tanstack/react-query": "^5.8.4",
    "react-hook-form": "^7.48.2",
    "@hookform/resolvers": "^3.3.2",
    "zod": "^3.22.4",
    "zustand": "^4.4.7",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "@supabase/supabase-js": "^2.38.0",
    "lucide-react": "^0.294.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0",
    "@saas-factory/ui": "workspace:*",
    "@saas-factory/types": "workspace:*",
    "@saas-factory/utils": "workspace:*",
    "@saas-factory/auth": "workspace:*"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@saas-factory/config": "workspace:*",
    "@vitejs/plugin-react": "^4.1.1",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.3.5",
    "typescript": "^5.2.2",
    "vite": "^5.0.0"
  }
}
```

### Backend Package.json (apps/api)

```json
{
  "name": "@saas-factory/api",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "deploy:staging": "wrangler deploy --env staging",
    "deploy:production": "wrangler deploy --env production",
    "build": "esbuild src/index.ts --bundle --outfile=dist/index.js --format=esm --platform=neutral",
    "lint": "eslint . --ext ts --report-unused-disable-directives --max-warnings 0",
    "type-check": "tsc --noEmit",
    "test": "bun test",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:deploy": "prisma migrate deploy",
    "db:seed": "bun run prisma/seed.ts",
    "clean": "rm -rf dist node_modules"
  },
  "dependencies": {
    "hono": "^3.11.7",
    "@prisma/client": "^5.6.0",
    "@supabase/supabase-js": "^2.38.0",
    "zod": "^3.22.4",
    "stripe": "^14.7.0",
    "@saas-factory/types": "workspace:*",
    "@saas-factory/utils": "workspace:*",
    "@saas-factory/auth": "workspace:*"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.20231025.0",
    "@saas-factory/config": "workspace:*",
    "esbuild": "^0.19.0",
    "prisma": "^5.6.0",
    "typescript": "^5.2.2",
    "wrangler": "^3.19.0"
  }
}
```

### Docker Compose Configuration

```yaml
# docker-compose.yml
version: "3.8"

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: saas_factory_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### TypeScript Configuration

#### Root tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "allowJs": true,
    "strict": true,
    "noEmit": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "references": [
    { "path": "./frontend" },
    { "path": "./backend" },
    { "path": "./shared" }
  ]
}
```

### ESLint Configuration

```json
{
  "root": true,
  "env": { "browser": true, "es2020": true, "node": true },
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended",
    "@typescript-eslint/recommended-requiring-type-checking"
  ],
  "ignorePatterns": ["dist", ".eslintrc.cjs"],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "project": [
      "./tsconfig.json",
      "./frontend/tsconfig.json",
      "./backend/tsconfig.json"
    ]
  },
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": [
      "error",
      { "argsIgnorePattern": "^_" }
    ],
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/prefer-const": "error"
  }
}
```

## Development Scripts

### Database Initialization Script

```sql
-- scripts/init-db.sql
CREATE DATABASE saas_factory_dev;
CREATE DATABASE saas_factory_test;

-- Create development user
CREATE USER saas_factory_dev WITH PASSWORD 'dev_password';
GRANT ALL PRIVILEGES ON DATABASE saas_factory_dev TO saas_factory_dev;
GRANT ALL PRIVILEGES ON DATABASE saas_factory_test TO saas_factory_dev;
```

### Development Setup Script

```bash
#!/bin/bash
# tools/setup-dev.sh

echo "🚀 Setting up SaaS Factory development environment..."

# Check prerequisites
command -v bun >/dev/null 2>&1 || { echo "❌ Bun is required but not installed."; exit 1; }

# Install dependencies
echo "📦 Installing dependencies with Bun..."
bun install

# Setup database (choose one option)
echo "🗄️ Setting up database..."
echo "Choose your database setup:"
echo "1. Local PostgreSQL with Docker"
echo "2. Use existing PostgreSQL provider"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
  docker run --name saas-factory-db \
    -e POSTGRES_PASSWORD=password \
    -e POSTGRES_DB=saas_factory_dev \
    -p 5432:5432 \
    -d postgres:15
  echo "⏳ Waiting for PostgreSQL to be ready..."
  sleep 10
fi

# Setup database schema
echo "🔧 Setting up database schema..."
cd apps/api
bun run db:migrate
bun run db:generate
bun run db:seed

echo "✅ Development environment setup complete!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend: http://localhost:8787"
echo "📊 Database: Check your PostgreSQL provider dashboard"
```

## Verification Steps

### 1. Check Services

```bash
# Verify Supabase connection
supabase status

# Verify database connection
cd apps/api
npx prisma db pull

# Verify API health
curl http://localhost:8787/health

# Verify frontend build
cd apps/web
bun run build
```

### 2. Run Tests

```bash
# Run all tests with Bun
bun test

# Run specific workspace tests
bun run --filter=web test
bun run --filter=api test
```

### 3. Check Code Quality

```bash
# Lint all code
bun run lint

# Type check all code
bun run type-check

# Build all packages
bun run build
```

## Troubleshooting

### Common Issues

#### Database Connection Issues

```bash
# Reset database migrations
cd apps/api
bun run db:migrate reset

# Regenerate Prisma client
bun run db:generate

# For local PostgreSQL with Docker
docker restart saas-factory-db
```

#### Port Conflicts

```bash
# Check what's using ports
lsof -i :3000  # Frontend
lsof -i :8787  # Backend
lsof -i :5432  # PostgreSQL
```

#### Bun Issues

```bash
# Clean install with Bun
bun run clean
bun install

# Clear Bun cache
bun pm cache rm
```

#### Workspace Issues

```bash
# Reinstall all workspace dependencies
rm -rf node_modules apps/*/node_modules packages/*/node_modules
bun install
```

### Alternative Solutions for Removed Supabase Features

#### Real-time Updates (Alternative to Supabase Realtime)

```typescript
// WebSocket-based real-time updates
import { WebSocketServer } from "ws";

// Server-Sent Events for real-time updates
app.get("/events", (c) => {
  return c.streamText(async (stream) => {
    // Send real-time updates
  });
});
```

#### File Storage (Alternative to Supabase Storage)

```typescript
// Use Cloudflare R2, AWS S3, or any S3-compatible storage
import { S3Client } from "@aws-sdk/client-s3";

const s3Client = new S3Client({
  region: "auto",
  endpoint: "https://your-account.r2.cloudflarestorage.com",
});
```

This vendor-agnostic setup guide provides everything needed to get the SaaS Factory development environment running locally with maximum portability and no vendor lock-in.
