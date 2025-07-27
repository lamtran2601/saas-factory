# SaaS Factory - API Design & Endpoints

## API Overview

The API follows RESTful principles with a focus on consistency, security, and developer experience. Built with Hono.js for Cloudflare Workers and integrated with Supabase Auth, it provides fast, scalable endpoints with built-in authentication and multi-tenancy support.

## Base URL Structure

```
Production:  https://api.saas-factory.com
Staging:     https://api-staging.saas-factory.com
Development: http://localhost:8787
```

## Authentication

### Hybrid Authentication Strategy

- **Header**: `Authorization: Bearer <supabase_jwt_token>`
- **Authentication**: Handled by Supabase Auth (login, registration, social providers)
- **Authorization**: Handled by application logic (permissions, roles, multi-tenancy)
- **Token refresh**: Automatic refresh via Supabase client
- **User context**: Extracted from JWT and managed by application middleware
- **Social providers**: Google, GitHub, Microsoft OAuth via Supabase Auth

### API Key Authentication (Alternative)

- **Header**: `X-API-Key: <api_key>`
- **Format**: `sf_live_<random>` or `sf_test_<random>`
- **Scoped permissions**: Organization-level access control
- **Rate limiting**: Per API key limits

## Request/Response Format

### Standard Response Structure

```json
{
  "success": true,
  "data": {}, // or [] for arrays
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Error Response Structure

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "issue": "Invalid email format"
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Core API Endpoints

### Authentication Endpoints

**Note**: Most authentication is handled directly by Supabase Auth on the frontend. These endpoints provide additional functionality and integration points.

#### GET /auth/session

Validate current Supabase session and return user context.

**Headers:**

```
Authorization: Bearer <supabase_jwt_token>
```

**Response:**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "emailVerified": true
    },
    "profile": {
      "firstName": "John",
      "lastName": "Doe",
      "avatarUrl": "https://..."
    },
    "organizations": [
      {
        "id": "uuid",
        "name": "Acme Corp",
        "role": "admin"
      }
    ]
  }
}
```

#### POST /auth/callback

Handle OAuth callbacks and create user profiles.

**Request Body:**

```json
{
  "supabaseSession": {
    "access_token": "...",
    "user": { ... }
  }
}
```

#### POST /auth/profile

Create or update user profile after Supabase Auth registration.

**Request Body:**

```json
{
  "firstName": "John",
  "lastName": "Doe",
  "avatarUrl": "https://..."
}
```

### User Management Endpoints

#### GET /users/me

Get current user profile.

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "avatarUrl": "https://...",
    "emailVerified": true,
    "lastLoginAt": "2024-01-15T10:30:00Z",
    "organizations": [
      {
        "id": "uuid",
        "name": "Acme Corp",
        "role": "admin",
        "permissions": ["read", "write", "admin"]
      }
    ]
  }
}
```

#### PUT /users/me

Update current user profile.

#### POST /users/me/avatar

Upload user avatar image.

#### POST /users/me/change-password

Change user password.

### Organization Management Endpoints

#### GET /organizations

List user's organizations.

**Query Parameters:**

- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)
- `search`: Search by name

#### POST /organizations

Create new organization.

**Request Body:**

```json
{
  "name": "Acme Corporation",
  "slug": "acme-corp",
  "domain": "acme.com"
}
```

#### GET /organizations/:id

Get organization details.

#### PUT /organizations/:id

Update organization.

#### DELETE /organizations/:id

Delete organization (admin only).

### Organization Members Endpoints

#### GET /organizations/:id/members

List organization members.

#### POST /organizations/:id/members/invite

Invite new member.

**Request Body:**

```json
{
  "email": "newuser@example.com",
  "role": "member",
  "permissions": ["read", "write"]
}
```

#### PUT /organizations/:id/members/:userId

Update member role/permissions.

#### DELETE /organizations/:id/members/:userId

Remove member from organization.

### Subscription Management Endpoints

#### GET /organizations/:id/subscription

Get current subscription details.

**Response:**

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "plan": {
      "id": "uuid",
      "name": "Professional",
      "priceMonthly": 29.99,
      "features": ["feature1", "feature2"]
    },
    "status": "active",
    "currentPeriodEnd": "2024-02-15T00:00:00Z",
    "usage": {
      "users": 5,
      "projects": 12,
      "storage": "2.5GB"
    },
    "limits": {
      "users": 10,
      "projects": 50,
      "storage": "10GB"
    }
  }
}
```

#### POST /organizations/:id/subscription/upgrade

Upgrade subscription plan.

#### POST /organizations/:id/subscription/cancel

Cancel subscription.

#### GET /subscription-plans

List available subscription plans.

### API Key Management Endpoints

#### GET /organizations/:id/api-keys

List organization API keys.

#### POST /organizations/:id/api-keys

Create new API key.

**Request Body:**

```json
{
  "name": "Production API Key",
  "permissions": ["read", "write"],
  "expiresAt": "2024-12-31T23:59:59Z"
}
```

#### PUT /organizations/:id/api-keys/:keyId

Update API key.

#### DELETE /organizations/:id/api-keys/:keyId

Revoke API key.

### Tenant-Specific Endpoints

#### Projects (Example)

#### GET /organizations/:id/projects

List organization projects.

#### POST /organizations/:id/projects

Create new project.

#### GET /organizations/:id/projects/:projectId

Get project details.

#### PUT /organizations/:id/projects/:projectId

Update project.

#### DELETE /organizations/:id/projects/:projectId

Delete project.

### Admin Endpoints

#### GET /admin/organizations

List all organizations (system admin only).

#### GET /admin/users

List all users (system admin only).

#### GET /admin/subscriptions

List all subscriptions (system admin only).

#### GET /admin/metrics

Get system metrics and analytics.

## Middleware Pipeline

### 1. CORS Middleware

```typescript
app.use(
  "*",
  cors({
    origin: ["https://app.saas-factory.com", "http://localhost:3000"],
    credentials: true,
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization", "X-API-Key"],
  })
);
```

### 2. Rate Limiting Middleware

```typescript
app.use(
  "*",
  rateLimiter({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    keyGenerator: (c) => c.req.header("x-forwarded-for") || "anonymous",
  })
);
```

### 3. Hybrid Authentication Middleware

```typescript
import { createClient } from "@supabase/supabase-js";
import { prisma } from "./db";

app.use("/api/*", async (c, next) => {
  const token = c.req.header("Authorization")?.replace("Bearer ", "");
  const apiKey = c.req.header("X-API-Key");

  if (token) {
    // Supabase JWT authentication (authentication only)
    const supabase = createClient(c.env.SUPABASE_URL, c.env.SUPABASE_ANON_KEY);

    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);

    if (error || !user) {
      return c.json({ error: "Unauthorized" }, 401);
    }

    // Get user profile from our database (application-level data)
    const userProfile = await prisma.user.findUnique({
      where: { id: user.id },
      include: {
        organizationMembers: {
          include: {
            organization: true,
          },
        },
      },
    });

    c.set("user", user);
    c.set("userProfile", userProfile);
    c.set("supabaseToken", token);
  } else if (apiKey) {
    // API key authentication
    const keyData = await validateApiKey(apiKey);
    c.set("organizationId", keyData.organizationId);
    c.set("apiKeyPermissions", keyData.permissions);
  } else {
    return c.json({ error: "Unauthorized" }, 401);
  }

  await next();
});
```

### 4. Application-Level Tenant Context Middleware

```typescript
app.use("/organizations/:id/*", async (c, next) => {
  const orgId = c.req.param("id");
  const user = c.get("user");
  const userProfile = c.get("userProfile");

  // Verify user belongs to organization using application logic
  const membership = userProfile?.organizationMembers.find(
    (member) => member.organizationId === orgId
  );

  if (!membership) {
    return c.json({ error: "Forbidden" }, 403);
  }

  // Set organization context for all subsequent queries
  c.set("organizationId", orgId);
  c.set("userRole", membership.role);
  c.set("userPermissions", membership.permissions);

  await next();
});

// Prisma middleware to automatically filter by organization
const prismaWithTenantFilter = (organizationId: string) => {
  return prisma.$extends({
    query: {
      $allModels: {
        async findMany({ args, query }) {
          args.where = { ...args.where, organizationId };
          return query(args);
        },
        async findFirst({ args, query }) {
          args.where = { ...args.where, organizationId };
          return query(args);
        },
        async findUnique({ args, query }) {
          args.where = { ...args.where, organizationId };
          return query(args);
        },
      },
    },
  });
};
```

### 5. Validation Middleware

```typescript
import { z } from "zod";

const validateBody = (schema: z.ZodSchema) => {
  return async (c: Context, next: Next) => {
    try {
      const body = await c.req.json();
      const validatedData = schema.parse(body);
      c.set("validatedData", validatedData);
      await next();
    } catch (error) {
      return c.json(
        {
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Invalid request data",
            details: error.errors,
          },
        },
        400
      );
    }
  };
};
```

## Error Handling

### Standard Error Codes

- `VALIDATION_ERROR`: Invalid input data
- `AUTHENTICATION_ERROR`: Invalid or missing authentication
- `AUTHORIZATION_ERROR`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `SUBSCRIPTION_REQUIRED`: Feature requires paid subscription
- `INTERNAL_ERROR`: Server error

### Error Response Examples

```json
{
  "success": false,
  "error": {
    "code": "SUBSCRIPTION_REQUIRED",
    "message": "This feature requires a paid subscription",
    "details": {
      "feature": "advanced_analytics",
      "requiredPlan": "professional"
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## API Versioning

### URL Versioning

- Current: `/api/v1/...`
- Future: `/api/v2/...`

### Backward Compatibility

- Maintain previous versions for 12 months
- Deprecation notices in response headers
- Migration guides for breaking changes

## Rate Limiting

### Limits by Authentication Type

- **Unauthenticated**: 100 requests/hour
- **Authenticated users**: 1000 requests/hour
- **API keys**: Based on subscription plan
- **Admin users**: 10000 requests/hour

### Rate Limit Headers

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642248000
```

This API design provides a comprehensive, scalable foundation for the SaaS Factory platform with proper authentication, multi-tenancy, and developer experience considerations.
