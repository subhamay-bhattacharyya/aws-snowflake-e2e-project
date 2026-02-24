# ============================================================================
# Terraform Tests for Platform Module
# ============================================================================
# These tests validate the Terraform configuration without deploying resources.
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
# Test: Variable Validation - Environment
# ----------------------------------------------------------------------------
run "test_environment_validation_devl" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "test"
  }

  assert {
    condition     = var.environment == "devl"
    error_message = "Environment should be devl"
  }
}

run "test_environment_validation_test" {
  command = plan

  variables {
    environment  = "test"
    project_code = "test"
  }

  assert {
    condition     = var.environment == "test"
    error_message = "Environment should be test"
  }
}

run "test_environment_validation_prod" {
  command = plan

  variables {
    environment  = "prod"
    project_code = "test"
  }

  assert {
    condition     = var.environment == "prod"
    error_message = "Environment should be prod"
  }
}

# ----------------------------------------------------------------------------
# Test: Project Code Configuration
# ----------------------------------------------------------------------------
run "test_project_code_default" {
  command = plan

  variables {
    environment = "devl"
  }

  assert {
    condition     = var.project_code == "snw"
    error_message = "Default project code should be 'snw'"
  }
}

run "test_project_code_custom" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "custom"
  }

  assert {
    condition     = var.project_code == "custom"
    error_message = "Custom project code should be 'custom'"
  }
}

# ----------------------------------------------------------------------------
# Test: Feature Flags
# ----------------------------------------------------------------------------
run "test_snowpipe_creation_enabled_by_default" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "test"
  }

  assert {
    condition     = var.enable_snowpipe_creation == true
    error_message = "Snowpipe creation should be enabled by default"
  }
}

run "test_trust_policy_update_disabled_by_default" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "test"
  }

  assert {
    condition     = var.enable_trust_policy_update == false
    error_message = "Trust policy update should be disabled by default"
  }
}

# ----------------------------------------------------------------------------
# Test: Snowflake Role Configuration
# ----------------------------------------------------------------------------
run "test_snowflake_roles_defaults" {
  command = plan

  variables {
    environment  = "devl"
    project_code = "test"
  }

  assert {
    condition     = var.db_provisioner_role == "DB_PROVISIONER"
    error_message = "Default db_provisioner_role should be 'DB_PROVISIONER'"
  }

  assert {
    condition     = var.warehouse_provisioner_role == "WAREHOUSE_PROVISIONER"
    error_message = "Default warehouse_provisioner_role should be 'WAREHOUSE_PROVISIONER'"
  }

  assert {
    condition     = var.data_object_provisioner_role == "DATA_OBJECT_PROVISIONER"
    error_message = "Default data_object_provisioner_role should be 'DATA_OBJECT_PROVISIONER'"
  }

  assert {
    condition     = var.ingest_object_provisioner_role == "INGEST_OBJECT_PROVISIONER"
    error_message = "Default ingest_object_provisioner_role should be 'INGEST_OBJECT_PROVISIONER'"
  }
}
