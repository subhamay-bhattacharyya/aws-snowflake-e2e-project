# -- infra/platform/tf/modules/iam_trust_policy/variables.tf

variable "enabled" {
  description = "Enable trust policy update"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role to update"
  type        = string
}

variable "snowflake_iam_user_arn" {
  description = "Snowflake IAM user ARN from storage integration"
  type        = string
}

variable "snowflake_external_id" {
  description = "Snowflake external ID from storage integration"
  type        = string
}
