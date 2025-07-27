# Terraform Outputs for SaaS Factory Infrastructure

# Worker Information
output "api_worker_name" {
  description = "Name of the deployed API worker"
  value       = cloudflare_worker_script.api.name
}

output "api_worker_url" {
  description = "URL of the deployed API worker"
  value       = "https://${cloudflare_worker_script.api.name}.${var.cloudflare_account_name}.workers.dev"
}

output "api_custom_domain" {
  description = "Custom domain for API (if configured)"
  value       = var.domain_name != "" ? "https://api.${var.domain_name}" : null
}

# Pages Information
output "frontend_project_name" {
  description = "Name of the Cloudflare Pages project"
  value       = cloudflare_pages_project.frontend.name
}

output "frontend_url" {
  description = "URL of the deployed frontend"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${cloudflare_pages_project.frontend.name}.pages.dev"
}

output "frontend_preview_url" {
  description = "Preview URL for staging deployments"
  value       = "https://${cloudflare_pages_project.frontend.name}.pages.dev"
}

# Custom Domain Information
output "custom_domain_configured" {
  description = "Whether custom domain is configured"
  value       = var.domain_name != ""
}

output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.domain_name != "" ? var.domain_name : null
}

# Storage Information
output "r2_bucket_name" {
  description = "Name of the R2 storage bucket"
  value       = cloudflare_r2_bucket.storage.name
}

output "kv_namespace_id" {
  description = "ID of the KV namespace for caching"
  value       = cloudflare_workers_kv_namespace.cache.id
}

output "d1_database_id" {
  description = "ID of the D1 database for edge caching"
  value       = cloudflare_d1_database.edge_cache.id
}

# Environment Information
output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "cloudflare_account_id" {
  description = "Cloudflare account ID"
  value       = local.account_id
}

# DNS Information
output "dns_records_created" {
  description = "Whether DNS records were created"
  value       = var.cloudflare_zone_id != ""
}

output "zone_id" {
  description = "Cloudflare Zone ID (if provided)"
  value       = var.cloudflare_zone_id != "" ? var.cloudflare_zone_id : null
}

# Security Information
output "waf_rules_enabled" {
  description = "Whether WAF rules are enabled"
  value       = var.cloudflare_zone_id != ""
}

output "page_rules_count" {
  description = "Number of page rules configured"
  value       = var.cloudflare_zone_id != "" ? (var.environment == "production" ? 2 : 1) : 0
}

# Configuration Summary
output "deployment_summary" {
  description = "Summary of the deployment configuration"
  value = {
    environment           = var.environment
    api_url              = var.domain_name != "" ? "https://api.${var.domain_name}" : "https://${cloudflare_worker_script.api.name}.${var.cloudflare_account_name}.workers.dev"
    frontend_url         = var.domain_name != "" ? "https://${var.domain_name}" : "https://${cloudflare_pages_project.frontend.name}.pages.dev"
    custom_domain        = var.domain_name != "" ? var.domain_name : "Not configured"
    storage_bucket       = cloudflare_r2_bucket.storage.name
    kv_namespace        = cloudflare_workers_kv_namespace.cache.title
    d1_database         = cloudflare_d1_database.edge_cache.name
    waf_enabled         = var.cloudflare_zone_id != ""
    analytics_enabled   = var.enable_analytics
    error_tracking      = var.enable_error_tracking
  }
}

# GitHub Integration Information
output "github_integration" {
  description = "GitHub integration details"
  value = {
    owner      = var.github_owner
    repository = var.github_repo
    branch     = var.environment == "production" ? "main" : "develop"
  }
}

# Supabase Integration Information
output "supabase_integration" {
  description = "Supabase integration details"
  value = {
    url         = var.supabase_url
    environment = var.environment
  }
  sensitive = false
}

# Feature Flags Status
output "feature_flags" {
  description = "Current feature flag configuration"
  value = {
    analytics      = var.enable_analytics
    error_tracking = var.enable_error_tracking
    real_time      = var.enable_real_time
    file_uploads   = var.enable_file_uploads
    webhooks       = var.enable_webhooks
    rate_limiting  = var.rate_limit_enabled
    compression    = var.enable_compression
    debug_mode     = var.enable_debug_mode
  }
}

# Performance Configuration
output "performance_config" {
  description = "Performance configuration settings"
  value = {
    cache_ttl           = var.cache_ttl
    api_timeout         = var.api_timeout
    compression_enabled = var.enable_compression
    rate_limit_requests = var.rate_limit_max_requests
    rate_limit_window   = var.rate_limit_window_ms
  }
}

# Monitoring and Logging
output "monitoring_config" {
  description = "Monitoring and logging configuration"
  value = {
    log_level           = var.log_level
    analytics_enabled   = var.enable_analytics
    error_tracking      = var.enable_error_tracking
    web_analytics_tag   = var.web_analytics_tag != "" ? "Configured" : "Not configured"
  }
  sensitive = false
}

# Deployment URLs for easy access
output "quick_access_urls" {
  description = "Quick access URLs for the deployment"
  value = {
    frontend    = var.domain_name != "" ? "https://${var.domain_name}" : "https://${cloudflare_pages_project.frontend.name}.pages.dev"
    api         = var.domain_name != "" ? "https://api.${var.domain_name}" : "https://${cloudflare_worker_script.api.name}.${var.cloudflare_account_name}.workers.dev"
    api_health  = var.domain_name != "" ? "https://api.${var.domain_name}/health" : "https://${cloudflare_worker_script.api.name}.${var.cloudflare_account_name}.workers.dev/health"
    api_docs    = var.domain_name != "" ? "https://api.${var.domain_name}/api" : "https://${cloudflare_worker_script.api.name}.${var.cloudflare_account_name}.workers.dev/api"
  }
}
