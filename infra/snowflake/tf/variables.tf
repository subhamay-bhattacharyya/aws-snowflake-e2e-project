# -- infra/snowflake/tf/variables.tf (Child Module)
# ============================================================================
# Snowflake Module Variables
# ============================================================================

variable "warehouse_config" {
  description = "Warehouse configuration map"
  type        = map(any)
}

variable "database_config" {
  description = "Database configuration map"
  type        = map(any)
  default     = {}
}

variable "schema_config" {
  description = "Schema configuration map"
  type        = map(any)
  default     = {}
}

variable "file_format_config" {
  description = "File format configuration map"
  type        = map(any)
  default     = {}
}

variable "storage_integration_config" {
  description = "Storage integration configuration map"
  type        = map(any)
  default     = {}
}

variable "stage_config" {
  description = "Stage configuration map"
  type        = map(any)
  default     = {}
}

variable "table_config" {
  description = "Table configuration map"
  type        = map(any)
  default     = {}
}

variable "snowpipe_config" {
  description = "Snowpipe configuration map"
  type        = map(any)
  default     = {}
}
