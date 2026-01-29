# -- infra/snowflake/tf/modules/snowpipe/main.tf (Child Module)
# ============================================================================
# Snowflake Snowpipe Sub-Module
# ============================================================================

resource "snowflake_pipe" "this" {
  for_each = { for pipe in var.snowpipe_config : pipe.name => pipe }

  database = each.value.database
  schema   = each.value.schema
  name     = each.value.name
  comment  = lookup(each.value, "comment", "")

  copy_statement = each.value.copy_statement
  auto_ingest    = lookup(each.value, "auto_ingest", false)

  # AWS SNS topic for auto-ingest
  aws_sns_topic_arn = lookup(each.value, "aws_sns_topic_arn", null)

  # Integration for notifications
  integration = lookup(each.value, "integration", null)

  # Error handling
  error_integration = lookup(each.value, "error_integration", null)
}
