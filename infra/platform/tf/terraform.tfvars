# -- infra/platform/tf/terraform.tfvars (Platform Module)
# ============================================================================
# Terraform Variable Values
# ============================================================================

# ----------------------------------------------------------------------------
# Snowflake Provider Configuration
# ----------------------------------------------------------------------------
snowflake_organization_name    = "AVDNPDD"
snowflake_account_name         = "DOC83156"
snowflake_user                 = "GITHUB_ACTIONS_USER"
db_provisioner_role            = "PLATFORM_DB_OWNER"
warehouse_provisioner_role     = "WAREHOUSE_ADMIN"
data_object_provisioner_role   = "DATA_OBJECT_ADMIN"
ingest_object_provisioner_role = "INGEST_ADMIN"
snowflake_warehouse            = "UTIL_WH"
# For CI/CD: Set SNOWFLAKE_PRIVATE_KEY environment variable with key content
aws_config_path       = "../../../input-jsons/aws/config.json"
snowflake_config_path = "../../../input-jsons/snowflake/config.json"
# ----------------------------------------------------------------------------
# Project Configuration
# ----------------------------------------------------------------------------
project_code = "e2eproj"
