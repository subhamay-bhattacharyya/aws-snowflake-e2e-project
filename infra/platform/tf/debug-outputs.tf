# # -- infra/platform/tf/debug-outputs.tf (Platform Module)
# # ============================================================================
# # Debug Outputs - Local Variable Values for Debugging/Verification
# # ============================================================================

# output "local_s3_config" {
#   description = "S3 configuration from locals"
#   value       = local.s3_config
# }

# output "local_iam_role_config" {
#   description = "IAM role configuration from locals"
#   sensitive   = true
#   value       = local.iam_role_config
# }

# output "local_warehouses" {
#   description = "Warehouse configurations from locals"
#   value       = local.warehouses
# }

# output "local_database_schemas" {
#   description = "Database and schema configurations from locals"
#   value       = local.database_schemas
# }

# output "local_file_formats" {
#   description = "File format configurations from locals"
#   value       = local.file_formats
# }

# output "local_storage_integrations" {
#   description = "Storage integration configurations from locals"
#   value       = local.storage_integrations
# }

# output "local_stages" {
#   description = "Stage configurations from locals"
#   value       = local.stages
# }

# output "local_tables" {
#   description = "Table configurations from locals"
#   value       = local.tables
# }

# output "has_storage_integration" {
#   description = "Whether a storage integration exists"
#   sensitive   = true
#   value       = local.has_storage_integration
# }

# output "first_storage_integration" {
#   description = "First storage integration details"
#   sensitive   = true
#   value       = local.first_storage_integration
# }

# output "snowflake_iam_user_arn" {
#   description = "Snowflake IAM user ARN from storage integration"
#   value       = local.snowflake_iam_user_arn
# }

# output "snowflake_external_id" {
#   description = "Snowflake external ID from storage integration"
#   value       = local.snowflake_external_id_output
# }

# output "storage_integration_keys" {
#   description = "storage_integration_keys"
#   sensitive   = true
#   value       = local.storage_integration_keys
# }

# output "local_iam_role_config" {
#   description = "IAM role configuration from locals"
#   sensitive   = true
#   value       = local.iam_role_config
# }

# # Debug outputs for Phase 3 trust policy update
# output "debug_has_storage_integration" {
#   description = "Whether storage integration exists"
#   sensitive   = true
#   value       = local.has_storage_integration
# }

# output "debug_snowflake_iam_user_arn" {
#   description = "Snowflake IAM user ARN"
#   sensitive   = true
#   value       = local.snowflake_iam_user_arn
# }

# output "debug_snowflake_external_id" {
#   description = "Snowflake external ID"
#   sensitive   = true
#   value       = local.snowflake_external_id_output
# }

# output "debug_first_storage_integration" {
#   description = "First storage integration describe_output"
#   sensitive   = true
#   value       = local.first_storage_integration
# }


# output "debug_snowpipes" {
#   description = "Snowpipes configuration from locals"
#   sensitive   = true
#   value       = local.snowpipes
# }
