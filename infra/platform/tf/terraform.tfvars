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
# For CI/CD: Set SNOWFLAKE_PRIVATE_KEY environment variable with key content
aws_config_path       = "../../../input-jsons/aws/config.json"
snowflake_config_path = "../../../input-jsons/snowflake/config.json"
# ----------------------------------------------------------------------------
# Project Configuration
# ----------------------------------------------------------------------------
project_code = "subhamay"
