# -- infra/platform/tf/variables.tf (Platform Module)
# ============================================================================
# Platform Module Variables
# ============================================================================

variable "environment" {
  description = "Environment name (devl, test, prod)"
  type        = string
  default     = "devl"

  validation {
    condition     = contains(["devl", "test", "prod"], var.environment)
    error_message = "Environment must be devl, test, or prod."
  }
}

variable "project_code" {
  description = "Project code prefix for resource naming (e.g., snw-lkh)"
  type        = string
  default     = "snw"
}

# ============================================================================
# Snowflake Provider Variables
# ============================================================================

variable "snowflake_organization_name" {
  description = "Snowflake organization name"
  type        = string
  default     = ""
}

variable "snowflake_account_name" {
  description = "Snowflake account name"
  type        = string
  default     = ""
}

variable "snowflake_user" {
  description = "Snowflake user for Terraform operations"
  type        = string
  default     = ""
}

variable "snowflake_role" {
  description = "Snowflake role for Terraform operations"
  type        = string
  default     = "SYSADMIN"
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse for Terraform operations"
  type        = string
  default     = "COMPUTE_WH"
}

variable "snowflake_private_key_path" {
  description = "Path to Snowflake private key file for JWT authentication"
  type        = string
  default     = ""
}

# ============================================================================
# Configuration File Paths
# ============================================================================

variable "aws_config_path" {
  description = "Path to AWS config JSON file (relative to module)"
  type        = string
  default     = "../../../input-jsons/aws/config.json"
}

variable "snowflake_config_path" {
  description = "Path to Snowflake config JSON file (relative to module)"
  type        = string
  default     = "../../../input-jsons/snowflake/config.json"
}
