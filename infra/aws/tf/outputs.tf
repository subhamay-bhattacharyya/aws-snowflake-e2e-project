# -- infra/aws/tf/outputs.tf (Child Module)

############ S3 Bucket Outputs ############################
output "s3_bucket_name" {
  description = "S3 bucket name used for static website"
  value       = module.s3.name
}
output "s3_bucket_region" {
  description = "S3 bucket region"
  value       = module.s3.bucket_region
}
output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}
output "s3_versioning_status" {
  description = "S3 bucket versioning status"
  value       = module.s3.versioning_status
}
############ IAM Role Outputs ############################
output "iam_role_arn" {
  description = "IAM role ARN for Snowflake storage integration"
  value       = module.iam_role.iam_role_arn
}
############ IAM Role Final (Phase 3) Outputs ############################
output "trust_policy_updated" {
  description = "Whether the trust policy was updated"
  value       = module.iam_role_final.trust_policy_updated
}
output "trust_policy" {
  description = "The trust policy that was applied."
  value       = module.iam_role_final.trust_policy
}

