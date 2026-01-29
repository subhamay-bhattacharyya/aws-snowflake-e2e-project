# -- infra/snowflake/tf/modules/snowpipe/variables.tf (Child Module)
# ============================================================================
# Snowflake Snowpipe Variables
# ============================================================================

variable "snowpipe_config" {
  description = "List of snowpipe configurations as JSON objects"
  type = list(object({
    database       = string
    schema         = string
    name           = string
    comment        = optional(string, "")
    copy_statement = string
    auto_ingest    = optional(bool, false)

    # AWS SNS topic for auto-ingest
    aws_sns_topic_arn = optional(string)

    # Integration for notifications
    integration = optional(string)

    # Error handling
    error_integration = optional(string)
  }))
}
