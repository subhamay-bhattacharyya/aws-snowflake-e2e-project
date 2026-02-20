# -- infra/aws/tf/modules/iam_trust_policy/main.tf
# ============================================================================
# IAM Trust Policy Update Module
# ============================================================================
# Updates an existing IAM role's assume role policy (trust policy)
# ============================================================================

# Get the existing role
data "aws_iam_role" "existing" {
  count = var.enabled ? 1 : 0
  name  = var.role_name
}

# Update the trust policy using AWS CLI
resource "terraform_data" "update_trust_policy" {
  count = var.enabled ? 1 : 0

  # Trigger update when Snowflake values change
  triggers_replace = {
    snowflake_iam_user_arn = var.snowflake_iam_user_arn
    snowflake_external_id  = var.snowflake_external_id
    role_name              = var.role_name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Updating trust policy for role: ${var.role_name}"
      echo "Snowflake IAM User ARN: ${var.snowflake_iam_user_arn}"
      echo "Snowflake External ID: ${var.snowflake_external_id}"
      
      aws iam update-assume-role-policy \
        --role-name ${var.role_name} \
        --policy-document '{
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "AWS": "${var.snowflake_iam_user_arn}"
              },
              "Action": "sts:AssumeRole",
              "Condition": {
                "StringEquals": {
                  "sts:ExternalId": "${var.snowflake_external_id}"
                }
              }
            }
          ]
        }'
      
      echo "Trust policy updated successfully"
    EOT
  }

  depends_on = [data.aws_iam_role.existing]
}
