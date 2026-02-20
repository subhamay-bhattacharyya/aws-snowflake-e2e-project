# -- infra/platform/tf/modules/iam_trust_policy/main.tf
# ============================================================================
# IAM Trust Policy Update Module
# ============================================================================
# Updates an existing IAM role's assume role policy (trust policy) using AWS CLI
# ============================================================================

locals {
  # Build the trust policy JSON
  trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.snowflake_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.snowflake_external_id
          }
        }
      }
    ]
  })
}

# Update the trust policy using AWS CLI via null_resource
# Always created, but only runs when enabled and values are non-empty
resource "null_resource" "update_trust_policy" {
  # Trigger update when any of these values change
  triggers = {
    enabled                = var.enabled
    snowflake_iam_user_arn = var.snowflake_iam_user_arn
    snowflake_external_id  = var.snowflake_external_id
    role_name              = var.role_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      if [ "${var.enabled}" = "true" ] && [ -n "${var.snowflake_iam_user_arn}" ] && [ -n "${var.snowflake_external_id}" ]; then
        echo "Updating IAM Trust Policy for role: ${var.role_name}"
        echo "Snowflake IAM User ARN: ${var.snowflake_iam_user_arn}"
        echo "Snowflake External ID: ${var.snowflake_external_id}"
        
        aws iam update-assume-role-policy \
          --role-name "${var.role_name}" \
          --policy-document '${local.trust_policy}'
        
        echo "Trust policy updated successfully!"
      else
        echo "Skipping trust policy update (enabled=${var.enabled}, arn=${var.snowflake_iam_user_arn}, external_id=${var.snowflake_external_id})"
      fi
    EOT
  }
}

output "trust_policy_updated" {
  description = "Whether the trust policy update was attempted"
  value       = var.enabled && var.snowflake_iam_user_arn != "" && var.snowflake_external_id != ""
}

output "trust_policy_json" {
  description = "The trust policy JSON that was applied"
  value       = var.enabled ? local.trust_policy : null
}
