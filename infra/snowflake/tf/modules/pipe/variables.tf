# -- infra/snowflake/tf/modules/pipe/variables.tf (Child Module)
# ============================================================================
# Snowflake Pipe Variables
# ============================================================================

variable "name" {
  description = "Name of the pipe"
  type        = string
}

variable "database" {
  description = "Database where the pipe will be created"
  type        = string
}

variable "schema" {
  description = "Schema where the pipe will be created"
  type        = string
}

variable "copy_statement" {
  description = "COPY INTO statement for the pipe"
  type        = string
}

variable "auto_ingest" {
  description = "Whether to enable auto-ingest for the pipe"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the pipe"
  type        = string
  default     = ""
}
