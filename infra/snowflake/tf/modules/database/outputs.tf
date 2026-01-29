# -- infra/snowflake/tf/modules/database/outputs.tf (Child Module)
# ============================================================================
# Snowflake Database Outputs
# ============================================================================

output "databases" {
  description = "Map of database names to their details"
  value = {
    for k, v in snowflake_database.this : k => {
      name = v.name
      id   = v.id
    }
  }
}

output "schemas" {
  description = "Map of schema names to their IDs"
  value = {
    for k, v in snowflake_schema.schemas : k => {
      name     = v.name
      database = v.database
      id       = v.id
    }
  }
}
