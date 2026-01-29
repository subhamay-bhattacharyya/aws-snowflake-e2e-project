# -- infra/aws/tf/versions.tf (Child Module)
# ============================================================================
# Terraform Version and Provider Requirements
# ============================================================================

terraform {
  required_version = ">= 1.14.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
