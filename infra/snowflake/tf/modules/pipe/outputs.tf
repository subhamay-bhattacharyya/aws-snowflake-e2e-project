# -- infra/snowflake/tf/modules/pipe/outputs.tf (Child Module)
# ============================================================================
# Snowflake Pipe Outputs
# ============================================================================

output "name" {
  description = "Name of the pipe"
  value       = snowflake_pipe.this.name
}

output "id" {
  description = "ID of the pipe"
  value       = snowflake_pipe.this.id
}

output "notification_channel" {
  description = "Notification channel for the pipe (SQS ARN for AWS)"
  value       = try(snowflake_pipe.this.notification_channel, null)
}
