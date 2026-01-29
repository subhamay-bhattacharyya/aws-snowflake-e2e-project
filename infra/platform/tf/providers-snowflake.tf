# -- infra/platform/tf/providers-snowflake.tf (Platform Module)
# ============================================================================
# Snowflake Provider Configuration
# ============================================================================
# Authentication priority:
# 1. snowflake_private_key (direct content - for CI/CD)
# 2. snowflake_private_key_path (file path - for local development)
# 3. SNOWFLAKE environment variables (fallback)
# ============================================================================

locals {
  # Use direct key content if provided, otherwise try to read from file path
  snowflake_private_key = var.snowflake_private_key != "" ? var.snowflake_private_key : (
    var.snowflake_private_key_path != "" && fileexists(var.snowflake_private_key_path) ? file(var.snowflake_private_key_path) : null
  )
  use_jwt_auth = local.snowflake_private_key != null
}

provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  role              = var.snowflake_role
  authenticator     = local.use_jwt_auth ? "JWT" : "SNOWFLAKE"
  private_key       = local.snowflake_private_key
  warehouse         = var.snowflake_warehouse
}
