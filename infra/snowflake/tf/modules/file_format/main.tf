# -- infra/snowflake/tf/modules/file_format/main.tf (Child Module)
# ============================================================================
# Snowflake File Format Sub-Module
# ============================================================================

resource "snowflake_file_format" "this" {
  for_each = { for ff in var.file_formats : ff.name => ff }

  database    = each.value.database
  schema      = each.value.schema
  name        = each.value.name
  format_type = each.value.type
  comment     = lookup(each.value, "comment", "")

  # CSV-specific options
  compression                    = lookup(each.value, "compression", null)
  field_delimiter                = lookup(each.value, "field_delimiter", null)
  record_delimiter               = lookup(each.value, "record_delimiter", null)
  skip_header                    = lookup(each.value, "skip_header", null)
  field_optionally_enclosed_by   = lookup(each.value, "field_optionally_enclosed_by", null)
  trim_space                     = lookup(each.value, "trim_space", null)
  error_on_column_count_mismatch = lookup(each.value, "error_on_column_count_mismatch", null)
  escape                         = lookup(each.value, "escape", null)
  escape_unenclosed_field        = lookup(each.value, "escape_unenclosed_field", null)
  date_format                    = lookup(each.value, "date_format", null)
  timestamp_format               = lookup(each.value, "timestamp_format", null)
  null_if                        = lookup(each.value, "null_if", null)

  # JSON-specific options
  enable_octal       = lookup(each.value, "enable_octal", null)
  allow_duplicate    = lookup(each.value, "allow_duplicate", null)
  strip_outer_array  = lookup(each.value, "strip_outer_array", null)
  strip_null_values  = lookup(each.value, "strip_null_values", null)
  ignore_utf8_errors = lookup(each.value, "ignore_utf8_errors", null)
}
