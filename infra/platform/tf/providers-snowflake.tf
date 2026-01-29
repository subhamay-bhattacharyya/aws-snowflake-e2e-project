# -- infra/platform/tf/providers-snowflake.tf (Platform Module)
# ============================================================================
# Snowflake Provider Configuration
# ============================================================================
# Authentication: Uses JWT with private key via SNOWFLAKE_PRIVATE_KEY env var
# 
# Required environment variables (set in CI/CD workflow):
#   - SNOWFLAKE_PRIVATE_KEY (the private key content)
#
# Optional environment variables (or use terraform.tfvars):
#   - SNOWFLAKE_ORGANIZATION_NAME
#   - SNOWFLAKE_ACCOUNT_NAME
#   - SNOWFLAKE_USER
#   - SNOWFLAKE_ROLE
#   - SNOWFLAKE_WAREHOUSE
# ============================================================================

provider "snowflake" {
  organization_name = var.snowflake_organization_name != "" ? var.snowflake_organization_name : null
  account_name      = var.snowflake_account_name != "" ? var.snowflake_account_name : null
  user              = var.snowflake_user != "" ? var.snowflake_user : null
  role              = var.snowflake_role != "" ? var.snowflake_role : null
  warehouse         = var.snowflake_warehouse != "" ? var.snowflake_warehouse : null
  authenticator     = "JWT"
  # private_key is read from SNOWFLAKE_PRIVATE_KEY environment variable automatically
}
