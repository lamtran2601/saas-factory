# SaaS Factory

A comprehensive SaaS platform foundation built with modern TypeScript stack, designed for rapid development and deployment of Software as a Service applications.

## 🚀 Features

- **Multi-tenant Architecture** - Support for multiple customers/organizations
- **Authentication & Authorization** - User management with role-based access control
- **Billing & Subscription Management** - Integrated payment processing with Stripe
- **API-first Design** - RESTful APIs for all functionality
- **Modern Tech Stack** - TypeScript, React, Hono.js, PostgreSQL, Cloudflare
- **Vendor Lock-in Prevention** - Portable architecture with standard technologies

## 🏗️ Architecture

### Tech Stack

- **Frontend**: React 18+ with Vite, TypeScript, Tailwind CSS, Radix UI
- **Backend**: Hono.js on Cloudflare Workers, TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: Supabase Auth (easily replaceable)
- **Deployment**: Cloudflare Pages + Workers
- **Package Manager**: Bun with workspaces

### Project Structure

```
saas-factory/
├── apps/
│   ├── web/                  # React frontend application
│   └── api/                  # Hono.js backend API
├── packages/
│   ├── ui/                   # Shared UI components
│   ├── types/                # Shared TypeScript types
│   ├── utils/                # Shared utilities
│   ├── auth/                 # Portable auth utilities
│   └── config/               # Shared configuration
├── docs/                     # Documentation
└── tools/                    # Development tools and scripts
```

## 🛠️ Development Setup

### Prerequisites

- **Bun**: Version 1.0.x or higher
- **Node.js**: Version 18.x or higher
- **PostgreSQL**: Local or cloud provider

### Quick Start

1. **Clone and install dependencies**:
   ```bash
   git clone <repository-url>
   cd saas-factory
   bun install
   ```

2. **Setup environment variables**:
   ```bash
   cp apps/api/.env.example apps/api/.env
   cp apps/web/.env.example apps/web/.env
   # Edit the .env files with your configuration
   ```

3. **Setup database**:
   ```bash
   # Run database migrations
   bun run db:migrate
   
   # Generate Prisma client
   bun run db:generate
   
   # Seed development data
   bun run db:seed
   ```

4. **Start development servers**:
   ```bash
   # Start all services
   bun run dev
   
   # Or start individually:
   # Frontend: http://localhost:3000
   # Backend: http://localhost:8787
   ```

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

- [Project Analysis](docs/01-project-analysis.md) - Overview and requirements
- [Architecture](docs/02-architecture.md) - System architecture and design
- [Database Schema](docs/03-database-schema.md) - Database design and models
- [API Design](docs/04-api-design.md) - API endpoints and specifications
- [Frontend Structure](docs/05-frontend-structure.md) - React application architecture
- [Deployment](docs/06-deployment-infrastructure.md) - Deployment and infrastructure
- [Development Roadmap](docs/07-development-roadmap.md) - Implementation timeline
- [Project Setup](docs/08-project-setup.md) - Detailed setup instructions
- [Vendor Lock-in Prevention](docs/09-vendor-lockin-prevention.md) - Portability strategy
- [Current Development Plan](docs/10-current-development-plan.md) - Next steps and priorities

## 🧪 Testing

```bash
# Run all tests
bun test

# Run unit tests
bun run test:unit

# Run integration tests
bun run test:integration

# Run E2E tests
bun run test:e2e
```

## 🔧 Available Scripts

- `bun run dev` - Start development servers
- `bun run build` - Build all packages
- `bun run lint` - Lint all code
- `bun run type-check` - Type check all packages
- `bun run db:migrate` - Run database migrations
- `bun run db:seed` - Seed development data
- `bun run clean` - Clean all build artifacts

## 🚀 Deployment

The application is designed to deploy on Cloudflare's edge platform:

- **Frontend**: Cloudflare Pages
- **Backend**: Cloudflare Workers
- **Database**: Any PostgreSQL provider (Neon, Railway, Supabase, etc.)

See [Deployment Documentation](docs/06-deployment-infrastructure.md) for detailed instructions.

## 🔒 Security

- JWT-based authentication with Supabase Auth
- Application-level multi-tenancy and authorization
- Input validation with Zod schemas
- CORS and security headers configured
- Rate limiting and abuse prevention

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- Check the [documentation](docs/) for detailed guides
- Review [troubleshooting](docs/08-project-setup.md#troubleshooting) section
- Open an issue for bugs or feature requests

---

Built with ❤️ using modern web technologies for maximum developer productivity and application performance.
