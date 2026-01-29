# -- infra/aws/tf/modules/iam_role_final/outputs.tf (Child Module)
# ============================================================================
# IAM Role Trust Policy Update Module - Outputs
# ============================================================================

output "trust_policy_updated" {
  description = "Whether the trust policy was updated"
  value       = var.enabled
}

output "trust_policy" {
  description = "The trust policy that was applied"
  value       = local.trust_policy
}
