# -- infra/aws/tf/modules/s3_event_notification/variables.tf (Child Module)
# ============================================================================
# S3 Event Notification Module - Variables
# ============================================================================

variable "enabled" {
  description = "Whether to create the S3 event notification"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Name of the S3 bucket to configure notifications for"
  type        = string
}

variable "notifications" {
  description = "List of notification configurations for Snowpipe SQS queues"
  type = list(object({
    id            = string
    sqs_arn       = string
    events        = optional(list(string), ["s3:ObjectCreated:*"])
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}
