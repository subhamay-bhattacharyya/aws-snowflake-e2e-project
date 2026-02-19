# -- infra/platform/tf/providers-snowflake.tf (Platform Module)
# ============================================================================
# Snowflake Provider Configuration
# ============================================================================
# Authentication: Uses JWT with private key via SNOWFLAKE_PRIVATE_KEY env var
# 
# Required environment variables (set in CI/CD workflow):
#   - SNOWFLAKE_PRIVATE_KEY (the private key content)
#
# Provider Aliases:
#   - default (db_provisioner_role)    : Database/Schema creation
#   - warehouse_provisioner            : Warehouse creation
#   - data_object_provisioner          : File formats, tables
#   - ingest_object_provisioner        : Storage integrations, stages, pipes
# ============================================================================

# Default provider - uses db_provisioner_role for database/schema operations
provider "snowflake" {
  organization_name = var.snowflake_organization_name != "" ? var.snowflake_organization_name : null
  account_name      = var.snowflake_account_name != "" ? var.snowflake_account_name : null
  user              = var.snowflake_user != "" ? var.snowflake_user : null
  role              = var.db_provisioner_role != "" ? var.db_provisioner_role : null
  warehouse         = var.snowflake_warehouse != "" ? var.snowflake_warehouse : null
  authenticator     = "SNOWFLAKE_JWT"

  params = {
    query_tag = "${var.project_code}-terraform-db-provisioner"
  }

  preview_features_enabled = [
    "snowflake_file_format_resource",
    "snowflake_storage_integration_aws_resource",
    "snowflake_stage_internal_resource",
    "snowflake_stage_external_s3_resource",
    "snowflake_pipe_resource"
  ]
}

provider "snowflake" {
  alias             = "warehouse_provisioner"
  organization_name = var.snowflake_organization_name != "" ? var.snowflake_organization_name : null
  account_name      = var.snowflake_account_name != "" ? var.snowflake_account_name : null
  user              = var.snowflake_user != "" ? var.snowflake_user : null
  role              = var.warehouse_provisioner_role != "" ? var.warehouse_provisioner_role : null
  warehouse         = var.snowflake_warehouse != "" ? var.snowflake_warehouse : null
  authenticator     = "SNOWFLAKE_JWT"

  params = {
    query_tag = "${var.project_code}-terraform-warehouse-provisioner"
  }

  preview_features_enabled = [
    "snowflake_file_format_resource",
    "snowflake_storage_integration_aws_resource",
    "snowflake_stage_internal_resource",
    "snowflake_stage_external_s3_resource"
  ]
}

provider "snowflake" {
  alias             = "data_object_provisioner"
  organization_name = var.snowflake_organization_name != "" ? var.snowflake_organization_name : null
  account_name      = var.snowflake_account_name != "" ? var.snowflake_account_name : null
  user              = var.snowflake_user != "" ? var.snowflake_user : null
  role              = var.data_object_provisioner_role != "" ? var.data_object_provisioner_role : null
  warehouse         = var.snowflake_warehouse != "" ? var.snowflake_warehouse : null
  authenticator     = "SNOWFLAKE_JWT"

  params = {
    query_tag = "${var.project_code}-terraform-data-object-provisioner"
  }

  preview_features_enabled = [
    "snowflake_file_format_resource",
    "snowflake_storage_integration_aws_resource",
    "snowflake_stage_internal_resource",
    "snowflake_stage_external_s3_resource",
    "snowflake_pipe_resource"
  ]
}

provider "snowflake" {
  alias             = "ingest_object_provisioner"
  organization_name = var.snowflake_organization_name != "" ? var.snowflake_organization_name : null
  account_name      = var.snowflake_account_name != "" ? var.snowflake_account_name : null
  user              = var.snowflake_user != "" ? var.snowflake_user : null
  role              = var.ingest_object_provisioner_role != "" ? var.ingest_object_provisioner_role : null
  warehouse         = var.snowflake_warehouse != "" ? var.snowflake_warehouse : null
  authenticator     = "SNOWFLAKE_JWT"

  params = {
    query_tag = "${var.project_code}-terraform-ingest-object-provisioner"
  }

  preview_features_enabled = [
    "snowflake_file_format_resource",
    "snowflake_storage_integration_aws_resource",
    "snowflake_stage_internal_resource",
    "snowflake_stage_external_s3_resource",
    "snowflake_pipe_resource"
  ]
}
