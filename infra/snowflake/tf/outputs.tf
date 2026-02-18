# -- infra/snowflake/tf/outputs.tf (Child Module)
# ============================================================================
# Snowflake Module Outputs
# ============================================================================

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
  description = "Map of database names with nested schemas"
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
  description = "Map of storage integration names to their details"
  value = {
    for k, v in module.storage_integrations.aws_storage_integrations : k => {
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
      for k, v in module.stage.internal_stages : k => {
        name                 = v.name
        fully_qualified_name = v.fully_qualified_name
        database             = v.database
        schema               = v.schema
        comment              = v.comment
      }
    }
    external = {
      for k, v in module.stage.external_stages : k => {
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

# output "tables" {
#   description = "Map of table names to their details"
#   value = {
#     for k, v in snowflake_table.this : k => {
#       name     = v.name
#       database = v.database
#       schema   = v.schema
#       comment  = v.comment
#     }
#   }
# }

# output "snowpipes" {
#   description = "Map of snowpipe names to their details"
#   value = {
#     for k, v in snowflake_pipe.this : k => {
#       name                 = v.name
#       database             = v.database
#       schema               = v.schema
#       copy_statement       = v.copy_statement
#       auto_ingest          = v.auto_ingest
#       notification_channel = v.notification_channel
#       comment              = v.comment
#     }
#   }
# }