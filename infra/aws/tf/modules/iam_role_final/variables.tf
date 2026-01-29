# -- infra/aws/tf/modules/iam_role_final/variables.tf (Child Module)
# ============================================================================
# IAM Role Trust Policy Update Module - Variables
# ============================================================================

variable "enabled" {
  description = "Whether to update the trust policy"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role to update"
  type        = string
}

variable "snowflake_iam_user_arn" {
  description = "Snowflake's IAM user ARN from storage integration (STORAGE_AWS_IAM_USER_ARN)"
  type        = string
}

variable "snowflake_external_id" {
  description = "Snowflake's external ID from storage integration (STORAGE_AWS_EXTERNAL_ID)"
  type        = string
}
