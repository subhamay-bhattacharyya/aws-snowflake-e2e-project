# -- infra/platform/tf/providers-aws.tf (Platform Module)
# ============================================================================
# AWS Provider Configuration
# ============================================================================
# NOTE: required_providers block is in backend.tf
# ============================================================================

provider "aws" {
  region = local.aws_config.region

  default_tags {
    tags = {
      Project     = var.project_code
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
