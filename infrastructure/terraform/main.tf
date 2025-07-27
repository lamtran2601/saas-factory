# SaaS Factory Infrastructure - Cloudflare Resources
# This Terraform configuration manages all Cloudflare infrastructure

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # Backend configuration for state management
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket = "saas-factory-terraform-state"
  #   key    = "infrastructure/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Configure the Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Data source to get account information
data "cloudflare_accounts" "main" {
  name = var.cloudflare_account_name
}

locals {
  account_id = data.cloudflare_accounts.main.accounts[0].id
  
  # Common tags for all resources
  common_tags = {
    Project     = "saas-factory"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Environment-specific configuration
  env_config = {
    staging = {
      worker_name_suffix = "-staging"
      pages_name_suffix  = "-staging"
      subdomain         = "staging"
    }
    production = {
      worker_name_suffix = "-prod"
      pages_name_suffix  = "-production"
      subdomain         = "app"
    }
  }
}

# Workers for API Backend
resource "cloudflare_worker_script" "api" {
  account_id = local.account_id
  name       = "saas-factory-api${local.env_config[var.environment].worker_name_suffix}"
  content    = file("${path.module}/../../apps/api/dist/index.js")

  # Environment variables (non-sensitive)
  plain_text_binding {
    name = "ENVIRONMENT"
    text = var.environment
  }

  plain_text_binding {
    name = "NODE_ENV"
    text = var.environment == "production" ? "production" : "development"
  }

  plain_text_binding {
    name = "SUPABASE_URL"
    text = var.supabase_url
  }

  plain_text_binding {
    name = "SUPABASE_ANON_KEY"
    text = var.supabase_anon_key
  }

  plain_text_binding {
    name = "API_URL"
    text = "https://saas-factory-api${local.env_config[var.environment].worker_name_suffix}.${var.cloudflare_account_name}.workers.dev"
  }

  plain_text_binding {
    name = "FRONTEND_URL"
    text = var.environment == "production" ? "https://${var.domain_name}" : "https://saas-factory${local.env_config[var.environment].pages_name_suffix}.pages.dev"
  }

  # Sensitive environment variables (managed via secrets)
  secret_text_binding {
    name = "DATABASE_URL"
    text = var.database_url
  }

  secret_text_binding {
    name = "SUPABASE_SERVICE_ROLE_KEY"
    text = var.supabase_service_role_key
  }

  secret_text_binding {
    name = "JWT_SECRET"
    text = var.jwt_secret
  }

  secret_text_binding {
    name = "STRIPE_SECRET_KEY"
    text = var.stripe_secret_key
  }

  secret_text_binding {
    name = "STRIPE_WEBHOOK_SECRET"
    text = var.stripe_webhook_secret
  }

  compatibility_date = "2024-01-15"

  tags = values(local.common_tags)
}

# Worker Route (if using custom domain)
resource "cloudflare_worker_route" "api" {
  count = var.domain_name != "" ? 1 : 0
  
  zone_id     = var.cloudflare_zone_id
  pattern     = "api.${var.domain_name}/*"
  script_name = cloudflare_worker_script.api.name
}

# Pages Project for Frontend
resource "cloudflare_pages_project" "frontend" {
  account_id        = local.account_id
  name              = "saas-factory${local.env_config[var.environment].pages_name_suffix}"
  production_branch = var.environment == "production" ? "main" : "develop"

  build_config {
    build_command       = "cd apps/web && bun run build"
    destination_dir     = "apps/web/dist"
    root_dir           = ""
    web_analytics_tag   = var.web_analytics_tag
    web_analytics_token = var.web_analytics_token
  }

  source {
    type = "github"
    config {
      owner                         = var.github_owner
      repo_name                    = var.github_repo
      production_branch            = var.environment == "production" ? "main" : "develop"
      pr_comments_enabled          = true
      deployments_enabled          = true
      production_deployment_enabled = true
      preview_deployment_setting   = "custom"
      preview_branch_includes      = ["develop", "staging"]
      preview_branch_excludes      = ["main"]
    }
  }

  deployment_configs {
    preview {
      environment_variables = {
        VITE_API_URL         = "https://saas-factory-api-staging.${var.cloudflare_account_name}.workers.dev"
        VITE_SUPABASE_URL    = var.supabase_url_staging
        VITE_SUPABASE_ANON_KEY = var.supabase_anon_key_staging
        VITE_ENVIRONMENT     = "staging"
        VITE_APP_NAME        = "SaaS Factory (Staging)"
        VITE_APP_URL         = "https://saas-factory-staging.pages.dev"
      }
    }

    production {
      environment_variables = {
        VITE_API_URL         = var.domain_name != "" ? "https://api.${var.domain_name}" : "https://saas-factory-api-prod.${var.cloudflare_account_name}.workers.dev"
        VITE_SUPABASE_URL    = var.supabase_url
        VITE_SUPABASE_ANON_KEY = var.supabase_anon_key
        VITE_ENVIRONMENT     = "production"
        VITE_APP_NAME        = "SaaS Factory"
        VITE_APP_URL         = var.domain_name != "" ? "https://${var.domain_name}" : "https://saas-factory-production.pages.dev"
        VITE_STRIPE_PUBLISHABLE_KEY = var.stripe_publishable_key
      }
    }
  }
}

# Custom Domain for Pages (if provided)
resource "cloudflare_pages_domain" "frontend" {
  count = var.domain_name != "" ? 1 : 0
  
  account_id   = local.account_id
  project_name = cloudflare_pages_project.frontend.name
  domain       = var.environment == "production" ? var.domain_name : "${local.env_config[var.environment].subdomain}.${var.domain_name}"
}

# DNS Records (if managing DNS through Cloudflare)
resource "cloudflare_record" "api" {
  count = var.domain_name != "" && var.cloudflare_zone_id != "" ? 1 : 0
  
  zone_id = var.cloudflare_zone_id
  name    = "api"
  value   = "saas-factory-api${local.env_config[var.environment].worker_name_suffix}.${var.cloudflare_account_name}.workers.dev"
  type    = "CNAME"
  proxied = true
  
  comment = "SaaS Factory API ${var.environment} endpoint"
}

# KV Namespace for caching (optional)
resource "cloudflare_workers_kv_namespace" "cache" {
  account_id = local.account_id
  title      = "saas-factory-cache-${var.environment}"
}

# R2 Bucket for file storage (optional)
resource "cloudflare_r2_bucket" "storage" {
  account_id = local.account_id
  name       = "saas-factory-storage-${var.environment}"
  location   = var.r2_location
}

# D1 Database for edge data (optional)
resource "cloudflare_d1_database" "edge_cache" {
  account_id = local.account_id
  name       = "saas-factory-edge-cache-${var.environment}"
}

# WAF Rules for security
resource "cloudflare_ruleset" "waf" {
  count = var.cloudflare_zone_id != "" ? 1 : 0
  
  zone_id     = var.cloudflare_zone_id
  name        = "SaaS Factory WAF Rules - ${var.environment}"
  description = "Custom WAF rules for SaaS Factory application"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action = "block"
    expression = "(http.request.uri.path contains \"/admin\" and ip.geoip.country ne \"US\")"
    description = "Block admin access from outside US"
    enabled = var.environment == "production"
  }

  rules {
    action = "challenge"
    expression = "(cf.threat_score gt 14)"
    description = "Challenge suspicious requests"
    enabled = true
  }
}

# Page Rules for caching and redirects
resource "cloudflare_page_rule" "cache_static" {
  count = var.cloudflare_zone_id != "" ? 1 : 0
  
  zone_id  = var.cloudflare_zone_id
  target   = "${var.domain_name}/assets/*"
  priority = 1

  actions {
    cache_level = "cache_everything"
    edge_cache_ttl = 31536000  # 1 year
    browser_cache_ttl = 31536000
  }
}

resource "cloudflare_page_rule" "redirect_www" {
  count = var.domain_name != "" && var.cloudflare_zone_id != "" && var.environment == "production" ? 1 : 0
  
  zone_id  = var.cloudflare_zone_id
  target   = "www.${var.domain_name}/*"
  priority = 2

  actions {
    forwarding_url {
      url         = "https://${var.domain_name}/$1"
      status_code = 301
    }
  }
}
