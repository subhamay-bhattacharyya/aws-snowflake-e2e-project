# -- infra/aws/tf/modules/iam_trust_policy/outputs.tf

output "role_arn" {
  description = "ARN of the IAM role"
  value       = var.enabled ? data.aws_iam_role.existing[0].arn : null
}

output "trust_policy_updated" {
  description = "Whether trust policy was updated"
  value       = var.enabled
}
