# ============================================================================
# Terraform Tests for Configuration Validation
# ============================================================================
# These tests validate the JSON configuration files are properly structured.
# Run with: terraform test
# ============================================================================

# ----------------------------------------------------------------------------
# Mock Providers
# ----------------------------------------------------------------------------
mock_provider "aws" {}
mock_provider "snowflake" {
  alias = "warehouse_provisioner"
}
mock_provider "snowflake" {
  alias = "db_provisioner"
}
mock_provider "snowflake" {
  alias = "data_object_provisioner"
}
mock_provider "snowflake" {
  alias = "ingest_object_provisioner"
}

# ----------------------------------------------------------------------------
# Test: Configuration File Paths
# ----------------------------------------------------------------------------
run "test_config_paths_default" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "test"
  }

  assert {
    condition     = var.aws_config_path == "../../../input-jsons/aws/config.json"
    error_message = "Default AWS config path should be '../../../input-jsons/aws/config.json'"
  }

  assert {
    condition     = var.snowflake_config_path == "../../../input-jsons/snowflake/config.json"
    error_message = "Default Snowflake config path should be '../../../input-jsons/snowflake/config.json'"
  }
}

# ----------------------------------------------------------------------------
# Test: Snowflake Warehouse Default
# ----------------------------------------------------------------------------
run "test_snowflake_warehouse_default" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "test"
  }

  assert {
    condition     = var.snowflake_warehouse == "COMPUTE_WH"
    error_message = "Default Snowflake warehouse should be 'COMPUTE_WH'"
  }
}
