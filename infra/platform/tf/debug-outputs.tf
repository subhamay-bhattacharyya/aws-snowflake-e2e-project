# -- infra/platform/tf/debug-outputs.tf (Platform Module)
# ============================================================================
# Debug Outputs - For troubleshooting trust policy update
# ============================================================================

# output "debug_aws_storage_integrations" {
#   description = "AWS storage integrations from module"
#   sensitive   = true
#   value       = local.aws_storage_integrations
# }

# output "debug_first_integration_key" {
#   description = "First integration key"
#   sensitive   = true
#   value       = local.first_integration_key
# }

# output "debug_snowflake_iam_user_arn" {
#   description = "Snowflake IAM user ARN extracted from storage integration"
#   sensitive   = true
#   value       = local.snowflake_iam_user_arn_output
# }

# output "debug_snowflake_external_id" {
#   description = "Snowflake external ID extracted from storage integration"
#   sensitive   = true
#   value       = local.snowflake_external_id_output
# }

# output "debug_has_storage_integration_config" {
#   description = "Whether storage integration is configured in JSON"
#   value       = local.has_storage_integration_config
# }

# output "debug_first_storage_integration" {
#   description = "First storage integration object"
#   sensitive   = true
#   value       = local.first_storage_integration
# }
