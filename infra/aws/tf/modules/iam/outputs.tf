# -- infra/aws/tf/modules/iam/outputs.tf (Child Module)

output "iam_role_arn" {
  description = "IAM role name for testing"
  value       = aws_iam_role.this.arn
}