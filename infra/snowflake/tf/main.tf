# -- infra/snowflake/tf/main.tf (Child Module)
# ============================================================================
# Snowflake Lakehouse - Snowflake Resources             ← YOU ARE HERE
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  1. WAREHOUSES                                              │
# ├─────────────────────────────────────────────────────────────┤
# │  Compute resources for query execution                      │
# │  (LOAD_WH, TRANSFORM_WH, ADHOC_WH, etc.)                    │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  2. DATABASES & SCHEMAS                                     │
# ├─────────────────────────────────────────────────────────────┤
# │  Logical containers for data organization                   │
# │  (LAKEHOUSE_DB → RAW, STAGING, ANALYTICS schemas)           │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  3. FILE FORMATS                                            │
# ├─────────────────────────────────────────────────────────────┤
# │  Define parsing rules for external data files               │
# │  (CSV, JSON, Parquet with compression settings)             │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  4. STORAGE INTEGRATION                                     │
# ├─────────────────────────────────────────────────────────────┤
# │  Secure connection to AWS S3 via IAM Role                   │
# │  Input:  storage_aws_role_arn (from AWS module)             │
# │  Output: STORAGE_AWS_IAM_USER_ARN ─┐                        │
# │          STORAGE_AWS_EXTERNAL_ID  ─┼─► For IAM trust policy │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  5. EXTERNAL STAGES                                         │
# ├─────────────────────────────────────────────────────────────┤
# │  Named references to S3 bucket paths                        │
# │  (Uses storage integration for authentication)              │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  6. TABLES                                                  │
# ├─────────────────────────────────────────────────────────────┤
# │  Target tables for data ingestion                           │
# │  (Column definitions, data types, defaults)                 │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  7. SNOWPIPES                                               │
# ├─────────────────────────────────────────────────────────────┤
# │  Auto-ingest pipelines triggered by S3 events               │
# │  Output: notification_channel (SQS ARN) ─► For S3 events    │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ----------------------------------------------------------------------------
# Phase 2: Snowflake Resources
# ----------------------------------------------------------------------------

# 1. Warehouses
resource "snowflake_warehouse" "this" {
  for_each = var.warehouse_config

  name                      = each.value.name
  comment                   = lookup(each.value, "comment", "")
  warehouse_size            = lookup(each.value, "warehouse_size", "X-SMALL")
  auto_resume               = lookup(each.value, "auto_resume", true)
  auto_suspend              = lookup(each.value, "auto_suspend", 60)
  enable_query_acceleration = lookup(each.value, "enable_query_acceleration", false)
  warehouse_type            = lookup(each.value, "warehouse_type", "STANDARD")
  min_cluster_count         = lookup(each.value, "min_cluster_count", 1)
  max_cluster_count         = lookup(each.value, "max_cluster_count", 1)
  scaling_policy            = lookup(each.value, "scaling_policy", "STANDARD")
  initially_suspended       = lookup(each.value, "initially_suspended", true)
}

# 2. Databases
resource "snowflake_database" "this" {
  for_each = var.database_config

  name    = each.value.name
  comment = lookup(each.value, "comment", "")
}

# 2.1 Schemas
resource "snowflake_schema" "this" {
  for_each = var.schema_config

  database = each.value.database
  name     = each.value.name
  comment  = lookup(each.value, "comment", "")

  depends_on = [snowflake_database.this]
}

# 3. File Formats
resource "snowflake_file_format" "this" {
  for_each = var.file_format_config

  name        = each.value.name
  database    = each.value.database
  schema      = each.value.schema
  format_type = each.value.type
  comment     = each.value.comment
  compression = each.value.compression

  # CSV-specific options
  field_delimiter                = each.value.type == "CSV" ? each.value.field_delimiter : null
  record_delimiter               = each.value.type == "CSV" ? each.value.record_delimiter : null
  skip_header                    = each.value.type == "CSV" ? each.value.skip_header : null
  field_optionally_enclosed_by   = each.value.type == "CSV" ? each.value.field_optionally_enclosed_by : null
  trim_space                     = each.value.type == "CSV" ? each.value.trim_space : null
  error_on_column_count_mismatch = each.value.type == "CSV" ? each.value.error_on_column_count_mismatch : null
  escape                         = each.value.type == "CSV" ? each.value.escape : null
  escape_unenclosed_field        = each.value.type == "CSV" ? each.value.escape_unenclosed_field : null
  date_format                    = each.value.type == "CSV" ? each.value.date_format : null
  timestamp_format               = each.value.type == "CSV" ? each.value.timestamp_format : null
  null_if                        = each.value.type == "CSV" ? each.value.null_if : null

  # JSON-specific options
  enable_octal       = each.value.type == "JSON" ? each.value.enable_octal : null
  allow_duplicate    = each.value.type == "JSON" ? each.value.allow_duplicate : null
  strip_outer_array  = each.value.type == "JSON" ? each.value.strip_outer_array : null
  strip_null_values  = each.value.type == "JSON" ? each.value.strip_null_values : null
  ignore_utf8_errors = each.value.type == "JSON" ? each.value.ignore_utf8_errors : null

  depends_on = [snowflake_schema.this]
}

# 4. Storage Integrations
resource "snowflake_storage_integration" "this" {
  for_each = var.storage_integration_config

  name                      = each.value.name
  type                      = "EXTERNAL_STAGE"
  storage_provider          = each.value.storage_provider
  storage_aws_role_arn      = each.value.storage_aws_role_arn
  storage_allowed_locations = each.value.storage_allowed_locations
  storage_blocked_locations = lookup(each.value, "storage_blocked_locations", [])
  enabled                   = lookup(each.value, "enabled", true)
  comment                   = lookup(each.value, "comment", "")
}


# 5. Stages
resource "snowflake_stage" "this" {
  for_each = var.stage_config

  name                = each.value.name
  database            = each.value.database
  schema              = each.value.schema
  url                 = lookup(each.value, "url", null)
  storage_integration = lookup(each.value, "storage_integration", null)
  comment             = lookup(each.value, "comment", "")

  depends_on = [snowflake_storage_integration.this, snowflake_schema.this]
}

# 6. Tables
resource "snowflake_table" "this" {
  for_each = var.table_config

  database = each.value.database
  schema   = each.value.schema
  name     = each.value.name
  comment  = lookup(each.value, "comment", "")

  dynamic "column" {
    for_each = each.value.columns
    content {
      name     = column.value.name
      type     = column.value.type
      nullable = lookup(column.value, "nullable", true)

      dynamic "default" {
        for_each = lookup(column.value, "default", null) != null ? [1] : []
        content {
          expression = column.value.default
        }
      }
    }
  }

  depends_on = [snowflake_schema.this]
}

# 7. Snowpipes
resource "snowflake_pipe" "this" {
  for_each = var.snowpipe_config

  name           = each.value.name
  database       = each.value.database
  schema         = each.value.schema
  copy_statement = each.value.copy_statement
  auto_ingest    = lookup(each.value, "auto_ingest", true)
  comment        = lookup(each.value, "comment", "")

  depends_on = [snowflake_stage.this, snowflake_table.this]
}
