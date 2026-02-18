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

# ----------------------------------------------------------------------------
# 1. Warehouses
# ----------------------------------------------------------------------------
module "warehouse" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-warehouse?ref=main"

  providers = {
    snowflake = snowflake.warehouse_provisioner
  }

  warehouse_configs = var.warehouse_configs
}


# ----------------------------------------------------------------------------
# 2. Databases and Schema
# ----------------------------------------------------------------------------
module "database_schemas" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-database-schema?ref=main"

  providers = {
    snowflake = snowflake.db_provisioner
  }

  database_configs = var.database_schemas
}

# ----------------------------------------------------------------------------
# 3. File Formats
# ----------------------------------------------------------------------------
module "file_formats" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-file-format?ref=main"

  providers = {
    snowflake = snowflake.data_object_provisioner
  }

  file_format_configs = var.file_format_configs

  depends_on = [module.database_schemas]
}

# ----------------------------------------------------------------------------
# 4. Storage Integrations
# ----------------------------------------------------------------------------
module "storage_integrations" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-storage-integration?ref=main"

  providers = {
    snowflake = snowflake.ingest_object_provisioner
  }

  storage_integration_configs = var.storage_integration_configs

  depends_on = [module.file_formats]
}

# ----------------------------------------------------------------------------
# 5. Stages
# ----------------------------------------------------------------------------
module "stage" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-stage?ref=main"

  providers = {
    snowflake = snowflake.ingest_object_provisioner
  }

  stage_configs = var.stage_configs

  depends_on = [module.storage_integrations]
}

# ----------------------------------------------------------------------------
# 6. Tables
# ----------------------------------------------------------------------------
module "table" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-table?ref=main"

  providers = {
    snowflake = snowflake.data_object_provisioner
  }

  table_configs = var.table_configs

  depends_on = [module.stage]
}

# # 7. Snowpipes
# resource "snowflake_pipe" "this" {
#   for_each = var.snowpipe_config

#   name           = each.value.name
#   database       = each.value.database
#   schema         = each.value.schema
#   copy_statement = each.value.copy_statement
#   auto_ingest    = lookup(each.value, "auto_ingest", true)
#   comment        = lookup(each.value, "comment", "")

#   depends_on = [snowflake_stage.this, snowflake_table.this]
# }
