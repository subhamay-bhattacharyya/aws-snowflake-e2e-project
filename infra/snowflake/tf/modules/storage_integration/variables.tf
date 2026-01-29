# -- infra/snowflake/tf/modules/storage_integration/variables.tf (Child Module)
# ============================================================================
# Snowflake Storage Integration Variables
# ============================================================================

variable "storage_integrations" {
  description = "List of storage integration configurations as JSON objects"
  type = list(object({
    name                      = string
    type                      = string # EXTERNAL_STAGE
    storage_provider          = string # S3, GCS, AZURE
    enabled                   = optional(bool, true)
    comment                   = optional(string, "")
    storage_allowed_locations = list(string)
    storage_blocked_locations = optional(list(string), [])

    # AWS S3 specific
    storage_aws_role_arn = optional(string)

    # Azure specific
    azure_tenant_id = optional(string)
  }))
}
