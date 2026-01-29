# -- infra/aws/tf/modules/iam/main.tf (Child Module)

resource "aws_iam_role" "this" {
  name               = var.iam_role.role_name
  assume_role_policy = var.iam_role.assume_role_policy

  # Ignore changes to assume_role_policy after creation
  # Phase 3 (aws_iam_role_final module) updates the trust policy via AWS CLI
  # with Snowflake's STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID
  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

resource "aws_iam_role_policy" "this" {
  role = aws_iam_role.this.id
  name = "${var.iam_role.role_name}-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = var.iam_role.s3_bucket_arn
      },
      { Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = "${var.iam_role.s3_bucket_arn}/*"
      },
      { Effect   = "Allow",
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
        Resource = var.iam_role.kms_key_arn
      }
    ]
  })
}
