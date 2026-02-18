# -- infra/snowflake/tf/variables.tf (Child Module)
# ============================================================================
# Snowflake Module Variables
# ============================================================================

variable "warehouse_configs" {
  description = "Warehouse configuration map"
  type        = map(any)
  default     = {}
}

variable "database_schemas" {
  description = "Database and schema configuration map"
  type = map(object({
    name    = string
    comment = optional(string, "")
    grants = optional(object({
      usage_roles = optional(list(string), [])
    }), { usage_roles = [] })
    schemas = list(object({
      name    = string
      comment = optional(string, "")
      grants = optional(object({
        usage_roles              = optional(list(string), [])
        create_file_format_roles = optional(list(string), [])
        create_stage_roles       = optional(list(string), [])
        create_table_roles       = optional(list(string), [])
        create_pipe_roles        = optional(list(string), [])
      }), {
        usage_roles              = []
        create_file_format_roles = []
        create_stage_roles       = []
        create_table_roles       = []
        create_pipe_roles        = []
      })
    }))
  }))
  default = {}
}

variable "file_format_configs" {
  description = "File format configuration map"
  type        = map(any)
  default     = {}
}

variable "storage_integration_configs" {
  description = "Storage integration configuration map"
  type        = map(any)
  default     = {}
}

variable "stage_configs" {
  description = "Stage configuration map"
  type        = map(any)
  default     = {}
}

# variable "database_config" {
#   description = "Database configuration map"
#   type        = map(any)
#   default     = {}
# }

# variable "schema_config" {
#   description = "Schema configuration map"
#   type        = map(any)
#   default     = {}
# }

# variable "file_format_config" {
#   description = "File format configuration map"
#   type        = map(any)
#   default     = {}
# }

# variable "storage_integration_config" {
#   description = "Storage integration configuration map"
#   type        = map(any)
#   default     = {}
# }

# variable "stage_config" {
#   description = "Stage configuration map"
#   type        = map(any)
#   default     = {}
# }

# variable "table_config" {
#   description = "Table configuration map"
#   type        = map(any)
#   default     = {}
# }

# variable "snowpipe_config" {
#   description = "Snowpipe configuration map"
#   type        = map(any)
#   default     = {}
# }
