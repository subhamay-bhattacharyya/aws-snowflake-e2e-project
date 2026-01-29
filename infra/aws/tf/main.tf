# -- infra/aws/tf/main.tf (Child Module)
# ============================================================================
# AWS Infrastructure for Snowflake Lakehouse
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 1: AWS Resources (infra/aws/tf)        ← YOU ARE HERE│
# ├─────────────────────────────────────────────────────────────┤
# │  1. S3 Bucket                                               │
# │  2. IAM Role (initial - with placeholder trust policy)      │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 2: Snowflake Resources (infra/snowflake/tf)          │
# ├─────────────────────────────────────────────────────────────┤
# │  1. Warehouses                                              │
# │  2. Databases                                               │
# │  3. File Formats                                            │
# │  4. Storage Integration ← references IAM Role ARN           │
# │     └─► Outputs: STORAGE_AWS_IAM_USER_ARN                   │
# │                  STORAGE_AWS_EXTERNAL_ID                    │
# │  5. Stages                                                  │
# │  6. Snowpipes                                               │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 3: AWS Trust Policy Update (infra/aws/tf)            │
# ├─────────────────────────────────────────────────────────────┤
# │  Update IAM Role trust policy with Snowflake's              │
# │  external ID and IAM user ARN                               │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ----------------------------------------------------------------------------
# Phase 1: AWS Resources
# ----------------------------------------------------------------------------

# 1. S3 Bucket for Snowflake external stage
module "s3" {
  source = "./modules/s3"

  s3_bucket = {
    bucket_name   = var.s3_config.bucket_name
    versioning    = var.s3_config.versioning
    kms_key_alias = var.s3_config.kms_key_alias
    kms_key_arn   = var.s3_config.kms_key_arn
    bucket_policy = var.s3_config.bucket_policy
    bucket_keys   = var.s3_config.bucket_keys
  }
}

# 2. IAM Role for Snowflake storage integration
#    - First apply: creates role with placeholder trust policy
#    - After Phase 2: re-apply with snowflake_principal_arn and snowflake_external_id
module "iam_role" {
  source   = "./modules/iam"
  iam_role = var.iam_role_config

  depends_on = [module.s3]
}

# ----------------------------------------------------------------------------
# Phase 3: Update IAM Role Trust Policy with Snowflake values
# ----------------------------------------------------------------------------
module "iam_role_final" {
  source = "./modules/iam_role_final"

  enabled                = var.update_trust_policy
  role_name              = var.iam_role_config.role_name
  snowflake_iam_user_arn = var.snowflake_iam_user_arn
  snowflake_external_id  = var.snowflake_external_id

  depends_on = [module.iam_role]
}