# -- infra/snowflake/tf/modules/file_format/variables.tf (Child Module)
# ============================================================================
# Snowflake File Format Variables
# ============================================================================

variable "file_formats" {
  description = "List of file format configurations as JSON objects"
  type = list(object({
    database = string
    schema   = string
    name     = string
    type     = string # CSV, JSON, PARQUET, AVRO, ORC, XML
    comment  = optional(string, "")

    # Common options
    compression = optional(string)

    # CSV-specific options
    field_delimiter                = optional(string)
    record_delimiter               = optional(string)
    skip_header                    = optional(number)
    field_optionally_enclosed_by   = optional(string)
    trim_space                     = optional(bool)
    error_on_column_count_mismatch = optional(bool)
    escape                         = optional(string)
    escape_unenclosed_field        = optional(string)
    date_format                    = optional(string)
    timestamp_format               = optional(string)
    null_if                        = optional(list(string))

    # JSON-specific options
    enable_octal       = optional(bool)
    allow_duplicate    = optional(bool)
    strip_outer_array  = optional(bool)
    strip_null_values  = optional(bool)
    ignore_utf8_errors = optional(bool)
  }))
}
