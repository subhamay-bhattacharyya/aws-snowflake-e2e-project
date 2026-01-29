# -- infra/aws/tf/modules/iam_role_final/main.tf (Child Module)
# ============================================================================
# IAM Role Trust Policy Update Module
# ============================================================================
# This module updates the IAM role trust policy with Snowflake's actual
# STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID values from the
# storage integration.
# ============================================================================

# Use aws_iam_role data source to get the existing role
data "aws_iam_role" "existing" {
  count = var.enabled ? 1 : 0
  name  = var.role_name
}

# Update the trust policy using aws_iam_role_policy resource won't work for trust policies
# We need to use a null_resource with local-exec, but force it to always run
resource "null_resource" "update_trust_policy" {
  count = var.enabled ? 1 : 0

  # Always trigger on every apply to ensure trust policy is correct
  triggers = {
    always_run             = timestamp()
    snowflake_iam_user_arn = var.snowflake_iam_user_arn
    snowflake_external_id  = var.snowflake_external_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Updating IAM trust policy for role: ${var.role_name}"
      echo "Snowflake IAM User ARN: ${var.snowflake_iam_user_arn}"
      echo "Snowflake External ID: ${var.snowflake_external_id}"
      aws iam update-assume-role-policy \
        --role-name ${var.role_name} \
        --policy-document '${local.trust_policy}'
      echo "Trust policy updated successfully"
    EOT
  }
}

locals {
  trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.snowflake_iam_user_arn }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "sts:ExternalId" = var.snowflake_external_id
        }
      }
    }]
  })
}
