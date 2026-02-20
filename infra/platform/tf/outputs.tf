# -- infra/platform/tf/outputs.tf (Platform Module)
# ============================================================================
# Platform Module Outputs
# ============================================================================

# ============================================================================
# AWS Outputs
# ============================================================================

# ----------------------------------------------------------------------------
# S3 Bucket Outputs
# ----------------------------------------------------------------------------
output "s3_bucket" {
  description = "S3 bucket details for Snowflake external stage"
  value = {
    name              = module.s3.bucket_id
    arn               = module.s3.bucket_arn
    region            = module.s3.bucket_region
    versioning_status = module.s3.versioning_status
  }
}

# ----------------------------------------------------------------------------
# IAM Role Outputs
# ----------------------------------------------------------------------------
output "iam_role" {
  description = "IAM role details for Snowflake storage integration"
  value = {
    arn  = module.iam_role.role_arn
    name = module.iam_role.role_name
  }
}

# # ============================================================================
# # Snowflake Outputs
# # ============================================================================

# ----------------------------------------------------------------------------
# 1. Warehouses
# ----------------------------------------------------------------------------
output "warehouses" {
  description = "Map of warehouse names to their details"
  value = {
    for k, v in module.warehouse.warehouses : k => {
      name                      = v.name
      fully_qualified_name      = v.fully_qualified_name
      warehouse_size            = v.warehouse_size
      warehouse_type            = v.warehouse_type
      auto_suspend              = v.auto_suspend
      auto_resume               = v.auto_resume
      initially_suspended       = v.initially_suspended
      enable_query_acceleration = v.enable_query_acceleration
      min_cluster_count         = v.min_cluster_count
      max_cluster_count         = v.max_cluster_count
      scaling_policy            = v.scaling_policy
      comment                   = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# 2. Databases and Schemas
# ----------------------------------------------------------------------------
output "database_schemas" {
  description = "Map of database names with their details"
  value = {
    for k, v in module.database_schemas.databases : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      comment              = v.comment
    }
  }
}

output "schemas" {
  description = "Map of schema names to their details"
  value = {
    for k, v in module.database_schemas.schemas : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      database             = v.database
      comment              = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# 3. File Formats
# ----------------------------------------------------------------------------
output "file_formats" {
  description = "Map of file format names to their details"
  value = {
    for k, v in module.file_formats.file_formats : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      database             = v.database
      schema               = v.schema
      format_type          = v.format_type
      comment              = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# 4. Storage Integrations
# ----------------------------------------------------------------------------
output "storage_integrations" {
  description = "Storage integration outputs from module"
  sensitive   = true
  value       = module.storage_integrations
}

# ----------------------------------------------------------------------------
# 5. Stages
# ----------------------------------------------------------------------------
output "stages" {
  description = "Stage outputs from module"
  value       = module.stage
}

# ----------------------------------------------------------------------------
# 6. Tables
# ----------------------------------------------------------------------------
output "tables" {
  description = "Table outputs from module"
  value       = module.table
}

# ----------------------------------------------------------------------------
# 7. Snowpipes
# ----------------------------------------------------------------------------
output "snowpipes" {
  description = "Map of snowpipe names to their details"
  value       = module.pipe.pipes
}

# ----------------------------------------------------------------------------
# 8. Dynamic tables
# ----------------------------------------------------------------------------
output "dynamic_tables" {
  description = "Map of dynamic tables to their details"
  value       = module.dynamic_table
}
