# -- infra/snowflake/tf/modules/stage/outputs.tf (Child Module)
# ============================================================================
# Snowflake Stage Outputs
# ============================================================================

output "stages" {
  description = "Map of stage names to their details"
  value = {
    for k, v in snowflake_stage.this : k => {
      name                = v.name
      id                  = v.id
      database            = v.database
      schema              = v.schema
      url                 = v.url
      storage_integration = v.storage_integration
      file_format         = v.file_format
    }
  }
}

output "stage_names" {
  description = "List of stage names"
  value       = [for k, v in snowflake_stage.this : v.name]
}
