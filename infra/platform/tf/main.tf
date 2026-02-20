# -- infra/platform/tf/main.tf (Platform Module)
# ============================================================================
# Snowflake Lakehouse - Platform Orchestration
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 1: AWS Resources                                     │
# ├─────────────────────────────────────────────────────────────┤
# │  1. S3 Bucket (landing zone for data files)                 │
# │  2. IAM Role (with placeholder trust policy)                │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 2: Snowflake Resources                               │
# ├─────────────────────────────────────────────────────────────┤
# │  1. Warehouses                                              │
# │  2. Databases & Schemas                                     │
# │  3. File Formats                                            │
# │  4. Storage Integration                                     │
# │  5. Stages                                                  │
# │  6. Tables                                                  │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 3: AWS Trust Policy Update                           │
# ├─────────────────────────────────────────────────────────────┤
# │  Update IAM Role trust policy with Snowflake credentials    │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 4: Snowpipes  (BRONZE layer)                         │
# └─────────────────────────────────────────────────────────────┘
#
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 5: Dynamic tables (SILVER layer)                     │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ============================================================================
# PHASE 1: AWS Resources
# ============================================================================

# ----------------------------------------------------------------------------
# 1.1 S3 Bucket for Snowflake external stage
# ----------------------------------------------------------------------------
module "s3" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-aws-s3-bucket/modules/bucket?ref=main"

  s3_config = local.s3_config
}

# ----------------------------------------------------------------------------
# 1.2 IAM Role for Snowflake storage integration (initial with placeholder trust)
# ----------------------------------------------------------------------------
module "iam_role" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-aws-iam/modules/role?ref=main"

  iam_role = local.iam_role_config

  depends_on = [module.s3]
}

# ============================================================================
# PHASE 2: Snowflake Resources
# ============================================================================

# ----------------------------------------------------------------------------
# 2.1 Warehouses
# ----------------------------------------------------------------------------
module "warehouse" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-warehouse?ref=main"

  providers = {
    snowflake = snowflake.warehouse_provisioner
  }

  warehouse_configs = local.warehouses
}

# ----------------------------------------------------------------------------
# 2.2 Databases and Schemas
# ----------------------------------------------------------------------------
module "database_schemas" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-database-schema?ref=main"

  providers = {
    snowflake = snowflake.db_provisioner
  }

  database_configs = local.database_schemas
}

# ----------------------------------------------------------------------------
# 2.3 File Formats
# ----------------------------------------------------------------------------
module "file_formats" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-file-format?ref=main"

  providers = {
    snowflake = snowflake.data_object_provisioner
  }

  file_format_configs = local.file_formats

  depends_on = [module.database_schemas]
}

# ----------------------------------------------------------------------------
# 2.4 Storage Integrations
# ----------------------------------------------------------------------------
module "storage_integrations" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-storage-integration?ref=main"

  providers = {
    snowflake = snowflake.ingest_object_provisioner
  }

  storage_integration_configs = local.storage_integrations

  depends_on = [module.file_formats]
}

# ----------------------------------------------------------------------------
# 2.5 Stages
# ----------------------------------------------------------------------------
module "stage" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-stage?ref=main"

  providers = {
    snowflake = snowflake.ingest_object_provisioner
  }

  stage_configs = local.stages

  depends_on = [module.storage_integrations]
}

# ----------------------------------------------------------------------------
# 2.6 Tables
# ----------------------------------------------------------------------------
module "table" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-table?ref=main"

  providers = {
    snowflake = snowflake.data_object_provisioner
  }

  table_configs = local.tables

  depends_on = [module.stage]
}

# ----------------------------------------------------------------------------
# 2.7 Table Grants - Grant INSERT and SELECT to INGEST_ADMIN for snowpipe
# ----------------------------------------------------------------------------
resource "snowflake_grant_privileges_to_account_role" "table_grants" {
  for_each = local.tables

  provider = snowflake.data_object_provisioner

  privileges        = ["INSERT", "SELECT"]
  account_role_name = var.ingest_object_provisioner_role
  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${each.value.database}\".\"${each.value.schema}\".\"${each.value.name}\""
  }

  depends_on = [module.table]
}

# ============================================================================
# PHASE 3: AWS Trust Policy Update
# ============================================================================
# Updates the IAM role trust policy with Snowflake credentials from storage integration.
#
# WORKFLOW FOR FRESH DEPLOYMENTS:
# 1. First apply:  terraform apply -var="enable_trust_policy_update=false"
#    - Creates all resources with placeholder trust policy
# 2. Second apply: terraform apply -var="enable_trust_policy_update=true"
#    - Updates trust policy with Snowflake values
# 3. Update input-jsons/aws/config.json with the Snowflake values from output
# 4. Future applies: terraform apply (no flag needed, uses JSON config values)
# ----------------------------------------------------------------------------
locals {
  # Runtime values from module output (only available after storage integration is created)
  aws_storage_integrations       = try(module.storage_integrations.aws_storage_integrations, {})
  first_integration_key          = length(keys(local.aws_storage_integrations)) > 0 ? keys(local.aws_storage_integrations)[0] : null
  first_storage_integration      = local.first_integration_key != null ? local.aws_storage_integrations[local.first_integration_key] : null
  snowflake_iam_user_arn_runtime = try(local.first_storage_integration.describe_output[0].iam_user_arn, "")
  snowflake_external_id_runtime  = try(local.first_storage_integration.describe_output[0].external_id, "")
}


module "aws_iam_role_final" {
  source = "./modules/iam_role_final"

  enabled                = local.has_storage_integration_config
  role_name              = local.iam_role_config.name
  snowflake_iam_user_arn = local.snowflake_iam_user_arn_runtime
  snowflake_external_id  = local.snowflake_external_id_runtime

  depends_on = [module.storage_integrations, module.iam_role]
}


# Update IAM role trust policy with Snowflake credentials (only when explicitly enabled)
# module "iam_trust_policy" {
#   source = "./modules/iam_trust_policy"

#   # Only run when explicitly enabled AND storage integration config exists
#   enabled                = var.enable_trust_policy_update && local.has_storage_integration_config
#   role_name              = local.iam_role_config.name
#   snowflake_iam_user_arn = local.snowflake_iam_user_arn_runtime
#   snowflake_external_id  = local.snowflake_external_id_runtime

#   depends_on = [module.storage_integrations, module.iam_role]
# }

# ============================================================================
# PHASE 4: Snowpipes
# ============================================================================
module "pipe" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-pipe?ref=main"

  providers = {
    snowflake = snowflake.ingest_object_provisioner
  }

  pipe_configs = var.enable_snowpipe_creation ? local.snowpipes : {}

  depends_on = [
    # module.iam_trust_policy,
    module.aws_iam_role_final,
    module.table
  ]
}

# ============================================================================
# PHASE 4: S3 Event Notifications for Snowpipe Auto-Ingest
# ============================================================================
module "s3_notification" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-aws-s3-bucket/modules/event-notification?ref=main"

  bucket_name = local.s3_config.bucket_name

  sqs_notifications = [
    for key, pipe_output in module.pipe.pipes : {
      id            = "${lower(replace(local.snowpipes[key].name, "_", "-"))}-notification"
      queue_arn     = pipe_output.notification_channel
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = lookup(local.snowpipes[key], "filter_prefix", null)
      filter_suffix = lookup(local.snowpipes[key], "filter_suffix", null)
    } if lookup(local.snowpipes[key], "auto_ingest", false) == true
  ]

  depends_on = [module.pipe, module.s3]
}

# ============================================================================
# PHASE 5: Dynamic Tables
# ============================================================================

# ----------------------------------------------------------------------------
# 5.1 Grants for Dynamic Table creation
# ----------------------------------------------------------------------------
# Grant CREATE DYNAMIC TABLE on schemas that have dynamic tables
resource "snowflake_grant_privileges_to_account_role" "schema_create_dynamic_table" {
  for_each = toset(distinct([
    for dt_key, dt in local.dynamic_tables : "${dt.database}.${dt.schema}"
  ]))

  provider = snowflake.db_provisioner

  privileges        = ["CREATE DYNAMIC TABLE"]
  account_role_name = var.data_object_provisioner_role
  on_schema {
    schema_name = "\"${split(".", each.value)[0]}\".\"${split(".", each.value)[1]}\""
  }

  depends_on = [module.database_schemas]
}

# Grant SELECT on source tables for dynamic tables
resource "snowflake_grant_privileges_to_account_role" "dynamic_table_source_select" {
  for_each = {
    for dt_key, dt in local.dynamic_tables : dt_key => dt
    if lookup(dt, "source_schema", null) != null
  }

  provider = snowflake.db_provisioner

  privileges        = ["SELECT"]
  account_role_name = var.data_object_provisioner_role
  on_schema_object {
    object_type = "TABLE"
    object_name = "\"${each.value.database}\".\"${lookup(each.value, "source_schema", "BRONZE")}\".\"${lookup(each.value, "source_table", "RAW_AQI")}\""
  }

  depends_on = [module.table]
}

# Grant USAGE on warehouse for dynamic table refresh
resource "snowflake_grant_privileges_to_account_role" "dynamic_table_warehouse_usage" {
  for_each = toset(distinct([
    for dt_key, dt in local.dynamic_tables : dt.warehouse if dt.warehouse != null
  ]))

  provider = snowflake.warehouse_provisioner

  privileges        = ["USAGE"]
  account_role_name = var.data_object_provisioner_role
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = each.value
  }

  depends_on = [module.warehouse]
}

# ----------------------------------------------------------------------------
# 5.2 Dynamic Table Module
# ----------------------------------------------------------------------------
module "dynamic_table" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-dynamic-table?ref=main"

  providers = {
    snowflake = snowflake.data_object_provisioner
  }

  dynamic_table_configs = local.dynamic_tables

  depends_on = [
    module.database_schemas,
    module.table,
    snowflake_grant_privileges_to_account_role.schema_create_dynamic_table,
    snowflake_grant_privileges_to_account_role.dynamic_table_source_select,
    snowflake_grant_privileges_to_account_role.dynamic_table_warehouse_usage
  ]
}