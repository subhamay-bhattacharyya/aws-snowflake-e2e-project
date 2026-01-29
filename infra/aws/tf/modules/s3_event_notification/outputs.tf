# -- infra/aws/tf/modules/s3_event_notification/outputs.tf (Child Module)
# ============================================================================
# S3 Event Notification Module - Outputs
# ============================================================================

output "notification_configured" {
  description = "Whether S3 event notifications were configured"
  value       = var.enabled && length(var.notifications) > 0
}

output "bucket_name" {
  description = "The S3 bucket name with notifications configured"
  value       = var.bucket_name
}

output "notification_count" {
  description = "Number of notification configurations"
  value       = length(var.notifications)
}
