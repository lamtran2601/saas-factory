# GitHub CLI Automation for SaaS Factory Deployment

## Overview

This guide demonstrates how to use GitHub CLI to automate the configuration of your GitHub repository for the SaaS Factory deployment pipeline, eliminating manual setup through the web interface.

## Benefits of GitHub CLI Automation

### ✅ Advantages
- **Speed**: Configure 20+ secrets in under 5 minutes
- **Accuracy**: Eliminate manual typing errors
- **Reproducibility**: Same setup across different repositories
- **Version Control**: Configuration scripts can be versioned
- **Batch Operations**: Set multiple secrets with one command
- **Validation**: Automatic verification of configuration

### 🔄 Comparison: Manual vs Automated

| Task | Manual (Web Interface) | Automated (GitHub CLI) |
|------|----------------------|------------------------|
| **Set 20+ secrets** | 15-20 minutes | 2-3 minutes |
| **Branch protection** | 5-10 minutes | 30 seconds |
| **Environment setup** | 5 minutes | 30 seconds |
| **Error prone** | High | Low |
| **Reproducible** | No | Yes |
| **Scriptable** | No | Yes |

## Quick Start

### 1. One-Command Setup

```bash
# Complete automated setup
./scripts/setup-github.sh

# Or with environment variables
CLOUDFLARE_API_TOKEN=your_token \
STAGING_SUPABASE_URL=your_url \
./scripts/setup-github.sh --from-env
```

### 2. Interactive Setup

```bash
# Run the main setup script
./scripts/setup-deployment.sh

# When prompted, choose "y" for GitHub configuration
# The script will guide you through the process
```

## GitHub CLI Commands Reference

### Installation and Authentication

```bash
# Install GitHub CLI
# macOS
brew install gh

# Windows
choco install gh

# Linux (Ubuntu/Debian)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

### Secrets Management

```bash
# Set individual secrets
gh secret set SECRET_NAME --body "secret_value"

# Set secret from file
gh secret set SECRET_NAME < secret_file.txt

# Set secret from environment variable
gh secret set SECRET_NAME --body "$ENV_VAR"

# List all secrets
gh secret list

# Delete a secret
gh secret delete SECRET_NAME
```

### Repository Variables

```bash
# Set repository variables (non-sensitive)
gh variable set VARIABLE_NAME --body "value"

# List all variables
gh variable list

# Delete a variable
gh variable delete VARIABLE_NAME
```

### Branch Protection

```bash
# Set up branch protection for main
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test","build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null

# Remove branch protection
gh api repos/:owner/:repo/branches/main/protection --method DELETE
```

### Environment Management

```bash
# Create environment
gh api repos/:owner/:repo/environments/production-approval --method PUT

# Create environment with protection rules
gh api repos/:owner/:repo/environments/production-approval \
  --method PUT \
  --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
  --field reviewers='[{"type":"User","id":USER_ID}]'

# List environments
gh api repos/:owner/:repo/environments
```

## Complete Configuration Examples

### Example 1: Basic Setup

```bash
#!/bin/bash

# Set Cloudflare secrets
gh secret set CLOUDFLARE_API_TOKEN --body "your_cloudflare_token"
gh secret set CLOUDFLARE_ACCOUNT_ID --body "your_account_id"

# Set Supabase secrets
gh secret set SUPABASE_ACCESS_TOKEN --body "your_supabase_token"
gh secret set STAGING_SUPABASE_URL --body "https://staging.supabase.co"
gh secret set PRODUCTION_SUPABASE_URL --body "https://production.supabase.co"

# Generate and set JWT secrets
STAGING_JWT=$(openssl rand -base64 32)
PRODUCTION_JWT=$(openssl rand -base64 32)
gh secret set STAGING_JWT_SECRET --body "$STAGING_JWT"
gh secret set PRODUCTION_JWT_SECRET --body "$PRODUCTION_JWT"

echo "✅ Basic secrets configured"
```

### Example 2: Batch Secret Setup

```bash
#!/bin/bash

# Define secrets in an associative array
declare -A secrets=(
    ["CLOUDFLARE_API_TOKEN"]="your_cloudflare_token"
    ["CLOUDFLARE_ACCOUNT_ID"]="your_account_id"
    ["STAGING_SUPABASE_URL"]="https://staging.supabase.co"
    ["PRODUCTION_SUPABASE_URL"]="https://production.supabase.co"
)

# Set all secrets
for secret_name in "${!secrets[@]}"; do
    echo "Setting $secret_name..."
    gh secret set "$secret_name" --body "${secrets[$secret_name]}"
done

echo "✅ All secrets configured"
```

### Example 3: Environment-Based Setup

```bash
#!/bin/bash

# Load from environment file
if [ -f ".env.secrets" ]; then
    source .env.secrets
fi

# Set secrets from environment variables
gh secret set CLOUDFLARE_API_TOKEN --body "$CLOUDFLARE_API_TOKEN"
gh secret set STAGING_DATABASE_URL --body "$STAGING_DATABASE_URL"
gh secret set PRODUCTION_DATABASE_URL --body "$PRODUCTION_DATABASE_URL"

echo "✅ Secrets loaded from environment"
```

## Advanced Automation

### Bulk Operations Script

```bash
#!/bin/bash

# Function to set multiple secrets from a JSON file
set_secrets_from_json() {
    local json_file="$1"
    
    # Read JSON and set secrets
    jq -r 'to_entries[] | "\(.key) \(.value)"' "$json_file" | while read -r key value; do
        echo "Setting secret: $key"
        gh secret set "$key" --body "$value"
    done
}

# Usage
# set_secrets_from_json secrets.json
```

### Validation Script

```bash
#!/bin/bash

# Validate all required secrets are set
required_secrets=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID"
    "STAGING_SUPABASE_URL"
    "PRODUCTION_SUPABASE_URL"
)

echo "🔍 Validating secrets..."
missing_secrets=()

for secret in "${required_secrets[@]}"; do
    if ! gh secret list | grep -q "$secret"; then
        missing_secrets+=("$secret")
    fi
done

if [ ${#missing_secrets[@]} -eq 0 ]; then
    echo "✅ All required secrets are configured"
else
    echo "❌ Missing secrets: ${missing_secrets[*]}"
    exit 1
fi
```

## Security Best Practices

### 1. Secret Generation

```bash
# Generate secure random secrets
openssl rand -base64 32

# Generate hex secrets
openssl rand -hex 32

# Generate using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

### 2. Secret Rotation

```bash
#!/bin/bash

# Rotate JWT secrets
NEW_STAGING_JWT=$(openssl rand -base64 32)
NEW_PRODUCTION_JWT=$(openssl rand -base64 32)

gh secret set STAGING_JWT_SECRET --body "$NEW_STAGING_JWT"
gh secret set PRODUCTION_JWT_SECRET --body "$NEW_PRODUCTION_JWT"

echo "✅ JWT secrets rotated"
```

### 3. Audit and Cleanup

```bash
# List all secrets with timestamps
gh api repos/:owner/:repo/actions/secrets | jq '.secrets[] | {name, updated_at}'

# Remove unused secrets
gh secret delete OLD_SECRET_NAME
```

## Troubleshooting

### Common Issues

**1. Authentication Errors**
```bash
# Re-authenticate
gh auth logout
gh auth login

# Check authentication status
gh auth status
```

**2. Permission Errors**
```bash
# Check repository permissions
gh api repos/:owner/:repo | jq '.permissions'

# Verify you have admin access
gh api repos/:owner/:repo/collaborators/$(gh api user --jq '.login')/permission
```

**3. API Rate Limits**
```bash
# Check rate limit status
gh api rate_limit

# Use authenticated requests (higher limits)
gh auth status
```

### Debug Commands

```bash
# Test API access
gh api repos/:owner/:repo

# List current secrets
gh secret list

# Check environment configuration
gh api repos/:owner/:repo/environments

# Verify branch protection
gh api repos/:owner/:repo/branches/main/protection
```

## Integration with CI/CD

### GitHub Actions Integration

```yaml
# .github/workflows/setup-secrets.yml
name: Setup Secrets

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to configure'
        required: true
        default: 'staging'

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup secrets
        run: ./scripts/setup-github.sh --from-env
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          # ... other environment variables
```

## Migration from Manual Setup

### Export Existing Secrets

```bash
#!/bin/bash

# Export current secrets to environment file
echo "# Generated secrets export" > .env.secrets.example
gh secret list --json name | jq -r '.[].name' | while read -r secret; do
    echo "${secret}=your_${secret,,}_value" >> .env.secrets.example
done

echo "✅ Secret template created in .env.secrets.example"
```

### Bulk Import

```bash
#!/bin/bash

# Import from existing environment
if [ -f ".env.production" ]; then
    source .env.production
    ./scripts/setup-github.sh --from-env
fi
```

## Conclusion

GitHub CLI automation provides a significant improvement in developer experience by:

- **Reducing setup time** from 30+ minutes to under 5 minutes
- **Eliminating manual errors** through automated configuration
- **Enabling reproducible setups** across multiple repositories
- **Providing version-controlled configuration** through scripts

The automated approach is now the recommended method for setting up SaaS Factory deployments, with manual configuration available as a fallback option.
