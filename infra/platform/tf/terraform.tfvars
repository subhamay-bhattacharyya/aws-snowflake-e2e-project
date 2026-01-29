# -- infra/platform/tf/terraform.tfvars (Platform Module)
# ============================================================================
# Terraform Variable Values
# ============================================================================


project_code = "sb"
# ----------------------------------------------------------------------------
# Snowflake Provider Configuration
# ----------------------------------------------------------------------------
snowflake_organization_name = "AGXUOKJ"
snowflake_account_name      = "JKC15404"
snowflake_user              = "GH_ACTIONS_USER"
snowflake_role              = "ACCOUNTADMIN"
snowflake_warehouse         = "UTIL_WH"
snowflake_private_key_path  = "../../snowflake/tf/snowflake_tf_keys/snowflake_tf_key.p8"
aws_config_path             = "../../../input-jsons/aws/config.json"
snowflake_config_path       = "../../../input-jsons/snowflake/config.json"
