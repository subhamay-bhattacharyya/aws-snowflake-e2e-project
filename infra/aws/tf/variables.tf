# -- infra/aws/tf/variables.tf (Child Module)
# ============================================================================
# AWS Infrastructure Variables
# ============================================================================

variable "s3_config" {
  description = "S3 bucket configuration passed from root module."
  type = object({
    bucket_name   = string
    versioning    = bool
    kms_key_alias = string
    kms_key_arn   = string
    bucket_policy = string
    bucket_keys   = list(string)
  })
}

variable "iam_role_config" {
  description = "IAM role configuration for Snowflake storage integration"
  type = object({
    role_name          = string
    assume_role_policy = string
    s3_bucket_arn      = string
    kms_key_arn        = string
  })
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "devl"

  validation {
    condition     = contains(["devl", "test", "prod"], var.environment)
    error_message = "Environment must be devl, test, or prod."
  }
}
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "snw-lkh"
}
variable "snowflake_external_id" {
  description = "Snowflake external ID for IAM role trust relationship"
  type        = string
  sensitive   = true
  default     = ""
}
variable "snowflake_principal_arn" {
  description = "Snowflake principal ARN for IAM role trust relationship"
  type        = string
  default     = ""
}
variable "snowflake_iam_user_arn" {
  description = "Snowflake IAM user ARN from storage integration (STORAGE_AWS_IAM_USER_ARN)"
  type        = string
  default     = ""
}
variable "update_trust_policy" {
  description = "Whether to update the IAM role trust policy with Snowflake values (Phase 3)"
  type        = bool
  default     = false
}
# variable "enable_s3_notifications" {
#   description = "Enable S3 event notifications for Snowpipe"
#   type        = bool
#   default     = false
# }

# variable "raw_data_lifecycle_days" {
#   description = "Number of days to retain raw data before transitioning to Glacier"
#   type        = number
#   default     = 90
# }

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Snowflake Variables
# ============================================================================

variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
  default     = ""
}

variable "snowflake_account_name" {
  description = "Snowflake account name (not the full account identifier)"
  type        = string
  default     = ""
}

variable "snowflake_user" {
  description = "Snowflake user for Terraform operations"
  type        = string
  default     = ""
}

variable "snowflake_password" {
  description = "Snowflake password for Terraform operations (use either password or private_key)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "snowflake_private_key" {
  description = "Snowflake private key for key-pair authentication (use either password or private_key)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "snowflake_role" {
  description = "Snowflake role for Terraform operations"
  type        = string
  default     = "SYSADMIN"
}

variable "snowflake_private_key_passphrase" {
  description = "Snowflake private key passphrase for encrypted keys"
  type        = string
  sensitive   = true
  default     = ""
}

# ============================================================================
# Uppercase variants for GitHub Secrets/Codespaces compatibility
# These map to lowercase variables used by the provider
# ============================================================================

variable "SNOWFLAKE_ACCOUNT" {
  description = "Snowflake account identifier (from GitHub secrets) - will be split into org and account name"
  type        = string
  default     = ""
}

variable "SNOWFLAKE_USER" {
  description = "Snowflake user (from GitHub secrets)"
  type        = string
  default     = ""
}

variable "SNOWFLAKE_PASSWORD" {
  description = "Snowflake password (from GitHub secrets)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "SNOWFLAKE_PRIVATE_KEY" {
  description = "Snowflake private key (from GitHub secrets)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "SNOWFLAKE_ROLE" {
  description = "Snowflake role (from GitHub secrets)"
  type        = string
  default     = ""
}

variable "SNOWFLAKE_PRIVATE_KEY_PASSPHRASE" {
  description = "Snowflake private key passphrase (from GitHub secrets)"
  type        = string
  sensitive   = true
  default     = ""
}
