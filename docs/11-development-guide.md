# SaaS Factory - Development Guide

## Quick Start

### Prerequisites

- **Bun**: Version 1.0.x or higher ([Install Bun](https://bun.sh/docs/installation))
- **Node.js**: Version 18.x or higher (for compatibility)
- **PostgreSQL**: Local installation or cloud provider
- **Git**: For version control

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd saas-factory

# Run the setup script
./tools/scripts/setup.sh

# Or manually:
bun install
cp apps/api/.env.example apps/api/.env
cp apps/web/.env.example apps/web/.env
```

### 2. Configure Environment

Edit your environment files:

**apps/api/.env**:
```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/saas_factory_dev"
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
JWT_SECRET="your-super-secret-jwt-key"
```

**apps/web/.env**:
```env
VITE_API_URL="http://localhost:8787"
VITE_SUPABASE_URL="https://your-project.supabase.co"
VITE_SUPABASE_ANON_KEY="your-anon-key"
```

### 3. Database Setup

```bash
# Start PostgreSQL (if using Docker)
docker-compose up -d postgres

# Run migrations
bun run db:migrate

# Seed development data
bun run db:seed
```

### 4. Start Development

```bash
# Start all development servers
bun run dev

# Or use the script
./tools/scripts/dev.sh

# Or start individually:
# API server (http://localhost:8787)
cd apps/api && bun run dev

# Web server (http://localhost:3000)
cd apps/web && bun run dev
```

## Development Workflow

### Project Structure

```
saas-factory/
├── apps/
│   ├── web/                  # React frontend
│   └── api/                  # Hono.js backend
├── packages/
│   ├── ui/                   # Shared UI components
│   ├── types/                # TypeScript types
│   ├── utils/                # Utilities
│   ├── auth/                 # Auth utilities
│   └── config/               # Shared config
├── tools/
│   ├── scripts/              # Development scripts
│   └── docker/               # Docker configurations
└── docs/                     # Documentation
```

### Available Scripts

**Root level**:
- `bun run dev` - Start all development servers
- `bun run build` - Build all packages
- `bun run test` - Run all tests
- `bun run lint` - Lint all code
- `bun run type-check` - Type check all packages
- `bun run clean` - Clean all build artifacts

**Database**:
- `bun run db:generate` - Generate Prisma client
- `bun run db:migrate` - Run database migrations
- `bun run db:seed` - Seed development data
- `bun run db:reset` - Reset database

**Helper scripts**:
- `./tools/scripts/setup.sh` - Initial project setup
- `./tools/scripts/dev.sh` - Start development servers
- `./tools/scripts/test.sh` - Run all tests
- `./tools/scripts/build.sh` - Build all packages

### Code Organization

#### Backend (apps/api)

```
apps/api/src/
├── index.ts              # Main application entry
├── middleware/           # Hono middleware
│   ├── auth.ts          # Authentication
│   ├── tenant.ts        # Multi-tenancy
│   ├── error.ts         # Error handling
│   └── rateLimit.ts     # Rate limiting
├── routes/              # API routes
│   ├── auth.ts          # Authentication endpoints
│   ├── users.ts         # User management
│   ├── organizations.ts # Organization management
│   ├── projects.ts      # Project management
│   ├── tasks.ts         # Task management
│   ├── subscriptions.ts # Billing & subscriptions
│   └── admin.ts         # Admin endpoints
└── test/                # Test files
```

#### Frontend (apps/web)

```
apps/web/src/
├── main.tsx             # Application entry
├── App.tsx              # Main app component
├── components/          # React components
│   ├── ui/              # Basic UI components
│   └── layout/          # Layout components
├── pages/               # Page components
│   ├── auth/            # Authentication pages
│   ├── dashboard/       # Dashboard
│   ├── projects/        # Project management
│   ├── tasks/           # Task management
│   ├── organization/    # Organization settings
│   └── settings/        # User settings
├── stores/              # Zustand stores
├── hooks/               # Custom React hooks
├── services/            # API services
└── test/                # Test files
```

### Testing

```bash
# Run all tests
bun test

# Run tests for specific package
cd packages/utils && bun test
cd apps/api && bun test
cd apps/web && bun test

# Run tests in watch mode
bun test --watch

# Run tests with coverage
bun test --coverage
```

### Linting and Formatting

```bash
# Lint all code
bun run lint

# Fix linting issues
bun run lint:fix

# Format code
bun run format

# Check formatting
bun run format:check
```

### Database Management

#### Migrations

```bash
# Create a new migration
cd apps/api
bunx prisma migrate dev --name migration_name

# Apply migrations
bun run db:migrate

# Deploy migrations to production
bun run db:migrate:deploy

# Reset database (development only)
bun run db:reset
```

#### Schema Changes

1. Edit `apps/api/prisma/schema.prisma`
2. Generate migration: `bunx prisma migrate dev`
3. Update seed data if needed: `apps/api/prisma/seed.ts`
4. Update TypeScript types if needed: `packages/types/src/index.ts`

### Adding New Features

#### 1. Backend API Endpoint

1. Add route to `apps/api/src/routes/`
2. Add validation schemas using Zod
3. Implement business logic
4. Add tests
5. Update API documentation

#### 2. Frontend Page/Component

1. Create component in `apps/web/src/components/` or `apps/web/src/pages/`
2. Add routing if needed
3. Create API service functions
4. Add state management if needed
5. Add tests

#### 3. Shared Package

1. Add functionality to appropriate package in `packages/`
2. Export from package index file
3. Add tests
4. Update dependent packages

### Environment Variables

#### API Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `SUPABASE_URL` | Supabase project URL | Yes |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Yes |
| `JWT_SECRET` | JWT signing secret | Yes |
| `STRIPE_SECRET_KEY` | Stripe secret key | No |
| `NODE_ENV` | Environment (development/production) | No |

#### Web Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `VITE_API_URL` | Backend API URL | Yes |
| `VITE_SUPABASE_URL` | Supabase project URL | Yes |
| `VITE_SUPABASE_ANON_KEY` | Supabase anonymous key | Yes |
| `VITE_STRIPE_PUBLISHABLE_KEY` | Stripe publishable key | No |

### Debugging

#### Backend Debugging

1. Add console.log statements or use debugger
2. Check Wrangler logs: `cd apps/api && bun run dev`
3. Use Prisma Studio: `bun run db:studio`

#### Frontend Debugging

1. Use browser developer tools
2. React Developer Tools extension
3. Check network requests in browser
4. Use Zustand devtools

### Deployment

See [Deployment Documentation](./06-deployment-infrastructure.md) for detailed deployment instructions.

### Troubleshooting

#### Common Issues

1. **Database connection errors**:
   - Check DATABASE_URL in .env
   - Ensure PostgreSQL is running
   - Verify database exists

2. **Supabase authentication errors**:
   - Check Supabase URL and keys
   - Verify Supabase project configuration

3. **Build errors**:
   - Clear node_modules: `rm -rf node_modules && bun install`
   - Clear build cache: `bun run clean`

4. **Type errors**:
   - Regenerate Prisma client: `bun run db:generate`
   - Check TypeScript configuration

#### Getting Help

1. Check the documentation in `docs/`
2. Review error messages carefully
3. Check the GitHub issues
4. Ask for help in team channels

### Best Practices

1. **Code Quality**:
   - Write tests for new features
   - Follow TypeScript best practices
   - Use ESLint and Prettier
   - Write meaningful commit messages

2. **Security**:
   - Never commit secrets to git
   - Use environment variables
   - Validate all inputs
   - Follow authentication best practices

3. **Performance**:
   - Optimize database queries
   - Use proper caching
   - Minimize bundle sizes
   - Monitor performance metrics

4. **Maintainability**:
   - Write clear documentation
   - Use consistent naming conventions
   - Keep functions small and focused
   - Refactor regularly
