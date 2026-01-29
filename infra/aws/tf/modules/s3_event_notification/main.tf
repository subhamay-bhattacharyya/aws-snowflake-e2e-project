# -- infra/aws/tf/modules/s3_event_notification/main.tf (Child Module)
# ============================================================================
# S3 Event Notification Module for Snowpipe
# ============================================================================
# Configures S3 bucket event notifications to trigger Snowpipe auto-ingest
# via the SQS queue ARN provided by Snowflake storage integration.
# ============================================================================

resource "aws_s3_bucket_notification" "snowpipe" {
  count  = var.enabled ? 1 : 0
  bucket = var.bucket_name

  dynamic "queue" {
    for_each = var.notifications
    content {
      id            = queue.value.id
      queue_arn     = queue.value.sqs_arn
      events        = lookup(queue.value, "events", ["s3:ObjectCreated:*"])
      filter_prefix = lookup(queue.value, "filter_prefix", null)
      filter_suffix = lookup(queue.value, "filter_suffix", null)
    }
  }
}
