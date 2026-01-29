# -- infra/platform/tf/outputs.tf (Platform Module)
# ============================================================================
# Platform Module (S3 and IAM) Outputs
# ============================================================================

# ----------------------------------------------------------------------------
# AWS Outputs
# ----------------------------------------------------------------------------
output "s3_bucket_arn" {
  description = "S3 bucket ARN for Snowflake external stage"
  value       = module.aws.s3_bucket_arn
}

output "iam_role_arn" {
  description = "IAM role ARN for Snowflake storage integration"
  value       = module.aws.iam_role_arn
}

# ----------------------------------------------------------------------------
# Snowflake Outputs 
# ----------------------------------------------------------------------------
output "warehouses" {
  description = "Map of warehouse names to their details"
  value = {
    for k, v in module.snowflake.warehouses : k => {
      warehouse_type            = v.warehouse_type
      warehouse_size            = v.warehouse_size
      comment                   = v.comment
      auto_suspend              = v.auto_suspend
      auto_resume               = v.auto_resume
      initially_suspended       = v.initially_suspended
      enable_query_acceleration = v.enable_query_acceleration
      warehouse_type            = v.warehouse_type
      min_cluster_count         = v.min_cluster_count
      max_cluster_count         = v.max_cluster_count
    }
  }
}
output "databases" {
  description = "Map of databases names to their details"
  value       = module.snowflake.databases
}
output "schemas" {
  description = "Map of databases schemas to their details"
  value       = module.snowflake.schemas
}
output "file_formats" {
  description = "Map of file formats to their details"
  value       = module.snowflake.file_formats
}
output "storage_integrations" {
  description = "Storage integration names"
  value       = module.snowflake.storage_integrations
}
output "stages" {
  description = "Stage names"
  value       = module.snowflake.stages
}
output "storage_aws_external_id" {
  description = "storage_aws_external_id"
  value       = local.snowflake_external_id_output
}
