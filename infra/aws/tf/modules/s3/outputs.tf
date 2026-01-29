# -- infra/aws/tf/modules/s3/outputs.tf (Child Module)

output "name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.this.id
}
output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.this.arn
}
output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.this.region
}
output "versioning_status" {
  description = "S3 bucket versioning status"
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}
