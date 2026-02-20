# -- infra/platform/tf/outputs.tf (Platform Module)
# ============================================================================
# Platform Module (S3 and IAM) Outputs
# ============================================================================

# ----------------------------------------------------------------------------
# AWS S3 Bucket Outputs
# ----------------------------------------------------------------------------
output "s3_bucket" {
  description = "S3 bucket details for Snowflake external stage"
  value = {
    name              = module.aws.s3_bucket_name
    arn               = module.aws.s3_bucket_arn
    region            = module.aws.s3_bucket_region
    versioning_status = module.aws.s3_versioning_status
  }
}

# ----------------------------------------------------------------------------
# AWS IAM Role Outputs
# ----------------------------------------------------------------------------
output "iam_role" {
  description = "IAM role details for Snowflake storage integration"
  value = {
    arn  = module.aws.iam_role_arn
    name = module.aws.iam_role_name
  }
}


# ----------------------------------------------------------------------------
# Snowflake Outputs 
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# 1. Warehouses
# ----------------------------------------------------------------------------
output "warehouses" {
  description = "Map of warehouse names to their details"
  value = length(local.warehouses) > 0 ? {
    for k, v in module.snowflake.warehouses : k => {
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
  } : null
}

# ----------------------------------------------------------------------------
# 2. Databases and Schemas
# ----------------------------------------------------------------------------
output "database_schemas" {
  description = "Map of database names with their details and granted roles"
  value = {
    for k, v in module.snowflake.database_schemas : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      comment              = v.comment
      grants               = local.database_schemas[k].grants
      schemas = [
        for idx, schema in local.database_schemas[k].schemas : {
          name   = schema.name
          grants = schema.grants
        }
      ]
    }
  }
}

output "schemas" {
  description = "Map of schema names to their details"
  value = {
    for k, v in module.snowflake.schemas : k => {
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
    for k, v in module.snowflake.file_formats : k => {
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
  description = "Map of storage integration names to their details"
  sensitive   = true
  value = {
    for k, v in module.snowflake.storage_integrations : k => {
      name                      = v.name
      fully_qualified_name      = v.fully_qualified_name
      storage_provider          = v.storage_provider
      storage_aws_role_arn      = v.storage_aws_role_arn
      storage_allowed_locations = v.storage_allowed_locations
      enabled                   = v.enabled
      comment                   = v.comment
      describe_output           = v.describe_output
    }
  }
}

# ----------------------------------------------------------------------------
# 5. Stages
# ----------------------------------------------------------------------------

output "stages" {
  description = "Map of stage names to their details"
  value = {
    internal = {
      for k, v in module.snowflake.stages.internal : k => {
        name                 = v.name
        fully_qualified_name = v.fully_qualified_name
        database             = v.database
        schema               = v.schema
        comment              = v.comment
      }
    }
    external = {
      for k, v in module.snowflake.stages.external : k => {
        name                 = v.name
        fully_qualified_name = v.fully_qualified_name
        database             = v.database
        schema               = v.schema
        url                  = v.url
        storage_integration  = v.storage_integration
        comment              = v.comment
      }
    }
  }
}

# ----------------------------------------------------------------------------
# 6. Tables
# ----------------------------------------------------------------------------

output "tables" {
  description = "Map of table names to their details"
  value = {
    for k, v in module.snowflake.tables : k => {
      name                 = v.name
      fully_qualified_name = v.fully_qualified_name
      database             = v.database
      schema               = v.schema
      table_type           = v.table_type
      columns = [
        for col in v.columns : {
          name          = col.name
          type          = col.type
          nullable      = col.nullable
          comment       = col.comment
          autoincrement = col.autoincrement
        }
      ]
      comment = v.comment
    }
  }
}

# ----------------------------------------------------------------------------
# 7. Snowpipes
# ----------------------------------------------------------------------------

output "snowpipes" {
  description = "Map of snowpipe names to their details"
  sensitive   = true
  value       = module.pipe.pipes
}
