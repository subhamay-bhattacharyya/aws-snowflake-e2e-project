# -- infra/platform/tf/providers-snowflake.tf (Platform Module)
# ============================================================================
# Snowflake Provider Configuration
# ============================================================================
# NOTE: required_providers block is in backend.tf
# ============================================================================

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = var.snowflake_private_key_path != "" ? "JWT" : "SNOWFLAKE"
  private_key       = var.snowflake_private_key_path != "" ? file(var.snowflake_private_key_path) : null
  warehouse         = var.snowflake_warehouse
}
