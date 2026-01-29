# -- infra/platform/tf/terraform.tfvars (Platform Module)
# ============================================================================
# Terraform Variable Values
# ============================================================================

# ----------------------------------------------------------------------------
# Snowflake Provider Configuration
# ----------------------------------------------------------------------------
snowflake_organization_name = "AGXUOKJ"
snowflake_account_name      = "JKC15404"
snowflake_user              = "GH_ACTIONS_USER"
snowflake_role              = "ACCOUNTADMIN"
snowflake_warehouse         = "UTIL_WH"
# snowflake_private_key_path  = "snowflake_key.p8"  # Uncomment for local development
# For CI/CD: Set TF_VAR_snowflake_private_key environment variable with key content
aws_config_path       = "../../../input-jsons/aws/config.json"
snowflake_config_path = "../../../input-jsons/snowflake/config.json"
# ----------------------------------------------------------------------------
# Project Configuration
# ----------------------------------------------------------------------------
project_code = "subham"
