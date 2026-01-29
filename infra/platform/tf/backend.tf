# -- infra/platform/tf/backend.tf (Platform Module)
# ============================================================================
# Terraform Backend Configuration
# ============================================================================

terraform {
  cloud {

    organization = "subhamay-bhattacharyya-projects"

    workspaces {
      name = "aws-snowflake-e2e-project"
    }
  }
}
