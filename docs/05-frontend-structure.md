# SaaS Factory - Frontend Structure Planning

## Overview

The frontend is built with React 18+ using modern patterns and tools for optimal developer experience and performance. The architecture emphasizes component reusability, type safety, and scalable state management.

## Technology Stack

### Core Framework
- **React 18+**: Latest React with concurrent features
- **TypeScript**: Strict type checking throughout
- **Vite**: Fast build tool and development server
- **React Router v6**: Modern routing with data loading

### UI & Styling
- **Tailwind CSS**: Utility-first CSS framework
- **Radix UI**: Accessible, unstyled component primitives
- **Lucide React**: Beautiful, customizable icons
- **Framer Motion**: Smooth animations and transitions

### State Management
- **TanStack Query**: Server state management and caching
- **Zustand**: Lightweight client state management
- **React Hook Form**: Form state and validation
- **Zod**: Runtime type validation

### Development Tools
- **ESLint**: Code linting and quality
- **Prettier**: Code formatting
- **Husky**: Git hooks for quality gates
- **Vitest**: Unit testing framework
- **Playwright**: End-to-end testing

## Project Structure

```
src/
├── components/           # Reusable UI components
│   ├── ui/              # Base UI components (buttons, inputs, etc.)
│   ├── forms/           # Form-specific components
│   ├── layout/          # Layout components (header, sidebar, etc.)
│   └── features/        # Feature-specific components
├── pages/               # Route components
│   ├── auth/           # Authentication pages
│   ├── dashboard/      # Main application pages
│   ├── settings/       # Settings and configuration
│   └── admin/          # Admin panel pages
├── hooks/               # Custom React hooks
│   ├── api/            # API-related hooks
│   ├── auth/           # Authentication hooks
│   └── utils/          # Utility hooks
├── services/            # External service integrations
│   ├── api.ts          # API client configuration
│   ├── auth.ts         # Authentication service
│   └── storage.ts      # Local storage utilities
├── stores/              # Zustand stores
│   ├── auth.ts         # Authentication state
│   ├── ui.ts           # UI state (modals, notifications)
│   └── organization.ts # Organization context
├── utils/               # Utility functions
│   ├── constants.ts    # Application constants
│   ├── helpers.ts      # Helper functions
│   ├── types.ts        # TypeScript type definitions
│   └── validations.ts  # Zod validation schemas
├── styles/              # Global styles and themes
│   ├── globals.css     # Global CSS and Tailwind imports
│   └── components.css  # Component-specific styles
└── assets/              # Static assets
    ├── images/         # Image files
    └── icons/          # Custom icon files
```

## Component Architecture

### UI Component Library

#### Base Components (`components/ui/`)
```typescript
// Button component with variants
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  children: React.ReactNode
}

// Input component with validation
interface InputProps {
  label?: string
  error?: string
  required?: boolean
  type?: 'text' | 'email' | 'password' | 'number'
}

// Modal component with portal
interface ModalProps {
  isOpen: boolean
  onClose: () => void
  title?: string
  children: React.ReactNode
}
```

#### Layout Components (`components/layout/`)
```typescript
// Main application layout
const AppLayout: React.FC = ({ children }) => {
  return (
    <div className="min-h-screen bg-gray-50">
      <Header />
      <div className="flex">
        <Sidebar />
        <main className="flex-1 p-6">
          {children}
        </main>
      </div>
    </div>
  )
}

// Authentication layout
const AuthLayout: React.FC = ({ children }) => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        {children}
      </div>
    </div>
  )
}
```

### Feature Components (`components/features/`)

#### Organization Switcher
```typescript
const OrganizationSwitcher: React.FC = () => {
  const { organizations, currentOrg, switchOrganization } = useOrganizations()
  
  return (
    <Select value={currentOrg?.id} onValueChange={switchOrganization}>
      {organizations.map(org => (
        <SelectItem key={org.id} value={org.id}>
          {org.name}
        </SelectItem>
      ))}
    </Select>
  )
}
```

#### User Menu
```typescript
const UserMenu: React.FC = () => {
  const { user, logout } = useAuth()
  
  return (
    <DropdownMenu>
      <DropdownMenuTrigger>
        <Avatar src={user?.avatarUrl} alt={user?.firstName} />
      </DropdownMenuTrigger>
      <DropdownMenuContent>
        <DropdownMenuItem onClick={() => navigate('/settings')}>
          Settings
        </DropdownMenuItem>
        <DropdownMenuItem onClick={logout}>
          Logout
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
```

## Routing Structure

### Route Configuration
```typescript
// Router setup with data loading
const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    children: [
      {
        index: true,
        element: <LandingPage />
      },
      {
        path: 'auth',
        element: <AuthLayout />,
        children: [
          { path: 'login', element: <LoginPage /> },
          { path: 'register', element: <RegisterPage /> },
          { path: 'forgot-password', element: <ForgotPasswordPage /> },
          { path: 'reset-password', element: <ResetPasswordPage /> }
        ]
      },
      {
        path: 'app',
        element: <ProtectedRoute><AppLayout /></ProtectedRoute>,
        children: [
          {
            index: true,
            element: <DashboardPage />
          },
          {
            path: 'projects',
            children: [
              { index: true, element: <ProjectsPage /> },
              { path: ':id', element: <ProjectDetailPage /> },
              { path: 'new', element: <CreateProjectPage /> }
            ]
          },
          {
            path: 'settings',
            children: [
              { index: true, element: <SettingsPage /> },
              { path: 'profile', element: <ProfilePage /> },
              { path: 'organization', element: <OrganizationPage /> },
              { path: 'billing', element: <BillingPage /> },
              { path: 'api-keys', element: <ApiKeysPage /> }
            ]
          }
        ]
      },
      {
        path: 'admin',
        element: <AdminRoute><AdminLayout /></AdminRoute>,
        children: [
          { index: true, element: <AdminDashboard /> },
          { path: 'users', element: <AdminUsersPage /> },
          { path: 'organizations', element: <AdminOrganizationsPage /> },
          { path: 'subscriptions', element: <AdminSubscriptionsPage /> }
        ]
      }
    ]
  }
])
```

### Protected Routes
```typescript
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth()
  
  if (isLoading) {
    return <LoadingSpinner />
  }
  
  if (!isAuthenticated) {
    return <Navigate to="/auth/login" replace />
  }
  
  return <>{children}</>
}

const AdminRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth()
  
  if (!user?.isAdmin) {
    return <Navigate to="/app" replace />
  }
  
  return <>{children}</>
}
```

## State Management

### Authentication Store (Zustand)
```typescript
interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  refreshToken: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: false,
  isLoading: true,
  
  login: async (email, password) => {
    set({ isLoading: true })
    try {
      const response = await api.post('/auth/login', { email, password })
      const { user, token } = response.data
      
      localStorage.setItem('token', token)
      set({ user, token, isAuthenticated: true, isLoading: false })
    } catch (error) {
      set({ isLoading: false })
      throw error
    }
  },
  
  logout: () => {
    localStorage.removeItem('token')
    set({ user: null, token: null, isAuthenticated: false })
  }
}))
```

### API Hooks (TanStack Query)
```typescript
// User profile hook
export const useUser = () => {
  return useQuery({
    queryKey: ['user', 'me'],
    queryFn: () => api.get('/users/me').then(res => res.data),
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

// Organizations hook
export const useOrganizations = () => {
  return useQuery({
    queryKey: ['organizations'],
    queryFn: () => api.get('/organizations').then(res => res.data),
  })
}

// Projects hook with pagination
export const useProjects = (page = 1, limit = 20) => {
  const { currentOrg } = useOrganizationStore()
  
  return useQuery({
    queryKey: ['projects', currentOrg?.id, page, limit],
    queryFn: () => 
      api.get(`/organizations/${currentOrg?.id}/projects`, {
        params: { page, limit }
      }).then(res => res.data),
    enabled: !!currentOrg?.id,
  })
}

// Create project mutation
export const useCreateProject = () => {
  const queryClient = useQueryClient()
  const { currentOrg } = useOrganizationStore()
  
  return useMutation({
    mutationFn: (data: CreateProjectData) =>
      api.post(`/organizations/${currentOrg?.id}/projects`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['projects', currentOrg?.id])
    },
  })
}
```

## Form Handling

### Form Components with Validation
```typescript
const CreateProjectForm: React.FC = () => {
  const createProject = useCreateProject()
  
  const form = useForm<CreateProjectData>({
    resolver: zodResolver(createProjectSchema),
    defaultValues: {
      name: '',
      description: '',
      status: 'active'
    }
  })
  
  const onSubmit = async (data: CreateProjectData) => {
    try {
      await createProject.mutateAsync(data)
      toast.success('Project created successfully')
      navigate('/app/projects')
    } catch (error) {
      toast.error('Failed to create project')
    }
  }
  
  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      <FormField
        control={form.control}
        name="name"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Project Name</FormLabel>
            <FormControl>
              <Input {...field} />
            </FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      
      <Button type="submit" loading={createProject.isLoading}>
        Create Project
      </Button>
    </form>
  )
}
```

## Performance Optimization

### Code Splitting
```typescript
// Lazy load pages
const DashboardPage = lazy(() => import('../pages/dashboard/DashboardPage'))
const ProjectsPage = lazy(() => import('../pages/projects/ProjectsPage'))
const SettingsPage = lazy(() => import('../pages/settings/SettingsPage'))

// Suspense wrapper
const AppRouter: React.FC = () => {
  return (
    <Suspense fallback={<PageLoader />}>
      <RouterProvider router={router} />
    </Suspense>
  )
}
```

### Image Optimization
```typescript
const OptimizedImage: React.FC<ImageProps> = ({ src, alt, ...props }) => {
  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      decoding="async"
      {...props}
    />
  )
}
```

### Virtual Scrolling for Large Lists
```typescript
import { FixedSizeList as List } from 'react-window'

const ProjectsList: React.FC = () => {
  const { data: projects } = useProjects()
  
  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      <ProjectCard project={projects[index]} />
    </div>
  )
  
  return (
    <List
      height={600}
      itemCount={projects.length}
      itemSize={120}
      width="100%"
    >
      {Row}
    </List>
  )
}
```

## Testing Strategy

### Component Testing
```typescript
// Example component test
describe('CreateProjectForm', () => {
  it('should submit form with valid data', async () => {
    const mockCreateProject = jest.fn()
    
    render(
      <QueryClient>
        <CreateProjectForm />
      </QueryClient>
    )
    
    await user.type(screen.getByLabelText(/project name/i), 'Test Project')
    await user.click(screen.getByRole('button', { name: /create/i }))
    
    expect(mockCreateProject).toHaveBeenCalledWith({
      name: 'Test Project',
      description: '',
      status: 'active'
    })
  })
})
```

### E2E Testing
```typescript
// Example E2E test
test('user can create a new project', async ({ page }) => {
  await page.goto('/auth/login')
  await page.fill('[data-testid=email]', 'test@example.com')
  await page.fill('[data-testid=password]', 'password')
  await page.click('[data-testid=login-button]')
  
  await page.goto('/app/projects')
  await page.click('[data-testid=create-project-button]')
  await page.fill('[data-testid=project-name]', 'Test Project')
  await page.click('[data-testid=submit-button]')
  
  await expect(page.locator('text=Test Project')).toBeVisible()
})
```

This frontend structure provides a scalable, maintainable foundation for the SaaS Factory application with modern React patterns and best practices.
