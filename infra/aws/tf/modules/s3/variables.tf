# -- infra/aws/tf/modules/s3/variables.tf (Child Module)

variable "s3_bucket" {
  description = "S3 bucket configuration"
  type = object({
    bucket_name   = string
    versioning    = bool
    kms_key_alias = string
    kms_key_arn   = string
    bucket_policy = string
    bucket_keys   = list(string)
  })
}