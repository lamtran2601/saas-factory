# Terraform Variables for SaaS Factory Infrastructure

# Cloudflare Configuration
variable "cloudflare_api_token" {
  description = "Cloudflare API token with necessary permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_name" {
  description = "Cloudflare account name"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for custom domain (optional)"
  type        = string
  default     = ""
}

# Environment Configuration
variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

# Domain Configuration
variable "domain_name" {
  description = "Custom domain name (optional, e.g., saas-factory.com)"
  type        = string
  default     = ""
}

# GitHub Configuration
variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

# Supabase Configuration
variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
}

variable "supabase_anon_key" {
  description = "Supabase anonymous key"
  type        = string
}

variable "supabase_service_role_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

variable "supabase_url_staging" {
  description = "Supabase staging project URL"
  type        = string
  default     = ""
}

variable "supabase_anon_key_staging" {
  description = "Supabase staging anonymous key"
  type        = string
  default     = ""
}

# Database Configuration
variable "database_url" {
  description = "PostgreSQL database connection URL"
  type        = string
  sensitive   = true
}

# Authentication Configuration
variable "jwt_secret" {
  description = "JWT secret for token signing"
  type        = string
  sensitive   = true
}

# Stripe Configuration
variable "stripe_secret_key" {
  description = "Stripe secret key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "stripe_publishable_key" {
  description = "Stripe publishable key"
  type        = string
  default     = ""
}

variable "stripe_webhook_secret" {
  description = "Stripe webhook secret"
  type        = string
  sensitive   = true
  default     = ""
}

# Analytics Configuration
variable "web_analytics_tag" {
  description = "Cloudflare Web Analytics tag"
  type        = string
  default     = ""
}

variable "web_analytics_token" {
  description = "Cloudflare Web Analytics token"
  type        = string
  default     = ""
}

# Storage Configuration
variable "r2_location" {
  description = "Cloudflare R2 bucket location"
  type        = string
  default     = "auto"
}

# Email Configuration
variable "email_api_key" {
  description = "Email service API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "email_from" {
  description = "Default email sender address"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "sentry_dsn" {
  description = "Sentry DSN for error tracking"
  type        = string
  sensitive   = true
  default     = ""
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

# Feature Flags
variable "enable_analytics" {
  description = "Enable analytics tracking"
  type        = bool
  default     = true
}

variable "enable_error_tracking" {
  description = "Enable error tracking"
  type        = bool
  default     = true
}

variable "enable_real_time" {
  description = "Enable real-time features"
  type        = bool
  default     = true
}

variable "enable_file_uploads" {
  description = "Enable file upload functionality"
  type        = bool
  default     = true
}

variable "enable_webhooks" {
  description = "Enable webhook functionality"
  type        = bool
  default     = true
}

# Security Configuration
variable "rate_limit_enabled" {
  description = "Enable rate limiting"
  type        = bool
  default     = true
}

variable "rate_limit_max_requests" {
  description = "Maximum requests per window"
  type        = number
  default     = 100
}

variable "rate_limit_window_ms" {
  description = "Rate limit window in milliseconds"
  type        = number
  default     = 900000  # 15 minutes
}

# Performance Configuration
variable "cache_ttl" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 3600  # 1 hour
}

variable "enable_compression" {
  description = "Enable response compression"
  type        = bool
  default     = true
}

# Development Configuration
variable "enable_debug_mode" {
  description = "Enable debug mode (staging only)"
  type        = bool
  default     = false
}

variable "show_dev_tools" {
  description = "Show development tools in UI"
  type        = bool
  default     = false
}

variable "api_timeout" {
  description = "API request timeout in milliseconds"
  type        = number
  default     = 5000
}

# Backup Configuration
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "enable_automated_backups" {
  description = "Enable automated database backups"
  type        = bool
  default     = true
}
