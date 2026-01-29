# -- infra/snowflake/tf/modules/stage/main.tf (Child Module)
# ============================================================================
# Snowflake Stage Sub-Module
# ============================================================================

resource "snowflake_stage" "this" {
  for_each = { for stage in var.stage_config : stage.name => stage }

  database = each.value.database
  schema   = each.value.schema
  name     = each.value.name
  comment  = lookup(each.value, "comment", "")

  # External stage properties
  url                 = lookup(each.value, "url", null)
  storage_integration = lookup(each.value, "storage_integration", null)
  file_format         = lookup(each.value, "file_format", null)

  # Credentials (if not using storage integration)
  credentials = lookup(each.value, "credentials", null)

  # Encryption
  encryption = lookup(each.value, "encryption", null)

  # Directory table
  directory = lookup(each.value, "directory", null)
}
