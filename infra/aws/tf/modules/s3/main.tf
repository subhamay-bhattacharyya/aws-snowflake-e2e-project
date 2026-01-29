# -- infra/aws/tf/modules/s3/main.tf (Child Module)

resource "aws_s3_bucket" "this" {
  bucket        = var.s3_bucket.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.s3_bucket.versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.s3_bucket.kms_key_alias
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = var.s3_bucket.bucket_policy
}

# Create S3 "folders" (empty objects with trailing slash)
resource "aws_s3_object" "folders" {
  for_each = toset(var.s3_bucket.bucket_keys)

  bucket       = aws_s3_bucket.this.id
  key          = endswith(each.value, "/") ? each.value : "${each.value}/"
  content_type = "application/x-directory"

  server_side_encryption = "aws:kms"
  kms_key_id             = var.s3_bucket.kms_key_arn
}