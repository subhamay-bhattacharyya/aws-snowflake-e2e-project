# -- infra/snowflake/tf/modules/pipe/main.tf (Child Module)
# ============================================================================
# Snowflake Pipe Sub-Module
# ============================================================================

resource "snowflake_pipe" "this" {
  name           = var.name
  database       = var.database
  schema         = var.schema
  comment        = var.comment
  copy_statement = var.copy_statement
  auto_ingest    = var.auto_ingest
}
