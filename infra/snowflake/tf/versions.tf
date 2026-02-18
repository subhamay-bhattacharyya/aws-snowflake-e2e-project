# -- infra/snowflake/tf/versions.tf (Child Module)
# ============================================================================
# Required Providers
# ============================================================================
# NOTE: This tells Terraform to use snowflakedb/snowflake, not hashicorp/snowflake
# ============================================================================

terraform {
  required_providers {
    snowflake = {
      source                = "snowflakedb/snowflake"
      version               = ">= 1.0.0"
      configuration_aliases = [
        snowflake.db_provisioner,
        snowflake.warehouse_provisioner,
        snowflake.data_object_provisioner,
        snowflake.ingest_object_provisioner
      ]
    }
  }
}
