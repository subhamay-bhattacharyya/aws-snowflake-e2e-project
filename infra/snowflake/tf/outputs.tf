# -- infra/snowflake/tf/outputs.tf (Child Module)
# ============================================================================
# Snowflake Module Outputs
# ============================================================================

output "warehouses" {
  description = "Map of warehouse names to their details"
  value = {
    for k, v in snowflake_warehouse.this : k => {
      name                      = v.name
      warehouse_type            = v.warehouse_type
      warehouse_size            = v.warehouse_size
      comment                   = v.comment
      auto_suspend              = v.auto_suspend
      auto_resume               = v.auto_resume
      initially_suspended       = v.initially_suspended
      enable_query_acceleration = v.enable_query_acceleration
      min_cluster_count         = v.min_cluster_count
      max_cluster_count         = v.max_cluster_count
    }
  }
}

# Future outputs (to be implemented)
output "databases" {
  description = "Map of database names to their details"
  value = {
    for k, v in snowflake_database.this : k => {
      name    = v.name
      comment = v.comment
    }
  }
}

output "schemas" {
  description = "Map of schema names to their details"
  value = {
    for k, v in snowflake_schema.this : k => {
      name     = v.name
      database = v.database
      comment  = v.comment
    }
  }
}

output "file_formats" {
  description = "Map of file format names to their details"
  value = {
    for k, v in snowflake_file_format.this : k => {
      name        = v.name
      database    = v.database
      schema      = v.schema
      format_type = v.format_type
      comment     = v.comment
    }
  }
}

# output "storage_integrations" { ... }
output "storage_integrations" {
  description = "Map of storage integration names to their details"
  value = {
    for k, v in snowflake_storage_integration.this : k => {
      name                      = v.name
      storage_provider          = v.storage_provider
      storage_aws_role_arn      = v.storage_aws_role_arn
      storage_aws_iam_user_arn  = v.storage_aws_iam_user_arn
      storage_aws_external_id   = v.storage_aws_external_id
      storage_allowed_locations = v.storage_allowed_locations
      enabled                   = v.enabled
      comment                   = v.comment
    }
  }
}

output "stages" {
  description = "Map of stage names to their details"
  value = {
    for k, v in snowflake_stage.this : k => {
      name                = v.name
      database            = v.database
      schema              = v.schema
      url                 = v.url
      storage_integration = v.storage_integration
      comment             = v.comment
    }
  }
}

output "tables" {
  description = "Map of table names to their details"
  value = {
    for k, v in snowflake_table.this : k => {
      name     = v.name
      database = v.database
      schema   = v.schema
      comment  = v.comment
    }
  }
}

output "snowpipes" {
  description = "Map of snowpipe names to their details"
  value = {
    for k, v in snowflake_pipe.this : k => {
      name                 = v.name
      database             = v.database
      schema               = v.schema
      copy_statement       = v.copy_statement
      auto_ingest          = v.auto_ingest
      notification_channel = v.notification_channel
      comment              = v.comment
    }
  }
}