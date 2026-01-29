# -- infra/platform/tf/main.tf (Platform Module)
# ============================================================================
# Snowflake Lakehouse - Platform Orchestration          ← YOU ARE HERE
# ============================================================================
#
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 1: AWS Resources (module.aws)                        │
# ├─────────────────────────────────────────────────────────────┤
# │  1. S3 Bucket (landing zone for data files)                 │
# │  2. IAM Role (initial - with placeholder trust policy)      │
# │     └─► Output: IAM Role ARN for Storage Integration        │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 2: Snowflake Base Resources (module.snowflake)       │
# ├─────────────────────────────────────────────────────────────┤
# │  1. Warehouses (compute resources)                          │
# │  2. Databases & Schemas                                     │
# │  3. File Formats (CSV, JSON, Parquet)                       │
# │  4. Storage Integration ← references IAM Role ARN           │
# │     └─► Outputs: STORAGE_AWS_IAM_USER_ARN                   │
# │                  STORAGE_AWS_EXTERNAL_ID                    │
# │  5. External Stages (S3 paths)                              │
# │  6. Tables (target tables for data)                         │
# │  NOTE: Snowpipes created separately in Phase 4              │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 3: AWS Trust Policy Update (module.aws_iam_role_final)│
# ├─────────────────────────────────────────────────────────────┤
# │  Update IAM Role trust policy with Snowflake's              │
# │  STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID       │
# │  (Enables Snowflake to assume the IAM role)                 │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 4: Snowpipes (snowflake_pipe resources)              │
# ├─────────────────────────────────────────────────────────────┤
# │  Create Snowpipes AFTER trust policy is updated             │
# │  (auto_ingest requires valid IAM role assumption)           │
# │     └─► Output: SQS Notification Channel ARN                │
# └─────────────────────────────────────────────────────────────┘
#                             │
#                             ▼
# ┌─────────────────────────────────────────────────────────────┐
# │  PHASE 5: S3 Event Notifications (module.s3_event_notification)│
# ├─────────────────────────────────────────────────────────────┤
# │  Configure S3 bucket event notifications to trigger         │
# │  Snowpipe auto-ingest via SQS queue                         │
# │  (s3:ObjectCreated:* → Snowpipe SQS ARN)                    │
# └─────────────────────────────────────────────────────────────┘
#
# ============================================================================

# ----------------------------------------------------------------------------
# Phase 1: AWS Resources (S3 Bucket + IAM Role with placeholder trust)
# ----------------------------------------------------------------------------
module "aws" {
  source = "../../aws/tf"

  # S3 bucket configuration
  s3_config = local.s3_config

  # IAM role configuration (with placeholder trust policy initially)
  iam_role_config = local.iam_role_config

  # Phase 3: Pass Snowflake values for trust policy update (empty on first apply)
  update_trust_policy    = false # Set to true after Phase 2 to update via AWS module
  snowflake_iam_user_arn = ""
  snowflake_external_id  = ""
}

# ----------------------------------------------------------------------------
# Phase 2: Snowflake Base Resources (WITHOUT Snowpipes)
# ----------------------------------------------------------------------------
module "snowflake" {
  source = "../../snowflake/tf"

  # Pass Snowflake configurations as individual config objects
  warehouse_config           = local.warehouses
  database_config            = local.databases
  schema_config              = local.schemas
  file_format_config         = local.file_formats
  storage_integration_config = local.storage_integrations
  stage_config               = local.stages
  table_config               = local.tables
  snowpipe_config            = {} # Empty - Snowpipes created in Phase 4

  depends_on = [module.aws]
}

# ----------------------------------------------------------------------------
# Phase 3: Update IAM Role Trust Policy with Snowflake values
# ----------------------------------------------------------------------------
# Extract the first storage integration's trust values from Snowflake output
locals {
  storage_integration_keys     = keys(module.snowflake.storage_integrations)
  has_storage_integration      = length(local.storage_integration_keys) > 0
  first_storage_integration    = local.has_storage_integration ? module.snowflake.storage_integrations[local.storage_integration_keys[0]] : null
  snowflake_iam_user_arn       = local.first_storage_integration != null ? local.first_storage_integration.storage_aws_iam_user_arn : ""
  snowflake_external_id_output = local.first_storage_integration != null ? local.first_storage_integration.storage_aws_external_id : ""
}

module "aws_iam_role_final" {
  source = "../../aws/tf/modules/iam_role_final"

  enabled                = local.has_storage_integration
  role_name              = local.iam_role_config.role_name
  snowflake_iam_user_arn = local.snowflake_iam_user_arn
  snowflake_external_id  = local.snowflake_external_id_output

  depends_on = [module.snowflake]
}

# ----------------------------------------------------------------------------
# Phase 4: Snowpipes (created AFTER trust policy is updated)
# ----------------------------------------------------------------------------
# Snowpipes with auto_ingest=true require the IAM role to be assumable by
# Snowflake. Creating them after the trust policy update ensures the
# storage integration can successfully assume the IAM role.
# ----------------------------------------------------------------------------
resource "snowflake_pipe" "this" {
  for_each = local.snowpipes

  name           = each.value.name
  database       = each.value.database
  schema         = each.value.schema
  copy_statement = each.value.copy_statement
  auto_ingest    = lookup(each.value, "auto_ingest", true)
  comment        = lookup(each.value, "comment", "")

  depends_on = [module.aws_iam_role_final, module.snowflake]
}

# ----------------------------------------------------------------------------
# Phase 5: Configure S3 Event Notifications for Snowpipe Auto-Ingest
# ----------------------------------------------------------------------------
locals {
  # Check if snowpipes are configured (known at plan time from input config)
  has_snowpipes = length(local.snowpipes) > 0

  # Build notification configs from snowpipe outputs
  snowpipe_notifications = [
    for key, pipe in snowflake_pipe.this : {
      id            = key
      sqs_arn       = pipe.notification_channel
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = lookup(local.snowpipes[key], "filter_prefix", null)
      filter_suffix = lookup(local.snowpipes[key], "filter_suffix", null)
    } if pipe.notification_channel != null && pipe.notification_channel != ""
  ]
}

module "s3_event_notification" {
  source = "../../aws/tf/modules/s3_event_notification"

  # Use input config to determine if enabled (known at plan time)
  enabled       = local.has_snowpipes
  bucket_name   = local.s3_config.bucket_name
  notifications = local.snowpipe_notifications

  depends_on = [snowflake_pipe.this, module.aws_iam_role_final]
}
