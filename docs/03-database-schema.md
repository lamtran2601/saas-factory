# SaaS Factory - Database Schema Design

## Overview

The database schema is designed for multi-tenancy using **application-level tenant isolation with standard PostgreSQL**. This approach provides maximum portability across PostgreSQL providers while maintaining security and performance.

## Multi-Tenancy Strategy

### Approach: Application-Level Tenant Isolation

- **Standard PostgreSQL**: Compatible with any PostgreSQL provider (Neon, Railway, Supabase, etc.)
- **Application-level filtering**: Tenant isolation enforced by application middleware
- **Portable schema**: No vendor-specific extensions or functions
- **Shared tables with filtering**: All tables use organization_id for tenant separation
- **Provider flexibility**: Easy migration between PostgreSQL providers

### Benefits

- **Provider agnostic**: Works with any PostgreSQL service
- **No vendor lock-in**: Standard SQL schema without proprietary features
- **Flexible deployment**: Can run on self-hosted or managed PostgreSQL
- **Cost efficient**: Single database instance with application-level isolation
- **Excellent portability**: Easy to migrate between providers
- **Scalable**: Can scale with any PostgreSQL provider's infrastructure

## Core Schema with Portable Design

### Users Table (Extends Supabase Auth)

```sql
-- User profiles table that extends Supabase Auth users
-- Uses standard PostgreSQL without vendor-specific features
CREATE TABLE users (
  id UUID PRIMARY KEY, -- References Supabase Auth user ID
  email VARCHAR(255) UNIQUE NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar_url TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Standard indexes (no vendor-specific features)
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_login ON users(last_login_at);
```

### Organizations Table

```sql
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  domain VARCHAR(255),
  logo_url TEXT,
  settings JSONB DEFAULT '{}',
  plan_id UUID REFERENCES subscription_plans(id),
  status VARCHAR(50) DEFAULT 'active',
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Standard indexes (no RLS policies - handled by application)
CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_domain ON organizations(domain);
CREATE INDEX idx_organizations_status ON organizations(status);
CREATE INDEX idx_organizations_created_by ON organizations(created_by);
```

### Organization Members Table

```sql
CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'member',
  permissions JSONB DEFAULT '[]',
  invited_by UUID REFERENCES users(id),
  invited_at TIMESTAMP,
  joined_at TIMESTAMP,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(organization_id, user_id)
);

-- Standard indexes (authorization handled by application middleware)
CREATE INDEX idx_org_members_org_id ON organization_members(organization_id);
CREATE INDEX idx_org_members_user_id ON organization_members(user_id);
CREATE INDEX idx_org_members_role ON organization_members(role);
CREATE INDEX idx_org_members_status ON organization_members(status);
```

### Subscription Plans Table

```sql
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  price_monthly DECIMAL(10,2),
  price_yearly DECIMAL(10,2),
  features JSONB DEFAULT '[]',
  limits JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Subscriptions Table

```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),
  stripe_subscription_id VARCHAR(255),
  status VARCHAR(50) NOT NULL,
  current_period_start TIMESTAMP,
  current_period_end TIMESTAMP,
  trial_start TIMESTAMP,
  trial_end TIMESTAMP,
  canceled_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_subscriptions_org_id ON subscriptions(organization_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_stripe_id ON subscriptions(stripe_subscription_id);
```

### API Keys Table

```sql
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  key_hash VARCHAR(255) NOT NULL,
  key_prefix VARCHAR(20) NOT NULL,
  permissions JSONB DEFAULT '[]',
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_api_keys_org_id ON api_keys(organization_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
```

### Audit Logs Table

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id),
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(100),
  resource_id UUID,
  details JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_audit_logs_org_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
```

## Tenant-Specific Tables with Application-Level Filtering

All tenant-specific tables use organization_id for filtering, with isolation enforced by application middleware:

### Projects Table (Example)

```sql
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'active',
  settings JSONB DEFAULT '{}',
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Standard indexes (tenant isolation handled by application)
CREATE INDEX idx_projects_org_id ON projects(organization_id);
CREATE INDEX idx_projects_created_by ON projects(created_by);
CREATE INDEX idx_projects_status ON projects(status);
```

### Tasks Table (Example)

```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'todo',
  priority VARCHAR(20) DEFAULT 'medium',
  assigned_to UUID REFERENCES users(id),
  due_date TIMESTAMP,
  completed_at TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Standard indexes (tenant isolation handled by application)
CREATE INDEX idx_tasks_org_id ON tasks(organization_id);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
```

## Prisma Schema Definition

```prisma
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// User profiles table that extends Supabase Auth
// Uses standard PostgreSQL schema
model User {
  id            String   @id @db.Uuid
  email         String   @unique
  firstName     String?  @map("first_name")
  lastName      String?  @map("last_name")
  avatarUrl     String?  @map("avatar_url")
  emailVerified Boolean  @default(false) @map("email_verified")
  lastLoginAt   DateTime? @map("last_login_at")
  createdAt     DateTime @default(now()) @map("created_at")
  updatedAt     DateTime @default(now()) @updatedAt @map("updated_at")

  // Relations
  organizationMembers  OrganizationMember[]
  createdOrganizations Organization[]
  createdApiKeys       ApiKey[]
  auditLogs           AuditLog[]
  createdProjects     Project[]
  assignedTasks       Task[]
  createdTasks        Task[] @relation("TaskCreator")

  @@map("users")
}

model Organization {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name      String
  slug      String   @unique
  domain    String?
  logoUrl   String?  @map("logo_url")
  settings  Json     @default("{}")
  planId    String?  @map("plan_id") @db.Uuid
  status    String   @default("active")
  createdBy String   @map("created_by") @db.Uuid
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @default(now()) @updatedAt @map("updated_at")

  // Relations
  creator       User                 @relation(fields: [createdBy], references: [id])
  members       OrganizationMember[]
  subscriptions Subscription[]
  apiKeys       ApiKey[]
  auditLogs     AuditLog[]
  projects      Project[]
  tasks         Task[]
  plan          SubscriptionPlan?    @relation(fields: [planId], references: [id])

  @@map("organizations")
}

model OrganizationMember {
  id             String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String    @map("organization_id") @db.Uuid
  userId         String    @map("user_id") @db.Uuid
  role           String    @default("member")
  permissions    Json      @default("[]")
  invitedBy      String?   @map("invited_by") @db.Uuid
  invitedAt      DateTime? @map("invited_at")
  joinedAt       DateTime? @map("joined_at")
  status         String    @default("active")
  createdAt      DateTime  @default(now()) @map("created_at")
  updatedAt      DateTime  @default(now()) @updatedAt @map("updated_at")

  // Relations
  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  user         User         @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([organizationId, userId])
  @@map("organization_members")
}

model SubscriptionPlan {
  id           String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  name         String
  description  String?
  priceMonthly Decimal? @map("price_monthly") @db.Decimal(10, 2)
  priceYearly  Decimal? @map("price_yearly") @db.Decimal(10, 2)
  features     Json     @default("[]")
  limits       Json     @default("{}")
  isActive     Boolean  @default(true) @map("is_active")
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @default(now()) @updatedAt @map("updated_at")

  // Relations
  organizations Organization[]
  subscriptions Subscription[]

  @@map("subscription_plans")
}

model Subscription {
  id                   String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId       String    @map("organization_id") @db.Uuid
  planId               String    @map("plan_id") @db.Uuid
  stripeSubscriptionId String?   @map("stripe_subscription_id")
  status               String
  currentPeriodStart   DateTime? @map("current_period_start")
  currentPeriodEnd     DateTime? @map("current_period_end")
  trialStart           DateTime? @map("trial_start")
  trialEnd             DateTime? @map("trial_end")
  canceledAt           DateTime? @map("canceled_at")
  createdAt            DateTime  @default(now()) @map("created_at")
  updatedAt            DateTime  @default(now()) @updatedAt @map("updated_at")

  // Relations
  organization Organization     @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  plan         SubscriptionPlan @relation(fields: [planId], references: [id])

  @@map("subscriptions")
}

model ApiKey {
  id             String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String    @map("organization_id") @db.Uuid
  name           String
  keyHash        String    @map("key_hash")
  keyPrefix      String    @map("key_prefix")
  permissions    Json      @default("[]")
  lastUsedAt     DateTime? @map("last_used_at")
  expiresAt      DateTime? @map("expires_at")
  isActive       Boolean   @default(true) @map("is_active")
  createdBy      String?   @map("created_by") @db.Uuid
  createdAt      DateTime  @default(now()) @map("created_at")
  updatedAt      DateTime  @default(now()) @updatedAt @map("updated_at")

  // Relations
  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  creator      User?        @relation(fields: [createdBy], references: [id])

  @@map("api_keys")
}

model AuditLog {
  id             String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String?   @map("organization_id") @db.Uuid
  userId         String?   @map("user_id") @db.Uuid
  action         String
  resourceType   String?   @map("resource_type")
  resourceId     String?   @map("resource_id") @db.Uuid
  details        Json      @default("{}")
  ipAddress      String?   @map("ip_address")
  userAgent      String?   @map("user_agent")
  createdAt      DateTime  @default(now()) @map("created_at")

  // Relations
  organization Organization? @relation(fields: [organizationId], references: [id])
  user         Profile?      @relation(fields: [userId], references: [id])

  @@map("audit_logs")
}

// Tenant-specific models with RLS
model Project {
  id             String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String   @map("organization_id") @db.Uuid
  name           String
  description    String?
  status         String   @default("active")
  settings       Json     @default("{}")
  createdBy      String   @map("created_by") @db.Uuid
  createdAt      DateTime @default(now()) @map("created_at")
  updatedAt      DateTime @default(now()) @updatedAt @map("updated_at")

  // Relations
  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  creator      Profile      @relation(fields: [createdBy], references: [id])
  tasks        Task[]

  @@map("projects")
}

model Task {
  id             String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  organizationId String    @map("organization_id") @db.Uuid
  projectId      String?   @map("project_id") @db.Uuid
  title          String
  description    String?
  status         String    @default("todo")
  priority       String    @default("medium")
  assignedTo     String?   @map("assigned_to") @db.Uuid
  dueDate        DateTime? @map("due_date")
  completedAt    DateTime? @map("completed_at")
  createdBy      String    @map("created_by") @db.Uuid
  createdAt      DateTime  @default(now()) @map("created_at")
  updatedAt      DateTime  @default(now()) @updatedAt @map("updated_at")

  // Relations
  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  project      Project?     @relation(fields: [projectId], references: [id], onDelete: Cascade)
  assignee     Profile?     @relation(fields: [assignedTo], references: [id])
  creator      Profile      @relation("TaskCreator", fields: [createdBy], references: [id])

  @@map("tasks")
}
```

## Migration Strategy with Portable PostgreSQL

### Initial Setup

1. **PostgreSQL provider setup**: Choose any PostgreSQL provider (Neon, Railway, Supabase, etc.)
2. **Database connection**: Configure standard PostgreSQL connection string
3. **Run Prisma migrations**: Apply schema to PostgreSQL database
4. **Configure Auth**: Set up Supabase Auth for authentication only
5. **Seed data**: Default subscription plans and initial data

### Provider-Agnostic Integration Steps

1. **Database URL**: Configure standard PostgreSQL connection string
2. **Auth integration**: Set up Supabase Auth in frontend and API (authentication only)
3. **Application middleware**: Implement tenant filtering in application layer
4. **Real-time alternatives**: Use WebSockets or Server-Sent Events for real-time features
5. **Storage setup**: Configure object storage (Cloudflare R2, AWS S3, etc.)

### Schema Evolution

1. **Prisma migrations**: Standard Prisma migration workflow
2. **Application logic updates**: Update middleware when schema changes
3. **Provider dashboard**: Monitor via your PostgreSQL provider's dashboard
4. **Testing**: Validate migrations on staging database
5. **Rollback strategy**: Database backups and migration rollbacks

### Development Workflow

1. **Local development**: Use local PostgreSQL or any cloud provider
2. **Schema changes**: Update Prisma schema and generate migrations
3. **Middleware testing**: Test tenant isolation with different user contexts
4. **Provider flexibility**: Easy switching between PostgreSQL providers

### Vendor Lock-in Prevention

1. **Standard SQL**: No vendor-specific extensions or functions
2. **Portable schema**: Works with any PostgreSQL provider
3. **Application-level logic**: Authorization and multi-tenancy in application layer
4. **Provider flexibility**: Easy migration between database providers
5. **Open standards**: Uses standard PostgreSQL features only

This portable schema design provides a vendor-agnostic foundation for multi-tenant SaaS applications with maximum flexibility and no vendor lock-in.
