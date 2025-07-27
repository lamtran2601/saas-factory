# SaaS Factory - System Architecture

## Architecture Overview

The SaaS Factory follows a modern, cloud-native architecture designed for scalability, maintainability, and developer productivity. The system is built using a TypeScript-first approach with a modern monorepo setup, leveraging Bun runtime and pnpm for optimal performance.

## High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │    │   Admin Panel   │    │  Mobile App     │
│ (Cloudflare     │    │   (React)       │    │   (Future)      │
│  Pages)         │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Gateway   │
                    │  (Cloudflare    │
                    │   Workers)      │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Hono.js API   │
                    │   (TypeScript)  │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Supabase Auth  │
                    │   & Database    │
                    │   (PostgreSQL)  │
                    └─────────────────┘
```

## Technology Stack

### Development Environment

- **Bun**: Fast JavaScript runtime, package manager, and monorepo orchestration
- **TypeScript**: End-to-end type safety across the monorepo
- **Bun Workspaces**: Native monorepo management without external tools
- **Bun Test**: Built-in testing framework

### Frontend Layer

- **React 18+**: Modern React with hooks and concurrent features
- **TypeScript**: Type safety and better developer experience
- **Vite**: Fast build tool and development server with esbuild
- **React Router**: Client-side routing with data loading
- **TanStack Query**: Server state management and caching
- **Zustand**: Lightweight client state management
- **Tailwind CSS**: Utility-first CSS framework
- **Radix UI**: Accessible, unstyled component primitives
- **React Hook Form**: Form handling with Zod validation

### Backend Layer

- **Hono.js**: Fast, lightweight web framework for Cloudflare Workers
- **TypeScript**: End-to-end type safety
- **Bun Build**: Fast bundling for production builds
- **Zod**: Runtime type validation and schema definition
- **Cloudflare Workers**: Serverless compute platform with Node.js compatibility

### Authentication & Database Layer

- **Supabase Auth**: Authentication only (login, registration, social providers)
- **Application-level Authorization**: Custom user management and permissions
- **PostgreSQL**: Standard PostgreSQL database (provider-agnostic)
- **Prisma**: Type-safe database ORM and query builder
- **Application-level Multi-tenancy**: Tenant isolation through application logic

### Infrastructure Layer

- **Cloudflare Pages**: Static site hosting for React app
- **Cloudflare Workers**: Serverless API hosting
- **PostgreSQL Provider**: Any managed PostgreSQL service (Neon, Railway, etc.)
- **Cloudflare KV**: Key-value storage for caching
- **Cloudflare R2**: Object storage for files

## Monorepo Structure

### Bun Workspace Organization

```
saas-factory/
├── apps/
│   ├── web/                 # React frontend application
│   ├── api/                 # Hono.js backend API
│   └── admin/               # Admin dashboard (future)
├── packages/
│   ├── ui/                  # Shared UI components
│   ├── types/               # Shared TypeScript types
│   ├── config/              # Shared configuration
│   ├── utils/               # Shared utilities
│   └── auth/                # Portable auth utilities
├── tools/
│   ├── scripts/             # Development and build scripts
│   └── configs/             # Shared configurations
├── docs/                    # Documentation
├── package.json             # Root package.json with Bun workspaces
├── bun.lockb               # Bun lockfile
└── bunfig.toml             # Bun configuration
```

## Core Components

### 1. API Layer (Hono.js)

#### Structure

```
apps/api/src/
├── routes/
│   ├── auth.ts          # Supabase Auth integration
│   ├── users.ts         # User management
│   ├── organizations.ts # Multi-tenant organization management
│   ├── subscriptions.ts # Billing and subscription management
│   └── admin.ts         # Admin-only endpoints
├── middleware/
│   ├── auth.ts          # Supabase Auth middleware
│   ├── cors.ts          # CORS configuration
│   ├── rateLimit.ts     # Rate limiting
│   └── validation.ts    # Request validation
├── services/
│   ├── supabase.ts      # Supabase client configuration
│   ├── user.service.ts  # User management logic
│   └── billing.service.ts # Subscription management
└── utils/
    ├── database.ts      # Database utilities
    ├── crypto.ts        # Encryption utilities
    └── email.ts         # Email service integration
```

#### Key Features

- **Supabase Integration**: Built-in authentication and RLS
- **Middleware pipeline**: Authentication, validation, rate limiting
- **Error handling**: Centralized error management
- **Request validation**: Zod schema validation
- **Response formatting**: Consistent API responses
- **Logging**: Structured logging for debugging and monitoring

### 2. Database Layer (PostgreSQL + Prisma)

#### Application-Level Multi-Tenancy Strategy

- **Standard PostgreSQL**: Any managed PostgreSQL provider (Neon, Railway, Supabase, etc.)
- **Application-level isolation**: Tenant filtering through application logic
- **Portable schema**: No vendor-specific extensions or functions
- **Middleware-based security**: Authentication and authorization in application layer

#### Schema Structure

```sql
-- Core tables (shared across tenants)
users                    # User profiles (extends Supabase Auth)
organizations           # Multi-tenant organizations
organization_members    # User-organization relationships
subscriptions          # Billing and subscription data
audit_logs             # System-wide audit trail

-- Tenant-specific tables (with organization_id filtering)
projects               # Organization projects
tasks                  # Project tasks
settings               # Organization settings
files                  # File metadata (actual files in object storage)
```

### 3. Frontend Layer (React)

#### Application Structure

```
apps/web/src/
├── components/
│   ├── ui/              # Shared UI components from packages/ui
│   ├── forms/           # Form components with React Hook Form
│   └── layout/          # Layout components
├── pages/
│   ├── auth/            # Authentication pages (Supabase Auth)
│   ├── dashboard/       # Main application pages
│   └── admin/           # Admin panel pages
├── hooks/
│   ├── useAuth.ts       # Supabase Auth hook
│   ├── useApi.ts        # API interaction hook
│   └── useSubscription.ts # Subscription management
├── services/
│   ├── supabase.ts      # Supabase client configuration
│   ├── api.ts           # API client configuration
│   └── storage.ts       # Local storage utilities
└── utils/
    ├── constants.ts     # Application constants
    ├── helpers.ts       # Utility functions
    └── types.ts         # TypeScript type definitions (from packages/types)
```

#### State Management

- **TanStack Query**: Server state management and caching
- **Zustand**: Lightweight client state management
- **WebSockets/SSE**: Real-time updates (provider-agnostic)
- **React Hook Form**: Form state with Zod validation
- **URL State**: Router-based state management

## Security Architecture

### Hybrid Authentication Flow

1. **User Registration/Login**: Supabase Auth for authentication only
2. **Session Management**: Supabase handles JWT tokens and refresh tokens
3. **Client Integration**: Supabase client manages authentication state
4. **API Authentication**: Supabase JWT tokens validated by middleware
5. **Application Authorization**: Custom authorization logic in application layer

### Social Authentication Providers

- **Google**: OAuth 2.0 integration via Supabase Auth
- **GitHub**: OAuth 2.0 integration via Supabase Auth
- **Microsoft**: OAuth 2.0 integration via Supabase Auth
- **Custom SAML**: Enterprise SSO support (future)

### Authorization Levels

- **Public**: No authentication required
- **Authenticated**: Valid Supabase session required
- **Organization Member**: User must belong to organization (application-enforced)
- **Organization Admin**: Admin role within organization (application-enforced)
- **System Admin**: Global admin privileges (application-enforced)

### Data Security

- **Application-level filtering**: Multi-tenancy enforced by application logic
- **Encryption at rest**: Database provider managed encryption
- **Encryption in transit**: HTTPS/TLS for all communications
- **Input validation**: Zod schemas for all inputs
- **SQL injection prevention**: Prisma ORM parameterized queries
- **XSS prevention**: Content Security Policy headers
- **Tenant isolation**: Middleware ensures proper organization context

## Scalability Considerations

### Horizontal Scaling

- **Stateless API**: No server-side sessions
- **Database connection pooling**: Efficient connection management
- **CDN integration**: Global content delivery
- **Caching strategy**: Multi-layer caching approach

### Performance Optimization

- **Code splitting**: Lazy loading of React components
- **Image optimization**: Automatic image compression and resizing
- **Bundle optimization**: Tree shaking and minification
- **Database indexing**: Optimized query performance

### Monitoring & Observability

- **Application metrics**: Response times, error rates
- **Business metrics**: User engagement, subscription metrics
- **Infrastructure metrics**: CPU, memory, database performance
- **Logging**: Structured logging with correlation IDs

## Deployment Architecture

### Cloudflare Integration

- **Pages**: Static React app deployment
- **Workers**: Serverless API deployment
- **D1/External DB**: Database hosting options
- **KV Store**: Caching and session storage
- **R2**: File and media storage

### CI/CD Pipeline

- **GitHub Actions**: Automated testing and deployment
- **Environment promotion**: Dev → Staging → Production
- **Database migrations**: Automated schema updates
- **Rollback strategy**: Quick rollback capabilities

## Development Workflow

### Local Development with Bun

1. **Runtime**: Bun for fast package installation, script execution, and testing
2. **Package management**: Bun's built-in package manager for all dependencies
3. **Database setup**: Any PostgreSQL provider or local Docker PostgreSQL
4. **API development**: Hono.js with Wrangler dev server
5. **Frontend development**: Vite dev server with Bun build
6. **Testing**: Bun test runner for unit tests, Playwright for E2E

### Monorepo Management with Bun

- **Bun Workspaces**: Native workspace management without external tools
- **Bun Scripts**: Fast script execution across workspaces
- **Shared packages**: Reusable code across applications
- **Parallel execution**: Built-in parallel task execution

### Code Quality

- **TypeScript**: Strict type checking across monorepo
- **ESLint**: Shared linting configuration
- **Prettier**: Consistent code formatting
- **Husky**: Git hooks for quality gates
- **Testing**: Bun test for unit tests, Playwright for E2E
- **Type safety**: End-to-end type safety with shared types package

### Vendor Lock-in Prevention

- **Portable database schema**: Standard PostgreSQL without vendor extensions
- **Provider-agnostic auth**: Supabase Auth with application-level authorization
- **Standard APIs**: RESTful APIs that work with any client
- **Configurable storage**: Support for multiple object storage providers
- **Database flexibility**: Easy migration between PostgreSQL providers

This architecture provides a high-performance, vendor-agnostic foundation for building scalable SaaS applications with excellent developer experience and maximum portability.
