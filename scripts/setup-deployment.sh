#!/bin/bash

# SaaS Factory Deployment Setup Script
# This script helps set up the CLI-first deployment pipeline

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

print_header() {
    echo ""
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
    echo ""
}

print_header "SaaS Factory Deployment Setup"

print_status "This script will help you set up the CLI-first deployment pipeline"
print_status "for your SaaS Factory application."
print_status ""

# Check if running in the correct directory
if [ ! -f "package.json" ] || [ ! -d "apps/api" ] || [ ! -d "apps/web" ]; then
    print_error "Please run this script from the root of your SaaS Factory project"
    exit 1
fi

print_header "Step 1: Prerequisites Check"

# Check for required tools
print_status "Checking for required tools..."

MISSING_TOOLS=()

if ! command -v bun &> /dev/null; then
    MISSING_TOOLS+=("bun")
fi

if ! command -v git &> /dev/null; then
    MISSING_TOOLS+=("git")
fi

if ! command -v curl &> /dev/null; then
    MISSING_TOOLS+=("curl")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_error "Missing required tools: ${MISSING_TOOLS[*]}"
    print_status "Please install the missing tools and run this script again"
    exit 1
fi

print_success "All required tools are installed"

# Check for GitHub CLI
print_status "Checking for GitHub CLI..."
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI not found. This is recommended for automated setup."
    read -p "Would you like to install GitHub CLI? (y/n): " install_gh
    if [ "$install_gh" = "y" ] || [ "$install_gh" = "Y" ]; then
        if command -v brew &> /dev/null; then
            print_status "Installing GitHub CLI via Homebrew..."
            brew install gh
        elif command -v apt &> /dev/null; then
            print_status "Installing GitHub CLI via apt..."
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh
        else
            print_warning "Please install GitHub CLI manually from https://github.com/cli/cli/releases"
        fi
    fi
fi

if command -v gh &> /dev/null; then
    print_success "GitHub CLI is available"

    # Check GitHub authentication
    if ! gh auth status &> /dev/null; then
        print_warning "Not authenticated with GitHub"
        read -p "Would you like to authenticate with GitHub now? (y/n): " auth_gh
        if [ "$auth_gh" = "y" ] || [ "$auth_gh" = "Y" ]; then
            gh auth login
            print_success "GitHub authentication completed"
        fi
    else
        print_success "Already authenticated with GitHub as $(gh api user --jq '.login')"
    fi
fi

# Check for optional tools
print_status "Checking for optional tools..."

if ! command -v wrangler &> /dev/null; then
    print_warning "Wrangler CLI not found. Installing..."
    bun add -g wrangler
    print_success "Wrangler CLI installed"
fi

if ! command -v supabase &> /dev/null; then
    print_warning "Supabase CLI not found. Installing..."
    bun add -g supabase
    print_success "Supabase CLI installed"
fi

print_header "Step 2: Authentication Setup"

print_status "Setting up authentication with required services..."

# Cloudflare authentication
print_status "Checking Cloudflare authentication..."
if wrangler whoami &> /dev/null; then
    CLOUDFLARE_USER=$(wrangler whoami 2>/dev/null | head -1)
    print_success "Already authenticated with Cloudflare as: $CLOUDFLARE_USER"
else
    print_warning "Not authenticated with Cloudflare"
    read -p "Would you like to authenticate with Cloudflare now? (y/n): " auth_cf
    if [ "$auth_cf" = "y" ] || [ "$auth_cf" = "Y" ]; then
        wrangler login
        print_success "Cloudflare authentication completed"
    else
        print_warning "Skipping Cloudflare authentication. You'll need to run 'wrangler login' later"
    fi
fi

# Supabase authentication
print_status "Checking Supabase authentication..."
if supabase projects list &> /dev/null; then
    print_success "Already authenticated with Supabase"
else
    print_warning "Not authenticated with Supabase"
    read -p "Would you like to authenticate with Supabase now? (y/n): " auth_sb
    if [ "$auth_sb" = "y" ] || [ "$auth_sb" = "Y" ]; then
        supabase login
        print_success "Supabase authentication completed"
    else
        print_warning "Skipping Supabase authentication. You'll need to run 'supabase login' later"
    fi
fi

print_header "Step 3: Project Configuration"

print_status "Checking project configuration..."

# Check if GitHub Actions workflows exist
if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(ls -1 .github/workflows/*.yml 2>/dev/null | wc -l)
    print_success "Found $WORKFLOW_COUNT GitHub Actions workflows"
else
    print_warning "GitHub Actions workflows directory not found"
fi

# Check if deployment scripts exist
if [ -d "scripts/deploy" ]; then
    SCRIPT_COUNT=$(ls -1 scripts/deploy/*.sh 2>/dev/null | wc -l)
    print_success "Found $SCRIPT_COUNT deployment scripts"
else
    print_warning "Deployment scripts directory not found"
fi

print_header "Step 4: Environment Setup"

print_status "Setting up environment configurations..."

# Create local environment files if they don't exist
if [ ! -f "apps/api/.env" ]; then
    if [ -f "apps/api/.env.example" ]; then
        cp apps/api/.env.example apps/api/.env
        print_success "Created apps/api/.env from example"
    else
        print_warning "No .env.example found for API"
    fi
fi

if [ ! -f "apps/web/.env" ]; then
    if [ -f "apps/web/.env.example" ]; then
        cp apps/web/.env.example apps/web/.env
        print_success "Created apps/web/.env from example"
    else
        print_warning "No .env.example found for web app"
    fi
fi

print_header "Step 5: Dependencies Installation"

print_status "Installing project dependencies..."
bun install
print_success "Dependencies installed successfully"

print_header "Step 6: Build Test"

print_status "Testing build process..."

# Test API build
print_status "Testing API build..."
cd apps/api
if bun run build &> /dev/null; then
    print_success "API build test passed"
else
    print_warning "API build test failed - check your configuration"
fi
cd ../..

# Test Web build
print_status "Testing web build..."
cd apps/web
if VITE_API_URL=http://localhost:8787 VITE_SUPABASE_URL=http://localhost:54321 VITE_SUPABASE_ANON_KEY=test-key bun run build &> /dev/null; then
    print_success "Web build test passed"
else
    print_warning "Web build test failed - check your configuration"
fi
cd ../..

print_header "GitHub Configuration"

if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    print_status "🔐 GitHub CLI is available and authenticated"
    read -p "Would you like to configure GitHub repository settings automatically? (y/n): " setup_github

    if [ "$setup_github" = "y" ] || [ "$setup_github" = "Y" ]; then
        print_status "Running GitHub configuration script..."
        if [ -f "scripts/setup-github.sh" ]; then
            ./scripts/setup-github.sh
            GITHUB_CONFIGURED=true
        else
            print_warning "GitHub setup script not found"
            GITHUB_CONFIGURED=false
        fi
    else
        print_status "Skipping automated GitHub configuration"
        GITHUB_CONFIGURED=false
    fi
else
    print_warning "GitHub CLI not available or not authenticated"
    print_status "You'll need to configure GitHub secrets manually"
    GITHUB_CONFIGURED=false
fi

print_header "Setup Complete!"

print_success "🎉 Deployment setup completed successfully!"
print_status ""

if [ "$GITHUB_CONFIGURED" = "true" ]; then
    print_status "✅ GitHub repository has been configured automatically!"
    print_status ""
    print_status "📋 Next Steps:"
    print_status ""
    print_status "1. 🚀 Test deployment:"
    print_status "   - Push to develop branch to test staging deployment"
    print_status "   - Create PR to main branch to test production deployment"
    print_status ""
    print_status "2. 🔍 Monitor deployments:"
    print_status "   - Check GitHub Actions tab for deployment status"
    print_status "   - Verify applications are working correctly"
else
    print_status "📋 Next Steps:"
    print_status ""
    print_status "1. 🔐 Configure GitHub Secrets:"
    print_status "   - Run: ./scripts/setup-github.sh (recommended)"
    print_status "   - Or manually via GitHub repository settings"
    print_status "   - See docs/15-cli-deployment-setup.md for details"
    print_status ""
    print_status "2. 🗄️ Set up Supabase projects:"
    print_status "   - Create staging and production projects"
    print_status "   - Configure authentication settings"
    print_status "   - Get project credentials"
    print_status ""
    print_status "3. ☁️ Configure Cloudflare:"
    print_status "   - Get API token and account ID"
    print_status "   - Set up Workers and Pages projects"
    print_status ""
    print_status "4. 🚀 Test deployment:"
    print_status "   - Push to develop branch to test staging deployment"
    print_status "   - Create PR to main branch to test production deployment"
fi
print_status ""
print_status "📚 Documentation:"
print_status "   - Setup Guide: docs/15-cli-deployment-setup.md"
print_status "   - Comparison: docs/16-deployment-approach-comparison.md"
print_status "   - CLI Guide: docs/14-cli-first-deployment-guide.md"
print_status ""
print_status ""
print_status "🛠️ Available Commands:"
print_status "   - bun run setup:deployment   # Run this setup script"
print_status "   - ./scripts/setup-github.sh  # Configure GitHub repository"
print_status "   - bun run deploy:staging     # Deploy to staging"
print_status "   - bun run deploy:production  # Deploy to production"
print_status "   - bun run verify:staging     # Verify staging deployment"
print_status "   - bun run verify:production  # Verify production deployment"
print_status "   - bun run rollback:staging   # Rollback staging"
print_status "   - bun run rollback:production # Rollback production"
print_status ""

if [ "$GITHUB_CONFIGURED" = "false" ]; then
    print_warning "⚠️  Important: Configure GitHub Secrets before deploying!"
    print_status "   Run: ./scripts/setup-github.sh"
fi

print_status ""
print_success "Happy deploying! 🚀"
