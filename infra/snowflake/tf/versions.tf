# -- infra/snowflake/tf/versions.tf (Child Module)
# ============================================================================
# Required Providers
# ============================================================================
# NOTE: This tells Terraform to use snowflakedb/snowflake, not hashicorp/snowflake
# ============================================================================

terraform {
  required_providers {
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }
}
