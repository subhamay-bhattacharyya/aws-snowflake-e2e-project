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

  update_trust_policy    = false
  snowflake_iam_user_arn = ""
  snowflake_external_id  = ""
}

# ----------------------------------------------------------------------------
# Phase 2: Snowflake Base Resources (WITHOUT Snowpipes)
# ----------------------------------------------------------------------------

module "snowflake" {
  source = "../../snowflake/tf"

  # Pass provider aliases
  providers = {
    snowflake                           = snowflake
    snowflake.db_provisioner            = snowflake
    snowflake.warehouse_provisioner     = snowflake.warehouse_provisioner
    snowflake.data_object_provisioner   = snowflake.data_object_provisioner
    snowflake.ingest_object_provisioner = snowflake.ingest_object_provisioner
  }

  # Pass Snowflake configurations
  warehouse_configs           = local.warehouses
  database_schemas            = local.database_schemas
  file_format_configs         = local.file_formats
  storage_integration_configs = local.storage_integrations
  stage_configs               = local.stages
  table_configs               = local.tables
  # snowpipe_config            = {} # Empty - Snowpipes created in Phase 4

  depends_on = [module.aws]
}


# ----------------------------------------------------------------------------
# Phase 3: Update IAM Role Trust Policy with Snowflake values
# ----------------------------------------------------------------------------
# Extract the first storage integration's trust values from Snowflake output
locals {
  # Check if storage integrations are configured (known at plan time from input config)
  has_storage_integration_config = length(lookup(local.snowflake_config, "storage_integrations", {})) > 0
  
  # Runtime values from module output
  storage_integration_keys     = keys(module.snowflake.storage_integrations)
  first_storage_integration    = length(local.storage_integration_keys) > 0 ? module.snowflake.storage_integrations[local.storage_integration_keys[0]] : null
  snowflake_iam_user_arn       = try(local.first_storage_integration.describe_output[0].iam_user_arn, "")
  snowflake_external_id_output = try(local.first_storage_integration.describe_output[0].external_id, "")
}

# ----------------------------------------------------------------------------
# Phase 3: Update IAM Role Trust Policy with Snowflake values
# ----------------------------------------------------------------------------
# Use dedicated module to update the trust policy
# This ensures proper state management and dependency ordering

module "iam_trust_policy" {
  source = "../../aws/tf/modules/iam_trust_policy"

  # Use static config-based check (known at plan time)
  enabled                = var.enable_trust_policy_update && local.has_storage_integration_config
  role_name              = local.iam_role_config.name
  snowflake_iam_user_arn = local.snowflake_iam_user_arn
  snowflake_external_id  = local.snowflake_external_id_output

  depends_on = [module.snowflake, module.aws]
}

# ----------------------------------------------------------------------------
# Phase 4: Snowpipes (created AFTER trust policy is updated)
# ----------------------------------------------------------------------------
# Snowpipes with auto_ingest=true require the IAM role to be assumable by
# Snowflake. Creating them after the trust policy update ensures the
# storage integration can successfully assume the IAM role.
# NOTE: On fresh deployments, run terraform apply twice or use -target flag
# to ensure trust policy is updated before pipe creation.
# ----------------------------------------------------------------------------
module "pipe" {
  source = "github.com/subhamay-bhattacharyya-tf/terraform-snowflake-pipe?ref=feature/TFMOD-0005-refactor-repository-struc"

  providers = {
    snowflake = snowflake.ingest_object_provisioner
  }

  # Only create pipes if snowpipes are configured
  pipe_configs = var.enable_snowpipe_creation ? local.snowpipes : {}

  depends_on = [
    module.iam_trust_policy,
    module.snowflake,
    module.aws
  ]
}

# # ----------------------------------------------------------------------------
# # Phase 5: Configure S3 Event Notifications for Snowpipe Auto-Ingest
# # ----------------------------------------------------------------------------
# locals {
#   # Check if snowpipes are configured (known at plan time from input config)
#   has_snowpipes = length(local.snowpipes) > 0

#   # Build notification configs from snowpipe outputs
#   snowpipe_notifications = [
#     for key, pipe in snowflake_pipe.this : {
#       id            = key
#       sqs_arn       = pipe.notification_channel
#       events        = ["s3:ObjectCreated:*"]
#       filter_prefix = lookup(local.snowpipes[key], "filter_prefix", null)
#       filter_suffix = lookup(local.snowpipes[key], "filter_suffix", null)
#     } if pipe.notification_channel != null && pipe.notification_channel != ""
#   ]
# }

# module "s3_event_notification" {
#   source = "../../aws/tf/modules/s3_event_notification"

#   # Use input config to determine if enabled (known at plan time)
#   enabled       = local.has_snowpipes
#   bucket_name   = local.s3_config.bucket_name
#   notifications = local.snowpipe_notifications

#   depends_on = [snowflake_pipe.this, module.aws_iam_role_final]
# }
