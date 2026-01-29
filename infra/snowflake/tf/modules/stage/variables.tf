# -- infra/snowflake/tf/modules/stage/variables.tf (Child Module)
# ============================================================================
# Snowflake Stage Variables
# ============================================================================

variable "stage_config" {
  description = "List of stage configurations as JSON objects"
  type = list(object({
    database = string
    schema   = string
    name     = string
    comment  = optional(string, "")

    # External stage properties
    url                 = optional(string) # S3, GCS, or Azure URL
    storage_integration = optional(string) # Name of storage integration
    file_format         = optional(string) # Name of file format

    # Credentials (alternative to storage integration)
    credentials = optional(string)

    # Encryption
    encryption = optional(string)

    # Directory table
    directory = optional(string)
  }))
}
