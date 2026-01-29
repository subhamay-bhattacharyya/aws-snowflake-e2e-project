# -- infra/platform/tf/locals.tf (Platform Module)
# ============================================================================
# Local Values
# ============================================================================

# data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Compute KMS key alias first (no dependency on s3_config)
locals {
  kms_key_alias_raw = jsondecode(file("${path.module}/${var.aws_config_path}")).aws.s3.kms_key_alias
  kms_key_alias     = startswith(local.kms_key_alias_raw, "alias/") ? local.kms_key_alias_raw : "alias/${local.kms_key_alias_raw}"
}

data "aws_kms_key" "kms" { key_id = local.kms_key_alias }

locals {
  # current_region = data.aws_region.current.id

  # Parse config from JSON files (relative to module path)
  aws_config_file       = jsondecode(file("${path.module}/${var.aws_config_path}"))
  snowflake_config_file = jsondecode(file("${path.module}/${var.snowflake_config_path}"))

  # Extract nested sections
  aws_config       = local.aws_config_file.aws
  snowflake_config = local.snowflake_config_file
  trust_config     = local.aws_config_file.trust

  # ============================================================================
  # AWS Configuration
  # ============================================================================

  # Assume role policy - uses Snowflake principal ARN and external ID from trust config
  snowflake_principal_arn = local.trust_config.snowflake_principal_arn
  snowflake_external_id   = local.trust_config.snowflake_external_id
  has_snowflake_trust     = local.snowflake_principal_arn != "" && local.snowflake_external_id != ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { AWS = local.has_snowflake_trust ? local.snowflake_principal_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
      Action    = "sts:AssumeRole",
      Condition = local.has_snowflake_trust ? {
        StringEquals = {
          "sts:ExternalId" = local.snowflake_external_id
        }
      } : {}
    }]
  })

  # S3 Configuration
  s3_config = {
    bucket_name   = "${var.project_code}-${local.aws_config.s3.bucket_name}-${var.environment}-${local.aws_config.region}"
    versioning    = local.aws_config.s3.versioning
    kms_key_alias = local.kms_key_alias
    kms_key_arn   = data.aws_kms_key.kms.arn
    bucket_keys   = lookup(local.aws_config.s3, "bucket_keys", [])
    bucket_policy = templatefile("${path.module}/../../aws/tf/templates/bucket-policy/s3-bucket-policy.tpl", {
      aws_account_id = data.aws_caller_identity.current.account_id
      bucket_name    = "${var.project_code}-${local.aws_config.s3.bucket_name}-${var.environment}-${local.aws_config.region}"
    })
  }

  # IAM Role Configuration
  iam_role_config = {
    role_name          = "${var.project_code}-snowflake-storage-integration-role-${var.environment}"
    assume_role_policy = local.assume_role_policy
    s3_bucket_arn      = "arn:aws:s3:::${var.project_code}-${local.aws_config.s3.bucket_name}-${var.environment}-${local.aws_config.region}"
    kms_key_arn        = data.aws_kms_key.kms.arn
  }

  # ============================================================================
  # Snowflake Configuration
  # ============================================================================

  # Warehouses - add optional prefix to names
  warehouses = {
    for key, wh in local.snowflake_config.warehouses : key => merge(wh, {
      name = var.project_code != "" ? upper("${var.project_code}_${wh.name}") : wh.name
    })
  }

  # Databases - extract only database-level attributes with optional prefix
  databases = {
    for key, db in local.snowflake_config.databases : key => {
      name    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
      comment = lookup(db, "comment", "")
    }
  }

  # Schemas - flatten from all databases into a map
  schemas = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for schema in lookup(db, "schemas", []) : {
          key      = "${db_key}_${lower(schema.name)}"
          database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          name     = schema.name
          comment  = lookup(schema, "comment", "")
        }
      ]
    ]) : item.key => item
  }

  # File Formats - flatten from all databases into a map with normalized structure
  file_formats = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for ff_key, ff in lookup(db, "file_formats", {}) : {
          key         = "${db_key}_${ff_key}"
          name        = ff.name
          type        = ff.type
          database    = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          schema      = "UTIL"
          comment     = lookup(ff, "comment", "")
          compression = lookup(ff, "compression", "AUTO")
          # CSV options
          field_delimiter                = lookup(ff, "field_delimiter", ",")
          record_delimiter               = lookup(ff, "record_delimiter", "\n")
          skip_header                    = lookup(ff, "skip_header", 0)
          field_optionally_enclosed_by   = lookup(ff, "field_optionally_enclosed_by", null)
          trim_space                     = lookup(ff, "trim_space", false)
          error_on_column_count_mismatch = lookup(ff, "error_on_column_count_mismatch", true)
          escape                         = lookup(ff, "escape", null)
          escape_unenclosed_field        = lookup(ff, "escape_unenclosed_field", null)
          date_format                    = lookup(ff, "date_format", "AUTO")
          timestamp_format               = lookup(ff, "timestamp_format", "AUTO")
          null_if                        = lookup(ff, "null_if", [])
          # JSON options
          enable_octal       = lookup(ff, "enable_octal", false)
          allow_duplicate    = lookup(ff, "allow_duplicate", false)
          strip_outer_array  = lookup(ff, "strip_outer_array", false)
          strip_null_values  = lookup(ff, "strip_null_values", false)
          ignore_utf8_errors = lookup(ff, "ignore_utf8_errors", false)
        }
      ]
    ]) : item.key => item
  }

  # Storage Integrations - flatten from all databases into a map
  storage_integrations = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for si_key, si in lookup(db, "storage_integrations", {}) : {
          key                       = "${db_key}_${si_key}"
          name                      = var.project_code != "" ? upper("${var.project_code}_${si.name}") : si.name
          storage_provider          = si.storage_provider
          storage_aws_role_arn      = local.iam_role_config.role_name != "" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.iam_role_config.role_name}" : si.storage_aws_role_arn
          storage_allowed_locations = [for loc in lookup(si, "storage_allowed_locations", []) : "s3://${local.s3_config.bucket_name}/${loc}"]
          storage_blocked_locations = lookup(si, "storage_blocked_locations", [])
          enabled                   = lookup(si, "enabled", true)
          comment                   = lookup(si, "comment", "")
        }
      ]
    ]) : item.key => item
  }

  # Stages - flatten from all databases into a map
  stages = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for stage_key, stage in lookup(db, "stages", {}) : {
          key      = "${db_key}_${stage_key}"
          name     = stage.name
          database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          schema   = lookup(stage, "schema", "UTIL")
          # Replace "the-s3-bucket" placeholder with actual S3 bucket name
          url = lookup(stage, "url", null) != null ? replace(stage.url, "the-s3-bucket", local.s3_config.bucket_name) : null
          # Only add prefix if storage_integration is defined and not empty
          storage_integration = lookup(stage, "storage_integration", null) != null && lookup(stage, "storage_integration", "") != "" ? (var.project_code != "" ? upper("${var.project_code}_${stage.storage_integration}") : stage.storage_integration) : null
          file_format         = lookup(stage, "file_format", null)
          comment             = lookup(stage, "comment", "")
        }
      ]
    ]) : item.key => item
  }

  # Tables - flatten from all databases into a map
  tables = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for table_key, table in lookup(db, "tables", {}) : {
          key      = "${db_key}_${table_key}"
          name     = table.name
          database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          schema   = lookup(table, "schema", "RAW_DATA")
          columns  = table.columns
          comment  = lookup(table, "comment", "")
        }
      ]
    ]) : item.key => item
  }

  # Snowpipes - flatten from all databases into a map
  snowpipes = {
    for item in flatten([
      for db_key, db in local.snowflake_config.databases : [
        for pipe_key, pipe in lookup(db, "snowpipes", {}) : {
          key      = "${db_key}_${pipe_key}"
          name     = var.project_code != "" ? upper("${var.project_code}_${pipe.name}") : pipe.name
          database = var.project_code != "" ? upper("${var.project_code}_${db.name}") : db.name
          schema   = lookup(pipe, "schema", "RAW_DATA")
          # Replace database/schema references in copy_statement with prefixed names
          copy_statement = var.project_code != "" ? replace(pipe.copy_statement, db.name, upper("${var.project_code}_${db.name}")) : pipe.copy_statement
          auto_ingest    = lookup(pipe, "auto_ingest", true)
          comment        = lookup(pipe, "comment", "")
        }
      ]
    ]) : item.key => item
  }
}
