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

variable "db_provisioner_role" {
  description = "Snowflake role for database provisioning operations"
  type        = string
  default     = "DB_PROVISIONER"
}

variable "warehouse_provisioner_role" {
  description = "Snowflake role for warehouse provisioning operations"
  type        = string
  default     = "WAREHOUSE_PROVISIONER"
}

variable "data_object_provisioner_role" {
  description = "Snowflake role for data object provisioning operations"
  type        = string
  default     = "DATA_OBJECT_PROVISIONER"
}

variable "ingest_object_provisioner_role" {
  description = "Snowflake role for ingest object provisioning operations"
  type        = string
  default     = "INGEST_OBJECT_PROVISIONER"
}

variable "snowflake_warehouse" {
  description = "Snowflake warehouse for Terraform operations"
  type        = string
  default     = "COMPUTE_WH"
}

# Note: For CI/CD, set SNOWFLAKE_PRIVATE_KEY environment variable directly
# The provider will pick it up automatically

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

# ============================================================================
# Feature Flags
# ============================================================================

variable "enable_snowpipe_creation" {
  description = "Enable Snowpipe creation. Set to false on first apply, then true on second apply after trust policy is updated."
  type        = bool
  default     = true
}

variable "enable_trust_policy_update" {
  description = "Enable IAM trust policy update with Snowflake credentials. Set to true only once after storage integration is created."
  type        = bool
  default     = false
}
